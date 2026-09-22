# Module Outline: Image Digests and Mirroring

**Module ID:** module-04
**Duration:** 20 min
**File:** `content/modules/ROOT/pages/module-04-signing-setup.adoc`

---

### Brief Overview

This module covers the practical reality of operating images in a private registry. Learners compare digests between the vendor registry and a local Podman pull to understand multi-architecture manifest handling. They then use Skopeo to mirror `hi/python:3.12` into their per-student registry with `--all --preserve-digests --remove-signatures` — first observing a failure when the vendor's OCI signature artifacts cannot be copied, then correcting it by explicitly removing signatures. They confirm the mirror digest matches the vendor's, then attempt to verify the mirrored image and observe the expected signature gap. The module closes by pushing the application image to the local registry by digest for use in module-05.

### Audience and Time

- **Personas:** DevSecOps practitioners, security-conscious developers, platform engineers
- **Prerequisites for this module:** Module-03 complete (Cosign verified, concepts understood); student has registry access at `registry-{guid}.{domain}`
- **Duration:** 20 minutes

### Learning Objectives

- Understand how multi-architecture image digests differ between a full registry manifest and a single-platform pull
- Mirror a vendor image into a private registry using Skopeo with digest preservation and signature removal
- Confirm that a preserved-digest mirror is bit-for-bit identical to the vendor's image
- Identify the signature gap created by mirroring and understand why it must be closed with a local signature
- Push an application image to the local registry and capture its digest for use in signing

### Lab Structure

| Section | Title | Duration |
|---------|-------|----------|
| 1 | Introduction | 2 min |
| 2 | Digests and How Mirroring Works | 4 min |
| 3 | Your Local Container Registry | 2 min |
| 4 | Mirror the Python Base Image | 4 min |
| 5 | Copy With a Preserved Digest | 4 min |
| 6 | Confirm the Signature Gap | 2 min |
| 7 | Push Your Application Image | 2 min |

### Detailed Steps

1. Read the introduction: most organizations mirror vendor images into private registries for availability and air-gap reasons; moving images can affect the trust chain if done carelessly.
2. Compare the local Podman digest for `hi/python:3.12` against the vendor registry digest using `skopeo inspect`, saving the vendor digest: `podman image inspect hi/python:3.12 --format '{{.Digest}}'` and `skopeo inspect docker://{rhhi-registry}/python:3.12 | jq -r .Digest | tee vendor.digest`
3. Observe that the two digests differ: Podman pulled only the `amd64` platform manifest, producing a single-platform digest; the registry holds the full multi-architecture index digest. Explain that `skopeo copy --all --preserve-digests` copies the index and all platform manifests without recomputing.
4. Read the registry overview panel: each student has a TLS-enabled registry at `registry-{guid}.{domain}`; credentials are pre-configured; the `REGISTRY` environment variable is set in `~/.bashrc`.
5. Attempt to mirror the vendor image with default `skopeo copy --all`: observe the failure — Skopeo attempts to copy OCI signature artifacts but the destination registry has signature writing disabled.
6. Explain why: Cosign signatures are OCI artifacts stored alongside the image in the source registry; `skopeo copy` attempts to carry them, fails. The solution is to remove signatures at copy time.
7. Mirror correctly: `skopeo copy --all --preserve-digests --remove-signatures --digestfile ~/python.digest docker://{rhhi-registry}/python:3.12 docker://registry-{guid}.{domain}/python:3.12`
8. Compare the mirror digest against the saved vendor digest to confirm they match: `skopeo inspect docker://registry-{guid}.{domain}/python:3.12 | jq -r .Digest` and `cat vendor.digest`
9. Confirm the signature gap: attempt `cosign verify --insecure-ignore-tlog --key ... registry-{guid}.{domain}/python:3.12` and observe the "no matching signatures" error.
10. Explain: the image is in the local registry with its digest intact, but no signature. Module-05 closes this gap.
11. Tag and push the application image: `podman tag rhhi-demo:hardened registry-{guid}.{domain}/rhhi-demo:hardened` then `podman push --digestfile ~/image.digest registry-{guid}.{domain}/rhhi-demo:hardened`
12. Capture and display the digest: `IMAGE_DIGEST=$(cat ~/image.digest); echo "Image digest: ${IMAGE_DIGEST}"`
13. Read the summary: both images are now in the local registry; both are unsigned; module-05 provides the signatures.

### Key Takeaways

- Multi-architecture images have a different digest in the full registry index vs. a single-platform local pull; `skopeo copy --all --preserve-digests` is the correct tool for mirroring.
- Cosign signatures are OCI artifacts in the source registry — `skopeo copy` attempts to carry them and fails if the destination disables signature writes; `--remove-signatures` is the correct flag.
- `--preserve-digests` ensures the mirror digest matches the vendor's, making the images provably identical without a vendor signature.
- A mirrored image without a local signature has a "signature gap" — it cannot be verified by consumers until re-signed.
- `podman push --digestfile` captures the registry-assigned digest for use in signing.

### Infrastructure Notes

- The per-student registry hostname follows the pattern `registry-{guid}.{domain}`; values are injected as environment variables by the lab platform.
- The registry is TLS-enabled and open (no login required) for lab simplicity.
- The `REGISTRY` environment variable is set in `~/.bashrc` by setup automation.
- `skopeo` must be installed and in PATH; setup automation handles this.
