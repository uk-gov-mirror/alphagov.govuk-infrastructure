locals {
  vpc_public_cidr_blocks = [
    for nat_gateway in data.aws_nat_gateway.govuk :
    "${nat_gateway.public_ip}/32"
  ]
}

data "aws_nat_gateway" "govuk" {
  count     = length(local.public_subnets)
  subnet_id = local.public_subnets[count.index]
}
