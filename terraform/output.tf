output "public_ip" {
    value = [for inst in module.ec2 : inst.public_ip]
}