provider "aws" {
    region = "${var.aws_region}"
}

resource "aws_vpc" "aws_lab" {
    cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "default" {
    vpc_id = "${aws_vpc.aws_lab.id}"
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = false
}

resource "aws_internet_gateway" "default" {
    vpc_id = "${aws_vpc.aws_lab.id}"
}

resource "aws_route" "internet_access" {
    route_table_id = "${aws_vpc.aws_lab.main_route_table_id}"
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
}

resource "aws_security_group" "ssh" {
    vpc_id = "${aws_vpc.aws_lab.id}"
    
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "salt_master" {
    vpc_id = "${aws_vpc.aws_lab.id}"

    ingress {
        from_port = 4505
        to_port = 4505
        protocol = "tcp"
        cidr_blocks = ["10.0.1.0/24"]
    }

    ingress {
        from_port = 4506
        to_port = 4506
        protocol = "tcp"
        cidr_blocks = ["10.0.1.0/24"]
    }
}

resource "aws_security_group" "outbound_internet" {
    vpc_id = "${aws_vpc.aws_lab.id}"

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "web" {
    vpc_id = "${aws_vpc.aws_lab.id}"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_key_pair" "default" {
    key_name = "${var.key_name}"
    public_key = "${file(var.public_key_path)}"
}

resource "aws_instance" "salt_master" {
    connection {
        user = "ec2-user"
        private_key = "${file(var.private_key_path)}"
    }

    instance_type = "t2.micro"


    ami = "${lookup(var.aws_amis, var.aws_region)}"
    key_name = "${var.key_name}"
    vpc_security_group_ids = ["${aws_security_group.ssh.id}", "${aws_security_group.salt_master.id}", "${aws_security_group.outbound_internet.id}"]

    subnet_id = "${aws_subnet.default.id}"
    associate_public_ip_address = true

    provisioner "file" {
        source = "conf/salt_master/master.conf"
        destination = "/tmp/master.conf"
    }

    provisioner "remote-exec" {
        inline = [
            "doas pkg_add salt",
            "doas mv /tmp/master.conf /etc/salt/master",
            "doas mkdir -p /var/salt/{base,pillar}",
            "doas rcctl enable salt_master",
            "doas rcctl start salt_master",
            "doas pkg_add py-pip libgit2",
            "doas pip2.7 install 'pygit2>=0.26,<0.27'"
        ]
    }
}

data "aws_route53_zone" "selected" {
    name = "danhatesnumbers.co.uk."
}

resource "aws_route53_record" "salt" {
    zone_id = "${data.aws_route53_zone.selected.zone_id}"
    name = "salt.${data.aws_route53_zone.selected.name}"
    type = "A"
    ttl = "300"
    records = ["${aws_instance.salt_master.public_ip}"]
}

resource "aws_route53_record" "test" {
    zone_id = "${data.aws_route53_zone.selected.zone_id}"
    name = "test.${data.aws_route53_zone.selected.name}"
    type = "A"
    ttl = "300"
    records = ["${aws_instance.web.public_ip}"]
}

resource "aws_instance" "web" {
    connection {
        user = "ec2-user"
        private_key = "${file(var.private_key_path)}"
    }

    instance_type = "t2.micro"


    ami = "${lookup(var.aws_amis, var.aws_region)}"
    key_name = "${var.key_name}"
    vpc_security_group_ids = ["${aws_security_group.ssh.id}", "${aws_security_group.web.id}", "${aws_security_group.outbound_internet.id}"]

    subnet_id = "${aws_subnet.default.id}"
    associate_public_ip_address = true

    provisioner "file" {
        source = "conf/web/minion.conf"
        destination = "/tmp/minion.conf"
    }

    provisioner "remote-exec" {
        inline = [
            "doas pkg_add salt",
            "doas mv /tmp/minion.conf /etc/salt/minion",
            "doas rcctl enable salt_minion",
            "doas rcctl start salt_minion",
        ]
    }
}