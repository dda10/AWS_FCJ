data "aws_availability_zones" "azs" {}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  # name = var.vpc_name
  cidr = var.vpc_cidr_block

  azs             = data.aws_availability_zones.azs.names
  private_subnets = var.cidr_subnets_private
  public_subnets  = var.cidr_subnets_public

  public_subnet_names  = ["Public Subnet 1", "Public Subnet 2"]
  private_subnet_names = ["Private Subnet 1", "Private Subnet 2"]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  # Tags
  tags = var.default_tags

}

# Security Group for RD Gateway
resource "aws_security_group" "rdgw" {
  name_prefix = "rdgw-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.rdgw_cidr]
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.rdgw_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Launch Template for RD Gateway
resource "aws_launch_template" "rdgw" {
  name_prefix   = "rdgw-"
  image_id      = data.aws_ami.windows_2019.id
  instance_type = var.rdgw_instance_type

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.rdgw.id]
  }

  user_data = base64encode(templatefile("${path.module}/userdata.ps1", {
    admin_user     = var.admin_user
    admin_password = var.admin_password
  }))

  key_name = var.key_pair

  monitoring {
    enabled = var.setup_app_insights_monitoring
  }
}

# Auto Scaling Group for RD Gateway
resource "aws_autoscaling_group" "rdgw" {
  name                = "rdgw-asg"
  desired_capacity    = var.number_of_rdgw_hosts
  max_size            = 4
  min_size            = 1
  target_group_arns   = [aws_lb_target_group.rdgw.arn]
  vpc_zone_identifier = module.vpc.public_subnets

  launch_template {
    id      = aws_launch_template.rdgw.id
    version = "$Latest"
  }
}

# Application Load Balancer
resource "aws_lb" "rdgw" {
  name               = "rdgw-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = module.vpc.public_subnets
}

resource "aws_lb_target_group" "rdgw" {
  name     = "rdgw-tg"
  port     = 3389
  protocol = "TCP"
  vpc_id   = module.vpc.vpc_id
}

resource "aws_lb_listener" "rdgw" {
  load_balancer_arn = aws_lb.rdgw.arn
  port              = 3389
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rdgw.arn
  }
}
