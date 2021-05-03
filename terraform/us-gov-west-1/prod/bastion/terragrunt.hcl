locals {
  env = merge(
    yamldecode(file(find_in_parent_folders("region.yaml"))),
    yamldecode(file(find_in_parent_folders("env.yaml")))
  )
}

terraform {
  source = "${path_relative_from_include()}//main/bastion"
}

include {
  path = find_in_parent_folders()
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id = "mock_vpc_id"
    public_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  }
}

dependency "ssh" {
  config_path = "../ssh"
  mock_outputs = {
    public_key = "mock_public_key"
    key_name = "mock_key_name"
  }
}

inputs = {
  name  = local.env.name
  vpc_id = dependency.vpc.outputs.vpc_id
  subnets = dependency.vpc.outputs.public_subnets
  ami = local.env.bastion.image
  instance_type = local.env.bastion.type
  key_name = dependency.ssh.outputs.key_name
  tags = merge(local.env.region_tags, local.env.tags, {})
}