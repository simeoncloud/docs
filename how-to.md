## Make sure a tenant meets the prerequisites to use Simeon

- Make sure the tenant has a valid Microsoft 365 license - any one of the following license configurations are supported  
    - Microsoft 365 Business Premium
    - Microsoft 365 E3
    - Microsoft 365 E5
    - A combination of EMS and O365 E3 or E5 licenses

You can verify the licenses in your tenant [in the Azure Portal](https://portal.azure.com/#blade/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/Licenses) under **All products**

- Make sure the tenant has an Azure RM Subscription for Simeon to use (the Simeon baseline includes several configurations of minimal cost for logging and alerting purposes that require an Azure RM Subscription)

You can verify the subscriptions in your tenant [in the Azure Portal](https://portal.azure.com/#blade/Microsoft_Azure_Billing/SubscriptionsBlade)

## Set up Simeon for a tenant

Run the [Install-Simeon](Install-Simeon.ps1) script by runnng the following command:

`
powershell -ExecutionPolicy Bypass -Command "iex (irm https://raw.githubusercontent.com/simeoncloud/docs/master/Install-Simeon.ps1); Install-Simeon"
`

- You will be prompted for your DevOps org name (provided to you by Simeon support) and the tenant name (the primary domain name associated with the Microsoft tenant - e.g. contoso.com or contoso.onmicrosoft.com)
- You can equivalently use `pwsh` to run the script with PowerShell Core
- The script will create a service account to allow Simeon to interact with the tenant and configure your tenant Deploy and Export pipelines. The service account is created with a randomly generated, secure password that cannot be viewed by anyone and can only be used by your pipelines. 

## Create a new tenant to manage your baseline
 
- [Create a new, empty Azure AD from the Azure Admin Portal](https://portal.azure.com/#create/Microsoft.AzureActiveDirectory) 
  - Consider using a name that identifies the tenant as your baseline (e.g. mycompanybaseline.onmicrosoft.com)
  - **Do not** create one using a personal account - otherwise it will create an Azure AD tenant called johndoegmail.onmicrosoft.com
  - Note that the user you create the new tenant as will be added to the tenant as an External User in the Global Administrator directory role
- **Create a new user** in the tenant and assign the user the Global Administrator role, then sign in as this new user for subsequent steps (this is required so that the licenses and subscriptions created in subsequent steps are linked to your new tenant)
- Get an **Azure RM Subscription** - purchase via the [Azure Portal](https://portal.azure.com/#blade/Microsoft_Azure_Billing/SubscriptionsBlade) or an [Enterprise Agreement](https://ea.azure.com/manage/enrollment) (the Simeon baseline includes several configurations of minimal cost for logging and alerting purposes that require an Azure RM Subscription)
- Get a **Microsoft 365** license (a trial is fine, and will continue to work for Simeon even if it expires)
  - Purchase via the [Microsoft 365 Admin Portal](https://admin.microsoft.com/AdminPortal/Home#/catalog) or [Volume Licensing](https://www.microsoft.com/Licensing/servicecenter/default.aspx) 
  - Any one of the following license configurations are supported  
    - Microsoft 365 Business Premium
    - Microsoft 365 E3
    - Microsoft 365 E5
    - A combination of EMS and O365 E3 or E5 licenses
  - You can verify the licenses have been added to your tenant [in the Azure Portal](https://portal.azure.com/#blade/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/Licenses) under **All products**
- [Set up Simeon for the new baseline tenant](#set-up-simeon-for-a-tenant)
  
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

You can start your pipelines programmatically using [this script](Invoke-AzurePipeline.ps1). Replace the variables at the bottom of the script to suit your purposes.
