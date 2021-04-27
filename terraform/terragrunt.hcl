locals {
  region = yamldecode(file(find_in_parent_folders("region.yaml")))
}

generate "providers" {
  path      = "providers.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.region.name}"
}
EOF
}

remote_state {
  backend = "s3"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    encrypt = true
    key     = format("%s/terraform.tfstate", path_relative_to_include())
    bucket  = "p1-bigbang-live-tf-states-${local.region.name}"
    region  = local.region.name
  }
}