terraform {
  required_version = ">= 0.12.0"
  experiments      = [variable_validation]
}

provider "aws" {
  assume_role {
    role_arn     = var.aws_role_arn
    session_name = "dotscience-tf"
  }
  region  = var.region
  version = "~> 2.53"
}

provider "kubernetes" {
  host                   = element(concat(data.aws_eks_cluster.cluster[*].endpoint, list("")), 0)
  cluster_ca_certificate = base64decode(element(concat(data.aws_eks_cluster.cluster[*].certificate_authority.0.data, list("")), 0))
  token                  = element(concat(data.aws_eks_cluster_auth.cluster[*].token, list("")), 0)
  load_config_file       = false
  version                = "~> 1.10.0"
}

// Terraform plugin for creating random ids
resource "random_id" "default" {
  byte_length = 4
}

resource "random_id" "deployer_token" {
  byte_length = 16
}

data "aws_availability_zones" "available" {
}

data "aws_availability_zone" "regional_az" {
  name = "${var.region}a"
}

data "aws_caller_identity" "current" {}

locals {
  hub_hostname             = join("", [replace(aws_eip.ds_eip.public_ip, ".", "-"), ".", var.dotscience_domain])
  hub_subnet               = module.vpc.public_subnets[0]
  runner_subnet            = module.vpc.private_subnets[0]
  deployer_token           = random_id.deployer_token.hex
  ingress_elb_name         = var.create_deployer && var.create_eks ? module.ds_deployer.ingress_host[0] : ""
  cluster_name             = "${var.environment}-${random_id.default.hex}"
  grafana_host             = var.create_monitoring && var.create_eks ? module.ds_monitoring.grafana_host : ""
  hub_ami                  = var.amis[var.region].Hub
  cpu_runner_ami           = var.amis[var.region].CPURunner
  gpu_runner_ami           = var.amis[var.region].GPURunner
  nat_cidrs                = [for ip in module.vpc.nat_public_ips : "${ip}/32"]
  ingress_elb_arn_type     = var.create_deployer && var.create_eks ? split("-", local.ingress_elb_name)[0] : ""
  ingress_elb_arn_id       = var.create_deployer && var.create_eks ? split(".", (split("-", local.ingress_elb_name)[1]))[0] : ""
  deployer_model_subdomain = var.create_deployer && var.create_eks && var.model_deployment_mode == "aws-ga" ? join("", ["model-", replace(aws_globalaccelerator_accelerator.ds_model_ingress[0].ip_sets[0].ip_addresses[0], ".", "-"), ".", var.dotscience_domain]) : "model-${local.cluster_name}.${var.model_deployment_domain}"
}

data "aws_eks_cluster" "cluster" {
  count = var.create_eks ? 1 : 0
  name  = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  count = var.create_eks ? 1 : 0
  name  = module.eks.cluster_id
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.6.0"

  name            = "vpc-${local.cluster_name}"
  cidr            = var.vpc_network_cidr
  azs             = data.aws_availability_zones.available.names
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    "kubernetes.io/cluster/eks-${local.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/eks-${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                          = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/eks-${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"                 = "1"
  }
}

module "ds_deployer" {
  source                 = "../modules/ds_deployer"
  create_deployer        = var.create_deployer && var.create_eks ? 1 : 0
  hub_hostname           = local.hub_hostname
  deployer_token         = local.deployer_token
  kubernetes_host        = element(concat(data.aws_eks_cluster.cluster[*].endpoint, list("")), 0)
  cluster_ca_certificate = base64decode(element(concat(data.aws_eks_cluster.cluster[*].certificate_authority.0.data, list("")), 0))
  kubernetes_token       = element(concat(data.aws_eks_cluster_auth.cluster[*].token, list("")), 0)
  dotscience_environment = "aws"
}

module "ds_monitoring" {
  source                 = "../modules/ds_monitoring"
  create_monitoring      = var.create_monitoring && var.create_deployer && var.create_eks ? 1 : 0
  grafana_admin_user     = var.grafana_admin_user
  grafana_admin_password = var.grafana_admin_password
  kubernetes_host        = element(concat(data.aws_eks_cluster.cluster[*].endpoint, list("")), 0)
  cluster_ca_certificate = base64decode(element(concat(data.aws_eks_cluster.cluster[*].certificate_authority.0.data, list("")), 0))
  kubernetes_token       = element(concat(data.aws_eks_cluster_auth.cluster[*].token, list("")), 0)
  dotscience_environment = "aws"
}

module "eks" {
  source                               = "terraform-aws-modules/eks/aws"
  cluster_name                         = "eks-${local.cluster_name}"
  subnets                              = module.vpc.private_subnets
  create_eks                           = var.create_eks ? true : false
  manage_aws_auth                      = var.create_eks ? true : false
  cluster_create_timeout               = "30m"
  cluster_delete_timeout               = "30m"
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  tags = {
    Environment = local.cluster_name
    GithubRepo  = "terraform-aws-eks"
    GithubOrg   = "terraform-aws-modules"
  }

  vpc_id = module.vpc.vpc_id

  worker_groups = [
    {
      name                          = "worker-group-1"
      instance_type                 = var.eks_cluster_worker_instance_type
      asg_desired_capacity          = var.eks_cluster_worker_count
      additional_security_group_ids = []
    },
  ]

  map_roles    = var.map_roles
  map_users    = var.map_users
  map_accounts = var.map_accounts
}

resource "aws_iam_role_policy" "ds_policy" {
  name   = "ds-policy-${random_id.default.hex}"
  role   = aws_iam_role.ds_role.id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AttachVolume",
                "ec2:TerminateInstances",
                "ec2:CreateTags",
                "ec2:RunInstances"
            ],
            "Resource": [
                "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:instance/*",
                "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:subnet/${local.runner_subnet}",
                "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:volume/*",
                "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:security-group/${aws_security_group.ds_hub_security_group.id}",
                "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:security-group/${aws_security_group.ds_runner_security_group.id}",
                "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:network-interface/*",
                "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:key-pair/${var.key_name}",
                "arn:aws:ec2:${var.region}::image/${local.hub_ami}",
                "arn:aws:ec2:${var.region}::image/${local.cpu_runner_ami}",
                "arn:aws:ec2:${var.region}::image/${local.gpu_runner_ami}"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:DescribeTags",
                "ec2:DescribeVolumes",
                "ec2:DescribeKeyPairs"
            ],
            "Resource": "*"
            },
       {
            "Effect": "Allow",
            "Action": [
                "kms:GenerateDataKey"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
}

resource "aws_iam_role" "ds_role" {
  name               = "ds-role-${random_id.default.hex}"
  path               = "/"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_instance_profile" "ds_instance_profile" {
  name = "ds-instance-profile-${random_id.default.hex}"
  path = "/"
  role = aws_iam_role.ds_role.id
}

resource "aws_security_group" "ds_runner_security_group" {
  name        = "ds-runner-sg-${random_id.default.hex}"
  description = "SG for Hub and Runner EC2 Instances"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_network_cidr]
    description = "provides ssh access to the dotscience runner, for debugging"
  }

  ingress {
    from_port       = 2376
    to_port         = 2376
    protocol        = "tcp"
    security_groups = [aws_security_group.ds_hub_security_group.id]
    description     = "access from the dotscience Hub to runner docker socket, to start the runner container"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "access to download images, dependencies, and self-updates of the runner"
  }
}
resource "aws_security_group" "ds_hub_security_group" {
  name        = "ds-hub-sg-${random_id.default.hex}"
  description = "SG for Hub and Runner EC2 Instances"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [for x in distinct(concat([var.vpc_network_cidr, var.letsencrypt_ingress_cidr], var.hub_ingress_cidrs)) : x if x != ""]
    description = "Access to the Dotscience Hub web UI for the browser"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [for x in distinct(concat([var.vpc_network_cidr, var.letsencrypt_ingress_cidr], var.hub_ingress_cidrs)) : x if x != ""]
    description = "Access to the Dotscience Hub web UI for the browser"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_access_cidrs
    description = "provides ssh access to the dotscience Hub, for debugging"
  }

  ingress {
    from_port   = 8800
    to_port     = 8800
    protocol    = "tcp"
    cidr_blocks = concat(local.nat_cidrs, [var.vpc_network_cidr])
    description = "Access to the Dotscience API gateway"
  }

  ingress {
    from_port   = 9800
    to_port     = 9800
    protocol    = "tcp"
    cidr_blocks = concat(local.nat_cidrs, [var.vpc_network_cidr])
    description = "Dotscience webhook relay transponder connections"
  }

  ingress {
    from_port   = 32607
    to_port     = 32607
    protocol    = "tcp"
    cidr_blocks = [var.vpc_network_cidr]
    description = "Access to the Dotmesh server API"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Outgoing connections from the hub to the internet"
  }
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.ds_hub.id
  allocation_id = aws_eip.ds_eip.id
}

resource "aws_eip" "ds_eip" {
  vpc = true
}

resource "aws_ebs_volume" "ds_hub_volume" {
  availability_zone = data.aws_availability_zone.regional_az.name
  size              = var.hub_volume_size
  type              = "gp2"

  tags = {
    Name = "ds-hub-volume-${random_id.default.hex}"
  }
}

resource "aws_instance" "ds_hub" {
  ami                  = local.hub_ami
  instance_type        = var.hub_instance_type
  iam_instance_profile = aws_iam_instance_profile.ds_instance_profile.id
  key_name             = var.key_name
  subnet_id            = local.hub_subnet

  vpc_security_group_ids      = [aws_security_group.ds_hub_security_group.id]
  associate_public_ip_address = true
  ebs_optimized               = false

  depends_on = [aws_security_group.ds_hub_security_group,
    aws_ebs_volume.ds_hub_volume,
    aws_kms_key.ds_kms_key,
  aws_security_group.ds_runner_security_group]
  user_data = <<-EOF
              #! /bin/bash
              set -euo pipefail
              echo "Dotscience hub"
              INSTANCE_ID=$( curl -s http://169.254.169.254/latest/meta-data/instance-id )
              echo "Attaching volume ${aws_ebs_volume.ds_hub_volume.id} to $INSTANCE_ID"
              while ! aws ec2 attach-volume --volume-id "${aws_ebs_volume.ds_hub_volume.id}" --instance-id $INSTANCE_ID --region "${var.region}" --device /dev/sdf 
              do
                  echo "Waiting for volume to attach..."
                  sleep 5
              done
              echo "Waiting for mount device to show up"
              sleep 60
              echo "Starting Dotscience hub"  
              sudo wget -O /usr/local/bin/ds-startup https://storage.googleapis.com/dotscience-startup/unstable/ds-startup
              sudo chmod +wx /usr/local/bin/ds-startup
              ds-startup --admin-password "${var.admin_password}" --hub-size "${var.hub_volume_size}" --hub-device "/dev/nvme1n1" --use-kms "true" --license-key "${var.license_key}" --hub-hostname "${local.hub_hostname}" --cmk-id "${aws_kms_key.ds_kms_key.id}" --aws-region "${var.region}" --aws-sshkey "${var.key_name}" --aws-runner-sg "${aws_security_group.ds_runner_security_group.id}" --aws-subnet-id "${local.runner_subnet}" --aws-cpu-runner-image "${var.amis[var.region].CPURunner}" --aws-gpu-runner-image "${local.gpu_runner_ami}" --grafana-user "${var.grafana_admin_user}" --grafana-host "${local.grafana_host}"  --grafana-password "${var.grafana_admin_password}" --letsencrypt-mode "${var.letsencrypt_mode}" --deployer-token "${random_id.deployer_token.hex}" --deployment-ingress-class "nginx" --deployment-subdomain ".${local.deployer_model_subdomain}"
              DATA_DEVICE=$(df --output=source /opt/dotscience-aws/ | tail -1)
              e2label $DATA_DEVICE data
              echo "LABEL=data      /opt/dotscience-aws      ext4   defaults,discard        0 0" >> /etc/fstab
              EOF
  root_block_device {
    volume_type           = "gp2"
    volume_size           = 128
    delete_on_termination = true
  }

  tags = {
    Name = "ds-hub-${local.cluster_name}-${random_id.default.hex}"
  }
}

data "aws_iam_policy_document" "ds_kms_policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions = [
      "kms:*"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_kms_key" "ds_kms_key" {
  description         = "Master key for protecting sensitive data"
  key_usage           = "ENCRYPT_DECRYPT"
  is_enabled          = true
  enable_key_rotation = false
  policy              = data.aws_iam_policy_document.ds_kms_policy.json
}

resource "local_file" "ds_env_file" {
  content  = "export DOTSCIENCE_USERNAME=admin\nexport DOTSCIENCE_PASSWORD=${var.admin_password}\nexport DOTSCIENCE_URL=https://${local.hub_hostname}"
  filename = ".ds_env.sh"
}

resource "aws_route53_zone" "model_deployments_subdomain" {
  count = var.create_deployer && var.create_eks && var.model_deployment_mode == "route53" ? 1 : 0
  name  = local.deployer_model_subdomain
}

resource "aws_route53_record" "model_deployments_subdomain" {
  count   = var.create_deployer && var.create_eks && var.model_deployment_mode == "route53" ? 1 : 0
  zone_id = aws_route53_zone.model_deployments_subdomain[0].zone_id
  name    = "*.${local.deployer_model_subdomain}"
  type    = "CNAME"
  ttl     = "60"
  records = [local.ingress_elb_name]
}

data "aws_route53_zone" "model_deployments_domain" {
  count = var.create_deployer && var.create_eks && var.model_deployment_mode == "route53" ? 1 : 0
  name  = var.model_deployment_domain
}

resource "aws_route53_record" "model_deployments_domain_ns" {
  count   = var.create_deployer && var.create_eks && var.model_deployment_mode == "route53" ? 1 : 0
  zone_id = data.aws_route53_zone.model_deployments_domain[0].zone_id
  name    = local.deployer_model_subdomain
  type    = "NS"
  ttl     = "60"
  records = aws_route53_zone.model_deployments_subdomain[0].name_servers
}


resource "aws_globalaccelerator_accelerator" "ds_model_ingress" {
  name            = "Model"
  ip_address_type = "IPV4"
  enabled         = var.create_deployer && var.create_eks && var.model_deployment_mode == "aws-ga" ? true : false
  count           = var.create_deployer && var.create_eks && var.model_deployment_mode == "aws-ga" ? 1 : 0
}

resource "aws_globalaccelerator_endpoint_group" "ds_model_ingress" {
  listener_arn = aws_globalaccelerator_listener.ds_model_ingress[0].id
  endpoint_configuration {
    endpoint_id = join("", concat(["arn:aws:elasticloadbalancing:${var.region}:${data.aws_caller_identity.current.account_id}:loadbalancer/net/"], [local.ingress_elb_arn_type, "/", local.ingress_elb_arn_id]))
    weight      = 100
  }
  health_check_path             = "/"
  health_check_port             = 80
  health_check_interval_seconds = 30
  count                         = var.create_deployer && var.create_eks && var.model_deployment_mode == "aws-ga" ? 1 : 0
}

resource "aws_globalaccelerator_listener" "ds_model_ingress" {
  accelerator_arn = aws_globalaccelerator_accelerator.ds_model_ingress[0].id
  client_affinity = "SOURCE_IP"
  protocol        = "TCP"
  count           = var.create_deployer && var.create_eks && var.model_deployment_mode == "aws-ga" ? 1 : 0

  port_range {
    from_port = 80
    to_port   = 80
  }
}
