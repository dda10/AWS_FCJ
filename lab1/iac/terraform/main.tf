data "availability_zones" "azs" {}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = var.vpc_cidr_block

  azs             = data.availability_zones.azs.names
  private_subnets = var.cidr_subnets_private
  public_subnets  = var.cidr_subnets_public

  enable_dns_hostnames = true
  enable_dns_support = true
  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = var.default_tags
}

module "vpc_vpn" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpn_vpc_name
  cidr = var.vpn_vpc_cidr_block

  azs             = data.availability_zones.azs.names
  private_subnets = var.vpn_cidr_subnets_private
  public_subnets  = var.vpn_cidr_subnets_public

  enable_dns_hostnames = true
  enable_dns_support = true
  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = var.vpn_default_tags
}