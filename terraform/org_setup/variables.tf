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

// Environments, Infrastructures, & Services
variable "environments" {
  type = map(object({
    env_name       = string
    env_identifier = string
    env_type       = string
    infrastructures = map(object({
      infra_name       = string
      infra_identifier = string
      namespace        = string
      services = map(object({
        serv_name           = string
        serv_identifier     = string
        artifact_identifier = string
        artifact_tag        = string
      }))
    }))
  }))
}

// Projects
variable "projects" {
  type = map(object({
    proj_name  = string
    proj_id    = string
    proj_desc  = string
    proj_color = string
  }))
}

// Repos
variable "repos" {
  type = map(object({
    repo_id        = string
    default_branch = string
    source_repo    = string
    source_type    = string
  }))
}

// Org Policies
variable "org_policies" {
  type = map(object({
    pol_type = string
    pol_rego = string
  }))
}
