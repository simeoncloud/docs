## Permissions required to run Simeon using delegated authentication

**Assign the following roles to a **non-guest** user in Azure AD:**
* Intune administrator
  * Required to manage Intune/Endpoint
* Compliance administrator 
  * Required to manage security compliance center
* Exchange administrator
  * Require to manage Exchange Online settings
* User administrator
  * Required to create users and groups
* Teams administrator
  * Required to manage Teams settings
* Application administrator
  * Required to manage app registrations and service principles 
* Groups administrator
  * Required to manage groups
* Security administrator
  * Required to manage configurations in Azure AD
* Cloud device administrator
  * Required to read/write Device registration policy 

**[Assign an Exchange Online Admin role](https://admin.exchange.microsoft.com/#/adminRoles/addRoleGroup) with the following permissions:**
* Address lists
  * Required for Exchange Online settings
