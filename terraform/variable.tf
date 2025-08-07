# variable "instance" {
#   type = map(object({ 
#   }))
# }

variable "instance" {
  description = "Instance configuration for EC2 module"
  type = map(object({
    instance_type          = string
    ami                    = string
    iam_instance_profile   = string
    subnet_id              = string
    key_name               = string
    vpc_security_group_ids = list(string)
  }))
}
