resource "aws_vpc" "kim_vpc" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_hostnames = "true"
  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.project_name}.vpc"
    )
  )}"
}

resource "aws_subnet" "private_net" {
  vpc_id     = "${aws_vpc.kim_vpc.id}"
  count = "${var.count}"
#  count      = "${length(var.vpc_zones)}"
  cidr_block = "${cidrsubnet(var.vpc_cidr, 4, (count.index * 2 + 1 ))}"
  availability_zone = "${element(var.vpc_zones, count.index)}"
  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.project_name}.priv_net.${count.index}"
    )
  )}"
}

resource "aws_subnet" "public_net" {
  vpc_id     = "${aws_vpc.kim_vpc.id}"
  count = "${var.count}"
#  count      = "${length(var.vpc_zones)}"
  cidr_block = "${cidrsubnet(var.vpc_cidr, 4, (count.index * 2) )}"
  availability_zone = "${element(var.vpc_zones, count.index)}"
  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.project_name}.pub_net.${count.index}"
    )
  )}"
}
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.kim_vpc.id}"
  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.project_name}.igw"
    )
  )}"
}

resource "aws_route_table" "def_route_pub" {
  vpc_id = "${aws_vpc.kim_vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }
  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.project_name}.def_route"
    )
  )}"
}

resource "aws_route_table_association" "def_igw" {
  route_table_id = "${aws_route_table.def_route_pub.id}"
  count = "${var.count}"
#  count = "${length(var.vpc_zones)}"
  subnet_id = "${element(aws_subnet.public_net.*.id, count.index)}"
}

resource "aws_eip" "nat" {
  vpc = true
  instance = "${aws_instance.bastion.id}"
  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.project_name}.eip"
    )
  )}"
}

#resource "aws_nat_gateway" "gw" {
#  allocation_id = "${aws_eip.nat.id}"
#  subnet_id     = "${aws_subnet.public_net.0.id}"
#  depends_on = ["aws_internet_gateway.igw"]
#}

resource "aws_route_table" "def_private" {
  vpc_id = "${aws_vpc.kim_vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    instance_id = "${aws_instance.bastion.id}"
#    nat_gateway_id = "${aws_nat_gateway.gw.id}"
  }
  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.project_name}.def_private_route"
    )
  )}"
}
resource "aws_route_table_association" "def_private" {
  route_table_id = "${aws_route_table.def_private.id}"
  count = "${var.count}"
#  count = "${length(var.vpc_zones)}"
  subnet_id = "${element(aws_subnet.private_net.*.id, count.index)}"
}

