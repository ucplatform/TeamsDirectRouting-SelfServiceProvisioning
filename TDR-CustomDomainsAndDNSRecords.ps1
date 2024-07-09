<#
.SYNOPSIS
    Phase 1: Custom Domains and TXT Record Creation
   
.DESCRIPTION
    Base configuration includes, Adding Custom Domains details to customers tenant and adding associated TXT Records to HALOs DNS Service ready for domain verification
    @@@@@ = Variables that include System Names, connection strings or Details that have been removed for saftey reasons 
    
.INPUTS
    Provisioning Portal Via Webhook
#>



#Add Domains MS Graph URL 
$Url = 'https://graph.microsoft.com/v1.0/domains'

#Get Domain verification record
$Url = "https://graph.microsoft.com/v1.0/domains/$i/verificationDnsRecords"

#Add TXT record to external none customer domain
New-AzDnsRecordSet -Name $ShortDomain -RecordType TXT -ZoneName @@@@@ -ResourceGroupName "uksouth_dns" -Ttl 3600 -DnsRecords (New-AzDnsRecordConfig -Value "$mxrecord")
