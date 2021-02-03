# Used for dev purposess
Import-Module .\SimeonInstaller.ps1 -Force
$env:PersonalAccessToken = Get-SimeonAzureDevOpsAccessToken

<#

# Get from keyvault by org name - This needs to run from webapp, not installer
$accessToken = ""
$restProps = @{
    Headers = @{ Authorization = "Bearer $accessToken"}
      ContentType = 'application/json'
  }
$url = "https://installer.vault.azure.net/secrets/Simeon-Test"
irm @restProps $url -Method Get

#>

$AuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$(Get-SimeonAzureDevOpsAccessToken)")) }
$Organization = "lance0958"

$url = "https://vssps.dev.azure.com/$Organization/_apis/graph/groups?api-version=6.1-preview.1"

<#
# Send invite to org
$body = '[{"from":"","op":0,"path":"","value":{"accessLevel":{"licensingSource":1,"accountLicenseType":2,"msdnLicenseType":0,"licenseDisplayName":"Basic","status":0,"statusMessage":"","assignmentSource":1},"user":{"principalName":"devops@simeoncloud.com","subjectKind":"user"}}}]'
Invoke-RestMethod  -Headers $AuthenicationHeader -Uri "https://vsaex.dev.azure.com/$Organization/_apis/UserEntitlements?api-version=6.1-preview.1" -Method Patch -Body $body -ContentType "application/json-patch+json"
#>

<#
# assign project collection admin
$projectColAdminDescriptor = ((Invoke-RestMethod -Headers $AuthenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/groups?api-version=6.1-preview.1" -Method Get).value | where displayname -eq "Project Collection Administrators").descriptor
$userDescriptor = ((Invoke-RestMethod -Headers $AuthenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/users?api-version=6.1-preview.1" -Method Get).value | where principalName -eq "devops@simeoncloud.com").descriptor

Invoke-RestMethod -Headers $AuthenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/memberships/$userDescriptor/$projectColAdminDescriptor`?api-version=6.1-preview.1" -Method Put
#>


# Pipelines > Settings > uncheck Limit job authorization scope to current project for non-release pipelines, Limit job authorization scope to referenced Azure DevOps repositories, and Limit variables that can be set at queue time

# Permissions > Project Collection Build Service Accounts > Members > Add > Project Collection Build Service
# New project > name it Tenants > Create project

<# Project settings
    Overview > uncheck all except Pipelines and Repos
    Permissions > Contributors > Members > Add > Tenants Build Service and Project Collection Build Service
    Repositories > Permissions > Contributors > allow Create repository
    Repositories > Permissions > Project Collection Administrators > allow Force push
    Repositories > Permissions > Project Collection Build Service Accounts > allow Force Push
    Pipelines > Settings > uncheck Limit job authorization scope to current project for non-release pipelines, Limit job authorization scope to referenced Azure DevOps repositories, and Limit variables that can be set at queue time
    Repositories > rename Tenants to default
#>

# Create Service connection pwsh -ExecutionPolicy Bypass -Command "iex (irm https://raw.githubusercontent.com/simeoncloud/docs/master/SimeonInstaller.ps1); Install-SimeonGitHubServiceConnection -Organization (Read-Host Enter Organization) -Project Tenants"
# Navigate to Project settings > Service connections > ... > Security > Add > Contributors > set role to Administrator > Add
# Pipelines > ... > Manage security > Contributors > ensure Administer build permissions and Edit build pipeline are set to Allow

# Install SummaryReport pipeline
# pwsh -ExecutionPolicy Bypass -Command "iex (irm https://raw.githubusercontent.com/simeoncloud/docs/master/SimeonInstaller.ps1); Install-SimeonReportingPipeline -FromEmailAddress 'noreply@simeoncloud.com' -FromEmailPw $emailPw -ToBccAddress '70e1ed48.simeoncloud.com@amer.teams.ms' -Organization $organization"

# Install Retry failed Pipelines
# pwsh -ExecutionPolicy Bypass -Command "iex (irm https://raw.githubusercontent.com/simeoncloud/docs/master/SimeonInstaller.ps1); Install-SimeonRetryPipeline -Organization $organization"
# Turn off Organization and Project alerts for Pipelines, but enable those sent to pipelinenotifications@simeoncloud.com

# Organization settings > Global notifications > disable Build completes and Pull request changes

# Project settings > Notifications > New subscription > Build > A build completes > Next > change 'Deliver to' to custom email address > pipelinenotifications@simeoncloud.com

# Install code search

# Organization settings > Extensions > Browse marketplace > search for Code Search > Get it free

# Organization settings

# Users > Add users > add the users from the client that need to be able to access the pipelines > Add

# Project settings > Permissions > Tenants Team > Members > Add > enter in the user you wish to add > Save