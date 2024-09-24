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
    rg_name  = string
    rg_id    = string
    projects = map(object({
      proj_name  = string
      proj_id    = string
      proj_desc  = string
      proj_color = string
    }))
  }))
}

// Resource Groups
variable "sandbox_org_resource_types" {
  type = list(string)
}

// Roles
variable "roles" {
  type = map(object({
    role_name  = string
    role_id    = string
    role_desc  = string
    role_perms = list(string)
  }))
}

// User Groups
variable "groups" {
  type = map(object({
    group_name = string
    group_id   = string
    group_desc = string
    group_members = list(string)
  }))
}

// Role Binding
variable "role_bindings" {
  type = map(object({
    rg_id     = string
    role_id   = string
    prin_id   = string
    prin_type = string
  }))
}

// Workspace
variable "workspace" {
  type = object({
    prov_type      = string
    prov_version   = string
    prov_connector = string
    repo_name      = string
    repo_branch    = string
    repo_path      = string
    repo_api_key   = string
  })
}

// Audit Config
variable "audit_config" {
  type = object({
    k8s_conn_id     = string
    k8s_conn_name   = string
    k8s_conn_desc   = string
    k8s_conn_url    = string
    k8s_conn_sa_ref = string
    k8s_conn_ca_ref = string
  })
}
