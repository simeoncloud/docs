$env:PersonalAccessToken = Get-SimeonAzureDevOpsAccessToken
function Invoke-Api {
    param(
        [string]$Uri,
        [string]$Method,
        [string]$Body,
        [string]$ContentType = "application/json",
        [int]$Retries = 3,
        [int]$SecondsDelay = 5
    )
    $retryCount = 0
    $completed = $false
    $response = $null
    $AuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($env:PersonalAccessToken)")) }

# create object for splatting, removing empty keys
$params = @{
    Uri = $Uri
    Method = $Method
    Header = $AuthenicationHeader
    Body = $Body
    ContentType = $ContentType
}
($params.GetEnumerator() | ? { -not $_.Value }) | % { $params.Remove($_.Name) }

    while (-not $completed) {
        try {
            $response = Invoke-RestMethod @params
            if ($response.StatusCode -ne 200) {
                throw "Expecting reponse code 200, was: $($response.StatusCode)"
            }
            $completed = $true
        } catch {
            Write-Host "$(Get-Date -Format G): Request to $url failed. $_"
            if ($retrycount -ge $Retries) {
                Write-Warning "Request to $url failed the maximum number of $retryCount times."
                throw
            } else {
                Write-Warning "Request to $url failed. Retrying in $SecondsDelay seconds."
                Start-Sleep $SecondsDelay
                $retrycount++
            }
        }
    }
}

# Used for dev purposess
Import-Module .\SimeonInstaller.ps1 -Force


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

$Organization = "lance0958"

$url = "https://vssps.dev.azure.com/$Organization/_apis/graph/groups?api-version=6.1-preview.1"

<#
# Send invite to org
$body = '[{"from":"","op":0,"path":"","value":{"accessLevel":{"licensingSource":1,"accountLicenseType":2,"msdnLicenseType":0,"licenseDisplayName":"Basic","status":0,"statusMessage":"","assignmentSource":1},"user":{"principalName":"devops@simeoncloud.com","subjectKind":"user"}}}]'
Invoke-RestMethod  -Headers $AuthenicationHeader -Uri "https://vsaex.dev.azure.com/$Organization/_apis/UserEntitlements?api-version=6.1-preview.1" -Method Patch -Body $body -ContentType "application/json-patch+json"
#>

<#
# assign project collection admin
$groupDescriptor = ((Invoke-RestMethod -Headers $AuthenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/groups?api-version=6.1-preview.1" -Method Get).value | where displayname -eq "Project Collection Administrators").descriptor
$userDescriptor = ((Invoke-RestMethod -Headers $AuthenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/users?api-version=6.1-preview.1" -Method Get).value | where principalName -eq "devops@simeoncloud.com").descriptor

Invoke-RestMethod -Headers $AuthenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/memberships/$userDescriptor/$groupDescriptor`?api-version=6.1-preview.1" -Method Put
#>

<#
# Pipelines > Settings > uncheck Limit job authorization scope to current project for non-release pipelines (enforceReferencedRepoScopedToken), Limit job authorization scope to referenced Azure DevOps repositories (enforceJobAuthScope), and Limit variables that can be set at queue time (enforceSettableVar)
$body = '{"contributionIds":["ms.vss-build-web.pipelines-org-settings-data-provider"],"dataProviderContext":{"properties":{"enforceReferencedRepoScopedToken":"false", "enforceJobAuthScope": "false", "enforceSettableVar": "false"}}}'
Invoke-RestMethod -Headers $AuthenicationHeader -Uri "https://dev.azure.com/$Organization/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1" -Method Post -Body $body -ContentType "application/json"
#>


# New project > name it Tenants > Create project
$projectId = ((Invoke-RestMethod -Headers $AuthenicationHeader -Uri "https://dev.azure.com/$Organization/_apis/projects?api-version=6.1-preview.4" -Method Get).Value |? {$_.name -eq "Tenants"}).id
if (!$projectId)
{
    $body = '{"name":"Tenants","description":"","visibility":0,"capabilities":{"versioncontrol":{"sourceControlType":"Git"},"processTemplate":{"templateTypeId":"b8a3a935-7e91-48b8-a94c-606d37c3e9f2"}}}'
    $projectId = (Invoke-RestMethod -Headers $AuthenicationHeader -Uri "https://dev.azure.com/$Organization/_apis/projects?api-version=6.1-preview.4" -Method Post -Body $body -ContentType "application/json").id
}


<#
# Permissions > Project Collection Build Service Accounts > Members > Add > Project Collection Build Service
$projectColAdminDescriptor = ((Invoke-RestMethod -Headers $AuthenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/groups?api-version=6.1-preview.1" -Method Get).value | where displayname -eq "Project Collection Build Service Accounts").descriptor
$userDescriptor = ((Invoke-RestMethod -Headers $AuthenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/users?api-version=6.1-preview.1" -Method Get).value | where displayName -eq "Project Collection Build Service ($Organization)").descriptor

Invoke-RestMethod -Headers $AuthenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/memberships/$userDescriptor/$projectColAdminDescriptor`?api-version=6.1-preview.1" -Method Put
#>

<# Project settings
    Overview > uncheck all except Pipelines and Repos
# Boards and Test Plans
$body = '{"featureId":"ms.vss-work.agile","scope":{"settingScope":"project","userScoped":false},"state":0}'
Invoke-RestMethod  -Headers $AuthenicationHeader -Uri "https://dev.azure.com/$Organization/_apis/FeatureManagement/FeatureStates/host/project/$ProjectId/ms.vss-work.agile?api-version=4.1-preview.1" -Method Patch -Body $body -ContentType "application/json"

# Artifacts
$body = '{"featureId":"ms.feed.feed","scope":{"settingScope":"project","userScoped":false},"state":0}'
Invoke-RestMethod  -Headers $AuthenicationHeader -Uri "https://dev.azure.com/$Organization/_apis/FeatureManagement/FeatureStates/host/project/$ProjectId/ms.feed.feed?api-version=4.1-preview.1" -Method Patch -Body $body -ContentType "application/json"

#  Permissions > Contributors > Members > Add > Tenants Build Service
$groupDescriptor = ((Invoke-RestMethod -Headers $AuthenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/groups?api-version=6.1-preview.1" -Method Get).value | where principalName -eq "[Tenants]\Contributors").descriptor
$userDescriptor = ((Invoke-RestMethod -Headers $AuthenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/users?api-version=6.1-preview.1" -Method Get).value | where displayName -eq "Tenants Build Service ($Organization)").descriptor

Invoke-RestMethod -Headers $AuthenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/memberships/$userDescriptor/$groupDescriptor`?api-version=6.1-preview.1" -Method Put
# and Project Collection Build Service
$userDescriptor = ((Invoke-RestMethod -Headers $AuthenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/users?api-version=6.1-preview.1" -Method Get).value | where displayName -eq "Project Collection Build Service ($Organization)").descriptor
Invoke-RestMethod -Headers $AuthenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/memberships/$userDescriptor/$groupDescriptor`?api-version=6.1-preview.1" -Method Put


# Repositories > Permissions > Contributors > allow Create repository
$groups = (Invoke-RestMethod -Headers $AuthenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/groups?api-version=6.0-preview.1" -Method Get -ContentType "application/json").value
# group descriptor required to get identity descriptor
$groupDescriptor = ($groups | Where-Object { $_.principalName -eq "[Tenants]\Contributors" }).descriptor
$identityDescriptor = ((Invoke-RestMethod -Headers $AuthenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/identities?api-version=6.0&subjectDescriptors=$groupDescriptor" -Method Get -ContentType "application/json").value).descriptor
$body = "{""token"":""repoV2/$projectId/"",""merge"":true,""accessControlEntries"":[{""descriptor"":""$identityDescriptor"",""allow"":256,""deny"":0,""extendedInfo"":{""effectiveAllow"":256,""effectiveDeny"":0,""inheritedAllow"":256,""inheritedDeny"":0}}]}"
Invoke-RestMethod -Headers $AuthenicationHeader -Uri "https://dev.azure.com/$organization/_apis/AccessControlEntries/2e9eb7ed-3c0a-47d4-87c1-0ffdd275fd87?api-version=5.0" -Method Post -Body $body -ContentType "application/json"

# Repositories > Permissions > Project Collection Administrators > allow Force push
$groupDescriptor = ($groups | Where-Object { $_.principalName -eq "[$Organization]\Project Collection Administrators" }).descriptor
$identityDescriptor = ((Invoke-RestMethod -Headers $AuthenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/identities?api-version=6.0&subjectDescriptors=$groupDescriptor" -Method Get -ContentType "application/json").value).descriptor
$body = "{""token"":""repoV2/$projectId/"",""merge"":true,""accessControlEntries"":[{""descriptor"":""$identityDescriptor"",""allow"":8,""deny"":0,""extendedInfo"":{""effectiveAllow"":8,""effectiveDeny"":0,""inheritedAllow"":8,""inheritedDeny"":0}}]}"
Invoke-RestMethod -Headers $AuthenicationHeader -Uri "https://dev.azure.com/$organization/_apis/AccessControlEntries/2e9eb7ed-3c0a-47d4-87c1-0ffdd275fd87?api-version=5.0" -Method Post -Body $body -ContentType "application/json"

# Repositories > Permissions > Project Collection Build Service Accounts > allow Force Push
$groupDescriptor = ($groups | Where-Object { $_.principalName -eq "[$Organization]\Project Collection Build Service Accounts" }).descriptor
$identityDescriptor = ((Invoke-RestMethod -Headers $AuthenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/identities?api-version=6.0&subjectDescriptors=$groupDescriptor" -Method Get -ContentType "application/json").value).descriptor
$body = "{""token"":""repoV2/$projectId/"",""merge"":true,""accessControlEntries"":[{""descriptor"":""$identityDescriptor"",""allow"":8,""deny"":0,""extendedInfo"":{""effectiveAllow"":8,""effectiveDeny"":0,""inheritedAllow"":8,""inheritedDeny"":0}}]}"
Invoke-RestMethod -Headers $AuthenicationHeader -Uri "https://dev.azure.com/$organization/_apis/AccessControlEntries/2e9eb7ed-3c0a-47d4-87c1-0ffdd275fd87?api-version=5.0" -Method Post -Body $body -ContentType "application/json"

# These are at the project level, not to be confused with those at the org level
# Pipelines > Settings > uncheck Limit job authorization scope to current project for non-release pipelines
# Limit job authorization scope to referenced Azure DevOps repositories
# Limit variables that can be set at queue time
$body = "{""contributionIds"":[""ms.vss-build-web.pipelines-general-settings-data-provider""],""dataProviderContext"":{""properties"":{""enforceReferencedRepoScopedToken"":""false"", ""enforceJobAuthScope"": ""false"", ""enforceSettableVar"": ""false"",""sourcePage"":{""url"":""https://dev.azure.com/$Organization/Tenants/_settings/settings"",""routeId"":""ms.vss-admin-web.project-admin-hub-route"",""routeValues"":{""project"":""Tenants"",""adminPivot"":""settings"",""controller"":""ContributedPage"",""action"":""Execute""}}}}}"
Invoke-RestMethod -Headers $AuthenicationHeader -Uri "https://dev.azure.com/$Organization/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1" -Method Post -Body $body -ContentType "application/json"


# Repositories > rename Tenants to default
# Get repo
$repos = (Invoke-RestMethod -Headers $AuthenicationHeader -Uri "https://dev.azure.com/$Organization/$projectId/_apis/git/repositories?api-version=6.0" -Method Get -ContentType "application/json").value
if ($repos.name -contains "Tenants") {
    $repoId = ($repos |? { $_.name -eq "Tenants"}).id
    $body = "{""name"":""Default""}"
    Invoke-RestMethod -Headers $AuthenicationHeader -Uri "https://dev.azure.com/$Organization/$projectId/_apis/git/repositories/$repoId`?api-version=5.0" -Method Patch -Body $body -ContentType "application/json"
}

#>

<#
# Create Service connection
$githubAccessToken ="Get from keyvault"
Install-SimeonGitHubServiceConnection -Organization $Organization -Project Tenants -GitHubAccessToken $githubAccessToken
#>

<#
# Install Retry failed Pipelines
Install-SimeonRetryPipeline -Organization $organization
#>

<#
# Navigate to Project settings > Service connections > ... > Security > Add > Contributors > set role to Administrator > Add
$groupId = ((Invoke-RestMethod -Headers $AuthenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/groups?api-version=6.1-preview.1" -Method Get).value | where principalName -eq "[Tenants]\Contributors").originId
$body = "[{""roleName"":""Administrator"",""userId"":""$groupId""}]"
Invoke-RestMethod -Headers $AuthenicationHeader -Uri "https://dev.azure.com/$organization/_apis/securityroles/scopes/distributedtask.project.serviceendpointrole/roleassignments/resources/$projectId`?api-version=5.0-preview.1" -Method Put -Body $body -ContentType "application/json"
#>

<#
# Install SummaryReport pipeline
$emailPw =
Install-SimeonReportingPipeline -FromEmailAddress 'noreply@simeoncloud.com' -FromEmailPw $emailPw -ToBccAddress '70e1ed48.simeoncloud.com@amer.teams.ms' -Organization $organization
#>

<#
# Pipelines > ... > Manage security > Contributors > ensure Administer build permissions and Edit build pipeline are set to Allow
$groupDescriptor = ($groups | Where-Object { $_.principalName -eq "[Tenants]\Contributors" }).descriptor
$identityDescriptor = ((Invoke-RestMethod -Headers $AuthenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/identities?api-version=6.0&subjectDescriptors=$groupDescriptor" -Method Get -ContentType "application/json").value).descriptor


$body = "{""token"":""$projectId"",""merge"":true,""accessControlEntries"":[{""descriptor"":""$identityDescriptor"",""allow"":16384,""deny"":0,""extendedInfo"":{""effectiveAllow"":16384,""effectiveDeny"":0,""inheritedAllow"":16384,""inheritedDeny"":0}}]}"
Invoke-RestMethod -Headers $AuthenicationHeader -Uri "https://dev.azure.com/$organization/_apis/AccessControlEntries/33344d9c-fc72-4d6f-aba5-fa317101a7e9?api-version=5.0" -Method Post -Body $body -ContentType "application/json"

$body = "{""token"":""$projectId"",""merge"":true,""accessControlEntries"":[{""descriptor"":""$identityDescriptor"",""allow"":2048,""deny"":0,""extendedInfo"":{""effectiveAllow"":2048,""effectiveDeny"":0,""inheritedAllow"":2048,""inheritedDeny"":0}}]}"
Invoke-RestMethod -Headers $AuthenicationHeader -Uri "https://dev.azure.com/$organization/_apis/AccessControlEntries/33344d9c-fc72-4d6f-aba5-fa317101a7e9?api-version=5.0" -Method Post -Body $body -ContentType "application/json"
#>

<#
I THINK I CAN REMOVE THESE COVERED BELOW
# Organization settings > Global notifications > disable Build completes and Pull request changes
# disable Build completes
$body = '{"status":-2}'
Invoke-RestMethod -Headers $AuthenicationHeader -Uri "https://dev.azure.com/$organization/_apis/notification/Subscriptions/ms.vss-build.build-requested-personal-subscription?api-version=6.1-preview.1" -Method Patch -Body $body -ContentType "application/json"

# Pull request changes
$body = '{"status":-2}'
Invoke-RestMethod -Headers $AuthenicationHeader -Uri "https://dev.azure.com/$organization/_apis/notification/Subscriptions/ms.vss-code.pull-request-updated-subscription?api-version=6.1-preview.1" -Method Patch -Body $body -ContentType "application/json"
#>

<#
# No idea if this works on org that hasn't had code search installed
# Install code search Organization settings > Extensions > Browse marketplace > search for Code Search > Get it free
$body = '{"assignmentType":0,"billingId":null,"itemId":"ms.vss-code-search","operationType":1,"quantity":0,"properties":{}}'
Invoke-RestMethod -Headers $AuthenicationHeader -Uri "https://extmgmt.dev.azure.com/$organization/_apis/ExtensionManagement/AcquisitionRequests?api-version=6.1-preview.1" -Method Post -Body $body -ContentType "application/json"
#>


$groupId = ($groups |? {$_.PrincipalName -eq "[Tenants]\Tenants Team" }).originId
# Project settings > Notifications > New subscription > Build > A build completes > Next > change 'Deliver to' to custom email address > pipelinenotifications@simeoncloud.com

$body = @"
    {
    "description": "A build completes",
    "filter": {
        "eventType": "ms.vss-build.build-completed-event",
        "criteria": {
            "clauses": [
                {
                    "fieldName": "Build reason",
                    "operator": "Does not contain",
                    "value": "-",
                    "index": 0
                }
            ]
        },
        "type": "Expression"
    },
    "notificationEventInformation": null,
    "type": 2,
    "subscriber": {
        "displayName": "[Tenants]\\Tenants Team",
        "id": "$groupId",
        "uniqueName": "vstfs:///Classification/TeamProject/$projectId\\Tenants Team",
        "isContainer": true
    },
    "channel": {
        "type": "EmailHtml",
        "address": "pipelinenotifications@simeoncloud.com",
        "useCustomAddress": true
    },
    "scope": {
        "id": "$projectId"
    },
    "dirty": true
}
"@

Invoke-RestMethod -Headers $AuthenicationHeader -Uri "https://dev.azure.com/$organization/_apis/notification/Subscriptions?api-version=6.1-preview.1" -Method Post -Body $body -ContentType "application/json"

# Disable pipeline notifications
$body = '{"optedOut":true}'
# Build completes
Invoke-RestMethod -Headers $AuthenicationHeader -Uri "https://dev.azure.com/$organization/_apis/notification/Subscriptions/ms.vss-build.build-requested-personal-subscription/UserSettings/$groupId`?api-version=6.1-preview.1" -Method Put -Body $body -ContentType "application/json"
# Pull requests
Invoke-RestMethod  -Headers $AuthenicationHeader -Uri "https://dev.azure.com/$organization/_apis/notification/Subscriptions/ms.vss-code.pull-request-updated-subscription/UserSettings/$groupId`?api-version=6.1-preview.1" -Method Put -Body $body -ContentType "application/json"