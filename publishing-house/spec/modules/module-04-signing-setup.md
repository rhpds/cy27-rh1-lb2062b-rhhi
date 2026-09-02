# Module Outline: Image Signing Setup (Push and Generate Keys)

**Module ID:** module-04
**Duration:** 20 min
**File:** `content/modules/ROOT/pages/module-04-signing-setup.adoc`

---

### Brief Overview

This module is the setup phase for the signing workflow. Learners push their application image (`rhhi-demo:hardened`) to their per-student local OCI registry, capture the immutable image digest, and generate a Cosign key pair. They then use Skopeo to mirror the Red Hat `hi/python:3.12` base image into their registry — first observing a deliberate failure (mirroring without preserving the original signature), then correcting it with `--preserve-digests --remove-signatures`. The module drives home the distinction between a tag (mutable), a digest (immutable), and a signature (a separate OCI artifact) and sets up the "proof-of-origin gap" that is closed in module-05.

### Audience and Time

- **Personas:** DevSecOps practitioners, security-conscious developers, platform engineers
- **Prerequisites for this module:** Module-03 complete (Cosign verified, concepts understood); student has valid registry credentials at `registry-{guid}.{domain}`
- **Duration:** 20 minutes

### Learning Objectives

- Push a container image to a per-student TLS-enabled OCI registry using Podman and capture its immutable digest
- Generate a Cosign key pair for image signing
- Mirror a vendor image into a private registry using Skopeo with correct flags to preserve digests
- Explain the distinction between an image tag, a digest, and an OCI signature artifact

### Lab Structure

| Section | Title | Duration |
|---------|-------|----------|
| 1 | Your Local Container Registry | 2 min |
| 2 | Tag and Push the Image | 4 min |
| 3 | Capture the Image Digest | 2 min |
| 4 | Generate a Cosign Key Pair | 3 min |
| 5 | Mirror a Vendor Image to Your Registry | 4 min |
| 6 | What the Mirror Keeps: the Digest | 2 min |
| 7 | What the Mirror Loses: Proof of Origin | 2 min |
| 8 | Summary | 1 min |

### Detailed Steps

1. Read the registry overview panel: each student has a dedicated TLS-enabled registry at `registry-{guid}.{domain}` (where `{guid}` and `{domain}` are environment variables set by the lab platform). Credentials are pre-configured in `/run/user/UID/containers/auth.json`.
2. Tag the application image for the student registry: `podman tag rhhi-demo:hardened registry-${GUID}.${DOMAIN}/rhhi-demo:hardened`
3. Push the image and capture the digest simultaneously: `podman push --digestfile ~/image.digest registry-${GUID}.${DOMAIN}/rhhi-demo:hardened`
4. Display the digest: `cat ~/image.digest`
5. Explain digest format (`sha256:...`): it is a cryptographic hash of the image manifest; any change to the image changes the digest; the tag is just a pointer that can be moved.
6. Export the digest as a shell variable: `IMAGE_DIGEST=$(cat ~/image.digest)`
7. Generate a Cosign key pair interactively: `cosign generate-key-pair`
8. Observe that Cosign produces `cosign.key` (encrypted private key) and `cosign.pub` (public key) in the current directory. Note the passphrase prompt — for the lab, an empty passphrase is acceptable.
9. List the key files: `ls -lh cosign.key cosign.pub`
10. Attempt to mirror the Red Hat Python image with default flags (intentional failure):
    ```
    skopeo copy docker://registry.access.redhat.com/hi/python:3.12 \
      docker://registry-${GUID}.${DOMAIN}/python:3.12
    ```
11. Observe that the copy succeeds but the original signatures are stripped. Explain why: Skopeo copies the manifest and layers but does not copy OCI signature artifacts by default.
12. Mirror correctly with digest and signature preservation flags:
    ```
    skopeo copy --all --preserve-digests --remove-signatures \
      docker://registry.access.redhat.com/hi/python:3.12 \
      docker://registry-${GUID}.${DOMAIN}/python:3.12
    ```
13. Read the "What the Mirror Keeps / Loses" comparison sidebar:
    - Keeps: image layers, manifest, original digest (content integrity intact).
    - Loses: Red Hat's original signature (proof-of-origin is broken; the mirrored image has no valid signature in the new registry).
14. Read the summary: the gap — a correctly digested image with no signature — is exactly what module-05 closes.

### Key Takeaways

- Image digests are immutable; signing by digest (not by tag) ensures you sign exactly what you intend.
- `podman push --digestfile` captures the registry-assigned digest for later use in signing and verification steps.
- Cosign key pairs are standard PEM-encoded keys; the private key is encrypted with a passphrase.
- Skopeo's `--preserve-digests` maintains content integrity across registries; `--remove-signatures` drops the vendor's OCI signature artifacts (because they reference the source registry, not your registry).
- Mirroring without re-signing creates a "proof-of-origin gap" — the image is bit-for-bit identical to the vendor's, but downstream consumers cannot verify that without your attestation.

### Infrastructure Notes

- The per-student registry hostname follows the pattern `registry-{guid}.{domain}`; the values are injected as environment variables (`GUID`, `DOMAIN`) by the lab platform.
- The registry must have a valid TLS certificate; setup automation provisions the cert and pre-configures `/etc/containers/registries.conf` to trust it.
- ZeroSSL is listed as the TLS certificate provider in the content analysis — the writer should include a brief note on how the certificate is provisioned without requiring learner action.
- `skopeo` and `cosign` must be installed and in PATH; setup automation handles this.
