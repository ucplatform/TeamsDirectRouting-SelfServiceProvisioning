<#
.SYNOPSIS
    Service Manager RBAC Role Assignment

.DESCRIPTION
    Assign EA-HALO-ServiceManager the Directory Role - Teams Administrator in Customers Tenant
    @@@@@ = Variables that include System Names, connection strings or Details that have been removed for saftey reasons 
    
.INPUTS
    Portal Via Webhook

#>


#Graph API to customer tenant to pull Ent App Object ID
$apiUrl = 'https://graph.microsoft.com/v1.0/servicePrincipals?$search="appId:@@@@@"'



#Graph API to customer tenant to add Ent App to Teams Administrator Directory Role
$apiUrl = "https://graph.microsoft.com/v1.0/directoryRoles/$ver/members/`$ref"
