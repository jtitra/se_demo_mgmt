// Define the resources to create
// Provisions the following resources: 
//    GKE Cluster, GKE Node Pool
//    Organizations, Projects

locals {
  gke_cluster_name = lower(join("-", ["se", var.org_id]))
  resource_purpose = lower(join("-", ["official-se", var.org_id]))
  organization_projects_list = flatten([
    for org_key, org_value in var.organizations : [
      for proj_key, proj_value in org_value.projects : {
        org_key    = org_key
        org_value  = org_value
        proj_key   = proj_key
        proj_value = proj_value
      }
    ]
  ])
  organization_projects = {
    for item in local.organization_projects_list :
    "${item.org_key}_${item.proj_key}" => {
      org_key  = item.org_key
      env      = item.org_value
      proj_key = item.proj_key
      proj     = item.proj_value
    }
  }
}

// Organizations
resource "harness_platform_organization" "orgs" {
  for_each = var.organizations

  identifier  = each.value.org_id
  name        = each.value.org_name
  description = each.value.org_desc
}

// Projects
resource "harness_platform_project" "project" {
  for_each = local.organization_projects

  identifier  = each.value.proj.proj_id
  name        = each.value.proj.proj_name
  description = each.value.proj.proj_desc
  org_id      = each.key
  color       = each.value.proj.proj_color
}

