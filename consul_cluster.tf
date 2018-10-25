resource "aws_instance" "consul" {
  ami = "${data.aws_ami.compute.id}"
  instance_type = "${var.instance_type_default}"
  count = "${var.count_app_instances}"
  subnet_id = "${element(module.network.private_subnet_id, count.index)}"
  key_name = "${var.key_name}"
  security_groups = ["${module.network.intra_sg}"]
  associate_public_ip_address = false
  user_data = "${data.template_cloudinit_config.user_data.rendered}"
  depends_on = ["module.network"]
  iam_instance_profile = "${aws_iam_instance_profile.ec2_descr_profile.name}"
  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.project_name}.consul-${count.index}",
      "Consul", "Server"
    )
  )}"
}

data "template_file" "consul" {
  template                    = "${file("templates/user_data.tmpl")}"
  vars {
    var.count_srv = "${var.count_app_instances}"
    var.region = "${var.region}"
    var.count.index = "${count.index}"
    var.ca_public_key = "${module.tls.ca_public_key}"
    var.public_key_srv = "${module.tls.public_key_srv}"
    var.private_key = "${module.tls.private_key}"
    var.consul_encrypt = "${random_id.consul_encrypt.b64_std}"
  }
}

data "template_cloudinit_config" "user_data" {
  part {
    filename = "consul_run.sh"
    content_type = "text/x-shellscript"
    content = "${data.template_file.consul.rendered}"
  }
}

resource "aws_iam_role_policy" "ec_describe_policy" {
  name = "EC2_describe__policy"
  role = "${aws_iam_role.ec2_describe_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:Describe*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "ec2_describe_role" {
  name = "EC2_describe_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "ec2_descr_profile" {
  name = "ec2_descr_profile"
  role = "${aws_iam_role.ec2_describe_role.name}"
}

resource "random_id" "consul_encrypt" {
    byte_length = 16
}