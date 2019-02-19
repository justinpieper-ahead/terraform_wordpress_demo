resource "aws_security_group" "rds_sg" {
  name        = "blog_rds_sg"
  description = "Allow traffic to the RDS instance backing the wordpress instance"
  vpc_id      = "${var.vpc_id}"

  tags = "${merge(local.common_tags,map(
     "Name", "blog_rds_sg"
    )
  )}"
}

resource "aws_security_group_rule" "rds_rule" {
  type      = "ingress"
  from_port = "${var.port}"
  to_port   = "${var.port}"
  protocol  = "tcp"
  self      = true

  security_group_id = "${aws_security_group.rds_sg.id}"
}

resource "aws_security_group_rule" "egress" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  cidr_blocks = ["0.0.0.0/0"]
  protocol    = "-1"

  security_group_id = "${aws_security_group.rds_sg.id}"
}

# TODO allow traffic from wordpress instance to

locals {
  common_tags = {
    Terraform   = "true"
    Environment = "${terraform.workspace}"
    Owner       = "justin"
  }
}
