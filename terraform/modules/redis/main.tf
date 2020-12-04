terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
  }
}

resource "aws_elasticache_subnet_group" "redis_cluster_subnet_group" {
  name       = var.elasticache_cluster_name
  subnet_ids = var.subnet_ids
}

resource "aws_security_group" "redis" {
  name        = "${var.elasticache_cluster_name}_elasticache"
  vpc_id      = var.vpc_id
  description = "Access to the ${var.elasticache_cluster_name} Redis cluster"
}

resource "aws_elasticache_replication_group" "redis_cluster" {
  replication_group_id          = var.elasticache_cluster_name
  replication_group_description = "${var.elasticache_cluster_name} Redis cluster with Redis master and replica"
  node_type                     = var.node_type
  port                          = 6379
  number_cache_clusters         = 2
  parameter_group_name          = "default.redis3.2"
  automatic_failover_enabled    = true
  engine_version                = "3.2.10"
  subnet_group_name             = aws_elasticache_subnet_group.redis_cluster_subnet_group.name
  security_group_ids            = [aws_security_group.redis.id]
}


/// internal route53 record

# TODO - we probably shouldn't be using the test.govuk-internal.digital Route53 zone directly here.
# It would be better for us to create our own Zone.
data "aws_route53_zone" "internal" {
  name         = var.internal_domain_name
  private_zone = true
}

resource "aws_route53_record" "internal_service_record" {
  zone_id = data.aws_route53_zone.internal.zone_id
  name    = "${var.elasticache_cluster_name}-redis.${var.internal_domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_elasticache_replication_group.redis_cluster.primary_endpoint_address]
}
