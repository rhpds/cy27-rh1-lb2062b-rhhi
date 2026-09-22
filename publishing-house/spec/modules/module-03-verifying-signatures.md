# Module Outline: Verifying Published Signatures

**Module ID:** module-03
**Duration:** 15 min
**File:** `content/modules/ROOT/pages/module-03-verifying-signatures.adoc`

---

### Brief Overview

Before learners sign their own images, they verify that Red Hat already signs its published images — and learn exactly how that works. This module uses Cosign to verify cryptographic signatures on `hi/python:3.12` (hardened) and `ubi10/ubi:latest`, using two trust anchors: a remote public key URL from `security.access.redhat.com` and the local RHEL signing key at `/etc/pki/sigstore/`. Signature JSON output is intentionally discarded — the focus is on the verification result and the trust model, not the envelope fields. The module explains why the lab skips tlog verification and what the Rekor log adds in production.

### Audience and Time

- **Personas:** DevSecOps practitioners, security-conscious developers, platform engineers
- **Prerequisites for this module:** Module-01 complete (Podman socket enabled); network access to `registry.access.redhat.com` and `security.access.redhat.com`
- **Duration:** 15 minutes

### Learning Objectives

- Verify a Red Hat Hardened Image signature using Cosign against a remote public key URL
- Verify a UBI image signature using the local RHEL release signing key on disk
- Understand the role of the Rekor transparency log and why tlog verification is skipped in lab environments
- Understand that both the URL-based and local-key verification methods use the same underlying signing key

### Lab Structure

| Section | Title | Duration |
|---------|-------|----------|
| 1 | Introduction | 2 min |
| 2 | About Cosign and the Transparency Log | 3 min |
| 3 | Verify the Python Base Image Signature | 4 min |
| 4 | Verify the UBI Image Signature | 4 min |
| 5 | Summary | 2 min |

### Detailed Steps

1. Read the introduction panel explaining OCI image signing: signatures are stored as OCI artifacts alongside the image, referenced by a `.sig` tag suffix derived from the image digest.
2. Read the Cosign/Rekor sidebar: Rekor is the Sigstore transparency log — a public, append-only ledger that makes signatures auditable and non-repudiable. Explain why `--insecure-ignore-tlog` is used in this lab (avoiding noise on the public Sigstore instance from lab-generated key pairs; production should always use the transparency log).
3. Explain that the remote key URL (`https://security.access.redhat.com/...`) is the canonical public key endpoint, and that `/etc/pki/sigstore/` on RHEL contains the same key for offline use.
4. Verify the hardened Python image signature using the remote key URL; discard JSON output to focus on the verification result:
   ```
   cosign verify --insecure-ignore-tlog --key https://security.access.redhat.com/... \
     registry.access.redhat.com/hi/python:3.12 > /dev/null
   ```
5. Note: JSON signature output is intentionally discarded — in practice it could be piped to other tools, but digests and signature payloads are not human-readable in any useful sense.
6. Verify the UBI image signature using the local RHEL key file:
   ```
   cosign verify --insecure-ignore-tlog --key /etc/pki/sigstore/SIGSTORE-redhat-release3 \
     registry.access.redhat.com/ubi10/ubi:latest > /dev/null
   ```
7. Explain that both approaches use the same underlying key — the URL method works anywhere with HTTPS egress; the local key works in air-gapped environments.
8. Read the summary panel: every Red Hat image on `registry.access.redhat.com` is signed; learners will replicate this workflow for their own images in modules 04 and 05.

### Key Takeaways

- OCI image signatures are stored as OCI artifacts tagged with a `.sig` suffix derived from the image digest — no external signature database needed.
- Cosign verification requires only the image reference and a public key; the signature artifact is fetched automatically.
- Rekor adds non-repudiation and auditability — in production, do not skip `--insecure-ignore-tlog`; the lab skips it to avoid adding noise to the public Sigstore instance.
- Red Hat publishes signing keys at `security.access.redhat.com`; RHEL also bundles the key at `/etc/pki/sigstore/` for offline verification.

### Infrastructure Notes

- Requires outbound access to `registry.access.redhat.com` and `security.access.redhat.com` from the student VM.
- The exact Red Hat public key URL should be validated against the current release key at lab delivery time; key URLs can change across RHEL major versions.
- `--insecure-ignore-tlog` is intentional for lab cleanliness; the content includes a callout box explaining this is not the recommended production flag.
