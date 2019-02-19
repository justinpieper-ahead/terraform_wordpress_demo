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

data "aws_ami" "wordpress_ami" {
  most_recent = true

  filter = {
    name   = "owner-id"
    values = ["137112412989"] // Amazon
  }

  filter = {
    name   = "name"
    values = ["amzn-ami-hvm-*"]
  }
}

data "aws_route53_zone" "showturtles" {
  name = "showturtles.com"
}

data "aws_acm_certificate" "blog_cert" {
  domain   = "blog.showturtles.com"
  statuses = ["ISSUED"]
}
