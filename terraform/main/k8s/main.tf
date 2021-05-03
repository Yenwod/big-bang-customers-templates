# Retrieves kubeconfig
resource "null_resource" "kubeconfig" {
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOF
      # Get kubeconfig from storage
      aws s3 cp ${var.kubeconfig_path} ~/.kube/new

      # Merge new config into existing
      export KUBECONFIGBAK=$KUBECONFIG
      export KUBECONFIG=~/.kube/new:~/.kube/config
      # Do not redirect to ~/.kube/config or you may truncate the results
      kubectl config view --flatten > ~/.kube/merged
      mv -f ~/.kube/merged ~/.kube/config

      # Cleanup
      rm -f ~/.kube/new
      export KUBECONFIG=$KUBECONFIGBAK
      unset KUBECONFIGBAK
    EOF
  }
}