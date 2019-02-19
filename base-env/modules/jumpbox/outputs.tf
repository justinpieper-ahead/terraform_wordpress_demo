output "jumpbox_ip" {
    value = "${aws_instance.jumpbox.private_ip}"
}