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

    provisioner "file" {
        content = <<EOF
        root ALL=(ALL) ALL
        ec2-user ALL=(ALL) NOPASSWD: ALL
        EOF
        destination = "/tmp/sudoers"
    }

    provisioner "remote-exec" {
        inline = [
            "su -l root -c 'echo hostname=\"salt.danhatesnumbers.co.uk\" >> /etc/rc.conf'",
            "su -l root -c 'pkg install -y sudo'",
            "su -l root -c 'mv /tmp/sudoers /usr/local/etc/sudoers && chown root:wheel /usr/local/etc/sudoers'",
            "sudo hostname salt.danhatesnumbers.co.uk",
            "sudo pkg install -y py27-salt",
            "sudo mv /tmp/master.conf /usr/local/etc/salt/master",
            "sudo mkdir -p /var/salt/base",
            "sudo mkdir -p /var/salt/pillar",
            "sudo sysrc salt_master_enable=\"YES\"",
            "sudo service salt_master start",
            "sudo pkg install -y git"
        ]
    }

    provisioner "remote-exec" {
        script = "conf/salt_master/bootstrap.sh"
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

data "template_file" "web_minion_conf" {
    template = "master: $${master_private_ip}"

    vars {
        master_private_ip = "${aws_instance.salt_master.private_ip}"
    }
}

resource "aws_iam_role" "web_iam_role" {
    name = "web_iam_role"
    assume_role_policy = "${data.aws_iam_policy_document.web_iam_assume_role_policy_document.json}"
}

data "aws_iam_policy_document" "web_iam_assume_role_policy_document" {
    statement {
        actions = ["sts:AssumeRole"]

        principals {
            type = "Service"
            identifiers = ["ec2.amazonaws.com"]
        }

        effect = "Allow"
    }
}

resource "aws_iam_role_policy" "web_iam_role_policy" {
    name = "web_iam_role_policy"
    role = "${aws_iam_role.web_iam_role.id}"
    policy = "${data.aws_iam_policy_document.web_iam_role_policy_document.json}"
}

data "aws_iam_policy_document" "web_iam_role_policy_document" {
    statement {
        actions = [
            "route53:ListHostedZones",
            "route53:GetChange"
        ]

        resources = ["*"]

        effect = "Allow"
    }

    statement {
        actions = ["route53:ChangeResourceRecordSets"]

        resources = ["arn:aws:route53:::hostedzone/${var.hosted_zone_id}"]

        effect = "Allow"
    }
}

resource "aws_iam_instance_profile" "web_instance_profile" {
    name = "web_instance_profile"
    role = "web_iam_role"
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

    iam_instance_profile = "${aws_iam_instance_profile.web_instance_profile.id}"

    subnet_id = "${aws_subnet.default.id}"
    associate_public_ip_address = true

    provisioner "file" {
        content = "${data.template_file.web_minion_conf.rendered}"
        destination = "/tmp/minion.conf"
    }

    provisioner "file" {
        content = <<EOF
        root ALL=(ALL) ALL
        ec2-user ALL=(ALL) NOPASSWD: ALL
        EOF
        destination = "/tmp/sudoers"
    }

    provisioner "remote-exec" {
        inline = [
            "su -l root -c 'echo hostname=\"test.danhatesnumbers.co.uk\" >> /etc/rc.conf'",
            "su -l root -c 'pkg install -y sudo'",
            "su -l root -c 'mv /tmp/sudoers /usr/local/etc/sudoers && chown root:wheel /usr/local/etc/sudoers'",
            "sudo hostname test.danhatesnumbers.co.uk",
            "sudo pkg install -y py27-salt",
            "sudo mv /tmp/minion.conf /usr/local/etc/salt/minion",
            "sudo sysrc salt_minion_enable=\"YES\"",
		    "sudo service salt_minion start"
        ]
    }
}