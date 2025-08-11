# instance_type = "t3.micro"   #demodemo@DEMO1
# ami = "ami-020cba7c55df1f615"
# iam_instance_profile = "ssm-role"
# key_name = "demo"
# subnet_id = "subnet-0dfc46ecd14d77717"
# vpc_security_group_ids = ["sg-0cbed14cf7f2fd51f"]
instance ={
    "web-1" = {
        instance_type          = "t3.micro"
        ami                    = "ami-020cba7c55df1f615"
        iam_instance_profile   = "ssm-role"
        key_name               = "demo"
        subnet_id              = "subnet-0dfc46ecd14d77717"
        vpc_security_group_ids = ["sg-0cbed14cf7f2fd51f"]
    }
}