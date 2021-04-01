locals {
  prometheus_server_port = 9090
  prometheus_ecs_log_options = {
    "awslogs-create-group" : "true", # TODO: create the log group in TF so we can configure the retention policy.
    "awslogs-group" : "ecs/${terraform.workspace}/prometheus",
    "awslogs-region" : data.aws_region.current.name,
  }
}

resource "aws_prometheus_workspace" "prometheus" {
  alias = "prometheus-${terraform.workspace}"
}

module "prometheus_public_alb" {
  source = "../../modules/public-load-balancer"

  app_name                  = "prometheus"
  vpc_id                    = local.vpc_id
  public_zone_id            = aws_route53_zone.workspace_public.zone_id
  dns_a_record_name         = "prometheus"
  public_subnets            = local.public_subnets
  external_app_domain       = local.workspace_external_domain
  certificate               = aws_acm_certificate.workspace_public.arn
  publishing_service_domain = var.publishing_service_domain
  workspace                 = local.workspace
  service_security_group_id = aws_security_group.prometheus.id
  external_cidrs_list       = var.office_cidrs_list
}

resource "aws_ecs_service" "prometheus" {
  name          = "prometheus"
  cluster       = aws_ecs_cluster.cluster.id
  launch_type   = "FARGATE"
  desired_count = 2

  load_balancer {
    target_group_arn = module.prometheus_public_alb.target_group_arn
    container_name   = "prometheus"
    container_port   = local.prometheus_server_port
  }

  network_configuration {
    security_groups = [aws_security_group.prometheus.id, aws_security_group.mesh_ecs_service.id]
    subnets         = local.private_subnets
  }

  task_definition = aws_ecs_task_definition.prometheus.arn
}

resource "aws_ecs_task_definition" "prometheus" {
  family                   = "prometheus"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  task_role_arn            = aws_iam_role.prometheus_task.arn
  execution_role_arn       = aws_iam_role.execution.arn
  volume { name = "configVolume" }
  volume { name = "logsVolume" }
  container_definitions = jsonencode([
    {
      "name" : "prometheus-server",
      "image" : "quay.io/prometheus/prometheus:v2.26.0", # TODO: hardcoded version
      "user" : "root",                                   # TODO: don't run as root; fix mount permissions.
      "essential" : true,
      "dependsOn" : [
        { "containerName" : "config-reloader", "condition" : "START" },
        { "containerName" : "aws-iamproxy", "condition" : "START" }
      ],
      "command" : [
        "--storage.tsdb.retention.time=15d",
        "--config.file=/etc/config/prometheus.yaml",
        "--storage.tsdb.path=/data",
        "--web.console.libraries=/etc/prometheus/console_libraries",
        "--web.console.templates=/etc/prometheus/consoles",
        "--web.enable-lifecycle"
      ],
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : merge(local.prometheus_ecs_log_options, {
          "awslogs-stream-prefix" : "prometheus"
        })
      },
      "mountPoints" : [
        {
          "sourceVolume" : "configVolume",
          "containerPath" : "/etc/config",
          "readOnly" : false
        },
        {
          "sourceVolume" : "logsVolume",
          "containerPath" : "/data"
        }
      ],
      "healthCheck" : {
        "command" : [
          "CMD-SHELL",
          "wget http://localhost:${local.prometheus_server_port}/-/healthy -O /dev/null || exit 1"
        ],
        "interval" : 10,
        "timeout" : 2,
        "retries" : 2,
        "startPeriod" : 10
      },
      "portMappings" : [{ "containerPort" : local.prometheus_server_port }]
    },
    {
      "name" : "config-reloader",
      "image" : "public.ecr.aws/awsvijisarathy/prometheus-sdconfig-reloader:1.0", # TODO: hardcoded version
      "essential" : true,
      "user" : "root", # TODO: don't run as root; fix mount permissions.
      "environment" : [
        { "name" : "CONFIG_FILE_DIR", "value" : "/etc/config" },
        { "name" : "CONFIG_RELOAD_FREQUENCY", "value" : "60" }
      ],
      "mountPoints" : [
        {
          "sourceVolume" : "configVolume",
          "containerPath" : "/etc/config",
          "readOnly" : false
        }
      ],
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : merge(local.prometheus_ecs_log_options, {
          "awslogs-stream-prefix" : "reloader"
        })
      }
    },
    {
      "name" : "aws-iamproxy",
      "image" : "public.ecr.aws/aws-observability/aws-sigv4-proxy:1.0", # TODO: hardcoded version
      "essential" : true,
      "portMappings" : [{ "containerPort" : 8080, "protocol" : "tcp" }],
      "command" : [
        "--name", "aps",
        "--region", data.aws_region.current.name,
        "--host", "aps-workspaces.${data.aws_region.current.name}.amazonaws.com"
      ],
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : merge(local.prometheus_ecs_log_options, {
          "awslogs-stream-prefix" : "iamproxy"
        })
      }
    }
  ])
}

resource "aws_security_group" "prometheus" {
  name        = "fargate_prometheus-${terraform.workspace}"
  vpc_id      = local.vpc_id
  description = "Prometheus ECS service (${terraform.workspace} TF workspace)"
}

resource "aws_iam_role" "prometheus_task" {
  name        = "prometheus_task_role-${terraform.workspace}"
  description = "Prometheus ECS task discovers targets, reads list of namespaces from SSM and writes metrics to AMP."

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17"
    "Statement" : [
      {
        "Action" : "sts:AssumeRole"
        "Effect" : "Allow"
        "Principal" : { "Service" : "ecs-tasks.amazonaws.com" }
      },
    ]
  })
}

resource "aws_iam_role_policy" "prometheus_task" {
  name = "prometheus_task-${terraform.workspace}"
  role = aws_iam_role.prometheus_task.id
  policy = jsonencode({
    "Version" : "2012-10-17"
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "aps:RemoteWrite",
          "aps:GetSeries",
          "aps:GetLabels",
          "aps:GetMetricMetadata"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : ["ssm:GetParameter"],
        "Resource" : "*" # TODO: tighten?
      },
      {
        "Effect" : "Allow",
        "Action" : ["servicediscovery:*"],
        "Resource" : "*"
      }
    ]
  })
}

# TODO: remove once we're managing log groups via TF.
resource "aws_iam_role_policy_attachment" "prometheus_create_log_group" {
  role       = aws_iam_role.prometheus_task.id
  policy_arn = aws_iam_policy.create_log_group_policy.arn
}
