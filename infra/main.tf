variable "ip_whitelist" {
  type = "list"
}

variable "vpc_cidr" {}
variable "aws_route53_zone" {}
variable "admin_domain" {}

variable "registry_container_image" {}
variable "registry_proxy_remoteurl" {}
variable "registry_proxy_username" {}
variable "registry_proxy_password" {}
variable "registry_internal_domain" {}

variable "admin_container_image" {}

variable "authbroker_client_id" {}
variable "authbroker_client_secret" {}
variable "authbroker_url" {}

data "aws_region" "aws_region" {}
variable "aws_availability_zones" {
 type = "list"
}
variable "aws_availability_zones_short" {
 type = "list"
}


locals {
  registry_container_name    = "jupyterhub-registry"
  registry_container_port    = "443"
  registry_container_memory  = 2048
  registry_container_cpu     = 1024
  registry_target_group_port = "443"
  registry_alb_port          = "443"

  admin_container_name    = "jupyterhub-admin"
  admin_container_port    = "8000"
  admin_container_memory  = 2048
  admin_container_cpu     = 1024
  admin_target_group_port = "8000"
  admin_alb_port          = "443"
}
