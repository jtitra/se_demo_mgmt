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
  dd_api = {
    secret_id = "DataDogAPIKey"
    secret_name = "DataDogAPIKey"
    secret_ref_name = "se_demo_DataDogAPIKey"
    secret_ver = "1"
  }
  dd_app = {
    secret_id = "DataDogAppKey"
    secret_name = "DataDogAppKey"
    secret_ref_name = "se_demo_DataDogAppKey"
    secret_ver = "1"
  }
  docker_pw = {
    secret_id = "docker-pw"
    secret_name = "docker-pw"
    secret_ref_name = "se_demo_docker-pw"
    secret_ver = "1"
  }
  appd_key = {
    secret_id = "AppDProdKey"
    secret_name = "AppDProdKey"
    secret_ref_name = "se_demo_AppDProdKey"
    secret_ver = "1"
  }
  artifactory_pw = {
    secret_id = "Artifactory-ShawnsPW"
    secret_name = "Artifactory-ShawnsPW"
    secret_ref_name = "se_demo_Artifactory-ShawnsPW"
    secret_ver = "1"
  }
  github_token = {
    secret_id = "Github-danf425"
    secret_name = "Github-danf425"
    secret_ref_name = "se_demo_Github-danf425"
    secret_ver = "1"
  }
  jira_api_key = {
    secret_id = "Harness_JIRA_Key"
    secret_name = "Harness JIRA Key"
    secret_ref_name = "se_demo_Harness_JIRA_Key"
    secret_ver = "1"
  }
  newrelic_api_key = {
    secret_id = "NewRelic"
    secret_name = "NewRelic"
    secret_ref_name = "se_demo_NewRelic"
    secret_ver = "1"
  }
  snow_api_key = {
    secret_id = "ServiceNow_API_Key"
    secret_name = "ServiceNow API Key"
    secret_ref_name = "se_demo_ServiceNow_API_Key"
    secret_ver = "1"
  }
  wiz_access_token = {
    secret_id = "wiz_access_token"
    secret_name = "wiz_access_token"
    secret_ref_name = "se_demo_wiz_access_token"
    secret_ver = "1"
  }
  wiz_access_id = {
    secret_id = "wiz_access_id"
    secret_name = "wiz_access_id"
    secret_ref_name = "se_demo_wiz_access_id"
    secret_ver = "1"
  }
  aws_secret_key = {
    secret_id = "AWS_Secret_Access_Key"
    secret_name = "AWS Secret Access Key"
    secret_ref_name = "se_demo_AWS_Secret_Access_Key"
    secret_ver = "1"
  }
  aws_access_key = {
    secret_id = "AWS_Access_Key"
    secret_name = "AWS Access Key"
    secret_ref_name = "se_demo_AWS_Access_Key"
    secret_ver = "1"
  }
  hcr_token = {
    secret_id = "HCR-AccountLevel_API_Key"
    secret_name = "HCR-AccountLevel API Key"
    secret_ref_name = "se_demo_HCR-AccountLevel_API_Key"
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
