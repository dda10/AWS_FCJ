#VPC Vars
vpc_cidr_block = "10.10.0.0/16"
vpc_name = "ASG"
cidr_subnets_private = ["10.10.3.0/24", "10.10.4.0/24"]
cidr_subnets_public  = ["10.10.1.0/24", "10.10.2.0/24"]

vpn_vpc_cidr_block = "10.11.1.0/24"
vpn_vpc_name = "ASG VPN"
# vpn_cidr_subnets_private = ["10.250.192.0/20", "10.250.208.0/20"]
vpn_cidr_subnets_public = ["10.11.1.0/24"]

default_tags = {
  "owner" = "tf-user"
} 