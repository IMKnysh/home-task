output "ca_public_key" {
  value = "${tls_self_signed_cert.ca.cert_pem}"
}

output "tls_private_key_ca_algorithm" {
  value = "${tls_private_key.ca.algorithm}"
}
output "tls_private_key_ca_private_key_pem" {
  value = "${tls_private_key.ca.private_key_pem}"
}
output "tls_self_signed_cert_ca_cert_pem" {
  value = "${tls_self_signed_cert.ca.cert_pem}"
}