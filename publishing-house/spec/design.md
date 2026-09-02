# Container Image Scanning, SBOMs, and Signing

## Overview

This lab teaches DevSecOps practitioners how to implement a complete container image supply chain using open-source tooling on Red Hat Enterprise Linux. Participants work with a pre-built Flask application based on Red Hat Hardened Images (hi/python:3.12) and an equivalent UBI10 image, progressing through seven hands-on modules that cover vulnerability scanning, SBOM generation, image signing, and supply chain provenance inspection. By the end, participants have scanned images with Grype, generated and attached SPDX SBOMs with Syft, signed and verified images with Cosign, and inspected Red Hat's own SLSA build provenance — establishing a full trust chain from scan to attestation.

## Target Audience

- **Role:** DevSecOps practitioners, security-conscious developers, platform engineers
- **Experience level:** Intermediate
- **What they already know:** Basic Linux CLI, container concepts (image, registry, tag, digest), basic public/private key cryptography
- **What they don't know:** Vulnerability scanning workflows, SBOM generation and formats (SPDX, CycloneDX), image signing with Cosign/Sigstore, SLSA provenance, OCI attestation artifacts

## Prerequisites

- Basic Linux command-line proficiency (navigating the shell, running commands, reading output)
- Familiarity with container concepts: image, registry, tag, and digest
- Basic understanding of public/private key cryptography (key pairs, signing, verification)
- No OpenShift or Kubernetes knowledge required
- Prerequisites cannot be validated automatically; they are assumed from the audience profile

## Learning Objectives

1. Scan container images using Grype to identify CVE exposure and compare vulnerability counts between a Red Hat Hardened Image and a UBI10-based image
2. Generate machine-readable SPDX-JSON SBOMs for container images using Syft and inspect package metadata, supplier data, and PURL references
3. Verify published cryptographic image signatures using Cosign against Red Hat's official public keys and inspect the in-toto envelope structure
4. Configure a per-student TLS-enabled OCI registry, push container images by immutable digest, and mirror a vendor image using Skopeo
5. Sign container images by digest using Cosign and verify OCI signature artifacts as a downstream consumer would
6. Attest a signed SBOM to a container image using cosign attest and verify the attestation envelope for offline inspection
7. Analyze vendor-published SLSA build provenance records to trace build identity, hermetic flag, and pinned input materials
8. Build a complete image supply chain trust model spanning scanning, SBOM generation, signing, and provenance attestation

## Content Type

Lab (hands-on)

## Products & Technologies

- Red Hat Enterprise Linux (RHEL 9/10)
- Red Hat Hardened Images (hi/python:3.12)
- Red Hat Universal Base Image 10 (UBI10)
- Podman (rootless, systemd user socket)
- Grype (Anchore OSS — vulnerability scanner)
- Syft (Anchore OSS — SBOM generator)
- Cosign / Sigstore (signing, verification, attestation)
- Skopeo (OCI image copy and inspect)
- SPDX (ISO/IEC 5962:2021 — SBOM standard)
- CycloneDX (OWASP — SBOM standard, reference)
- SLSA v0.2 (Supply-chain Levels for Software Artifacts)
- Tekton Chains (Red Hat build provenance backend)
- jq (JSON query tool)

## Module Map

| Module | Title | Duration |
|--------|-------|----------|
| 1 | Vulnerability Scanning Container Images | 20 min |
| 2 | Working with SBOMs | 15 min |
| 3 | Verifying Published Signatures | 15 min |
| 4 | Image Signing Setup (Push and Generate Keys) | 20 min |
| 5 | Image Signing and Verification | 20 min |
| 6 | Image SBOM Attestation | 15 min |
| 7 | Establishing Supply Chain Trust | 15 min |
| — | **Total hands-on** | **120 min** |
| — | Intro / orientation | ~0 min (ZT — no presenter) |
| — | **Total lab** | **~2 hours** |

## Difficulty Level

Intermediate

## Environment

**Learner view:** A single RHEL VM is pre-provisioned per student. The VM has rootless Podman configured with a systemd user socket. Two pre-built container images are loaded into the local container storage before the lab starts: `rhhi-demo:hardened` (based on hi/python:3.12, running a Flask app) and `rhhi-demo:ubi` (equivalent app on UBI10). A per-student local OCI registry with TLS is reachable at `registry-{guid}.{domain}`. Grype, Syft, Cosign, Skopeo, and jq are pre-installed. External access to `registry.access.redhat.com` and `security.access.redhat.com` is required for signature verification steps.

**Automation needed:** Yes — setup automation must pre-load container images, configure the rootless Podman socket, and provision the per-student TLS registry before the lab begins.

## Infrastructure Requirements

- **Cloud provider:** CNV
- **Platform:** RHEL VMs (no OpenShift cluster required)
- **Topology:** Per-student
- **Sizing:** 1 RHEL 10 VM per student — 1 vCPU, 4GB RAM, 40GB disk
- **Automation approach:** Ansible (pre-installs tooling, pre-loads container images, provisions per-student TLS registry)
- **AI/MaaS:** None
- **External services:** `registry.access.redhat.com`, `security.access.redhat.com` (egress TCP 80 + 443 required)
- **AAP version:** N/A
- **Non-GA products:** None — all tools are upstream OSS; Red Hat Hardened Images and UBI10 are GA

## Assessment Strategy (Optional)

This is a Zero-Touch lab. Each module has a solve/validate button pair:

- **Solve:** Runs the authoritative command sequence for the module so a stuck learner can unblock and continue.
- **Validate:** Runs a verification script that checks for expected artifacts (e.g., presence of `~/rhhi-demo.spdx`, a valid cosign signature tag on the registry image, a matching attestation envelope) and returns pass/fail with a brief explanation.

Module-07 has no solve button — the final provenance inspection is read-only and has no persistent artifact to validate.
