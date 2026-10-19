# aws-infrastructure-hardening
Automated secure AWS infrastructure deployment blueprint using Terraform and Checkov SAST pipeline orchestration.


# Enterprise Cloud Infrastructure Hardening Blueprint
[![IaC Security Compliance Audit](https://github.com)](https://github.com)

An enterprise-grade, compliance-hardened AWS Infrastructure as Code (IaC) baseline built from scratch using Terraform. This repository demonstrates a production-ready, security-first network architecture featuring automated DevSecOps static analysis guardrails.

## 🏗️ Architectural Posture & Controls

This architecture establishes a secure **Multi-Tier Corporate Topology** mapped strictly against commercial enterprise data protection baselines:

*   **Perimeter Segmentation & Network Isolation:** Segregates public-facing routing tiers from backend compute resources. Subnets housing application logic are configured as fully private tiers with disabled auto-assign public IP rules, eliminating direct public exposure.
*   **Default-Deny Security Boundary:** Intercepts and explicitly locks down the AWS default security group. Stripping all ingress/egress vectors ensures that unassigned resources fail-secure by dropping all implicit traffic.
*   **Cryptographic Data Protection (KMS CMK):** Integrates an AWS Customer Managed Key (CMK) enforcing AES-256 encryption-at-rest. The key features an explicit resource-based access policy granting least-privilege cryptographic access exclusively to active monitoring services.
*   **Long-Term Audit Logging Compliance:** Deploys VPC Flow Logs capturing all network traffic. Logs are funneled into a dedicated CloudWatch Log Group with a **365-day retention policy** to satisfy commercial compliance forensic windows.

## 🚀 Automated DevSecOps Pipeline

To maintain velocity while ensuring absolute compliance, this repository utilizes an automated **GitHub Actions CI/CD Pipeline**:

*   **Tooling:** Infrastructure static code analysis via **Checkov**.
*   **Execution Policy:** Triggers instantly on every code `push` or `pull_request` targeting the `main` branch.
*   **Gatekeeping:** Evaluates code against hundreds of cloud misconfiguration policies. The pipeline executes a strict blocking strategy (`soft_fail: false`), immediately halting integration if critical security or architecture drift is discovered.

## 📁 Repository Structure

```text
├── .github/
│   └── workflows/
│       └── iac-security-scan.yml    # GitHub Actions Checkov Automation Pipeline
├── environments/
│   └── dev/
│       ├── main.tf                  # Root Environment Deployment Blueprint
│       └── variables.tf             # Global Architecture Variables
└── modules/
    └── network/
        ├── main.tf                  # Hardened Core Network Logic & KMS Controls
        └── variables.tf             # Module Input Constraints
```

## 🛠️ Local Verification & Installation

To run static validation checks locally in an Ubuntu environment:

1. Install Checkov: `pip3 install checkov`
2. Run validation check: `checkov -d . --framework terraform`
