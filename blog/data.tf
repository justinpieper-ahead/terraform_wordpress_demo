data "terraform_remote_state" "base_env" {
  backend = "s3"

  config {
    bucket = "tfstate-jrpieper-personal"
    key    = "env:/${terraform.workspace}/aws/base.tfstate"
    region = "us-east-1"
  }
}

data "template_file" "userdata" {
  template = "${file("scripts/install.sh")}"
}

data "aws_region" "current" {}

data "aws_route53_zone" "showturtles" {
  name = "showturtles.com"
}

data "aws_acm_certificate" "blog_cert" {
  domain   = "blog.showturtles.com"
  statuses = ["ISSUED"]
}
