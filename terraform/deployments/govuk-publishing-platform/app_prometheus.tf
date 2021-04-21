locals {
  prometheus_server_port       = 9090
  prometheus_aws_iamproxy_port = 8005
  prometheus_ecs_log_options = {
    "awslogs-create-group" : "true",                   # TODO: create the log group in TF so we can configure the retention policy.
    "awslogs-group" : "${local.log_group}/prometheus", # TODO: other apps are all mixed into the same group; do we want that?
    "awslogs-region" : data.aws_region.current.name,
  }
  prometheus_config = {
    "global" : {
      "evaluation_interval" : "1m",
      "scrape_interval" : "1m",
      "scrape_timeout" : "10s"
    },
    "remote_write" : [
      {
        "url" : "http://localhost:${local.prometheus_aws_iamproxy_port}/workspaces/${aws_prometheus_workspace.prometheus.id}/api/v1/remote_write"
      }
    ],
    "scrape_configs" : [
      {
        "job_name" : "appmesh-envoy",
        "file_sd_configs" : [
          {
            "files" : ["/etc/config/ecs-services.json"],
            "refresh_interval" : "30s"
          }
        ],
        "relabel_configs" : [
          {
            "source_labels" : ["__address__"],
            "regex" : "(.*):.*",
            "replacement" : "$1:9901", # TODO: define this port number in one authoritative place.
            "target_label" : "__address__"
          },
          # TODO: Remove this workaround once we've got rid of prometheus-sdconfig-reloader.
          # We should just be able to set metrics_path normally, but because
          # prometheus-sdconfig-reloader sets __metrics_path__ on every target
          # for some reason, we have to override it by relabelling.
          {
            "replacement" : "/stats/prometheus",
            "target_label" : "__metrics_path__"
          },
        ]
      }
    ]
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
  target_port               = local.prometheus_server_port
  health_check_path         = "/-/ready"
  external_cidrs_list       = var.office_cidrs_list
}

resource "aws_ecs_service" "prometheus" {
  name          = "prometheus"
  cluster       = aws_ecs_cluster.cluster.id
  launch_type   = "FARGATE"
  desired_count = 2

  load_balancer {
    target_group_arn = module.prometheus_public_alb.target_group_arn
    container_name   = "prometheus-server"
    container_port   = local.prometheus_server_port
  }

  network_configuration {
    security_groups = [aws_security_group.prometheus.id]
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
    # TODO: replace awsvijisarathy/prometheus-sdconfig-reloader with aws-cloudmap-prometheus-sd (already in our ECR at 172025368201.dkr.ecr.eu-west-1.amazonaws.com/awslabs/aws-cloudmap-prometheus-sd) and a shell command to copy the config from S3 at startup.
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
      "portMappings" : [{ "containerPort" : local.prometheus_aws_iamproxy_port }],
      "command" : [
        "--port", ":${local.prometheus_aws_iamproxy_port}",
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

# TODO: This doesn't currently support workspaces. Need to patch
# https://github.com/aws-samples/prometheus-for-ecs/blob/main/cmd/main.go to:
# - Take the service discovery namespace from an env var (not from SSM) and
# - Take the name of the SSM parameter containing the Prometheus configuration
#   from an env var.
resource "aws_ssm_parameter" "prometheus_config" {
  name        = "ECS-Prometheus-Configuration"
  type        = "String"
  description = "Contents of the prometheus.yaml config file. The prometheus-sdconfig-reloader sidecar reads this from SSM at startup and writes it to the local filesystem, where it's then read by Prometheus."
  value       = jsonencode(local.prometheus_config)
}
resource "aws_ssm_parameter" "prometheus_service_discovery_namespace" {
  name        = "ECS-ServiceDiscovery-Namespaces"
  type        = "String"
  description = "Tells the prometheus-sdconfig-reloader sidecar which Cloud Map namespaces to search for scrape targets. This should be a command-line flag, not an SSM parameter."
  value       = aws_service_discovery_private_dns_namespace.govuk_publishing_platform.name
}

resource "aws_security_group" "prometheus" {
  name        = "fargate_prometheus-${terraform.workspace}"
  vpc_id      = local.vpc_id
  description = "Prometheus ECS service (${terraform.workspace} TF workspace)"
}

resource "aws_security_group_rule" "prometheus_to_app_apps_any" {
  description       = "Prometheus sends requests to anywhere on any port"
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
  security_group_id = aws_security_group.prometheus.id
  # TODO: tighten this to the VPC subnets
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "prometheus_to_prometheus" {
  description       = "Prometheus ECS tasks can monitor each other"
  type              = "ingress"
  from_port         = local.prometheus_server_port
  to_port           = local.prometheus_server_port
  protocol          = "tcp"
  security_group_id = aws_security_group.prometheus.id
  self              = true
}

resource "aws_security_group_rule" "all_apps_from_prometheus_any" {
  description              = "All apps accept requests from Prometheus on any port"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.mesh_ecs_service.id
  source_security_group_id = aws_security_group.prometheus.id
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
