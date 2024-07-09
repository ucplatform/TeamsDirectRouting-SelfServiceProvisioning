<#
.SYNOPSIS
    Phase 2: Domain Verification
 
.DESCRIPTION
    Verify all custom domains in the Customer Microsoft Tenant
    @@@@@ = Variables that include System Names, connection strings or Details that have been removed for saftey reasons 

.INPUTS
    Provisioning Portal Via Webhook

#>


#Verify in customers Microsoft Tenant, will retry while errors
$apiUrl = "https://graph.microsoft.com/v1.0/domains/$i/verify"
          
## Remove TXT records following successful verification
## Connect to HALO Tenant and Update DNS
Remove-AzDnsRecordSet -Name $ShortDomain -RecordType TXT -ZoneName @@@@@ -ResourceGroupName "uksouth_dns"


