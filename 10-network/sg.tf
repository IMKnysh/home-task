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
  # Allow ICMP
  ingress {
    from_port = -1
    protocol = "icmp"
    to_port = -1
    cidr_blocks = ["0.0.0.0/0"]
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
  # SSH access from anywhere
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
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  ingress {
    from_port = 8300
    to_port = 8600
    protocol = "tcp"
    cidr_blocks = ["${aws_subnet.private_net.*.cidr_block}"]
  }
  ingress {
    from_port = 8300
    to_port = 8600
    protocol = "udp"
    cidr_blocks = ["${aws_subnet.private_net.*.cidr_block}"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
