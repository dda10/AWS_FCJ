data "aws_availability_zones" "azs" {}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = var.vpc_cidr_block

  azs             = data.aws_availability_zones.azs.names
  private_subnets = var.cidr_subnets_private
  public_subnets  = var.cidr_subnets_public

  public_subnet_names  = ["Public Subnet 1", "Public Subnet 2"]
  private_subnet_names = ["Private Subnet 1", "Private Subnet 2"]

  enable_dns_hostnames = true
  enable_dns_support   = true

  # Tags
  tags = var.default_tags
  igw_tags = {
    "Name" : "Internet Gateway"
  }

  public_route_table_tags = {
    "Name" : "Route table-Public"
  }
  private_route_table_tags = {
    "Name" : "Route table-Private"
  }
}

module "vpc_vpn" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpn_vpc_name
  cidr = var.vpn_vpc_cidr_block

  azs = data.aws_availability_zones.azs.names
  #private_subnets = var.vpn_cidr_subnets_private
  public_subnets       = var.vpn_cidr_subnets_public
  public_subnet_names  = ["VPN Public"]
  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway   = false
  # enable_vpn_gateway   = true

  tags = var.default_tags
  # Tags
  igw_tags = {
    "Name" = "Internet Gateway VPN"
  }


}

module "public_subnet_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "Public subnet - SG"
  description = "Enter Allow SSH and Ping for servers in the public subnet"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["ssh-tcp", "all-icmp"]

  egress_rules = ["all-all"]
}

module "private_subnet_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "Private subnet - SG"
  description = "Enter Allow SSH and Ping for servers in the private subnet"
  vpc_id      = module.vpc.vpc_id

  # Allow ingress from public security group
  ingress_with_source_security_group_id = [
    {
      from_port                = 0
      to_port                  = 65535
      protocol                 = "tcp"
      description              = "Allow all TCP from public security group"
      source_security_group_id = module.public_subnet_sg.security_group_id
    },
  ]

  ingress_with_cidr_blocks = [
    {
      from_port   = -1
      to_port     = -1
      protocol    = "icmp"
      description = "Allow all Ping from anywhere"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_rules = ["all-all"]
}

module "vpn_subnet_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "VPN Public - SG"
  description = "Allow IPSec, SSH, and Ping for servers in the public subnet"
  vpc_id      = module.vpc_vpn.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = -1
      to_port     = -1
      protocol    = "icmp"
      description = "Allow ICMP"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 500
      to_port     = 500
      protocol    = "udp"
      description = "IKE"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 4500
      to_port     = 4500
      protocol    = "udp"
      description = "IKE NAT-T"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = -1
      to_port     = -1
      protocol    = "50"
      description = "ESP"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_rules = ["all-all"]
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"] #Amazon
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [module.public_subnet_sg.security_group_id]
  key_name                    = "aws-keypair"
  associate_public_ip_address = true
  tags = merge(var.default_tags, tomap({
    Name = "EC2 Public"
  }))

}

resource "aws_instance" "cgw_instance" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  subnet_id                   = module.vpc_vpn.public_subnets[0]
  vpc_security_group_ids      = [module.vpn_subnet_sg.security_group_id]
  key_name                    = "aws-keypair"
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install libreswan -y
              
              # Initialize NSS database for Libreswan
              ipsec initnss

              # Configure system for IPsec/VPN
              echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
              echo "net.ipv4.conf.default.rp_filter = 0" >> /etc/sysctl.conf
              echo "net.ipv4.conf.default.accept_source_route = 0" >> /etc/sysctl.conf
              sysctl -p

              # Create vpn config
              touch /etc/ipsec.d/aws.conf
              touch /etc/ipsec.d/aws.secrets

              # Start and enable IPsec service
              systemctl start ipsec
              systemctl enable ipsec
              EOF

  tags = merge(var.default_tags, tomap({
    Name = "Customer Gateway instance"
  }))
}

# Create Customer Gateway
resource "aws_customer_gateway" "main" {
  bgp_asn    = 65000 # BGP ASN for your on-premises network
  ip_address = aws_instance.cgw_instance.public_ip
  type       = "ipsec.1"

  tags = {
    Name = "Customer Gateway"
  }
}

# Create Transit Gateway
resource "aws_ec2_transit_gateway" "main" {
  description = "Transit Gateway ASG"

  tags = {
    Name = "Transit Gateway ASG"
  }
}

resource "aws_vpn_connection" "main" {
  customer_gateway_id = aws_customer_gateway.main.id
  transit_gateway_id  = aws_ec2_transit_gateway.main.id
  type                = "ipsec.1"
  static_routes_only  = true

  tags = {
    Name = "VPN Connection"
  }
}

# Create Transit Gateway VPC Attachment
resource "aws_ec2_transit_gateway_vpc_attachment" "main" {
  # Remove the extra [] brackets around module.vpc.private_subnets
  subnet_ids         = module.vpc.public_subnets
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = module.vpc.vpc_id

  tags = {
    Name = "VPC Attachment ASG VPN"
  }
}

# Add route to VPN in Transit Gateway Route Table
resource "aws_ec2_transit_gateway_route" "vpn_route" {
  destination_cidr_block         = module.vpc_vpn.vpc_cidr_block
  transit_gateway_route_table_id = aws_ec2_transit_gateway.main.association_default_route_table_id
  transit_gateway_attachment_id  = aws_vpn_connection.main.transit_gateway_attachment_id
}

resource "aws_route" "public_to_vpn" {
  route_table_id         = module.vpc.public_route_table_ids[0]
  destination_cidr_block = module.vpc_vpn.vpc_cidr_block
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
}

resource "aws_route" "private_to_vpn" {
  route_table_id         = module.vpc.private_route_table_ids[0]
  destination_cidr_block = module.vpc_vpn.vpc_cidr_block
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
}
