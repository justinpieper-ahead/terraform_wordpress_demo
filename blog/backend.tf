terraform {
  backend "s3" {
    bucket = "tfstate-jrpieper-personal"
    key    = "aws/blog.tfstate"
    region = "us-east-1"
  }
}
