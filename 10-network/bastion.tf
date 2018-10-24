resource "aws_instance" "bastion" {
  ami = "${var.amis_nat}"
  instance_type = "${var.instance_type_default}"
  subnet_id = "${aws_subnet.public_net.0.id}"
  key_name = "${var.key_name}"
  security_groups = ["${aws_security_group.bastion_sg.id}", "${aws_security_group.nat_sg.id}"]
  associate_public_ip_address = true
  source_dest_check = false
  user_data = "${data.template_cloudinit_config.user_data.rendered}"
  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.project_name}.bastion"
    )
  )}"
}

data "template_cloudinit_config" "user_data" {
  part {
    content = <<EOF
#cloud-config
---
package_upgrade: true
runcmd:
- yum update -y
EOF
  }
}