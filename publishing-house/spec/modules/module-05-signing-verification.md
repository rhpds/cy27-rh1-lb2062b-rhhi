# Module Outline: Image Signing and Verification

**Module ID:** module-05
**Duration:** 20 min
**File:** `content/modules/ROOT/pages/module-05-signing-verification.adoc`

---

### Brief Overview

This module completes the core signing workflow. Learners first generate a Cosign key pair, then sign their pushed application image by digest and verify the signature as a downstream consumer would. They then close the "proof-of-origin gap" established in module-04 by signing the mirrored `python:3.12` vendor image under their own key pair — establishing a single organizational trust boundary in their registry. Signature OCI artifact storage (`.sig` tag suffix) is examined using Skopeo to connect the theoretical model from module-03 to the learner's own artifacts.

### Audience and Time

- **Personas:** DevSecOps practitioners, security-conscious developers, platform engineers
- **Prerequisites for this module:** Module-04 complete (application image pushed, digest captured at `~/image.digest`; vendor image mirrored with digest preserved at `~/python.digest`)
- **Duration:** 20 minutes

### Learning Objectives

- Generate a Cosign key pair for image signing
- Sign a container image by digest using Cosign with a local key pair
- Verify an OCI image signature using Cosign from the consumer's perspective
- Sign a mirrored vendor image to establish organizational custody in a private registry
- Inspect OCI signature artifacts stored in a registry using Skopeo to confirm the `.sig` tag structure

### Lab Structure

| Section | Title | Duration |
|---------|-------|----------|
| 1 | Generate a Cosign Key Pair | 3 min |
| 2 | Sign the Image | 5 min |
| 3 | Verify the Signature | 4 min |
| 4 | Re-sign the Mirrored Image | 5 min |
| 5 | Summary | 3 min |

### Detailed Steps

1. Set an empty passphrase for the lab key pair: `export COSIGN_PASSWORD=""`
2. Generate a Cosign key pair: `cosign generate-key-pair`
3. Observe that Cosign produces `cosign.key` (encrypted private key) and `cosign.pub` (public key). Note that empty passphrases are for lab use only; production key strategies include OIDC keyless signing, KMS-backed keys, or HSMs.
4. Confirm the `IMAGE_DIGEST` variable is set from `~/image.digest`: `IMAGE_DIGEST=$(cat ~/image.digest)`
5. Sign the application image by digest — note the `@${IMAGE_DIGEST}` syntax, not the tag:
   ```
   cosign sign --tlog-upload=false --yes --key cosign.key \
     registry-{guid}.{domain}/rhhi-demo@${IMAGE_DIGEST}
   ```
6. Observe the Cosign output confirming the signature was pushed to the registry.
7. Explain `--tlog-upload=false`: skips Rekor upload for lab cleanliness; in production, omit this flag.
8. Verify the signature as a consumer would, using a tag reference:
   ```
   cosign verify --insecure-ignore-tlog=true --key cosign.pub \
     registry-{guid}.{domain}/rhhi-demo:hardened
   ```
9. Observe successful verification output including the brief JSON signature payload.
10. Use Skopeo to list all tags in the student registry for `rhhi-demo`: `skopeo list-tags docker://registry-{guid}.{domain}/rhhi-demo`
11. Identify the `.sig` tag (format: `sha256-<digest-hex>.sig`). Explain that this is the OCI artifact storing the signature blob alongside the image.
12. Close the mirror gap: load the preserved vendor digest: `PYTHON_DIGEST=$(cat ~/python.digest)`
13. Sign the mirrored vendor image under the student's own key:
    ```
    cosign sign --tlog-upload=false --yes --key cosign.key \
      registry-{guid}.{domain}/python@${PYTHON_DIGEST}
    ```
14. Verify the custody signature: `cosign verify --insecure-ignore-tlog=true --key cosign.pub registry-{guid}.{domain}/python:3.12`
15. Confirm verification passes. Both images in the registry now carry signatures under the student's key.

### Key Takeaways

- Always sign by digest, not by tag; the digest is immutable whereas the tag can be moved to a different image.
- The `.sig` OCI artifact is stored in the same registry as the image — no external signature service needed.
- Signing the mirrored vendor image under your own key establishes organizational custody: downstream systems verify your signature, not the vendor's (which is no longer present after mirroring).
- `--tlog-upload=false` and `--insecure-ignore-tlog=true` are lab-only flags; production workflows should use Rekor for non-repudiation.
- Empty passphrases are lab-only; production key strategies include OIDC keyless signing, KMS-backed keys (AWS KMS, Azure Key Vault, GCP KMS, HashiCorp Vault), or HSMs.

### Infrastructure Notes

- The `IMAGE_DIGEST` and `PYTHON_DIGEST` values are loaded from `~/image.digest` and `~/python.digest` respectively — files written by module-04.
- Cosign stores the signature as an OCI artifact; the student registry must support OCI artifact storage (OCI Distribution Spec v1.1+).
- `COSIGN_PASSWORD=""` must be set before `cosign generate-key-pair` to avoid an interactive passphrase prompt.
