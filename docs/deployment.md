# Deployment guide

## Deployment status

The infrastructure has been deployed manually through Azure CLI and
redeployed successfully through GitHub Actions using OIDC.

A complete deployment into an empty environment has not yet been verified.

## Prerequisites

- An active Azure subscription with sufficient credit or an approved budget.
- Azure CLI and Bicep.
- Git and GitHub CLI.
- An SSH key pair. Only the public key is supplied to Azure.
- Permission to deploy resources at the required scopes.

The GitHub identity and role definitions in this repository describe this
project's setup. Other users must replace subscription, repository and
identity references with their own values.

## Configuration

`infra/dev.bicepparam` contains the development settings:

- Region: Germany West Central.
- Naming suffix: gwc.
- VM size: Standard_D2ls_v7.
- Administrator username: azureadmin.
- CPU alert: disabled by default, threshold 80%.

VM availability, subscription eligibility, quota and current pricing must
be checked before choosing a region and size.

## Local Azure CLI deployment

Run commands from the repository root in PowerShell.

Sign in and verify the selected subscription:

```powershell
az login
az account show --query "{Name:name, State:state}" --output table
```

Set the required process environment variables:

```powershell
$env:AZURE_SSH_PUBLIC_KEY = (Get-Content "$env:USERPROFILE\.ssh\azure-secure-web.pub" -Raw).Trim()
$env:AZURE_ALERT_EMAIL = Read-Host "Enter notification email"
```

Adapt the public-key path if your key has a different filename.

Compile:

```powershell
az bicep build --file infra/main.bicep
```

Preview:

```powershell
az deployment sub what-if --name preview-secure-web-dev --location germanywestcentral --parameters infra/dev.bicepparam
```

Review the proposed changes before deploying. For a redeployment of the
existing VM, ensure it is running so its extensions can complete.

Deploy:

```powershell
az deployment sub create --name deploy-secure-web-dev --location germanywestcentral --parameters infra/dev.bicepparam
```

The deployment creates billable resources. Deallocation stops VM compute
charges, but retained disks and public IPs remain billable.

## GitHub Actions

The manually triggered workflow supports `preview` and `deploy`.

Required repository variables:

- AZURE_CLIENT_ID
- AZURE_TENANT_ID
- AZURE_SUBSCRIPTION_ID
- AZURE_SSH_PUBLIC_KEY

Required repository secret:

- AZURE_ALERT_EMAIL

The workflow authenticates through an Entra federated credential.
It does not use an Azure client secret or upload the SSH private key.

The federated subject must exactly match the GitHub token's subject.
This project's subject includes numeric owner and repository IDs.

Azure permissions consist of:

- Contributor on the project Resource Group.
- A custom subscription role permitting deployment operations and
  subscription metadata reads.

The existing Resource Group and identity permissions are bootstrap
prerequisites for the GitHub identity. Its Resource Group assignment
does not permit creating arbitrary new Resource Groups.

Preview:

```powershell
gh workflow run azure-auth-test.yml --ref main -f operation=preview
```

Deploy:

```powershell
gh workflow run azure-auth-test.yml --ref main -f operation=deploy
```

Both operations compile and preview. Only deploy applies changes.
The preview does not automatically judge whether changes are desirable.

Inspect runs:

```powershell
gh run list --workflow azure-auth-test.yml --limit 5
```

## Verification

Retrieve the public IP and test HTTP while the VM is running:

```powershell
$webIp = az network public-ip show --resource-group rg-secure-web-dev-gwc --name pip-web-secure-web-dev-gwc-01 --query ipAddress --output tsv
Invoke-WebRequest -Uri "http://$webIp" -UseBasicParsing | Select-Object StatusCode
```

Expected HTTP status: 200. HTTPS is not configured yet.

Check the monitoring extension:

```powershell
az vm extension show --resource-group rg-secure-web-dev-gwc --vm-name vm-web-secure-web-dev-gwc-01 --name AzureMonitorLinuxAgent --query provisioningState --output tsv
```

Expected extension state: Succeeded.

Extension provisioning alone does not prove telemetry is arriving.
Heartbeat and Perf records must also be verified in Log Analytics.
The Linux aggregate CPU instance observed in this project is `total`.

## Cloud-init limitations

Cloud-init configures Ubuntu on its first boot. Existing standalone VMs
do not permit changing their customData.

The template normalizes cloud-init line endings to CRLF to match this
VM's original provisioning data across Windows and Linux builds.

Editing cloud-init is not a supported way to update the existing website.

## Pause the lab

Deallocate the VM:

```powershell
az vm deallocate --resource-group rg-secure-web-dev-gwc --name vm-web-secure-web-dev-gwc-01
```

Verify:

```powershell
az vm get-instance-view --resource-group rg-secure-web-dev-gwc --name vm-web-secure-web-dev-gwc-01 --query "instanceView.statuses[].displayStatus" --output table
```

Expected power state: VM deallocated.

The website is offline while deallocated. Disk and public IP charges
continue until those resources are deleted.