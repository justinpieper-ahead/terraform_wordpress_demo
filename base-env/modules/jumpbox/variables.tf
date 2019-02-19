variable "ami_id" {
    description = "AMI ID to use for the jumpbox"
}

variable "key_name" {
    description = "SSH key name"
}

variable "public_subnets" {
    type = "list"
    description = "Public subnets for the jumpbox to be placed in."
}

variable "vpc_id" {
    description = "VPC id"
}

variable "amis" {
    type = "map"
    default = {
        us-east-1 = "ami-0ac019f4fcb7cb7e6"
        us-east-2 = "ami-0f65671a86f061fcd"
    }
}