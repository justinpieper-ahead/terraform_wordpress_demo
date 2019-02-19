output "web_sg_id" {
  value = "${aws_security_group.web_access.id}"
}

output "ssh_sg_id" {
  value = "${aws_security_group.ssh_access.id}"
}

output "efs_sg_id" {
  value = "${aws_security_group.efs_sg.id}"
}

output "allow_alb_sg_id" {
  value = "${aws_security_group.allow_alb_http.id}"
}
