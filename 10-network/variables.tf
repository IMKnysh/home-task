variable "vpc_cidr" {}
variable "vpc_zones" {type = "list"}
variable "tagITA" {}
variable "project_name" {}
locals {
  common_tags = {
    Tag = "${var.tagITA}"
  }
}
#variable "route53_zone_id" {}
#variable "dns_name" {}
#variable "s3bucket_id" {}
variable "count" {}
variable "amis" {}
variable "amis_nat" {}
variable "instance_type_default" {}
variable "key_name" {}
variable "count_app_instances" {}
