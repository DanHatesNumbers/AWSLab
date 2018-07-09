variable "public_key_path" {
    default = "C:\\Users\\Dan\\AWSLab\\AWSLab_openssh.pub"
}

variable "private_key_path" {
    default = "C:\\Users\\Dan\\AWSLab\\AWSLab.priv"
}

variable "key_name" {
    default = "AWS Lab default keypair"
}

variable "aws_region" {
    default = "eu-west-1"
}

# My OpenBSD 6.3 AMI
variable "aws_amis" {
    default = {
        eu-west-1 = "ami-ee939d04"
    }
}