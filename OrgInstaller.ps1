# Used for dev purposess
Import-Module .\SimeonInstaller.ps1 -Force
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
            Write-Verbose "Invoking rest method with params:"
            Write-Verbose ($params | Out-String)
            $response = Invoke-RestMethod @params
            if (!$response -or !$response.StatusCode -ne 200) {
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
    return $response
}

$Organization = "globaladmin0504"
$ProjectName = "Tenants"
$SimeonUserToInviteToOrg = "devops@simeoncloud.com"
$PipelineNotificationEmail ="pipelinenotifications@simeoncloud.com"

$groups = (Invoke-Api -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/groups?api-version=6.1-preview.1" -Method Get).value

if ($SimeonUserToInviteToOrg) {
    # Send invite to org for Simeon User
    Write-Information "Sending invite to devops Org: $Organization for user: $SimeonUserToInviteToOrg"
    $body = @"
    [
        {
            "from": "",
            "op": 0,
            "path": "",
            "value": {
                "accessLevel": {
                    "licensingSource": 1,
                    "accountLicenseType": 2,
                    "msdnLicenseType": 0,
                    "licenseDisplayName": "Basic",
                    "status": 0,
                    "statusMessage": "",
                    "assignmentSource": 1
                },
                "user": {
                    "principalName": "$SimeonUserToInviteToOrg",
                    "subjectKind": "user"
                }
            }
        }
    ]
"@
    Invoke-Api -Uri "https://vsaex.dev.azure.com/$Organization/_apis/UserEntitlements?api-version=6.1-preview.1" -Method Patch -ContentType "application/json-patch+json" -Body $body

    # assign project collection admin
    Write-Information "Making user: $SimeonUserToInviteToOrg Project Collection Admin"
    $groupDescriptor = ($groups|? displayname -eq "Project Collection Administrators").descriptor
    $userDescriptor = ((Invoke-Api -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/users?api-version=6.1-preview.1" -Method Get).value |? principalName -eq "$SimeonUserToInviteToOrg").descriptor
    Invoke-Api -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/memberships/$userDescriptor/$groupDescriptor`?api-version=6.1-preview.1" -Method Put | Out-Null
}

Write-Information "Getting project id for: $projectName"
# Set or get Project id
$projectId = ((Invoke-Api -Uri "https://dev.azure.com/$Organization/_apis/projects?api-version=6.1-preview.4" -Method Get).value |? {$_.name -eq "$ProjectName"}).id
if (!$projectId)
{
    Write-Information "Creating project: $projectName"
    $body = @"
    {
        "name": "$ProjectName",
        "description": "",
        "visibility": 0,
        "capabilities": {
            "versioncontrol": {
                "sourceControlType": "Git"
            },
            "processTemplate": {
                "templateTypeId": "b8a3a935-7e91-48b8-a94c-606d37c3e9f2"
            }
        }
    }
"@
    $projectId = (Invoke-Api -Uri "https://dev.azure.com/$Organization/_apis/projects?api-version=6.1-preview.4" -Method Post -Body $body).id
}

Write-Information "Getting all users"
# Get users after inviting Simeon User and creating the new project
$users = (Invoke-Api -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/users?api-version=6.1-preview.1" -Method Get).value
$groups = (Invoke-Api -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/groups?api-version=6.1-preview.1" -Method Get).value

# TODO THESE NEED TO MOVE TO PROJECT LEVEL
Write-Information "Configuring pipeline settings"
# Pipelines > Settings > uncheck Limit job authorization scope to current project for non-release pipelines (enforceReferencedRepoScopedToken), Limit job authorization scope to referenced Azure DevOps repositories (enforceJobAuthScope), and Limit variables that can be set at queue time (enforceSettableVar)
$body = @"
{
    "contributionIds": [
        "ms.vss-build-web.pipelines-org-settings-data-provider"
    ],
    "dataProviderContext": {
        "properties": {
            "enforceReferencedRepoScopedToken": "false",
            "enforceJobAuthScope": "false",
            "enforceSettableVar": "false"
        }
    }
}
"@
Invoke-Api -Uri "https://dev.azure.com/$Organization/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1" -Method Post -Body $body | Out-Null

# Permissions > Project Collection Build Service Accounts > Members > Add > Project Collection Build Service
Write-Information "Setting Project Collection Build Service as Project Collection Build Service Accounts"
$groupDescriptor = ($groups |? displayname -eq "Project Collection Build Service Accounts").descriptor
$userDescriptor = ($users |? displayName -like "Project Collection Build Service (*").descriptor # Sometimes the displayname contains the org name in () other times a guid
Invoke-Api -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/memberships/$userDescriptor/$groupDescriptor`?api-version=6.1-preview.1" -Method Put | Out-Null

## Project settings
# Overview > uncheck Boards and Test Plans
Write-Information "Updating project settings turning off Boards and Test Plans"
$body = @"
{
    "featureId": "ms.vss-work.agile",
    "scope": {
        "settingScope": "project",
        "userScoped": false
    },
    "state": 0
}
"@
Invoke-Api -Uri "https://dev.azure.com/$Organization/_apis/FeatureManagement/FeatureStates/host/project/$projectId/ms.vss-work.agile?api-version=4.1-preview.1" -Method Patch -Body $body | Out-Null

# Overview > uncheck Artifacts
Write-Information "Updating project settings turning off Artifacts"
$body = @"
{
    "featureId": "ms.feed.feed",
    "scope": {
        "settingScope": "project",
        "userScoped": false
    },
    "state": 0
}
"@
Invoke-Api -Uri "https://dev.azure.com/$Organization/_apis/FeatureManagement/FeatureStates/host/project/$projectId/ms.feed.feed?api-version=4.1-preview.1" -Method Patch -Body $body | Out-Null

#  Permissions > Contributors > Members > Add > $ProjectName Build Service
### Contributors group actions
Write-Information "Configuring permissions for Contributors group"
Write-Information "Adding $ProjectName Build Service ($Organization)"
$groupDescriptor = ($groups |? principalName -eq "[$ProjectName]\Contributors").descriptor
$userDescriptor = ($users |? displayName -eq "$ProjectName Build Service ($Organization)").descriptor
Invoke-Api -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/memberships/$userDescriptor/$groupDescriptor`?api-version=6.1-preview.1" -Method Put | Out-Null

# Permissions > Contributors > Members > Add > Project Collection Build Service
Write-Information "Adding Project Collection Build Service ($Organization)"
$userDescriptor = ($users |? displayName -like "Project Collection Build Service (*").descriptor
Invoke-Api -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/memberships/$userDescriptor/$groupDescriptor`?api-version=6.1-preview.1" -Method Put | Out-Null

# Repositories > Permissions > Contributors > allow Create repository
Write-Information "Allowing Contributors to create repository"
$identityDescriptor = ((Invoke-Api -Uri "https://vssps.dev.azure.com/$Organization/_apis/identities?api-version=6.0&subjectDescriptors=$groupDescriptor" -Method Get).value).descriptor
$body = @"
{
    "token": "repoV2/$projectId/",
    "merge": true,
    "accessControlEntries": [
        {
            "descriptor": "$identityDescriptor",
            "allow": 256,
            "deny": 0,
            "extendedInfo": {
                "effectiveAllow": 256,
                "effectiveDeny": 0,
                "inheritedAllow": 256,
                "inheritedDeny": 0
            }
        }
    ]
}
"@
Invoke-Api -Uri "https://dev.azure.com/$Organization/_apis/AccessControlEntries/2e9eb7ed-3c0a-47d4-87c1-0ffdd275fd87?api-version=5.0" -Method Post -Body $body | Out-Null

# Repositories > Permissions > Project Collection Administrators > allow Force push
Write-Information "Allowing force push for Project Collection Administrators"
$groupDescriptor = ($groups |? { $_.principalName -eq "[$Organization]\Project Collection Administrators" }).descriptor
$identityDescriptor = ((Invoke-Api -Uri "https://vssps.dev.azure.com/$Organization/_apis/identities?api-version=6.0&subjectDescriptors=$groupDescriptor" -Method Get).value).descriptor
$body = @"
{
    "token": "repoV2/$projectId/",
    "merge": true,
    "accessControlEntries": [
        {
            "descriptor": "$identityDescriptor",
            "allow": 8,
            "deny": 0,
            "extendedInfo": {
                "effectiveAllow": 8,
                "effectiveDeny": 0,
                "inheritedAllow": 8,
                "inheritedDeny": 0
            }
        }
    ]
}
"@
Invoke-Api -Uri "https://dev.azure.com/$Organization/_apis/AccessControlEntries/2e9eb7ed-3c0a-47d4-87c1-0ffdd275fd87?api-version=5.0" -Method Post -Body $body | Out-Null

# Repositories > Permissions > Project Collection Build Service Accounts > allow Force Push
Write-Information "Allowing force push for Project Collection Build Service Accounts"
$groupDescriptor = ($groups |? { $_.principalName -eq "[$Organization]\Project Collection Build Service Accounts" }).descriptor
$identityDescriptor = ((Invoke-Api -Uri "https://vssps.dev.azure.com/$Organization/_apis/identities?api-version=6.0&subjectDescriptors=$groupDescriptor" -Method Get).value).descriptor
$body = @"
{
    "token": "repoV2/$projectId/",
    "merge": true,
    "accessControlEntries": [
        {
            "descriptor": "$identityDescriptor",
            "allow": 8,
            "deny": 0,
            "extendedInfo": {
                "effectiveAllow": 8,
                "effectiveDeny": 0,
                "inheritedAllow": 8,
                "inheritedDeny": 0
            }
        }
    ]
}
"@
Invoke-Api -Uri "https://dev.azure.com/$Organization/_apis/AccessControlEntries/2e9eb7ed-3c0a-47d4-87c1-0ffdd275fd87?api-version=5.0" -Method Post -Body $body | Out-Null

# Pipelines > Settings > uncheck Limit job authorization scope to current project for non-release pipelines
Write-Information "Unchecking Limit job authorization scope to current project for non-release pipelines"
# Limit job authorization scope to referenced Azure DevOps repositories
$body = @"
{
    "contributionIds": [
        "ms.vss-build-web.pipelines-general-settings-data-provider"
    ],
    "dataProviderContext": {
        "properties": {
            "enforceReferencedRepoScopedToken": "false",
            "enforceJobAuthScope": "false",
            "enforceSettableVar": "false",
            "sourcePage": {
                "url": "https://dev.azure.com/$Organization/$ProjectName/_settings/settings",
                "routeId": "ms.vss-admin-web.project-admin-hub-route",
                "routeValues": {
                    "project": "$ProjectName",
                    "adminPivot": "settings",
                    "controller": "ContributedPage",
                    "action": "Execute"
                }
            }
        }
    }
}
"@
Invoke-Api -Uri "https://dev.azure.com/$Organization/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1" -Method Post -Body $body | Out-Null

# Repositories > rename $ProjectName to default
Write-Information "Renaming $ProjectName to default"
$repos = (Invoke-Api -Uri "https://dev.azure.com/$Organization/$projectId/_apis/git/repositories?api-version=6.0" -Method Get).value
if ($repos.name -contains "$ProjectName") {
    $repoId = ($repos |? { $_.name -eq "$ProjectName"}).id
    $body = "{""name"":""Default""}"
    Invoke-Api -Uri "https://dev.azure.com/$Organization/$projectId/_apis/git/repositories/$repoId`?api-version=5.0" -Method Patch -Body $body | Out-Null
}

<#
# Create Service connection
Write-Information "Creating Github Service connection"
$githubAccessToken ="Get from keyvault"
Install-SimeonGitHubServiceConnection -Organization $Organization -Project $ProjectName -GitHubAccessToken $githubAccessToken

# Install Retry failed Pipelines
Write-Information "Installing retry pipelines"
Install-SimeonRetryPipeline -Organization $Organization

# Install SummaryReport pipeline
Write-Information "Installing reporting pipeline"
$emailPw = "Get from keyvault"
Install-SimeonReportingPipeline -FromEmailAddress 'noreply@simeoncloud.com' -FromEmailPw $emailPw -ToBccAddress '70e1ed48.simeoncloud.com@amer.teams.ms' -Organization $Organization
#>

# Navigate to Project settings > Service connections > ... > Security > Add > Contributors > set role to Administrator > Add
Write-Information "Making Contributors admin for Github service connection"
$groupId = ($groups |? principalName -eq "[$ProjectName]\Contributors").originId
$body = @"
[
    {
        "roleName": "Administrator",
        "userId": "$groupId"
    }
]
"@
Invoke-Api -Uri "https://dev.azure.com/$Organization/_apis/securityroles/scopes/distributedtask.project.serviceendpointrole/roleassignments/resources/$projectId`?api-version=5.0-preview.1" -Method Put -Body $body | Out-Null

# Pipelines > ... > Manage security > Contributors > ensure Administer build permissions and Edit build pipeline are set to Allow
Write-Information "Ensuring Administer build permissions and Edit build pipeline are set to Allow"
$groupDescriptor = ($groups |? { $_.principalName -eq "[$ProjectName]\Contributors" }).descriptor
$identityDescriptor = ((Invoke-Api -Uri "https://vssps.dev.azure.com/$Organization/_apis/identities?api-version=6.0&subjectDescriptors=$groupDescriptor" -Method Get).value).descriptor

$body = @"
{
    "token": "$projectId",
    "merge": true,
    "accessControlEntries": [
        {
            "descriptor": "$identityDescriptor",
            "allow": 16384,
            "deny": 0,
            "extendedInfo": {
                "effectiveAllow": 16384,
                "effectiveDeny": 0,
                "inheritedAllow": 16384,
                "inheritedDeny": 0
            }
        }
    ]
}
"@
Invoke-Api -Uri "https://dev.azure.com/$Organization/_apis/AccessControlEntries/33344d9c-fc72-4d6f-aba5-fa317101a7e9?api-version=5.0" -Method Post -Body $body | Out-Null

$body = @"
{
    "token": "$projectId",
    "merge": true,
    "accessControlEntries": [
        {
            "descriptor": "$identityDescriptor",
            "allow": 2048,
            "deny": 0,
            "extendedInfo": {
                "effectiveAllow": 2048,
                "effectiveDeny": 0,
                "inheritedAllow": 2048,
                "inheritedDeny": 0
            }
        }
    ]
}
"@
Invoke-Api -Uri "https://dev.azure.com/$Organization/_apis/AccessControlEntries/33344d9c-fc72-4d6f-aba5-fa317101a7e9?api-version=5.0" -Method Post -Body $body | Out-Null

# Install code search Organization settings > Extensions > Browse marketplace > search for Code Search > Get it free
Write-Information "Installing code search"
$body = @"
{
    "assignmentType": 0,
    "billingId": null,
    "itemId": "ms.vss-code-search",
    "operationType": 1,
    "quantity": 0,
    "properties": {}
}
"@
Invoke-Api -Uri "https://extmgmt.dev.azure.com/$Organization/_apis/ExtensionManagement/AcquisitionRequests?api-version=6.1-preview.1" -Method Post -Body $body | Out-Null

# Project settings > Notifications > New subscription > Build > A build completes > Next > change 'Deliver to' to custom email address > pipelinenotifications@simeoncloud.com
Write-Information "Updating pipeline notifications"
$groupId = ($groups |? {$_.PrincipalName -eq "[$ProjectName]\$ProjectName Team" }).originId
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
        "displayName": "[$ProjectName]\\$ProjectName Team",
        "id": "$groupId",
        "uniqueName": "vstfs://Classification/TeamProject/$projectId\\$ProjectName Team",
        "isContainer": true
    },
    "channel": {
        "type": "EmailHtml",
        "address": "$PipelineNotificationEmail",
        "useCustomAddress": true
    },
    "scope": {
        "id": "$projectId"
    },
    "dirty": true
}
"@

Invoke-Api -Uri "https://dev.azure.com/$Organization/_apis/notification/Subscriptions?api-version=6.1-preview.1" -Method Post -Body $body | Out-Null

# Disable pipeline notifications
$body = '{"optedOut":true}'
# Build completes
Write-Information "Disabling build completes pipeline notifications"
Invoke-Api -Uri "https://dev.azure.com/$Organization/_apis/notification/Subscriptions/ms.vss-build.build-requested-personal-subscription/UserSettings/$groupId`?api-version=6.1-preview.1" -Method Put -Body $body | Out-Null
# Pull requests
Write-Information "Disableing pull request pipeline notifications"
Invoke-Api -Uri "https://dev.azure.com/$Organization/_apis/notification/Subscriptions/ms.vss-code.pull-request-updated-subscription/UserSettings/$groupId`?api-version=6.1-preview.1" -Method Put -Body $body | Out-Null


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
