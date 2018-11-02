
# ---------------------------------------------------------------------------------------------------------------------
# CREATE A TLS CERTIFICATE SIGNED USING THE CA CERTIFICATE
# ---------------------------------------------------------------------------------------------------------------------

resource "tls_private_key" "cert" {
  count = "${var.count_app_instances}"
  algorithm   = "${var.private_key_algorithm}"
  rsa_bits    = "${var.private_key_rsa_bits}"
}

resource "tls_cert_request" "cert" {
  count = "${var.count_app_instances}"
  key_algorithm   = "${var.private_key_algorithm}"
  private_key_pem = "${element(tls_private_key.cert.*.private_key_pem, count.index)}"

  dns_names    = ["ip-${replace(element(var.net_if_priv_ip, count.index ),"." , "-" )}.${var.region}.consul"]
  ip_addresses = ["${element(var.net_if_priv_ip, count.index )}", "127.0.0.1"]

  subject {
    common_name  = "ip-${replace(element(var.net_if_priv_ip, count.index ),"." , "-" )}.${var.region}.consul"
    organization = "${var.organization_name}"
  }
}

resource "tls_locally_signed_cert" "cert" {
  count = "${var.count_app_instances}"
  cert_request_pem = "${element(tls_cert_request.cert.*.cert_request_pem, count.index)}"

  ca_key_algorithm   = "${var.tls_private_key_ca_algorithm}"
  ca_private_key_pem = "${var.tls_private_key_ca_private_key_pem}"
  ca_cert_pem        = "${var.tls_self_signed_cert_ca_cert_pem}"

  validity_period_hours = "${var.validity_period_hours}"
  allowed_uses          = ["${var.allowed_uses}"]
}
