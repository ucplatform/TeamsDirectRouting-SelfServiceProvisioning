<#
.SYNOPSIS
    Phase 1: Custom Domains and TXT Record Creation
   
.DESCRIPTION
    Base configuration includes, Adding Custom Domains details to customers tenant and adding associated TXT Records to HALOs DNS Service ready for domain verification
    @@@@@ = Variables that include System Names, connection strings or Details that have been removed for saftey reasons 
    
.INPUTS
    Provisioning Portal Via Webhook
#>


param
(
    [Parameter(Mandatory=$false)]
    [object] $WebhookData
)

#Covert JSON Body to Input Object
$input = ConvertFrom-Json -InputObject $WebhookData.RequestBody

#Update status of implementation function
function JobStatusUpdate {
    param
    (
        [string]$job_id,
        [string]$result,
        [string]$des,
        [string]$orderid,
        [string]$ProvStepID

    )

    $insertquery=" 
    INSERT INTO tb_JobLog VALUES ('$job_id','$result','$des','$orderid','$ProvStepID')
    GO
    " 

    Invoke-Sqlcmd -Query $insertquery -ConnectionString "Data Source=@@@@@;Initial Catalog=@@@@@;Persist Security Info=False;User ID=$DBusername;Password=$DBpassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30"

}


#Password for status update 
#DB Access Credentials 
$CredsDB = Get-AutomationPSCredential -Name '@@@@@'
$DBUsername = $CredsDB.Username
$DBPassword = $CredsDB.Password
$DBpassword = $CredsDB.GetNetworkCredential().Password

#Global Varibles
$export = ""
$Domains = @();
$Domains.Clear();
$Success = "0"

#Access token to Customer Tenant
$token = $input.GraphToken

#Get customer tenant info for Status Updates
$apiUrl = 'https://graph.microsoft.com/v1.0/organization'
$Data = Invoke-RestMethod -Headers @{Authorization = "Bearer $($input.GraphToken)"} -Uri $apiUrl -Method Get
$tenantid = $Data.Value.id
$apiUrl = 'https://graph.microsoft.com/v1.0/domains'
$Data = Invoke-RestMethod -Headers @{Authorization = "Bearer $($input.GraphToken)"} -Uri $apiUrl -Method Get
$domain = $data.Value.Id -like "*onmicrosoft.com"
$ex = "tenantid=" + $tenantid + ",domain=" + $domain

#Create array of Custom Domains for Customer MS Tenant
$Domains += $input.MSTeamsID + "." + "AMER" + "1drms.@@@@@"
$Domains += $input.MSTeamsID + "." + "AMER" + "2drms.@@@@@"
$Domains += $input.MSTeamsID + "." + "EMEA" + "1drms.@@@@@"
$Domains += $input.MSTeamsID + "." + "EMEA" + "2drms.@@@@@"
$Domains += $input.MSTeamsID + "." + "APAC" + "1drms.@@@@@"
$Domains += $input.MSTeamsID + "." + "APAC" + "2drms.@@@@@"


#Add all custom domains to customers MS Tenant
foreach ($i in $Domains){
$Error.Clear()

    try {
        $apiUrl = "https://graph.microsoft.com/v1.0/domains/$i"
        Invoke-RestMethod -Headers @{Authorization = "Bearer $($token)"} -Uri $apiUrl -Method Get
    }
    catch {
    $Error.Clear()
    $body= @"
    {
    "id": "$i"
    }
    "@

        try {
            $apiUrl = 'https://graph.microsoft.com/v1.0/domains'
            Invoke-RestMethod -Headers @{Authorization = "Bearer $($token)"} -Uri $apiUrl -Body $body -Method Post -Contenttype "application/json"
        } catch {
            JobStatusUpdate -job_id $PSPrivateMetadata.JobId.Guid -result "Failed" -des "#SDA-Failed to add domin $i" -orderid $input.OrderID -ProvStepID "3"
            $Success = "1"
        }

     }

    #Get MX Record for Domain
    $apiUrl = "https://graph.microsoft.com/v1.0/domains/$i/verificationDnsRecords"
    $Data = Invoke-RestMethod -Headers @{Authorization = "Bearer $($token)"} -Uri $apiUrl -Method Get
    $mxrecord = $Data.Value.text

    #Create TXT record in DNS
    #Credentials for DNS Update
    $Credential = Get-AutomationPSCredential -Name '@@@@@'
    
    #Varible for TenantID
    $CredsSCTenant = Get-AutomationPSCredential -Name '@@@@@'
    $TenantId = $CredsSCTenant.Username

    #Connect to HALO DNS Service
    Connect-AzAccount -Credential $Credential -Tenant $TenantId

    #Add TXT records to the DNS Service
    Set-AzContext -SubscriptionId "@@@@@"
    $ShortDomain = $i.SubString(0,24)
    $record = Get-AzDnsRecordSet -ResourceGroupName "uksouth_dns" -ZoneName @@@@@ -Name $ShortDomain -RecordType TXT
    #If record exists do nothing, else add record
    if ($record){
    }
    else {
        $Error.Clear()    
        New-AzDnsRecordSet -Name $ShortDomain -RecordType TXT -ZoneName @@@@@ -ResourceGroupName "uksouth_dns" -Ttl 3600 -DnsRecords (New-AzDnsRecordConfig -Value "$mxrecord")
    }
    Disconnect-AZAccount
}

#Update Implementation Status
if ($Success = "1"){
    JobStatusUpdate -job_id $PSPrivateMetadata.JobId.Guid -result "Failed" -des $ex -orderid $input.OrderID -ProvStepID "3"
}
else {
    JobStatusUpdate -job_id $PSPrivateMetadata.JobId.Guid -result "Success" -des $ex -orderid $input.OrderID -ProvStepID "3"
}
