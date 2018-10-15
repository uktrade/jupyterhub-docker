variable "private_subnets_with_egress" {
  type = "list"
}

variable "ip_whitelist" {
  type = "list"
}

variable "aws_route53_zone" {}

variable "registry_container_image" {}
variable "registry_proxy_remoteurl" {}
variable "registry_proxy_username" {}
variable "registry_proxy_password" {}
variable "registry_internal_domain" {}

data "aws_region" "aws_region" {}

locals {
  registry_container_name    = "jupyerhub-registry"
  registry_container_port    = "443"
  registry_container_memory  = 2048
  registry_container_cpu     = 1024
  registry_target_group_port = "443"
  registry_alb_port          = "443"
}
