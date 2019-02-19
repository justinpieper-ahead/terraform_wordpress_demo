variable "rds_password" {
  description = "Admin password for the RDS DB"
}

variable "ami_ids" {
    type = "map"
    description = "Map the AMI IDs to use to each AWS region"
    default = {
        us-east-1 = "ami-0ac019f4fcb7cb7e6"
        us-east-2 = "ami-0f65671a86f061fcd"
    }

}