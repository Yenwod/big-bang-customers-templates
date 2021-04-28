locals {
  env = merge(
    yamldecode(file(find_in_parent_folders("region.yaml"))),
    yamldecode(file(find_in_parent_folders("env.yaml")))
  )
}

terraform {
  source = "${path_relative_from_include()}//main/vpc"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  name = local.env.name
  aws_region = local.env.region
  vpc_cidr = local.env.cidr
  tags = merge(local.env.region_tags, local.env.tags, {})
}