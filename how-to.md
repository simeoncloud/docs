## Getting access to Simeon

If you don't yet have a Simeon instance and you want to start a Simeon trial, please go to [Simeoncloud.com](https://www.simeoncloud.com/) to request a demo. If you decide to do a trial after the demo or if you purchased a subscription with us, you will be able to book an onboarding meeting with one of our engineers who will create your Simeon instance for you (no need to create an Azure DevOps organization yourself unless you want to provide your own). You will be given access to your Simeon instance during your onboarding meeting.

Please follow these instructions before your onboarding:
- Ensure a user with admin access is available to grant admin consent to the Simeon Cloud Web Admin service principal. This is necessary to sign into the Simeon app.
- Prepare an Azure AD tenant to be used to manage your **baseline**, or you can create a new, empty Azure AD tenant. Please follow the instructions here. We recommend purchasing at least a **Microsoft 365 F3** and **Azure Entra ID P2 licenses** (not trial licenses as trial licenses can result in errors with the software).
  - These licenses are needed if you want to deploy and test the Simeon Baseline configurations in your baseline tenant. Generally, Simeon will work with any license SKU.
- Come prepared with any **additional test/dev** or other tenants to install in association with the baseline tenant.

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
- [Set up Simeon for the new baseline tenant](#install-a-baseline)

## Set up billing for your organization

- This is required only if you exceed the [free tier of Azure DevOps](https://azure.microsoft.com/en-us/pricing/details/devops/azure-devops-services/). The free tier includes 5 users and 1800 minutes of runtime per month.
- Navigate to [Azure DevOps](https://dev.azure.com/)
- **Organization settings**
  - **Billing** > **Set up billing** > select either an existing subscription or **+ New Azure Subscription** > **Save**
  - Next to **MS Hosted CI/CD**, change the Paid parallel jobs from **0** to **1**

## Make sure a tenant meets the prerequisites to use Simeon

* Your tenant must be operating on global Azure or the [Government Community Cloud (GCC)](https://learn.microsoft.com/en-us/azure/azure-government/documentation-government-welcome)
  * Simeon does not support [GCC High and DoD](https://learn.microsoft.com/en-us/office365/servicedescriptions/office-365-platform-service-description/office-365-us-government/gcc-high-and-dod) environments
* Make sure the tenant has a valid Microsoft 365 license - all licensed SKUs are supported

You can verify the licenses in your tenant [in the Azure Portal](https://portal.azure.com/#blade/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/Licenses) under **All products**

## Tenant install options

* **Service Principal Authentication**: By default, Simeon creates a service principal in the tenant you are installing. This service principal is used to authenticate into the tenant and to Sync supported configurations. A user account is required in addition to the service principal.
  * Microsoft does not support Syncing all configurations with a service principal. Where possible, Simeon will use the service principal to Sync configurations.
  * When Syncing a configuration that is unsupported by the service principal, Simeon will use the user account selected at install time - delegated authentication or service account authentication.
  * The service principal increases security for supported configurations, as no user is involved.

* **Delegated Authentication**: With this option, Simeon will authenticate into the tenant with a user of your choosing (typically a pre-existing Global Administrator in the tenant or a user with the minimum [required permissions](https://simeoncloud.github.io/docs/#/permissions)). Simeon recommends using delegated authentication for all production tenants.
  * Simeon will create a refresh token for the user you authenticate with. This refresh token will cache the sign-in information for Simeon to use.
  * You can authenticate with a user subject to MFA, Conditional Access, and other security policies.
  * If the refresh token is invalidated, then you will need to log into the Simeon app and [reauthenticate](https://simeoncloud.github.io/docs/#/how-to?id=re-prompt-sync-to-complete-delegated-authentication) to create a new refresh token. The token can be invalidated for reasons including re-requiring MFA and token expiration policies.
  * Certain types of MFA enforcement cannot be used with delegated authentication, such as location-based enforcement (unless you are using a self-hosted agent where you control the device location).

* **Service Account Authentication**: This option creates an Azure AD user named simeon@tenantdomainname with the Global Administrator role to authenticate into the tenant. Simeon randomly generates a 128-character password and stores it along with the username in an encrypted pipeline variable.
  * You must exclude the service account from Conditional Access policies that restrict Simeon's access to the tenant.

## Install a baseline

*   First, create a baseline Azure tenant by following the steps [here](https://simeoncloud.github.io/docs/#/how-to?id=create-a-new-tenant-to-manage-your-baseline)
*   From the [Simeon portal](https://app.simeoncloud.com/), click **Install** on the navigation pane
*   For **Tenant**, enter the primary domain name of your baseline tenant (e.g. [simeonbaseline.onmicrosoft.com](http://simeonbaseline.onmicrosoft.com)) > **Baseline** should be **None/I am creating a baseline tenant** \> **Install**
*   If you would like to use the Simeon Baseline, toggle on **Use Simeon Baseline**. Otherwise, leave **Use Simeon Baseline** toggled off.
*   Click **Install** > (optional) select a subscription for Simeon to use for deploying resource groups > **Sync now**
    *   If you install using the Simeon Baseline, the Sync will pend approval to populate the baseline tenant portal. You can [approve these changes on the Sync page](https://simeoncloud.github.io/docs/#/how-to?id=approve).

## Install a client tenant onto Simeon

*   First, [ensure that the tenant meets the prerequisites to use Simeon](https://simeoncloud.github.io/docs/#/how-to?id=make-sure-a-tenant-meets-the-prerequisites-to-use-simeon)
* From the [Simeon portal](https://app.simeoncloud.com/), click **Install** on the navigation pane
* For **Tenant domain name**, enter the tenant's primary domain name (e.g. [simeoncloud.com](http://simeoncloud.com))
* **Baseline or repository URL** should be the baseline you wish to point this tenant to. If you are trying to create a baseline, leave the **Baseline or repository URL** empty
* Expand **Advanced Settings** > select the authentication method > **INSTALL** > authenticate with a global administrator in the tenant
* Once the installation has completed, click **Sync now**. Doing so will make a backup of your tenant and prepare the tenant for reconciliation

## Install a tenant with delegated authentication

* From the [Simeon portal](https://app.simeoncloud.com/), click **Install** on the navigation pane
* For **Tenant domain name**, enter the tenant's primary domain name (e.g. [simeoncloud.com](http://simeoncloud.com))
* **Baseline or repository URL** should be the baseline you wish to point this tenant to. If you are trying to create a baseline, leave the **Baseline or repository URL** empty
* Expand **Advanced Settings** > select **Use Delegated Authentication** > **INSTALL** > authenticate with a global administrator in the tenant
* Once the installation has completed, click **Sync now**. Doing so will kick off the delegated authentication process
* Navigate to [**Sync**](https://app.simeoncloud.com/sync) > click on **Pending authentication** next to your newly installed tenant > copy the code > click **login** > authenticate with the account you want to run Simeon with > paste the code > repeat 3x
    *   Please note you cannot authenticate with a guest user in the tenant.
* After the fourth authentication, and **In Progress** returns to **Idle**, the install and initial Sync are complete

## Install a tenant with service account

* From the [Simeon portal](https://app.simeoncloud.com/), click **Install** on the navigation pane
* For **Tenant domain name**, enter the tenant's primary domain name (e.g. [simeoncloud.com](http://simeoncloud.com))
* **Baseline or repository URL** should be the baseline you wish to point this tenant to. If you are trying to create a baseline, leave the **Baseline or repository URL** empty
* Expand **Advanced Settings** > select **Use Service Account** > **INSTALL** > authenticate with a global administrator in the tenant
* Once the installation has completed, click **Sync now**.

## Reinstall an existing tenant

* Navigate to [Simeon portal](https://app.simeoncloud.com/) > **Install** > toggle off **New Tenant** > select the tenant under **Display name**
  * If you are reinstalling a baseline, leave the **Baseline or repository URL** empty.
  * If you are reinstalling a baseline to change it to a downstream tenant, **Baseline or repository URL** should be the baseline you wish to point the tenant to.
  * If you are reinstalling a downstream tenant, **Baseline or repository URL** should be the baseline you wish to point the tenant to.
  * If you are reinstalling a downstream tenant to change it to a baseline, leave the **Baseline or repository URL** empty.
* Select the desired authentication method under **ADVANCED SETTINGS** > click **INSTALL** > follow the instructions on the screen.

## Rename a tenant

* Navigate to [Simeon portal](https://app.simeoncloud.com/) > **Install** > toggle off **New Tenant** > click **RENAME** > enter the new name for the tenant > click **RENAME**.

## Reconcile and deploy to a client tenant

*   From the Simeon portal, click **Reconcile** on the navigation pane
*   Choose the tenant you would like to reconcile. You may reconcile at any time to identify and resolve differences between the baseline and your tenant.
*   You can expand all and collapse all configurations using the buttons located at the top of the page next to the header. You may also expand individual configurations and their respective properties. Doing so will display more information on the given configuration.
*   Now, you may go through the four sections and decide on how to reconcile the different configurations with your baseline.
    *   **Tenant-Specific Configurations** contains those configurations that were exported from your tenant and do not overlap with the baseline. For each configuration in this section, you must decide whether you want to **keep the configuration** or **remove the configuration**. By keeping the box checked, you are choosing to keep the configuration. If you uncheck the box, you are choosing to remove the configuration from the tenant.
    *   **Available From Baseline** contains those configurations from your baseline that are not in your tenant. By keeping the box unchecked, you are choosing to **exclude the baseline configuration from the tenant**. If you check the box, you are choosing to **use the baseline configuration in the tenant**.
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

* :warning: **Warning**	:warning: this is a destructive operation that can result in deleting data (such as users) from your tenant(s). Please carefully review the pending changes on the Sync page before approving.
* Navigate to [the Simeon web application](https://app.simeoncloud.com/) > **Reconcile** > choose the tenant that you wish to revert by selecting it from the list.
* Expand **Advanced Settings** by clicking on the arrow to the left of the **Search** bar. Under **USING BASELINE**, select the same organization and tenant. In the new drop-down menu > select the date of the commit you want to revert to (e.g. 20230504.7).
* Review any differences between the current version of configurations (master) and previous versions of configurations (e.g. deploy-20230504.7), and restore any changes through the normal Reconcile process.
* Once you're satisfied with the changes, click **Preview** to verify changes and then click the **Reconcile** button to initiate a Sync.
<br />
<img src="https://raw.githubusercontent.com/simeoncloud/docs/master/assets/images/revert_to_point_in_time.gif" width="800"/>

## Add users to Simeon

* Navigate to [DevOps](https://dev.azure.com/)
  * **Organization settings** > **Users** > **Add users** > enter the email(s) of the user(s) you are inviting > **Add**
  * **Tenants** > **Project settings** > **Permissions** > **Tenants Team** > **Members** > **Add** > **Save**
  * (Optional) If you want to make the user a Project Administrator:
    * **Organization settings** > **Permissions** > **Project Collection Administrators** > **Members** > **Add**
* Once you have added the user(s), they will receive an email invitation from DevOps. This invitation must be accepted with a work or school account. Also, to avoid login issues, we recommend accepting the invitation with an incognito window.

## Remove a user from Simeon

* Navigate to [DevOps](https://dev.azure.com/)
  * **Organization settings** > **Users** > click on the three dots on the right side of the user > **Remove from organization**

## Change user access level
* Navigate to [DevOps](https://dev.azure.com/)
  * **Organization Settings** > **Users** > next to the user whose access level you want to change, click the “…” > **Manage user** > from the **Access level** dropdown, select **Basic** > **Save**

## Change which users receive the daily Summary Email

* From the [Simeon portal](https://app.simeoncloud.com/)
  * **User Icon** > **Settings** > select the setting **SummaryEmailToAddresses** > Enter the desired emails separated by a semicolon ';' (no spaces between the email addresses)

## Change user used for delegated authentication

* Navigate to [Simeon](https://app.simeoncloud.com/install) > toggle off **New Tenant** > select the tenant under **Display name** > **INSTALL** > follow the steps on the screen > **SYNC NOW** > when the status of the tenant Sync is **Pending Authentication**, authenticate with a different user. If you don't authenticate within 5 minutes after the status changes to **Pending Authentication**, the Sync will time out.

## Re-prompt Sync to complete delegated authentication

* Navigate to the [Sync screen](https://app.simeoncloud.com/sync) > next to the tenant, click **Sync** > **Sync** > when the status changes from **In Progress** to **Pending Authentication**, click **Pending Authentication** > complete the steps on the screen. If you don't authenticate within 5 minutes after the status changes to **Pending Authentication**, the Sync will time out.

## Add variables to configurations and Intune Apps

* On [DevOps](dev.azure.com), in the baseline tenant repository, define the variable in the config.tenant.json file (as shown in the video below).
    * **Tenants** > **Repos** > from the dropdown, select your baseline tenant > expand the **Source** folder > expand the **Resources** folder > **config.tenant.json** > **Edit**
    * Inside ResourceContext, add "VariableName": "PLACEHOLDER_VALUE" as shown below > **Commit** > **Commit**
        ```
        {
            "ResourceContext": {
                "M365Licenses": "[]",
                "VariableName": "PLACEHOLDER_VALUE"
            }
        }
        ```
    * Variable values must be a minimum of 7 characters.
    * If you define multiple variables, you must include trailing commas.

        <br />
        <video src="assets/videos/add_variables.mov" controls="controls" style="max-width: 1000px;"></video>
<br>


* Create the configuration or Intune app in the baseline tenant. Ensure the property that you want to variablize matches the property value as defined in the config.tenant.json file.
    * If you want to add a variable to an existing configuration or Intune app, contact support@simeoncloud.com.
* [Sync](https://app.simeoncloud.com/sync) your baseline
* In the downstream tenant repository config.tenant.json file, define the variable with the value you want to be replaced as shown below.
    ```
    {
        "ResourceContext": {
            "M365Licenses": "[]",
            "VariableName": "downstream tenant value"
        }
    }
    ```
* [Sync](https://app.simeoncloud.com/sync) the downstream tenant and **Approve** to deploy the configuration. The configuration should deploy to the tenant and replace the variable with the value as defined in the tenant's config.tenant.json file.

## Upload a custom ADMX file to Simeon

* Navigate to the [Intune Admin Center](https://endpoint.microsoft.com/#home), click on Devices > Configuration Policies
* On the Import ADMX tab, click Import > upload an ADMX file and its associated ADML file > Next > Create
* Wait for the state of the resource to become available.
<img src="https://raw.githubusercontent.com/simeoncloud/docs/master/assets/images/import_admx.png" width="800"/>

* Navigate to the Profiles tab on the top-left > Create Profile
    * Select Platform “Windows 10 and later”
    * Select Profile Type “Templates”
    * Select Template Name: “Imported Administrative templates (Preview)"
    * Give the configuration a name
    * In this example, since we are using the Mozilla and Firefox ADMX resources, we will be configuring the profile for the resource (this may not be required for all ADMX resources)
        * Under Configuration Settings, click Computer Configuration on the left tab then select Mozilla > Firefox > Cookies Select “Do not allow preferences to be changed" > on the right panel, select “Enabled" > OK
        * Finish the creation steps
* Run a Sync to export the newly added ADMX resource and profile to Simeon
* On [Azure DevOps](https://dev.azure.com/) > Tenants > Repos > navigate to Source/Resources/Content/MSGraph/DeviceManagement/GroupPolicyUploadedDefinitionFiles
* There will be 3 files per ADMX resource that was created. An ADML file, an ADMX file, and a JSON file
<img src="https://raw.githubusercontent.com/simeoncloud/docs/master/assets/images/admx_file.png" width="250"/>

* The exported ADMX and ADML files will have the following content: `TODO: Add adml file content here`
* Click **Edit** on each .admx and .adml file and update the contents with the ADMX and ADML files that were initially uploaded to the Intune portal > Save
* [Sync](https://app.simeoncloud.com/sync) the baseline tenant and **Approve** to deploy the configuration updates

## Remove a tenant from Simeon

* Navigate to [Simeon](https://app.simeoncloud.com/install) > toggle off **New Tenant** > select the tenant under **Display name** > **REMOVE** > follow the steps on the screen.
* If the tenant was installed using the Service Account, remove the Azure AD user (simeon@tenantdomain) from the tenant.
* If the tenant was used to host **Simeon Cloud Power BI Reporting**, you may uninstall Power BI Reporting by following [these instructions](https://simeoncloud.github.io/docs/#/reporting?id=uninstall-power-bi-reporting)
