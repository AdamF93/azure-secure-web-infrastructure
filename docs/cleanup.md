# Cleanup guide

## Pause between sessions

Deallocate the VM to stop compute charges:

```powershell
az vm deallocate --resource-group rg-secure-web-dev-gwc --name vm-web-secure-web-dev-gwc-01
```

Verify the power state:

```powershell
az vm get-instance-view --resource-group rg-secure-web-dev-gwc --name vm-web-secure-web-dev-gwc-01 --query "instanceView.statuses[].displayStatus" --output table
```

Expected: VM deallocated.

Disks and public IP addresses remain billable. Deallocation does not
delete the environment or stop every charge.

## Delete the project environment

This permanently removes the Resource Group and its resources, including
the VM, disk, public IP, networking and monitoring configuration.

Before deletion:

- Save the source code and documentation to GitHub.
- Capture required screenshots and verification evidence.
- Confirm the subscription and inspect the Resource Group contents.
- Confirm no unrelated resources have been added to the group.

```powershell
az account show --query "{Name:name, State:state}" --output table
az resource list --resource-group rg-secure-web-dev-gwc --query "[].{Name:name, Type:type}" --output table
```

Delete the group when ready:

```powershell
az group delete --name rg-secure-web-dev-gwc
```

Read and accept the CLI confirmation only when deletion is intended.

Verify after deletion completes:

```powershell
az group exists --name rg-secure-web-dev-gwc
```

Expected: false.

Deleting the group removes its resources, but is not evidence that the
entire subscription has no other billable resources.

## Earlier regional attempts

The project also created these Resource Groups during regional testing:

- rg-secure-web-dev-uks
- rg-secure-web-dev-weu

Inspect each before deciding whether to delete it:

```powershell
az resource list --resource-group rg-secure-web-dev-uks --output table
az resource list --resource-group rg-secure-web-dev-weu --output table
```

If they contain only disposable project resources, delete them separately
using az group delete and verify with az group exists.

## GitHub deployment identity

Deleting the workload Resource Group does not delete the Entra application
or its subscription-level role assignment.

For permanent project retirement:

1. Remove the GitHub identity's Azure role assignments.
2. Remove its federated credential and service principal/application.
3. Remove the custom role definition once no assignments use it.
4. Remove unused GitHub repository variables and secrets.

If the project will be rebuilt, retain or remove these deliberately.
The GitHub identity's Resource Group permissions will need to be restored
after recreating a deleted group.

## Trial expiry

Record the actual trial expiry date from Azure billing information.
Do not rely on an estimated date.

Complete cleanup and verify the remaining subscription resources before
the trial expires. No subscription upgrade is required for this project.