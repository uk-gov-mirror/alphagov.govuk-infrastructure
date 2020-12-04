variable "mesh_name" {
  type = string
}

variable "service_name" {
  description = "Service name of the Fargate service, cluster, task etc."
  type        = string
}

output "container_definition" {
  value = {
    "name" : "envoy",
    # TODO: don't hardcode the version; track stable Envoy
    # TODO: control when Envoy updates happen (but still needs to be automatic)
    # TODO: don't hardcode the region
    "image" : "840364872350.dkr.ecr.eu-west-1.amazonaws.com/aws-appmesh-envoy:v1.15.1.0-prod",
    "user" : "1337",
    "environment" : [
      { "name" : "APPMESH_RESOURCE_ARN", "value" : "mesh/${var.mesh_name}/virtualNode/${var.service_name}" },
    ],
    "essential" : true,
    "logConfiguration" : {
      "logDriver" : "awslogs",
      "options" : {
        "awslogs-create-group" : "true",
        "awslogs-group" : "awslogs-fargate", # TODO: this log group should vary by terraform.workspace
        "awslogs-region" : "eu-west-1", # TODO: hardcoded
        "awslogs-stream-prefix" : "awslogs-${var.service_name}-envoy"
      }
    }
  }
}

output "egress_ignored_ips" {
  value = "169.254.170.2,169.254.169.254" # TODO: no longer required (try omitting, might need to stay but empty?)
}

output "ignored_uid" {
  value = "1337"
}

output "proxy_egress_port" {
  value = 15001
}

output "proxy_ingress_port" {
  value = 15000
}
