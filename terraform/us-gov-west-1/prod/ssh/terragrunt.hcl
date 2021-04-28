locals {
  env = yamldecode(file(find_in_parent_folders("env.yaml")))
}

terraform {
  source = "${path_relative_from_include()}//main/ssh"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  name  = local.env.name
}