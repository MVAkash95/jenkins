terraform {
  backend "s3" {
    bucket         = "djlksjdks-terraform-backend"
    key            = "ec2/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
