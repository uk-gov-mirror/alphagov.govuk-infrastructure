resource "aws_route53_zone" "external" {
  name = "${terraform.workspace}.${data.terraform_remote_state.infra_root_dns_zones.outputs.external_root_domain_name}"

  tags = {
    Repo       = "alphagov/govuk-infrastructure"
    Deployment = "govuk-publishing-platform"
    Workspace  = terraform.workspace
  }
}

resource "aws_route53_record" "external-ns" {
  zone_id = data.terraform_remote_state.infra_root_dns_zones.outputs.external_root_zone_id
  name    = "${terraform.workspace}.${data.terraform_remote_state.infra_root_dns_zones.outputs.external_root_domain_name}"
  type    = "NS"
  ttl     = "30"
  records = aws_route53_zone.external.name_servers
}
