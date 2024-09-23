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
    secret_id       = "DataDogApiKeyDiego"
    secret_name     = "DataDogApiKeyDiego"
    secret_ref_name = "se_demo_DataDogApiKeyDiego"
    secret_ver      = "1"
  }
  dd_app_diego = {
    secret_id       = "DataDogAppKeyDiego"
    secret_name     = "DataDogAppKeyDiego"
    secret_ref_name = "se_demo_DataDogAppKeyDiego"
    secret_ver      = "1"
  }
  dd_api = {
    secret_id       = "DataDogAPIKey"
    secret_name     = "DataDogAPIKey"
    secret_ref_name = "se_demo_DataDogAPIKey"
    secret_ver      = "1"
  }
  dd_app = {
    secret_id       = "DataDogAppKey"
    secret_name     = "DataDogAppKey"
    secret_ref_name = "se_demo_DataDogAppKey"
    secret_ver      = "1"
  }
  docker_pw = {
    secret_id       = "docker-pw"
    secret_name     = "docker-pw"
    secret_ref_name = "se_demo_docker-pw"
    secret_ver      = "1"
  }
  appd_key = {
    secret_id       = "AppDProdKey"
    secret_name     = "AppDProdKey"
    secret_ref_name = "se_demo_AppDProdKey"
    secret_ver      = "1"
  }
  artifactory_pw = {
    secret_id       = "Artifactory-ShawnsPW"
    secret_name     = "Artifactory-ShawnsPW"
    secret_ref_name = "se_demo_Artifactory-ShawnsPW"
    secret_ver      = "1"
  }
  github_token = {
    secret_id       = "Github-danf425"
    secret_name     = "Github-danf425"
    secret_ref_name = "se_demo_Github-danf425"
    secret_ver      = "1"
  }
  jira_api_key = {
    secret_id       = "Harness_JIRA_Key"
    secret_name     = "Harness JIRA Key"
    secret_ref_name = "se_demo_Harness_JIRA_Key"
    secret_ver      = "1"
  }
  newrelic_api_key = {
    secret_id       = "NewRelic"
    secret_name     = "NewRelic"
    secret_ref_name = "se_demo_NewRelic"
    secret_ver      = "1"
  }
  snow_api_key = {
    secret_id       = "ServiceNow_API_Key"
    secret_name     = "ServiceNow API Key"
    secret_ref_name = "se_demo_ServiceNow_API_Key"
    secret_ver      = "1"
  }
  wiz_access_token = {
    secret_id       = "wiz_access_token"
    secret_name     = "wiz_access_token"
    secret_ref_name = "se_demo_wiz_access_token"
    secret_ver      = "1"
  }
  wiz_access_id = {
    secret_id       = "wiz_access_id"
    secret_name     = "wiz_access_id"
    secret_ref_name = "se_demo_wiz_access_id"
    secret_ver      = "1"
  }
  aws_secret_key = {
    secret_id       = "AWS_Secret_Access_Key"
    secret_name     = "AWS Secret Access Key"
    secret_ref_name = "se_demo_AWS_Secret_Access_Key"
    secret_ver      = "1"
  }
  aws_access_key = {
    secret_id       = "AWS_Access_Key"
    secret_name     = "AWS Access Key"
    secret_ref_name = "se_demo_AWS_Access_Key"
    secret_ver      = "1"
  }
  hcr_token = {
    secret_id       = "HCR-AccountLevel_API_Key"
    secret_name     = "HCR-AccountLevel API Key"
    secret_ref_name = "se_demo_HCR-AccountLevel_API_Key"
    secret_ver      = "1"
  }
  ssca_key = {
    secret_id       = "PlatformDemoCosignKey"
    secret_name     = "Platform Demo Cosign Key"
    secret_ref_name = "se_demo_PlatformDemoCosignKey"
    secret_ver      = "1"
  }
  ssca_pub = {
    secret_id       = "PlatformDemoCosignPub"
    secret_name     = "Platform Demo Cosign Pub"
    secret_ref_name = "se_demo_PlatformDemoCosignPub"
    secret_ver      = "1"
  }
  ssca_secret = {
    secret_id       = "PlatformDemoCosignPassword"
    secret_name     = "Platform Demo Cosign Password"
    secret_ref_name = "se_demo_PlatformDemoCosignPassword"
    secret_ver      = "1"
  }
}

// Organizations & Projects
organizations = {
  management = {
    org_name = "Management"
    org_id   = "management"
    org_desc = "Used for automated management of the SE Demo Environment."
    rg_name  = ""
    rg_id    = ""
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
    org_name = "Demo"
    org_id   = "demo"
    org_desc = "The place to be for all your demo needs."
    rg_name  = "Demo_Org Resource Group"
    rg_id    = "DemoOrg_Resource_Group"
    projects = {}
  }
  sandbox = {
    org_name = "Sandbox"
    org_id   = "sandbox"
    org_desc = "SE playground. The fun starts here!"
    rg_name  = "Sandbox_Org Resource Group"
    rg_id    = "Sandbox_Resource_Group"
    projects = {}
  }
}

// Resource Groups
sandbox_org_resource_types = [
  "AUDIT", "RESOURCEGROUP", "CCM_RECOMMENDATIONS", "GITOPS_AGENT", "IDP_CATALOG_ACCESS_POLICY",
  "ENVIRONMENT_GROUP", "IDP_SCORECARD", "IDP_INTEGRATION", "CCM_ANOMALIES", "DELEGATE",
  "SETTING", "TEMPLATE", "SERVICE", "FEATUREFLAG", "DOWNTIME", "DEPLOYMENTFREEZE",
  "USERGROUP", "NETWORK_MAP", "CCM_FOLDER", "SECRET", "CONNECTOR", "CODE_REPOSITORY",
  "CERTIFICATE", "CCM_CLOUD_ASSET_GOVERNANCE_RULE_SET", "SERVICEACCOUNT", "ENVIRONMENT",
  "IDP_ADVANCED_CONFIGURATION", "IDP_LAYOUT", "ORGANIZATION", "ROLE", "CHAOS_SECURITY_GOVERNANCE",
  "VARIABLE", "IDP_PLUGIN", "FILE", "DASHBOARDS", "GITX_WEBHOOKS", "STREAMING_DESTINATION",
  "USER", "AUTHSETTING", "DELEGATECONFIGURATION", "CCM_CLOUD_ASSET_GOVERNANCE_RULE_ENFORCEMENT"
]

// Roles
roles = {
  se_almost_admin = {
    role_name = "SE - Almost Account Admin"
    role_id   = "SE_Almost_Account_Admin"
    role_desc = "Provides the role for granting near Admin account level resources for the SEUsergroup"
    role_perms = [
      "core_deploymentfreeze_global", "core_serviceaccount_view", "core_template_view", "core_certificate_view",
      "core_resourcegroup_view", "core_secret_edit", "core_pipeline_view", "core_user_view", "core_delegateconfiguration_edit",
      "core_gitxWebhooks_edit", "core_file_delete", "core_role_view", "code_repo_reportCommitCheck", "core_environment_rollback",
      "code_repo_review", "core_audit_view", "core_file_access", "core_secret_delete", "core_delegateconfiguration_view",
      "core_authsetting_view", "core_organization_view", "core_delegate_delete", "core_template_edit", "core_secret_view",
      "code_repo_push", "core_project_edit", "core_secret_access", "core_account_edit", "core_environmentgroup_edit", "core_service_view",
      "core_certificate_edit", "core_setting_edit", "code_repo_edit", "core_service_edit", "code_repo_delete", "core_dashboards_edit",
      "core_gitxWebhooks_delete", "core_account_view", "core_environmentgroup_access", "core_delegateconfiguration_delete",
      "core_environment_view", "core_serviceaccount_delete", "core_service_delete", "core_deploymentfreeze_override", "core_usergroup_view",
      "core_environmentgroup_view", "core_connector_view", "core_environmentgroup_delete", "core_template_copy", "code_repo_view",
      "core_certificate_delete", "core_variable_edit", "core_environment_access", "core_serviceaccount_manageapikey",
      "core_environment_delete", "core_streamingDestination_view", "core_file_view", "core_delegate_view", "core_template_access",
      "core_variable_delete", "core_pipeline_delete", "core_dashboards_view", "core_project_view", "core_connector_edit",
      "core_service_access", "core_deploymentfreeze_manage", "core_pipeline_edit", "core_template_delete", "core_connector_access",
      "core_pipeline_execute", "core_serviceaccount_edit", "core_delegate_edit", "core_variable_view", "core_environment_edit",
      "core_connector_delete", "core_file_edit", "core_gitxWebhooks_view"
    ]
  }
  se_account_level = {
    role_name = "SE - Account Level Resources"
    role_id   = "SE_Account_Level_Resources"
    role_desc = "Provides the role for managing account level resources for the SEUsergroup"
    role_perms = [
      "ccm_autoStoppingRule_delete", "core_certificate_view", "sei_seiinsights_delete", "ccm_recommendations_view", "sei_seicollections_create",
      "idp_scorecard_view", "idp_advancedconfiguration_delete", "core_role_view", "ccm_costCategory_edit", "sei_seiinsights_edit",
      "code_repo_reportCommitCheck", "core_audit_view", "idp_plugin_toggle", "ccm_perspective_edit", "sei_seiconfigurationsettings_edit",
      "core_organization_view", "ccm_commitmentOrchestrator_view", "ccm_budget_view", "ccm_cloudAssetGovernanceEnforcement_edit",
      "sei_seiconfigurationsettings_delete", "iac_workspace_view", "ccm_cloudAssetGovernanceRule_delete", "ccm_perspective_delete",
      "ccm_anomalies_view", "idp_integration_delete", "core_environment_view", "ccm_overview_view", "idp_advancedconfiguration_edit",
      "core_usergroup_view", "idp_integration_edit", "ccm_folder_view", "core_template_copy", "idp_plugin_edit", "ccm_loadBalancer_edit",
      "core_file_view", "idp_scorecard_delete", "sei_seicollections_view", "sei_seiconfigurationsettings_create", "ccm_budget_edit",
      "core_dashboards_view", "ccm_costCategory_delete", "core_project_view", "idp_catalogaccesspolicy_edit", "core_service_access",
      "core_connector_access", "core_variable_view", "ccm_loadBalancer_delete", "ccm_cloudAssetGovernanceRule_view", "core_gitxWebhooks_view",
      "ccm_cloudAssetGovernanceRule_execute", "core_serviceaccount_view", "core_template_view", "core_resourcegroup_view",
      "ccm_commitmentOrchestrator_edit", "idp_catalogaccesspolicy_create", "core_pipeline_view", "core_user_view", "idp_integration_create",
      "ccm_cloudAssetGovernanceRuleSet_view", "core_environment_rollback", "code_repo_review", "ssca_remediationtracker_view", "core_file_access",
      "idp_scorecard_edit", "core_delegateconfiguration_view", "core_authsetting_view", "ccm_cloudAssetGovernanceRule_edit",
      "ccm_cloudAssetGovernanceRuleSet_delete", "core_secret_view", "code_repo_push", "core_secret_access", "ccm_currencyPreference_edit",
      "core_service_view", "idp_layout_edit", "ccm_cloudAssetGovernanceEnforcement_delete", "sei_seiinsights_view", "ccm_folder_delete",
      "ccm_autoStoppingRule_edit", "core_dashboards_edit", "core_account_view", "ccm_cloudAssetGovernanceEnforcement_view",
      "core_environmentgroup_view", "core_connector_view", "ccm_autoStoppingRule_view", "sei_seiinsights_create", "idp_layout_view",
      "code_repo_view", "core_environment_access", "core_streamingDestination_view", "ccm_budget_delete", "idp_plugin_delete",
      "idp_catalogaccesspolicy_delete", "sei_seicollections_delete", "ccm_folder_edit", "ccm_currencyPreference_view",
      "idp_advancedconfiguration_view", "core_delegate_view", "core_template_access", "idp_catalogaccesspolicy_view", "idp_integration_view",
      "core_deploymentfreeze_manage", "sei_seicollections_edit", "idp_plugin_view", "ccm_costCategory_view", "sei_seiconfigurationsettings_view",
      "ccm_loadBalancer_view", "ccm_cloudAssetGovernanceRuleSet_edit", "ccm_perspective_view"
    ]
  }
}

// User Groups
groups = {
  sales_eng = {
    group_name = "SalesEngineers"
    group_id   = "SalesEngineers"
    group_desc = "Default role for all SEs. Provides access to the \"Demo\" and \"Sandbox\" organizations with default roles"
  }
  temp_admin = {
    group_name = "TempAdmin"
    group_id   = "TempAdmin"
    group_desc = "Used to grant temporary admin access for product to help troubleshoot. Should be purged weekly."
  }
}

// Role Binding
role_bindings = {
  se_demo_org = {
    rg_id     = "DemoOrg_Resource_Group"
    role_id   = "SE_Almost_Account_Admin"
    prin_id   = "SalesEngineers"
    prin_type = "USER_GROUP"
  }
  se_sandbox_org = {
    rg_id     = "Sandbox_Resource_Group"
    role_id   = "_account_admin"
    prin_id   = "SalesEngineers"
    prin_type = "USER_GROUP"
  }
  se_account_level = {
    rg_id     = "_all_account_level_resources"
    role_id   = "SE_Account_Level_Resources"
    prin_id   = "SalesEngineers"
    prin_type = "USER_GROUP"
  }
  temp_admin = {
    rg_id     = "_all_resources_including_child_scopes"
    role_id   = "_account_admin"
    prin_id   = "TempAdmin"
    prin_type = "USER_GROUP"
  }
}

// Workspace
workspace = {
  prov_type      = "opentofu"
  prov_version   = "1.8.1"
  prov_connector = "account.GCP_Sales_Admin"
  repo_name      = "jtitra/se_demo_mgmt"
  repo_branch    = "main"
  repo_path      = "terraform/org_setup"
  repo_api_key   = "github_token" // "account.Github-danf425"
}

// Audit Config
audit_config = {
  k8s_conn_id     = "sedemoproject0ns"
  k8s_conn_name   = "se-demo-project0-ns"
  k8s_conn_desc   = "Used by the Audit_Events pipeline"
  k8s_conn_url    = "https://35.237.6.220"
  k8s_conn_sa_ref = "project0-k8s-user"
  k8s_conn_ca_ref = "project0-k8s-ca-data"
}
