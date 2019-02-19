resource "aws_instance" "jumpbox" {
  ami                    = "${lookup(var.amis, data.aws_region.current.name)}"
  instance_type          = "t2.micro"
  key_name               = "${var.key_name}"
  subnet_id              = "${var.public_subnets[0]}"
  vpc_security_group_ids = ["${aws_security_group.ssh_access.id}"]

  tags = "${merge(local.common_tags,map(
     "Name", "jumpbox"
    )
  )}"
}

resource "aws_security_group" "ssh_access" {
  name        = "jumpbox_ssh"
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
  cidr_blocks = ["${data.external.get_ip.result.ip}/32"]

  security_group_id = "${aws_security_group.ssh_access.id}"
}

resource "aws_security_group_rule" "ssh_egress" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  cidr_blocks = ["0.0.0.0/0"]
  protocol    = "-1"

  security_group_id = "${aws_security_group.ssh_access.id}"
}

locals {
  common_tags = {
    Terraform   = "true"
    Environment = "${terraform.workspace}"
    Owner       = "justin"
  }
}
