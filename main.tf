terraform {
  backend "s3" {
    bucket = "ht-terraform-state-bucket"
    key    = "default"
    region = "us-east-1"
    dynamodb_table = "HT.TF.State"
  }
}

provider "aws" {
  region     = "${var.region}"
  access_key = "${var.AWS_ACCESS_KEY_ID}"
  secret_key = "${var.SECRET_ACCESS_KEY}"
}
data "aws_ami" "compute" {
  most_recent = true
  filter {
    name = "name"
    values = ["amzn-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  "owners" = ["amazon"]
}

data "aws_ami" "nat_ami" {
  most_recent = true
  filter {
    name = "name"
    values = ["amzn-ami-vpc-nat*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  "owners" = ["amazon"]
}

data "aws_availability_zones" "available" {
  state = "available"
}
module "network" {
  source = "./10-network"
  tagITA = "${var.tagITA}"
  project_name = "${var.project_name}"
  vpc_zones = ["${data.aws_availability_zones.available.names}"]
  count_app_instances = "${var.count_app_instances}"
  vpc_cidr = "${var.vpc_cidr}"
  count = "${var.count}"
  amis = "${data.aws_ami.compute.id}"
  instance_type_default = "${var.instance_type_default}"
  key_name = "${var.key_name}"
  amis_nat = "${data.aws_ami.nat_ami.id}"
}
module "tls" {
  source = "./20-tls"
  region = "${var.region}"
  count_app_instances = "${var.count_app_instances}"
}