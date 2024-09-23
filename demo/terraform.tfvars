// Harness Platform
account_id = "EeRjnXTnS4GrLG5VNNJZUw"
org_id     = "demo"

// Environments, Infrastructures, & Services
environments = {
  dev = {
    env_name       = "Dev"
    env_identifier = "dev"
    env_type       = "PreProduction"
    infrastructures = {
      boutique = {
        infra_name       = "Boutique Dev"
        infra_identifier = "boutiquedev"
        namespace        = "boutique-dev"
        services = {
          boutique_pm = {
            serv_name           = "Boutique - PMService"
            serv_identifier     = "Boutique_PMService_dev"
            artifact_identifier = "tbd"
            artifact_tag        = "tbd"
          }
        }
      }
      devsecops = {
        infra_name       = "DevSecOps"
        infra_identifier = "devsecops"
        namespace        = "devsecops"
        services = {
          devsec_frontend = {
            serv_name           = "DevSecOps - Frontend"
            serv_identifier     = "DevSecOps_Frontend"
            artifact_identifier = "frontend"
            artifact_tag        = "0.0.<+pipeline.sequenceId>"
          }
          devsec_backend = {
            serv_name           = "DevSecOps - Backend"
            serv_identifier     = "DevSecOps_Backend"
            artifact_identifier = "backend"
            artifact_tag        = "backend-latest"
          }
        }
      }
    }
  }
  qa = {
    env_name       = "QA"
    env_identifier = "qa"
    env_type       = "PreProduction"
    infrastructures = {
      boutique = {
        infra_name       = "Boutique QA"
        infra_identifier = "boutiqueqa"
        namespace        = "boutique-qa"
        services = {
          boutique_pm = {
            serv_name           = "Boutique - PMService"
            serv_identifier     = "Boutique_PMSerivce_qa"
            artifact_identifier = "tbd"
            artifact_tag        = "tbd"
          }
        }
      }
    }
  }
  prod = {
    env_name       = "Prod"
    env_identifier = "prod"
    env_type       = "Production"
    infrastructures = {
      boutique = {
        infra_name       = "Boutique Prod"
        infra_identifier = "boutiqueprod"
        namespace        = "boutique-prod"
        services = {
          boutique_pm = {
            serv_name           = "Boutique - PMService"
            serv_identifier     = "Boutique_PMSerivce_prod"
            artifact_identifier = "tbd"
            artifact_tag        = "tbd"
          }
        }
      }
    }
  }
}

// Projects
projects = {
  plat = {
    proj_name  = "Platform Engineering"
    proj_id    = "Platform_Engineering"
    proj_desc  = "Simplify your developer experience with the world's first AI-augmented software delivery platform"
    proj_color = "#FF8800" # ORANGE
  }
  arch = {
    proj_name  = "Reference Architecture"
    proj_id    = "Reference_Architecture"
    proj_desc  = "Templates and Pipelines for a variety of CI and CD use-cases"
    proj_color = "#0063F7" # BLUE
  }
  temp = {
    proj_name  = "TEMP"
    proj_id    = "TEMP"
    proj_desc  = "Only visible to #demo-working-group and used for manual testing of new features and demo flows before we migrate them to the proper project as-code"
    proj_color = "#28293D" # DARK
  }
}

// Repos
repos = {
  devsecops = {
    repo_id        = "devsecops"
    default_branch = "main"
    source_repo    = "harness-community/unscripted-workshop-2024"
    source_type    = "github"
  }
}
