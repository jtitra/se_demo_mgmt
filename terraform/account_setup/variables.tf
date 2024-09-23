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

// GKE Cluster & Node Pool
variable "gke_min_node_count" {
  type = string
}

variable "gke_max_node_count" {
  type = string
}

variable "gke_machine_type" {
  type = string
}

variable "resource_owner" {
  type = string
}

// Secrets
variable "secrets" {
  type = map(object({
    secret_name     = string
    secret_id       = string
    secret_ref_name = string
    secret_ver      = string
  }))
}

// Organizations & Projects
variable "organizations" {
  type = map(object({
    org_name = string
    org_id   = string
    org_desc = string
    projects = map(object({
      proj_name  = string
      proj_id    = string
      proj_desc  = string
      proj_color = string
    }))
  }))
}
