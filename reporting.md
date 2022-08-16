# Power BI
[put Overview here]

## Installation
The first step in installing Power BI Reporting for Simeon Cloud Sync is to determine which tenant will host the report. All tenants in your orgnization will write sync data to tenant hosting the report.

### Prerequisites
During installation, you will be prompted to login with a user account. Select an account that has:
- A Power BI Pro license
- Has logged into [Power BI](https://app.powerbi.com) at least one time
- Has the following Azure AD roles (These are included in the global admin role):
    - Application Administrator
    - Groups Administrator
    - Power BI Administrator

### Runing the installer
- From [Simeon Cloud](https://app.simeoncloud.com/)
- Select 'Install' on the left navigation pane
- Select the 'Install Power BI Reporting' tab at the top of the page
- Enter the domain of the tenant and select 'Install'
- Read and confirm the dialog
- When prompted, login with the appropriate account
- When install finishes, select 'Yes' on the prompt to Run Backfill Now

### Tenant updates
The installer makes the follwing changes to the tenant selected to host the Power BI report:
- Creates an Azure Service Principal named 'Simeon Cloud Power BI Reporting'
- Generates credentials for 'Simeon Cloud Power BI Reporting' and saves those credentials to a DevOps Variable Group shared by all pipelines (note the secret is encrypted and only the pipelines have access to view it)
- Creates the 'Simeon Cloud' Power BI Workspace
    - Grants admin access to 'Simeon Cloud Power BI Reporting'
- Updates the Power BI setting to allow Service Principals access to the Power BI APIs
- Updates the Power BI setting to allow the logged in user access to create workspaces
    - This setting defaults to the tenant wide setting for allowing M365 Group creation, if this default is turned on and the account running the installer is not a member of the group, the account will be added

## Backfill Power BI Pipeline
The Backfill Power BI Pipeline allows you to immediately benefit from having your sync data in Power BI. Upon installation, you will be prompted to run the Backfill Pipeline. Running the pipeline will install the 'Baseline Compliance Report' and initiate a backfill to upload to Power BI all Simeon Syncs with export/deploy changes in the past 72 hours.

If you need to update the 'Baseline Compliance Report' or if you want more than 72 hours of past Syncs, you can manually trigger the 'Backfill Power BI Pipeline'.

To run the backfill
- Go to [Azure Devops](https://dev.azure.com)
- Select 'Tenants'
- On the left navigation pane, select 'Pipelines'
- Find and select 'Backfill Power BI' in the list of pipelines
- Select 'Run pipeline' in the top left of the page
- From here, you will be presented with options for running the pipeline. For most cases, the default options suffice, but in certain cases the options can be updated before running. The options are as follows:
    - Update the Power BI Table schema to the latest schema: This will be selected by default and is used to ensure the datasource has all required columns
    - Delete all data in the Simeon Power BI dataset: Selecting this option will delete all the data in the Power BI datasource before uploading new data. Running with this unselected will result in duplicate data
    - Install or reinstall the Power BI report: Installs or updates the lastest version of the Power BI Report(s) provided by Simeon Cloud
    -Backfill only failed upload to Power BI steps: If for any reason the upload to Power BI fails for a Sync, this option will attempt to upload only the failed steps
    - Number of hours to include in backfill: Specifies the number of hours to search for Syncs with export or deploy changes
    - Number of parallel pipelines to backfill: Should stay at default of 1 for most runs, shouldn't be greater than 5

## Simeon Sync Power BI dataset
The dataset stores all export, preview, and deploy results. If it is the first time running for a tenant, all configurations including unchanged will be uploaded. After the initial load for a tenant, only those configs that are added, updated, or removed will be tracked.

Each row in the datasource represents a single property of a configuration.

The fields available in the dataset are as follows:
- Organization: The DevOps organization the tenant is apart of
- Tenant: The name of the tenant running the sync
- Action: The sync stage, e.g., export, preview, deploy
- Sync Run Name: Automated name of the run, the date with a prefix for the build count for that day
- Sync Comment: Additional comments entered when running syncs from Sync page
- Sync Date Time: The date and time of the sync in UTC timezone
- Sync Date: The date only of the sync in UTC timezone
- Sync Year: The year only of the sync (used to assist in slicing the data)
- Sync Month: A number representing the month of the sync (used to assist in slicing the data)
- Sync Day: The sync day (used to assist in slicing the data)
- Sync Time: The time the sync was run in UTC (used to assist in slicing the data)
- Configuration: The name only of the configuration
- Configuration Full Name: Full name of the configuration, including the path where the config can be found
- Configuration Description: If using a configuration from the Simeon Baseline provides a full description about the config
- Configuration Type: The configuration type used by Simeon to distinguish where a config should be deployed to
- Configuration Type Description: The translation of the Configuration Type
- Baseline Name: The name of the baseline the tenant is using, if the tenant does not have a baseline this column will have a value of '[No Baseline]'
- Baseline Property Value: The baseline value of the property at the time of the Sync
- Configuration Reconciliation Type: The section that the config falls in on the reconcile screen, including 'only in tenant', 'available from baseline', 'conflicting with baseline', 'matching baseline'
- Property Reconciliation Type: Similar to the 'Configuration Reconcile Type', but at the property level
- Property Name: The name of the property inside of the configuration
- Property Value: The value of the property at the time of the sync
- Old Property Value: Captures the previous value of the property before the sync changes were applied
- Change Type: The result of the sync on the property including, 'Removed', 'Added', 'Changed', 'Unchanged'
- Error Message: If the configuration fails for anyreason the full error message will be captured in this column

## Baseline and Compliance report


Note, you will the preview results and baseline tenant data are filtered out of the report by default. If you need to view/report on this data please see the section on building custom reports.

## Building custom reports
Simeon Cloud will pre-install reports, but you are more than welcome to create your own reports with the data int he Simeon Sync Power BI dataset. To do so:
- Login to app.powerbi.com
- On the left, select 'Workspaces' > 'Simeon Cloud'
- This page shows all resources in the Workspace, select the 'Simeon Sync' dataset
- At the top of the page select '+ Create a report' > 'Start from Scratch'

From here you can build a Power BI report that meets your needs.

## Data alerts

## Q & A
### Can I make changes to the reports deployed by Simeon?
Simeon Cloud will continually work to enhance reports. Pushing these reports to your tenant will require us to delete the existing report and create a new copy. So any changes you make to the report will be removed when the 'Backfill Power BI' pipeline is run with the option to install/reinstall the report selected. If by accident you lose changes to your reports, we do take a copy of the report before reinstalling and can assist in recoverying the old copy.

### Can I use the dataset to build my own reports?
Yes please! If you build a report you think others might like, please let us know and we would be happy to spread the word!

### Why does this dataset not have some of the functions I'm used to in other Power BI datasets?
We are using a [direct query dataset](https://docs.microsoft.com/en-us/power-bi/connect-data/desktop-use-directquery#benefits-of-using-directquery), which has many benefits including speed and ease of managing the dataset, but does also come with some limitations. The biggest limitation is the inability to transform the data or to create certain calculated fields. If you find that you need a certain data point to build a report, please contact us and we will do what we can to help.


# Summary Email
[put overview here]