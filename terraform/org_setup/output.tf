// Output After Run
output "gcloud_kubeconfig_command" {
  value       = "gcloud container clusters get-credentials se-demo --region us-east1-b --project sales-209522"
  description = "Command to create kubeconfig and connect to the GKE cluster"
}
