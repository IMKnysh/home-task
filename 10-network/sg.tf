resource "aws_security_group" "bastion_sg" {
  name = "${var.project_name}.bastion_sg"
  description = "Bastion security group"
  vpc_id = "${aws_vpc.kim_vpc.id}"
  # Allow SHH
  ingress {
    from_port = 22
    protocol = "tcp"
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 443
    protocol = "tcp"
    to_port = 443
    security_groups = ["${aws_security_group.intra.id}"]
  }
  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    security_groups = ["${aws_security_group.intra.id}"]
  }

  # Allow all to out
  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.project_name}.bastion_sg"
    )
  )}"
}

resource "aws_security_group" "intra" {
  name        = "${var.project_name}.intranet.sg"
  description = "Intranet instances SG"
  vpc_id      = "${aws_vpc.kim_vpc.id}"
  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.project_name}.intra_sg"
    )
  )}"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = ["${aws_security_group.bastion_sg.id}"]
    self = true
  }
  # Allow all ICMP traffic
  ingress {
    from_port = -1
    protocol = "icmp"
    to_port = -1
    security_groups = ["${aws_security_group.bastion_sg.id}"]
    self = true
  }
  ingress {
    from_port = 8300
    to_port = 8600
    protocol = "tcp"
    security_groups = ["${aws_security_group.bastion_sg.id}"]
    self = true
  }
  ingress {
    from_port = 8300
    to_port = 8600
    protocol = "udp"
    security_groups = ["${aws_security_group.bastion_sg.id}"]
    self = true
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
