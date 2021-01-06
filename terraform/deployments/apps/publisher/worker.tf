module "worker_container_definition" {
  source = "../../../modules/app-container-definition"
  name   = "worker-publisher"
  image  = "govuk/publisher:bill-content-schemas" # TODO use "govuk/publisher:${var.image_tag}"
  environment_variables = merge(
    local.environment_variables,
    {
    },
  )
  log_group             = local.log_group
  secrets_from_arns     = local.secrets_from_arns
  aws_region            = data.aws_region.current.name
  depends_on_containers = { envoy : "START" }
}

module "worker_envoy_configuration" {
  source = "../../../modules/envoy-configuration"

  mesh_name    = local.mesh_name
  service_name = "worker-publisher"
  log_group    = local.log_group
  aws_region   = data.aws_region.current.name
}

resource "aws_ecs_task_definition" "worker" {
  family                   = "worker-publisher"
  requires_compatibilities = ["FARGATE"]
  container_definitions = jsonencode([
    module.worker_container_definition.value,
    module.worker_envoy_configuration.container_definition,
  ])

  network_mode       = "awsvpc"
  cpu                = 512
  memory             = 1024
  task_role_arn      = local.fargate_task_iam_role_arn
  execution_role_arn = local.fargate_execution_iam_role_arn

  proxy_configuration {
    type           = "APPMESH"
    container_name = "envoy"
    properties     = module.worker_envoy_configuration.proxy_properties
  }
}