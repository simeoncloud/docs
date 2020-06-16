# Integration Overview

Simeon interacts with Microsoft APIs in order to read and deploy configurations for your tenant. These APIs include
- Microsoft Graph
- Azure AD Graph
- Azure AD Portal
- Azure RM Management
- Exchange Online PowerShell
- Skype for Business Online PowerShell
- Office 365 Security and Compliance Center PowerShell
- Microsoft Teams

When Simeon runs, it enables these APIs in your tenant if they are not already. 

A full list of configuration types automated by Simeon using these APIs can be found [here](automated-configuration-types.md).

Simeon uses a dedicated service account to interact with these APIs. This service account needs to be a global administrator in Azure AD and have contributor permissions on an Azure RM subscription in order to read and deploy configurations for your tenant. In order for Simeon to authenticate using this service account, it must be exempt from any multi-factor authentication policies. 

Azure Pipelines are used to run Simeon on demand or a schedule. 

Credentials for the service account are encrypted and stored securely in these pipelines. These credentials are never viewed by Simeon and Simeon support will not run any deployment pipeline unless requested (such as when using the Simeon Outsource product offering). 

Simeon supports a multi-step approval before a pipeline makes any changes to your tenant. Before approving, you can review and validate a Preview report with changes to be made. Additionally, because configurations are stored in source control, inadvertent changes can be easily reverted. 
