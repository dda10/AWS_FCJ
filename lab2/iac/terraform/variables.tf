variable "region" {
  description = "Region"
  type        = string
  default     = "ap-southeast-1"
}

# VPC ASG
variable "cidr_subnets_private" {
  description = "CIDR Blocks for private subnets in Availability Zones"
  type        = list(string)
}

variable "cidr_subnets_public" {
  description = "CIDR Blocks for public subnets in Availability Zones"
  type        = list(string)
}

variable "vpc_cidr_block" {
  description = "CIDR Block for VPC"
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "admin_user" {
  type    = string
  default = "StackAdmin"
}

variable "key_pair" {
  type = string
}

variable "number_of_rdgw_hosts" {
  type    = number
  default = 1
}

variable "rdgw_instance_type" {
  type    = string
  default = "t3.2xlarge"
}

variable "rdgw_cidr" {
  type = string
}

variable "setup_app_insights_monitoring" {
  type    = bool
  default = false
}

variable "default_tags" {
  description = "Default tags for all resources"
  type        = map(string)
}
