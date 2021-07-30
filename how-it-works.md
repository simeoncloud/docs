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

A full list of configuration types automated by Simeon using these APIs can be found [here](managed-configurations.md).

Azure Pipelines are used to run Simeon on demand or a schedule. 

Simeon supports a multi-step approval before a pipeline makes any changes to your tenant. Before approving, you can review and validate a Preview report with changes to be made. You then have the option to complete or cancel the deployment. Additionally, because configurations are stored in source control, inadvertent changes can be easily reverted. 
