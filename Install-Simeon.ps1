$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Install-AzureModule {
    # Install required modules
    $requiredModules = @(
        @{ Name = 'Az.Resources' }
    )
    if ($PSVersionTable.PSEdition -eq 'Core') {
        Register-PackageSource -Name PoshTestGallery -Location https://www.poshtestgallery.com/api/v2/ -ProviderName PowerShellGet -Force | Out-Null
        $requiredModules += @{ Name = 'AzureAD.Standard.Preview'; RequiredVersion = '0.0.0.10'; Repository = 'PoshTestGallery' }
    }
    else {
        $requiredModules += @{ Name = 'AzureAD' }
    }

    foreach ($m in $requiredModules) {
        if (!$m.Repository) { $m.Repository = 'PSGallery' }
        if (!(Get-Module $m.Name -ListAvailable | ? { !$m.RequiredVersion -or $m.RequiredVersion -eq $_.Version })) { 
            Write-Host "Installing module $($m.Name)"
            Install-Module @m -Scope CurrentUser -Force | Out-Null
        }
        $m.Remove('Repository')            
        Import-Module @m
    }
}

function Get-AzProfileContext {
    [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile.DefaultContext
}

function Get-AzContextToken {
    param(
        [string]$Resource
    )
    # Gets an OAuth token using the existing AzContext
    $context = Get-AzProfileContext
    [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id.ToString(), $null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, $Resource).AccessToken
}

function Connect-AzureADUsingAzContext {
    # Connects to AzureAD PS module using existing AzContext token
    $context = Get-AzProfileContext
    Connect-AzureAD -AadAccessToken (Get-AzContextToken 'https://graph.windows.net/') -AccountId $context.Account.Id -TenantId $context.Tenant.Id
}

function Resolve-AzureTenantId {
    param(
        [ValidateNotNullOrEmpty()]
        [string]$Id
    )
    # Resolves tenant domain name to id
    [Guid]$g = [Guid]::Empty
    if ([Guid]::TryParse($Id, [ref]$g)) { return $Id }
    $endpoint = (irm "https://login.microsoftonline.com/$Id/v2.0/.well-known/openid-configuration").token_endpoint
    $result = [uri]::new($endpoint).PathAndQuery -split '/' | ? { $_ } | Select -First 1
    if (!$result) { throw "Could not resolve tenant id for $Id." }
    Write-Host "Resolved tenant id from $Id to $result"
    return $result
}

function Set-SimeonServiceAccount {
    param(
        [ValidateNotNullOrEmpty()]
        [string]$Organization,
        [ValidateNotNullOrEmpty()]
        [string]$Project,
        [ValidateNotNullOrEmpty()]
        [string]$Tenant        
    )
    # Creates/updates service account and required permissions

    $TenantId = Resolve-AzureTenantId $Tenant
    Connect-AzAccount -Tenant $TenantId
    <#
    try {
        if ((Set-AzContext -Tenant $TenantId).Tenant.Id -ne $TenantId) { Connect-AzAccount -Tenant $TenantId | Out-Null }
    }
    catch {
        Connect-AzAccount -Tenant $TenantId | Out-Null
    }
    #>
    Set-AzContext -Tenant $TenantId | Out-Null
    
    Connect-AzureADUsingAzContext | Out-Null

    Write-Host "Connected to Azure tenant $Tenant"

    # Create/update Azure AD user with random password
    $user = Get-AzureADUser -Filter "displayName eq 'Simeon Service Account'"
    $upn = "simeon@$(Get-AzureADDomain |? IsDefault -eq $true | Select -ExpandProperty Name)"
    $password = [Guid]::NewGuid().ToString("N").Substring(0, 10) + "Ul!"
    Write-Host "Using password $password"

    if (!$user) {
        Write-Host "Creating user $upn"
        $user = New-AzureADUser -DisplayName 'Simeon Service Account' `
            -UserPrincipalName $upn `
            -MailNickName simeon -AccountEnabled $true `
            -PasswordProfile @{ Password = $password; ForceChangePasswordNextLogin = $false } -PasswordPolicies DisablePasswordExpiration
    }
    else {
        Write-Host "User $upn already exists - updating user password"
        $user | Set-AzureADUser -PasswordProfile @{ Password = $password; ForceChangePasswordNextLogin = $false } -PasswordPolicies DisablePasswordExpiration
    }

    # this can sometimes fail on first request
    try { Get-AzureADDirectoryRole | Out-Null } catch { }

    # Make sure Directory Synchronization Accounts role is activated 
    if (!(Get-AzureADDirectoryRole | ? DisplayName -eq 'Directory Synchronization Accounts')) { 
        Write-Host "Activating role Directory Synchronization Accounts"
        Get-AzureADDirectoryRoleTemplate | ? DisplayName -eq 'Directory Synchronization Accounts' | % { Enable-AzureADDirectoryRole -RoleTemplateId $_.ObjectId -EA SilentlyContinue | Out-Null }
    }

    # Add to Company Administrator (aka Global Admin) role for administration purposes and Directory Synchronization Accounts role so account is excluded from MFA 
    Get-AzureADDirectoryRole | ? { $_.DisplayName -in @('Company Administrator', 'Directory Synchronization Accounts') } | % { 
        if (!(Get-AzureADDirectoryRoleMember -ObjectId $_.ObjectId | ? ObjectId -eq $user.ObjectId)) {
            Write-Host "Adding to directory role $($_.DisplayName)"
            Add-AzureADDirectoryRoleMember -ObjectId $_.ObjectId -RefObjectId $user.ObjectId | Out-Null
        }
        else {
            Write-Host "Already has directory role $($_.DisplayName)"
        }
    }

    # Find Azure RM subscription to use 
    $subscriptionId = Get-AzSubscription -Tenant $TenantId | ? State -eq Enabled | Sort-Object Name | Select -First 1 -ExpandProperty Id
    if (!$subscriptionId) {
        Write-Host "Elevating access to allow assignment of subscription roles"
        # Elevate access to see all subscriptions in the tenant and force re-login
        irm 'https://management.azure.com/providers/Microsoft.Authorization/elevateAccess?api-version=2016-07-01' -Method Post -Headers @{ Authorization = "Bearer $(Get-AzContextToken 'https://management.azure.com/')" }
        Connect-AzAccount -Tenant $TenantId | Out-Null        
        $subscriptionId = Get-AzSubscription -Tenant $TenantId | ? State -eq Enabled | Sort-Object Name | Select -First 1 -ExpandProperty Id
    }

    # Add as contributor to an Azure RM Subscription
    if (!(Get-AzRoleAssignment -SignInName $upn -RoleDefinitionName 'Contributor' -Scope "/subscriptions/$subscriptionId")) {
        Write-Host "Adding to Contributor role on subscription $subscriptionId"
        New-AzRoleAssignment -SignInName $upn -RoleDefinitionName 'Contributor' -Scope "/subscriptions/$subscriptionId" | Out-Null
    }
    else {
        Write-Host "Already has Contributor role on subscription $subscriptionId"
    }
}

function Get-SimeonAzureDevOpsAccessToken {
    # Gets an OAuth token to make API calls to Azure DevOps
    # Needs to run as a job (external process) because a bug in .NET Core keeps a reservation on the http endpoint even after the http listener is disposed (until process exits)

    $job = Start-Job -ScriptBlock {
        $http = [System.Net.HttpListener]::new() 
        $http.Prefixes.Add("http://localhost:3546/")
        $http.Start()

        try {
            # initiate browser request for token
            $appId = '26D8E4BF-3432-4640-B58E-2ADA3FEC36B4'
            $redirectUri = 'https://simeondevopsapi.azurewebsites.net/api/oauth2/callback'
            $scope = 'vso.analytics vso.auditlog vso.build_execute vso.code_full vso.code_status vso.connected_server vso.dashboards_manage vso.entitlements vso.environment_manage vso.extension.data_write vso.extension_manage vso.gallery_acquire vso.gallery_manage vso.graph_manage vso.identity_manage vso.loadtest_write vso.machinegroup_manage vso.memberentitlementmanagement_write vso.notification_diagnostics vso.notification_manage vso.packaging_manage vso.profile_write vso.project_manage vso.release_manage vso.securefiles_manage vso.security_manage vso.serviceendpoint_manage vso.symbols_manage vso.taskgroups_manage vso.test_write vso.tokenadministration vso.tokens vso.variablegroups_manage vso.wiki_write vso.work_full'
            $state = [Guid]::NewGuid()
            $authorizeUrl = "https://app.vssps.visualstudio.com/oauth2/authorize?client_id=$appId&response_type=Assertion&state=$state&scope=$scope&redirect_uri=$redirectUri"
            Start-Process $authorizeUrl

            # listen for callback
            while ($http.IsListening) {
                Write-Host "Waiting for DevOps authentication callback"
                $context = $http.GetContext()

                Write-Host "Received DevOps authentication callback"
                $inputData = [System.IO.StreamReader]::new($context.Request.InputStream).ReadToEnd()
   
                if ($inputData -like 'access_token=*') { 
                    $accessToken = $inputData.Substring('access_token='.Length)

                    $html = "<html><body><h3>DevOps authentication successful</h3></body></html>" 
                } 
                else {
                    $html = "<html><body><h3>Could not obtain DevOps access token</h3></body></html>"
                }

                $html += @"
<script type='text/javascript'>
    setTimeout(function() { window.close() }, 1500);
</script> 
"@

                $buffer = [System.Text.Encoding]::UTF8.GetBytes($html) 
                $context.Response.ContentLength64 = $buffer.Length
                $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
                $context.Response.OutputStream.Close()
            
                if (!$accessToken) {
                    throw "Could not obtain DevOps access token"
                }

                return $accessToken
            } 
        }
        finally {
            $http.Dispose()
        }
    } 
    $job | Receive-Job -Wait
    $job | Remove-Job
}

function Set-SimeonAzureDevOpsResources {
    param(
        [ValidateNotNullOrEmpty()]
        [string]$Organization,
        [ValidateNotNullOrEmpty()]
        [string]$Project,
        [ValidateNotNullOrEmpty()]
        [string]$Tenant,
        [ValidateNotNullOrEmpty()]
        [string]$Password,
        [switch]$IsBaseline
    )    
    # Creates repo and pipelines and stores service account password

    $token = Get-SimeonAzureDevOpsAccessToken

    $restProps = @{
        Headers = @{ Authorization = "Bearer $token" }
        ContentType = 'application/json'
    }
    $queryString = "?api-version=5.1-preview.1"
    $apiBaseUrl = "https://dev.azure.com/$Organization/$Project/_apis"

    $projects = irm @restProps "https://dev.azure.com/$Organization/_apis/projects$queryString"   
    $projectId = $projects.value | ? name -eq $Project | Select -ExpandProperty id
    if (!$projectId) {
        throw "Could not find project $Project in organization $Organization"
    }

    $repos = irm @restProps "$apiBaseUrl/git/repositories$queryString"
    $repoName = $Tenant
    if ($IsBaseline) {
        $repoName = 'baseline'
    }
    $repo = $repos.value | ? name -eq $repoName

    if (!$repo) {
        Write-Host "Creating repository $repoName"
        $repo = irm @restProps "$apiBaseUrl/git/repositories$queryString" -Method Post -Body (@{
                name = $repoName
                project = @{
                    id = $projectId
                    name = $Project
                }            
            } | ConvertTo-Json)
    }
    else {
        Write-Host "Repository $repoName already exists - will not create"
    }

    $importUrl = 'https://github.com/simeoncloud/DefaultTenant.git'
    if ($IsBaseline) {
        $importUrl = 'https://github.com/simeoncloud/Baseline.git' 
    }
    
    try {
        irm @restProps "$apiBaseUrl/git/repositories/$($repo.id)/importRequests$queryString" -Method Post -Body (@{
                parameters = @{
                    gitSource = @{
                        overwrite = $false
                        url = $importUrl
                    }
                }
            } | ConvertTo-Json) | Out-Null

        Write-Host "Importing repository contents from $importUrl"                
    }
    catch {
        if ($_.Exception.Response.StatusCode -ne 'Conflict') {
            throw
        }
        Write-Host "Repository is not empty - will not import"
    }

    $serviceEndpoint = (irm @restProps "$apiBaseUrl/serviceendpoint/endpoints$queryString").value |? name -eq 'simeoncloud'
    
    if (!$serviceEndpoint) { throw "Could not find service connection to simeoncloud GitHub." }

    $baselineRepo = $repos |? name -eq 'baseline'

    $pipelines = irm @restProps "$apiBaseUrl/build/definitions$queryString"

    foreach ($action in @('Deploy')) {        
        $pipelineName = "$repoName - $action"
        
        $pipeline = $pipelines.value |? name -eq $pipelineName

        if (!$pipeline) {
            Write-Host "Creating pipeline $pipelineName"      
            $pipeline = irm @restProps "$apiBaseUrl/build/definitions$queryString" -Method Post -Body (@{
                    name = $pipelineName
                    path = $Tenant
                    repository = "https://github.com/simeoncloud/AzurePipelines.git"
                    uri = "M365Management$($action).yml"
                } | ConvertTo-Json)
        }
        else {
            Write-Host "Pipeline $pipelineName already exists - updating variables"
            #  irm @restProps "$apiBaseUrl/build/definitions/$($pipeline.id)$queryString"

        }
    }    
}

function Install-Simeon {
    param(
        # The organization name that appears in DevOps - e.g. 'simeon-orgName'
        [ValidateNotNullOrEmpty()]
        [string]$Organization = (& { if ($script:Organization) { $script:Organization } else { Read-Host 'Enter Azure DevOps organization name' } }),
        # The project name that appears in DevOps - usually 'Tenants'
        [ValidateNotNullOrEmpty()]
        [string]$Project = 'Tenants',
        [ValidateNotNullOrEmpty()]
        # The Azure tenant domain name to configure Simeon for - e.g. 'contoso.com or contoso.onmicrosoft.com'
        [string]$Tenant = (Read-Host 'Enter tenant domain name'),
        # Indicates that this tenant is to be used as a baseline - affects the naming of the repository and pipelines in Azure DevOps
        [switch]$IsBaseline
    )
    <#
    .SYNOPSIS
    Prepares a tenant for use with Simeon.
    - Creates/updates a service account with random password
    - Adds the service account as a Company Administrator
    - Adds the service account as a Contributor to the first available Azure RM subscription
    - Creates necessary DevOps repositories and pipelines and securely stored service account credentials
    #>

    $script:Organization = $Organization

    Set-SimeonServiceAccount -Organization $Organization -Project $Project -Tenant $Tenant

    # Take password and set it in pipeline or library
    #Set-SimeonAzureDevOpsResources -Organization $Organization -Project $Project -Tenant $TenantId -Password $password -IsBaseline:$IsBaseline
}
