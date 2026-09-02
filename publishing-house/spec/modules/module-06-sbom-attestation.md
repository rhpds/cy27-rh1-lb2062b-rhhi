# Module Outline: Image SBOM Attestation

**Module ID:** module-06
**Duration:** 15 min
**File:** `content/modules/ROOT/pages/module-06-sbom-attestation.adoc`

---

### Brief Overview

This module closes the loop between module-02 (SBOM generation) and the signed image from module-05. Learners use `cosign attest` to attach the `~/rhhi-demo.spdx` file generated in module-02 as a signed OCI attestation to their image — making the SBOM both verifiable and co-located with the image in the registry. They then verify the attestation with `cosign verify-attestation` and download the full attestation envelope for offline inspection. The module briefly introduces Kyverno and OPA Gatekeeper as admission-control integration points that can enforce SBOM attestation presence in production clusters.

### Audience and Time

- **Personas:** DevSecOps practitioners, security-conscious developers, platform engineers
- **Prerequisites for this module:** Module-02 complete (`~/rhhi-demo.spdx` exists); Module-05 complete (image signed, `IMAGE_DIGEST` set, `cosign.key`/`cosign.pub` present)
- **Duration:** 15 minutes

### Learning Objectives

- Attach a signed SBOM attestation to a container image using `cosign attest` with the `spdxjson` predicate type
- Verify the attestation signature and predicate type using `cosign verify-attestation`
- Download the attestation envelope and inspect its DSSE structure using jq
- Explain how admission controllers like Kyverno and OPA Gatekeeper can enforce SBOM attestation requirements

### Lab Structure

| Section | Title | Duration |
|---------|-------|----------|
| 1 | What Is an Attestation? | 2 min |
| 2 | Attach the SBOM as a Signed Attestation | 4 min |
| 3 | Verify the SBOM Attestation | 4 min |
| 4 | Download the Attestation | 3 min |
| 5 | Summary | 2 min |

### Detailed Steps

1. Read the "What Is an Attestation?" panel: distinguish between a signature (proves who signed an image) and an attestation (signs a claim about an image — e.g., "this SBOM describes this image"). Attestations use the DSSE (Dead Simple Signing Envelope) format with a structured predicate.
2. Confirm the SBOM file exists: `ls -lh ~/rhhi-demo.spdx`
3. Confirm `IMAGE_DIGEST` is set; if not, reload: `IMAGE_DIGEST=$(cat ~/image.digest)`
4. Attach the SBOM as a signed attestation:
   ```
   cosign attest --key cosign.key \
     --predicate ~/rhhi-demo.spdx \
     --type spdxjson \
     --tlog-upload=false \
     registry-${GUID}.${DOMAIN}/rhhi-demo@${IMAGE_DIGEST}
   ```
5. Observe Cosign output confirming the attestation artifact was pushed to the registry.
6. Explain the `--type spdxjson` flag: this sets the `predicateType` field in the DSSE envelope so downstream tools know how to parse the payload.
7. Verify the attestation:
   ```
   cosign verify-attestation \
     --key cosign.pub \
     --type spdxjson \
     --insecure-ignore-tlog=true \
     registry-${GUID}.${DOMAIN}/rhhi-demo@${IMAGE_DIGEST} | jq
   ```
8. Observe the DSSE envelope structure in the jq output: `payloadType`, `payload` (base64-encoded), `signatures`.
9. Decode the payload to inspect the predicate: `cosign verify-attestation --key cosign.pub --type spdxjson --insecure-ignore-tlog=true registry-${GUID}.${DOMAIN}/rhhi-demo@${IMAGE_DIGEST} | jq -r '.payload | @base64d | fromjson'`
10. Confirm the decoded payload matches the SPDX JSON from module-02.
11. Download the raw attestation envelope for offline use: `cosign download attestation registry-${GUID}.${DOMAIN}/rhhi-demo@${IMAGE_DIGEST} > ~/my-attestation.json`
12. Inspect the downloaded file: `jq keys ~/my-attestation.json`
13. Read the production integration sidebar: Kyverno policies can require that every image in a namespace has a valid SBOM attestation before admission; OPA Gatekeeper provides the same via rego policies. Both verify signatures and predicate types without additional tooling.
14. Read the summary panel: the per-student trust chain is now complete — scan (Grype), SBOM (Syft), signature (Cosign), attestation (Cosign attest). Module-07 shows how Red Hat applies the same model at scale.

### Key Takeaways

- An attestation = a signed claim about an image; the claim payload (the SBOM) is wrapped in a DSSE envelope with a `predicateType` URI that identifies the payload format.
- `cosign attest` pushes the attestation as an OCI artifact into the same registry as the image — no external attestation service needed.
- Verification (`cosign verify-attestation`) checks both the cryptographic signature and the predicate type in one command.
- The base64-encoded `payload` field in the DSSE envelope is the actual SBOM content; it can be decoded and inspected offline.
- Kyverno and OPA Gatekeeper can enforce SBOM attestation presence at admission time — this is the production enforcement path for the workflow demonstrated in this module.

### Infrastructure Notes

- `cosign attest` requires the registry to support OCI artifact storage (OCI Distribution Spec v1.1+).
- The `~/rhhi-demo.spdx` file must persist from module-02; setup automation should not clean up the home directory between modules.
- The attestation OCI artifact appears as a separate tag in the registry alongside the `.sig` tag from module-05.
