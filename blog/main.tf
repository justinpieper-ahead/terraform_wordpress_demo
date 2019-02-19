resource "aws_db_instance" "blog_db" {
  allocated_storage = 10
  storage_type      = "gp2"
  engine            = "mysql"
  engine_version    = "5.7"
  instance_class    = "db.t2.small"
  name              = "wordpress"

  username               = "foo"
  password               = "${aws_ssm_parameter.rds_password.value}"
  parameter_group_name   = "default.mysql5.7"
  db_subnet_group_name   = "${aws_db_subnet_group.default_sub_group.name}"
  port                   = 8090
  deletion_protection    = "${terraform.workspace == "prod" ? true : false}"
  skip_final_snapshot    = "${terraform.workspace == "prod" ? false : true}"
  vpc_security_group_ids = ["${module.rds_sg.rds_sg_id}"]

  tags = "${merge(local.common_tags,map(
     "Name", "blog_rds_instance"
    )
  )}"
}

resource "aws_route53_record" "db_record" {
  zone_id = "${data.aws_route53_zone.showturtles.zone_id}"
  name    = "blogdb.showturtles.com"
  type    = "CNAME"
  ttl     = "60"
  records = ["${aws_db_instance.blog_db.address}"]
}

resource "aws_route53_record" "instance_record" {
  zone_id = "${data.aws_route53_zone.showturtles.zone_id}"
  name    = "blog.showturtles.com"
  type    = "CNAME"
  ttl     = "60"
  records = ["${aws_lb.blog_alb.dns_name}"]
}

resource "aws_route53_record" "efs_record" {
  zone_id = "${data.aws_route53_zone.showturtles.zone_id}"
  name    = "efs.showturtles.com"
  type    = "CNAME"
  ttl     = "60"
  records = ["${aws_efs_file_system.blog_fs.dns_name}"]
}

resource "aws_ssm_parameter" "rds_password" {
  name   = "rds_admin_pass"
  type   = "SecureString"
  value  = "${var.rds_password}"
  key_id = "${data.terraform_remote_state.base_env.key_id}"
}

resource "aws_db_subnet_group" "default_sub_group" {
  name       = "blog_group"
  subnet_ids = ["${data.terraform_remote_state.base_env.private_subnets}"]
}

module "rds_sg" {
  source = "modules/database-security-group"
  vpc_id = "${data.terraform_remote_state.base_env.vpc_id}"
  port   = 8090
}

module "web_sg" {
  source = "modules/blog-security-groups"
  vpc_id = "${data.terraform_remote_state.base_env.vpc_id}"
}

resource "aws_lb" "blog_alb" {
  name               = "blog-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${module.web_sg.web_sg_id}", "${module.web_sg.allow_alb_sg_id}"]
  subnets            = ["${data.terraform_remote_state.base_env.public_subnets}"]

  tags = "${merge(local.common_tags,map(
     "Name", "blog_rds_instance"
    )
  )}"
}

resource "aws_lb_target_group" "blog_tg" {
  name     = "blog-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${data.terraform_remote_state.base_env.vpc_id}"

  stickiness {
    type    = "lb_cookie"
    enabled = true
  }
}

resource "aws_autoscaling_attachment" "blog_asg_attach" {
  autoscaling_group_name = "${aws_autoscaling_group.blog_asg.id}"
  alb_target_group_arn   = "${aws_lb_target_group.blog_tg.arn}"
}

resource "aws_lb_listener" "blog_listener" {
  load_balancer_arn = "${aws_lb.blog_alb.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${data.aws_acm_certificate.blog_cert.arn}"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.blog_tg.arn}"
  }
}

resource "aws_autoscaling_group" "blog_asg" {
  vpc_zone_identifier = ["${data.terraform_remote_state.base_env.private_subnets}"]
  desired_capacity    = 2
  max_size            = 4
  min_size            = 1

  health_check_grace_period = 300
  health_check_type         = "ELB"

  launch_template {
    id      = "${aws_launch_template.blog_launch_template.id}"
    version = "$$Latest"
  }
}

resource "aws_launch_template" "blog_launch_template" {
  // Need the efs_mount up before we stand up any instances
  depends_on             = ["aws_efs_mount_target.efs_mounts", "aws_route53_record.efs_record"]
  ami                    = "${lookup(var.amis, data.aws_region.current.name)}"
  instance_type          = "t2.micro"
  key_name               = "${data.terraform_remote_state.base_env.key_name}"
  vpc_security_group_ids = ["${module.web_sg.allow_alb_sg_id}", "${module.rds_sg.rds_sg_id}", "${module.web_sg.ssh_sg_id}", "${module.web_sg.efs_sg_id}"]
  user_data              = "${base64encode(data.template_file.userdata.rendered)}"

  iam_instance_profile {
    name = "${aws_iam_instance_profile.blog_profile.name}"
  }

  tag_specifications {
    resource_type = "instance"
    tags = "${merge(local.common_tags,map(
     "Name", "blog_asg_instance"
    )
  )}"
  }

  tags = "${merge(local.common_tags,map(
     "Name", "blog_launch_template"
    )
  )}"
}

resource "aws_efs_file_system" "blog_fs" {
  tags = "${merge(local.common_tags,map(
     "Name", "blog_efs_filesystem"
    )
  )}"
}

resource "aws_efs_mount_target" "efs_mounts" {
  count           = 3
  file_system_id  = "${aws_efs_file_system.blog_fs.id}"
  subnet_id       = "${data.terraform_remote_state.base_env.private_subnets[count.index]}"
  security_groups = ["${module.web_sg.efs_sg_id}"]
}

locals {
  common_tags = {
    Terraform   = "true"
    Environment = "${terraform.workspace}"
  }
}

// TODO.  Put this in a module
resource "aws_iam_instance_profile" "blog_profile" {
  name = "blog_profile"
  role = "${aws_iam_role.role.name}"
}

resource "aws_iam_role" "role" {
  name = "test_role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_policy" "policy" {
  name        = "blog_policy"
  path        = "/"
  description = "My blog policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "policy-attach" {
  name       = "policy-attachment"
  roles      = ["${aws_iam_role.role.name}"]
  policy_arn = "${aws_iam_policy.policy.arn}"
}
