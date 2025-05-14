#VPC Vars
vpc_cidr_block = "10.10.0.0/16"
# vpc_name = "lab-vpc"
cidr_subnets_private = ["10.10.0.0/19", "10.10.32.0/19"]
cidr_subnets_public  = ["10.10.128.0/20", "10.10.144.0/20"]

default_tags = {
  "owner" = "tf-user"
} 

rdgw_instance_type = "t3.2xlarge"
admin_password = "Daoduyanh123@"