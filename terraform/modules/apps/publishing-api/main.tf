terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.69"
    }
  }
}

resource "aws_ecs_task_definition" "service" {
  family                   = var.service_name
  requires_compatibilities = ["FARGATE"]
  container_definitions    = file("${path.module}/publishing-api.json")
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  task_role_arn            = var.task_role_arn
  execution_role_arn       = var.execution_role_arn

  proxy_configuration {
    type           = "APPMESH"
    container_name = "envoy"

    properties = {
      AppPorts         = var.container_ingress_port
      EgressIgnoredIPs = "169.254.170.2,169.254.169.254"
      IgnoredUID       = "1337"
      ProxyEgressPort  = 15001
      ProxyIngressPort = 15000
    }
  }
}

resource "aws_ecs_service" "service" {
  name            = var.service_name
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.service.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [
      aws_security_group.service.id,
      var.govuk_management_access_security_group,
      data.aws_security_group.service_dependencies.id,
      aws_security_group.dependencies.id
    ]
    subnets = var.private_subnets
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.service.arn
    container_name = var.service_name
  }

  depends_on = [aws_service_discovery_service.service]
}

#
# ECS Service Security groups
#

resource "aws_security_group" "service" {
  name        = "fargate_${var.service_name}_ingress"
  vpc_id      = var.vpc_id
  description = "Permit internal services to access the ${var.service_name} ECS service"
}

resource "aws_security_group" "dependencies" {
  name        = "fargate_${var.service_name}_app"
  vpc_id      = var.vpc_id
  description = "Allows ingress from ${var.service_name} to its dependencies"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#
# Dependencies
#

data "aws_security_group" "service_dependencies" {
  id = "sg-05ad7398fc0d7c5b4" # legacy govuk-aws group: govuk_publishing-api_access
}
