# Module Outline: Image Signing and Verification

**Module ID:** module-05
**Duration:** 20 min
**File:** `content/modules/ROOT/pages/module-05-signing-verification.adoc`

---

### Brief Overview

This module completes the core signing workflow. Learners sign their pushed application image by digest using Cosign with the key pair from module-04, then verify the signature as a downstream consumer would. They then close the "proof-of-origin gap" established in module-04 by signing the mirrored `python:3.12` vendor image under their own key pair — establishing a single organizational trust boundary in their registry. Signature OCI artifact storage (`.sig` tag suffix) is examined using Skopeo to connect the theoretical model from module-03 to the learner's own artifacts.

### Audience and Time

- **Personas:** DevSecOps practitioners, security-conscious developers, platform engineers
- **Prerequisites for this module:** Module-04 complete (image pushed, digest captured, Cosign key pair generated, vendor image mirrored)
- **Duration:** 20 minutes

### Learning Objectives

- Sign a container image by digest using Cosign with a local key pair
- Verify an OCI image signature using Cosign from the consumer's perspective
- Sign a mirrored vendor image to establish organizational custody in a private registry
- Inspect OCI signature artifacts stored in a registry using Skopeo to confirm the `.sig` tag structure

### Lab Structure

| Section | Title | Duration |
|---------|-------|----------|
| 1 | Sign the Image | 6 min |
| 2 | Verify the Signature | 5 min |
| 3 | Take Custody of the Mirrored Image | 6 min |
| 4 | The Chain of Trust So Far | 3 min |

### Detailed Steps

1. Confirm the image digest variable is still set: `echo $IMAGE_DIGEST`. If not, reload it: `IMAGE_DIGEST=$(cat ~/image.digest)`.
2. Sign the application image by digest — note the `@${IMAGE_DIGEST}` syntax, not the tag:
   ```
   cosign sign --tlog-upload=false --key cosign.key \
     registry-${GUID}.${DOMAIN}/rhhi-demo@${IMAGE_DIGEST}
   ```
3. Observe the Cosign output confirming the signature was pushed to the registry.
4. Explain `--tlog-upload=false`: skips Rekor upload for lab cleanliness; in production, omit this flag.
5. Verify the signature as a consumer would:
   ```
   cosign verify --insecure-ignore-tlog=true --key cosign.pub \
     registry-${GUID}.${DOMAIN}/rhhi-demo@${IMAGE_DIGEST}
   ```
6. Observe successful verification output and inspect the JSON structure — same in-toto envelope format seen in module-03.
7. Use Skopeo to list all tags in the student registry for the `rhhi-demo` image: `skopeo list-tags docker://registry-${GUID}.${DOMAIN}/rhhi-demo`
8. Identify the `.sig` tag (format: `sha256-<digest-hex>.sig`). Explain that this is the OCI artifact storing the signature blob.
9. Inspect the signature artifact directly: `skopeo inspect docker://registry-${GUID}.${DOMAIN}/rhhi-demo:<sig-tag>`
10. Now close the mirror gap: get the digest of the mirrored python image: `skopeo inspect --format '{{.Digest}}' docker://registry-${GUID}.${DOMAIN}/python:3.12`
11. Export as a variable: `PYTHON_DIGEST=<paste digest>`
12. Sign the mirrored vendor image under the student's own key:
    ```
    cosign sign --tlog-upload=false --key cosign.key \
      registry-${GUID}.${DOMAIN}/python@${PYTHON_DIGEST}
    ```
13. Verify the new custody signature: `cosign verify --insecure-ignore-tlog=true --key cosign.pub registry-${GUID}.${DOMAIN}/python@${PYTHON_DIGEST}`
14. Read the "Chain of Trust So Far" summary sidebar: the registry now has two signed images — the student's app image and the vendor base image — both under the student's key. The next step (module-06) is to attach the SBOM as a verified provenance record.

### Key Takeaways

- Always sign by digest, not by tag; the digest is immutable whereas the tag can be moved to a different image.
- The `.sig` OCI artifact is stored in the same registry as the image — no external signature service needed.
- Signing the mirrored vendor image under your own key establishes organizational custody: downstream systems verify your signature, not the vendor's (which is no longer present after mirroring).
- `--tlog-upload=false` and `--insecure-ignore-tlog=true` are lab-only flags; production workflows should use Rekor for non-repudiation.
- Verification from the consumer's perspective is a single command with the public key; this is what a Kyverno or OPA Gatekeeper admission policy would execute automatically.

### Infrastructure Notes

- The `IMAGE_DIGEST` shell variable from module-04 must persist across module boundaries; the lab platform should ensure it is set in the student's shell profile or the validate script should re-derive it if missing.
- Cosign stores the signature as an OCI artifact; the student registry must support OCI artifact storage (OCI Distribution Spec v1.1+).
