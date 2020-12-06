variable "name" {
  type = string
}
variable "image" {
  type = string
}
variable "environment" {
  type = map
}
variable "log_group" {
  type = string
}
variable "log_stream_prefix" {
  type = string
}
variable "secrets_from_arns" {
  type = map
}
output "value" {
  value = {
    "name": var.name,
    "image" : var.image,
    "essential" : true,
    "environment" : [for key, value in var.environment: { name: key, value: value }],
    "dependsOn" : [{
      "containerName" : "envoy",
      "condition" : "START"
    }],
    "logConfiguration" : {
      "logDriver" : "awslogs",
      "options" : {
        "awslogs-create-group" : "true",
        "awslogs-group" : var.log_group,
        "awslogs-region" : "eu-west-1", # TODO: hardcoded region
        "awslogs-stream-prefix" : var.log_stream_prefix,
      }
    },
    "mountPoints" : [],
    "portMappings" : [
      {
        "containerPort" : 80,
        "hostPort" : 80,
        "protocol" : "tcp"
      }
    ],
    "secrets" : [for key, value in var.secrets_from_arns: { name: key, valueFrom: value }]
  }
}
