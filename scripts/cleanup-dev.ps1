param(
    [switch]$Delete
)

$ErrorActionPreference = 'Stop'

$subscriptionId = '637c8b51-7107-451b-9a7b-3e12cc03a9a4'
$resourceGroup = 'rg-secure-web-dev-gwc'
$resourceRoot = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers"

function Invoke-AzChecked {
    & az @args
    if ($LASTEXITCODE -ne 0) {
        throw "Azure CLI failed. Cleanup stopped."
    }
}

function Get-ProjectResources {
    $json = Invoke-AzChecked resource list `
        --subscription $subscriptionId `
        --resource-group $resourceGroup `
        --output json

    $parsed = ($json -join "`n") | ConvertFrom-Json

    foreach ($resource in $parsed) {
        if ([string]::IsNullOrWhiteSpace([string]$resource.id)) {
            throw "Resource entry has no ID. Cleanup stopped."
        }

        Write-Output $resource
    }
}

# Delete dependent resources before their dependencies.
$resourcePaths = @(
    'Microsoft.Compute/virtualMachines/vm-web-secure-web-dev-gwc-01'
    'Microsoft.Network/networkInterfaces/nic-web-secure-web-dev-gwc-01'
    'Microsoft.Compute/disks/osdisk-vm-web-secure-web-dev-gwc-01'
    'Microsoft.Insights/metricAlerts/alert-cpu-secure-web-dev-gwc'
    'Microsoft.Insights/actionGroups/ag-secure-web-dev-gwc'
    'Microsoft.Insights/dataCollectionRules/dcr-web-secure-web-dev-gwc'
    'Microsoft.OperationalInsights/workspaces/law-secure-web-dev-gwc'
    'Microsoft.Network/publicIPAddresses/pip-web-secure-web-dev-gwc-01'
    'Microsoft.Network/virtualNetworks/vnet-secure-web-dev-gwc'
    'Microsoft.Network/networkSecurityGroups/nsg-web-secure-web-dev-gwc'
)

$deleteIds = @($resourcePaths | ForEach-Object {
    "$resourceRoot/$_"
})

# These child resources disappear with the VM.
$vmId = $deleteIds[0]
$allowedIds = $deleteIds + @(
    "$vmId/extensions/AzureMonitorLinuxAgent"
    "$vmId/providers/Microsoft.Insights/dataCollectionRuleAssociations/dcra-web-cpu"
)

$resources = @(Get-ProjectResources)

$unexpected = @($resources | Where-Object {
    $allowedIds -notcontains $_.id
})

if ($unexpected.Count -gt 0) {
    $unexpected | Format-Table name, type
    Write-Host "Unexpected resource IDs:"
    $unexpected | Select-Object name, id | ConvertTo-Json -Depth 5

    Write-Host "Expected resource IDs:"
    $allowedIds | ConvertTo-Json
    throw "Unexpected resources found. Nothing deleted."
}

Write-Host "Subscription: $subscriptionId"
Write-Host "Resource Group to KEEP: $resourceGroup"
Write-Host "Resources selected for deletion:"
$resources | Format-Table name, type

if (-not $Delete) {
    Write-Host "PREVIEW ONLY. Nothing deleted."
    return
}

$confirmation = Read-Host "Type $resourceGroup to permanently delete the listed resources"

if ($confirmation -cne $resourceGroup) {
    throw "Confirmation did not match. Nothing deleted."
}

foreach ($resourceId in $deleteIds) {
    $current = @(Get-ProjectResources)

    if ($current.id -contains $resourceId) {
        Write-Host "Deleting $resourceId"

        Invoke-AzChecked resource delete `
            --subscription $subscriptionId `
            --ids $resourceId `
            --output none

        Invoke-AzChecked resource wait `
            --subscription $subscriptionId `
            --ids $resourceId `
            --deleted `
            --interval 10 `
            --timeout 600
    }
    else {
        Write-Host "Already absent: $resourceId"
    }
}

$remaining = @(Get-ProjectResources)

if ($remaining.Count -gt 0) {
    $remaining | Format-Table name, type
    throw "Resources remain. Inspect before rebuilding."
}

Write-Host "Cleanup complete. The Resource Group is empty and retained."