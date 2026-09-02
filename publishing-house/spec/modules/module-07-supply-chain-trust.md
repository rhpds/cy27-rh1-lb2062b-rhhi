# Module Outline: Establishing Supply Chain Trust

**Module ID:** module-07
**Duration:** 15 min
**File:** `content/modules/ROOT/pages/module-07-supply-chain-trust.adoc`

---

### Brief Overview

The final module zooms out from the student's own artifacts to Red Hat's supply chain. Learners download the published attestation bundle for `registry.access.redhat.com/hi/python:3.12` and discover it contains multiple attestation types — both an SPDX SBOM and a SLSA v0.2 build provenance record. They isolate the SLSA envelope, decode its payload, and inspect the builder identity (Tekton Chains), build type, hermetic flag, and pinned input materials. This ties together the full lab narrative: every transparency tool the student applied is mirrored — and in many cases exceeded — in Red Hat's own supply chain artifacts.

### Audience and Time

- **Personas:** DevSecOps practitioners, security-conscious developers, platform engineers
- **Prerequisites for this module:** All prior modules conceptually; no persistent artifacts required from earlier modules (this module reads Red Hat's public registry)
- **Duration:** 15 minutes

### Learning Objectives

- Download vendor-published OCI attestation bundles using `cosign download attestation`
- Analyze SLSA v0.2 build provenance to extract builder identity, build type, hermetic flag, and pinned input materials
- Distinguish between SPDX SBOM attestations and SLSA provenance attestations within a single OCI attestation bundle
- Explain how the tools and workflows learned in this lab mirror Red Hat's own supply chain transparency practices

### Lab Structure

| Section | Title | Duration |
|---------|-------|----------|
| 1 | Introduction | 2 min |
| 2 | Download the Vendor's Attestations | 3 min |
| 3 | Isolate the SLSA Provenance | 3 min |
| 4 | Inspect the Build Provenance | 5 min |
| 5 | Provenance and the Mirror Gap | 1 min |
| 6 | Summary | 1 min |

### Detailed Steps

1. Read the introduction panel: explain that Red Hat publishes attestations for its container images in the same OCI registry where the images live. These attestations follow the same DSSE format that learners produced in module-06.
2. Download the full attestation bundle for the Red Hat Python hardened image:
   ```
   cosign download attestation \
     --output-file redhat.sbom \
     registry.access.redhat.com/hi/python:3.12
   ```
   Note: the `--output-file` flag writes one JSON object per line (NDJSON format).
3. Count how many attestation records are in the bundle: `wc -l redhat.sbom`
4. List all predicate types present in the bundle:
   ```
   jq -r '.payload | @base64d | fromjson | .predicateType' redhat.sbom
   ```
5. Observe that the bundle contains both an SPDX SBOM predicate and a SLSA provenance predicate.
6. Isolate the SLSA provenance envelope:
   ```
   jq -r 'select((.payload | @base64d | fromjson | .predicateType) | test("slsa")) | .payload | @base64d | fromjson' redhat.sbom > ~/python-slsa.json
   ```
7. Inspect the SLSA predicate type URI to confirm it is SLSA v0.2: `jq '.predicateType' ~/python-slsa.json`
8. Inspect the builder identity: `jq -r '.predicate.builder.id' ~/python-slsa.json`
   - Expected value: a Tekton Chains builder URI identifying the Red Hat build infrastructure.
9. Inspect the build type: `jq -r '.predicate.buildType' ~/python-slsa.json`
10. Check the hermetic flag: `jq '.predicate.buildConfig.hermetic' ~/python-slsa.json`
11. Inspect the pinned input materials (source repo + commit SHA):
    ```
    jq '.predicate.materials' ~/python-slsa.json
    ```
12. Read the "Provenance and the Mirror Gap" sidebar: when the student mirrored `hi/python:3.12` in module-04, the SLSA provenance attestation was also stripped (it referenced the source registry). The student's signature from module-05 provides custody proof, but not build provenance — that is a gap in the current mirroring workflow and a realistic challenge in air-gapped environments.
13. Read the summary panel tying together all seven modules: scan → SBOM → verify vendor signatures → push + key setup → sign → attest → inspect vendor provenance. The student has completed the full supply chain trust loop.

### Key Takeaways

- Red Hat publishes both SBOM and SLSA build provenance attestations for its container images in the same OCI registry — the same format and tooling the student used in this lab.
- A single OCI attestation bundle can contain multiple attestations of different predicate types; `jq` is used to filter by predicate type.
- SLSA v0.2 provenance records identify the builder (Tekton Chains), build type, hermetic isolation flag, and the exact source commit and input materials used to build the image.
- Mirroring strips vendor attestations along with vendor signatures — a known challenge in air-gapped environments that requires re-signing and re-attestation workflows.
- The full supply chain trust model — scan, SBOM, signature, attestation, provenance — is achievable with open-source tools on a single RHEL VM.

### Infrastructure Notes

- This module is read-only: it downloads and inspects Red Hat's public attestations. There is no solve button and no persistent artifact to validate.
- Requires outbound access to `registry.access.redhat.com` from the student VM.
- The attestation bundle format (NDJSON, one JSON object per line) is a Cosign artifact storage detail; the writer should note this explicitly to avoid learner confusion when inspecting the file with a standard JSON viewer.
- SLSA v0.2 predicate type URI: `https://slsa.dev/provenance/v0.2`. The writer should include this for reference alongside the jq output.
