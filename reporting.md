# Simeon Cloud Power BI Reporting
Report on your Simeon Sync data from a single location. Use one of our builtin reports or create your own from the raw data.

## Tenant updates
When installing Simeon Cloud Power BI Reporting, the installer will make the following changes to the tenant selected to host the Power BI report:
- Creates an **Azure Service Principal** named Simeon Cloud Power BI Reporting
- **Generates credentials** for Simeon Cloud Power BI Reporting and saves the credentials in an Azure DevOps Variable Group shared only with your tenant pipelines
- Creates the Simeon Cloud **Power BI Workspace**
    - Grants admin access to Simeon Cloud Power BI Reporting
- Updates the Power BI tenant setting to **allow Service Principals access to the Power BI APIs**
- Updates the Power BI setting to allow the **logged in user access to create Power BI workspaces**
    - Power BI defaults restrict workspace creation to accounts with rights to create M365 Groups. If your tenant has this setting and the account running the installer is not allowed to create M365 Groups, the account will be added to the group during installation

## Installation
The first step to install Simeon Power BI Reporting is to determine which tenant will host the report. If you're an MSP, we recommend installing into your production or baseline tenant. If you're an enterprise, we recommend installing into your production tenant.

### Prerequisites
During installation, you will be prompted to log in with a user account. Select an account that has:
- A **Power BI Pro license**
- Has recently **logged in to [Power BI](https://app.powerbi.com)**
- Has either the **Global Administrator role** or **all of the following Azure AD roles**:
    - Application Administrator
    - Groups Administrator
    - Power BI Administrator

### Runing the installer
- From the [Simeon portal](https://app.simeoncloud.com/), click **Install** on the navigation pane > select the **Install Power BI Reporting** tab
- Enter the domain name of the tenant > **Install** > authenticate with an account that meets the [prerequisites](#prerequisites)
- Once the installation is complete, click **Run Backfill Now**. This will backfill your Power BI report with the past 72 hours of Sync data.

## Backfill Power BI Pipeline
The backfill pipeline uploads historical data to Power BI and also keeps the data source schema and reports up to date.

The backfill can also be initiated via Azure DevOps. To do so:
- Go to [Azure DevOps](https://dev.azure.com) > **Tenants** > **Pipelines**
- Find the pipeline **Backfill Power BI** > **Run pipeline**
- Select the desired parameters or keep defaults > **Run**

The pipeline parameters are as follows:
- **Update the Power BI Table schema to the latest schema** keeps the data source schema up to date
- **Delete all data in the Simeon Power BI dataset** running a data backfill with this unselected will result in duplicate data being uploaded to the data source
- **Install or reinstall Simeon Power BI report(s)** updates all Simeon reports to the latest version
- **Backfill only failed upload to Power BI steps** only backfills Syncs that have failed to upload to Power BI, allows you to run the backfill without duplicating data
- **Number of hours to include in backfill** uploads to Power BI all export/deploy Syncs in the specified number of hours
- **Number of parallel pipelines to backfill** for most runs should stay as default of 1, shouldn't be greater than 5

Run with the parameters listed below if you need to do any of the following tasks:
### Reinstall/update Simeon reports
- Check the option for **Backfill only failed upload to Power BI steps**
- Keep all other parameters as default

### Backfill more than 72 hours worth of Syncs
- Update the number in **Number of hours to include in backfill**
- Keep all other parameters as default

### Capture data from a Sync that failed to upload to Power BI
- Check the option for **Backfill only failed upload to Power BI steps**
- Ensure the failed step happened within 72 hours. If not, update **Number of hours to include in backfill** to a value that will capture the Sync
- Keep all other parameters as default


## Simeon Sync Power BI dataset
The dataset stores all export, preview, and deploy results. If it is the first time running for a tenant, all configurations including those that are unchanged will be uploaded. After the initial load for a tenant, only those configs that are added, updated, or removed will be tracked.

Each row in the data source represents a single property of a configuration.

The fields available in the dataset are as follows:
- Organization: The DevOps organization the tenant is in
- Tenant: The name of the tenant running the sync
- Action: The Sync stage, e.g., **export**, **preview**, **deploy**
- Sync Run Name: Specified by the user at Sync time, otherwise the automated name of the run given by Azure DevOps
- Sync Comment: Additional comments entered when running from the Sync page
- Sync Date Time: The date and time of the Sync in UTC time zone
- Sync Date: The date of the Sync in UTC time zone
- Sync Year: The year of the Sync (used to assist in slicing the data)
- Sync Month: A number representing the month of the Sync (used to assist in slicing the data)
- Sync Day: The Sync day (used to assist in slicing the data)
- Sync Time: The time the Sync was run in UTC (used to assist in slicing the data)
- Configuration: The name of the configuration
- Configuration Full Name: The full name of the configuration, including the path where the configuration can be found
- Configuration Description: If the configuration is from the Simeon Baseline this provides a full description about the config
- Configuration Type: The configuration type used by Simeon to distinguish where a config should be deployed to
- Configuration Type Description: The translation of the Configuration Type
- Baseline Name: The name of the baseline the tenant is using. If the tenant does not have a baseline, the value is be **[No Baseline]**
- Baseline Property Value: The baseline value of the property (if applicable) at the time of the Sync
- Configuration Reconciliation Type: The section that the configuration falls into on the reconcile screen - **only in tenant**, **available from baseline**, **conflicting with baseline**, **matching baseline**
- Property Reconciliation Type: Similar to the Configuration Reconcile Type, but at the property level
- Property Name: The name of the property being reported on
- Property Value: The value of the property at the time of the sync
- Old Property Value: Captures the previous value of the property before the Sync changes are applied
- Change Type: The action the Sync performed - **removed**, **added**, **changed**, **unchanged**
- Error Message: If the configuration fails for any reason, the full error message is captured in this column

## Baseline and Compliance report
Displays how each of your tenants compared to its baseline repository. You can see the comparison **by tenant**, **type of configuration**, and **configuration**. You can also drill down to see how properties in a **specific configuration** compare to the baseline.

Note, the preview Sync results and baseline tenant data are filtered out of the report by default. If you need to view/report on this data, please see the section on [building custom reports](#building-custom-reports).

## Building custom reports
Simeon will pre-install reports, but you are more than welcome to create your own reports with the data in the Simeon Sync Power BI dataset. To do so:
- [Power BI](https://app.powerbi.com) > **Workspaces** > **Simeon Cloud**
- Select the **Simeon Sync** dataset
- At the top of the page, select **+ Create a report** > **Start from Scratch**

From here, you can build a Power BI report that meets your needs.

## Q & A
### Can I make changes to the reports deployed by Simeon?
Simeon will continually work to enhance reports. Pushing these report updates to your tenant will require us to delete the existing report and create a new copy. So, any changes you make to the report will be removed when the **Backfill Power BI Pipeline** is run with the option to **install/reinstall the report** selected. If, by accident, you lose changes to your reports, we do take a copy of the report before reinstalling and can assist in recovering the old copy.

### Can I use the dataset to build my own reports?
Yes, please! If you build a report you think others might like, please let us know and we would be happy to spread the word!

### Why does this dataset not have some of the functions I'm used to in other Power BI datasets?
We are using a [direct query dataset](https://docs.microsoft.com/en-us/power-bi/connect-data/desktop-use-directquery#benefits-of-using-directquery), which has many benefits including speed and ease of management, but it does come with some limitations. The biggest limitation is the inability to transform the data or to create certain calculated fields. If you find that you need additional data points to build a report, please contact us and we will do what we can to help.

# Daily Summary Email
Sends a daily digest of all changes made to your tenants, providing you an easy way to monitor your tenants.