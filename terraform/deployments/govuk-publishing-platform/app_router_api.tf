locals {
  router_api_defaults = {
    cpu    = 512  # TODO parameterize this
    memory = 1024 # TODO parameterize this

    backend_services = flatten([
      local.defaults.virtual_service_backends,
      module.signon.virtual_service_names,
    ])

    environment_variables = merge(
      local.defaults.environment_variables,
      {
        GOVUK_APP_NAME          = "router-api",
        GOVUK_APP_ROOT          = "/var/apps/router-api",
        PLEK_SERVICE_SIGNON_URI = local.defaults.signon_uri,
      }
    )

    secrets_from_arns = local.defaults.secrets_from_arns

    mongodb_url = format(
      "mongodb://%s,%s,%s",
      data.terraform_remote_state.govuk_aws_router_mongo.outputs.router_backend_1_service_dns_name,
      data.terraform_remote_state.govuk_aws_router_mongo.outputs.router_backend_2_service_dns_name,
      data.terraform_remote_state.govuk_aws_router_mongo.outputs.router_backend_3_service_dns_name,
    )
  }
}


module "router_api" {
  source                           = "../../modules/app"
  registry                         = var.registry
  image_name                       = "router-api"
  service_name                     = "router-api"
  backend_virtual_service_names    = local.router_api_defaults.backend_services
  mesh_name                        = aws_appmesh_mesh.govuk.id
  service_discovery_namespace_id   = aws_service_discovery_private_dns_namespace.govuk_publishing_platform.id
  service_discovery_namespace_name = aws_service_discovery_private_dns_namespace.govuk_publishing_platform.name
  cluster_id                       = aws_ecs_cluster.cluster.id
  vpc_id                           = local.vpc_id
  subnets                          = local.private_subnets
  desired_count                    = var.router_api_desired_count
  extra_security_groups            = [local.govuk_management_access_security_group, aws_security_group.mesh_ecs_service.id]
  environment_variables = merge(
    local.router_api_defaults.environment_variables,
    {
      MONGODB_URI = "${local.router_api_defaults.mongodb_url}/router",
    },
  )
  secrets_from_arns = merge(
    local.router_api_defaults.secrets_from_arns,
    {
      GDS_SSO_OAUTH_ID     = data.aws_secretsmanager_secret.router_api_oauth_id.arn,
      GDS_SSO_OAUTH_SECRET = data.aws_secretsmanager_secret.router_api_oauth_secret.arn,
      SECRET_KEY_BASE      = data.aws_secretsmanager_secret.router_api_secret_key_base.arn,
    },
  )
  log_group          = local.log_group
  aws_region         = data.aws_region.current.name
  cpu                = local.router_api_defaults.cpu
  memory             = local.router_api_defaults.memory
  task_role_arn      = aws_iam_role.task.arn
  execution_role_arn = aws_iam_role.execution.arn
}

module "draft_router_api" {
  source = "../../modules/app"

  registry                         = var.registry
  image_name                       = "router-api"
  service_name                     = "draft-router-api"
  backend_virtual_service_names    = local.router_api_defaults.backend_services
  mesh_name                        = aws_appmesh_mesh.govuk.id
  service_discovery_namespace_id   = aws_service_discovery_private_dns_namespace.govuk_publishing_platform.id
  service_discovery_namespace_name = aws_service_discovery_private_dns_namespace.govuk_publishing_platform.name
  cluster_id                       = aws_ecs_cluster.cluster.id
  vpc_id                           = local.vpc_id
  subnets                          = local.private_subnets
  desired_count                    = var.draft_router_api_desired_count
  extra_security_groups            = [local.govuk_management_access_security_group, aws_security_group.mesh_ecs_service.id]
  environment_variables = merge(
    local.router_api_defaults.environment_variables,
    {
      MONGODB_URI = "${local.router_api_defaults.mongodb_url}/draft_router",
    },
  )
  secrets_from_arns = merge(
    local.router_api_defaults.secrets_from_arns,
    {
      GDS_SSO_OAUTH_ID     = data.aws_secretsmanager_secret.draft_router_api_oauth_id.arn,
      GDS_SSO_OAUTH_SECRET = data.aws_secretsmanager_secret.draft_router_api_oauth_secret.arn,
      SECRET_KEY_BASE      = data.aws_secretsmanager_secret.draft_router_api_secret_key_base.arn,
    },
  )
  log_group          = local.log_group
  aws_region         = data.aws_region.current.name
  cpu                = local.router_api_defaults.cpu
  memory             = local.router_api_defaults.memory
  task_role_arn      = aws_iam_role.task.arn
  execution_role_arn = aws_iam_role.execution.arn
}
