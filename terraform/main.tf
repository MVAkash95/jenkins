module "ec2" {
    source = "./module/ec2"
    for_each = var.instance
    instance_type = each.value.instance_type
    ami = each.value.ami
    iam_instance_profile = each.value.iam_instance_profile
    subnet_id = each.value.subnet_id
    key_name = each.value.key_name
    vpc_security_group_ids = each.value.vpc_security_group_ids
}