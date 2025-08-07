resource "aws_instance" "foo" {
  ami           = var.ami # us-east-1
  instance_type = var.instance_type
  iam_instance_profile = var.iam_instance_profile
  key_name = var.key_name
  subnet_id = var.subnet_id
  vpc_security_group_ids = var.vpc_security_group_ids
  tags = {
      Name = "TF-Instance"
  }
}

