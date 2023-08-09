# Simeon Cloud Power BI Reporting

Report on your Simeon Sync data from a single location. Use one of our built-in reports or create your own from the raw data.

## Tenant updates
When installing Simeon Cloud Power BI Reporting, the installer will make the following changes to the tenant selected to host the Power BI report:
- Creates the Simeon Cloud **Power BI Workspace**
- Creates the **Azure Resource Group** named simeoncloudreporting
- Creates a **Log Analytics workspace** named SimeonCloud
    - Defaults to the Analytic logs Pay-As-You-Go tier, see [here for pricing information](https://azure.microsoft.com/en-us/pricing/details/monitor/)
- Creates a **Log Analytics data collection endpoint**
- Creates a **Log Analytics data collection rule**
- Creates a **Service Principal** named Simeon Cloud Reporting with the role **Monitoring Metrics Publisher** on the SimeonCloud Log Analytics workspace and **admin accesss** to the Power BI Workspace
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
<img src="https://raw.githubusercontent.com/simeoncloud/docs/master/assets/images/power_bi_auth_to_tenant.png" width: 338; height: auto;/>
- When prompted, select the Azure Subscription
<br />
<img src="https://raw.githubusercontent.com/simeoncloud/docs/master/assets/images/power_bi_subscription.png" width: 337; height: auto;/>
- When prompted, select an Azure location
<br />
<img src="https://raw.githubusercontent.com/simeoncloud/docs/master/assets/images/power_bi_location.png" width: 337; height: auto;/>
- Once the installation is complete, click **Run Backfill Now**. This will backfill your Power BI report with the past 72 hours of Sync data.
<br />
<img src="https://raw.githubusercontent.com/simeoncloud/docs/master/assets/images/power_bi_install_complete.png" width: auto; height: auto;/>

### Setup the Power BI Datasets
- Go to [Power BI](https://app.powerbi.com) > Workspaces > Simeon Cloud > click the three dots next to **Baseline Compliance Report** Dataset > Settings > **Take Over** > **Take Over**
- Change the Data source credentials to OAuth2. Go to Data source creditials > Edit credentials > Authentication Method to OAuth2 > Sign In
- Enter the credentials for the authenticating user
- Repeat these steps for the Summary of Deteced Changes Dataset
<br />
<img src="https://raw.githubusercontent.com/simeoncloud/docs/master/assets/images/power_bi_dataset.gif" width: 700; height: auto;/>

### Grant access to the Power BI Workspace
The user account that runs the Power BI installer will be the administrator of the workspace. Other users will not be able to view the workspace until given access. To grant access:
- Go to [Power BI](https://app.powerbi.com) > **Workspaces** > Click the **three dots** next to **Simeon Cloud** > **Workspace access**
- Enter the group or email address > Select the **role** > **Add**

## Backfill Sync Integrations
The backfill job uploads historical data to Power BI and keeps the reports up to date.

## Simeon Sync Power BI dataset
Each row in the data source represents a single property of a configuration.

The fields available in the dataset are as follows:
- Organization: The DevOps organization the tenant is in
- Tenant: The name of the tenant running the sync
- Action: The Sync stage, e.g., **export**, **preview**, **deploy**
- Sync_Run_Name: Specified by the user at Sync time, otherwise the automated name of the run given by Azure DevOps
- Sync_Comment: Additional comments entered when running from the Sync page
- Sync_Date_Time: The date and time of the Sync in UTC time zone
- Configuration: The name of the configuration
- Configuration_Full_Name: The full name of the configuration, including the path where the configuration can be found
- Configuration_Description: If the configuration is from the Simeon Baseline this provides a full description about the config
- Configuration_Type: The configuration type used by Simeon to distinguish where a config should be deployed to
- Configuration_Type_Description: The translation of the Configuration Type
- Baseline_Name: The name of the baseline the tenant is using. If the tenant does not have a baseline, the value is **[No Baseline]**
- Baseline_Property_Value: The baseline value of the property (if applicable) at the time of the Sync
- Configuration_Reconciliation_Type: The section that the configuration falls into on the Reconcile Screen - **only in tenant**, **available from baseline**, **conflicting with baseline**, **matching baseline**
- Property_Reconciliation_Type: Similar to the Configuration Reconcile Type, but at the property level
- Property_Name: The name of the property being reported on
- Property_Value: The value of the property at the time of the sync
- Old_Property_Value: Captures the previous value of the property before the Sync changes are applied
- Change_Type: The action the Sync performed - **Removed**, **Added**, **Changed**, **Unchanged**, **Skipped**
- Error_Message: If the configuration fails for any reason, the full error message is captured in this column

## Baseline and Compliance report
<br />
<img src="https://raw.githubusercontent.com/simeoncloud/docs/master/assets/images/power_bi.png" width: 700; height: auto;/>

*This screenshot shows the baseline compliance report for a demo environment.*

The Baseline Compliance Report displays how each of your tenants compare to their baseline. You can see the comparison **by tenant**, **type of configuration**, and **configuration**. You can also drill down to see how properties in a **specific configuration** compare to the baseline.

The data in the Baseline and Compliance report uses Power BI [import connections](https://learn.microsoft.com/en-us/power-bi/connect-data/desktop-directquery-about#import-connections) and is refreshed every 3 hours, which is the max number of automated refreshes allowed in Power BI Pro. You can refresh the report manually when viewing in Power BI. To do so:
- Go to [Power BI](https://app.powerbi.com) > **Workspaces** > **Simeon Cloud**
- Hover your mouse over the **Baseline Compliance Report** dataset > Click on the **refresh** icon

## Building custom reports and alerts
Simeon includes a **Baseline and Compliance report** and **Summary of Detected changes report** by default. Users are encouraged to create their own custom reports with the data in the Simeon Sync Power BI dataset. To create custom reports, [follow these instructions](https://learn.microsoft.com/en-us/power-bi/connect-data/create-dataset-log-analytics#create-a-dataset-from-log-analytics).

## Uninstall Power BI Reporting

### Uninstall Azure SQL
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

### Uninstall Log Analytics
Power BI Reporting installed after August 2023 reads from a Log Analytics workspace by default. To remove Power BI Reporting with Log Analytics, do the following:
- Delete the resource group named **simeoncloudreporting** from [portal.microsoft.com](https://portal.microsoft.com/) > Resource groups
- Delete the Service Principal named **Simeon Cloud Reporting** from [portal.microsoft.com](https://portal.microsoft.com/) > Enterprise applications
- Update the Library in Azure DevOps to remove all variables that start with **LogAnalytics** AND **SimeonSync**. Go to [DevOps](https://dev.azure.com/) > Tenants > Pipelines > Library > Variable Groups > Sync > remove the following:
    - LogAnalyticsResourceId
    - LogAnalyticsEndpointUrl
    - SimeonSyncIntegrationTenant
    - SimeonSyncIntegrationAppSecret
    - SimeonSyncIntegrationAppId

## Q & A
### Can I make changes to the reports deployed by Simeon?
Simeon continually enhances reports. Pushing these report updates to your tenant requires deleting the existing report and creating a new copy. So, any customizations you make to the report will be removed when the **Backfill Sync Integrations** is run. If you accidentally lose changes to your reports, please contact support@simeoncloud.com.

### Can I use the dataset to build my own reports?
Yes! If you build a report you think others might benefit from, let us know. We are happy to spread the word!

### I don't have a Power BI Pro license; can I still see the workspace?
Accessing a shared Power BI workspace requires at least a Power BI Pro license assigned to the user accessing the workspace. If you are unsure that you want to signup, Power BI offers several trial options. Also, a Power BI Pro license is included in the **Office E5 license**.

# Daily Summary Email
Sends a daily digest of all changes made to your tenants in the past 24 hours, providing you an easy way to monitor your tenants.
