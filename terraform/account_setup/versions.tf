// Version requirements or limitations 
// As well as location to define remote backend for storing state
terraform {

  required_providers {
    harness = {
      source  = "harness/harness"
      version = "0.31.8" #"0.40.2"
    }
    google = {
      source  = "hashicorp/google"
      version = "6.0.1"
    }
  }

  backend "http" {
    address = "https://app.harness.io/gateway/iacm/api/orgs/default/projects/default_project/workspaces/Project0/terraform-backend?accountIdentifier=EeRjnXTnS4GrLG5VNNJZUw"
    username = "harness"
    lock_address = "https://app.harness.io/gateway/iacm/api/orgs/default/projects/default_project/workspaces/Project0/terraform-backend/lock?accountIdentifier=EeRjnXTnS4GrLG5VNNJZUw"
    lock_method = "POST"
    unlock_address = "https://app.harness.io/gateway/iacm/api/orgs/default/projects/default_project/workspaces/Project0/terraform-backend/lock?accountIdentifier=EeRjnXTnS4GrLG5VNNJZUw"
    unlock_method = "DELETE"
  }
}
