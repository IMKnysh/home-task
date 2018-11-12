output "vpc_id" {
  value = "${aws_vpc.kim_vpc.id}"
}
output "public_subnet_cidr" {
  value = "${aws_subnet.public_net.*.cidr_block}"
}
output "public_subnet_id" {
  value = ["${aws_subnet.public_net.0.id}"]
}
output "public_subnet_ids" {
  value = ["${aws_subnet.public_net.*.id}"]
}
output "bastion_sg_id" {
  value = "${aws_security_group.bastion_sg.id}"
}
output "intra_sg" {
  value = "${aws_security_group.intra.id}"
}
output "private_subnet_cidr" {
  value = ["${aws_subnet.private_net.*.cidr_block}"]
}
output "private_subnet_id" {
  value = ["${aws_subnet.private_net.*.id}"]
}
output "nat_id" {
  value = "${aws_instance.bastion.id}"
}
output "bastion_ip" {
  value = "${aws_instance.bastion.public_ip}"
}