locals {
  env = yamldecode(file(find_in_parent_folders("env.yaml")))
}

include {
  path = find_in_parent_folders()
}

inputs = {
  name  = local.env.name
}