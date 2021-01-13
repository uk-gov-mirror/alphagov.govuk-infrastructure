output "web_task_definition" {
  description = "ARNs of the web task definition revision"
  value       = aws_ecs_task_definition.web.arn
}

output "worker_task_definition" {
  description = "ARNs of the worker task definition revision"
  value       = aws_ecs_task_definition.worker.arn
}
