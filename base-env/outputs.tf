output "vpc_id" {
  value = "${module.vpc.vpc_id}"
}

output "private_subnets" {
  value = "${module.vpc.private_subnets}"
}

output "public_subnets" {
  value = "${module.vpc.public_subnets}"
}

output "key_id" {
  value = "${aws_kms_key.base_key.key_id}"
}

output "key_name" {
  value = "${aws_key_pair.mac_ssh.key_name}"
}

output "jumpbox_ip" {
  value = "${module.jumpbox.jumpbox_ip}"
}