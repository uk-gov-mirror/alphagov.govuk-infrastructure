output "json_format" {
  value = {
    name        = var.name,
    command     = var.command,
    essential   = true,
    environment = [for key, value in var.environment_variables : { name : key, value : tostring(value) }],
    dependsOn   = var.dependsOn
    healthCheck = {
      command = ["/bin/bash", "-c", var.health_check]
    }
    image = var.image
    linuxParameters = {
      initProcessEnabled = true
    }
    logConfiguration = {
      logDriver = "splunk",
      options = {
        splunk-url        = var.splunk_url,
        splunk-token      = var.splunk_token,
        splunk-sourcetype = var.splunk_sourcetype,
        splunk-index      = var.splunk_index,
      }
    },
    mountPoints  = [],
    portMappings = [for port in var.ports : { containerPort = port, hostPort = port, protocol = "tcp" }],
    secrets      = [for key, value in var.secrets_from_arns : { name = key, valueFrom = value }]
    user         = var.user
  }
}
