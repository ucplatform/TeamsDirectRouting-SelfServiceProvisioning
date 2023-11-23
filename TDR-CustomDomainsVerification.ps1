<#
.SYNOPSIS
    Phase 2: Domain Verification
 
.DESCRIPTION
    Verify all custom domains in the Customer Microsoft Tenant
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

#Function to update status of Implementation
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

    Invoke-Sqlcmd -Query $insertquery -ConnectionString "Data Source=@@@@@;Initial Catalog=@@@@@;Persist Security Info=False;User ID=$dbusername;Password=$dbpassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30"

}


#Passwords
#Credentials for DB Access
$CredsDBL = Get-AutomationPSCredential -Name '@@@@@'
$dbusername = $CredsDB.Username
$dbpassword = $CredsDB.Password
$dbpassword = $CredsDB.GetNetworkCredential().Password

#Global Varibles
$export = ""
$Domains = @();
$Domains.Clear();
$Success = "0"

#Customer Microsoft Tenant Access Token
$token = $input.GraphToken

#Array of Custom Domais to be Verified
$Domains += $input.MSTeamsID + "." + "AMER" + "1drms.@@@@@"
$Domains += $input.MSTeamsID + "." + "AMER" + "2drms.@@@@@"
$Domains += $input.MSTeamsID + "." + "APAC" + "1drms.@@@@@"
$Domains += $input.MSTeamsID + "." + "APAC" + "2drms.@@@@@"
$Domains += $input.MSTeamsID + "." + "EMEA" + "1drms.@@@@@"
$Domains += $input.MSTeamsID + "." + "EMEA" + "2drms.@@@@@"

#Verify in customers Microsoft Tenant, will retry while errors
foreach ($i in $Domains){

#Check is Custom Domain already verified
$apiUrl = "https://graph.microsoft.com/v1.0/domains/$i"
$dom = Invoke-RestMethod -Headers @{Authorization = "Bearer $($token)"} -Uri $apiUrl -Method Get
$verified = $dom.isVerified

#Report failure if custom domain does not exist
if($dom){}
else {
JobStatusUpdate -job_id $PSPrivateMetadata.JobId.Guid -result "Failed" -des "Domain Does Not Exist $i" -orderid $input.OrderID -ProvStepID "7"
$Success = "1"
}

#If already verifed remove HALO DNS txt record, else verify domain then remove record
if ($verified -Match "True"){
 
        JobStatusUpdate -job_id $PSPrivateMetadata.JobId.Guid -result "Success" -des "#SDA-Domain Verified $i" -orderid $input.OrderID -ProvStepID "7"
        
        ## Remove TXT records following successful verification
        ## Connect to HALO Tenant and Update DNS
        $Credential = Get-AutomationPSCredential -Name '@@@@@'
        $TenantDetails = Get-AutomationPSCredential -Name '@@@@@'
        $TenantId = $TenantDetails.Username
        Connect-AzAccount -Credential $Credential -Tenant $TenantId
        Set-AzContext -SubscriptionId "@@@@@"       
        $ShortDomain = $i.SubString(0,24)
        Remove-AzDnsRecordSet -Name $ShortDomain -RecordType TXT -ZoneName @@@@@ -ResourceGroupName "uksouth_dns"
        Disconnect-AZAccount

}
else{
$count = "0"
    #Start loop to verify Custom Domain
    while ($count -eq "0"){

        Try {
            #Attemp Verify
            $Error.Clear()	
            $apiUrl = "https://graph.microsoft.com/v1.0/domains/$i/verify"
            Invoke-RestMethod -Headers @{Authorization = "Bearer $($token)"} -Uri $apiUrl -Method Post -Contenttype "application/json"
        } 
        Catch {
            #Continue Loop and ReRun in 10 Seconds
            Start-Sleep -s 10 
        }

        if (!$error) {
        
            #Stop Loop Custom Domain Verifed
            $count = "1"
            JobStatusUpdate -job_id $PSPrivateMetadata.JobId.Guid -result "Success" -des "#SDA-Domain Verified $i" -orderid $input.OrderID -ProvStepID "7"
        
            ## Remove TXT records following successful verification
            ## Connect to HALO Tenant and Update DNS
            $Credential = Get-AutomationPSCredential -Name '@@@@@'
            $TenantDetails = Get-AutomationPSCredential -Name '@@@@@'
            $TenantId = $TenantDetails.Username
            Connect-AzAccount -Credential $Credential -Tenant $TenantId
            Set-AzContext -SubscriptionId "@@@@@"       
            $ShortDomain = $i.SubString(0,24)
            Remove-AzDnsRecordSet -Name $ShortDomain -RecordType TXT -ZoneName @@@@@ -ResourceGroupName "uksouth_dns"
            Disconnect-AZAccount

        }
    }
}
}

#Report Success of process
if ($Success -eq "1"){
JobStatusUpdate -job_id $PSPrivateMetadata.JobId.Guid -result "Failed" -des "#SDA-Ready for phase 2" -orderid $input.OrderID -ProvStepID "8"
}
else {
JobStatusUpdate -job_id $PSPrivateMetadata.JobId.Guid -result "Success" -des "#SDA-Ready for phase 2" -orderid $input.OrderID -ProvStepID "8"
}
