output "public_ip" {
    # value = [for inst in module.ec2 : inst.public_ip]
    value = {for name, inst in module.ec2 : name => inst.public_ip}
}