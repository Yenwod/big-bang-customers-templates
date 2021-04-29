locals {
  # Number of availability zones determines number of CIDRs we need
  num_azs = length(data.aws_availability_zones.available.names)

  # Size of the CIDR range, this is added to the VPC CIDR bits
  # For example if the VPC CIDR is 10.0.0.0/16 and the CIDR size is 8, the CIDR will be 10.0.xx.0/24
  cidr_size = 8

  # Step of CIDR range.  How much space to leave between CIDR sets (public, private, intra)
  cidr_step = max(10, local.num_azs)

  # Based on VPC CIDR, create subnet ranges
  cidr_index = range(local.num_azs)
  public_subnet_cidrs = [ for i in local.cidr_index : cidrsubnet(var.vpc_cidr, local.cidr_size, i) ]
  private_subnet_cidrs = [ for i in local.cidr_index : cidrsubnet(var.vpc_cidr, local.cidr_size, i + local.cidr_step) ]
}

data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name = "group-name"
    values = [var.aws_region]
  }
}

# https://github.com/terraform-aws-modules/terraform-aws-vpc
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.name
  cidr = var.vpc_cidr

  azs             = data.aws_availability_zones.available.names
  public_subnets  = local.public_subnet_cidrs
  private_subnets = local.private_subnet_cidrs

  # If you have resources in multiple Availability Zones and they share one NAT gateway,
  # and if the NAT gateway’s Availability Zone is down, resources in the other Availability
  # Zones lose internet access. To create an Availability Zone-independent architecture,
  # create a NAT gateway in each Availability Zone.
  enable_nat_gateway   = true
  single_nat_gateway   = false
  one_nat_gateway_per_az = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  # Create EIPs for NAT gateways
  reuse_nat_ips = false

  # Add in required tags for proper AWS CCM integration
  public_subnet_tags = merge({
    "kubernetes.io/cluster/${var.name}" = "shared"
    "kubernetes.io/role/elb"              = "1"
  }, var.tags)

  private_subnet_tags = merge({
    "kubernetes.io/cluster/${var.name}" = "shared"
    "kubernetes.io/role/internal-elb"     = "1"
  }, var.tags)

  tags = merge({
    "kubernetes.io/cluster/${var.name}" = "shared"
  }, var.tags)
}

# resource "aws_security_group_rule" "rke2_ssh" {
#   from_port         = 22
#   to_port           = 22
#   protocol          = "tcp"
#   security_group_id = module.rke2.cluster_data.cluster_sg
#   type              = "ingress"
#   cidr_blocks       = ["0.0.0.0/0"]
# }