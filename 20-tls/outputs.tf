output "ca_public_key" {
  value = "${tls_self_signed_cert.ca.cert_pem}"
}

output "public_key_srv" {
  value = "${tls_locally_signed_cert.cert_srv.cert_pem}"
}
output "private_key" {
  value = "${tls_private_key.cert.private_key_pem}"
}