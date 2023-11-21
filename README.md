Scripting Repository for Teams Direct Routing - Self Service Provisioning
This document describes the high-level usage of PowerShell scripts, during the Self Service Provisioning jorney through ucplatform.io

Prerequisites
1: Access to ucplatform.io
2: Global Admin account in Tenant that requires the Teams Direct Routing configuration

Step 1: Provision Customer Specific Custom Domains in Entra ID
Six Custom Domains are created and can be used as PSTN Gateways for your service, these gateways are used to route your calls. Two custom domains are made in each region for high avalibility. Only the Custom Domains in the regions you are active in are Activated. This is based on the Telephone Numbers allocated to your service in the platform

The below scripts creates the six Custom domains in your Tenant based on the Unique PSTN Domains that have been assigned to your service.

Script Link:                

Step 2: Verification of Custom Domains in Entra ID
All six domains are Verifed ready to be Activated for your Service if required

The below script collects the MX records from your Tenant for the Custom Domains, creates the associated record in the parent domain (not your tenant) and then verifies the Custom Domains in your Tenant

Script Link:  

Step 3: Provision single user in each Custom Domain and assign License to activiate the domain as a PSTN Gateway, then provision the Voice Settings in Teams to create Direct Routing Policies and Emergency Services policies
Based on your Telephone Numbers in our System, we Activate the Custom Domains in the Regions you are active.

 Example 1: All Telephone Numbers are in the US only +1 = Four Custom Domains in the Americas Region are Activated
 Example 2: Telephone Number exist in both France and the US = Four Custom Domains are Activated, two in the Americas and two in Europe

Each Custom Domain becomes active by adding a single User account (HALO.EnterpriseVoice) to each domain and assign the User account with a Microsoft License (E1,E3,E5) The licenses do not require voice. These accounts cannot be removed and must remain licensed

The below script creates the Users and Assigns a license. The license was selected by the party performing the Action during the process

Script Link:  

Step 4: Add rights to Service Manager Enterprise App


Conclusion
This script provides an effective way to collate and analyze information about your Microsoft Teams tenants, including their geographical distribution based on the team zones. It uses a CSV file as input, making it easy to handle a large amount of data. It exports the processed data to a CSV file for further analysis.
