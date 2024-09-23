// Harness Platform
account_id = "EeRjnXTnS4GrLG5VNNJZUw"
org_id     = "demo"

// GKE Cluster & Node Pool
gke_min_node_count = 1
gke_max_node_count = 10
gke_machine_type   = "e2-standard-8"
resource_owner     = "dan"

// Secrets
secrets = {
  dd_api_diego = {
    secret_id = "DataDogApiKeyDiego"
    secret_name = "DataDogApiKeyDiego"
    secret_ref_name = "se_demo_DataDogApiKeyDiego"
    secret_ver = "1"
  }
  dd_app_diego = {
    secret_id = "DataDogAppKeyDiego"
    secret_name = "DataDogAppKeyDiego"
    secret_ref_name = "se_demo_DataDogAppKeyDiego"
    secret_ver = "1"
  }
}

// Organizations & Projects
organizations = {
  management = {
    org_name  = "Management"
    org_id    = "management"
    org_desc  = "Used for automated management of the SE Demo Environment."
    projects = {
      proj0 = {
        proj_name  = "Project0"
        proj_id    = "Project0"
        proj_desc  = "It all starts here..."
        proj_color = "#FFCC00" # YELLOW
      }
    }
  }
  demo = {
    org_name  = "Demo"
    org_id    = "demo"
    org_desc  = "The place to be for all your demo needs."
    projects = {}
  }
  sandbox = {
    org_name  = "Sandbox"
    org_id    = "sandbox"
    org_desc  = "SE playground. The fun starts here!"
    projects = {}
  }
}
