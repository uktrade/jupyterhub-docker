data "aws_region" "aws_region" {}
data "aws_caller_identity" "aws_caller_identity" {}

variable "aws_availability_zones" {
 type = "list"
}
variable "aws_availability_zones_short" {
 type = "list"
}

variable "ip_whitelist" {
  type = "list"
}

variable "vpc_cidr" {}

variable "aws_route53_zone" {}
variable "admin_domain" {}
variable "jupyterhub_domain" {}

variable "registry_container_image" {}
variable "registry_proxy_remoteurl" {}
variable "registry_proxy_username" {}
variable "registry_proxy_password" {}
variable "registry_internal_domain" {}

variable "admin_container_image" {}

variable "admin_authbroker_client_id" {}
variable "admin_authbroker_client_secret" {}
variable "admin_authbroker_url" {}

variable "jupyterhub_container_image" {}
variable "jupyterhub_admin_users" {}
variable "jupyterhub_oauth_client_id" {}
variable "jupyterhub_oauth_client_secret" {}
variable "jupyterhub_oauth_authorize_url" {}
variable "jupyterhub_oauth_token_url" {}
variable "jupyterhub_oauth_userdata_url" {}

variable "notebooks_bucket" {}
variable "notebook_container_image" {}

locals {
  registry_container_name    = "jupyterhub-registry"
  registry_container_port    = "443"
  registry_container_memory  = 2048
  registry_container_cpu     = 1024
  registry_alb_port          = "443"

  admin_container_name    = "jupyterhub-admin"
  admin_container_port    = "8000"
  admin_container_memory  = 2048
  admin_container_cpu     = 1024
  admin_alb_port          = "443"
  admin_api_path          = "/api/v1/databases"

  jupyterhub_container_name       = "jupyterhub"
  jupyterhub_container_port       = "8000"
  jupyterhub_container_memory     = 2048
  jupyterhub_container_cpu        = 1024
  jupyterhub_alb_port             = "443"
  jupyterhub_oauth_username_key  = "email"
  jupyterhub_oauth_callback_path = "/hub/oauth_callback"

  notebook_container_name   = "jupyterhub-notebook"
  notebook_container_port   = "8888"
  notebook_container_memory = 16384
  notebook_container_cpu    = 2048
}
