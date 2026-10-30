                         Internet
                            │
                            ▼
                     Public IP / HTTPS
                            │
                            ▼
                    ┌──────────────┐
                    │   Linux VM   │
                    │ NGINX Web    │
                    └──────┬───────┘
                           │
                         NSG
                           │
                 ┌─────────┴─────────┐
                 │                   │
            Web Subnet          Mgmt Subnet
          10.10.1.0/24        10.10.2.0/24
                 │                   │
                 └─────────┬─────────┘
                           │
                     Azure VNet
                     10.10.0.0/16

                  Azure Monitor / Logs
                           │
                           ▼
                    Log Analytics

                Microsoft Entra ID
                           │
                           ▼
                         RBAC
