# Scripting Repository for Teams Direct Routing - Self Service Provisioning 

This document describes the high-level usage of PowerShell scripts, during the Self-Service Provisioning journey for Teams Direct Routing through ucplatform.io

## Prerequisites:
1: Access to ucplatform.io 
 
2: Global Admin account in the Microsoft Tenant that requires the Teams Direct Routing configuration

# Script Implementation Steps

## Step 1: Provision Customer Specific Custom Domains in Entra ID 
Six Custom Domains are created and can be used as PSTN Gateways for your service, these gateways are used to route your calls. Two custom domains are created in each region for high availability. Only the Custom Domains in the regions you are active in are Activated. This is based on the Telephone Numbers allocated to your service in the platform

The below scripts creates the six Custom domains in your Microsoft Tenant based on the Unique PSTN Domains that have been assigned to your service. Then adds the associated TXT records to a HALO DNS service (not customer DNS) ready for domain verification

**Script Link:** https://github.com/ucplatform/TeamsDirectRouting-SelfServiceProvisioning/blob/main/TDR-CustomDomainsAndDNSRecords.ps1

## Step 2: Verification of Custom Domains in Entra ID 
All six domains are Verified ready to be Activated for your Service if required

The below script verifies all the Custom Domains the HALO Service has created then removes the TXT DNS record from the HALO DNS Service 

**Script Link:** https://github.com/ucplatform/TeamsDirectRouting-SelfServiceProvisioning/blob/main/TDR-CustomDomainsVerification.ps1

## Step 3: Provision single user in each Custom Domain and assign License to activate the domain as a PSTN Gateway, then provision the Voice Settings in Teams to create Direct Routing Policies and Emergency Services policies 
Based on your Telephone Numbers in our System, we Activate the Custom Domains in the Regions you are active.

**Example 1:** All Telephone Numbers are in the US only +1 = Four Custom Domains in the Americas Region are Activated 

**Example 2:** Telephone Number exist in both France and the US = Four Custom Domains are Activated, two in the Americas and two in Europe

Each Custom Domain becomes active by adding a single User account (HALO.EnterpriseVoice) to each domain and assign the User account with a Microsoft License (E1,E3,E5) The licenses do not require voice. These accounts cannot be removed and must remain licensed

The below script Adds Users, Assigns Licenses, Adds Voice Polices then Adds Emergency Policies for the Regions and Countries your company is Active in

**Script Link:**

## Step 4: Add rights to Service Manager Enterprise App
For the Service Manager application to be able to access the Voice Configuration in the Tenant it requires Teams Administrator role. This role allows it to connect and check the Voice settings are correctly configured and count the number of Telephone Numbers utilizing the platform.

The below script assigns the RBAC role of Teams Administator to the Service Manager Enterprise App

**Script Link:**

## Conclusion
The above 4 scripts are the only scripts run against your Tenant during the Automated Self-Service configuration journey
