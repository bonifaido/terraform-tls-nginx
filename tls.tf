resource "tls_private_key" "ca" {
  algorithm   = "RSA"
  ecdsa_curve = "2048"
}

resource "tls_self_signed_cert" "ca" {
  key_algorithm   = "${tls_private_key.ca.algorithm}"
  private_key_pem = "${tls_private_key.ca.private_key_pem}"

  subject {
    common_name         = "Example Inc. Root"
    organization        = "Example, Inc"
    organizational_unit = "Department of Certificate Authority"
    street_address      = ["5879 Cotton Link"]
    locality            = "Pirate Harbor"
    province            = "CA"
    country             = "US"
    postal_code         = "95559-1227"
  }

  validity_period_hours = 17520

  is_ca_certificate = true

  allowed_uses = ["cert_signing"]
}

resource "local_file" "ca_key" {
  content  = "${tls_private_key.ca.private_key_pem}"
  filename = "${path.module}/ca.key"
}

resource "local_file" "ca_crt" {
  content  = "${tls_self_signed_cert.ca.cert_pem}"
  filename = "${path.module}/ca.crt"
}

# server tls certificate

resource "tls_private_key" "server" {
  algorithm   = "RSA"
  ecdsa_curve = "2048"
}

resource "tls_self_signed_cert" "server" {
  key_algorithm   = "${tls_private_key.server.algorithm}"
  private_key_pem = "${tls_private_key.server.private_key_pem}"

  subject {
    common_name         = "localhost"
    organization        = "Example, Inc"
    organizational_unit = "Tech Ops Dept"
  }

  validity_period_hours = 17520
  early_renewal_hours   = 8760

  allowed_uses = ["server_auth"]

  dns_names = ["localhost"]
}

resource "local_file" "server_key" {
  content  = "${tls_private_key.server.private_key_pem}"
  filename = "${path.module}/server.key"
}

resource "local_file" "server_crt" {
  content  = "${tls_self_signed_cert.server.cert_pem}"
  filename = "${path.module}/server.crt"
}

# client tls certificate

resource "tls_private_key" "johndoe" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "johndoe" {
  key_algorithm   = "${tls_private_key.johndoe.algorithm}"
  private_key_pem = "${tls_private_key.johndoe.private_key_pem}"

  subject {
    common_name         = "johndoe@gmail.com"
    organization        = "Example, Inc"
    organizational_unit = "Tech Ops Dept"
  }
}

resource "tls_locally_signed_cert" "johndoe" {
  cert_request_pem   = "${tls_cert_request.johndoe.cert_request_pem}"
  ca_key_algorithm   = "${tls_self_signed_cert.ca.key_algorithm}"
  ca_private_key_pem = "${tls_private_key.ca.private_key_pem}"
  ca_cert_pem        = "${tls_self_signed_cert.ca.cert_pem}"

  validity_period_hours = 17520

  allowed_uses = [
    "client_auth",
  ]
}

resource "local_file" "johndoe_key" {
  content  = "${tls_private_key.johndoe.private_key_pem}"
  filename = "${path.module}/johndoe.key"
}

resource "local_file" "johndoe_crt" {
  content  = "${tls_locally_signed_cert.johndoe.cert_pem}"
  filename = "${path.module}/johndoe.crt"

  depends_on = ["local_file.johndoe_key"]

  # Create a pkcs12 version as well for OS X
  provisioner "local-exec" {
    command = "openssl pkcs12 -export -clcerts -out johndoe.p12 -inkey johndoe.key -in johndoe.crt -certfile ca.crt -password pass:johndoe01"
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "rm johndoe.p12"
  }
}

# Some useful commands

# Connect with httpie
# http --verify no --cert johndoe.crt --cert-key johndoe.key https://localhost:8080

# Connect with openssl
# openssl s_client -connect localhost:8080 -prexit -CAfile ca.crt -cert johndoe.crt -key johndoe.key

# Check cert
# openssl x509 -text -in ca.crt

# Check signing
# openssl verify -CAfile ca.crt johndoe.crt
