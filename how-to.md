## Set up a tenant for use with Simeon

- Launch PowerShell Core or PowerShell command prompt by running ```pwsh -ExecutionPolicy Bypass``` or ```powershell -ExecutionPolicy Bypass``` respectively (note that ```-ExecutionPolicy Bypass``` is required to allow PowerShell to run scripts)

* Run the [Install-Simeon](Install-Simeon.ps1) script by runnng the following command from the prompt you launched above
```
iex (irm https://raw.githubusercontent.com/simeoncloud/docs/master/Install-Simeon.ps1); Install-Simeon"
```

## Create a tenant to manage your baseline
 
- [Create a new, empty Azure AD from the Azure Admin Portal](https://portal.azure.com/#create/Microsoft.AzureActiveDirectory) 
  - **Do not** create one using a personal account - otherwise it will create an AAD tenant called johndoegmail.onmicrosoft.com
  - Note that the user you create the new tenant as will be added to the tenant as an External User in the Global Administrator directory role
  - Optionally, create and verify a new custom domain name, then make this the primary domain for Azure AD (Azure Portal > Azure AD > Custom domain names)
- **Create a new user** in the tenant and assign the user the Global Administrator role, then sign in as this new user (this is required so that the licenses and subscriptions created in subsequent steps are  linked to the correct tenant).
- Get an **Azure Subscription** - purchase via the [Azure Portal](https://portal.azure.com/#blade/Microsoft_Azure_Billing/SubscriptionsBlade) or an [Enterprise Agreement](https://ea.azure.com/manage/enrollment) (the Simeon baseline includes a minimal number of configurations for logging and alerting purposes that require an Azure Subscription).
- Get a **Microsoft 365** license (a trial will work for managing the  tenant, even if it expires)
  - Purchase via the [Microsoft 365 Admin Portal](https://admin.microsoft.com/AdminPortal/Home#/catalog) or [Volume Licensing](https://www.microsoft.com/Licensing/servicecenter/default.aspx) 
  - You must have one of the follow licenses in your tenant  
    - Microsoft 365 Business Premium
    - Microsoft 365 E3
    - Microsoft 365 E5
    - A combination of EMS and O365 E3 or E5 licenses
  
  
## Update a baseline configuration and deploying to tenants

* Add the setting in the corresponding Azure portal - a list of the configuration types automated by Simeon can be found [here](managed-configurations.md)
* [Run the export pipeline for the **baseline** tenant](#run-an-export)
* [Run the deploy pipeline for your **client** tenants](#run-a-deployment)

## Update a tenant specific configuration

* Add the setting in the corresponding Azure portal - a list of the configuration types automated by Simeon can be found [here](managed-configurations.md)
* [Run the export pipeline for the **client** tenant](#run-an-export)

## Run a Deployment

* Click on **Pipelines** > **\[tenant name\]** **-** **Deploy** > **Run pipeline** > **Run**
  * Note - you can see a history of the runs for a given pipeline or of all the runs across all pipelines by selecting the **Runs** tab
* Deploy has two stages: Preview and Deploy
  * Preview will generate a list of changes that will be made to the tenant if deployed
    * To see the result of the Preview stage, click **Extensions** and scroll to the section labeled **Preview** 
    * If you have [approval required](#require-approval) for the deployment, [approve](#approve) to continue
  * Deploy applies these changes to the tenant
    * To see the result of the Deploy stage, click **Extensions** and scroll to the section labeled **Deploy** 

## Run an Export

* Click on **Pipelines** > **\[tenant name\]** **-** **Export** > **Run pipeline** > **Run**
* Export has two stages: Export and Merge Changes
  * Export will generate a list of changes to be made to the tenant repository
    * To see the result of the Export stage, click **Extensions** and scroll to the section labeled **Export** 
    * If you have [approval required](#require-approval) for the deployment, [approve](#approve) to continue
  * Merge Changes applies these changes to the tenant repository
    * To see the changes in the tenant repository, navigate to **Repos** > **repositories dropdown at the top** > **\[tenant name\]**
      * By clicking **History** you can see a history of all past changes

## Schedule Deployment/Export

* Note - approval should be turned off when using scheduling, otherwise a user must be present to approve
* To utilize scheduling, navigate to **Pipelines** > **\[tenant name\]** - **Deploy** or **Export** > **Edit** > **...** \(top right\) > **Triggers** > **Add** \(next to **Scheduled**\) > schedule the run accordingly

## Require Approval

* Navigate to [Azure DevOps](http://dev.azure.com) and click on your project \(named after your company\)
* On the left-hand side, click on **Pipelines** > **Environments**
  * To require approval before deploying changes, click **Deploy**
  * To require approval before committing exported changes, click **Export**
* In the upper-right corner, click **...** > **Approvals and checks** > **+** > **Next**
* Under **Approvers**, add the group or user that you want to require approval from
  * To add a user as an approver, type and then click the user's email address
  * To add an approval that allows any member of your organization to approve the operation, type and then click **Project Valid Users**
  * Under **Advanced**, you can choose whether to allow approvers to approve their own runs by selecting the box. This will be enabled by default
  * Under **Control options**, you can specify the amount of time before the deploy or export times out if not approved - this will be set to 30 days by default
* Click **Create**

## Approve

* Navigate to **Pipelines** > **\[tenant name\]** **-** **Deploy** > **\#\[date\].\[run number\]** \(e.g. \#20200528.1\) 
* Click the **Extensions** tab and review the changes to be approved - for Deploy operations this will be under the **Preview** section and for Export operations this will be under the **Export** section
* Navigate to the summary tab and click **Review** > **Approve**

## Remove Approval

* Approvals can easily be removed by navigating to the environment you want to remove an approval from \(Deploy or Export\)
* Once you have selected either the **Deploy** or **Export** environment, click **...** > **Approvals and checks** > hover mouse over the approval you want to delete > **trash icon** > **Delete**

## Run Pipelines Programmatically

You can start your pipelines programmatically using the following script. Replace the variables at the bottom of the script to suit your purposes.

```
function Invoke-AzurePipeline
{
    param (
        [string]
        # The organization name that appears in DevOps - e.g. simeon-orgName
        $Organization = (Read-Host "Enter the organization name that appears in DevOps, example: simeon-orgName"),
        [string]
        # The project name that in DevOps - usually 'Default'
        $Project = 'Default',
        [string]
        # Baseline or the client name
        $Tenant = (Read-Host "Enter 'baseline' or the client name"),
        [string]
        [ValidateSet("Export", "Deploy")]
        # The desired action - Export or Deploy
        $Action = (Read-Host "Enter desired action: Export or Deploy"), 
        [string]
        # Azure DevOps Personal Access token with rights to trigger builds - for details see: https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops&tabs=preview-page
        $PersonalAccessToken = (Read-Host "Enter your Azure Devops Personal Access Token" -AsSecureString |% { [System.Net.NetworkCredential]::new('',$_).Password }),
        [string]
        # The Azure Active Directory user name to be used during export/deployment
        $TenantAadUserName = (Read-Host "Enter the Simeon service account Azure Active Directory user name"),   
        [string]
        # The Azure Active Directory password to be used during export/deployment
        $TenantAadPassword = (Read-Host "Enter the Simeon service account Azure Active Directory password" -AsSecureString |% { [System.Net.NetworkCredential]::new('',$_).Password })
    )
    <#
    .SYNOPSIS
    Initiates the desired action (export/deploy) against the provided Azure AD tenant
    #>

    $ErrorActionPreference = 'Stop'

    $devOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PersonalAccessToken)")) }

    # Get Build Definition
    $pipelineName = "$Tenant - $Action"

    Write-Host "Getting pipeline definition for pipeline: $pipelineName"

    $pipelines = (Invoke-RestMethod -Uri "https://dev.azure.com/$Organization/$Project/_apis/build/definitions?api-version=5.0" -Method Get -Headers $devOpsAuthenicationHeader -ContentType "application/json").Value
    
    $pipelineDefintion = $pipelines |? name -eq $pipelineName
    
    if (!$pipelineDefintion) {
        throw "Counld not find pipeline for $pipelineName. Verify that the provided client name and that the pipeline has been created."
    }

    # Trigger build
    $body = @{
        definition = @{
            id = $pipelineDefintionId.id;
        };
        sourceBranch = "refs/heads/master";
        parameters = (@{ "AadAuth:UserName" = $TenantAadUserName; "AadAuth:Password" = $TenantAadPassword } | ConvertTo-Json)
    } | ConvertTo-Json -Depth 5
    
    $result = Invoke-RestMethod -Uri "https://dev.azure.com/$Organization/$Project/_apis/build/builds?api-version=5.0" `
        -Method Post -Headers $devOpsAuthenicationHeader -Body $body -ContentType "application/json"

    Write-Host "Started pipeline - for details see: https://dev.azure.com/$Organization/$Project/_build/results?buildId=$($result.id)&view=results"
}

$pipelineArgs = @{
    Organization = '<Your DevOps organization name>'
    Action = 'Deploy'
    PersonalAccessToken = '***'
}

$pipelinesToRun = @(
    @{
        Tenant = 'baseline'
        TenantAadUsername = 'simeon@mybaseline.onmicrosoft.com'
        TenantAadPassword = '***'
    }
    @{
        Tenant = 'client'
        TenantAadUsername = 'simeon@client.org'
        TenantAadPassword = '***' 
    }
)

$pipelinesToRun |% { Invoke-AzurePipeline @pipelineArgs @_ }
```
