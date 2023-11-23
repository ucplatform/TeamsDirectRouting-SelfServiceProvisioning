<#
.SYNOPSIS
    Phase 3: Add Users to Custom Domains in regions Customer is Active, Assign Users Licenses then configure Voice Settings

.DESCRIPTION
    Base configuration includes, Creating the holding accounts to activate the domain and assigning the licenses the customer selected. Configuing the pstn and voice routing policies based on the Customers requirements, Configuring E911 settings in customers tenant

.INPUTS
    Provisioning Portal Via Webhook

#>

param
(
    [Parameter(Mandatory = $false)]
    [object] $WebhookData
)

#Covert JSON Body to Input Object
$input = ConvertFrom-Json -InputObject $WebhookData.RequestBody

#Function to update Status
function JobStatusUpdate {

    param (
        [string]$job_id,
        [string]$result,
        [string]$des,
        [string]$orderid,
        [string]$ProvStepID

    )

    $insertquery = " 
    INSERT INTO tb_JobLog VALUES ('$job_id','$result','$des','$orderid','$ProvStepID')
    GO
    " 

    Invoke-Sqlcmd -Query $insertquery -ConnectionString "Data Source=@@@@@;Initial Catalog=@@@@@;Persist Security Info=False;User ID=$dbusername;Password=$dbpassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30"

}

#Global Variable and Arrays
$export = @();
$export.Clear();
$Domains = @();
$Domains.Clear();
$Success = "1"

#Passwords
#DB Access Credentials
$CredsDB = Get-AutomationPSCredential -Name '@@@@@'
$dbusername = $CredsDB.Username
$DBPassword = $CredsDB.Password
$dbpassword = $CredsDB.GetNetworkCredential().Password

#Create HALO Enterprise Voice Domains Array
foreach ($i in $input.region) {

    $Domains += $input.MSTeamsID + "." + $i.GeographicRegion + "1drms.@@@@@"
    $Domains += $input.MSTeamsID + "." + $i.GeographicRegion + "2drms.@@@@@"  
    $CountryData = [PSCustomObject]@{

        Country = $i.CountryISO2
        FQDN1   = $input.MSTeamsID + "." + $i.GeographicRegion + "1drms.@@@@@"
        FQDN2   = $input.MSTeamsID + "." + $i.GeographicRegion + "2drms.@@@@@"
        DOPU    = $i.CountryISO2 + " National Calls"
        DDC     = "^\" + $i.CountryDiallingCode + "\d*|^\d{3}"
        DVRP    = "VRP_" + $i.CountryISO2 + "_National_Calling"
        IOPU    = $i.CountryISO2 + " International Calls"
        IVRP    = "VRP_" + $i.CountryISO2 + "_International_Calling"
        EOPU    = $i.CountryISO2 + " Emergency Calls"
        EN1     = $i.EmergencyPoliceDialCode
        EN2     = $i.EmergencyAmbulanceDialCode
        EN3     = $i.EmergencyFireDialCode

    }
    $export += $CountryData
}

#####################################################################################

# Create and License Users in Active Custom Domains #

#####################################################################################

# Import System.Web assembly for random password generation function
Add-Type -AssemblyName System.Web

#Global Account Settings
$firstname = "HALO"
$lastname = "EnterpriseVoice"
$location = $i.CountryISO2

#Create user in each domain and assign license
foreach ($i in $Domains) {

    $Error.Clear()
    $upn = $firstname + "." + $lastname + "@" + $i
    $password = [System.Web.Security.Membership]::GeneratePassword(20, 2)


    $body = @"
{
"accountEnabled": true,
"displayName": "$firstname $lastname DONT DELETE",
"mailNickname": "$firstname.$lastname",
"GivenName": "$firstname",
"Surname": "$lastname",
"UsageLocation": "$location",
"userPrincipalName": "$upn",
"passwordProfile" : {
    "password" : "$password"
}
}
"@

    #Check if user already exists, if not "catch" and then create user
    try {
            $apiUrl = 'https://graph.microsoft.com/v1.0/users/$upn'
            Invoke-RestMethod -Headers @{Authorization = "Bearer $($input.GraphToken)" } -Uri $apiUrl -Method Get -Contenttype "application/json"
    } 
    catch {

        $Error.Clear()

        try {
            $apiUrl = 'https://graph.microsoft.com/v1.0/users'
            Invoke-RestMethod -Headers @{Authorization = "Bearer $($input.GraphToken)" } -Uri $apiUrl -Body $body -Method Post -Contenttype "application/json"
        }
        catch {
            JobStatusUpdate -job_id $PSPrivateMetadata.JobId.Guid -result "Failed" -des "#SDA-User Creation In $i Domain Failed" -orderid $input.OrderID -ProvStepID "9"
            $Success = "0"
        }
    }

    if (!$error) {
        JobStatusUpdate -job_id $PSPrivateMetadata.JobId.Guid -result "Success" -des "#SDA-User Created In $i Domain" -orderid $input.OrderID -ProvStepID "9"        
    }

    #Add License to created user (License chosen by Customer during provisioning process"
    $Sku = $input.LicenseSkuID

    $body = @"
{
  "addLicenses": [
    {
      "skuId": "$Sku"
    }
  ],
  "removeLicenses": []
}
"@

    try {
        $apiUrl = "https://graph.microsoft.com/v1.0/users/$upn/assignLicense"
        Invoke-RestMethod -Headers @{Authorization = "Bearer $($input.GraphToken)" } -Uri $apiUrl -Body $body -Method Post -Contenttype "application/json"
    }
    catch {
        JobStatusUpdate -job_id $PSPrivateMetadata.JobId.Guid -result "Failed" -des "#SDA-User Licence Assignment In $i Domain Failed" -orderid $input.OrderID -ProvStepID "9"
        $Success = "0"
    }

    if (!$error) {
        JobStatusUpdate -job_id $PSPrivateMetadata.JobId.Guid -result "Success" -des "#SDA-User Licenced In $i Domain" -orderid $input.OrderID -ProvStepID "9"
    }

}

#####################################################################################

# Create Teams Voice Configuration #

#####################################################################################

#Connect-MicrosoftTeams
try {
    Connect-MicrosoftTeams -AccessTokens @($input.GraphToken, $input.TeamsToken)
}
catch {
    JobStatusUpdate -job_id $PSPrivateMetadata.JobId.Guid -result "Failed" -des "#SDA-Failed to connect to Teams Module with Tokens" -orderid $input.OrderID -ProvStepID "10"
    $Success = "0"
}

if (!$error) { 
    JobStatusUpdate -job_id $PSPrivateMetadata.JobId.Guid -result "Success" -des "#SDA-Successfully connected to Tenant through Teams Module" -orderid $input.OrderID -ProvStepID "10"
}

$Error.Clear()

foreach ($i in $export) {

    $Error.Clear()
    $Country = $i.Country

#####################################################################################

# National Policy #

#####################################################################################

#####################################################################################

# Online PSTN Usage Set #

#####################################################################################

$Usage = Get-CsOnlinePstnUsage -Identity "Global"
#Check if Online PSTN Usage already exists, if not "Else" and create it
$Conf1 = $Usage.Usage -eq $i.DOPU
if ($Conf1){
}      
else {
        $Error.Clear()

        try {
            Set-CsOnlinePstnUsage -Identity "Global" -Usage @{Add = $i.DOPU }

        }
        catch {
            JobStatusUpdate -job_id $PSPrivateMetadata.JobId.Guid -result "Failed" -des "#SDA-Failed to create National OnlinePstnUsage $Country " -orderid $input.OrderID -ProvStepID "12"   
            $Success = "0"
        }
    
}

    if (!$error) {
        JobStatusUpdate -job_id $PSPrivateMetadata.JobId.Guid -result "Success" -des "#SDA-Successfully created National OnlinePstnUsage $Country" -orderid $input.OrderID -ProvStepID "12"
    }

    $Error.Clear()

    #####################################################################################

    # Online VoiceRoutingPolicy #

    #####################################################################################


        #Check if Voice Routing Policy already exists, if not "Else" and create it
        $Conf2 = Get-CsOnlineVoiceRoutingPolicy -Identity $i.DVRP     
        if ($Conf2){
        } 
        else {

        $Error.Clear()

        try {
            New-CsOnlineVoiceRoutingPolicy -OnlinePstnUsages $i.DOPU -Identity $i.DVRP
        }
        catch {
            JobStatusUpdate -job_id $PSPrivateMetadata.JobId.Guid -result "Failed" -des "#SDA-Failed to create National VoiceRoutingPolicy $Country " -orderid $input.OrderID -ProvStepID "12"
            $Success = "0"        
        }

    }
    if (!$error) {
        JobStatusUpdate -job_id $PSPrivateMetadata.JobId.Guid -result "Success" -des "#SDA-Successfully created National VoiceRoutingPolicy $Country " -orderid $input.OrderID -ProvStepID "12"
    }

    $Error.Clear()

    #####################################################################################

    # Online VoiceRoute #

    #####################################################################################
   
    #Check if online voice routes already exists, if not "Else" and create it 
    $Conf3 = Get-CsOnlineVoiceRoute -Identity $i.DOPU
    if ($Conf3){
    }
    Else{
        $Error.Clear()
        $count = "0"
        $attempt = 1
        #Loop to create online voice route to allow for Microsoft to provision background services for 50 attempts then fail
        while ($count -eq "0") {
        try {
            $Error.Clear()
            New-CsOnlineVoiceRoute -Identity $i.DOPU -Priority 0 -Description $i.DOPU -NumberPattern $i.DDC -OnlinePstnUsages $i.DOPU -OnlinePstnGatewayList  $i.FQDN1, $i.FQDN2
        }
        catch {
            $attempt++
            if ($attempt -eq "50"){
                        JobStatusUpdate -job_id $PSPrivateMetadata.JobId.Guid -result "Failed" -des "#SDA-Failed creating National VoiceRoute $Country" -orderid $input.OrderID -ProvStepID "12"
                        $Success = "0"
                        $count = "1"  
            } 
            Start-Sleep -s 20
        }
        #Exit Loop
        if (!$error) {
            $count = "1"
        }
        }
    }

    if (!$error) {
        JobStatusUpdate -job_id $PSPrivateMetadata.JobId.Guid -result "Success" -des "#SDA-Successfully created National VoiceRoute $Country" -orderid $input.OrderID -ProvStepID "12"
    }


    #####################################################################################

    # International Policy #

    #####################################################################################


    #####################################################################################

    # Online PSTN Usage Set #

    #####################################################################################

    $Usage = Get-CsOnlinePstnUsage -Identity "Global"
    #Check if online PSTN Usage Set already exists, if not "Else" and create it 
    $Conf4 = $Usage.Usage -eq $i.IOPU
    if ($Conf4){
    }      
    else {
        $Error.Clear()
        try {
            Set-CsOnlinePstnUsage -Identity "Global" -Usage @{Add = $i.IOPU }
        }
        catch {
            JobStatusUpdate -job_id $PSPrivateMetadata.JobId.Guid -result "Failed" -des "#SDA-Failed to create International OnlinePstnUsage $Country " -orderid $input.OrderID -ProvStepID "12" 
            $Success = "0"
        }
    
    }
        if (!$error) {
            JobStatusUpdate -job_id $PSPrivateMetadata.JobId.Guid -result "Success" -des "#SDA-Successfully created International OnlinePstnUsage $Country" -orderid $input.OrderID -ProvStepID "12"
        }

        $Error.Clear()

        #####################################################################################

        # Online VoiceRoutingPolicy #

        #####################################################################################
        
        #Check if Voice Routing Policy already exists, if not "Else" and create it
        $Conf5 = Get-CsOnlineVoiceRoutingPolicy -Identity $i.IVRP
        if ($Conf5){
        } 
        else {
            $Error.Clear()

            try {
                New-CsOnlineVoiceRoutingPolicy -OnlinePstnUsages $i.IOPU -Identity $i.IVRP
            }
            catch {
                JobStatusUpdate -job_id $PSPrivateMetadata.JobId.Guid -result "Failed" -des "#SDA-Failed to create International VoiceRoutingPolicy $Country " -orderid $input.OrderID -ProvStepID "12"
                $Success = "0"
            }
        }

        if (!$error) {
            JobStatusUpdate -job_id $PSPrivateMetadata.JobId.Guid -result "Success" -des "#SDA-Successfully created International VoiceRoutingPolicy $Country" -orderid $input.OrderID -ProvStepID "12"
        }

        $Error.Clear()

        #####################################################################################

        # Try Online VoiceRoute #

        #####################################################################################

        #Check if online voice routes already exists, if not "Else" and create it 
        $Conf6 = Get-CsOnlineVoiceRoute -Identity $i.IOPU
        if ($Conf6){
        }
        Else{

            $Error.Clear()

            try {
                New-CsOnlineVoiceRoute -Identity $i.IOPU -Priority 0 -Description $i.IOPU -NumberPattern "^\+*\d*" -OnlinePstnUsages $i.IOPU -OnlinePstnGatewayList  $i.FQDN1, $i.FQDN2
            
            }
            catch {
                JobStatusUpdate -job_id $PSPrivateMetadata.JobId.Guid -result "Failed" -des "#SDA-Failed to create International VoiceRoute $Country " -orderid $input.OrderID -ProvStepID "12"
                $Success = "0"           
            }
        
        }

        if (!$error) {
            JobStatusUpdate -job_id $PSPrivateMetadata.JobId.Guid -result "Success" -des "#SDA-Successfully created International VoiceRoute $Country" -orderid $input.OrderID -ProvStepID "12"
        }

######################################################################################

# Emergency Calling Policy and Call Routing Policy Per Country

######################################################################################

#Check for Emergency Calling Policy, if not "Else" and create it
$eopu =  Get-CsTeamsEmergencyCallingPolicy -Identity $i.EOPU

if ($eopu) {
    JobStatusUpdate -job_id $PSPrivateMetadata.JobId.Guid -result "Success" -des "#SDA-Successfully created EmergencyCallingPolicy" -orderid $input.OrderID -ProvStepID "12"
}
else{

    $Error.Clear()

    try {
        New-CsTeamsEmergencyCallingPolicy -Identity $i.EOPU -Description $i.EOPU
    }
    catch {
        JobStatusUpdate -job_id $PSPrivateMetadata.JobId.Guid -result "Failed" -des "#SDA-Failed to create EmergencyCallingPolicy" -orderid $input.OrderID -ProvStepID "12"
        $Success = "0"
    }
}

#Create EmergencyDailString Placeholder
$en1 =  New-CsTeamsEmergencyNumber -EmergencyDialString "@@@@@" -OnlinePSTNUsage $i.DOPU

#Create Emergency Calling Policy and assign placeholder String
$identity = $Country + " Emergency Call Routing Policy"
New-CsTeamsEmergencyCallRoutingPolicy -Identity $identity -EmergencyNumbers @{add=$en1} -Description $identity

#Get the new Emergency Calling Policy
$policy = Get-CsTeamsEmergencyCallRoutingPolicy -Identity $identity

#Create Array
$emergencyDialStrings = @()  # Initialize an empty array

#Add all emergency dail string to array
foreach ($emergencyNumber in $policy.emergencyNumbers) {

    $eds = $emergencyNumber.emergencyDialString

    $emergencyDialStrings += $eds

}

#Remove all emergency dial strings including inherited
foreach ($a in $emergencyDialStrings){ 
$en1 =  New-CsTeamsEmergencyNumber -EmergencyDialString $a -OnlinePSTNUsage $i.DOPU
Set-CsTeamsEmergencyCallRoutingPolicy -Identity $identity -EmergencyNumbers @{remove=$en1}
}


#Add country specific dial strigs i.e US 911, 933
if($i.EN1){
## Set Emergency Calling Numbers ##
$en1 = New-CsTeamsEmergencyNumber -EmergencyDialString $i.EN1 -OnlinePSTNUsage $i.DOPU
## Update Emergency Call Routing Policy ##
Set-CsTeamsEmergencyCallRoutingPolicy -Identity $identity -EmergencyNumbers @{add = $en1}
}

if($i.EN2){
## Set Emergency Calling Numbers ##
$en2 = New-CsTeamsEmergencyNumber -EmergencyDialString $i.EN2 -OnlinePSTNUsage $i.DOPU
## Update Emergency Call Routing Policy ##
Set-CsTeamsEmergencyCallRoutingPolicy -Identity $identity -EmergencyNumbers @{add = $en2}
}

if($i.EN3){
## Set Emergency Calling Numbers ##
$en3 = New-CsTeamsEmergencyNumber -EmergencyDialString $i.EN3 -OnlinePSTNUsage $i.DOPU
## Update Emergency Call Routing Policy ##
Set-CsTeamsEmergencyCallRoutingPolicy -Identity $identity -EmergencyNumbers @{add = $en3}
}

}

Disconnect-MicrosoftTeams

#Report back final configuration status
if ($Success -eq "1"){
JobStatusUpdate -job_id $PSPrivateMetadata.JobId.Guid -result "Success" -des "#SDA-Process Complete" -orderid $input.OrderID -ProvStepID "14"
}
else {
JobStatusUpdate -job_id $PSPrivateMetadata.JobId.Guid -result "Failed" -des "#SDA-Process Complete" -orderid $input.OrderID -ProvStepID "14"
}