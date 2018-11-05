resource "aws_instance" "app" {
  ami = "${data.aws_ami.compute.id}"
  instance_type = "${var.instance_type_default}"
  count = "${var.count_app}"
  key_name = "${var.key_name}"
  user_data = "${element(data.template_cloudinit_config.user_data_app.*.rendered, count.index)}"
  depends_on = ["module.network"]
  iam_instance_profile = "${aws_iam_instance_profile.ec2_descr_profile.name}"
  network_interface {
    network_interface_id = "${element(aws_network_interface.net_if_app.*.id, count.index)}"
    device_index = 0
  }
  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.project_name}.app-${count.index}",
      "App", "Instance"
    )
  )}"
}

resource "aws_network_interface" "net_if_app" {
  count = "${var.count_app}"
  subnet_id = "${element(module.network.private_subnet_id, count.index)}"
  security_groups = ["${module.network.intra_sg}"]
  tags {
    Name = "primary_network_interface_app"
  }
}
data "template_file" "nomad_client" {
  count = "${var.count_app}"
  template = "${file("templates/user_data_nomad_app.tmpl")}"
  vars {
    var.count_srv = "${var.count_app}"
    var.region = "${var.region}"
    var.ca_public_key = "${module.tls.ca_public_key}"
    var.public_key = "${element(module.tls_keys.public_key, count.index)}"
    var.private_key = "${element(module.tls_keys.private_key, count.index)}"
    var.consul_encrypt = "${random_id.consul_encrypt.b64_std}"
    var.consul_acl_master_token = "${random_id.consul_acl_master_token.b64_url}"
    var.consul_acl_agent_token = "${random_id.consul_acl_agent_token.b64_url}"
    var.nomad_ver = "${var.nomad_ver}"
  }
}

data "template_file" "consul_client" {
  count = "${var.count_app}"
  template = "${file("templates/user_data_consul_app.tmpl")}"
  vars {
    var.count_srv = "${var.count_app}"
    var.region = "${var.region}"
    var.ca_public_key = "${module.tls.ca_public_key}"
    var.public_key = "${element(module.tls_keys.public_key, count.index)}"
    var.private_key = "${element(module.tls_keys.private_key, count.index)}"
    var.consul_encrypt = "${random_id.consul_encrypt.b64_std}"
    var.consul_acl_master_token = "${random_id.consul_acl_master_token.b64_url}"
    var.consul_acl_agent_token = "${random_id.consul_acl_agent_token.b64_url}"
  }
}

data "template_cloudinit_config" "user_data_app" {
  count = "${var.count_app}"
  part {
    filename = "nomad_client_run.sh"
    content_type = "text/x-shellscript"
    content = "${element(data.template_file.nomad_client.*.rendered, count.index)}"
  }
  part {
    filename = "consul_client_run.sh"
    content_type = "text/x-shellscript"
    content = "${element(data.template_file.consul_client.*.rendered, count.index)}"
  }
}
