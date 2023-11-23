<#
.SYNOPSIS
    Service Manager RBAC Role Assignment

.DESCRIPTION
    Assign EA-HALO-ServiceManager the Directory Role - Teams Administrator in Customers Tenant

.INPUTS
    Portal Via Webhook

#>

param
(
    [Parameter(Mandatory=$false)]
    [object] $WebhookData
)

#Covert JSON Body to Input Object
$input = ConvertFrom-Json -InputObject $WebhookData.RequestBody

#Function to update Status 
function JobStatusUpdate {
    param
    (
        [string]$job_id,
        [string]$result,
        [string]$des,
        [string]$Customerid

    )

    $insertquery=" 
    INSERT INTO tb_ServiceManagementTeamsAdminSetupStatus VALUES ('$job_id','$result','$des','$Customerid')
    GO
    " 

    Invoke-Sqlcmd -Query $insertquery -ConnectionString "Data Source=@@@@@;Initial Catalog=@@@@@;Persist Security Info=False;User ID=$dbusername;Password=$dbpassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30"

}


#Passwords
#DB Access Credentials
$CredsDB = Get-AutomationPSCredential -Name '@@@@@'
$dbusername = $CredsDB.Username
$DBPassword = $CredsDB.Password
$dbpassword = $CredsDB.GetNetworkCredential().Password

#Enable Teams Administrator if not already enabled
$body= @"
{ 
    "roleTemplateId": "69091246-20e8-4a56-aa4d-066075b2a7a8"
}
"@


#Graph API to customer tenant to add Ent App to Teams Administrator Directory Role
$apiUrl = "https://graph.microsoft.com/v1.0/directoryRoles"
Invoke-RestMethod -Headers @{Authorization = "Bearer $($input.GraphToken)"} -Uri $apiUrl -Body $body -Method Post -Contenttype "application/json"

#Clear any errors and wait for role to propergate
$Error.Clear()
sleep 90


#Graph API to customer tenant to pull Ent App Object ID
$apiUrl = 'https://graph.microsoft.com/v1.0/servicePrincipals?$search="appId:@@@@@"'
$App = Invoke-RestMethod -Headers @{Authorization = "Bearer $($input.GraphToken)"; ConsistencyLevel='eventual'} -Uri $apiUrl  -Method GET -Contenttype "application/json"
$Value = $App.value.id


#Graph API to directoryRole pull all roles the for loop to find ID for Teams Administrator Role
$apiUrl = "https://graph.microsoft.com/v1.0/directoryRoles"
$App = Invoke-RestMethod -Headers @{Authorization = "Bearer $($input.GraphToken)";} -Uri $apiUrl -Method GET -Contenttype "application/json"

$TeamsAdminID = ""

foreach ($i in $App.value){
if ($i.displayName -eq "Teams Administrator"){
$TeamsAdminID = $i.id
}
}

#Take Object ID of the Enterprise App and assign the Teams Adminstrator Role using the associated Teams Administrator Object ID

#Graph JSON Body ENterpise APP ID 
$body= @"
{
  "@odata.id": "https://graph.microsoft.com/v1.0/directoryObjects/$Value"
}
"@

#Graph API to customer tenant to add Ent App to Teams Administrator Directory Role
$apiUrl = "https://graph.microsoft.com/v1.0/directoryRoles/$TeamsAdminID/members/`$ref"

Invoke-RestMethod -Headers @{Authorization = "Bearer $($input.GraphToken)"} -Uri $apiUrl -Body $body -Method Post -Contenttype "application/json"

#Report Status to HALO Platform
if (!$error) {
JobStatusUpdate -job_id $PSPrivateMetadata.JobId.Guid -result "Success" -des "Success" -Customerid $input.CustomerID
}
else {
JobStatusUpdate -job_id $PSPrivateMetadata.JobId.Guid -result "Failed" -des "$error" -Customerid $input.CustomerID
}