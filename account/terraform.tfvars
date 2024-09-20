// Harness Platform
account_id = "EeRjnXTnS4GrLG5VNNJZUw"
org_id     = "default"

// GKE Cluster & Node Pool
gke_min_node_count = 1
gke_max_node_count = 10
gke_machine_type   = "e2-standard-8"
resource_owner     = "dan"

// Organizations
organizations = {
  mgmt = {
    org_name  = "Management"
    org_id    = "Management"
    org_desc  = "Used for automated management of the SE Demo Environment."
  }
  demo = {
    org_name  = "Demo"
    org_id    = "Demo"
    org_desc  = "The place to be for all your demo needs."
  }
  sandbox = {
    org_name  = "Sandbox"
    org_id    = "Sandbox"
    org_desc  = "SE playground. The fun starts here!"
  }
}

// Projects
projects = {
  proj0 = {
    proj_name  = "Project0"
    proj_id    = "Project0"
    proj_desc  = "It all starts here..."
    proj_color = "#FFCC00" # YELLOW
  }
}



