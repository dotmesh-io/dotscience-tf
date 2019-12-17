provider "aws" {
  region = "us-east-2"
}

resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}

resource "aws_cloudformation_stack" "dotscience-hub" {
  name = "dotscience-hub"
  template_url = "https://get.dotmesh.io/dotscience-aws/1f6a73da40822d800bf5b8b590235598ef94cb04/dotscience-cf.json"

  parameters = {
    # Example param
    VPCCidr = "10.0.0.0/16"
  }
}
