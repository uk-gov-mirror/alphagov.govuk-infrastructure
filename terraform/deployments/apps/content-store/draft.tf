module "draft_container_definition" {
  source = "../../../modules/app-container-definition"

  name              = "draft-content-store"
  image             = "govuk/content-store:${local.image_tag}"
  log_group         = "awslogs-fargate"             # TODO - make this something better, like "govuk-${terraform.workspace}"
  log_stream_prefix = "awslogs-draft-content-store" # TODO - remove the awslogs prefix
  secrets_from_arns = local.secrets
  environment = merge(
    local.environment,
    { "PLEK_SERVICE_ROUTER_API_URI" : "http://draft-router-api.${var.mesh_domain}" }
  )
}

module "draft_envoy_settings" {
  source       = "../../../modules/envoy-settings"
  mesh_name    = var.mesh_name
  service_name = "draft-content-store"
}

resource "aws_ecs_task_definition" "draft" {
  family                   = "content-store"
  requires_compatibilities = ["FARGATE"]
  container_definitions = jsonencode([
    module.draft_container_definition.value,
    module.draft_envoy_settings.container_definition,
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

output "draft_task_definition_arn" {
  value       = aws_ecs_task_definition.draft.arn
  description = "ARN of the task definition revision"
}

