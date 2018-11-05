resource "aws_security_group" "bastion_sg" {
  name = "${var.project_name}.bastion_sg"
  description = "Bastion security group"
  vpc_id = "${aws_vpc.kim_vpc.id}"
  ingress {
    from_port = 22
    protocol = "tcp"
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

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

resource "aws_security_group" "nat_sg" {
  name = "${var.project_name}.nat_sg"
  description = "NAT security group"
  vpc_id = "${aws_vpc.kim_vpc.id}"
  ingress {
    from_port = 443
    protocol = "tcp"
    to_port = 443
    cidr_blocks = [
      "${aws_subnet.private_net.*.cidr_block}"]
  }
  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = [
      "${aws_subnet.private_net.*.cidr_block}"]
  }
}
resource "aws_security_group" "intra" {
  name        = "${var.project_name}.PrivSubnet.sg"
  description = "Private Subnet SG"
  vpc_id      = "${aws_vpc.kim_vpc.id}"
  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.project_name}.privsub_sg"
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
    cidr_blocks = ["${var.vpc_cidr}"]
    self = true
  }
  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    self = true
    security_groups = ["${aws_security_group.bastion_sg.id}"]
  }
  ingress {
    from_port = 0
    to_port = 65535
    protocol = "udp"
    self = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
