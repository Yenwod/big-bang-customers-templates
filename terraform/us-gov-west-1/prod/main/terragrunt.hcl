terraform {
  source = "${path_relative_from_include()}//main/k8s"
}

include {
  path = find_in_parent_folders()
}

dependency "server" {
  config_path = "../server"
  mock_outputs = {
    kubeconfig_path = "kubeconfig_mock_path"
  }
}

inputs = {
  kubeconfig_path = dependency.server.outputs.kubeconfig_path
}