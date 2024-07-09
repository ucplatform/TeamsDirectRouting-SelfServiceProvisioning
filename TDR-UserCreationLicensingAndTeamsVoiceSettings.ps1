<#
.SYNOPSIS
    Phase 3: Add Users to Custom Domains in regions Customer is Active, Assign Users Licenses then configure Voice Settings

.DESCRIPTION
    Base configuration includes, Creating the holding accounts to activate the domain and assigning the licenses the customer selected. Configuing the pstn and voice routing policies based on the Customers requirements, Configuring E911 settings in customers tenant
    @@@@@ = Variables that include System Names, connection strings or Details that have been removed for saftey reasons 

.INPUTS
    Provisioning Portal Via Webhook

#>


#####################################################################################

# Create and License Users in Active Custom Domains #

#####################################################################################

#Create Users
$apiUrl = 'https://graph.microsoft.com/v1.0/users'
Invoke-RestMethod -Headers @{Authorization = "Bearer $($ver)" } -Uri $apiUrl -Body $body -Method Post -Contenttype "application/json"

#Assign MS Base License
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

$apiUrl = "https://graph.microsoft.com/v1.0/users/$upn/assignLicense"
Invoke-RestMethod -Headers @{Authorization = "Bearer $($ver)" } -Uri $apiUrl -Body $body -Method Post -Contenttype "application/json"


#####################################################################################

# Create Teams Voice Configuration #

#####################################################################################


#####################################################################################

# National Policy #

#####################################################################################

#####################################################################################

# Online PSTN Usage Set #

#####################################################################################

#Check if Online PSTN Usage already exists, if not "Else" and create it
Set-CsOnlinePstnUsage -Identity "Global" -Usage @{Add = $ver }

#####################################################################################

# Online VoiceRoutingPolicy #

#####################################################################################

New-CsOnlineVoiceRoutingPolicy -OnlinePstnUsages $ver -Identity $ver


#####################################################################################

# Online VoiceRoute #

#####################################################################################
   

New-CsOnlineVoiceRoute -Identity $ver -Priority 0 -Description $ver -NumberPattern $ver -OnlinePstnUsages $ver -OnlinePstnGatewayList  $ver, $ver


#####################################################################################

# International Policy #

#####################################################################################


#####################################################################################

# Online PSTN Usage Set #

#####################################################################################

Set-CsOnlinePstnUsage -Identity "Global" -Usage @{Add = $ver }


#####################################################################################

# Online VoiceRoutingPolicy #

#####################################################################################
        
New-CsOnlineVoiceRoutingPolicy -OnlinePstnUsages $ver -Identity $ver

#####################################################################################

# Try Online VoiceRoute #

#####################################################################################

New-CsOnlineVoiceRoute -Identity $ver -Priority 0 -Description $ver -NumberPattern "^\+*\d*" -OnlinePstnUsages $ver -OnlinePstnGatewayList  $ver, $ver
            
######################################################################################

# Emergency Calling Policy and Call Routing Policy Per Country

######################################################################################


New-CsTeamsEmergencyCallingPolicy -Identity $ver -Description $ver

$en1 =  New-CsTeamsEmergencyNumber -EmergencyDialString "@@@@@" -OnlinePSTNUsage $ver


New-CsTeamsEmergencyCallRoutingPolicy -Identity $ver -EmergencyNumbers @{add=$ver} -Description $ver

New-CsTeamsEmergencyNumber -EmergencyDialString $ver -OnlinePSTNUsage $ver
Set-CsTeamsEmergencyCallRoutingPolicy -Identity $ver -EmergencyNumbers @{remove=$ver}
