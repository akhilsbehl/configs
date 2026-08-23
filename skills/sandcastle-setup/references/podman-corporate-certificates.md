# Podman corporate certificates

Use this reference when a Sandcastle image build fails with TLS errors such as:

- `curl: (60) SSL certificate problem`
- Debian cannot fetch repository metadata.
- npm reports `UNABLE_TO_GET_ISSUER_CERT_LOCALLY`.

The host trust store is not automatically present in a Podman build.

## Procedure

1. Check that `$NODE_EXTRA_CA_CERTS` points to a readable certificate file.
2. Copy it into the ignored Sandcastle build context:

   ```bash
   cp "$NODE_EXTRA_CA_CERTS" .sandcastle/extra-certs.crt
   ```

3. Add `extra-certs.crt` to `.sandcastle/.gitignore`.
4. Place this before network-dependent `apt`, `curl`, and npm commands in `.sandcastle/Containerfile`:

   ```dockerfile
   COPY extra-certs.crt /usr/local/share/ca-certificates/extra-certs.crt
   RUN update-ca-certificates

   ENV NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt \
       NODE_USE_SYSTEM_CA=1
   ```

5. Preserve Debian's system CA bundle. Do not replace it with only the corporate certificate.
6. Rebuild with:

   ```bash
   npx @ai-hero/sandcastle podman build-image
   ```

The build context must include `.sandcastle/extra-certs.crt`; do not assume `/tmp/host-ca` exists in the build context.
