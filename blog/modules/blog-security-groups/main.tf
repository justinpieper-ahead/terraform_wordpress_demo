resource "aws_security_group" "web_access" {
  name        = "web_access_sg"
  description = "Allow 80 and 443 access to the load balancer"
  vpc_id      = "${var.vpc_id}"

  tags = "${merge(local.common_tags,map(
     "Name", "web_access_sg"
    )
  )}"
}

resource "aws_security_group_rule" "http_access" {
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.web_access.id}"
}

resource "aws_security_group_rule" "https_access" {
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.web_access.id}"
}

resource "aws_security_group" "allow_alb_http" {
  name = "allow_alb_http"
  description = "Allow http and https between alb and asg"
  vpc_id = "${var.vpc_id}"

  tags = "${merge(local.common_tags,map(
     "Name", "allow_alb_http"
    )
  )}"
}

resource "aws_security_group_rule" "allow_alb_http_rule" {
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  self = true

  security_group_id = "${aws_security_group.allow_alb_http.id}"
}

resource "aws_security_group_rule" "allow_alb_https_rule" {
  type = "ingress"
  from_port = 443
  to_port = 443
  protocol = "tcp"
  self = true

  security_group_id = "${aws_security_group.allow_alb_http.id}"
}

resource "aws_security_group" "ssh_access" {
  name        = "ssh_access_sg"
  description = "Allow 22 access to web instance"
  vpc_id      = "${var.vpc_id}"

  tags = "${merge(local.common_tags,map(
     "Name", "ssh_access_sg"
    )
  )}"
}

resource "aws_security_group_rule" "ssh_access_rule" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["${data.terraform_remote_state.base_env.jumpbox_ip}/32"]

  security_group_id = "${aws_security_group.ssh_access.id}"
}

resource "aws_security_group" "efs_sg" {
  name        = "efs_rds_sg"
  description = "Allow traffic to the RDS instance backing the wordpress instance"
  vpc_id      = "${var.vpc_id}"

  tags = "${merge(local.common_tags,map(
     "Name", "efs_rds_sg"
    )
  )}"
}

resource "aws_security_group_rule" "efs_rule" {
  type      = "ingress"
  from_port = 0
  to_port   = 65535
  protocol  = "tcp"
  self      = true

  security_group_id = "${aws_security_group.efs_sg.id}"
}

resource "aws_security_group_rule" "egress" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  cidr_blocks = ["0.0.0.0/0"]
  protocol    = "-1"

  security_group_id = "${aws_security_group.efs_sg.id}"
}

resource "aws_security_group_rule" "ssh_egress" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  cidr_blocks = ["0.0.0.0/0"]
  protocol    = "-1"

  security_group_id = "${aws_security_group.ssh_access.id}"
}

resource "aws_security_group_rule" "web_egress" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  cidr_blocks = ["0.0.0.0/0"]
  protocol    = "-1"

  security_group_id = "${aws_security_group.web_access.id}"
}

locals {
  common_tags = {
    Terraform   = "true"
    Environment = "${terraform.workspace}"
    Owner       = "justin"
  }
}
