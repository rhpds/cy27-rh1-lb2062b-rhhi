# Module Outline: Working with SBOMs

**Module ID:** module-02
**Duration:** 15 min
**File:** `content/modules/ROOT/pages/module-02-sbom-generation.adoc`

---

### Brief Overview

This module introduces SBOMs (Software Bills of Materials) as machine-readable inventories of everything inside a container image. Learners use Syft to generate both a human-readable table output and a standards-compliant SPDX-JSON SBOM for the hardened image. They then use jq to query the JSON — examining package count and specific package metadata. The SPDX file produced here is a live artifact that is carried forward to module-06, where it is attached as a signed attestation to the image.

### Audience and Time

- **Personas:** DevSecOps practitioners, security-conscious developers, platform engineers
- **Prerequisites for this module:** Module-01 complete (Podman socket enabled, images loaded)
- **Duration:** 15 minutes

### Learning Objectives

- Generate a human-readable package inventory table for a container image using Syft
- Generate a machine-readable SPDX-JSON SBOM and write it to disk for downstream use
- Query SBOM structure using jq to extract package count and inspect specific package metadata
- Identify common machine-readable SBOM output formats and their tooling compatibility

### Lab Structure

| Section | Title | Duration |
|---------|-------|----------|
| 1 | Introduction | 2 min |
| 2 | Step 1: View a Human-Readable Package Table | 3 min |
| 3 | Step 2: Generate a Machine-Readable SPDX SBOM | 4 min |
| 4 | Step 3: Inspect the SBOM | 4 min |
| 5 | SBOM Formats | 1 min |
| 6 | Summary | 1 min |

### Detailed Steps

1. Read the introduction panel explaining what an SBOM is and why it matters for supply chain compliance (EO 14028, CISA guidance).
2. Generate and display a human-readable package table: `syft rhhi-demo:hardened -o table`
3. Observe column layout: Package, Version, Type, Location. Note how few packages appear — distroless design.
4. Generate an SPDX-JSON SBOM and write it to the home directory: `syft rhhi-demo:hardened -o spdx-json=~/rhhi-demo.spdx`
5. Confirm the file was created via Syft output (package and file counts displayed).
6. Count the packages recorded: `jq '.packages | length' ~/rhhi-demo.spdx`
7. Query a specific package by name to inspect its metadata: `jq '.packages[] | select(.name == "flask") | {name, versionInfo, sourceInfo}' ~/rhhi-demo.spdx`
8. Note how `sourceInfo` shows where Syft found the package — pip dist-info for Python packages, RPM database for system packages.
9. Read the SBOM Formats note listing supported Syft output formats: SPDX-JSON (ISO/IEC 5962:2021), CycloneDX JSON (OWASP), Table, and Syft native JSON.
10. Read the summary panel reminding learners that `~/rhhi-demo.spdx` is used again in module-06.

### Key Takeaways

- An SBOM gives you a complete, auditable inventory of a container image's contents without running it.
- SPDX-JSON is the format Red Hat uses for published attestations; CycloneDX is common in enterprise vulnerability management pipelines.
- Syft can output both formats from the same image scan — the format choice is driven by downstream tooling.
- The SBOM file written here (`~/rhhi-demo.spdx`) is a live artifact; keep it for module-06.

### Infrastructure Notes

- `rhhi-demo:hardened` is already in local Podman storage from module-01.
- Syft does not require the Podman socket for local image analysis but will use it if available.
- The SBOM file is written to the student home directory (`~/rhhi-demo.spdx`); setup automation should ensure sufficient disk space.
