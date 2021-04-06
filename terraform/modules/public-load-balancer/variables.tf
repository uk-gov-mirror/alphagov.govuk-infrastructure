variable "external_app_domain" {
  type        = string
  description = "e.g. test.govuk.digital. Domain in which to create DNS records for the app's Internet-facing load balancer."
}

variable "certificate" {
  type = string
}

variable "app_name" {
  type        = string
  description = "A GOV.UK application name. E.g. publisher, content-publisher"
}

variable "dns_a_record_name" {
  type        = string
  description = "DNS A Record name. Should be cluster and environment-aware."
}

variable "publishing_service_domain" {
  type        = string
  description = "e.g. test.publishing.service.gov.uk"
}

variable "public_subnets" {
  type = list(any)
}

variable "service_security_group_id" {
  type        = string
  description = "Security group ID for the associated ECS Service."
}

variable "restricted_paths" {
  type        = list(any)
  description = "Paths IP restricted to GDS VPN and GOV.UK VPC"
  default     = ["/healthcheck"]
}

variable "vpc_id" {
  type = string
}

variable "public_zone_id" {
  type = string
}

variable "health_check_path" {
  type    = string
  default = "/healthcheck"
}

variable "target_port" {
  type    = number
  default = 80
}

variable "cidrs_allowlist" {
  type        = list(any)
  default     = ["0.0.0.0/0"]
  description = "Allowlist for HTTPS access (not necessarily all paths)."
}

variable "unrestricted_cidrs" {
  type        = list(any)
  default     = ["0.0.0.0/0"]
  description = "Endpoint allowlist for restricted_paths."
}

variable "workspace" {
  type = string
}
