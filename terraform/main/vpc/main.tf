locals {
  # Number of availability zones determines number of CIDRs we need
  num_azs = length(data.aws_availability_zones.available.names)

  # Size of the CIDR range, this is added to the VPC CIDR bits
  # For example if the VPC CIDR is 10.0.0.0/16 and the CIDR size is 8, the CIDR will be 10.0.xx.0/24
  cidr_size = 8

  # Based on VPC CIDR, create subnet ranges
  cidr_index = range(local.num_azs)
  public_subnet_cidrs = [ for i in local.cidr_index : cidrsubnet(var.vpc_cidr, local.cidr_size, i) ]
  private_subnet_cidrs = [ for i in local.cidr_index : cidrsubnet(var.vpc_cidr, local.cidr_size, i + local.num_azs) ]
  intra_subnet_cidrs = [ for i in local.cidr_index : cidrsubnet(var.vpc_cidr, local.cidr_size, i + (local.num_azs * 2)) ]
}

data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name = "group-name"
    values = [var.aws_region]
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "2.78.0"

  name = var.name
  cidr = var.vpc_cidr

  azs             = data.aws_availability_zones.available.names
  #azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  public_subnets  = local.public_subnet_cidrs
  private_subnets = local.private_subnet_cidrs
  intra_subnets   = local.intra_subnet_cidrs

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Use AWS VPC private endpoints to mirror functionality on airgapped (T)C2S environments
  #   S3: for some vendors cluster bootstrapping/artifact storage
  #   STS: for caller identity checks
  #   EC2: for cloud manager type requests (such as auto ebs provisioning)
  #   ASG: for cluster autoscaler
  #   ELB: for auto elb provisioning
  enable_s3_endpoint                   = true
  enable_sts_endpoint                  = true
  enable_ec2_endpoint                  = true
  enable_ec2_autoscaling_endpoint      = true
  enable_elasticloadbalancing_endpoint = true

  ec2_endpoint_security_group_ids  = [aws_security_group.endpoints.id]
  ec2_endpoint_subnet_ids          = module.vpc.intra_subnets
  ec2_endpoint_private_dns_enabled = true

  ec2_autoscaling_endpoint_security_group_ids  = [aws_security_group.endpoints.id]
  ec2_autoscaling_endpoint_subnet_ids          = module.vpc.intra_subnets
  ec2_autoscaling_endpoint_private_dns_enabled = true

  elasticloadbalancing_endpoint_security_group_ids  = [aws_security_group.endpoints.id]
  elasticloadbalancing_endpoint_subnet_ids          = module.vpc.intra_subnets
  elasticloadbalancing_endpoint_private_dns_enabled = true

  sts_endpoint_security_group_ids  = [aws_security_group.endpoints.id]
  sts_endpoint_subnet_ids          = module.vpc.intra_subnets
  sts_endpoint_private_dns_enabled = true

  # Prevent creation of EIPs for NAT gateways
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

  intra_subnet_tags = merge({
    "kubernetes.io/cluster/${var.name}" = "shared"
  }, var.tags)

  tags = merge({
    "kubernetes.io/cluster/${var.name}" = "shared"
  }, var.tags)
}

# Shared Private Endpoint Security Group
resource "aws_security_group" "endpoints" {
  name        = "${var.name}-endpoint"
  description = "${var.name} endpoint"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# resource "aws_security_group_rule" "rke2_ssh" {
#   from_port         = 22
#   to_port           = 22
#   protocol          = "tcp"
#   security_group_id = module.rke2.cluster_data.cluster_sg
#   type              = "ingress"
#   cidr_blocks       = ["0.0.0.0/0"]
# }