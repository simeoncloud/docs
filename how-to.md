## Create a new tenant to manage your baseline

- [Create a new, empty Azure AD from the Azure Admin Portal](https://portal.azure.com/#create/Microsoft.AzureActiveDirectory)
  - Consider using a name that identifies the tenant as your baseline (e.g. mycompanybaseline.onmicrosoft.com)
  - **Do not** create one using a personal account - otherwise it will create an Azure AD tenant called johndoegmail.onmicrosoft.com
  - Note that the user you create the new tenant as will be added to the tenant as an External User in the Global Administrator directory role
- **Create a new user** in the tenant and assign the user the Global Administrator role, then sign in as this new user for subsequent steps (this is required so that the licenses and subscriptions created in subsequent steps are linked to your new tenant)
- (Optional) Get an **Azure Subscription** - purchase via the [Azure Portal](https://portal.azure.com/#blade/Microsoft_Azure_Billing/SubscriptionsBlade) or an [Enterprise Agreement](https://ea.azure.com/manage/enrollment)
  - Note that an Azure Subscription is required to use the baseline configurations for logging and alerting. The cost of the subscription ranges between $5 and $10 USD per month. 
- Get a **Microsoft 365** license
  - Purchase via the [Microsoft 365 Admin Portal](https://admin.microsoft.com/AdminPortal/Home#/catalog) or [Volume Licensing](https://www.microsoft.com/Licensing/servicecenter/default.aspx)
  - All licensed SKUs are supported
  - If you want access to all baseline configurations, we recommend **Microsoft 365 F3** and **Azure AD P2** (optional, if you want to use PIM and/or the secure score baseline)
  - You can verify the license has been added to your tenant [in the Azure Portal](https://portal.azure.com/#blade/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/Licenses) under **All products**
- [Set up Simeon for the new baseline tenant](#set-up-simeon-for-a-baseline-tenant)

## Make sure a tenant meets the prerequisites to use Simeon

- You must be operating on global Azure cloud (not [Government Community Cloud](https://docs.microsoft.com/en-us/office365/servicedescriptions/office-365-platform-service-description/office-365-us-government/gcc)). The Azure Government cloud is not currently supported
- Make sure the tenant has a valid Microsoft 365 license - all licensed SKUs are supported

You can verify the licenses in your tenant [in the Azure Portal](https://portal.azure.com/#blade/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/Licenses) under **All products**

- If you want to use the baseline configurations for logging and alerting, make sure the tenant has an Azure Subscription for Simeon to use

You can verify the subscriptions in your tenant [in the Azure Portal](https://portal.azure.com/#blade/Microsoft_Azure_Billing/SubscriptionsBlade)

## Set up Simeon for a baseline tenant

*   First, create a baseline Azure tenant by following the steps [here](https://simeoncloud.github.io/docs/#/how-to?id=create-a-new-tenant-to-manage-your-baseline)
*   From the [Simeon portal](https://app.simeoncloud.com), click **Install** on the navigation pane    
*   For **Tenant**, enter the primary domain name of your baseline tenant (e.g. [simeonbaseline.onmicrosoft.com](http://simeonbaseline.onmicrosoft.com)) > **Organization** should be **Simeon-\[YourCompanyName\]** > **Baseline** should be **None/I am creating a baseline tenant** \> **Install**
*   Once the installation has completed, click **Deploy**. Doing so will populate the baseline tenant portal

## Set up Simeon for a client tenant

*   First, [ensure that the tenant meets the prerequisites to use Simeon](https://simeoncloud.github.io/docs/#/how-to?id=make-sure-a-tenant-meets-the-prerequisites-to-use-simeon)
*   From the [Simeon portal](https://app.simeoncloud.com), click **Install** on the navigation pane
*   For **Tenant**, enter the tenant's primary domain name (e.g. [simeoncloud.com](http://simeoncloud.com)) > **Baseline** should be the baseline you wish to deploy to this tenant > **Install**
*   Once the installation has completed, click **Sync now**. Doing so will make a backup of your tenant and prepare the tenant for reconciliation

## Install a baseline

*   First, create a baseline Azure tenant by following the steps [here](https://simeoncloud.github.io/docs/#/how-to?id=create-a-new-tenant-to-manage-your-baseline)
    
* From the [Simeon portal](https://app.simeoncloud.com/), click **Install** on the navigation pane
    
*   For **Tenant**, enter the primary domain name of your baseline tenant (e.g. [simeonbaseline.onmicrosoft.com](http://simeonbaseline.onmicrosoft.com)) > **Baseline** should be **None/I am creating a baseline tenant** \> **Install**
    
*   Once the installation has completed, click **Deploy**. Doing so will populate the baseline tenant portal
    

## Install a client tenant onto Simeon

*   First, [ensure that the tenant meets the prerequisites to use Simeon](https://simeoncloud.github.io/docs/#/how-to?id=make-sure-a-tenant-meets-the-prerequisites-to-use-simeon)
    
* From the [Simeon portal](https://app.simeoncloud.com/), click **Install** on the navigation pane
    
* For **Tenant**, enter the tenant's primary domain name (e.g. [simeoncloud.com](http://simeoncloud.com)) > **Baseline** should be the baseline you wish to deploy to this tenant > **Install**
    
* Once the installation has completed, click **Sync now**. Doing so will make a backup of your tenant and prepare the tenant for reconciliation

## Install a tenant with delegated authentication

* From the [Simeon portal](https://app.simeoncloud.com/), click **Install** on the navigation pane

* For **Tenant**, enter the tenant's primary domain name (e.g. [simeoncloud.com](http://simeoncloud.com)) > **Baseline** should be the baseline you wish to point this tenant to 

* Expand **Advanced Settings** > toggle off **Use Simeon service account** > **Install**

* Once the installation has completed, click **Sync now**. Doing so will kick off the delegated authentication process

* Navigate to [**Sync**](https://app.simeoncloud.com/sync) > click on **Pending authentication** next to your newly installed tenant > copy the code > click **login** > authenticate with the account you want to run Simeon with > paste the code > repeat 4x

* After the fourth authentication, and **in progress** returns to **Idle**, the install and initial Sync are complete 
    

## Reconcile and deploy a client tenant

*   From the Simeon portal, click **Reconcile** on the navigation pane
    
*   Choose the tenant you would like to reconcile. You may reconcile at any time to identify and resolve differences between the baseline and your tenant.
    
*   You can expand all and collapse all configurations using the buttons located at the top of the page next to the header. You may also expand individual configurations and their respective properties. Doing so will display more information on the given configuration.
    
*   Now, you may go through the four sections and decide on how to reconcile the different configurations with your baseline.
    
    *   **Exported from Tenant** contains those configurations that were exported from your tenant and do not overlap with the baseline. For each configuration in this section, you must decide whether you want to **keep the configuration** or **remove the configuration**. By keeping the box checked, you are choosing to keep the configuration. If you uncheck the box, you are choosing to remove the configuration from the tenant.
        
    *   **Missing from Baseline** contains those configurations from your baseline that are not in your tenant. By keeping the box checked, you are choosing to **exclude the baseline configuration from the tenant**. If you uncheck the box, you are choosing to **use the baseline configuration in the tenant**.
        
    *   **Conflicting with Baseline** contains those configurations that are in both the tenant and the baseline, but where the configurations have different values. You can choose between **keeping the configuration you have** versus **reverting to the baseline configuration**. By keeping the box checked, you are choosing to keep your existing tenant configuration. If you uncheck the box, you are choosing to revert to the baseline configuration.
        
    *   **Matching Baseline** contains those configurations that are in both your tenant and the baseline. By keeping the box checked, you are choosing to **keep the baseline configuration**. If you uncheck the box, you are choosing to **exclude the baseline configuration**.
        
*   Once you have gone through each section and checked/unchecked boxes accordingly, click **Reconcile** at the bottom of the page. You will have two options from here:
    
    *   (1) **I’M DONE** commits the changes to the tenant repository but does not deploy to the tenant. Note that if you do this, the tenant will be synced during the scheduled nightly sync and you will be prompted for approval as indicated in your daily summary email. To immediately deploy these changes to your tenant, you can manually sync the tenant in the Sync page.
        
    *   (2) **SYNC NOW** immediately deploys the changes to the tenant.
        

## Update a baseline configuration and sync to tenants

*   Add the setting in the baseline Azure portal - a list of the configuration types automated by Simeon can be found [here](https://simeoncloud.github.io/docs/#/managed-configurations)
    
*   From the Simeon Portal, click **Sync** on the navigation pane
    
*   Select your baseline and the tenants you want to sync by clicking the corresponding checkbox, or select all by clicking the checkbox > **Sync Selected**
    
*   Please note that you may alternatively wait until the nightly scheduled Sync and you will be prompted to approve changes during this process.
    

## Update a tenant-specific configuration and sync

*   Add the setting in the tenant Azure portal - a list of the configuration types automated by Simeon can be found [here](https://simeoncloud.github.io/docs/#/managed-configurations)
    
*   From the Simeon Portal, click **Sync** on the navigation pane
    
*   Select the tenant you added the configuration to > **Sync Now**
    

## Sync all of your tenants

*   Select your baseline and all tenants by checking the box at the top left of the page (next to **Org**)
    
*   Click **Sync Selected**
    

## Approve all pending changes to your tenants

*   Select your baseline and all tenants by checking the box at the top left of the page (next to **Org**)
    
*   Click **Approve Selected**

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

## Remove a tenant from Simeon

* Delete the Simeon service account from your tenant
  * http://portal.azure.com/ > log in to the tenant you are uninstalling > **Azure Active Directory** > **Users** > select the Simeon service account (named simeon@[tenantdomain]) > **Delete user**
* Remove the tenant from [DevOps](https://dev.azure.com/)
  * **Tenants** > **Repos** > select dropdown at the top of the page > **Manage repositories** > **...** (next to the tenant you want to remove) > **Delete** > follow the on-screen instructions to delete the repository
  * **Pipelines** > **...** (next to the tenant you want to remove) > follow the on-screen instructions to delete the pipeline
  * **Environments** (on the left pane under **Pipelines**) > select the tenant you want to remove > **...** > **Delete** > **Delete**
