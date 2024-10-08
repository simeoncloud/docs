# The Simeon Baseline: A comprehensive set of best practice Microsoft 365 configurations.

Welcome to the Simeon Baseline. Simeon Cloud has expertly configured these settings to optimize your Microsoft 365 environments in accordance with industry best practices. This list represents the most important, relevant and security-focused configurations across Azure AD, Office 365, and Intune. These configurations can be deployed to a tenant to provide a fully functional environment out of the box, capable of enrolling devices using Autopilot, managing devices using Intune and providing secure access to Office 365 for users.

Not yet a client of Simeon? [Get started here](https://www.simeoncloud.com/).

## Summary of security-focused configurations

### Data loss prevention (DLP)
- Users can only access corporate data from:
  - Compliant corporate devices managed by Intune
  - In-office locations
  - Approved applications on personal mobile devices
- Corporate data on personal mobile devices are restricted from leaving approved client applications, preventing data loss
- Integration with third-party services, such as LinkedIn, Dropbox, Google Drive, personal Microsoft accounts, etc., is disabled

### Security auditing
- Microsoft 365 is configured to audit and optionally alert on all login and device management operations

### Authentication
- Multifactor authentication is required whenever authenticating from a personal device or as an administrator
- Corporate devices have a randomized local administrator password

### Endpoint security
- Corporate devices block the use of simple passwords
- Corporate devices are blocked from communicating using insecure protocols
- Corporate devices are encrypted
- Corporate devices use a fixed list of trusted internet sites
- Corporate devices are continuously monitored for security compliance, including encryption status, antivirus protection, and malware protection; non-compliant devices are restricted from accessing corporate data

### Data retention
- All corporate data in O365 is retained for one year, including emails, chat, and files

### User privileges
- End users are restricted from connecting their personal Windows computers to O365
- End users are restricted from creating groups
- End users are restricted from inviting external users to view corporate data

## Entra ID > Authorization Policies
*MSGraph/Policies/AuthorizationPolicy*

###### hidden-header

### Configuration

|Name |Configuration|
| :-- | :-- |
| What does this do? | Defines Azure Active Directory authorization settings. The baseline allows users to sign up for email based subscriptions, use Self-Serve Password Reset, and join the tenant by email validation. Only adminstrators and guest inviters can invite external users to the organization. Users are allowed to read other users. |
| Why should you use this? | If you want to apply Azure Active Directory authorization settings. |
| What is the end-user impact? | Users are not allowed to read BitLocker keys for their owned device. |
| Learn more | [Authorization Policy](https://docs.microsoft.com/en-us/graph/api/resources/authorizationpolicy?view=graph-rest-1.0) |

## Entra ID > Device Settings
*MSGraph/Policies/DeviceRegistrationPolicy*

###### hidden-header

### Configuration

|Name |Configuration|
| :-- | :-- |
| What does this do? | Configures settings that control joining devices to Azure AD. The baseline allows only the groups "Baseline - Device Enrollers" and "Baseline - Microsoft 365 Users" to join devices to Azure AD. These groups may join up to 100 devices and are required to perform MFA when joining the device. |
| Why should you use this? | If you want to restrict the ability to join devices to Azure AD to only authorized groups and require MFA. |
| What is the end-user impact? | <span style='color: red'>High Impact.</span> Only authorized groups may join devices, and users in those groups will be prompted for MFA to join. |
| Learn more | N/A |

## Entra ID > Directory Settings
*MSGraph/Settings*

###### hidden-header

### Consent Policy Settings

|Name |Consent Policy Settings|
| :-- | :-- |
| What does this do? | Prevents users from consenting to 3rd party applications. |
| Why should you use this? | Ensure that only administrators can consent to third-party applications and only administrators can control which permissions are granted. An admin consent workflow can be configured in Azure AD; otherwise, users will be blocked when they try to access an application that requires permissions to access organizational data.  |
| What is the end-user impact? | <span style='color: black'>Low Impact.</span> The number of times a user should be trying to consent a 3rd part application should be low but when they do, they will be blocked. If you have configured the admin consent flow, they will be notified accordingly. This setting is not generally something that requires any communication before turning on. |
| Learn more | [Configure User Consent to Applications](https://learn.microsoft.com/en-us/azure/active-directory/manage-apps/configure-user-consent?pivots=portal) |



###### hidden-header

### Group.Unified

|Name |Group.Unified|
| :-- | :-- |
| What does this do? | Configures restrictions for creating Azure AD Groups. The baseline restricts users not in "Baseline - Group Creators" from creating groups. |
| Why should you use this? | If you want to tighten security around group creation. |
| What is the end-user impact? | <span style='color: red'>High Impact.</span> User who are not in "Baseline - Group Creators" will not be allowed to create Azure AD groups. |
| Learn more | [Manage who can create Microsoft 365 Groups](https://docs.microsoft.com/en-us/microsoft-365/solutions/manage-creation-of-groups?view=o365-worldwide) |

## Entra ID > Enterprise Applications
*MSGraph/ServicePrincipals*

###### hidden-header

### Microsoft Intune

|Name |Microsoft Intune|
| :-- | :-- |
Multi-Tenant App: Microsoft Intune



###### hidden-header

### Microsoft Intune Enrollment

|Name |Microsoft Intune Enrollment|
| :-- | :-- |
Multi-Tenant App: Microsoft Intune Enrollment



###### hidden-header

### Windows Azure Service Management API

|Name |Windows Azure Service Management API|
| :-- | :-- |
Multi-Tenant App: Windows Azure Service Management API

## Entra ID > Enterprise Applications > User Settings
*AadIam/EnterpriseApplicationUserSettings*

###### hidden-header

### Configuration

|Name |Configuration|
| :-- | :-- |
| What does this do? | Prohibits users from registering enterprise applications. |
| Why should you use this? | If you want to prohibit users from registering enterprise applications. |
| What is the end-user impact? | Users will not be able to register enterprise applications. |
| Learn more | [Default user permissions](https://docs.microsoft.com/en-us/azure/active-directory/fundamentals/users-default-permissions#to-restrict-the-default-permissions-for-member-users) |

## Entra ID > External User Guest Settings
*AadIam/ExternalUserGuestSettings*

###### hidden-header

### Configuration

|Name |Configuration|
| :-- | :-- |
| What does this do? | Defines settings for permissions that guest users have in the tenant and to which external tenants guest invitations may be sent. The baseline preserves the Microsoft default settings, which only allows Admins and users in the guest inviter role to send invitations and restricts the permissions of guest users. The baseline also enables one-time passcodes for external users without a Microsoft or Azure AD account. |
| Why should you use this? | The baseline applies Microsoft's default settings for guest users and provides improved functionality through the use of one time passcodes. |
| What is the end-user impact? | <span style='color: red'>High Impact.</span> Authorized users may send invitations to any domain, but guest user permissions are restricted. One time passcodes are enabled. |
| Learn more | [Configure B2B external collaboration settings](https://docs.microsoft.com/en-us/azure/active-directory/external-identities/delegate-invitations#to-configure-external-collaboration-settings) |

## Entra ID > Group Settings
*AadIam/GroupSettings*

###### hidden-header

### Configuration

|Name |Configuration|
| :-- | :-- |
| What does this do? | Configures group membership management options. The baseline restricts the following activities to administrators: owners managing group membership requests, access to features in the portal, creation of security groups, and creation of Microsoft 365 groups. |
| Why should you use this? | If you want to have a more secure group settings environment. |
| What is the end-user impact? | The following activities will be restricted to administrators: owners managing group membership requests, access to features in the portal, creation of security groups, and creation of Microsoft 365 groups. |
| Learn more | [Users, groups, and roles](https://docs.microsoft.com/en-us/azure/active-directory/users-groups-roles/groups-self-service-management) |

## Entra ID > Groups
*MSGraph/Groups*

###### hidden-header

### Baseline - Autopilot Devices - Self Deploying

|Name |Baseline - Autopilot Devices - Self Deploying|
| :-- | :-- |
| What does this do? | Creates a dynamic device group that is used to assign the "Baseline - Self Deploying Profile" Autopilot profile to devices. This group contains corporate physical devices with the tag "Autopilot-SelfDeploying." Devices can be tagged from the Intune portal or via an automated hardware hash upload. To tag in Intune go to Devices > Windows Enrollment > Devices, then select the required device and add to the "Group Tag" field. |
| Why should you use this? | If you want devices to be assigned the "Baseline - Self Deploying Profile" Autopilot profile for device enrollment. |
| What is the end-user impact? | Devices in this group will automatically Autopilot without end-user input. |
| Learn more | [Windows Autopilot Self-Deploying mode](https://docs.microsoft.com/en-us/mem/autopilot/self-deploying) |



###### hidden-header

### Baseline - Autopilot Devices - User Driven

|Name |Baseline - Autopilot Devices - User Driven|
| :-- | :-- |
| What does this do? | Creates a dynamic device group that is used to assign the "Baseline - User Driven Profile" Autopilot profile to devices. This group includes all devices that are not in the Azure AD group "Baseline - Autopilot Devices - Self Deploying." |
| Why should you use this? | When a device is going to be used by a single user, this approach is ideal because the device shows as assigned in all relevant Intune pages and reports. It is also the most stable and consistent Autopilot mode. |
| What is the end-user impact? | Devices with this profile can be Autopiloted by users themselves. The device will be registered to the user and the user will be able to use the company portal application. |
| Learn more | [Windows Autopilot User-Driven mode](https://docs.microsoft.com/en-us/mem/autopilot/user-driven) |



###### hidden-header

### Baseline - Corporate Devices

|Name |Baseline - Corporate Devices|
| :-- | :-- |
| What does this do? | Creates a group that includes all corporate devices regardless if they are virtual or physical. |
| Why should you use this? | This group can be used to assign Intune configurations that should apply to all devices. |
| What is the end-user impact? | N/A |
| Learn more | N/A |



###### hidden-header

### Baseline - Corporate Devices - Android

|Name |Baseline - Corporate Devices - Android|
| :-- | :-- |
| What does this do? | Creates a group that includes only Android devices in Azure AD. |
| Why should you use this? | This group is used to assign Intune configurations that should apply to only Android devices. |
| What is the end-user impact? | N/A |
| Learn more | N/A |



###### hidden-header

### Baseline - Corporate Devices - Apple

|Name |Baseline - Corporate Devices - Apple|
| :-- | :-- |
| What does this do? | Creates a group that includes only Apple devices in Azure AD. |
| Why should you use this? | This group is used to assign Intune configurations that should apply to only Apple devices (e.g. FileVault encryption). |
| What is the end-user impact? | N/A |
| Learn more | N/A |



###### hidden-header

### Baseline - Corporate Devices - Insiders

|Name |Baseline - Corporate Devices - Insiders|
| :-- | :-- |
| What does this do? | Creates a manually assigned device group to which configurations can be deployed before other rings of devices. Devices added to this group will be assigned to the "Insiders" Windows update ring. |
| Why should you use this? | If you want to test configuration changes using release rings (Insiders > Preview > All Devices) containing a subset of devices before deploying to all devices. |
| What is the end-user impact? | Devices in this group may receive and test configuration changes before others. |
| Learn more | N/A |



###### hidden-header

### Baseline - Corporate Devices - Physical

|Name |Baseline - Corporate Devices - Physical|
| :-- | :-- |
| What does this do? | Creates that includes only physical corporate devices managed by Intune. |
| Why should you use this? | This group is used to assign Intune configurations that should apply to only physical devices (e.g. BitLocker encryption). |
| What is the end-user impact? | N/A |
| Learn more | N/A |



###### hidden-header

### Baseline - Corporate Devices - Preview

|Name |Baseline - Corporate Devices - Preview|
| :-- | :-- |
| What does this do? | Creates a manually assigned device group to which configurations can be deployed before other rings of devices. Devices added to this group will be assigned to the "Preview" Windows update ring. |
| Why should you use this? | If you want to test configuration changes using release rings (Insiders > Preview > All Devices) containing a subset of devices before deploying to all devices. |
| What is the end-user impact? | Devices in this group may receive and test configuration changes before others. |
| Learn more | N/A |



###### hidden-header

### Baseline - Device Administrators

|Name |Baseline - Device Administrators|
| :-- | :-- |
| What does this do? | Creates a group of users assigned as local administrators on Azure AD joined devices. The baseline grants users in this group the Azure AD role "Azure AD Joined Device Local Administrator." |
| Why should you use this? | If you want to have a group of users with local administrator permissions on Azure AD joined devices. |
| What is the end-user impact? | Members in this group will have local administrator access on Azure AD joined devices. |
| Learn more | [Azure AD Joined Device Local Administrator Role](https://docs.microsoft.com/en-us/azure/active-directory/users-groups-roles/directory-assign-admin-roles#device-administrators) |



###### hidden-header

### Baseline - Device Enrollers

|Name |Baseline - Device Enrollers|
| :-- | :-- |
| What does this do? | Creates a group of users that have permission to enroll a device that is not registered with Autopilot. If a user is not a member of this group, they cannot enroll a non-Autopilot device. |
| Why should you use this? | If you want to restrict users from being able to enroll new devices into your environment that have not been pre-registered with Autopilot. |
| What is the end-user impact? | Users in this group will be able to have enroll devices without using Autopilot. |
| Learn more | N/A |



###### hidden-header

### Baseline - Excluded from MFA

|Name |Baseline - Excluded from MFA|
| :-- | :-- |
| What does this do? | Creates a group that is used to exclude breakglass accounts from MFA policies through conditional access. |
| Why should you use this? | You do not want to lock yourself out of your Microsoft account. |
| What is the end-user impact? | N/A |
| Learn more | [Manage emergency access accounts in Azure AD](https://learn.microsoft.com/en-us/azure/active-directory/roles/security-emergency-access)  |



###### hidden-header

### Baseline - Group Creators

|Name |Baseline - Group Creators|
| :-- | :-- |
| What does this do? | Creates a manually assigned group whose members are allowed to create Microsoft 365 groups. |
| Why should you use this? | If you want a user to be able to create Microsoft 365 groups. |
| What is the end-user impact? | Users in this group will be able to create Microsoft 365 groups. |
| Learn more | [Manage who can create Microsoft 365 Groups](https://docs.microsoft.com/en-us/microsoft-365/solutions/manage-creation-of-groups?view=o365-worldwide) |



###### hidden-header

### Baseline - Microsoft 365 Users

|Name |Baseline - Microsoft 365 Users|
| :-- | :-- |
| What does this do? | This group is used to assign configurations that should be applied to all Microsoft 365 users. |
| Why should you use this? | If you want to apply certain Simeon Baseline configurations to your users. |
| Learn more | [Assign policies to users and groups](https://docs.microsoft.com/en-us/microsoftteams/assign-policies-users-and-groups) |



###### hidden-header

### Baseline - Microsoft 365 Users - Insiders

|Name |Baseline - Microsoft 365 Users - Insiders|
| :-- | :-- |
| What does this do? | Creates a manually assigned group to which configurations can be deployed before other rings of users. The baseline does not assign this group to any configurations. It is provided as a convenience. |
| Why should you use this? | If you want to test configuration changes using release rings (Insiders > Preview > All Users) containing a subset of users before deploying to all users. |
| What is the end-user impact? | Users in this group may receive and test configuration changes before others. |
| Learn more | N/A |



###### hidden-header

### Baseline - Microsoft 365 Users - Preview

|Name |Baseline - Microsoft 365 Users - Preview|
| :-- | :-- |
| What does this do? | Creates a manually assigned group to which configurations can be deployed before other rings of users. The baseline does not assign this group to any configurations. It is provided as a convenience. |
| Why should you use this? | If you want to test configuration changes using release rings (Insiders > Preview > All Users) containing a subset of users before deploying to all users. |
| What is the end-user impact? | Users in this group may receive and test configuration changes before others. |
| Learn more | N/A |



###### hidden-header

### Baseline - PIM Approvers

|Name |Baseline - PIM Approvers|
| :-- | :-- |
| What does this do? | Creates a manually assigned group whose members are allowed to approve PIM request for activiating the Global Administrator Role. |
| Why should you use this? | To have a formal group that approvers for users elevating their priviledges temporarily. |
| What is the end-user impact? | Users in this group will be able approve Privileged Identity Management Request for the Global Admin Role |
| Learn more | [Plan a Privileged Identity Management Deployment]( https://learn.microsoft.com/en-us/azure/active-directory/privileged-identity-management/pim-deployment-plan)|



###### hidden-header

### Baseline - Unrestricted Access From Unmanaged Devices And Untrusted Locations

|Name |Baseline - Unrestricted Access From Unmanaged Devices And Untrusted Locations|
| :-- | :-- |
| What does this do? | C |

## Entra ID > Mobility (MDM and MAM)
*AadIam/MdmApplications*

###### hidden-header

### Microsoft Intune

|Name |Microsoft Intune|
| :-- | :-- |
| What does this do? | Configures Intune enrollment settings for devices. The baseline configures devices to automatically enroll in Intune when joining Azure AD. |
| Why should you use this? | If you want to use Intune to manage devices. |
| What is the end-user impact? | N/A |
| Learn more | [MDM vs. MAM](https://techcommunity.microsoft.com/t5/microsoft-intune/mdm-vs-mam/m-p/90906)



###### hidden-header

### Microsoft Intune Enrollment

|Name |Microsoft Intune Enrollment|
| :-- | :-- |
| What does this do? | Configures a second version of Microsoft Intune enrollment settings, which is required in some tenants depending on tenant age. The baseline configures devices to automatically enroll in Intune when joining Azure AD. |
| Why should you use this? | If you want to use Intune to manage devices. |
| What is the end-user impact? | N/A |
| Learn more | [Intune vs. Intune Enrollment](https://github.com/MicrosoftDocs/azure-docs/issues/27017) |

## Entra ID > Organization (Company Branding)
*MSGraph/Organization*

###### hidden-header

### Configuration

|Name |Configuration|
| :-- | :-- |
| What does this do? | Defines the messages and logos shown to users on Azure login screens. The baseline automatically populates the username watermark with "user@yourcompanyname.org." |
| Why should you use this? | If you want to provide your users with a personalized login screen for added security, familiarity, and branding. |
| What is the end-user impact? | Users will see the watermark (username hint) on Azure login screens. |
| Learn more | [Customize your Azure AD sign-in page](https://docs.microsoft.com/en-us/azure/active-directory/fundamentals/customize-branding) |

## Entra ID > Password Reset
*AadIam/PasswordResetPolicies*

###### hidden-header

### Configuration

|Name |Configuration|
| :-- | :-- |
| What does this do? | Defines Azure's password reset policy and specifies the Azure AD groups to which it applies. This allows users to reset their passwords or unlock their Azure accounts. The baseline applies the password reset policy to members of the group "Baseline - Microsoft 365 Users." |
| Why should you use this? | If you want users to use self-service password reset instead of contacting IT support. This improves password reset security because it requires that users reset their passwords only via Mobile application code (the authenticator app) or SMS. |
| What is the end-user impact? | <span style='color: red'>High Impact.</span> Users can securely recover and reset their passwords. |
| Learn more | [How it works: Azure AD self-service password reset](https://docs.microsoft.com/en-us/azure/active-directory/authentication/concept-sspr-howitworks)

## Entra ID > Privileged Identity Management > Entra Roles > Access Reviews
*MSGraph/IdentityGovernance/AccessReviews/Definitions*

###### hidden-header

### Global Admin Access Review - Global Administrator

|Name |Global Admin Access Review - Global Administrator|
| :-- | :-- |
| What does this do? | Creates an Access Review Policy for the Global Administrator role. This will notify all Global Admins quarterly and ask to provide a justification reason for maintaining the role. |
| Why should you use this? | Access reviews should be periodically performed for users with permanent or eligible privileged roles. |
| What is the end-user impact? | Users assigned the Global Administrator role will receive an email notice quarterly. They will need to provide a justification reason for keeping this role. If the user selects that the role is not longer needed, that Global Administrator role will be removed from the user. |
| Learn more | [Microsoft Access Reviews](https://learn.microsoft.com/en-us/azure/active-directory/governance/access-reviews-overview) |

## Entra ID > Roles and Administrators
*MSGraph/DirectoryRoles*

###### hidden-header

### Application Administrator

|Name |Application Administrator|
| :-- | :-- |
Can create and manage all aspects of app registrations and enterprise apps.



###### hidden-header

### Application Developer

|Name |Application Developer|
| :-- | :-- |
Can create application registrations independent of the 'Users can register applications' setting.



###### hidden-header

### Authentication Administrator

|Name |Authentication Administrator|
| :-- | :-- |
Can access to view, set and reset authentication method information for any non-admin user.



###### hidden-header

### Azure DevOps Administrator

|Name |Azure DevOps Administrator|
| :-- | :-- |
Can manage Azure DevOps organization policy and settings.



###### hidden-header

### Azure Information Protection Administrator

|Name |Azure Information Protection Administrator|
| :-- | :-- |
Can manage all aspects of the Azure Information Protection product.



###### hidden-header

### B2C IEF Keyset Administrator

|Name |B2C IEF Keyset Administrator|
| :-- | :-- |
Can manage secrets for federation and encryption in the Identity Experience Framework (IEF).



###### hidden-header

### B2C IEF Policy Administrator

|Name |B2C IEF Policy Administrator|
| :-- | :-- |
Can create and manage trust framework policies in the Identity Experience Framework (IEF).



###### hidden-header

### Billing Administrator

|Name |Billing Administrator|
| :-- | :-- |
Can perform common billing related tasks like updating payment information.



###### hidden-header

### Cloud Application Administrator

|Name |Cloud Application Administrator|
| :-- | :-- |
Can create and manage all aspects of app registrations and enterprise apps except App Proxy.



###### hidden-header

### Cloud Device Administrator

|Name |Cloud Device Administrator|
| :-- | :-- |
Limited access to manage devices in Microsoft Entra ID.



###### hidden-header

### Compliance Administrator

|Name |Compliance Administrator|
| :-- | :-- |
Can read and manage compliance configuration and reports in Microsoft Entra ID and Microsoft 365.



###### hidden-header

### Compliance Data Administrator

|Name |Compliance Data Administrator|
| :-- | :-- |
Creates and manages compliance content.



###### hidden-header

### Conditional Access Administrator

|Name |Conditional Access Administrator|
| :-- | :-- |
Can manage Conditional Access capabilities.



###### hidden-header

### Customer LockBox Access Approver

|Name |Customer LockBox Access Approver|
| :-- | :-- |
Can approve Microsoft support requests to access customer organizational data.



###### hidden-header

### Desktop Analytics Administrator

|Name |Desktop Analytics Administrator|
| :-- | :-- |
Can access and manage Desktop management tools and services.



###### hidden-header

### Directory Readers

|Name |Directory Readers|
| :-- | :-- |
| What does this do? | Can read basic directory information. Commonly used to grant directory read access to applications and guests. |



###### hidden-header

### Directory Synchronization Accounts

|Name |Directory Synchronization Accounts|
| :-- | :-- |
| What does this do? | Only used by Azure AD Connect service. |



###### hidden-header

### Dynamics 365 Administrator

|Name |Dynamics 365 Administrator|
| :-- | :-- |
Can manage all aspects of the Dynamics 365 product.



###### hidden-header

### Exchange Administrator

|Name |Exchange Administrator|
| :-- | :-- |
Can manage all aspects of the Exchange product.



###### hidden-header

### External Identity Provider Administrator

|Name |External Identity Provider Administrator|
| :-- | :-- |
Can configure identity providers for use in direct federation.



###### hidden-header

### Fabric Administrator

|Name |Fabric Administrator|
| :-- | :-- |
Manages all aspects of Microsoft Fabric.



###### hidden-header

### Global Administrator

|Name |Global Administrator|
| :-- | :-- |
| What does this do? | Can manage all aspects of Azure AD and Microsoft services that use Azure AD identities. |



###### hidden-header

### Global Reader

|Name |Global Reader|
| :-- | :-- |
Can read everything that a Global Administrator can, but not update anything.



###### hidden-header

### Groups Administrator

|Name |Groups Administrator|
| :-- | :-- |
Members of this role can create/manage groups, create/manage groups settings like naming and expiration policies, and view groups activity and audit reports.



###### hidden-header

### Guest Inviter

|Name |Guest Inviter|
| :-- | :-- |
Can invite guest users independent of the 'members can invite guests' setting.



###### hidden-header

### Helpdesk Administrator

|Name |Helpdesk Administrator|
| :-- | :-- |
Can reset passwords for non-administrators and Helpdesk Administrators.



###### hidden-header

### Hybrid Identity Administrator

|Name |Hybrid Identity Administrator|
| :-- | :-- |
Can manage Active Directory to Microsoft Entra cloud provisioning, Microsoft Entra Connect, and federation settings.



###### hidden-header

### Intune Administrator

|Name |Intune Administrator|
| :-- | :-- |
Can manage all aspects of the Intune product.



###### hidden-header

### Kaizala Administrator

|Name |Kaizala Administrator|
| :-- | :-- |
Can manage settings for Microsoft Kaizala.



###### hidden-header

### License Administrator

|Name |License Administrator|
| :-- | :-- |
Can manage product licenses on users and groups.



###### hidden-header

### Message Center Privacy Reader

|Name |Message Center Privacy Reader|
| :-- | :-- |
Can read security messages and updates in Office 365 Message Center only.



###### hidden-header

### Message Center Reader

|Name |Message Center Reader|
| :-- | :-- |
Can read messages and updates for their organization in Office 365 Message Center only.



###### hidden-header

### Network Administrator

|Name |Network Administrator|
| :-- | :-- |
Can manage network locations and review enterprise network design insights for Microsoft 365 Software as a Service applications.



###### hidden-header

### Office Apps Administrator

|Name |Office Apps Administrator|
| :-- | :-- |
Can manage Office apps cloud services, including policy and settings management, and manage the ability to select, unselect and publish 'what's new' feature content to end-user's devices.



###### hidden-header

### Password Administrator

|Name |Password Administrator|
| :-- | :-- |
Can reset passwords for non-administrators and Password Administrators.



###### hidden-header

### Power Platform Administrator

|Name |Power Platform Administrator|
| :-- | :-- |
Can create and manage all aspects of Microsoft Dynamics 365, PowerApps and Microsoft Flow.



###### hidden-header

### Printer Administrator

|Name |Printer Administrator|
| :-- | :-- |
Can manage all aspects of printers and printer connectors.



###### hidden-header

### Printer Technician

|Name |Printer Technician|
| :-- | :-- |
Can register and unregister printers and update printer status.



###### hidden-header

### Privileged Authentication Administrator

|Name |Privileged Authentication Administrator|
| :-- | :-- |
Can access to view, set and reset authentication method information for any user (admin or non-admin).



###### hidden-header

### Privileged Role Administrator

|Name |Privileged Role Administrator|
| :-- | :-- |
Can manage role assignments in Microsoft Entra ID, and all aspects of Privileged Identity Management.



###### hidden-header

### Reports Reader

|Name |Reports Reader|
| :-- | :-- |
Can read sign-in and audit reports.



###### hidden-header

### Search Administrator

|Name |Search Administrator|
| :-- | :-- |
Can create and manage all aspects of Microsoft Search settings.



###### hidden-header

### Search Editor

|Name |Search Editor|
| :-- | :-- |
Can create and manage the editorial content such as bookmarks, Q and As, locations, floorplan.



###### hidden-header

### Security Administrator

|Name |Security Administrator|
| :-- | :-- |
Can read security information and reports, and manage configuration in Microsoft Entra ID and Office 365.



###### hidden-header

### Security Operator

|Name |Security Operator|
| :-- | :-- |
Creates and manages security events.



###### hidden-header

### Security Reader

|Name |Security Reader|
| :-- | :-- |
Can read security information and reports in Microsoft Entra ID and Office 365.



###### hidden-header

### Service Support Administrator

|Name |Service Support Administrator|
| :-- | :-- |
Can read service health information and manage support tickets.



###### hidden-header

### SharePoint Administrator

|Name |SharePoint Administrator|
| :-- | :-- |
Can manage all aspects of the SharePoint service.



###### hidden-header

### Skype for Business Administrator

|Name |Skype for Business Administrator|
| :-- | :-- |
Can manage all aspects of the Skype for Business product.



###### hidden-header

### Teams Administrator

|Name |Teams Administrator|
| :-- | :-- |
Can manage the Microsoft Teams service.



###### hidden-header

### Teams Communications Administrator

|Name |Teams Communications Administrator|
| :-- | :-- |
Can manage calling and meetings features within the Microsoft Teams service.



###### hidden-header

### Teams Communications Support Engineer

|Name |Teams Communications Support Engineer|
| :-- | :-- |
Can troubleshoot communications issues within Teams using advanced tools.



###### hidden-header

### Teams Communications Support Specialist

|Name |Teams Communications Support Specialist|
| :-- | :-- |
Can troubleshoot communications issues within Teams using basic tools.



###### hidden-header

### Teams Devices Administrator

|Name |Teams Devices Administrator|
| :-- | :-- |
Can perform management related tasks on Teams certified devices.



###### hidden-header

### User Administrator

|Name |User Administrator|
| :-- | :-- |
Can manage all aspects of users and groups, including resetting passwords for limited admins.

## Entra ID > Roles and Administrators
*MSGraph/RoleManagement/Directory/RoleDefinitions*

###### hidden-header

### Application Administrator

|Name |Application Administrator|
| :-- | :-- |
Can create and manage all aspects of app registrations and enterprise apps.



###### hidden-header

### Application Developer

|Name |Application Developer|
| :-- | :-- |
Can create application registrations independent of the 'Users can register applications' setting.



###### hidden-header

### Attribute Definition Administrator

|Name |Attribute Definition Administrator|
| :-- | :-- |
Define and manage the definition of custom security attributes.



###### hidden-header

### Authentication Administrator

|Name |Authentication Administrator|
| :-- | :-- |
Can access to view, set and reset authentication method information for any non-admin user.



###### hidden-header

### Azure AD Joined Device Local Administrator

|Name |Azure AD Joined Device Local Administrator|
| :-- | :-- |
| What does this do? | Users assigned to this role are added to the local administrators group on Azure AD-joined devices. |



###### hidden-header

### Azure DevOps Administrator

|Name |Azure DevOps Administrator|
| :-- | :-- |
Can manage Azure DevOps organization policy and settings.



###### hidden-header

### Azure Information Protection Administrator

|Name |Azure Information Protection Administrator|
| :-- | :-- |
Can manage all aspects of the Azure Information Protection product.



###### hidden-header

### B2C IEF Keyset Administrator

|Name |B2C IEF Keyset Administrator|
| :-- | :-- |
Can manage secrets for federation and encryption in the Identity Experience Framework (IEF).



###### hidden-header

### B2C IEF Policy Administrator

|Name |B2C IEF Policy Administrator|
| :-- | :-- |
Can create and manage trust framework policies in the Identity Experience Framework (IEF).



###### hidden-header

### Billing Administrator

|Name |Billing Administrator|
| :-- | :-- |
Can perform common billing related tasks like updating payment information.



###### hidden-header

### Cloud Application Administrator

|Name |Cloud Application Administrator|
| :-- | :-- |
Can create and manage all aspects of app registrations and enterprise apps except App Proxy.



###### hidden-header

### Cloud Device Administrator

|Name |Cloud Device Administrator|
| :-- | :-- |
Limited access to manage devices in Microsoft Entra ID.



###### hidden-header

### Compliance Administrator

|Name |Compliance Administrator|
| :-- | :-- |
Can read and manage compliance configuration and reports in Microsoft Entra ID and Microsoft 365.



###### hidden-header

### Compliance Data Administrator

|Name |Compliance Data Administrator|
| :-- | :-- |
Creates and manages compliance content.



###### hidden-header

### Conditional Access Administrator

|Name |Conditional Access Administrator|
| :-- | :-- |
Can manage Conditional Access capabilities.



###### hidden-header

### Customer LockBox Access Approver

|Name |Customer LockBox Access Approver|
| :-- | :-- |
Can approve Microsoft support requests to access customer organizational data.



###### hidden-header

### Desktop Analytics Administrator

|Name |Desktop Analytics Administrator|
| :-- | :-- |
Can access and manage Desktop management tools and services.



###### hidden-header

### Directory Readers

|Name |Directory Readers|
| :-- | :-- |
| What does this do? | Can read basic directory information. Commonly used to grant directory read access to applications and guests. |



###### hidden-header

### Directory Synchronization Accounts

|Name |Directory Synchronization Accounts|
| :-- | :-- |
| What does this do? | Only used by Azure AD Connect service. |



###### hidden-header

### Dynamics 365 Administrator

|Name |Dynamics 365 Administrator|
| :-- | :-- |
Can manage all aspects of the Dynamics 365 product.



###### hidden-header

### Exchange Administrator

|Name |Exchange Administrator|
| :-- | :-- |
Can manage all aspects of the Exchange product.



###### hidden-header

### External Identity Provider Administrator

|Name |External Identity Provider Administrator|
| :-- | :-- |
Can configure identity providers for use in direct federation.



###### hidden-header

### Fabric Administrator

|Name |Fabric Administrator|
| :-- | :-- |
Manages all aspects of Microsoft Fabric.



###### hidden-header

### Global Administrator

|Name |Global Administrator|
| :-- | :-- |
| What does this do? | Can manage all aspects of Azure AD and Microsoft services that use Azure AD identities. |



###### hidden-header

### Global Reader

|Name |Global Reader|
| :-- | :-- |
Can read everything that a Global Administrator can, but not update anything.



###### hidden-header

### Groups Administrator

|Name |Groups Administrator|
| :-- | :-- |
Members of this role can create/manage groups, create/manage groups settings like naming and expiration policies, and view groups activity and audit reports.



###### hidden-header

### Guest Inviter

|Name |Guest Inviter|
| :-- | :-- |
Can invite guest users independent of the 'members can invite guests' setting.



###### hidden-header

### Guest User

|Name |Guest User|
| :-- | :-- |
| What does this do? | Default role for guest users. Can read a limited set of directory information. |



###### hidden-header

### Helpdesk Administrator

|Name |Helpdesk Administrator|
| :-- | :-- |
Can reset passwords for non-administrators and Helpdesk Administrators.



###### hidden-header

### Hybrid Identity Administrator

|Name |Hybrid Identity Administrator|
| :-- | :-- |
Can manage Active Directory to Microsoft Entra cloud provisioning, Microsoft Entra Connect, and federation settings.



###### hidden-header

### Intune Administrator

|Name |Intune Administrator|
| :-- | :-- |
Can manage all aspects of the Intune product.



###### hidden-header

### Kaizala Administrator

|Name |Kaizala Administrator|
| :-- | :-- |
Can manage settings for Microsoft Kaizala.



###### hidden-header

### License Administrator

|Name |License Administrator|
| :-- | :-- |
Can manage product licenses on users and groups.



###### hidden-header

### Message Center Privacy Reader

|Name |Message Center Privacy Reader|
| :-- | :-- |
Can read security messages and updates in Office 365 Message Center only.



###### hidden-header

### Message Center Reader

|Name |Message Center Reader|
| :-- | :-- |
Can read messages and updates for their organization in Office 365 Message Center only.



###### hidden-header

### Network Administrator

|Name |Network Administrator|
| :-- | :-- |
Can manage network locations and review enterprise network design insights for Microsoft 365 Software as a Service applications.



###### hidden-header

### Office Apps Administrator

|Name |Office Apps Administrator|
| :-- | :-- |
Can manage Office apps cloud services, including policy and settings management, and manage the ability to select, unselect and publish 'what's new' feature content to end-user's devices.



###### hidden-header

### Password Administrator

|Name |Password Administrator|
| :-- | :-- |
Can reset passwords for non-administrators and Password Administrators.



###### hidden-header

### Power Platform Administrator

|Name |Power Platform Administrator|
| :-- | :-- |
Can create and manage all aspects of Microsoft Dynamics 365, PowerApps and Microsoft Flow.



###### hidden-header

### Printer Administrator

|Name |Printer Administrator|
| :-- | :-- |
Can manage all aspects of printers and printer connectors.



###### hidden-header

### Printer Technician

|Name |Printer Technician|
| :-- | :-- |
Can register and unregister printers and update printer status.



###### hidden-header

### Privileged Authentication Administrator

|Name |Privileged Authentication Administrator|
| :-- | :-- |
Can access to view, set and reset authentication method information for any user (admin or non-admin).



###### hidden-header

### Privileged Role Administrator

|Name |Privileged Role Administrator|
| :-- | :-- |
Can manage role assignments in Microsoft Entra ID, and all aspects of Privileged Identity Management.



###### hidden-header

### Reports Reader

|Name |Reports Reader|
| :-- | :-- |
Can read sign-in and audit reports.



###### hidden-header

### Search Administrator

|Name |Search Administrator|
| :-- | :-- |
Can create and manage all aspects of Microsoft Search settings.



###### hidden-header

### Search Editor

|Name |Search Editor|
| :-- | :-- |
Can create and manage the editorial content such as bookmarks, Q and As, locations, floorplan.



###### hidden-header

### Security Administrator

|Name |Security Administrator|
| :-- | :-- |
Can read security information and reports, and manage configuration in Microsoft Entra ID and Office 365.



###### hidden-header

### Security Operator

|Name |Security Operator|
| :-- | :-- |
Creates and manages security events.



###### hidden-header

### Security Reader

|Name |Security Reader|
| :-- | :-- |
Can read security information and reports in Microsoft Entra ID and Office 365.



###### hidden-header

### Service Support Administrator

|Name |Service Support Administrator|
| :-- | :-- |
Can read service health information and manage support tickets.



###### hidden-header

### SharePoint Administrator

|Name |SharePoint Administrator|
| :-- | :-- |
Can manage all aspects of the SharePoint service.



###### hidden-header

### Skype for Business Administrator

|Name |Skype for Business Administrator|
| :-- | :-- |
Can manage all aspects of the Skype for Business product.



###### hidden-header

### Teams Administrator

|Name |Teams Administrator|
| :-- | :-- |
Can manage the Microsoft Teams service.



###### hidden-header

### Teams Communications Administrator

|Name |Teams Communications Administrator|
| :-- | :-- |
Can manage calling and meetings features within the Microsoft Teams service.



###### hidden-header

### Teams Communications Support Engineer

|Name |Teams Communications Support Engineer|
| :-- | :-- |
Can troubleshoot communications issues within Teams using advanced tools.



###### hidden-header

### Teams Communications Support Specialist

|Name |Teams Communications Support Specialist|
| :-- | :-- |
Can troubleshoot communications issues within Teams using basic tools.



###### hidden-header

### Teams Devices Administrator

|Name |Teams Devices Administrator|
| :-- | :-- |
Can perform management related tasks on Teams certified devices.



###### hidden-header

### User Administrator

|Name |User Administrator|
| :-- | :-- |
Can manage all aspects of users and groups, including resetting passwords for limited admins.

## Entra ID > Security > Conditional Access > Policies
*MSGraph/Identity/ConditionalAccess/Policies*

###### hidden-header

### Baseline - Block High Risk Sign-Ins

|Name |Baseline - Block High Risk Sign-Ins|
| :-- | :-- |
| What does this do? | Sign-ins detected as high risk are to be blocked via Conditional Access. |
| Why should you use this? | Azure AD Identity Protection uses various signals to detect the risk level for each sign-in. High risk sign-ins should not be blocked until further investigation. |
| What is the end-user impact? | <span style='color: red'>High Impact.</span> Once a respective conditional access policy is implemented, if a high-risk user attempts to login, the user will receive an error message with instructions to contact the administrator to re-enable their access |
| Learn more | [Create Risk Policies](https://learn.microsoft.com/en-us/azure/active-directory/conditional-access/howto-conditional-access-policy-risk) |



###### hidden-header

### Baseline - Block High Risk Users

|Name |Baseline - Block High Risk Users|
| :-- | :-- |
| What does this do? | Users who are determined to be high risk are to be blocked from accessing the system via Conditional Access until an administrator remediates their account. |
| Why should you use this? | Azure AD Identity Protection uses various signals to detect the risk level for each user and determine if an account has likely been compromised. High risk users should not be allowed to sign in until further investigation. |
| What is the end-user impact? | <span style='color: red'>High Impact.</span> Once a respective conditional access policy is implemented, if a high-risk user attempts to login, the user will receive an error message with instructions to contact the administrator to re-enable their access |
| Learn more | [Create Risk Policies](https://learn.microsoft.com/en-us/azure/active-directory/identity-protection/howto-identity-protection-configure-risk-policies) |



###### hidden-header

### Baseline - Block Legacy Authentication

|Name |Baseline - Block Legacy Authentication|
| :-- | :-- |
| What does this do? | Blocks all legacy authentication in the tenant. |
| Why should you use this? | Due to the increased risk associated with legacy authentication protocols, Microsoft recommends that organizations block authentication requests using these protocols and require modern authentication. |
| What is the end-user impact? | <span style='color: yellow'>Medium Impact.</span> The level of impact will vary by organization depending on the use of legacy authentication. It is possible there will be no impact at all if no legacy authentication protocols are in use. If there are some in use like IMAP/POP there would be significant end-user impact as they would not be able to authenticate to their account. |
| Learn more | [Block Legacy Authentication](https://learn.microsoft.com/en-us/azure/active-directory/conditional-access/howto-conditional-access-policy-block-legacy) |



###### hidden-header

### Baseline - Block Persistent Browser Sessions for privileged users

|Name |Baseline - Block Persistent Browser Sessions for privileged users|
| :-- | :-- |
| What does this do? | Users with the Global Administrator role will have to reauthenticate when they close and reopen the browser. |
| Why should you use this? | To reduce the risk of credential theft during user sessions, disallow persistent browser sessions for highly privileged users. |
| What is the end-user impact? | <span style='color: yellow'>Medium Impact.</span> Since this will be only scoped to Global Administrator roles, the impact will be limited. The severity of impact is increased to medium since it does require the scoped users to reauthenticate once every time the user closes and reopens the browser. |
| Learn more | [Configure Authentication Sesssion Management](https://learn.microsoft.com/en-us/azure/active-directory/conditional-access/howto-conditional-access-session-lifetime#policy-2-persistent-browser-session) |



###### hidden-header

### Baseline - Block Platforms Other than iOS or Android from Unmanaged Devices and Untrusted Locations

|Name |Baseline - Block Platforms Other than iOS or Android from Unmanaged Devices and Untrusted Locations|
| :-- | :-- |
| What does this do? | Blocks platforms other than iOS and Android from devices that are off-network and not Intune-managed. This policy does not apply to external/guest users, users in the Azure AD group "Baseline - Unrestricted Access From Unmanaged Devices And Untrusted Locations" or users with the role "Global Administrator" or "Directory Synchronization Accounts." The policy excludes the applications Microsoft Intune and Microsoft Intune Enrollment. |
| Why should you use this? | This policy helps protect your data by blocking authentication from untrusted devices and locations. Application protection policies on iOS and Android protect data and provide DLP. |
| What is the end-user impact? | <span style='color: red'>High Impact.</span> Users are restricted to iOS and Android platforms for authenticating devices when connecting from untrusted devices and locations. |
| Learn more | [How you can protect app data](https://docs.microsoft.com/en-us/mem/intune/apps/app-protection-policy) |



###### hidden-header

### Baseline - Require Approved Client Apps from Unmanaged Devices and Untrusted Locations

|Name |Baseline - Require Approved Client Apps from Unmanaged Devices and Untrusted Locations|
| :-- | :-- |
| What does this do? | Allows only mobile applications (iOS and Android) that support application protection policies (e.g. Outlook, SharePoint, OneDrive, Excel) to connect from off-network and from unmanaged devices. This policy does not apply to external/guest users, users in the Azure AD group "Baseline - Unrestricted Access From Unmanaged Devices And Untrusted Locations" or users with the role "Global Administrator" or "Directory Synchronization Accounts." The policy is assigned to all applications except Microsoft Intune and Microsoft Intune Enrollment. These protection policies do not work from other device types. This policy works in conjunction with the policy "Block Platforms Other than iOS or Android from Unmanaged Devices and Untrusted Locations" to restrict non-iOS and Android platforms and unprotected applications. |
| Why should you use this? | This policy helps protect your data. Application protection policies on iOS and Android protect data and provide DLP. |
| What is the end-user impact? | <span style='color: red'>High Impact.</span> Users may only use applications that support protection policies to access data from iOS and Android devices off-network. |
| Learn more | [How you can protect app data](https://docs.microsoft.com/en-us/mem/intune/apps/app-protection-policy) |



###### hidden-header

### Baseline - Require Compliant Device for Intune Enrollment

|Name |Baseline - Require Compliant Device for Intune Enrollment|
| :-- | :-- |
| What does this do? | Requires that a device be registered in Autopilot by uploading a hardware hash before it can be enrolled in Intune. This policy does not apply to users in the Azure AD group "Baseline - Unrestricted Access From Unmanaged Devices And Untrusted Locations" or users with the role "Global Administrator" or "Directory Synchronization Accounts." |
| Why should you use this? | This increases security by preventing unauthorized devices from being enrolled into your tenant. |
| What is the end-user impact? | <span style='color: red'>High Impact.</span> An administrator must register devices in Autopilot before a general user can enroll it. |
| Learn more | N/A |



###### hidden-header

### Baseline - Require Managed Devices for Authentication

|Name |Baseline - Require Managed Devices for Authentication|
| :-- | :-- |
| What does this do? | Require that users connect to M365 from a device that is managed using conditional access and is listed as compliant in Intune. The group Baseline - Unrestricted Access From Unmanaged Devices And Untrusted Locations is excluded from this policy. Since this policy is so restrictive, it will be created in a report-only state. |
| Why should you use this? | Only compliant, managed devices should be allowed to access corporate resources. |
| What is the end-user impact? | <span style='color: red'>High Impact.</span> Users will not be able to login to their account on devices not enrolled into Intune and in a “Compliant” state. |
| Learn more | [Require a compliant device](https://learn.microsoft.com/en-us/azure/active-directory/conditional-access/howto-conditional-access-policy-compliant-device#create-a-conditional-access-policy) |



###### hidden-header

### Baseline - Require MFA for Admins

|Name |Baseline - Require MFA for Admins|
| :-- | :-- |
| What does this do? | Requires that users with privileged administrator roles authenticate using MFA. The baseline includes all users except those with the Azure AD role "Directory Synchronization Accounts." |
| Why should you use this? | If you want to protect your tenant by requiring MFA for accounts that have privileged access. |
| What is the end-user impact? | <span style='color: red'>High Impact.</span> Users with privileged access must authenticate using MFA. |
| Learn more | [Protect your Microsoft 365 global administrator accounts](https://docs.microsoft.com/en-us/office365/enterprise/protect-your-global-administrator-accounts) |



###### hidden-header

### Baseline - Require MFA for All Users

|Name |Baseline - Require MFA for All Users|
| :-- | :-- |
| What does this do? | Requires MFA for all users. Excludes users part of the "Baseline - Unrestricted Access From Unmanaged Devices And Untrusted Locations." that is part of the baseline. |
| Why should you use this? | By enforcing MFA within an organization, companies can better protect themselves against cyber threats, such as hacking and identity theft. |
| What is the end-user impact? | <span style='color: red'>High Impact.</span> Users must authenticate using MFA when accessing their account. |
| Learn more | [How to: Require MFA for all users with Conditional Access](https://learn.microsoft.com/en-us/azure/active-directory/conditional-access/howto-conditional-access-policy-all-users-mfa) |



###### hidden-header

### Baseline - Require MFA For Azure Management

|Name |Baseline - Require MFA For Azure Management|
| :-- | :-- |
| What does this do? | Requires MFA when accessing the Azure management portal. |
| Why should you use this? | Organizations use many Azure services and manage them from Azure Resource Manager.  To protect these privileged resources, Microsoft recommends requiring multifactor authentication for any user accessing these resources |
| What is the end-user impact? | <span style='color: red'>High Impact.</span> Users accessing the Azure Portal, Azure PowerShell, or Azure CLI must authenticate using MFA. |
| Learn more | [Require MFA for Azure Management](https://learn.microsoft.com/en-us/azure/active-directory/conditional-access/howto-conditional-access-policy-azure-management) |



###### hidden-header

### Baseline - Require MFA for Guest Users

|Name |Baseline - Require MFA for Guest Users|
| :-- | :-- |
| What does this do? | Requries MFA for Guest Users in the organization.  |
| Why should you use this? | By enforcing MFA within an organization, companies can better protect themselves against cyber threats, such as hacking and identity theft. Guest users are likely accessing corprorate data and should be required to have MFA just like other users in the org. |
| What is the end-user impact? | <span style='color: yellow'>Medium Impact.</span> Guest users will be prompted for MFA when signing in. They will have to set up MFA when it is their first time logging in to your organization if they do not have it set up already. |
| Learn more | [Require MFA for Guest Users](https://learn.microsoft.com/en-us/azure/active-directory/conditional-access/howto-policy-guest-mfa) |



###### hidden-header

### Baseline - Require MFA for Intune Enrollment

|Name |Baseline - Require MFA for Intune Enrollment|
| :-- | :-- |
| What does this do? | Requires MFA to enroll a device into Microsoft Intune. |
| Why should you use this? | If you require MFA, employees and students wanting to enroll devices must first authenticate with a second device and two forms of credentials. We do not want unauthorized users joining devices to our network.  |
| What is the end-user impact? | <span style='color: red'>High Impact.</span> Users must fulfill an MFA prompt before enrolling a device into Intune. |
| Learn more | [Confgiure Intune to Require MFA](https://learn.microsoft.com/en-us/MEM/intune/enrollment/multi-factor-authentication#configure-intune-to-require-multifactor-authentication-at-device-enrollment) |



###### hidden-header

### Baseline - Require MFA from Unmanaged Devices and Untrusted Locations

|Name |Baseline - Require MFA from Unmanaged Devices and Untrusted Locations|
| :-- | :-- |
| What does this do? | Requires MFA when authenticating from an unmanaged device that is off-network. This policy does not apply to users with the role "Global Administrator" or "Directory Synchronization Accounts." |
| Why should you use this? | This protects your data by requiring MFA from unmanaged devices and when off-network. |
| What is the end-user impact? | <span style='color: red'>High Impact.</span> Users must authenticate using MFA when accessing data from unmanaged devices and when off-network. |
| Learn more | [How to: Require MFA for access from untrusted networks with Conditional Access](https://docs.microsoft.com/en-us/azure/active-directory/conditional-access/untrusted-networks) |



###### hidden-header

### Baseline - Require MFA to Enroll Devices into Azure AD

|Name |Baseline - Require MFA to Enroll Devices into Azure AD|
| :-- | :-- |
| What does this do? | Requries users to fulfill an MFA prompt before registering a device to Azure AD. |
| Why should you use this? | It is recommended to enforce MFA before a user can register or join their device to Azure AD. This ensures that compromised accounts cannot be used to add rogue devices to Azure Active Directory |
| What is the end-user impact? | <span style='color: yellow'>Medium Impact.</span> Users will get prompted with MFA when trying to register or join devices to Azure Active Directory. This could be through the out-of-box experience, users signing in via the company portal app, or users registering their devices through the account settings. |
| Learn more | [Create Risk Policies](https://learn.microsoft.com/en-us/azure/active-directory/conditional-access/howto-conditional-access-policy-risk) |

## Entra ID > Security > Identity Protection
*AadGraph/IdentityProtectionPolicies*

###### hidden-header

### Sign-In Risk Policy

|Name |Sign-In Risk Policy|
| :-- | :-- |
| What does this do? | Analyzes user sign-ins and calculates a risk score based on the probability that the sign-in was not performed by the user. If a risky sign-in is detected, the user will be prompted for MFA. |
| Why should you use this? | This protects your tenants from nefarious sign-in attempts. |
| What is the end-user impact? | When a sign-in attempt is flagged as risky, the user will be required to complete MFA. If a user has not yet registered for MFA on their account, they would be blocked from accessing their account. You must configure the MFA registration policy for all users who are a part of the sign-in risk policy to ensure that they are not locked out of their accounts. |
| Learn more | [Sign-in risk policy](https://docs.microsoft.com/en-us/azure/active-directory/identity-protection/concept-identity-protection-policies#sign-in-risk-policy) |



###### hidden-header

### User Risk and MFA Registration Policy

|Name |User Risk and MFA Registration Policy|
| :-- | :-- |
| What does this do? | Blocks users that are deemed risky by Microsoft and requires those users to change their password. |
| Why should you use this? | This protects your tenants from hijacked user accounts. |
| What is the end-user impact? | Users deemed risky by Microsoft will be required to perform self-service password reset. Password reset must be configured for all users who are a part of this policy to ensure that they are not locked out of their accounts. |
| Learn more | [User risk policy](https://docs.microsoft.com/en-us/azure/active-directory/identity-protection/concept-identity-protection-policies#user-risk-policy) |

## Entra ID > User Settings
*AadIam/UserSettings*

###### hidden-header

### Configuration

|Name |Configuration|
| :-- | :-- |
| What does this do? | Enables additional controls for users in Azure. The baseline allows users to access the Azure portal, but does not allow users to register applications and does not allow LinkedIn connectors. |
| Why should you use this? | If you want to prohibit users from registering new applications and from sharing data with LinkedIn, but allow them to access the Azure portal. |
| What is the end-user impact? | Users can neither register new applications nor access their LinkedIn connections within Microsoft applications, but users can access the Azure portal. |
| Learn more | [Default user permissions](https://docs.microsoft.com/en-us/azure/active-directory/fundamentals/users-default-permissions#to-restrict-the-default-permissions-for-member-users) |

## Intune > Apps
*MSGraph/DeviceAppManagement/MobileApps*

###### hidden-header

### 7-Zip

|Name |7-Zip|
| :-- | :-- |
| What does this do? | 7-Zip is a file archiver with a high compression ratio. |
| Why should you use this? | 7-Zip is one of the most popular, compatible and fastest file archiving software. |
| What is the end-user impact? | Users will have 7-Zip installed on their computer. |
| Learn more | [7-Zip](https://www.7-zip.org/)



###### hidden-header

### Adobe Acrobat Pro DC

|Name |Adobe Acrobat Pro DC|
| :-- | :-- |
| What does this do? | Installs Adobe Acrobat Pro DC. |
| Why should you use this? | If you want users to have Adobe Acrobat Pro DC installed on their computers. |
| What is the end-user impact? | Users will have Adobe Acrobat Pro DC installed on their computer. |
| Learn more | [Adobe](https://acrobat.adobe.com/us/en/acrobat/acrobat-pro.html)



###### hidden-header

### CMTrace

|Name |CMTrace|
| :-- | :-- |
| What does this do? | CMTrace is one of the Configuration Manager tools. It allows you to view and monitor log files including the following types: Log files in Configuration Manager or Client Component Manager (CCM) format, plain ASCII or Unicode text files, such as Intune logs. |
| Why should you use this? | CMTrace helps to analyze Intune log files by highlighting, filtering, and error lookup. |
| What is the end-user impact? | N/A |
| Learn more | [CMTrace](https://docs.microsoft.com/en-us/mem/configmgr/core/support/cmtrace)



###### hidden-header

### Microsoft .NET Framework 3.5

|Name |Microsoft .NET Framework 3.5|
| :-- | :-- |
| What does this do? | Microsoft .NET Framework 3.5 is used to create and run applications. |
| Why should you use this? | Microsoft .NET Framework 3.5 is required to run many applications. |
| What is the end-user impact? | Users will have Microsoft .NET Framework 3.5 installed on their machines. |
| .NET Framework | [What is .NET Framework?](https://dotnet.microsoft.com/learn/dotnet/what-is-dotnet-framework)



###### hidden-header

### Microsoft Edge for Windows 10

|Name |Microsoft Edge for Windows 10|
| :-- | :-- |
| What does this do? | Microsoft Edge is the browser for business with modern and legacy web compatibility, new privacy features such as Tracking prevention, and built-in productivity tools such as enterprise-grade PDF support and access to Office and corporate search right from a new tab. This is the new Chromium based version of Edge and is a viable replacement for Chrome for many organizations. |
| Why should you use this? | If you want users to have a faster default web browser with more features. |
| What is the end-user impact? | Users will have Microsoft Edge installed on their machines. |
| Learn more | [Microsoft Edge](https://www.microsoft.com/en-us/edge)



###### hidden-header

### Office 365

|Name |Office 365|
| :-- | :-- |
| What does this do? | Office 365 is Microsoft’s productivity suite with popular applications such as Word, Excel and PowerPoint. |
| Why should you use this? | If you want Office 365 desktop applications to be installed on managed devices. |
| What is the end-user impact? | Users will have Office 365 installed on their devices. |
| Learn more | N/A

## Intune > Apps > App Configuration Policies
*MSGraph/DeviceAppManagement/TargetedManagedAppConfigurations*

###### hidden-header

### Baseline - Configure Policy Managed Client Apps on Unmanaged iOS Devices

|Name |Baseline - Configure Policy Managed Client Apps on Unmanaged iOS Devices|
| :-- | :-- |
| What does this do? | Configures the default behavior for application settings of managed applications on unmanaged iOS devices. The baseline expands the list of applications that are allowed by Intune and data loss protection policies. |
| Why should you use this? | If you want to improve your users' iOS mobile experience by expanding the list of allowed applications. |
| What is the end-user impact? |  If you want to expand the list of applications that can access organization data on iOS devices. |
| Learn more | [Add app configuration policies for managed apps without device enrollment](https://docs.microsoft.com/en-us/mem/intune/apps/app-configuration-policies-managed-app) |

## Intune > Apps > App Protection Policies (Platform = Android)
*MSGraph/DeviceAppManagement/AndroidManagedAppProtections*

###### hidden-header

### Baseline - Protect Policy Managed Client Apps on Unmanaged Android Devices

|Name |Baseline - Protect Policy Managed Client Apps on Unmanaged Android Devices|
| :-- | :-- |
| What does this do? | Configures the default behavior for managed client applications on unmanaged Android devices. The baseline allows data to flow between allowed applications, but prohibits users from copying or saving data outside of the application except for users in the Azure AD group "Baseline - Unrestricted Access From Unmanaged Devices And Untrusted Locations." |
| Why should you use this? |  If you want to protect users' personal Android devices by preventing organization data from leaving allowed apps. |
| What is the end-user impact? | <span style='color: red'>High Impact.</span> Android device users cannot copy or save data outside of your managed client applications. |
| Learn more | [App protection policies overview](https://docs.microsoft.com/en-us/mem/intune/apps/app-protection-policy) |

## Intune > Apps > App Protection Policies (Platform = iOS/iPadOS)
*MSGraph/DeviceAppManagement/IosManagedAppProtections*

###### hidden-header

### Baseline - Protect Policy Managed Client Apps on Unmanaged iOS Devices

|Name |Baseline - Protect Policy Managed Client Apps on Unmanaged iOS Devices|
| :-- | :-- |
| What does this do? | Configures the default behavior for managed client apps on unmanaged iOS devices. The baseline allows data to flow between protected apps, but prohibits users from copying or saving data outside of the app except for users in the Azure AD group "Baseline - Unrestricted Access From Unmanaged Devices And Untrusted Locations". |
| Why should you use this? |  If you want to protect your data on users' personal iOS devices by preventing organization data from leaving protected apps. |
| What is the end-user impact? | <span style='color: red'>High Impact.</span> iOS device users cannot copy or save data outside of your managed client apps. |
| Learn more | [How you can protect app data](https://docs.microsoft.com/en-us/mem/intune/apps/app-protection-policy) |

## Intune > Devices > Compliance Policies
*MSGraph/DeviceManagement/DeviceCompliancePolicies*

###### hidden-header

### Baseline - Corporate Devices - Android

|Name |Baseline - Corporate Devices - Android|
| :-- | :-- |
| What does this do? | Defines the required state that a device for an Android phone must be in to be considered compliant before accessing an organization's data. The baseline requires that a device is not jailbroken and requires storage encrpytion. This policy applies to all devices in the Azure AD group "Baseline - Corporate Devices - Android". |
| Why should you use this? | This ensures your managed Android devices meet a minimum level of security to access data. |
| What is the end-user impact? | Users may access an organization's data only if the device meets the conditions specified in the policy. |
| Learn more | [Use compliance policies to set rules for devices you manage with Intune](https://learn.microsoft.com/en-us/mem/intune/protect/compliance-policy-create-android-aosp) |



###### hidden-header

### Baseline - Corporate Devices - iOS

|Name |Baseline - Corporate Devices - iOS|
| :-- | :-- |
| What does this do? | Defines the required state that a device for an iOS/iPad device must be in to be considered compliant before accessing an organization's data. The baseline requires that a device is not jailbroken and prevents simple passwords. It also requires a managed email profile on the device and a threat protection level at or below medium. This policy applies to all devices in the Azure AD group "Baseline - Corporate Devices - Apple". |
| Why should you use this? | This ensures your managed iOS/iPad devices meet a minimum level of security to access data. |
| What is the end-user impact? | Users may access an organization's data only if the device meets the conditions specified in the policy. The user will have to choose a new password every 45 days. They will also have to set up a managed email profile if it is not already configured on the device. |
| Learn more | [Use compliance policies to set rules for devices you manage with Intune](https://learn.microsoft.com/en-us/mem/intune/protect/compliance-policy-create-ios) |



###### hidden-header

### Baseline - Corporate Devices - macOS

|Name |Baseline - Corporate Devices - macOS|
| :-- | :-- |
| What does this do? | Defines the required state that a macOS device must be in to be considered compliant before accessing an organization's data. The baseline requires that a device blocks simple passwords, has firewall enabled, and storage encryption through FileVault. This policy applies to all devices in the Azure AD group "Baseline - Corporate Devices - Apple". |
| Why should you use this? | This ensures your managed macOS devices meet a minimum level of security to access data. |
| What is the end-user impact? | Users may access an organization's data only if the device meets the requirements defined in this policy. |
| Learn more | [Use compliance policies to set rules for devices you manage with Intune](https://learn.microsoft.com/en-us/mem/intune/protect/compliance-policy-create-mac-os) |



###### hidden-header

### Baseline - Corporate Devices - Windows

|Name |Baseline - Corporate Devices - Windows|
| :-- | :-- |
| What does this do? | Defines the required state that a device (both physical and virtual) must be in to be considered compliant before accessing an organization's data. The baseline requires that a device has Microsoft Defender Antimalware configured, Bitlocker, Secure Boot, code integrity, TPM, Antivrus software, Antispyware software, and blocks simple passwords. This policy applies to all devices in the Azure AD group "Baseline - Corporate Devices". |
| Why should you use this? | This ensures your managed Windows devices, both physical and virtual, meet a minimum level of security to access data. |
| What is the end-user impact? | Users may access an organization's data only if the device meets the requiremnets outlined in the policy. |
| Learn more | [Use compliance policies to set rules for devices you manage with Intune](https://learn.microsoft.com/en-us/mem/intune/protect/compliance-policy-create-windows) |

## Intune > Devices > Compliance Policies > Compliance Policy Settings
*MSGraph/DeviceManagement*

###### hidden-header

### Configuration

|Name |Configuration|
| :-- | :-- |
| What does this do? | This removes devices from Intune that have not checked in for over 30 days. In order to ensure an inventory of active authorized devices, device clean-up rules should be configured to automatically delete devices that have not checked in for over 30 days.  |

## Intune > Devices > Configuration Profiles
*MSGraph/DeviceManagement/DeviceConfigurations*

###### hidden-header

### Baseline - Functionality - Microsoft Store Limited to Private Store Only

|Name |Baseline - Functionality - Microsoft Store Limited to Private Store Only|
| :-- | :-- |
| What does this do? | Limits applications available for download in the Microsoft Store via the "Private Store" functionality. This policy allows you to restrict your users to only those applications that you deem necessary. |
| Why should you use this? | If you want to limit the applications which users may download to those in your private store. |
| What is the end-user impact? | <span style='color: red'>High Impact.</span> Users may only use apps that have been added to the private store. |
| Learn more | [Distribute apps using your private store](https://docs.microsoft.com/en-us/microsoft-store/distribute-apps-from-your-private-store) |



###### hidden-header

### Baseline - OS - Default iOS Update Ring

|Name |Baseline - OS - Default iOS Update Ring|
| :-- | :-- |
| What does this do? | Defines the OS update Policy for iOS updates. You may have to modify the UTC differential depending on your time zone. The baseline notifys the users about updates and installs them during a window of 7pm to 5am during the week. This time is 12am to 5am on the weekend. Critial updates get installed immediately. The policy is installed to the "Baseline - Corporate Devices - Apple" Azure AD group. |
| Why should you use this? | To ensure that devices are being patched properly in the organization.  |
| Learn more | [Manage iOS/iPadOS software updates](https://learn.microsoft.com/en-us/mem/intune/protect/software-updates-ios#configure-the-policy) |



###### hidden-header

### Baseline - OS - Default macOS Update Ring

|Name |Baseline - OS - Default macOS Update Ring|
| :-- | :-- |
| What does this do? | Defines the OS update Policy for macOS updates. You may have to modify the UTC differential depending on your time zone. The baseline notifys the users about updates and installs them during a window of 7pm to 5am during the week. This time is 12am to 5am on the weekend. Critial updates get installed immediately. The policy is installed to the "Baseline - Corporate Devices - Apple" Azure AD group. |
| Why should you use this? | To ensure that devices are being patched properly in the organization.  |
| Learn more | [Manage macOS software updates](https://learn.microsoft.com/en-us/mem/intune/protect/software-updates-macos#configure-the-policy |



###### hidden-header

### Baseline - OS - Default Windows 10 Update Ring

|Name |Baseline - OS - Default Windows 10 Update Ring|
| :-- | :-- |
| What does this do? | Defines the default Windows Update configuration for managed devices. The baseline delays feature updates for 30 days and quality updates for 14 days after released by Microsoft. Once the deferral period has expired for the device, users have 3 days to restart (if required). Unattended updates are only applied outside working hours of 5am to 10pm. The Windows Update configuration applies to all corporate devices except those in the "Insiders" or "Preview" update rings that will receive updates before they are released to all other corporates devices. |
| Why should you use this? | If you want to ensure that your devices are kept up-to-date with the latest Windows updates. |
| What is the end-user impact? | Corporate devices outside of the "Insiders" or "Preview" rings will receive Windows feature updates 30 days after being released and quality updates 14 days after being released by Microsoft. |
| Learn more | [Tactical considerations for creating Windows deployment rings](https://techcommunity.microsoft.com/t5/windows-it-pro-blog/tactical-considerations-for-creating-windows-deployment-rings/ba-p/746979) |



###### hidden-header

### Baseline - OS - Insiders Windows 10 Update Ring

|Name |Baseline - OS - Insiders Windows 10 Update Ring|
| :-- | :-- |
| What does this do? | Creates a Windows Update configuration for managed devices in the "Insiders" ring that receive updates before any other device in your tenant. The baseline delays feature and quality updates to "Insiders" for 3 days after released by Microsoft. Once the deferral period has expired for the device, users have 3 days to restart (if required). Unattended updates will be applied outside the working hours of 5am to 10pm. This Windows Update configuration applies to users in the Azure AD group "Baseline - Corporate Devices – Insiders". |
| Why should you use this? | A Windows update ring is the best way to ensure Windows updates are compatible in your environment. The "Insider" ring is meant for users that are technical enough to understand when an update is applied and to let you know if that update caused problems. |
| What is the end-user impact? | Users in the "Insiders" ring will receive feature and quality updates 3 days after being released by Microsoft. |
| Learn more | [Tactical considerations for creating Windows deployment rings](https://techcommunity.microsoft.com/t5/windows-it-pro-blog/tactical-considerations-for-creating-windows-deployment-rings/ba-p/746979) |



###### hidden-header

### Baseline - OS - Local Autopilot Reset Enabled

|Name |Baseline - OS - Local Autopilot Reset Enabled|
| :-- | :-- |
| What does this do? | Enables local Autopilot Reset on Windows 10, which allows an Autopilot Reset to be initiated locally at the device itself. If you do not enable this, you can initiate a reset only from the Azure Portal. |
| Why should you use this? | In the event that remote Autopilot Reset from the Azure Portal is not possible due to connectivity or other issues, a user may initiate an Autopilot Reset themselves to restore their device to a known good state. |
| What is the end-user impact? | Users may initiate an Autopilot Reset themselves, which can come in handy if Autopilot Reset from the Azure Portal is not possible. |
| Learn more | [Windows Autopilot Reset](https://docs.microsoft.com/en-us/windows/deployment/windows-autopilot/windows-autopilot-reset-local) |



###### hidden-header

### Baseline - OS - Preview Windows 10 Update Ring

|Name |Baseline - OS - Preview Windows 10 Update Ring|
| :-- | :-- |
| What does this do? | Creates a Windows Update configuration for managed devices in the "Preview" ring, which receive updates after "Insiders" but before devices with the default policy. The baseline delays feature and quality updates to the "Preview" group for 7 days after released by Microsoft. Once the deferral period has expired for a device, users have 3 days to restart (if required). Unattended updates will only be applied outside working hours of 5am to 10pm. Applies to users in the Azure AD group "Baseline - Corporate Devices – Preview". |
| Why should you use this? | A Windows update ring is the best way to ensure Windows updates are compatible in your environment by testing the update in rings of users. |
| What is the end-user impact? | Users in the "Preview" ring will receive updates 7 days after being released by Microsoft and after Insiders, but before devices with the default policy. |
| Learn more | [Tactical considerations for creating Windows deployment rings](https://techcommunity.microsoft.com/t5/windows-it-pro-blog/tactical-considerations-for-creating-windows-deployment-rings/ba-p/746979) |



###### hidden-header

### Baseline - OS - RDP Enabled

|Name |Baseline - OS - RDP Enabled|
| :-- | :-- |
| What does this do? | Enables Remote Desktop access to the device for users that are members of the "Remote Desktop Users" local group. A separate configuration (Add-AuthenticatedUsersToRemoteDesktopUsers) adds the users to the "Remote Desktop Users" group. |
| Why should you use this? | If you want to allow Remote Desktop access to managed devices. |
| What is the end-user impact? | Users in the "Remote Desktop Users" local group will be able to connect to remote devices. |
| Learn more | [Policy CSP - RemoteDesktopServices](https://docs.microsoft.com/en-us/windows/client-management/mdm/policy-csp-remotedesktopservices) |



###### hidden-header

### Baseline - Security - BitLocker Device Encryption Enabled

|Name |Baseline - Security - BitLocker Device Encryption Enabled|
| :-- | :-- |
| What does this do? | Enables and configures BitLocker device encryption for physical devices. BitLocker requires a machine to have TPM 1.2 or later, which excludes older hardware and virtual machines. |
| Why should you use this? | Device encryption is essential to protecting data on physical devices. |
| What is the end-user impact? | <span style='color: red'>High Impact.</span> Data on users' hard drives are encrypted. |
| Learn more | [Overview of BitLocker Device Encryption in Windows 10](https://docs.microsoft.com/en-us/windows/security/information-protection/bitlocker/bitlocker-device-encryption-overview-windows-10) |



###### hidden-header

### Baseline - Security - IE Site-to-Zone Assignment

|Name |Baseline - Security - IE Site-to-Zone Assignment|
| :-- | :-- |
| What does this do? | Configures URLs to include in the browser's security zones. The baseline configures the Intranet zone to include necessary Microsoft URLs for Azure Active Directory Seamless Single Sign-On. |
| Why should you use this? | Improves your users' browsing experience by automatically logging in to sites secured by Azure AD. |
| What is the end-user impact? | Users will be unable to configure URLs for browser security zones themselves. |
| Learn more | [Internet Explorer security zones registry entries for advanced users](https://support.microsoft.com/en-us/help/182569/internet-explorer-security-zones-registry-entries-for-advanced-users), [Azure Active Directory Seamless Single Sign-On](https://docs.microsoft.com/en-us/azure/active-directory/hybrid/how-to-connect-sso-quick-start) |



###### hidden-header

### Baseline - Security - NTLMv2 LAN Manager Authentication Level

|Name |Baseline - Security - NTLMv2 LAN Manager Authentication Level|
| :-- | :-- |
| What does this do? | Configures the Windows LAN Manager Authentication Level to require NTLMv2. |
| Why should you use this? | This is recommended by Microsoft to prevent the use of insecure protocols. |
| What is the end-user impact? | <span style='color: red'>High Impact.</span> Windows file sharing will not work with any devices that do not support NTLMv2. |
| Learn more | [Network security: LAN Manager authentication level](https://docs.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/network-security-lan-manager-authentication-level) |



###### hidden-header

### Baseline - Security - Password Reset Enabled

|Name |Baseline - Security - Password Reset Enabled|
| :-- | :-- |
| What does this do? | Enables Azure AD users to reset their passwords from the Windows login screen. |
| Why should you use this? | If you want to allow users to reset their passwords from the Windows login screen. |
| What is the end-user impact? | Users may reset their passwords from the Windows login screen. |
| Learn more | [Enable Azure Active Directory self-service password reset at the Windows sign-in screen](https://docs.microsoft.com/en-us/azure/active-directory/authentication/howto-sspr-windows) |



###### hidden-header

### Baseline - Security - Personal Microsoft Accounts Blocked

|Name |Baseline - Security - Personal Microsoft Accounts Blocked|
| :-- | :-- |
| What does this do? | Disables the addition of personal Microsoft accounts to devices to ensure Data Loss Prevention. |
| Why should you use this? | If you want to prevent users from adding personal Microsoft accounts to Windows, which would allow them to transfer data outside of your organization. |
| What is the end-user impact? | Users cannot connect Windows to personal Microsoft accounts. |
| Learn more | [Microsoft accounts configuration](https://docs.microsoft.com/en-us/mem/intune/configuration/device-restrictions-windows-10#cloud-and-storage) |



###### hidden-header

### Baseline - Security - Simple Passwords Disabled

|Name |Baseline - Security - Simple Passwords Disabled|
| :-- | :-- |
| What does this do? | Blocks simple passwords including picture passwords. |
| Why should you use this? | If you want to increase security by blocking simple passwords. |
| What is the end-user impact? | Users are restricted from creating simple passwords. |
| Learn more | [Eliminate bad passwords using Azure Active Directory Password Protection](https://docs.microsoft.com/en-us/azure/active-directory/authentication/concept-password-ban-bad) |



###### hidden-header

### Baseline - UX - Microsoft Consumer Experience Disabled

|Name |Baseline - UX - Microsoft Consumer Experience Disabled|
| :-- | :-- |
| What does this do? | Disables Microsoft Consumer Experiences such as Start suggestions, Membership notifications, Post-OOBE app install and redirect tiles. |
| Why should you use this? | If you want to improve the user experience by eliminating non value-add notifications and suggestions. |
| What is the end-user impact? | Users will not see these additional pop-ups, suggestions and notifications. |
| Learn more | [Policy CSP - Experience](https://docs.microsoft.com/en-us/windows/client-management/mdm/policy-csp-experience#experience-allowwindowsconsumerfeatures) |



###### hidden-header

### Baseline - UX - Windows First Run Animation Disabled

|Name |Baseline - UX - Windows First Run Animation Disabled|
| :-- | :-- |
| What does this do? | Disables Windows First Run animation, which displays animation and marketing when a user first signs into Windows. |
| Why should you use this? | If you want to eliminate marketing materials and non-essential animation during initial sign-in. |
| What is the end-user impact? | Users may have an improved experience when opting out of First Run Animation. |
| Learn more | [Policy CSP - WindowsLogon](https://docs.microsoft.com/en-us/windows/client-management/mdm/policy-csp-windowslogon#windowslogon-enablefirstlogonanimation) |



###### hidden-header

### Baseline - UX - Windows Spotlight Disabled

|Name |Baseline - UX - Windows Spotlight Disabled|
| :-- | :-- |
| What does this do? | Disables Windows Spotlight, which displays tips and third party marketing materials on users' lock screen. |
| Why should you use this? | If you want to eliminate marketing materials being displayed to users. |
| What is the end-user impact? | Users will not receive third party marketing materials on the lock screen. |
| Learn more | [Configure Windows Spotlight on the lock screen](https://docs.microsoft.com/en-us/windows/configuration/windows-spotlight) |

## Intune > Devices > Configuration Profiles (Profile Type = Administrative Templates)
*MSGraph/DeviceManagement/GroupPolicyConfigurations*

###### hidden-header

### Baseline - Functionality - Microsoft Edge Configuration

|Name |Baseline - Functionality - Microsoft Edge Configuration|
| :-- | :-- |
| What does this do? | Configures Microsoft Edge for all devices to automatically sign in to the browser and synchronize history and passwords. Also sets Google as the default search engine. |
| Why should you use this? | If you want to create an optimal user experience for the new Chromium Edge browser. |
| What is the end-user impact? | Users' search history and passwords will be synchronized across devices. |
| Learn more | [Microsoft Edge Enterprise Sync](https://docs.microsoft.com/en-us/deployedge/microsoft-edge-enterprise-sync) |



###### hidden-header

### Baseline - Functionality - OneDrive Silent Configuration

|Name |Baseline - Functionality - OneDrive Silent Configuration|
| :-- | :-- |
| What does this do? | Automatically and silently configures OneDrive and enables the Files On Demand feature. |
| Why should you use this? | Allows users to store data in OneDrive and access it without downloading all OneDrive content to the computer. |
| What is the end-user impact? | The first time a user logs in to a device, OneDrive will automatically sign in. Upon first sign-in the user will be able to see all her files, but not all files need to be downloaded to the computer. Files stored in the cloud will have a cloud icon in the corner, whereas files stored locally will have a green checkmark. |
| Learn more | [Sync files with OneDrive Files on Demand](https://support.microsoft.com/en-us/office/sync-files-with-onedrive-files-on-demand-62e8d748-7877-420f-b600-24b56562aa70) |



###### hidden-header

### Baseline - Functionality - Windows Known Folders Move to OneDrive

|Name |Baseline - Functionality - Windows Known Folders Move to OneDrive|
| :-- | :-- |
| What does this do? | Configures OneDrive's Known Folders Move, which moves the directories Desktop, Documents, and Pictures to OneDrive and disables the option to opt out of the feature. |
| Why should you use this? | When configured this way, OneDrive backs up user data and enables access from any device. |
| What is the end-user impact? | Users may continue using familiar folders while being backed up. |
| Learn more | [Redirect and move Windows known folders to OneDrive](https://docs.microsoft.com/en-us/onedrive/redirect-known-folders) |



###### hidden-header

### Baseline - OS - Sleep When Plugged In Disabled

|Name |Baseline - OS - Sleep When Plugged In Disabled|
| :-- | :-- |
| What does this do? | Sets the system sleep timeout for devices to "Never" when plugged in. |
| Why should you use this? | If you want to prevent desktop computers from going to sleep so you can connect remotely at any time. |
| What is the end-user impact? | Users' devices will not go to sleep when plugged in, so users may connect remotely at any time. |
| Learn more | N/A |



###### hidden-header

### Baseline - Security - LinkedIn Features in Office Applications Disabled

|Name |Baseline - Security - LinkedIn Features in Office Applications Disabled|
| :-- | :-- |
| What does this do? | The baseline turns off LinkedIn features in Office applications. By default, this setting is turned on. |
| Why should you use this? | You can turn off Office LinkedIn features so that your users are not sharing data externally with LinkedIn. |
| What is the end-user impact? | Users will not be able to use the LinkedIn Office features. |
| Learn more | [Integrate LinkedIn account connections in Azure Active Directory](https://docs.microsoft.com/en-us/azure/active-directory/users-groups-roles/linkedin-integration) |

## Intune > Devices > Configuration Profiles (Settings Catalog)
*MSGraph/DeviceManagement/ConfigurationPolicies*

###### hidden-header

### Baseline - Edge Baseline

|Name |Baseline - Edge Baseline|
| :-- | :-- |
| What does this do? | Leverages the default Security Baseline in the Intune admin center for Edge configuration settings. This policy applies to all devices in the Azure AD group "Baseline - Corporate Devices". |
| Why should you use this? | This ensures your managed devices meet get the recommended security settings for Microsoft Edge. |
| What is the end-user impact? | Users will experience the security configurations as defined in the policy. Changes may be required depending on the organization. |
| Learn more | [Security Baseline Profiles in Intune](https://learn.microsoft.com/en-us/mem/intune/protect/security-baselines-configure#create-the-profile) |



###### hidden-header

### Baseline - Office 365 Apps

|Name |Baseline - Office 365 Apps|
| :-- | :-- |
| What does this do? | Leverages the default Security Baseline in the Intune admin center for Office 365 2016 configuration settings. This policy applies to all devices in the Azure AD group "Baseline - Corporate Devices". |
| Why should you use this? | This ensures your managed devices meet get the recommended security settings for Office 365. |
| What is the end-user impact? | Users will experience the security configurations as defined in the policy. Changes may be required depending on the organization. |
| Learn more | [Security Baseline Profiles in Intune](https://learn.microsoft.com/en-us/mem/intune/protect/security-baselines-configure#create-the-profile) |

## Intune > Devices > Enrollment Restrictions
*MSGraph/DeviceManagement/DeviceEnrollmentConfigurations*

###### hidden-header

### limit--All users and all devices

|Name |limit--All users and all devices|
| :-- | :-- |
| What does this do? | This is the default Device Limit Restriction applied with the lowest priority to all users regardless of group membership. |



###### hidden-header

### platformRestrictions--All users and all devices

|Name |platformRestrictions--All users and all devices|
| :-- | :-- |
| What does this do? | This is the default Device Type Restriction applied with the lowest priority to all users regardless of group membership. |



###### hidden-header

### singlePlatformRestriction--Baseline - Device Enrollers can enroll any devices

|Name |singlePlatformRestriction--Baseline - Device Enrollers can enroll any devices|
| :-- | :-- |
| What does this do? | The baseline allows users in the Azure AD group "Baseline - Device Enrollers" to enroll any Windows device, even if they have not been previously registered in Autopilot. This can be overridden by other configurations with a higher priority. |
| Why should you use this? | If you want to allow certain users to register non-Autopilot registered devices. |
| What is the end-user impact? | <span style='color: red'>High Impact.</span> Only certain users will be able to enroll devices to Intune that are non-Autopilot registered. |
| Learn more | [Set enrollment restrictions](https://docs.microsoft.com/en-us/mem/intune/enrollment/enrollment-restrictions-set) |



###### hidden-header

### singlePlatformRestriction--Baseline - Device Enrollers can enroll any devices

|Name |singlePlatformRestriction--Baseline - Device Enrollers can enroll any devices|
| :-- | :-- |
| What does this do? | The baseline allows users in the Azure AD group "Baseline - Device Enrollers" to enroll any Windows device, even if they have not been previously registered in Autopilot. This can be overridden by other configurations with a higher priority. |
| Why should you use this? | If you want to allow certain users to register non-Autopilot registered devices. |
| What is the end-user impact? | <span style='color: red'>High Impact.</span> Only certain users will be able to enroll devices to Intune that are non-Autopilot registered. |
| Learn more | [Set enrollment restrictions](https://docs.microsoft.com/en-us/mem/intune/enrollment/enrollment-restrictions-set) |



###### hidden-header

### singlePlatformRestriction--Baseline - Device Enrollers can enroll any devices

|Name |singlePlatformRestriction--Baseline - Device Enrollers can enroll any devices|
| :-- | :-- |
| What does this do? | The baseline allows users in the Azure AD group "Baseline - Device Enrollers" to enroll any Windows device, even if they have not been previously registered in Autopilot. This can be overridden by other configurations with a higher priority. |
| Why should you use this? | If you want to allow certain users to register non-Autopilot registered devices. |
| What is the end-user impact? | <span style='color: red'>High Impact.</span> Only certain users will be able to enroll devices to Intune that are non-Autopilot registered. |
| Learn more | [Set enrollment restrictions](https://docs.microsoft.com/en-us/mem/intune/enrollment/enrollment-restrictions-set) |



###### hidden-header

### singlePlatformRestriction--Baseline - Device Enrollers can enroll any devices

|Name |singlePlatformRestriction--Baseline - Device Enrollers can enroll any devices|
| :-- | :-- |
| What does this do? | The baseline allows users in the Azure AD group "Baseline - Device Enrollers" to enroll any Windows device, even if they have not been previously registered in Autopilot. This can be overridden by other configurations with a higher priority. |
| Why should you use this? | If you want to allow certain users to register non-Autopilot registered devices. |
| What is the end-user impact? | <span style='color: red'>High Impact.</span> Only certain users will be able to enroll devices to Intune that are non-Autopilot registered. |
| Learn more | [Set enrollment restrictions](https://docs.microsoft.com/en-us/mem/intune/enrollment/enrollment-restrictions-set) |



###### hidden-header

### singlePlatformRestriction--Baseline - Device Enrollers can enroll any devices

|Name |singlePlatformRestriction--Baseline - Device Enrollers can enroll any devices|
| :-- | :-- |
| What does this do? | The baseline allows users in the Azure AD group "Baseline - Device Enrollers" to enroll any Windows device, even if they have not been previously registered in Autopilot. This can be overridden by other configurations with a higher priority. |
| Why should you use this? | If you want to allow certain users to register non-Autopilot registered devices. |
| What is the end-user impact? | <span style='color: red'>High Impact.</span> Only certain users will be able to enroll devices to Intune that are non-Autopilot registered. |
| Learn more | [Set enrollment restrictions](https://docs.microsoft.com/en-us/mem/intune/enrollment/enrollment-restrictions-set) |



###### hidden-header

### windowsHelloForBusiness--All users and all devices

|Name |windowsHelloForBusiness--All users and all devices|
| :-- | :-- |
| What does this do? | This is the default Windows Hello for Business configuration applied with the lowest priority to all users regardless of group membership. |

## Intune > Devices > Scripts
*MSGraph/DeviceManagement/DeviceManagementScripts*

###### hidden-header

### Baseline - Management - Set-IntuneManagementExtensionConfiguration

|Name |Baseline - Management - Set-IntuneManagementExtensionConfiguration|
| :-- | :-- |
| What does this do? | The baseline configures the IntuneManagementExtension to not delete installation logs from devices. |
| Why should you use this? | If you want to have logs available to troubleshoot device management issues. |
| What is the end-user impact? | Users will be able to view installation logs. |
| Learn more | N/A |



###### hidden-header

### Baseline - Management - Set-LocalAdminPassword

|Name |Baseline - Management - Set-LocalAdminPassword|
| :-- | :-- |
| What does this do? | Creates a local administrator account on Windows devices called "devicelocaladmin". This account password is set from the first three portions of the device's BitLocker recovery key (which can be viewed in the Azure portal) plus the letter "X" (e.g. 123456-123456-123456X) |
| Why should you use this? | Administrators with permission to view the BitLocker recovery key will be able to log in to Windows devices using a local administrator account. |
| What is the end-user impact? | N/A |
| Learn more | [View BitLocker recovery keys](https://365adviser.com/azure/how-to-find-the-bitlocker-recovery-key-in-azure-ad) |



###### hidden-header

### Baseline - OS - Enable-TaskSchedulerHistory

|Name |Baseline - OS - Enable-TaskSchedulerHistory|
| :-- | :-- |
| What does this do? | Enables the Windows Task Scheduler to display history of task runs. The baseline enables this setting. It is disabled in Windows by default. |
| Why should you use this? | This can help with troubleshooting scheduled tasks. |
| What is the end-user impact? | N/A |
| Learn more | [Enable Windows task scheduler history](https://medium.com/techygeekshome/enable-windows-task-scheduler-history-996a601a178c) |



###### hidden-header

### Baseline - OS - Set-TimeZone

|Name |Baseline - OS - Set-TimeZone|
| :-- | :-- |
| What does this do? | Configures Windows to set time zone automatically based on location. Also sets the default computer time zone based on public IP address, as some computers have issues using the Auto Time Zone Updater because of ISP or network restrictions. |
| Why should you use this? | If you want to automatically set the time zone based on location. |
| What is the end-user impact? | The time zone will be set automatically based on the device location. |
| Learn more | N/A |



###### hidden-header

### Baseline - Security - Add-AuthenticatedUsersToRemoteDesktopUsers

|Name |Baseline - Security - Add-AuthenticatedUsersToRemoteDesktopUsers|
| :-- | :-- |
| What does this do? | Adds the Authenticated Users group to the Remote Desktop Users group so any authenticated user can connect via Remote Desktop. A separate configuration (Baseline - OS - RDP Enabled) allows users in the "Remote Desktop users' group to access devices remotely. |
| Why should you use this? | If you want to allow users to connect remotely via Remote Desktop. |
| What is the end-user impact? | Users may connect remotely via Remote Desktop. |
| Learn more | N/A |



###### hidden-header

### Baseline - Security - Disable-RdpNetworkLevelAuthentication

|Name |Baseline - Security - Disable-RdpNetworkLevelAuthentication|
| :-- | :-- |
| What does this do? | Disables Network Level Authentication as a requirement for Remote Desktop. This is required to support clients that do not support Network Level Authentication. |
| Why should you use this? | To allow connections via Remote Desktop from non-Azure AD joined devices. |
| What is the end-user impact? | Users may connect remotely via Remote Desktop. |
| Learn more | It is not currently possible to use Network Level Authentication when using Remote Desktop to connect from a non-Azure AD joined device to an Azure AD joined device. Removing the requirement for Network Level Authentication will not prevent clients from trying to negotiate Network Level Authentication if they support it. That means that Windows clients that are not joined to the same Azure AD as the host must explicitly add "enablecredsspsupport:i:0" in the .rdp file when connecting to prevent attempts to pre-authenticate. |

## Intune > Devices > Windows Autopilot Deployment Profiles
*MSGraph/DeviceManagement/WindowsAutopilotDeploymentProfiles*

###### hidden-header

### Baseline: Self Deploying Profile

|Name |Baseline: Self Deploying Profile|
| :-- | :-- |
| What does this do? | Creates an Intune Autopilot profile for enrolling machines using the self deploying method, which enables a device to be enrolled into your environment with little to no user interaction. Self deployment mode comes with restrictions including that the device must have TPM 2.0, and it is not supported on virtual machines even if they have a virtual TPM. Devices in the Azure AD group "Baseline Autopilot Devices Self Deploying" will be assigned this profile. |
| Why should you use this? | This is most useful for devices that will be shared or used as a kiosk. If a device is going to be used by a single user it is best to use the user driven method. |
| What is the end user impact? | User devices assigned to this profile can be configured using the self deployment method. |



###### hidden-header

### Baseline: User Driven Profile

|Name |Baseline: User Driven Profile|
| :-- | :-- |
| What does this do? | Creates an Intune Autopilot profile for enrolling machines using the user driven method. Devices in the Azure AD group "Autopilot Devices User Driven" will be assigned this profile. |
| Why should you use this? | When a device is going to be used by a single user, this approach is ideal because the device shows as assigned in all relevant Intune pages and reports. It is also the most stable and consistent Autopilot mode. |
| What is the end user impact? | Devices with this profile can be enrolled by users themselves. The device will be registered to the user and the user will be able to use the company portal application. |

## Intune > Endpoint Security
*MSGraph/DeviceManagement/Intents*

###### hidden-header

### Baseline - Defender for Endpoint

|Name |Baseline - Defender for Endpoint|
| :-- | :-- |
| What does this do? | Leverages the default Security Baseline in the Intune admin center for Defender for Endpoint configuration settings. This policy applies to all devices in the Azure AD group "Baseline - Corporate Devices". |
| Why should you use this? | This ensures your managed devices meet the recommended security settings for Defender for Endpoint. |
| What is the end-user impact? | Users will experience the security configurations as defined in the policy. Changes may be required depending on the organization. |
| Learn more | [Security Baseline Profiles in Intune](https://learn.microsoft.com/en-us/mem/intune/protect/security-baselines-configure#create-the-profile) |



###### hidden-header

### Baseline - Windows

|Name |Baseline - Windows|
| :-- | :-- |
| What does this do? | Leverages the default Security Baseline in the Intune admin center for Windows 10 and greater device configuration settings. This policy applies to all devices in the Azure AD group "Baseline - Corporate Devices". |
| Why should you use this? | This ensures your managed devices meet the recommended security settings for Windows devics. |
| What is the end-user impact? | Users will experience the security configurations as defined in the policy. Changes may be required depending on the organization. |
| Learn more | [Security Baseline Profiles in Intune](https://learn.microsoft.com/en-us/mem/intune/protect/security-baselines-configure#create-the-profile) |

## Intune > Endpoint Security > Security Baselines
*MSGraph/DeviceManagement/Templates*

###### hidden-header

### MDM Security Baseline for Windows 10 and later for November 2021

|Name |MDM Security Baseline for Windows 10 and later for November 2021|
| :-- | :-- |
MDM Security Baseline for Windows 10 and later



###### hidden-header

### Microsoft Defender for Endpoint baseline

|Name |Microsoft Defender for Endpoint baseline|
| :-- | :-- |
Microsoft Defender for Endpoint baseline as recommended by Microsoft

## Intune > Tenant Administration > Roles > Scope Tags
*MSGraph/DeviceManagement/RoleScopeTags*

###### hidden-header

### Default

|Name |Default|
| :-- | :-- |
Default Role Scope Tag. This will exist by default on all Intune entities whenever a user defined Role Scope Tag is not present.

## M365 Admin Center > Domains
*MSGraph/Domains*

###### hidden-header

### ${ResourceContext:TenantDomainName}

|Name |${ResourceContext:TenantDomainName}|
| :-- | :-- |
| What does this do? | Disables password expiration per Microsoft's recommendation. |
| Why should you use this? | This is recommended by Microsoft and affects Microsoft secure score. |
| What is the end-user impact? | Users will not be required to change their passwords. |
| Learn more | [Dropping the password expiration policies](https://docs.microsoft.com/en-us/archive/blogs/secguide/security-baseline-final-for-windows-10-v1903-and-windows-server-v1903) |

## Microsoft 365 > Exchange > Admin Audit Log Config
*ExchangeOnline/AdminAuditLogConfig*

###### hidden-header

### Configuration

|Name |Configuration|
| :-- | :-- |
| What does this do? | Configures Exchange logging so that IT users can search Exchange audit logs. The baseline turns on Exchange logging. |
| Why should you use this? | If you want to identify who made the change, augment your change logs with detailed records of the change as it was implemented, comply with regulatory requirements and requests for discovery, as well as other tracing. |
| What is the end-user impact? | N/A |
| Learn more | [Turn audit log search on or off](https://docs.microsoft.com/en-us/microsoft-365/compliance/turn-audit-log-search-on-or-off?view=o365-worldwide#turn-on-audit-log-search) |

## Microsoft 365 > Exchange > DomainKeys Identified Mail Signing Config
*ExchangeOnline/DkimSigningConfig*

###### hidden-header

### ${ResourceContext:TenantDomainName}

|Name |${ResourceContext:TenantDomainName}|
| :-- | :-- |
| What does this do? | Enables DomainKeys Identified Mail (DKIM) for the default domain in the tenant. |
| Why should you use this? | DomainKeys Identified Mail (DKIM) allows digital signatures to be added to email messages in the message header, providing a layer of both authenticity and integrity to emails.|
| What is the end-user impact? | While there is no direct impact to end-users, they should experience better outbound mail flow delivery with DKIM in place. |
| Learn more | [Using DKIM](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/email-authentication-dkim-configure?view=o365-worldwide) |



###### hidden-header

### Baseline - Default OnMicrosoft Domain

|Name |Baseline - Default OnMicrosoft Domain|
| :-- | :-- |
| What does this do? | Enables DomainKeys Identified Mail (DKIM) for the .onmicrosoft domain in the tenant. |
| Why should you use this? | DomainKeys Identified Mail (DKIM) allows digital signatures to be added to email messages in the message header, providing a layer of both authenticity and integrity to emails.|
| What is the end-user impact? | While there is no direct impact to end-users, they should experience better outbound mail flow delivery with DKIM in place. |
| Learn more | [Using DKIM](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/email-authentication-dkim-configure?view=o365-worldwide) |

## Microsoft 365 > Exchange > Mail Flow > Remote Domains
*ExchangeOnline/RemoteDomain*

###### hidden-header

### Default

|Name |Default|
| :-- | :-- |
| What does this do? | Blocks users from setting up auto-forwarding rules to external domains. |
| Why should you use this? | This control is intended to prevent bad actors from using client-side forwarding rules to exfiltrate data to external recipients.|
| What is the end-user impact? | With this setting enabled, users will be prevented from setting up any auto-forwarding rules to external domains. |
| Learn more | [Remote Domains in Exchange Online](https://learn.microsoft.com/en-us/exchange/mail-flow-best-practices/remote-domains/remote-domains) |

## Microsoft 365 > Exchange > Malware Filter Policies
*ExchangeOnline/MalwareFilterPolicy*

###### hidden-header

### Baseline - Default

|Name |Baseline - Default|
| :-- | :-- |
| What does this do? | Updates the default anti-malware policy to reject certain file attachment types and enable Zero-Hour auto purge (ZAP).  |
| Why should you use this? | Some types of files (e.g., executable files) are dangerous and should not be sent over email. |
| What is the end-user impact? | With this setting in place, users will not be able to receive attachments specified in the policy.|
| Learn more | [Configure Anti-malware Policies ](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/anti-malware-policies-configure?view=o365-worldwide) |

## Microsoft 365 > Exchange > Modern Authentication
*ExchangeOnline/AuthenticationPolicy*

###### hidden-header

### Baseline - Block Basic Authentication Methods

|Name |Baseline - Block Basic Authentication Methods|
| :-- | :-- |
| What does this do? | Disables Simple Mail Transfer Protocol Authentication and other legacy authentication methods.|
| Why should you use this? | Only modern authentication methods that support MFA should be used in your environment. SMTP auth should be disabled for Exchange Online but may be enabled on a per-mailbox basis. |
| What is the end-user impact? | This will vary depending on the organization and what existing mail infrastructure looks like. This can be impactful if you have scanners, printers, or Line-of-business (LOB) applications leveraging SMTP auth for message relay. |
| Learn more | [Diable STMP Auth](https://learn.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/authenticated-client-smtp-submission#disable-smtp-auth-in-your-organization) |

## Microsoft 365 > Exchange > Organization Config
*ExchangeOnline/OrganizationConfig*

###### hidden-header

### Configuration

|Name |Configuration|
| :-- | :-- |
| What does this do? | Defines various Exchange settings. Microsoft changes these settings frequently as features are added and removed. The baseline uses the default configurations provided by Microsoft. |
| Why should you use this? | If you want to track configuration changes made in the environment. |
| What is the end-user impact? | N/A |
| Learn more | [Set-OrganizationConfig](https://docs.microsoft.com/en-us/powershell/module/exchange/set-organizationconfig?view=exchange-ps) |

## Microsoft 365 > Exchange > Outlook Web App Policies
*ExchangeOnline/OwaMailboxPolicy*

###### hidden-header

### OwaMailboxPolicy-Default

|Name |OwaMailboxPolicy-Default|
| :-- | :-- |
| What does this do? | Configures the default settings for Outlook on the web. The baseline uses the default configurations provided by Microsoft. |
| Why should you use this? | If you want to use the default Outlook on the web policies. |
| What is the end-user impact? | N/A |
| Learn more | [OwaMailboxPolicy](https://docs.microsoft.com/en-us/powershell/module/exchange/set-owamailboxpolicy?view=exchange-ps) |

## Microsoft 365 > Exchange > Sharing Policies
*ExchangeOnline/SharingPolicy*

###### hidden-header

### Baseline - Default

|Name |Baseline - Default|
| :-- | :-- |
| What does this do? | Restricts calendar detail sharing with external users to only free/busy information. |
| Why should you use this? | Users should be restricted on the users they can share their calendar with externally and the level of calendar details. It is recommened to whitelist domains on-demand and leave all others blocked. |
| What is the end-user impact? | With this setting in place, users will not be able to share calendar or contacts to any external domains unless they are whitelisted. A formal request process should be put into place and evaluated when a user needs to share their calendar details.  |
| Learn more | [Sharing Policies](https://learn.microsoft.com/en-us/exchange/sharing/sharing-policies/sharing-policies) |

## Microsoft 365 > Security & Compliance > DLP Compliance Policies
*SecurityAndCompliance/DlpCompliancePolicy*

###### hidden-header

### Baseline - Default DLP Policy for Office 365

|Name |Baseline - Default DLP Policy for Office 365|
| :-- | :-- |
| What does this do? | This policy detects the presence of credit card numbers in externally shared documents and emails. End users are notified of the detection with the suggestion to consider either removing the sensitive data or restricting the sharing.|
| Why should you use this? | Senesitive content should be restricted from being shared inside the organization where it could easily be exfiltrated such as externally sent email messages.|
| What is the end-user impact? | End users are notified of the detection with the suggestion to consider either removing the sensitive data or restricting the sharing. |
| Learn more | [Data loss prevention in Exchange Online](https://learn.microsoft.com/en-us/exchange/security-and-compliance/data-loss-prevention/data-loss-prevention) |



###### hidden-header

### Baseline - Default DLP Policy for Teams

|Name |Baseline - Default DLP Policy for Teams|
| :-- | :-- |
| What does this do? | This policy detects the presence of credit card numbers in Teams chats and channel messages. When this sensitive info is detected, admins will receive an alert but policy tips won't be displayed to users. |
| Why should you use this? | Senesitive content should be restricted from being shared inside the organization where it could easily be exfiltrated such as Teams chats.|
| What is the end-user impact? | Users will continue to be able to send messages but admins will be alerted to senstive content being shared. |
| Learn more | [Data loss prevention and Microsoft Teams](https://learn.microsoft.com/en-us/microsoft-365/compliance/dlp-microsoft-teams?view=o365-worldwide) |



###### hidden-header

### Baseline - Encrypt Email

|Name |Baseline - Encrypt Email|
| :-- | :-- |
| What does this do? | Creates a DLP compliance policy that will automatically encrpyt an email with the word Secure in the subject line. |
| Why should you use this? | Email message encryption helps ensure that only intended recipients can view message content. This places additional protections on senstive content delivered inside or outside the organization. |
| What is the end-user impact? | End-Users will likely need some instructions on how to use email encryption within the organization. Depending on how you role it out, they may have to type a specific subject line or leverage a built in plug-in that allows them to encrypt the message on demand. Users will need to open encrypted messages in Outlook on the web vs the email client on the desktop |
| Learn more | [Message Encrpytion](https://learn.microsoft.com/en-us/microsoft-365/compliance/set-up-new-message-encryption-capabilities?view=o365-worldwide) |



###### hidden-header

### Baseline - External Shared Sender

|Name |Baseline - External Shared Sender|
| :-- | :-- |
| What does this do? | Modifies incoming email such that mail from external users can be easily identified, for example, by prepending the subject line with “[External].” |
| Why should you use this? | Seeing this message can help users identify email messages that might be spoofed and mark them as malicious.|
| What is the end-user impact? | With this setting in place, users will see a prepended message with each email they get originating outside the organization.|
| Learn more | [Mail Flow Rules ](https://learn.microsoft.com/en-us/exchange/security-and-compliance/mail-flow-rules/mail-flow-rules) |

## Microsoft 365 > Security & Compliance > DLP Compliance Policies > Rules
*SecurityAndCompliance/DlpComplianceRule*

###### hidden-header

### Default Teams DLP policy rule

|Name |Default Teams DLP policy rule|
| :-- | :-- |
| What does this do? | This policy detects the presence of credit card numbers in Teams chats and channel messages. When this sensitive info is detected, admins will receive an alert but policy tips won't be displayed to users. |
| Why should you use this? | Senesitive content should be restricted from being shared inside the organization where it could easily be exfiltrated such as Teams chats.|
| What is the end-user impact? | Users will continue to be able to send messages but admins will be alerted to senstive content being shared. |
| Learn more | [Data loss prevention and Microsoft Teams](https://learn.microsoft.com/en-us/microsoft-365/compliance/dlp-microsoft-teams?view=o365-worldwide) |



###### hidden-header

### Encrypt email with the word Secure in subject line

|Name |Encrypt email with the word Secure in subject line|
| :-- | :-- |
| What does this do? | Creates a DLP compliance policy that will automatically encrpyt an email with the word Secure in the subject line. |
| Why should you use this? | Email message encryption helps ensure that only intended recipients can view message content. This places additional protections on senstive content delivered inside or outside the organization. |
| What is the end-user impact? | End-Users will likely need some instructions on how to use email encryption within the organization. Depending on how you role it out, they may have to type a specific subject line or leverage a built in plug-in that allows them to encrypt the message on demand. Users will need to open encrypted messages in Outlook on the web vs the email client on the desktop |
| Learn more | [Message Encrpytion](https://learn.microsoft.com/en-us/microsoft-365/compliance/set-up-new-message-encryption-capabilities?view=o365-worldwide) |

## Microsoft 365 > Security & Compliance > DLP Sensitive Information Types
*SecurityAndCompliance/DlpSensitiveInformationType*

###### hidden-header

### Credit Card Number

|Name |Credit Card Number|
| :-- | :-- |
Detects credit card numbers for American Express, Diner's Club, Discover Card, JCB, BrandSmart, Mastercard, and Visa.

## Microsoft 365 > Security & Compliance > Hosted Content Filter Policies
*ExchangeOnline/HostedContentFilterPolicy*

###### hidden-header

### Baseline - Default

|Name |Baseline - Default|
| :-- | :-- |
| What does this do? | Configures policy settings to protect against inbound spam with bulk compliant level, quarantine, safety tips, and zero hour auto purge. |
| Why should you use this? | Anti-spam policies (also known as spam filter policies or content filter policies) are used as part of your organization's overall defense against spam.|
| What is the end-user impact? | With this setting in place, its possible that false positives will be generated and users will need to look either in their junk folder or have an admin release a message from quarantine that is legitimate|
| Learn more | [Configure Spam Policies ](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/anti-spam-policies-configure) |

## Microsoft 365 > Security & Compliance > Information Governance > Retention
*SecurityAndCompliance/RetentionCompliancePolicy*

###### hidden-header

### Baseline - Default Retention Policy

|Name |Baseline - Default Retention Policy|
| :-- | :-- |
| What does this do? | Defines the data retention policy for SharePoint, OneDrive and Exchange Online. The baseline retains this data for one year. |
| Why should you use this? | If you want this data to be retained for one year and to be searchable in Office 365 content search tools. |
| What is the end-user impact? | Users cannot permanently delete data that is less than one year old. |
| Learn more | [Retention policies and labels](https://docs.microsoft.com/en-us/microsoft-365/compliance/retention?view=o365-worldwide) |



###### hidden-header

### Baseline - Teams Retention Policy

|Name |Baseline - Teams Retention Policy|
| :-- | :-- |
| What does this do? | Defines the data retention policy for Microsoft Teams. Teams retention policies must be created independently of other retention policies. The baseline retains Teams data for one year. |
| Why should you use this? | If you want this data to be retained for one year and to be searchable in Office 365 content search tools. |
| What is the end-user impact? | Users cannot permanently delete data that is less than one year old. |
| Learn more | [Retention policies and labels](https://docs.microsoft.com/en-us/microsoft-365/compliance/retention?view=o365-worldwide) |

## Microsoft 365 > Security & Compliance > Protection Alerts
*SecurityAndCompliance/ProtectionAlert*

###### hidden-header

### A potentially malicious URL click was detected

|Name |A potentially malicious URL click was detected|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### A Tenant Allow Block List entry has been found malicious

|Name |A Tenant Allow Block List entry has been found malicious|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### A user clicked through to a potentially malicious URL

|Name |A user clicked through to a potentially malicious URL|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### Admin Submission Result Completed

|Name |Admin Submission Result Completed|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### Admin triggered manual investigation of email

|Name |Admin triggered manual investigation of email|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### Admin triggered user compromise investigation

|Name |Admin triggered user compromise investigation|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### Compliance Manager Default Alert Policy

|Name |Compliance Manager Default Alert Policy|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### Creation of forwarding/redirect rule

|Name |Creation of forwarding/redirect rule|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### eDiscovery search started or exported

|Name |eDiscovery search started or exported|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### Elevation of Exchange admin privilege

|Name |Elevation of Exchange admin privilege|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### Email messages containing malicious file removed after delivery

|Name |Email messages containing malicious file removed after delivery|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### Email messages containing malicious URL removed after delivery

|Name |Email messages containing malicious URL removed after delivery|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### Email messages containing malware removed after delivery

|Name |Email messages containing malware removed after delivery|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### Email messages containing phish URLs removed after delivery

|Name |Email messages containing phish URLs removed after delivery|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### Email messages from a campaign removed after delivery

|Name |Email messages from a campaign removed after delivery|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### Email messages removed after delivery

|Name |Email messages removed after delivery|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### Email reported by user as junk

|Name |Email reported by user as junk|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### Email reported by user as malware or phish

|Name |Email reported by user as malware or phish|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### Email reported by user as not junk

|Name |Email reported by user as not junk|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### Email sending limit exceeded

|Name |Email sending limit exceeded|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### Failed exact data match upload

|Name |Failed exact data match upload|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### Form flagged and confirmed as phishing

|Name |Form flagged and confirmed as phishing|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### Malware not zapped because ZAP is disabled

|Name |Malware not zapped because ZAP is disabled|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### Messages containing malicious entity not removed after delivery

|Name |Messages containing malicious entity not removed after delivery|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### Messages have been delayed

|Name |Messages have been delayed|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### MIP AutoLabel simulation completed

|Name |MIP AutoLabel simulation completed|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### Phish delivered due to an ETR override

|Name |Phish delivered due to an ETR override|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### Phish delivered due to an IP allow policy

|Name |Phish delivered due to an IP allow policy|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### Phish not zapped because ZAP is disabled

|Name |Phish not zapped because ZAP is disabled|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### Potential Nation-State Activity

|Name |Potential Nation-State Activity|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### Priority accounts' mail flow is unhealthy

|Name |Priority accounts' mail flow is unhealthy|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### Remediation action taken by admin on emails or URL or sender

|Name |Remediation action taken by admin on emails or URL or sender|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### Removed an entry in Tenant Allow/Block List

|Name |Removed an entry in Tenant Allow/Block List|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### Reply-all storm detected

|Name |Reply-all storm detected|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### Retention Auto-labeling Policy Simulation Completed

|Name |Retention Auto-labeling Policy Simulation Completed|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### Successful exact data match upload

|Name |Successful exact data match upload|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### Suspicious connector activity

|Name |Suspicious connector activity|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### Suspicious Email Forwarding Activity

|Name |Suspicious Email Forwarding Activity|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### Suspicious email sending patterns detected

|Name |Suspicious email sending patterns detected|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### Suspicious tenant sending patterns observed

|Name |Suspicious tenant sending patterns observed|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### Teams message reported by user as security risk

|Name |Teams message reported by user as security risk|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### Tenant Allow/Block List entry is about to expire

|Name |Tenant Allow/Block List entry is about to expire|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### Tenant restricted from sending email

|Name |Tenant restricted from sending email|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### Tenant restricted from sending unprovisioned email

|Name |Tenant restricted from sending unprovisioned email|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### Unusual volume of external file sharing

|Name |Unusual volume of external file sharing|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### User requested to release a quarantined message

|Name |User requested to release a quarantined message|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### User restricted from sending email

|Name |User restricted from sending email|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|



###### hidden-header

### User restricted from sharing forms and collecting responses

|Name |User restricted from sharing forms and collecting responses|
| :-- | :-- |
| What does this do? | This policy ensures all Exchange alerts are enabled and are being sent to admins in the tenant when triggered. |
| Why should you use this? | Alert policies in the new Exchange admin center (EAC) allow you to track events related to mail flow. |
| What is the end-user impact? | Only Admin users in the tenant receive email notifiations of alert triggers. End-Users are not affectedd. |
| Learn more | [Alert policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/monitoring/mail-flow-insights/alert-policy-and-its-configuration)|

## Microsoft 365 > Security & Compliance > Threat Management > Policy > ATP Anti-phishing
*ExchangeOnline/AntiPhishPolicy*

###### hidden-header

### Office365 AntiPhish Default

|Name |Office365 AntiPhish Default|
| :-- | :-- |
| What does this do? | Configures the anti-phishing policies to include impersonation protection, mailbox intelligence, and safety tips. |
| Why should you use this? |  Impersonation protection checks incoming emails to see if the sender address is similar to the users or domains on an agency-defined list. If the sender address is significantly similar, as to indicate an impersonation attempt, the email is quarantined. Mailbox intelligence is an artificial intelligence (AI)-based tool for identifying potential impersonation attempts|
| What is the end-user impact? | With this setting in place, users will better protection against spoofing attempts against their email. With additional protections, there is a higher chance of false positives that could negatively impact the user in which they do not receive legitimate mail.|
| Learn more | [Configure Anti-phishing Policies ](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/anti-phishing-policies-eop-configure?view=o365-worldwide) |

## Microsoft 365 > Security & Compliance > Threat Management > Policy > ATP Safe Attachments
*ExchangeOnline/SafeAttachmentPolicy*

###### hidden-header

### Baseline - Default

|Name |Baseline - Default|
| :-- | :-- |
| What does this do? | Safe Attachments will scan messages for attachments with malicious content in Teams, Email, and Office Apps. |
| Why should you use this? | This settings routes all messages and attachments that do not have a virus/malware signature to a special environment. The process then uses machine learning and analysis techniques to detect malicious intent.|
| What is the end-user impact? |With this setting in place, there may be some latency in email flow while the attachment is being scanned before delivery. If the attachment is found to be malicious, the email will be blocked from sending.|
| Learn more | [Safe Attachments Policies](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/safe-attachments-about?view=o365-worldwide#safe-attachments-policy-settings) |

## Microsoft 365 > Security & Compliance > Threat Management > Policy > ATP Safe Attachments > Rules
*ExchangeOnline/SafeAttachmentRule*

###### hidden-header

### Default Safe Attachment

|Name |Default Safe Attachment|
| :-- | :-- |
| What does this do? | Safe Attachments will scan messages for attachments with malicious content in Teams, Email, and Office Apps. |
| Why should you use this? | This settings routes all messages and attachments that do not have a virus/malware signature to a special environment. The process then uses machine learning and analysis techniques to detect malicious intent.|
| What is the end-user impact? |With this setting in place, there may be some latency in email flow while the attachment is being scanned before delivery. If the attachment is found to be malicious, the email will be blocked from sending.|
| Learn more | [Safe Attachments Policies](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/safe-attachments-about?view=o365-worldwide#safe-attachments-policy-settings) |

## Microsoft 365 > Security & Compliance > Threat Management > Policy > ATP Safe Links
*ExchangeOnline/SafeLinksPolicy*

###### hidden-header

### Baseline - Default

|Name |Baseline - Default|
| :-- | :-- |
| What does this do? | Creates a default safe links policy that provides real-time click protection in Teams, Email, and Office Apps. |
| Why should you use this? | This settings helps prevent users from acccessing malicious links or potential phishing websites. |
| What is the end-user impact? | With this setting in place, there may be some latency in email flow while the URL is being scanned before delivery. When users click on a link and the link is found to be malicious, users will get a page describing the malicious link and will not be able to proceed to the webpage. |
| Learn more | [Safe Links Policies](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/safe-links-about?view=o365-worldwide) |

## Microsoft 365 > Security & Compliance > Threat Management > Policy > ATP Safe Links > Rules
*ExchangeOnline/SafeLinksRule*

###### hidden-header

### Default Safe Links

|Name |Default Safe Links|
| :-- | :-- |
| What does this do? | Creates a default safe links policy that provides real-time click protection in Teams, Email, and Office Apps. |
| Why should you use this? | This settings helps prevent users from acccessing malicious links or potential phishing websites. |
| What is the end-user impact? | With this setting in place, there may be some latency in email flow while the URL is being scanned before delivery. When users click on a link and the link is found to be malicious, users will get a page describing the malicious link and will not be able to proceed to the webpage. |
| Learn more | [Safe Links Policies](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/safe-links-about?view=o365-worldwide) |

## Microsoft 365 > Security & Compliance > Threat Management > Policy > Global Settings
*ExchangeOnline/AtpPolicyForO365*

###### hidden-header

### Configuration

|Name |Configuration|
| :-- | :-- |
| What does this do? | Defines Azure Active Directory authorization settings. The baseline allows users to sign up for email based subscriptions, use Self-Serve Password Reset, and join the tenant by email validation. Only adminstrators and guest inviters can invite external users to the organization. Users are allowed to read other users. |
| Why should you use this? | If you want to apply Azure Active Directory authorization settings. |
| What is the end-user impact? | Users are not allowed to read BitLocker keys for their owned device. |
| Learn more | [Authorization Policy](https://docs.microsoft.com/en-us/graph/api/resources/authorizationpolicy?view=graph-rest-1.0) |

## Microsoft 365 > Security & Compliance > Threat Management > Policy > Quarantine Policies
*ExchangeOnline/QuarantinePolicy*

###### hidden-header

### AdminOnlyAccessPolicy

|Name |AdminOnlyAccessPolicy|
| :-- | :-- |
| What does this do? | Microsoft's default quarantine policy. |
| Why should you use this? | Quarantine policies allow you to define the user experience for quarantined messages. |
| What is the end-user impact? | Defines when the user is notified for quarantined emails. |
| Learn more | [Quarantine policies](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/quarantine-policies?view=o365-worldwide) |



###### hidden-header

### DefaultFullAccessPolicy

|Name |DefaultFullAccessPolicy|
| :-- | :-- |
| What does this do? | Microsoft's default quarantine policy. |
| Why should you use this? | Quarantine policies allow you to define the user experience for quarantined messages. |
| What is the end-user impact? | Defines when the user is notified for quarantined emails. |
| Learn more | [Quarantine policies](https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/quarantine-policies?view=o365-worldwide) |

## Microsoft 365 > Teams > Apps > Permission Policies
*Teams/CsTeamsAppPermissionPolicy*

###### hidden-header

### Global

|Name |Global|
| :-- | :-- |
| What does this do? | Allows admins to specify approved Teams applications. Another setting (TenantWideAppsSettings) allows for Teams applications in general to be used. The baseline uses the default configurations provided by Microsoft. |
| Why should you use this? | If you want to be able to restrict users from using unapproved Teams apps. |
| What is the end-user impact? | Users may use only those Teams apps allowed by admins. |
| Learn more | [Manage app permission policies in Microsoft Teams](https://docs.microsoft.com/en-us/microsoftteams/teams-app-permission-policies) |

## Microsoft 365 > Teams > Meetings > Live Event Policies
*Teams/CsTeamsMeetingBroadcastPolicy*

###### hidden-header

### Global

|Name |Global|
| :-- | :-- |
| What does this do? | Ensures that the Global default Policies for Live Events is set so that only the Organizer can record the session. |
| Why should you use this? | Live events are recorded by default. Organizations should increase their privacy by changing the policy so that events are only recorded at the organizer’s discretion. |
| What is the end-user impact? | Only the meeting organizer will be able to record the live session. |
| Learn more | [Live Events Recording Policies](https://learn.microsoft.com/en-us/microsoftteams/teams-live-events/live-events-recording-policies) |

## Microsoft 365 > Teams > Meetings > Meeting Settings
*Teams/CsTeamsMeetingConfiguration*

###### hidden-header

### Global

|Name |Global|
| :-- | :-- |
| What does this do? | Configures Microsoft Teams meeting policies. The baseline prohibits anonymous users from joining Teams meetings.  |
| Why should you use this? | The Microsoft default allows all anonymous users to join Teams meetings. Disabling this feature can protect users from unwanted Teams meeting attendees. |
| What is the end-user impact? | Users without Teams accounts will not be allowed into Teams meetings. |
| Learn more | [Meeting Settings in Microsoft Teams](https://docs.microsoft.com/en-us/microsoftteams/meeting-settings-in-teams) |

## Microsoft 365 > Teams > Org-wide Settings > Teams Settings
*Teams/CsTeamsClientConfiguration*

###### hidden-header

### Global

|Name |Global|
| :-- | :-- |
| What does this do? | Defines global settings for Microsoft Teams. The baseline blocks third party file sharing applications (e.g. Box, DropBox, Google Drive). |
| Why should you use this? | To prevent users from sharing company content externally. |
| What is the end-user impact? | <span style='color: red'>High Impact.</span> Users will not be able to share content outside of the organization using Microsoft Teams. |
| Learn more | [Disable additional cloud storage (DropBox, Box and Google Drive)](https://techcommunity.microsoft.com/t5/microsoft-teams/disable-additional-cloud-storage-dropbox-box-and-google-drive/m-p/253335) |

## Microsoft 365 > Teams > Users > External Access
*Teams/CsTenantFederationConfiguration*

###### hidden-header

### Global

|Name |Global|
| :-- | :-- |
| What does this do? | Blocks external access in Teams to all external domains. Domains can be whitelisted in the Teams admin center.  |
| Why should you use this? | External access allows external users to look up internal users by their email address to initiate chats and calls entirely within Teams. Blocking external access prevents external users from using Teams as an avenue for reconnaissance or phishing. |
| What is the end-user impact? | This will vary depending on the organization and need for external collaboration. A formal process for adding external domains for collaboration should be established so that end users have a place to request new external participants. |
| Learn more | [Manage External Chat](https://learn.microsoft.com/en-us/microsoftteams/trusted-organizations-external-meetings-chat?tabs=organization-settings) |

## SharePoint Admin Center > Settings and Policies
*SharePoint/TenantProperties*

###### hidden-header

### Baseline - Configuration

|Name |Baseline - Configuration|
| :-- | :-- |
| What does this do? | File and Folder links default sharing settings are set to Specific People. External sharing is limited to only approved domains. Expiration timers for guest access to shared links is limited to 30 days. |
| Why should you use this? | Having the settings reduces the chances of data exflitration in your organization. |
| What is the end-user impact? | The end user impact is high if there is a lot of external collaboration going on with shared documents from SharePoint or OneDrive. Users will not be able to share with users outside the org unless their domain is whitelisted in the SharePoint Admin Center. Guest user links will expire by default in 30 days.  |
| Learn more | [Manage Sharing Settings](https://learn.microsoft.com/en-us/sharepoint/turn-external-sharing-on-or-off) |
