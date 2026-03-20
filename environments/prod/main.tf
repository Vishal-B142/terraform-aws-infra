module "ecr_gateway" {
  source          = "../../modules/ecr"
  repository_name = "app/gateway-service"
  environment     = "prod"
}

module "ecr_auth" {
  source          = "../../modules/ecr"
  repository_name = "app/auth-service"
  environment     = "prod"
}

# Add one module block per service:
# module "ecr_<service>" {
#   source          = "../../modules/ecr"
#   repository_name = "app/<service-name>"
#   environment     = "prod"
# }
