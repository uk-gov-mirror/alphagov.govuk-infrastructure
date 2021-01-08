module "live_container_definition" {
  source = "../../../modules/app-container-definition"
  name   = "live-frontend"
  image  = "govuk/frontend:#{var.image_tag}" # TODO use "govuk/content-store:${var.image_tag}"
  environment_variables = merge(
    local.environment_variables,
    {
    },
  )
  log_group             = data.terraform_remote_state.govuk.outputs.log_group
  secrets_from_arns     = local.secrets_from_arns
  aws_region            = data.aws_region.current.name
  depends_on_containers = { envoy : "START" }
}

module "live_envoy_configuration" {
  source = "../../../modules/envoy-configuration"

  mesh_name    = local.mesh_name
  service_name = "live-frontend"
  log_group    = local.log_group
  aws_region   = data.aws_region.current.name
}

resource "aws_ecs_task_definition" "live" {
  family                   = "frontend"
  requires_compatibilities = ["FARGATE"]
  container_definitions = jsonencode([
    module.live_container_definition.value,
    module.live_envoy_configuration.container_definition,
  ])

  network_mode       = "awsvpc"
  cpu                = 512
  memory             = 1024
  task_role_arn      = local.fargate_task_iam_role_arn
  execution_role_arn = local.fargate_execution_iam_role_arn

  proxy_configuration {
    type           = "APPMESH"
    container_name = "envoy"
    properties     = module.live_envoy_configuration.proxy_properties
  }
}


