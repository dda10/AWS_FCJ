#Global Vars
# cluster_name = "devtest"

#VPC Vars
vpc_cidr_block       = "10.10.0.0/16"
vpc_name = "ASG"
cidr_subnets_private = ["10.250.192.0/20", "10.250.208.0/20"]
cidr_subnets_public  = ["10.250.224.0/20", "10.250.240.0/20"]

vpn_vpc_cidr_block       = "10.250.192.0/18"
vpn_vpc_name = "ASG VPN"
vpn_cidr_subnets_private = ["10.250.192.0/20", "10.250.208.0/20"]
vpn_cidr_subnets_public  = ["10.250.224.0/20", "10.250.240.0/20"]

#Bastion Host
# instance_count  = 1
# instance_size = "t3.small"
# instance_ami = ""


default_tags = {
  #  Env = "dev"
  #  Product = "kubernetes"
}