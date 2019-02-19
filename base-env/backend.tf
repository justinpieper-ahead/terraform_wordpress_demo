terraform {
  backend "s3" {
    bucket = "tfstate-jrpieper-personal"
    key    = "aws/base.tfstate"
    region = "us-east-1"
  }
}
