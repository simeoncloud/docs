## To run Simeon with delegated authentication, the Sync must authenticate with an Azure AD, non-guest user that has either the Global Administrator role and the Exchange Online Admin role (with permissions for Address lists)
&nbsp;

&nbsp;
or

## the following minimum required roles:
* Authentication Policy Administrator
  * Required to manage Authentication policy settings
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
* SharePoint administrator
  * Required to read/write SharePoint settings

**[Assign an Exchange Online Admin role](https://admin.exchange.microsoft.com/#/adminRoles/addRoleGroup) with the following permissions:**
* Address lists
  * Required for Exchange Online settings

:exclamation: **Without the Global Adminstrator Role, you can read but cannot apply changes to Azure Active Directory User Settings** :exclamation:
