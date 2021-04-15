locals {
  signon_defaults = {
    backend_services = flatten([
      # TODO: Add remaining services
      local.defaults.virtual_service_backends,
    ])

    environment_variables = merge(
      local.defaults.environment_variables,
      {
        GOVUK_APP_NAME           = "signon"
        GOVUK_APP_ROOT           = "/app"
        GOVUK_STATSD_PREFIX      = "govuk-ecs.app.signon"
        RAILS_SERVE_STATIC_FILES = "true"
        REDIS_URL                = module.shared_redis_cluster.uri
      }
    )

    secrets_from_arns = merge(
      local.defaults.secrets_from_arns,
      {
        SECRET_KEY_BASE   = data.aws_secretsmanager_secret.signon_secret_key_base.arn
        SENTRY_DSN        = data.aws_secretsmanager_secret.sentry_dsn.arn
        DATABASE_URL      = data.aws_secretsmanager_secret.signon_database_url.arn
        DEVISE_PEPPER     = data.aws_secretsmanager_secret.signon_devise_pepper.arn
        DEVISE_SECRET_KEY = data.aws_secretsmanager_secret.signon_devise_secret_key.arn
      }
    )
  }
}

module "signon" {
  registry                         = var.registry
  image_name                       = "signon"
  service_name                     = "signon"
  backend_virtual_service_names    = local.signon_defaults.backend_services
  mesh_name                        = aws_appmesh_mesh.govuk.id
  service_discovery_namespace_id   = aws_service_discovery_private_dns_namespace.govuk_publishing_platform.id
  service_discovery_namespace_name = aws_service_discovery_private_dns_namespace.govuk_publishing_platform.name
  subnets                          = local.private_subnets
  vpc_id                           = local.vpc_id
  cluster_id                       = aws_ecs_cluster.cluster.id
  source                           = "../../modules/app"
  desired_count                    = var.signon_desired_count
  extra_security_groups            = [local.govuk_management_access_security_group, aws_security_group.mesh_ecs_service.id]
  load_balancers = [{
    target_group_arn = module.signon_public_alb.target_group_arn
    container_port   = 80
  }]
  environment_variables = local.signon_defaults.environment_variables
  secrets_from_arns     = local.signon_defaults.secrets_from_arns
  log_group             = local.log_group
  aws_region            = data.aws_region.current.name
  cpu                   = 512
  memory                = 1024
  task_role_arn         = aws_iam_role.task.arn
  execution_role_arn    = aws_iam_role.execution.arn
}

module "signon_public_alb" {
  source = "../../modules/public-load-balancer"

  app_name                  = "signon"
  vpc_id                    = local.vpc_id
  public_zone_id            = aws_route53_zone.workspace_public.zone_id
  dns_a_record_name         = "signon"
  public_subnets            = local.public_subnets
  external_app_domain       = local.workspace_external_domain
  certificate               = aws_acm_certificate.workspace_public.arn
  publishing_service_domain = var.publishing_service_domain
  workspace                 = local.workspace
  service_security_group_id = module.signon.security_group_id
}
