module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  enable_dns_hostnames = true

  single_nat_gateway = "${terraform.workspace == "prod" ? false : true}"

  # TODO update these tags to be a vriable
  tags = {
    Terraform   = "true"
    Environment = "${terraform.workspace}"
  }
}

module "jumpbox" {
  source = "modules/jumpbox"

  ami_id = "ami-0ac019f4fcb7cb7e6"

  key_name = "${aws_key_pair.mac_ssh.key_name}"

  public_subnets = "${module.vpc.public_subnets}"

  vpc_id = "${module.vpc.vpc_id}"


}

resource "aws_kms_key" "base_key" {
  description             = "Default Key"
  deletion_window_in_days = "${terraform.workspace == "prod" ? 30 : 7}"
}

resource "aws_key_pair" "mac_ssh" {
  key_name = "mac_ssh"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCrD8Tuqccb9YrDUCc/ouJvqsKLo7+VRPzGolg28uTwq7fBikfZ9uqHfML5k0Tgp8rBgb/AIwGkuwFJrntiV0mIoCs2BSzhb9e1i8Fa0ZnG0RCXV6+aUboqSeBwpWlDAnZnBK1KQqKoQsv7I9DjYQW2uMyogUQl8EtHco6z/sSmYcGBw6/EWRXz26oGw72CgEVH96X+QDDO+xCQO12MP12IjMISSos1Ab9YzWyvOmcbKg2UHCXUhI25v2KURjVlXQuPTuYXYcCl4wH8ONAld/Dvuk0cK4pnbm+HcEhm8QJmxb65tHNoCK+tB/BVeDOBBdaX0rrq9M3LB17RwEQJVvGJj+rTQWQOanzwM1VglrliRRjc9Tgy4emTJD0h5kMqbstPOAkvdNrkFwTtqjMT3Vm4iAga2Bhteary9FgT2Mo5DYJfqp5cdwI/t2sn+V/7Ca8hIbfistu9TRByw35ZBC4uHXnRztsMhDVkzFR2J+dsuHPKN7buTs8zWEZwQSDCTAEeses9+DdJbv/hXeOvHLVdu/CxIMGqDN8tfUTiw4AbAHppnqzW0Do+hVS2Gp/U+y+GZ0jZ7712U3YBiZtVk4XcWa/zERe4deiiePpvPOK4oFRRGQnm5rFHxBFYW+5HkbP5+h4pbBGNN94vbJw6l56wP940Z8hxiudYn3falyGFuQ== justin.pieper@AHD-MBP13-053.local"
}