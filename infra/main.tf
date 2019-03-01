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
variable "subnets_num_bits" {}
variable "vpc_notebooks_cidr" {}
variable "vpc_notebooks_subnets_num_bits" {}

variable "aws_route53_zone" {}
variable "admin_domain" {}
variable "jupyterhub_domain" {}
variable "jupyterhub_secondary_domain" {}

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

variable "alb_access_logs_bucket" {}
variable "alb_logs_account" {}

variable "logstash_container_image" {}
variable "logstash_internal_domain" {}
variable "logstash_downstream_url" {}
variable "logstash_downstream_authorization_header" {}

variable "dnsmasq_container_image" {}
variable "sentryproxy_container_image" {}

variable "cloudwatch_destination_arn" {}

variable "mirrors_bucket_name" {}
variable "mirrors_sync_container_image" {}

variable "sentry_dsn" {}

locals {
  registry_container_name    = "jupyterhub-registry"
  registry_container_port    = "5000"
  registry_container_memory  = 15360
  registry_container_cpu     = 2048
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
  notebook_container_memory = 30720
  notebook_container_cpu    = 4096

  notebook_task_role_prefix      = "jupyterhub-notebook-user-"
  notebook_task_role_policy_name = "jupyterhub-notebook-task"

  logstash_container_name       = "jupyterhub-logstash"
  logstash_alb_port             = "443"
  logstash_container_memory     = 8192
  logstash_container_cpu        = 2048
  logstash_container_port       = "8889"
  logstash_container_api_port   = "9600"

  dnsmasq_container_name       = "jupyterhub-dnsmasq"
  dnsmasq_container_memory     = 512
  dnsmasq_container_cpu        = 256

  sentryproxy_container_name       = "jupyterhub-sentryproxy"
  sentryproxy_container_memory     = 512
  sentryproxy_container_cpu        = 256

  mirrors_sync_container_name    = "jupyterhub-mirrors-sync"
  mirrors_sync_container_memory  = 8192
  mirrors_sync_container_cpu     = 1024
}
