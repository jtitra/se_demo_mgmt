// Define Valid Variables
// Harness Platform
variable "account_id" {
  type = string
}

variable "org_id" {
  type = string
}

variable "api_key" {
  type      = string
  sensitive = true
}

// GCP
variable "gcp_project_id" {
  type    = string
  default = "sales-209522"
}

variable "gcp_region" {
  type    = string
  default = "us-east1"
}

variable "gcp_zone" {
  type    = string
  default = "us-east1-b"
}
