## Create a new tenant to manage your baseline

- [Create a new, empty Azure AD from the Azure Admin Portal](https://portal.azure.com/#create/Microsoft.AzureActiveDirectory)
  - Consider using a name that identifies the tenant as your baseline (e.g. mycompanybaseline.onmicrosoft.com)
  - **Do not** create one using a personal account - otherwise it will create an Azure AD tenant called johndoegmail.onmicrosoft.com
  - Note that the user you create the new tenant as will be added to the tenant as an External User in the Global Administrator directory role
- **Create a new user** in the tenant and assign the user the Global Administrator role, then sign in as this new user for subsequent steps (this is required so that the licenses and subscriptions created in subsequent steps are linked to your new tenant)
- Get an **Azure Subscription** - purchase via the [Azure Portal](https://portal.azure.com/#blade/Microsoft_Azure_Billing/SubscriptionsBlade) or an [Enterprise Agreement](https://ea.azure.com/manage/enrollment) (the Simeon baseline includes several configurations of minimal cost for logging and alerting purposes that require an Azure RM Subscription)
- Get a **Microsoft 365** license
  - Purchase via the [Microsoft 365 Admin Portal](https://admin.microsoft.com/AdminPortal/Home#/catalog) or [Volume Licensing](https://www.microsoft.com/Licensing/servicecenter/default.aspx)
  - Any one of the following license configurations are supported
    - Microsoft 365 Business Premium
    - Microsoft 365 E3
    - Microsoft 365 E5
    - A combination of EMS and O365 E3 or E5 licenses
  - You can verify the licenses have been added to your tenant [in the Azure Portal](https://portal.azure.com/#blade/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/Licenses) under **All products**
- [Set up Simeon for the new baseline tenant](#set-up-simeon-for-a-tenant)

## Make sure a tenant meets the prerequisites to use Simeon

- You must be operating on global Azure cloud (not [Government Community Cloud](https://docs.microsoft.com/en-us/office365/servicedescriptions/office-365-platform-service-description/office-365-us-government/gcc)). The Azure Government cloud is not currently supported
- Make sure the Microsoft Intune Enterprise Application is enabled for users to sign in
    - Navigate to the [Azure Portal](https://portal.azure.com/#home) > **Azure Active Directory** > **Enterprise applications** > switch **Application type** from **Enterprise Applications** to **All Applications** > **Apply** > search for **Microsoft Intune** > **Properties** > **Enabled for users to sign-in** > **Yes**
- Make sure the tenant has a valid Microsoft 365 license - any one of the following license configurations are supported
    - Microsoft 365 Business Premium
    - Microsoft 365 E3
    - Microsoft 365 E5
    - A combination of EMS and O365 E3 or E5 licenses

You can verify the licenses in your tenant [in the Azure Portal](https://portal.azure.com/#blade/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/Licenses) under **All products**

- Make sure the tenant has an Azure Subscription for Simeon to use (the Simeon baseline includes several configurations of minimal cost for logging and alerting purposes that require an Azure Subscription)

You can verify the subscriptions in your tenant [in the Azure Portal](https://portal.azure.com/#blade/Microsoft_Azure_Billing/SubscriptionsBlade)

## Set up Simeon for a baseline tenant

*   First, create a baseline Azure tenant by following the steps [here](https://simeoncloud.github.io/docs/#/how-to?id=create-a-new-tenant-to-manage-your-baseline)
*   From the [Simeon portal](https://app.simeoncloud.com), click **Install** on the navigation pane    
*   For **Tenant**, enter the primary domain name of your baseline tenant (e.g. [simeonbaseline.onmicrosoft.com](http://simeonbaseline.onmicrosoft.com)) > **Organization** should be **Simeon-\[YourCompanyName\]** > **Baseline** should be **None/I am creating a baseline tenant** \> **Install**
*   Once the installation has completed, click **Deploy**. Doing so will populate the baseline tenant portal

## Set up Simeon for a client tenant

*   First, [ensure that the tenant meets the prerequisites to use Simeon](https://simeoncloud.github.io/docs/#/how-to?id=make-sure-a-tenant-meets-the-prerequisites-to-use-simeon)
*   From the [Simeon portal](https://app.simeoncloud.com), click **Install** on the navigation pane
*   For **Tenant**, enter the tenant's primary domain name (e.g. [simeoncloud.com](http://simeoncloud.com)) > **Organization** should be **Simeon-\[YourCompanyName\]** > **Baseline** should be the baseline you wish to deploy to this tenant > **Install**
*   Once the installation has completed, click **Run an export**. Doing so will make a backup of your tenant and prepare the tenant for reconciliation

## Reconcile and deploy a client tenant

*   From the [Simeon portal](https://app.simeoncloud.com), click **Reconcile** on the navigation pane
*   Choose the tenant you would like to reconcile > for **Run**, select **\[date of reconciliation\] - Export for reconciliation**
    *   <span style='color: red'>Please note that you can reconcile a tenant only one time. If you would like to perform an additional reconciliation on the same tenant, please contact [support@simeoncloud.com](mailto:support@simeoncloud.com).</span>
*   You can expand all and collapse all configurations using the buttons located at the top of the page next to the header. You may also expand individual configurations and their respective properties. Doing so will display more information on the given configuration.
*   Now, you may go through the three sections and decide on how to reconcile the different configurations with your baseline.
    *   Note that you can expand individual configurations in any section by clicking the arrow to display more information, such as documentation on the configuration.
    *   **Exported from Tenant** contains those configurations that were exported from your tenant and do not overlap with the baseline. For each configuration in this section, you must decide whether you want to **keep the configuration** or **remove the configuration**. By keeping the box checked, you are choosing to keep the configuration. If you uncheck the box, you are choosing to remove the configuration from the tenant.
    *   **New from Baseline** contains those configurations from your baseline that are to be deployed to your tenant. By keeping the box checked, you are choosing to deploy the configuration to the tenant. If you uncheck the box, you are choosing to exclude the baseline configuration from the tenant.
    *   **Conflicting with Baseline** contains those configurations that are in both the tenant and the baseline, but where the configurations have different properties. You can choose between keeping the configuration you have versus reverting to the baseline configuration. By keeping the box checked, you are choosing to keep your existing tenant configuration. If you uncheck the box, you are choosing to revert to the baseline configuration.
*   Once you have gone through each section and checked/unchecked boxes accordingly, click **Reconcile** at the bottom of the page. You will have two options from here:
    *   (1) **I’M DONE** commits the changes to the tenant repository but does not deploy to the tenant. Note that if you do this, you must manually run the deploy pipeline before the scheduled nightly export and uncheck **Run an export operation before running the deployment**... Otherwise, your reconciliation choices will be overwritten (if this happens, please contact [support@simeoncloud.com](mailto:support@simeoncloud.com) and we can recover your reconciliation choices).
    *   (2) **RUN A DEPLOY** deploys the changes to the tenant.

## Update a baseline configuration and deploying to tenants

* Add the setting in the corresponding Azure portal - a list of the configuration types automated by Simeon can be found [here](managed-configurations.md)
* [Run the export pipeline for the **baseline** tenant](#run-an-export)
* [Run the deploy pipeline for your **client** tenants](#run-a-deployment)

## Update a tenant-specific configuration

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
