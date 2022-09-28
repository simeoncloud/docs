## Create a new tenant to manage your baseline

- [Create a new, empty Azure AD from the Azure Admin Portal](https://portal.azure.com/#create/Microsoft.AzureActiveDirectory)
  - Consider using a name that identifies the tenant as your baseline (e.g. mycompanybaseline.onmicrosoft.com)
  - **Do not** create one using a personal account - otherwise it will create an Azure AD tenant called johndoegmail.onmicrosoft.com
  - Note that the user you create the new tenant as will be added to the tenant as an External User in the Global Administrator directory role
- **Create a new user** in the tenant and assign the user the Global Administrator role, then sign in as this new user for subsequent steps (this is required so that the licenses and subscriptions created in subsequent steps are linked to your new tenant)
- Get a **Microsoft 365** license
  - Purchase via the [Microsoft 365 Admin Portal](https://admin.microsoft.com/AdminPortal/Home#/catalog) or [Volume Licensing](https://www.microsoft.com/Licensing/servicecenter/default.aspx)
  - All licensed SKUs are supported
  - If you want access to all baseline configurations, we recommend **Microsoft 365 F3** and **Azure AD P2** (optional, if you want to use PIM and/or the secure score baseline)
  - You can verify the license has been added to your tenant [in the Azure Portal](https://portal.azure.com/#blade/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/Licenses) under **All products**
- [Set up Simeon for the new baseline tenant](#set-up-simeon-for-a-baseline-tenant)

## Set up billing for your organization

- Navigate to [Azure DevOps](https://dev.azure.com/)
- **Organization settings**
  - **Billing** > **Set up billing** > select either an existing subscription or **+ New Azure Subscription** > **Save**
  - Next to **MS Hosted CI/CD**, change the Paid parallel jobs from **0** to **1**

## Make sure a tenant meets the prerequisites to use Simeon

- You must be operating on global Azure cloud (not [Government Community Cloud](https://docs.microsoft.com/en-us/office365/servicedescriptions/office-365-platform-service-description/office-365-us-government/gcc)). The Azure Government cloud is not currently supported
- Make sure the tenant has a valid Microsoft 365 license - all licensed SKUs are supported

You can verify the licenses in your tenant [in the Azure Portal](https://portal.azure.com/#blade/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/Licenses) under **All products**

## Install a baseline

*   First, create a baseline Azure tenant by following the steps [here](https://simeoncloud.github.io/docs/#/how-to?id=create-a-new-tenant-to-manage-your-baseline)    
* From the [Simeon portal](https://app.simeoncloud.com/), click **Install** on the navigation pane    
*   For **Tenant**, enter the primary domain name of your baseline tenant (e.g. [simeonbaseline.onmicrosoft.com](http://simeonbaseline.onmicrosoft.com)) > **Baseline** should be **None/I am creating a baseline tenant** \> **Install**
*   If you would like to use the Simeon Baseline, toggle on **Use Simeon Baseline**. Otherwise, leave **Use Simeon Baseline** toggled off.
*   Click **Install** > (optional) select a subscription for Simeon to use for deploying resource groups > **Sync now**
    *   If you install using the Simeon Baseline, the Sync will pend approval to populate the baseline tenant portal. You can [approve these changes on the Sync page](https://simeoncloud.github.io/docs/#/how-to?id=approve).
    
## Install a client tenant onto Simeon

*   First, [ensure that the tenant meets the prerequisites to use Simeon](https://simeoncloud.github.io/docs/#/how-to?id=make-sure-a-tenant-meets-the-prerequisites-to-use-simeon)
* From the [Simeon portal](https://app.simeoncloud.com/), click **Install** on the navigation pane
* For **Tenant**, enter the tenant's primary domain name (e.g. [simeoncloud.com](http://simeoncloud.com)) > **Baseline** should be the baseline you wish to point this tenant to > authenticate with a global administrator in the tenant 
* Once the installation has completed, click **Sync now**. Doing so will make a backup of your tenant and prepare the tenant for reconciliation

## Install a tenant with delegated authentication

* From the [Simeon portal](https://app.simeoncloud.com/), click **Install** on the navigation pane
* For **Tenant**, enter the tenant's primary domain name (e.g. [simeoncloud.com](http://simeoncloud.com)) > **Baseline** should be the baseline you wish to point this tenant to 
* Expand **Advanced Settings** > toggle off **Use Simeon service account** > **Install** > authenticate with a global administrator in the tenant
* Once the installation has completed, click **Sync now**. Doing so will kick off the delegated authentication process
* Navigate to [**Sync**](https://app.simeoncloud.com/sync) > click on **Pending authentication** next to your newly installed tenant > copy the code > click **login** > authenticate with the account you want to run Simeon with > paste the code > repeat 3x
    *   Please note you cannot authenticate with a guest user in the tenant.
* After the fourth authentication, and **in progress** returns to **Idle**, the install and initial Sync are complete    

## Reconcile and deploy a client tenant

*   From the Simeon portal, click **Reconcile** on the navigation pane
*   Choose the tenant you would like to reconcile. You may reconcile at any time to identify and resolve differences between the baseline and your tenant.    
*   You can expand all and collapse all configurations using the buttons located at the top of the page next to the header. You may also expand individual configurations and their respective properties. Doing so will display more information on the given configuration.    
*   Now, you may go through the four sections and decide on how to reconcile the different configurations with your baseline.    
    *   **Tenant-Specific Configurations** contains those configurations that were exported from your tenant and do not overlap with the baseline. For each configuration in this section, you must decide whether you want to **keep the configuration** or **remove the configuration**. By keeping the box checked, you are choosing to keep the configuration. If you uncheck the box, you are choosing to remove the configuration from the tenant.        
    *   **Available From Baseline** contains those configurations from your baseline that are not in your tenant. By keeping the box checked, you are choosing to **exclude the baseline configuration from the tenant**. If you uncheck the box, you are choosing to **use the baseline configuration in the tenant**.        
    *   **Conflicting With Baseline** contains those configurations that are in both the tenant and the baseline, but where the configurations have different values. You can choose between **keeping the configuration you have** versus **reverting to the baseline configuration**. By keeping the box checked, you are choosing to keep your existing tenant configuration. If you uncheck the box, you are choosing to revert to the baseline configuration.        
    *   **Matching Baseline** contains those configurations that are in both your tenant and the baseline. By keeping the box checked, you are choosing to **keep the baseline configuration**. If you uncheck the box, you are choosing to **exclude the baseline configuration**.        
*   Once you have gone through each section and checked/unchecked boxes accordingly, click **Reconcile** at the bottom of the page. You will have two options from here:   
    *   (1) **I’M DONE** commits the changes to the tenant repository but does not deploy to the tenant. Note that if you do this, the tenant will be synced during the scheduled nightly sync and you will be prompted for approval as indicated in your daily summary email. To immediately deploy these changes to your tenant, you can manually sync the tenant in the Sync page.        
    *   (2) **SYNC NOW** immediately deploys the changes to the tenant.

## Generate Health Check Reports
* First, in the tenant you are generating the report for, obtain a user with either (1) Global Administrator role or (2) [the minimum required roles](https://simeoncloud.github.io/docs/#/permissions?id=permissions)
* If you are using a global administrator user, follow these instructions to [install your tenant](https://simeoncloud.github.io/docs/#/how-to?id=install-a-client-tenant-onto-simeon)
* If you are using a user with the minimum required roles, follow these instruction to [install your tenant using delegated authentication](https://simeoncloud.github.io/docs/#/how-to?id=install-a-tenant-with-delegated-authentication)
* Once the tenant is installed and the initial Sync is complete, navigate to [**Reconcile**](https://app.simeoncloud.com/reconcile) > select your tenant > click Export Report in the bottom left
  * To white label the report, upload a logo and enter in your company's information in the text box
  * To include more granular data, you have the option to include conficting property names and values
* Click **Export** and your report will be downloaded as a .xlsx

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

*   Navigate to [the Simeon web application](https://app.simeoncloud.com/) > Sync > check the box at the top left of the page
*   Click **Sync Selected**

## Approve

*   Navigate to [the Simeon web application](https://app.simeoncloud.com/) > Sync
*   Next to the tenant that you would like to approve, click **Pending Approval** > **Approve**
    * **Approve** will deploy the proposed changes to your tenant
    * **Reject** will reject the Sync. The next Sync will prompt you for approval
    * **Reject and Revert** will reject the Sync and revert the changes pending approval so you can Reconcile them at a later date   

## Approve all pending changes to your tenants

*   Navigate to [the Simeon web application](https://app.simeoncloud.com/) > Sync > check the box at the top left of the page
*   Click **Approve Selected**

## Revert your tenant to a point in time

* :warning: **Warning**	:warning: this is a destructive operation that can result in deleting data (such as users) from your tenant(s). Please carefully review the pending changes on the Sync page before approving 
* Navigate to https://dev.azure.com/ > **Tenants** > **Pipelines** > select the tenant that you want to revert > **Run pipeline** > **master** > **Tags** > enter the date of the commit you want to revert to (e.g. 20210112.1) > select the commit you want to revert by clicking the date > **Run** > several minutes later you will be required to approve the Sync to make the changes to your tenant 
<br />
<img src="https://raw.githubusercontent.com/simeoncloud/docs/master/assets/images/revert_to_point_in_time.gif" width="300" height="822.5" />

## Remove a tenant from Simeon

* Delete the Simeon service account from your tenant
  * http://portal.azure.com/ > log in to the tenant you are uninstalling > **Azure Active Directory** > **Users** > select the Simeon service account (named simeon@[tenantdomain]) > **Delete user**
* Remove the tenant from [DevOps](https://dev.azure.com/)
  * **Tenants** > **Repos** > select dropdown at the top of the page > **Manage repositories** > **...** (next to the tenant you want to remove) > **Delete** > follow the on-screen instructions to delete the repository
  * **Pipelines** > **...** (next to the tenant you want to remove) > follow the on-screen instructions to delete the pipeline
  * **Environments** (on the left pane under **Pipelines**) > select the tenant you want to remove > **...** > **Delete** > **Delete**

## Re-prompt Sync to complete delegated authentication

* Navigate to the [Sync](https://app.simeoncloud.com/sync) screen > next to the tenant, click **Sync** > **Sync** > when the status changes from *In Progress* to *Pending Authentication*, click **Pending Authentication** > complete the steps on the screen. If you don't authenticate within 5 minutes after the status changes to *Pending Authentication*, the Sync will time out.
