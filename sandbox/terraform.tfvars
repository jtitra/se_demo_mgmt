// Harness Platform
account_id = "EeRjnXTnS4GrLG5VNNJZUw"
org_id     = "sandbox"


// Environments & Infrastructures
environments = {
  dev = {
    env_name         = "Dev"
    env_identifier   = "dev"
    env_type         = "PreProduction"
    infra_name       = "K8s Dev"
    infra_identifier = "k8s_dev"
    namespace        = "boutique-dev"
  }
  qa = {
    env_name         = "QA"
    env_identifier   = "qa"
    env_type         = "PreProduction"
    infra_name       = "K8s QA"
    infra_identifier = "k8s_qa"
    namespace        = "boutique-qa"
  }
  prod = {
    env_name         = "Prod"
    env_identifier   = "prod"
    env_type         = "Production"
    infra_name       = "K8s Prod"
    infra_identifier = "k8s_prod"
    namespace        = "boutique-prod"
  }
}
