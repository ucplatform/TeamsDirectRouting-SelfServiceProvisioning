﻿<#
.SYNOPSIS
    Phase 2: Domain Verification
 
.DESCRIPTION
    Verify all custom domains in the Customer Microsoft Tenant
    @@@@@ = Variables that include System Names, connection strings or Details that have been removed for saftey reasons 

.INPUTS
    Provisioning Portal Via Webhook

#>

#Verify in customers Microsoft Tenant, will retry while errors
$apiUrl = "https://graph.microsoft.com/v1.0/domains/$ver/verify"
          
## Remove TXT records following successful verification in HALO system
Remove-AzDnsRecordSet -Name $ver -RecordType TXT -ZoneName @@@@@ -ResourceGroupName "ver"
