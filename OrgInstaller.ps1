Import-Module .\SimeonInstaller.ps1 -Force

function Invoke-WithRetry {
    [CmdletBinding()]
    param(
        [scriptblock]$ScriptBlock,
        [int]$MaxRetryCount = 5,
        [int]$DelaySeconds = 10
    )

    $retryCount = 0
    while ($true) {
        try {
            . $ScriptBlock
            return
        }
        catch {
            $ex = $_.Exception
            if ($ex -is [System.AggregateException] -and $ex.InnerExceptions.Count -eq 1 -and $ex.InnerExceptions[0].Message) {
                $ex = $ex.InnerExceptions[0]
            }
            $operation = $ScriptBlock -split '\n' | % { $_.Trim() } | ? { $_ } | Select -First 1
            Write-Warning "Operation '$operation' failed. Trying again in $DelaySeconds seconds - Exception: $($ex.Message)"
            Start-Sleep -Seconds $DelaySeconds
            $retryCount++
            if ($retryCount -ge $MaxRetryCount) {
                throw
            }
        }
    }
}

function Set-AzureDevOpsAccessControlEntry {
    param(
        [string]$Organization,
        [string]$ProjectId,
        [string]$SubjectGroupPrincipalName,
        [string]$PermissionDescription,
        [int]$PermissionNumber
    )
    $groups = (Invoke-WithRetry { Invoke-RestMethod -Header $AuthenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/groups?api-version=6.1-preview.1" -Method Get }).value

    Write-Information "Allowing $SubjectGroupPrincipalName to $PermissionDescription"
    $groupDescriptor = ($Groups |? principalName -eq $SubjectGroupPrincipalName).descriptor
    $identityDescriptor = ((Invoke-WithRetry { Invoke-RestMethod -Header $AuthenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/identities?api-version=6.0&subjectDescriptors=$groupDescriptor" -Method Get }).value).descriptor
    # 2e9eb7ed-3c0a-47d4-87c1-0ffdd275fd87 is the Git Repositories namespace
    Invoke-WithRetry { Invoke-RestMethod -Header $AuthenicationHeader -Uri "https://dev.azure.com/$Organization/_apis/AccessControlEntries/2e9eb7ed-3c0a-47d4-87c1-0ffdd275fd87?api-version=5.0" -Method Post -ContentType "application/json" -Body @"
    {
        "token": "repoV2/$ProjectId/",
        "merge": true,
        "accessControlEntries": [
            {
                "descriptor": "$identityDescriptor",
                "allow": $PermissionNumber,
                "deny": 0,
                "extendedInfo": {
                    "effectiveAllow": $PermissionNumber,
                    "effectiveDeny": 0,
                    "inheritedAllow": $PermissionNumber,
                    "inheritedDeny": 0
                }
            }
        ]
    }
"@
    } | Out-Null
}

$projectIdCache = @{}
function Get-ProjectId {
    param(
        [string]$Organization,
        [string]$Project
    )

    if (!$projectIdCache.$Project) {
        Write-Host "Getting project id for Organization: $Organization project: $Project"
        $projectIdCache.$Project = ((Invoke-RestMethod -Header $AuthenicationHeader -Uri "https://dev.azure.com/$Organization/_apis/projects?api-version=6.1-preview.4" -Method Get).value |? { $_.name -eq "$Project" }).id
    }
    return $projectIdCache.$Project
}


function Get-AzureKeyVaultSecret {
    param(
        [string]$KeyVaultSecretUri
    )

    $token = Get-SimeonAzureADAccessToken -Resource 'KeyVault'
    Write-Information "Getting keyvault secret access token from Uri: $KeyVaultSecretUri"
    $secret = (Invoke-WithRetry { Invoke-RestMethod -Header @{Authorization = "Bearer $token" } -Uri "$KeyVaultSecretUri`?api-version=7.1" -Method Get }).Value

    return $secret
}

<#
.SYNOPSIS
    Creates and/or configures the provided Azure DevOps organization to be compatible with Simeon Cloud
#>
function Install-SimeonDevOpsOrganization {
    param (
        [ValidateNotNullOrEmpty()]
        [string]$Organization,
        [string]$Project = "Tenants",
        [string]$GitHubAccessTokenKeyVaultUrl = "https://installer.vault.azure.net/secrets/$Organization",
        [string]$ReportingEmailPasswordKeyVaultUrl = "https://installer.vault.azure.net/secrets/ReportingEmailPw",
        # List of user email addresses to invite to the DevOps organization and make project collection admins
        [string][]$InviteToOrgAsAdmin = "devops@simeoncloud.com",
        [string]$PipelineNotificationEmail = "pipelinenotifications@simeoncloud.com"
    )

    Write-Information "Getting required values from Key Vault"
    Invoke-Command -ScriptBlock {
        Write-Information "Getting GitHub access token"
        $gitHubAccessToken = (Get-AzureKeyVaultSecret -KeyVaultSecretUri $GitHubAccessTokenKeyVaultUrl)
        if (!$gitHubAccessToken) {
            throw "Please check that the DevOps organization is correct or contact Simeon Support for a trial."
        }

        Write-Information "Getting reporting email password"
        $reportingEmailPw = (Get-AzureKeyVaultSecret -KeyVaultSecretUri $ReportingEmailPasswordKeyVaultUrl)
        if (!$reportingEmailPw) {
            throw "Unable to retrieve reporting email password please contact Simeon Support for assistance."
        }
    }

    $token = Get-SimeonAzureDevOpsAccessToken
    $AuthenicationHeader = @{Authorization = "Bearer $token" }

    # Check for org, create if it doesn't exist
    Write-Information "Validating DevOps organization"
    Invoke-Command -ScriptBlock {
        Write-Information "Checking if Organization: $Organization is available"
        $existingOrg = Invoke-WithRetry { Invoke-RestMethod -Header $AuthenicationHeader -Uri "https://aex.dev.azure.com/_apis/HostAcquisition/NameAvailability/$Organization" -Method Get }
        if (!$existingOrg.isAvailable) {
            $currentUserId = (Invoke-WithRetry { Invoke-RestMethod -Header $AuthenicationHeader -Uri "https://app.vssps.visualstudio.com/_apis/profile/profiles/me?api-version=5.1" -Method Get }).id
            $accessToOrgs = (Invoke-WithRetry { Invoke-RestMethod -Header $AuthenicationHeader -Uri "https://app.vssps.visualstudio.com/_apis/accounts?memberId=$currentUserId&api-version=5.1" -Method Get }).value
            if ($accessToOrgs.accountName -contains "$Organization") {
                Write-Information "DevOps Organization: $Organization exists and current user has access"
            }
            else {
                throw "DevOps Organization: $Organization exists but the current user does not have access to $Organization"
            }
        }
        else {
            Write-Information "Creating DevOps Organization: $Organization"
            Invoke-WithRetry { Invoke-RestMethod -Headers $AuthenicationHeader -ContentType "application/json" -Method Post -Uri "https://aex.dev.azure.com/_apis/HostAcquisition/Collections?collectionName=$Organization`&api-version=5.0-preview.2" -Body @"
                {
                    "VisualStudio.Services.HostResolution.UseCodexDomainForHostCreation": "true",
                    "CampaignId": "",
                    "AcquisitionId": $(New-Guid),
                    "SignupEntryPoint": "WebSuite"
                }
"@
            } | Out-Null
        }
    }

    Write-Information "Inviting users to org and setting permissions."
    Invoke-Command -ScriptBlock {
        $groups = (Invoke-WithRetry { Invoke-RestMethod -Header $AuthenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/groups?api-version=6.1-preview.1" -Method Get }).value
        foreach ($userToInvite in $InviteToOrgAsAdmin) {
            # Send invite to org
            Write-Information "Sending invite to DevOps Organization: $Organization for user: $userToInvite"
            Invoke-WithRetry { Invoke-RestMethod -Header $AuthenicationHeader -Uri "https://vsaex.dev.azure.com/$Organization/_apis/UserEntitlements?api-version=5.1-preview.3" -Method Patch -ContentType "application/json-patch+json" -Body @"
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
                        "principalName": "$userToInvite",
                        "subjectKind": "user"
                    }
                }
            }
        ]
"@
            } | Out-Null

            # assign project collection admin
            Write-Information "Making user: $userToInvite Project Collection Admin"
            $projectCollectionAdminGroupDescriptor = ($groups |? displayname -eq "Project Collection Administrators").descriptor
            $userToInviteDescriptor = ((Invoke-WithRetry { Invoke-RestMethod -Header $AuthenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/users?api-version=6.1-preview.1" -Method Get }).value |? principalName -eq "$userToInvite").descriptor
            Invoke-WithRetry { Invoke-RestMethod -Header $AuthenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/memberships/$userToInviteDescriptor/$projectCollectionAdminGroupDescriptor`?api-version=6.1-preview.1" -Method Put } | Out-Null
        }
    }

    Write-Information "Setting project information"
    Invoke-Command -ScriptBlock {
        # Set or get Project id
        $projectId = (Get-ProjectId -Organization $Organization -ProjectName $Project)
        if (!$projectId) {
            Write-Information "Creating project: $Project"
            Invoke-WithRetry { Invoke-RestMethod -Header $AuthenicationHeader -Uri "https://dev.azure.com/$Organization/_apis/projects?api-version=6.1-preview.4" -Method Post -ContentType "application/json" -Body @"
                {
                    "name": "$Project",
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
            } | Out-Null
            # Get projectId after creating
            $projectId = (Get-ProjectId -Organization $Organization -ProjectName $Project)
            # Repositories > rename $Project to default
            Write-Information "Renaming the repository: $Project to default"
            $repos = (Invoke-WithRetry { Invoke-RestMethod -Header $AuthenicationHeader -Uri "https://dev.azure.com/$Organization/$projectId/_apis/git/repositories?api-version=6.0" -Method Get }).value
            if ($repos.name -contains "$Project") {
                $repoId = ($repos |? { $_.name -eq "$Project" }).id
                Invoke-WithRetry { Invoke-RestMethod  -Headers $AuthenicationHeader -Uri "https://dev.azure.com/$Organization/$projectId/_apis/git/repositories/$repoId`?api-version=5.0" -Method Patch -Body '{"name":"Default"}' -ContentType "application/json" } | Out-Null
            }

            # Overview > uncheck Boards and Test Plans
            Write-Information "Updating project settings turning off Boards and Test Plans"
            Invoke-WithRetry { Invoke-RestMethod -Header $AuthenicationHeader -Uri "https://dev.azure.com/$Organization/_apis/FeatureManagement/FeatureStates/host/project/$projectId/ms.vss-work.agile?api-version=4.1-preview.1" -Method Patch -ContentType "application/json" -Body @"
                {
                    "featureId": "ms.vss-work.agile",
                    "scope": {
                        "settingScope": "project",
                        "userScoped": false
                    },
                    "state": 0
                }
"@
            } | Out-Null

            # Overview > uncheck Artifacts
            Write-Information "Updating project settings turning off Artifacts"
            Invoke-WithRetry { Invoke-RestMethod -Header $AuthenicationHeader -Uri "https://dev.azure.com/$Organization/_apis/FeatureManagement/FeatureStates/host/project/$projectId/ms.feed.feed?api-version=4.1-preview.1" -Method Patch -ContentType "application/json" -Body @"
                {
                    "featureId": "ms.feed.feed",
                    "scope": {
                        "settingScope": "project",
                        "userScoped": false
                    },
                    "state": 0
                }
"@
            } | Out-Null
        }
    }

    ## Project settings
    Write-Information "Configuring pipeline settings"
    Invoke-Command -ScriptBlock {
        # Pipelines > Settings > uncheck Limit job authorization scope to current project for non-release pipelines (enforceReferencedRepoScopedToken), Limit job authorization scope to referenced Azure DevOps repositories (enforceJobAuthScope), and Limit variables that can be set at queue time (enforceSettableVar)
        Write-Information "Limiting job authorization scope to current project for non-release pipelines"
        Invoke-WithRetry { Invoke-RestMethod -Header $AuthenicationHeader -Uri "https://dev.azure.com/$Organization/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1" -Method Post -ContentType "application/json" -Body @"
            {
                "contributionIds": [
                    "ms.vss-build-web.pipelines-general-settings-data-provider"
                ],
                "dataProviderContext": {
                    "properties": {
                        "enforceSettableVar": "false",
                        "enforceJobAuthScope": "false",
                        "enforceJobAuthScopeForReleases": "false",
                        "sourcePage": {
                            "url": "https://dev.azure.com/$Organization/$Project/_settings/settings",
                            "routeId": "ms.vss-admin-web.project-admin-hub-route",
                            "routeValues": {
                                "project": "$Project",
                                "adminPivot": "settings",
                                "controller": "ContributedPage",
                                "action": "Execute"
                            }
                        }
                    }
                }
            }
"@
        } | Out-Null
    }

    Write-Information "Updating project permissions"
    Invoke-Command -ScriptBlock {
        $projectId = (Get-ProjectId -Organization $Organization -ProjectName $Project)
        $users = (Invoke-WithRetry { Invoke-RestMethod -Header $AuthenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/users?api-version=6.1-preview.1" -Method Get }).value
        $groups = (Invoke-WithRetry { Invoke-RestMethod -Header $AuthenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/groups?api-version=6.1-preview.1" -Method Get }).value

        #  Permissions > Contributors > Members > Add > $Project Build Service
        ### Contributors group actions
        Write-Information "Configuring permissions for Contributors group"
        Write-Information "Adding $Project Build Service ($Organization)"
        $contributorsgroupDescriptor = ($groups |? principalName -eq "[$Project]\Contributors").descriptor
        $buildServiceUserDescriptor = ($users |? displayName -like "$Project Build Service (*").descriptor
        Invoke-WithRetry { Invoke-RestMethod -Header $AuthenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/memberships/$buildServiceUserDescriptor/$contributorsgroupDescriptor`?api-version=6.1-preview.1" -Method Put } | Out-Null
        # Repositories > Permissions > Contributors > allow Create repository

        Set-AzureDevOpsAccessControlEntry -Organization $Organization -ProjectId $projectId -SubjectGroupPrincipalName "[$Project]\Contributors" -PermissionNumber 256 -PermissionDescription "Create Repository"
        Set-AzureDevOpsAccessControlEntry -Organization $Organization -ProjectId $projectId -SubjectGroupPrincipalName "[$Organization]\Project Collection Administrators" -PermissionNumber 8 -PermissionDescription "Force Push"
        Set-AzureDevOpsAccessControlEntry -Organization $Organization -ProjectId $projectId -SubjectGroupPrincipalName "[$Project]\Contributors" -PermissionNumber 8 -PermissionDescription "Force Push"

        # Pipelines > Settings > uncheck Limit job authorization scope to current project for non-release pipelines
        Write-Information "Unchecking Limit job authorization scope to current project for non-release pipelines"
        # Limit job authorization scope to referenced Azure DevOps repositories
        Invoke-WithRetry { Invoke-RestMethod -Header $AuthenicationHeader -Uri "https://dev.azure.com/$Organization/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1" -Method Post -ContentType "application/json" -Body @"
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
                            "url": "https://dev.azure.com/$Organization/$Project/_settings/settings",
                            "routeId": "ms.vss-admin-web.project-admin-hub-route",
                            "routeValues": {
                                "project": "$Project",
                                "adminPivot": "settings",
                                "controller": "ContributedPage",
                                "action": "Execute"
                            }
                        }
                    }
                }
            }
"@
        } | Out-Null
    }

    # Create Service connection
    Write-Information "Creating GitHub Service connection"
    Install-SimeonGitHubServiceConnection -Organization $Organization -Project $Project -GitHubAccessToken $gitHubAccessToken

    # Install Retry failed Pipelines
    Write-Information "Installing retry pipelines"
    Install-SimeonRetryPipeline -Organization $Organization

    # Install SummaryReport pipeline
    Write-Information "Installing reporting pipeline"
    Install-SimeonReportingPipeline -FromEmailAddress 'noreply@simeoncloud.com' -FromEmailPw $reportingEmailPw -ToBccAddress '70e1ed48.simeoncloud.com@amer.teams.ms' -Organization $Organization

    Write-Information "Updating permissions for GitHub service connection"
    Invoke-Command -ScriptBlock {
        $projectId = (Get-ProjectId -Organization $Organization -ProjectName $Project)
        $groups = (Invoke-WithRetry { Invoke-RestMethod -Header $AuthenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/groups?api-version=6.1-preview.1" -Method Get }).value

        # Navigate to Project settings > Service connections > ... > Security > Add > Contributors > set role to Administrator > Add
        Write-Information "Making Contributors admin for GitHub service connection"
        $contributorsGroupId = ($groups |? principalName -eq "[$Project]\Contributors").originId
        Invoke-WithRetry { Invoke-RestMethod -Header $AuthenicationHeader -Uri "https://dev.azure.com/$Organization/_apis/securityroles/scopes/distributedtask.project.serviceendpointrole/roleassignments/resources/$projectId`?api-version=5.0-preview.1" -Method Put -ContentType "application/json" -Body @"
            [
                {
                    "roleName": "Administrator",
                    "userId": "$contributorsGroupId"
                }
            ]
"@
        } | Out-Null
    }

    # Install code search Organization settings > Extensions > Browse marketplace > search for Code Search > Get it free
    Write-Information "Installing code search"
    Invoke-Command -ScriptBlock {
        Invoke-WithRetry { Invoke-RestMethod -Header $AuthenicationHeader -Uri "https://extmgmt.dev.azure.com/$Organization/_apis/ExtensionManagement/AcquisitionRequests?api-version=6.1-preview.1" -Method Post -ContentType "application/json" -Body @"
            {
                "assignmentType": 0,
                "billingId": null,
                "itemId": "ms.vss-code-search",
                "operationType": 1,
                "quantity": 0,
                "properties": {}
            }
"@
        } | Out-Null
    }

    Write-Information "Updating notification settings"
    Invoke-Command -ScriptBlock {
        $projectId = (Get-ProjectId -Organization $Organization -ProjectName $Project)
        $groups = (Invoke-WithRetry { Invoke-RestMethod -Header $AuthenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/groups?api-version=6.1-preview.1" -Method Get }).value

        # Project settings > Notifications > New subscription > Build > A build completes > Next > change 'Deliver to' to custom email address > pipelinenotifications@simeoncloud.com
        $existingSubscriptions = (Invoke-WithRetry { Invoke-RestMethod -Header $AuthenicationHeader -Uri "https://dev.azure.com/$Organization/_apis/notification/Subscriptions?api-version=6.1-preview.1" -Method Get }).value
        # Need to get address long way due to this https://github.com/PowerShell/PowerShell/issues/8105
        $subExists = ((($existingSubscriptions |? { $_.description -eq "A build completes" }).channel | Select -Property address) |? { $_ -match "$PipelineNotificationEmail" })
        if (!$subExists) {
            Write-Information "Creating build completed notification for $PipelineNotificationEmail"
            $projectTeamGroupId = ($groups |? { $_.PrincipalName -eq "[$Project]\$Project Team" }).originId

            Invoke-WithRetry { Invoke-RestMethod -Header $AuthenicationHeader -Uri "https://dev.azure.com/$Organization/_apis/notification/Subscriptions?api-version=6.1-preview.1" -Method Post -ContentType "application/json" -Body  @"
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
                    "displayName": "[$Project]\\$Project Team",
                    "id": "$projectTeamGroupId",
                    "uniqueName": "vstfs://Classification/TeamProject/$projectId\\$Project Team",
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
"@ } | Out-Null
        }

        # Disable pipeline notifications
        # Build completes
        Write-Information "Disabling build completes pipeline notifications"
        Invoke-WithRetry { Invoke-RestMethod -Header $AuthenicationHeader -Uri "https://dev.azure.com/$Organization/_apis/notification/Subscriptions/ms.vss-build.build-requested-personal-subscription/UserSettings/$projectTeamGroupId`?api-version=6.1-preview.1" -Method Put -ContentType "application/json" -Body '{"optedOut":true}' }| Out-Null
        # Pull requests
        Write-Information "Disabling pull request pipeline notifications"
        Invoke-WithRetry { Invoke-RestMethod -Header $AuthenicationHeader -Uri "https://dev.azure.com/$Organization/_apis/notification/Subscriptions/ms.vss-code.pull-request-updated-subscription/UserSettings/$projectTeamGroupId`?api-version=6.1-preview.1" -Method Put -ContentType "application/json" -Body '{"optedOut":true}' }| Out-Null
    }
}