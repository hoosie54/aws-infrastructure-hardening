# Enterprise Cloud Infrastructure Hardening Blueprint
[![IaC Security Compliance Audit](https://github.com)](https://github.com)

An enterprise-grade, compliance-hardened AWS Multi-Tier Infrastructure as Code (IaC) architecture built from scratch using Terraform. This repository demonstrates a production-ready, zero-trust network and compute baseline protected by automated DevSecOps static analysis gates.

## 🏗️ Architectural Posture & Controls

This architecture implements rigorous defense-in-depth security parameters to protect enterprise assets against modern cloud attack vectors:

### 🌐 1. Network Perimeter & Isolation Layer
*   **Perimeter Segmentation:** Isolates internet-facing entry points from backend application components using distinct public and private subnet tiers across multiple Availability Zones.
*   **Default-Deny Security Boundary:** Intercepts and completely strips all ingress and egress rules from the AWS Default Security Group, ensuring unassigned resources fail-secure by dropping all implicit traffic.
*   **Audit Forensics Logging:** Deploys VPC Flow Logs capturing all network interface traffic. Metadata is funneled into a dedicated CloudWatch Log Group configured with a **365-day retention policy** to satisfy compliance forensic investigation windows.

### 🔐 2. Cryptographic Data Protection & Identity
*   **KMS Customer Managed Key (CMK):** Implements an isolated KMS key enforcing robust AES-256 encryption-at-rest for network monitoring logs, featuring mandatory key rotation.
*   **Least-Privilege Key Policy:** Attaches an explicit, resource-based access policy restricting cryptographic operations exclusively to the CloudWatch logging service and root administrators.
*   **Zero-Trust Machine Identity:** Provisions an **IAM Instance Profile** and execution role for backend resources. This eliminates the risk of static, hardcoded access credentials by forcing servers to assume temporary, short-lived API permissions.

### 💻 3. Hardened Compute & Exploit Mitigation
*   **Advanced Web Exploit Defenses (IMDSv2):** Enforces strict session-token requirements on the host Instance Metadata Service. Restricting the response hop limit to `1` completely neutralizes Server-Side Request Forgery (SSRF) data-skimming and container-breakout vectors.
*   **Cryptographic Block Storage:** Guarantees full volume encryption on all attached root block storage devices using platform-managed AES-256 standard protocols.
*   **Operational Visibility & Optimization:** Enables high-resolution **1-minute detailed cloud monitoring** to compress security incident response visibility gaps, while enforcing **EBS Optimization** to isolate storage network paths from standard machine application traffic.

## 🚀 Automated DevSecOps Pipeline

To maintain velocity while ensuring absolute configuration compliance, this repository utilizes an automated **GitHub Actions CI/CD Pipeline**:

*   **Static Analysis Engine:** Configured with **Checkov** to audit declarative files against industry security benchmarks.
*   **Execution Policy:** Triggers dynamically on every code `push` or `pull_request` targeting the `main` branch.
*   **Gatekeeping Strategy:** Executes a strict blocking strategy (`soft_fail: false`), immediately halting code integration if infrastructure misconfigurations or compliance drift are introduced.

## 📁 Repository Structure

```text
├── .github/
│   └── workflows/
│       └── iac-security-scan.yml    # GitHub Actions Checkov Automation Pipeline
├── environments/
│   └── dev/
│       ├── main.tf                  # Root Environment Orchestration Layout
│       └── variables.tf             # Global Environment Target Variables
└── modules/
    ├── compute/
    │   ├── main.tf                  # Hardened EC2, Security Groups, & IAM Profiles
    │   └── variables.tf             # Compute Input Mapping Parameters
    └── network/
        ├── main.tf                  # Core Network Logic, KMS Keys, & Flow Logs
        ├── outputs.tf               # Exposed Network Architectural Resource IDs
        └── variables.tf             # Network Module Constraints
```
