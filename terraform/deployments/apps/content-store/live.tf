module "live_container_definition" {
  source = "../../../modules/app-container-definition"

  name              = "content-store"
  image             = "govuk/content-store:${local.image_tag}"
  log_group         = "awslogs-fargate"       # TODO - make this something better, like "govuk-${terraform.workspace}"
  log_stream_prefix = "awslogs-content-store" # TODO - remove the awslogs prefix
  secrets_from_arns = local.secrets
  environment       = local.environment
}

module "live_envoy_settings" {
  source       = "../../../modules/envoy-settings"
  mesh_name    = var.mesh_name
  service_name = "content-store"
}

resource "aws_ecs_task_definition" "live" {
  family                   = "content-store"
  requires_compatibilities = ["FARGATE"]
  container_definitions = jsonencode([
    module.live_container_definition.value,
    module.live_envoy_settings.container_definition,
  ])

  network_mode       = "awsvpc"
  cpu                = 512
  memory             = 1024
  task_role_arn      = data.aws_iam_role.task.arn
  execution_role_arn = data.aws_iam_role.execution.arn

  proxy_configuration {
    type           = "APPMESH"
    container_name = "envoy"
    properties     = module.draft_envoy_settings.proxy_properties
  }
}

output "live_task_definition_arn" {
  value       = aws_ecs_task_definition.live.arn
  description = "ARN of the task definition revision"
}
