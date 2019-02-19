data "external" "get_ip" {
  program = ["sh", "scripts/getip.sh"]
}

data "aws_region" "current" {}