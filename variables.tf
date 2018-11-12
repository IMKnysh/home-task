variable "region" {
  default = "us-east-1"
}

variable "key_name" {
  default = "my-east"
}
variable "vpc_cidr" {
  description = "CIDR for the whole VPC"
  default = "10.33.0.0/20"
}
variable "tagITA" {
  default = "Home Task"
}
variable "project_name" {
  default = "HT"
}

variable "instance_type_default" {
  default = "t2.micro"
}
variable "AWS_ACCESS_KEY_ID" {}
variable "SECRET_ACCESS_KEY" {}
variable "count" {
  default = "2"
}
locals {
  common_tags = {
    Tag = "${var.tagITA}"
  }
}
variable "vault_srv" {
  default = 2
}
variable "count_app_instances" {
  default = "2"
}
variable "count_app" {
  default = "1"
}
variable "nomad_ver" {
  default = "0.8.6"
}
variable "chef_server" {
  default = "https://test-chef-dwsvlc2iyxni6cld.us-east-1.opsworks-cm.io/organizations/default"
}
variable "chef_client_name" {
  default = "test"
}
variable "chef_key_file" {
  default = "c:/users/igor.knysh/.chef/private.pem"
}
variable "ssh_bastion_key" {
  default = "C:/Work/DevOps/AWS/free/my-east.pem"
}
variable "run_list" {
  default = ["recipe[consul-chef::consul]"]
  type = "list"
}