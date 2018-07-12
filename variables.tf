variable "public_key_path" {
    default = "..\\AWSLab_openssh.pub"
}

variable "private_key_path" {
    default = "..\\AWSLab.priv"
}

variable "key_name" {
    default = "AWS Lab default keypair"
}

variable "aws_region" {
    default = "eu-west-1"
}

# Public FreeBSD 11.2 AMI
variable "aws_amis" {
    default = {
        eu-west-1 = "ami-ab050d41"
    }
}