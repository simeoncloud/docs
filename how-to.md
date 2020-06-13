# How To

## Update a baseline configuration and deploying to tenants

* Add the setting in the corresponding Azure portal - a list of the configuration types automated by Simeon can be found [here](automated-microsoft-365-configuration-types.md)
* [Run the export pipeline for the **baseline** tenant](how-to.md#run-an-export)
* [Run the deploy pipeline for your **client** tenants](how-to.md#run-a-deployment)

## Update a tenant specific configuration

* Add the setting in the corresponding Azure portal - a list of the configuration types automated by Simeon can be found [here](automated-configuration-types.md)
* [Run the export pipeline for the **client** tenant](./#run-an-export)

## Run a Deployment

* Click on **Pipelines** &gt; **\[tenant name\]** **-** **Deploy** &gt; **Run pipeline** &gt; **Run**
  * Note - you can see a history of the runs for a given pipeline or of all the runs across all pipelines by selecting the **Runs** tab
* Deploy has two stages: Preview and Deploy
  * Preview will generate a list of changes that will be made to the tenant if deployed
    * To see the result of the Preview stage, click **Extensions** and scroll to the section labeled **Preview** 
    * If you have [approval required](how-to-require-approvals.md#how-to-require-approval) for the deployment, [approve](how-to-require-approvals.md#how-to-approve) to continue
  * Deploy applies these changes to the tenant
    * To see the result of the Deploy stage, click **Extensions** and scroll to the section labeled **Deploy** 

## Run an Export

* Click on **Pipelines** &gt; **\[tenant name\]** **-** **Export** &gt; **Run pipeline** &gt; **Run**
* Export has two stages: Export and Merge Changes
  * Export will generate a list of changes to be made to the tenant repository
    * To see the result of the Export stage, click **Extensions** and scroll to the section labeled **Export** 
    * If you have [approval required](how-to-require-approvals.md#how-to-require-approval) for the deployment, [approve](how-to-require-approvals.md#how-to-approve) to continue
  * Merge Changes applies these changes to the tenant repository
    * To see the changes in the tenant repository, navigate to **Repos** &gt; **repositories dropdown at the top** &gt; **\[tenant name\]**
      * By clicking **History** you can see a history of all past changes

## Schedule Deployment/Export

* Note - approval should be turned off when using scheduling, otherwise a user must be present to approve
* To utilize scheduling, navigate to **Pipelines** &gt; **\[tenant name\]** - **Deploy** or **Export** &gt; **Edit** &gt; **...** \(top right\) ****&gt; **Triggers** &gt; **Add** \(next to **Scheduled**\) &gt; schedule the run accordingly

## Set up a tenant for use with Simeon

This is a manual, one time process per tenant

* Create AAD tenant or log in to the existing tenant you want to configure 
  * [Create a new, empty AAD from the Azure Admin Portal](https://portal.azure.com/#create/Microsoft.AzureActiveDirectory) 
    * **Do not** create one using a personal account - otherwise it will create an AAD tenant called `johndoegmail.onmicrosoft.com`\)
    * Note that the user you create the new tenant as will be added to the tenant as an External User in the Global Administrator directory role
  * Optionally, create and verify a new custom domain name, then make this the primary domain for AAD \(Azure Portal &gt; Azure AD &gt; Custom domain names\)
* Create a new AAD service account - the below PowerShell will do so and can be run from a local computer or Cloud Shell

```text
function New-SimeonServiceAccount {
    param(
        [string]$TenantId = (Read-Host 'Enter tenant domain name or id'), 
        [securestring]$Password = (Read-Host 'Enter password' -AsSecureString)
    )

    $ErrorActionPreference = 'Stop'
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    if (!(@('AzureAD', 'AzureAD.Standard.Preview') |% { Get-Module $_ -ListAvailable })) { Install-Module AzureAD -Scope CurrentUser -Force }
    
    try {
        if (!(Get-AzureADCurrentSessionInfo |? { @($_.TenantId, $_.TenantDomain) -contains $TenantId })) {
            Connect-AzureAD -TenantId $TenantId
        }
    }
    catch { Connect-AzureAD -TenantId $TenantId }

    $user = Get-AzureADUser -Filter "displayName eq 'Simeon Service Account'"
    if (!$user) {
        Write-Host "Creating user"
        $user = New-AzureADUser -DisplayName 'Simeon Service Account' `
            -UserPrincipalName "simeon@$(Get-AzureADDomain |? IsDefault -eq $true | Select -ExpandProperty Name)" `
            -MailNickName simeon -AccountEnabled $true `
            -PasswordProfile @{ Password = ([System.Net.NetworkCredential]::new("", $Password).Password); ForceChangePasswordNextLogin = $false } -PasswordPolicies DisablePasswordExpiration
    }
    else {
        Write-Host "Updating user password"
        $user | Set-AzureADUser -PasswordProfile @{ Password = ([System.Net.NetworkCredential]::new("", $Password).Password); ForceChangePasswordNextLogin = $false } -PasswordPolicies DisablePasswordExpiration
    }

    # this can sometimes fail on first request
    try { Get-AzureADDirectoryRole | Out-Null } catch {}

    if (!(Get-AzureADDirectoryRole |? DisplayName -eq 'Directory Synchronization Accounts')) { 
        Write-Host "Activating role Directory Synchronization Accounts"
        Get-AzureADDirectoryRoleTemplate |? DisplayName -eq 'Directory Synchronization Accounts' |% { Enable-AzureADDirectoryRole -RoleTemplateId $_.ObjectId -EA SilentlyContinue | Out-Null }
    }

    Get-AzureADDirectoryRole |? { $_.DisplayName -in @('Company Administrator', 'Directory Synchronization Accounts') } |% { 
        if (!(Get-AzureADDirectoryRoleMember -ObjectId $_.ObjectId |? ObjectId -eq $user.ObjectId)) {
            Write-Host "Adding to role $($_.DisplayName)"
            Add-AzureADDirectoryRoleMember -ObjectId $_.ObjectId -RefObjectId $user.ObjectId 
        }
        else {
            Write-Host "Already a member of role $($_.DisplayName)"
        }
    }
}
New-SimeonServiceAccount
```

* **If this is a new tenant,** sign in to the Azure Portal as the newly created AAD user [simeon@mydomain.com](mailto:m365management@mydomain.com) to create/associate subscriptions and licenses as described in the subsequent steps
* **If you do not already have one,** get an Azure Subscription \(for provisioning Azure RM Services - e.g Storage Accounts, CloudShell, Key Vaults\)
  * Purchase via the [Azure Portal](https://portal.azure.com/#blade/Microsoft_Azure_Billing/SubscriptionsBlade) or an [Enterprise Agreement](https://ea.azure.com/manage/enrollment) 
  * Name it as desired
  * Note that you may need to sign out and back in to use the new subscription
* Navigate to the subscription &gt; **Access control \(IAM\)** &gt; **Role assignments** &gt; **Add** &gt; **Add role assignment** 
  * **Role** &gt; **Owner** 
  * **Select** &gt; **Simeon Service Account**
  * **Save**
  * **Note** - if you have more than 1 subscription, be sure to only assign the Owner role for the subscription you want Simeon to use
* **If you do not already have one,** get [Microsoft 365](https://www.microsoft.com/en-us/microsoft-365/enterprise)  E3, E5, or Business Premium licenses for the new AAD tenant
  * Purchase via the [Microsoft 365 Admin Portal](https://admin.microsoft.com/AdminPortal/Home#/catalog) or [Volume Licensing](https://www.microsoft.com/Licensing/servicecenter/default.aspx) 
  * **Note** - [**Office 365** is **not** the same as **Microsoft 365**](https://www.acutec.co.uk/blog/difference-between-microsoft-365-office-365)  - make sure you get the right license - we use the full range of Microsoft 365 functionality \(if Microsoft 365 E5 isn't available, you can combine an EMS E5 and O365 E5 license to get the same result\)
  * The exact license name listed in the [Azure Portal](https://portal.azure.com/#blade/Microsoft_AAD_IAM/LicensesMenuBlade/Products)
  * If omitted, the default is Microsoft 365 Business Premium
