# Security Policy

This is a small, best-effort personal image-build repo, not an actively
monitored service — see the disclaimer in [README.md](README.md).

## Scanning already in place

- Every build runs a full [Trivy](https://github.com/aquasecurity/trivy-action)
  scan of the built image; results are in this repo's
  [Security → Code scanning](../../security/code-scanning) tab.
- Most alerts come from the upstream vendor base image's own OS packages
  (Debian, OpenThread build tooling) and are outside this repo's control —
  including known-benign matches like the OpenThread `tcat_ble_client` test
  certificates, which are upstream example fixtures, not real secrets.
- [Dependabot](.github/dependabot.yml) tracks the base image digest, the
  pinned pip package, and the GitHub Actions used in CI.

## Reporting a vulnerability

If you find something not already visible in code scanning, use GitHub's
[private vulnerability reporting](../../security/advisories/new) rather than
a public issue. No fix SLA is promised.
