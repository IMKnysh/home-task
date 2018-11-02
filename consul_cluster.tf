resource "aws_instance" "consul" {
  ami = "${data.aws_ami.compute.id}"
  instance_type = "${var.instance_type_default}"
  count = "${var.count_app_instances}"
  key_name = "${var.key_name}"
  user_data = "${element(data.template_cloudinit_config.user_data.*.rendered, count.index)}"
  depends_on = ["module.network"]
  iam_instance_profile = "${aws_iam_instance_profile.ec2_descr_profile.name}"
  network_interface {
    network_interface_id = "${element(aws_network_interface.net_if.*.id, count.index)}"
    device_index = 0
  }
  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.project_name}.consul-${count.index}",
      "Consul", "Server"
    )
  )}"
}

resource "aws_ssm_parameter" "create_ssm_path" {
  name  = "/vault/vault"
  description  = "Vault parameters"
  type  = "String"
  value = "vault parameters"
}

resource "aws_network_interface" "net_if" {
  count = "${var.count_app_instances}"
  subnet_id = "${element(module.network.private_subnet_id, count.index)}"
  security_groups = ["${module.network.intra_sg}"]
  tags {
    Name = "primary_network_interface"
  }
}

module "tls_keys" {
  source = "./20-tls-key"
  region = "${var.region}"
  count_app_instances = "${var.count_app_instances}"
  tls_private_key_ca_algorithm = "${module.tls.tls_private_key_ca_algorithm}"
  tls_private_key_ca_private_key_pem = "${module.tls.tls_private_key_ca_private_key_pem}"
  tls_self_signed_cert_ca_cert_pem = "${module.tls.tls_self_signed_cert_ca_cert_pem}"
  net_if_priv_ip = "${aws_network_interface.net_if.*.private_ip}"
}

module "tls_keys_vault" {
  source = "./20-tls-key"
  region = "${var.region}"
  count_app_instances = "${var.vault_srv}"
  tls_private_key_ca_algorithm = "${module.tls.tls_private_key_ca_algorithm}"
  tls_private_key_ca_private_key_pem = "${module.tls.tls_private_key_ca_private_key_pem}"
  tls_self_signed_cert_ca_cert_pem = "${module.tls.tls_self_signed_cert_ca_cert_pem}"
  net_if_priv_ip = "${aws_network_interface.net_if.*.private_ip}"
}

data "template_file" "consul" {
  count = "${var.count_app_instances}"
  template = "${file("templates/user_data_consul.tmpl")}"
  vars {
    var.count_srv = "${var.count_app_instances}"
    var.region = "${var.region}"
    var.ca_public_key = "${module.tls.ca_public_key}"
    var.public_key = "${element(module.tls_keys.public_key, count.index)}"
    var.private_key = "${element(module.tls_keys.private_key, count.index)}"
    var.consul_encrypt = "${random_id.consul_encrypt.b64_std}"
    var.consul_acl_master_token = "${random_id.consul_acl_master_token.b64_url}"
    var.consul_acl_agent_token = "${random_id.consul_acl_agent_token.b64_url}"
  }
}

data "template_file" "vault" {
  count = "${var.vault_srv}"
  template = "${file("templates/user_data_vault.tmpl")}"
  vars {
    var.count_srv = "${var.vault_srv}"
    var.region = "${var.region}"
    var.ca_public_key = "${module.tls.ca_public_key}"
    var.public_key = "${element(module.tls_keys_vault.public_key, count.index)}"
    var.private_key = "${element(module.tls_keys_vault.private_key, count.index)}"
    var.consul_acl_master_token = "${random_id.consul_acl_master_token.b64_url}"
    var.consul_acl_vault_token = "${random_id.consul_acl_vault_token.b64_url}"
  }
}
data "template_file" "nomad" {
  count = "${var.vault_srv}"
  template = "${file("templates/user_data_nomad.tmpl")}"
  vars {
    var.count_srv = "${var.vault_srv}"
    var.region = "${var.region}"
    var.ca_public_key = "${module.tls.ca_public_key}"
    var.public_key = "${element(module.tls_keys_vault.public_key, count.index)}"
    var.private_key = "${element(module.tls_keys_vault.private_key, count.index)}"
    var.consul_acl_master_token = "${random_id.consul_acl_master_token.b64_url}"
    var.consul_acl_vault_token = "${random_id.consul_acl_vault_token.b64_url}"
    var.nomad_ver = "${var.nomad_ver}"
  }
}

data "template_cloudinit_config" "user_data" {
  count = "${var.count_app_instances}"
  part {
    filename = "01_consul_run.sh"
    content_type = "text/x-shellscript"
    content = "${element(data.template_file.consul.*.rendered, count.index)}"
  }
  part {
    filename = "02_vault_run.sh"
    content_type = "text/x-shellscript"
    content = "${element(data.template_file.vault.*.rendered, count.index)}"
  }
  part {
    filename = "03_nomad_run.sh"
    content_type = "text/x-shellscript"
    content = "${element(data.template_file.nomad.*.rendered, count.index)}"
  }
}

resource "aws_iam_role_policy" "ec_describe_policy" {
  name = "EC2_describe__policy"
  role = "${aws_iam_role.ec2_describe_role.id}"
  depends_on = ["aws_ssm_parameter.create_ssm_path"]

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
    },
    {
      "Sid": "VisualEditor0",
      "Effect": "Allow",
      "Action": [
         "ssm:PutParameter",
         "ssm:DeleteParameter",
         "ssm:GetParametersByPath",
         "ssm:GetParameters",
         "ssm:GetParameter",
         "ssm:DeleteParameters"
            ],
            "Resource": "arn:aws:ssm:${var.region}:*:parameter/*"
    },
    {
      "Sid": "VisualEditor1",
      "Effect": "Allow",
      "Action": "ssm:DescribeParameters",
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

resource "random_id" "consul_acl_master_token" {
  byte_length = 16
}
resource "random_id" "consul_acl_agent_token" {
  byte_length = 16
}
resource "random_id" "consul_acl_vault_token" {
  byte_length = 16
}
