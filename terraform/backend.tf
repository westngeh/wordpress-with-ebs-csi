terraform {
  backend "s3" {
    bucket = "kubedeploy.state"
    region = "us-east-1"
    key = "eks/terraform.tfstate"
  }
}