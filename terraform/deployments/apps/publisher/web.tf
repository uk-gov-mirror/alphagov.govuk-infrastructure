module "web_container_definition" {
  source = "../../../modules/app-container-definition"
  name   = "web-publisher"
  image  = var.image_tag
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

module "web_envoy_configuration" {
  source = "../../../modules/envoy-configuration"

  mesh_name    = local.mesh_name
  service_name = "web-publisher"
  log_group    = local.log_group
  aws_region   = data.aws_region.current.name
}

resource "aws_ecs_task_definition" "web" {
  family                   = "web-publisher"
  requires_compatibilities = ["FARGATE"]
  container_definitions = jsonencode([
    module.web_container_definition.value,
    module.web_envoy_configuration.container_definition,
  ])

  network_mode       = "awsvpc"
  cpu                = 512
  memory             = 1024
  task_role_arn      = local.fargate_task_iam_role_arn
  execution_role_arn = local.fargate_execution_iam_role_arn

  proxy_configuration {
    type           = "APPMESH"
    container_name = "envoy"
    properties     = module.web_envoy_configuration.proxy_properties
  }
}