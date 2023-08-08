# Simeon Cloud Power BI Reporting

Report on your Simeon Sync data from a single location. Use one of our built-in reports or create your own from the raw data.

## Tenant updates
When installing Simeon Cloud Power BI Reporting, the installer will make the following changes to the tenant selected to host the Power BI report:
- Creates the Simeon Cloud **Power BI Workspace**
- Creates the **Azure Resource Group** named simeoncloudreporting
- Creates a **Log Analytics workspace** named SimeonCloud
    - Defaults to the Analytic logs Pay-As-You-Go tier, see [here for pricing information](https://azure.microsoft.com/en-us/pricing/details/monitor/)
- Creates a **Service Principal** named Simeon Cloud Reporting **with admin access** to the SimeonCloud Log Analytics workspace and Power BI Workspace
- **Generates a client secret** for Simeon Cloud Power BI Reporting and saves it as a secure variable in an Azure DevOps Variable Group shared only with your tenant pipelines
- Updates the Power BI tenant setting to **allow Service Principals access to the Power BI APIs**
- Updates the Power BI setting to provide the **logged in user access to create Power BI workspaces**
    - Power BI defaults restrict workspace creation to accounts with rights to create M365 Groups. If your tenant has this setting and the account running the installer is not allowed to create M365 Groups, the account will be added to the group of users allowed to create M365 groups

## Installation
The first step to install Simeon Power BI Reporting is to determine which tenant will host the report. If you're an MSP, we recommend installing into your MSP's own tenant. If you're an enterprise, we recommend installing into your production tenant. The tenant must have an Azure Subscription.

### Prerequisites
During installation, you will be prompted to log in with a user account. The account used must:
- Have a **Power BI Pro license**
- Have **logged in to [Power BI](https://app.powerbi.com)** at least once
- Have contributor access to the **Azure Subscription**
- Have either the **Global Administrator role** or **all the following Azure AD roles**:
    - Application Administrator
    - Groups Administrator
    - Power BI Administrator

### Running the installer
- From the [Simeon portal](https://app.simeoncloud.com/), click **Install** on the navigation pane > select the **Install Power BI Reporting** tab
- Enter the domain name of the tenant > **INSTALL**
- Authenticate with an account that meets the [prerequisites](#prerequisites)
<br />
<img src="https://raw.githubusercontent.com/simeoncloud/docs/feature/loganalytics/assets/images/power_bi_auth_to_tenant.png" width: auto; height: auto;/>
- When prompted, select the Azure Subscription
<br />
<img src="https://raw.githubusercontent.com/simeoncloud/docs/feature/loganalytics/assets/images/power_bi_subscription.png" width: auto; height: auto;/>
- When prompted, select an Azure location
<br />
<img src="https://raw.githubusercontent.com/simeoncloud/docs/feature/loganalytics/assets/images/power_bi_location.png" width: auto; height: auto;/>
- Once the installation is complete, click **Run Backfill Now**. This will backfill your Power BI report with the past 72 hours of Sync data.
<br />
<img src="https://raw.githubusercontent.com/simeoncloud/docs/feature/loganalytics/assets/images/power_bi_install_complete.png" width: auto; height: auto;/>

### Setup the Power BI Datasets
- Go to [Power BI](https://app.powerbi.com) > Workspaces > Simeon Cloud > click the three dots next to **Baseline Compliance Report** Dataset > Settings > **Take Over** > **Take Over**
- Change the Data source credentials to OAuth2. Go to Data source creditials > Edit credentials > Authentication Method to OAuth2 > Sign In
- Enter the credentials for the authenticating user
- Repeat these steps for the Summary of Deteced Changes Dataset
<br />
<img src="https://raw.githubusercontent.com/simeoncloud/docs/feature/loganalytics/assets/images/power_bi_dataset.gif" width: auto; height: auto;/>

### Grant access to the Power BI Workspace
The user account that runs the Power BI installer will be the administrator of the workspace. Other users will not be able to view the workspace until given access. To grant access:
- Go to [Power BI](https://app.powerbi.com) > **Workspaces** > Click the **three dots** next to **Simeon Cloud** > **Workspace access**
- Enter the group or email address > Select the **role** > **Add**

## Backfill Power BI Job
The backfill job uploads historical data to Power BI and keeps the data source schema and reports up to date.

The backfill can be initiated via Azure DevOps. To do so:
- Go to [Azure DevOps](https://dev.azure.com) > **Tenants** > **Pipelines**
- Find the pipeline **Backfill Power BI** > **Run pipeline**
- Select the desired parameters or keep defaults > **Run**

The pipeline parameters are as follows:
- **Update the Power BI Table schema to the latest schema** keeps the data source schema up to date
- **Delete all data in the Simeon Power BI dataset** - running a data backfill with this unselected will result in duplicate data being uploaded to the data source
- **Install or reinstall Simeon Power BI report(s)** updates all Simeon provided (not custom) reports to the latest version
- **Backfill only failed upload to Power BI steps** only backfills Syncs that have failed to upload to Power BI - allows you to run the backfill without duplicating data
- **Number of hours to include in backfill** uploads to Power BI all export/deploy Syncs in the specified number of hours
- **Number of parallel pipelines to backfill** - for most runs, should stay as the default defined in the backfill job

### Run with the parameters listed below if you need to do any of the following tasks:
#### Reinstall/update Simeon reports
- Check the option for **Backfill only failed upload to Power BI steps**
- Keep all other parameters as default

#### Backfill more than 72 hours worth of Syncs
- Update the number in **Number of hours to include in backfill**
- Keep all other parameters as default

#### Capture data from a Sync that failed to upload to Power BI
- Check the option for **Backfill only failed upload to Power BI steps**
- Ensure the failed step happened within 72 hours. If not, update **Number of hours to include in backfill** to a value that will capture the Sync
- Keep all other parameters as default

## Simeon Sync Power BI dataset
The dataset stores all export, preview, and deploy results. The latest Sync for a tenant will include unchanged configurations, and historical Syncs will only track configurations that are added, updated, or removed. This dataset uses Power BI's [direct connection](https://learn.microsoft.com/en-us/power-bi/connect-data/desktop-directquery-about#directquery-connections) to connect to the data and is refreshed every hour.

Each row in the data source represents a single property of a configuration.

The fields available in the dataset are as follows:
- Organization: The DevOps organization the tenant is in
- Tenant: The name of the tenant running the sync
- Action: The Sync stage, e.g., **export**, **preview**, **deploy**
- Sync Run Name: Specified by the user at Sync time, otherwise the automated name of the run given by Azure DevOps
- Sync Comment: Additional comments entered when running from the Sync page
- Sync Date Time: The date and time of the Sync in UTC time zone
- Configuration: The name of the configuration
- Configuration Full Name: The full name of the configuration, including the path where the configuration can be found
- Configuration Description: If the configuration is from the Simeon Baseline this provides a full description about the config
- Configuration Type: The configuration type used by Simeon to distinguish where a config should be deployed to
- Configuration Type Description: The translation of the Configuration Type
- Baseline Name: The name of the baseline the tenant is using. If the tenant does not have a baseline, the value is **[No Baseline]**
- Baseline Property Value: The baseline value of the property (if applicable) at the time of the Sync
- Configuration Reconciliation Type: The section that the configuration falls into on the Reconcile Screen - **only in tenant**, **available from baseline**, **conflicting with baseline**, **matching baseline**
- Property Reconciliation Type: Similar to the Configuration Reconcile Type, but at the property level
- Property Name: The name of the property being reported on
- Property Value: The value of the property at the time of the sync
- Old Property Value: Captures the previous value of the property before the Sync changes are applied
- Change Type: The action the Sync performed - **Removed**, **Added**, **Changed**, **Unchanged**, **Skipped**
- Error Message: If the configuration fails for any reason, the full error message is captured in this column

## Baseline and Compliance report
<br />
<img src="https://raw.githubusercontent.com/simeoncloud/docs/master/assets/images/power_bi.png" width: 700; height: auto;/>

*This screenshot shows the baseline compliance report for a demo environment.*

The Baseline Compliance Report displays how each of your tenants compare to their baseline. You can see the comparison **by tenant**, **type of configuration**, and **configuration**. You can also drill down to see how properties in a **specific configuration** compare to the baseline.

The data in the Baseline and Compliance report uses Power BI [import connections](https://learn.microsoft.com/en-us/power-bi/connect-data/desktop-directquery-about#import-connections) and is refreshed every 3 hours, which is the max number of automated refreshes allowed in Power BI Pro. You can refresh the report manually when viewing in Power BI. To do so:
- Go to [Power BI](https://app.powerbi.com) > **Workspaces** > **Simeon Cloud**
- Hover your mouse over the **Baseline Compliance Report** dataset > Click on the **refresh** icon

## Building custom reports
Simeon will pre-install reports, but users are encouraged to create their own reports with the data in the Simeon Sync Power BI dataset. To do so:
- Go to [Power BI](https://app.powerbi.com) > **Workspaces** > **Simeon Cloud**
- Select the **Simeon Sync** dataset
- At the top of the page, select **+ Create a report** > **Start from Scratch**

From here, you can build a Power BI report that meets your needs. Note, you must use the **Simeon Sync** dataset. Datasets attached to other reports will be deleted when those reports are updated.

## Removing Azure SQL
Prior to August 2023, Power BI read from Azure SQL. It is now recommended to remove Azure SQL in favor of Log Analytics for Simeon Cloud Power BI reports. To do so:
- Delete the resource group named **SimeonCloudReporting** from [portal.microsoft.com](https://portal.microsoft.com/) > Resource groups
    - Note, if Log Analytics has already been installed, delete the following resources from the resource group:
        - simeoncloudreporting-tenantname SQL Server
        - SimeonCloud SQL database
- Delete the App registration named **Simeon Cloud Power BI Reporting** from [portal.microsoft.com](https://portal.microsoft.com/) > App registrations
- In [Power BI](https://app.powerbi.com), remove the dataset and report named **Simeon Sync**
- Update the Library in Azure DevOps to remove all variables that start with **SQLAzure**. Go to [DevOps](https://dev.azure.com/) > Tenants > Pipelines > Library > Variable Groups > Sync > remove the following:
    - SQLAzureAppId
    - SQLAzureAppSecret
    - SQLAzureServerAdminPassword
    - SQLAzureServerAdminUserName
    - SQLAzureServerName
    - SQLAzureTenant
- You may now [reinstall Power BI Reporting](https://simeoncloud.github.io/docs/#/reporting?id=installation) to transition to the Log Analytics workspace

## Q & A
### Can I make changes to the reports deployed by Simeon?
Simeon continually enhances reports. Pushing these report updates to your tenant requires deleting the existing report and creating a new copy. So, any customizations you make to the report will be removed when the **Backfill Power BI job** is run with the option to **Reinstall/update Simeon reports** selected. If you accidentally lose changes to your reports, please contact support@simeoncloud.com.

### Can I use the dataset to build my own reports?
Yes! If you build a report you think others might benefit from, let us know. We are happy to spread the word!

### I don't have a Power BI Pro license; can I still see the workspace?
Accessing a shared Power BI workspace requires at least a Power BI Pro license assigned to the user accessing the workspace. If you are unsure that you want to signup, Power BI offers several trial options. Also, a Power BI Pro license is included in the **Office E5 license**.

# Daily Summary Email
Sends a daily digest of all changes made to your tenants in the past 24 hours, providing you an easy way to monitor your tenants.
