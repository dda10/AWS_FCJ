variable "region" {
  description = "Region"
  type = string
  default = "ap-southeast-1"
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

variable "default_tags" {
  description = "Default tags for all resources"
  type        = map(string)
}

variable "vpc_name" {
  description = "Name of VPC"
  type        = string
}

# VPC ASG VPN
variable "vpn_vpc_name" {
  description = "Name of VPC"
  type        = string
}

variable "vpn_cidr_subnets_private" {
  description = "CIDR Blocks for private subnets in Availability Zones"
  type        = list(string)
}

variable "vpn_cidr_subnets_public" {
  description = "CIDR Blocks for public subnets in Availability Zones"
  type        = list(string)
}

variable "vpn_vpc_cidr_block" {
  description = "CIDR Block for VPC"
}

variable "vpn_default_tags" {
  description = "Default tags for all resources"
  type        = map(string)
}

variable "instance_type" {
  description = "EC2 Instance Type"
  type        = string
  default     = "t2.micro"
}