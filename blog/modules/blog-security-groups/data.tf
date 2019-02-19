
data "terraform_remote_state" "base_env" {
  backend = "s3"

  config {
    bucket = "tfstate-jrpieper-personal"
    key    = "env:/${terraform.workspace}/aws/base.tfstate"
    region = "us-east-1"
  }
}