
resource "fastly_service_v1" "www_service" {
  count = contains(concat(["ecs"], var.non_default_workspaces_enabled_cdn_list), local.workspace) ? 1 : 0
  name  = "www_service_${var.govuk_environment}"

  domain {
    #TODO: replace www1 with www as this is for testing only
    name    = local.is_default_workspace ? "www1.ecs.${var.publishing_service_domain}" : aws_route53_record.fastly_cdn_www[0].fqdn
    comment = "www CDN entry point for the ${var.govuk_environment} GOV.UK environment"
  }

  force_destroy = true

  vcl {
    name = "www_main_vcl_template"
    content = templatefile("templates/www_vcl_template.tpl",
      { origin_hostname                     = module.www_origin.origin_app_fqdn
        basic_authentication_encoded_secret = contains(["staging", "production"], var.govuk_environment) ? "" : data.aws_secretsmanager_secret_version.cdn_basic_authentication_encoded_secret[0].secret_string,
        allowed_ip_addresses                = [for cidr in concat(var.office_cidrs_list, local.nat_gateway_public_cidrs_list) : cidrhost(cidr, 0)],
        default_ttl                         = var.cdn_cache_default_ttl,
      }
    )
    main = true
  }
}

resource "aws_route53_record" "fastly_cdn_www" {
  count   = local.create_non_default_workspace_cdn ? 1 : 0
  zone_id = aws_route53_zone.workspace_public.zone_id
  name    = "www"
  type    = "CNAME"
  ttl     = 300
  records = ["www-gov-uk.map.fastly.net."]
}

resource "aws_route53_record" "fastly_cdn_www_tls_validation" {
  count   = local.create_non_default_workspace_cdn ? 1 : 0
  zone_id = aws_route53_zone.workspace_public.zone_id
  name    = "_acme-challenge"
  type    = "CNAME"
  ttl     = 300
  records = [var.dns_validation_for_cdn[local.workspace]]
}
