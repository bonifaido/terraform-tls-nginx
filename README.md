# Client verification with Terraform generated certificates and nginx

Generates a CA certificate, a server certificate and a client certificate based on the CA, then runs NGINX with SSL based client verificate via the client certificate.

## Dependencies

- terraform
- openssl
- httpie or curl (curl doesn't work well with client certificates on OS X (they have to be in KeyChain), to overcome this install it with OpenSSL support `brew install curl --with-openssl`)


## Workflow

```bash
terraform plan
terraform apply
nginx -p . -c nginx.conf
# With HTTPie
http --verify no --cert johndoe.crt --cert-key johndoe.key https://localhost:8080
# Or with NGiNX
curl -vk --cert ./johndoe.crt --key ./johndoe.key https://localhost:8080
```

# TODO
- CRL (Certificate Revocation List support)
