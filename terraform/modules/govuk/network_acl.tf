# In the test environment, block all traffic to/from outside the VPC except for
# the GDS office and VPN.

locals {
  allowed_external_cidrs = var.restrict_external_access ? var.office_cidrs_list : []
}

resource "aws_network_acl" "external_traffic_allowlist" {
  count      = var.restrict_external_access ? 1 : 0
  vpc_id     = var.vpc_id
  subnet_ids = var.public_subnets
}

# XXX
resource "aws_network_acl_rule" "allow_other_vpc_subnets_ingress" {
  count          = length(local.allowed_external_cidrs)
  network_acl_id = aws_network_acl.acl[0].id
  rule_action    = "allow"
  protocol       = -1
  rule_number    = 1000 + 10 * count.index
  cidr_block     = var.office_cidrs_list[count.index]
}

# Using count for non-identical resources is usually an antipattern, but in
# this case it's the lesser of evils. This is because we have to assign rule_no
# anyway, so for_each doesn't save us from re-creating subsequent list items
# whenever anything changes (and for_each really only supports unordered sets,
# not lists, so it'd be awkward to compute rule_no).
resource "aws_network_acl_rule" "external_allowlist_ingress" {
  count          = length(local.allowed_external_cidrs)
  network_acl_id = aws_network_acl.acl[0].id
  rule_action    = "allow"
  protocol       = -1
  rule_number    = 1000 + 10 * count.index
  cidr_block     = var.office_cidrs_list[count.index]
}

resource "aws_network_acl_rule" "external_allowlist_egress" {
  count          = length(local.allowed_external_cidrs)
  network_acl_id = aws_network_acl.acl[0].id
  rule_action    = "allow"
  egress         = true
  protocol       = -1
  rule_number    = 10000 + 10 * count.index
  cidr_block     = var.office_cidrs_list[count.index]
}

resource "aws_network_acl_rule" "default_deny" {
  count          = var.restrict_external_access ? 1 : 0
  network_acl_id = aws_network_acl.acl[0].id
  protocol       = -1
  rule_number    = 32000
  rule_action    = "deny"
}
