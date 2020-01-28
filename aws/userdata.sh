#! /bin/bash
echo "Dotscience hub"
INSTANCE_ID=$( curl -s http://169.254.169.254/latest/meta-data/instance-id )
echo "Attaching device $INSTANCE_VOLUME_ID to $INSTANCE_ID"
while ! aws ec2 attach-volume --volume-id "${aws_ebs_volume.ds_hub_volume.id}" --instance-id $INSTANCE_ID --region "${var.region}" --device /dev/sdf 
do
    echo "Waiting for volume to attach..."
    sleep 5
done
echo "Waiting for mount device to show up"
sleep 60
echo "Starting Dotscience hub"
/home/ubuntu/startup.sh "${var.admin_password}" "${var.hub_volume_size}" /dev/nvme1n1 "${aws_elb.ds_elb.dns_name}" "${aws_kms_key.ds_kms_key.id}" "${var.region}" "${var.key_name}" "${aws_security_group.ds_runner_security_group.id}" "${aws_subnet.ds_subnet.id}" "${var.amis[var.region].CPURunner}" "${var.amis[var.region].GPURunner}"