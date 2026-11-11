# Security decisions

## Network controls

The web VM is placed in snet-web (10.10.1.0/24).

The subnet is associated with an NSG containing custom inbound rules
allowing TCP 80 and 443 from the Internet service tag.

There is no custom rule allowing SSH from the internet. Azure's default
inbound rules deny unmatched internet traffic.

The management subnet (10.10.2.0/24) is currently empty. Separate subnets
do not automatically isolate workloads: default NSG rules allow virtual
network traffic. Additional rules would be needed for stricter isolation.

## Administrative access

The VM disables SSH password authentication and is provisioned with an
SSH public key. The private key remains outside the repository.

Administrative checks used Azure Run Command, which operates through the
VM agent without requiring an inbound SSH rule.

Run Command is privileged access. Azure permissions that allow its use
must be restricted to trusted administrators and deployment identities.

## VM security

The VM uses Ubuntu Server 24.04 LTS and Trusted Launch with Secure Boot
and a virtual TPM enabled.

Cloud-init installs NGINX and creates the demonstration page. Its custom
data contains no passwords, tokens or private keys.

Ongoing patch scheduling and vulnerability assessment have not yet been
implemented or verified.

## Web transport

Public HTTP access has been verified.

The NSG permits TCP 443, but HTTPS is not configured. Opening port 443
does not install a certificate or configure TLS in NGINX.

The site hosts demonstration content and must not collect credentials
or sensitive information over HTTP.

## Workload identity

The VM has a system-assigned managed identity used by Azure Monitor Agent.
Azure manages the identity credentials.

This VM identity is separate from the GitHub deployment service principal.

## GitHub authentication

GitHub Actions authenticates through OIDC and an Entra federated credential.
No Azure client secret is stored in GitHub.

The federated credential matches this repository's main-branch token
subject, including its numeric owner and repository IDs.

The trust is branch-based, not restricted to one workflow filename.
People able to change or run trusted main-branch workflows must therefore
be treated as having access to the deployment identity.

## Deployment authorization

The GitHub service principal has:

- Contributor on rg-secure-web-dev-gwc.
- A custom role at subscription scope permitting
  Microsoft.Resources/deployments/* and
  Microsoft.Resources/subscriptions/read.

Contributor permits creating, modifying and deleting project resources,
including privileged VM operations. It does not grant Azure role-assignment
management.

The custom role permits subscription deployment operations, including
managing subscription deployment records. Resource operations still
require their own authorization.

These permissions are scoped and documented, but are not a custom
minimum-action role for every workload operation.

## Repository configuration

Azure client, tenant and subscription IDs are repository variables.
They are identifiers, not authentication secrets.

The SSH public key is a repository variable. The private key is not uploaded.

The alert email is supplied through a GitHub secret and a secure Bicep
parameter. Authorized Azure users can still view the Action Group recipient.

.gitignore excludes selected generated templates and local files.
It does not remove files already tracked or guarantee secret detection.

## Deployment controls

The workflow is manually triggered and defaults to preview.

Deployment requires selecting the deploy operation. A what-if preview runs
first, but its output is not automatically approved or rejected.

Branch protection, independent deployment approval and automated security
scanning have not yet been configured.

## Monitoring

CPU telemetry and an actual alert email have been verified.

The CPU alert was restored to an 80% threshold and disabled after testing.
It therefore does not currently provide active alert coverage.