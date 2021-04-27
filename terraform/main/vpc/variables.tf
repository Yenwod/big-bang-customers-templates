variable "name" {
  description = "The name to apply to the VPC and Subnets"
  type    = string
  default = "bigbang-dev"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC in the format xx.xx.xx.xx/xx"
  type        = string
}

# Assumption: region has 3 availability zones named a, b, and c
variable "aws_region" {
  description = "The AWS region to deploy resources"
  type    = string
  default = "us-gov-west-1"
}

variable "tags" {
  description = "The tags to apply to resources"
  type = map(string)
  default = {}
}