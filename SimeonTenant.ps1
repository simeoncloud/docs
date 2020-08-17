#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

New-Module -Name 'SimeonTenant' -ScriptBlock {
    $ErrorActionPreference = 'Stop'
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    function Read-HostBooleanValue {
        param(
            [ValidateNotNullOrEmpty()]
            [string]$Prompt      
        )    
        $line = ''
        while ($line -notin @('y', 'n')) {
            Write-Host $Prompt            
            $line = Read-Host "Y [Yes]  N [No]"
        }
        if ($line -eq 'Y') { return $true }
        return $false    
    }

    function Read-Tenant {
        Read-Host 'Enter tenant primary domain name (e.g. contoso.com or contoso.onmicrosoft.com)'
    }

    function Read-Organization {
        Read-Host 'Enter Azure DevOps organization name'
    }

    function Wait-EnterKey {
        param(
            [ValidateNotNullOrEmpty()]
            [string]$Message
        )
        $writeArgs = @{}
        if ($ConfirmPreference -ne 'None') {
            $Message += " - press Enter to continue..."
            $writeArgs['NoNewline'] = $true
        }
        
        Write-Host "$Message" -ForegroundColor Green @writeArgs
        
        if ($ConfirmPreference -ne 'None') {
            Read-Host | Out-Null
        }
    }

    function Install-AzureModule {         
        if (!(Get-Module PowerShellGet -ListAvailable |? { $_.Version.Major -ge 2 })) {
            Write-Host "Updating PowerShellGet"
            Install-Module PowerShellGet -Force -Scope CurrentUser -Repository PSGallery -AllowClobber -WarningAction SilentlyContinue            
        }

        if ($PSVersionTable.PSEdition -ne 'Core' -and !(Get-PackageProvider NuGet -ListAvailable)) {
            Write-Host "Installing NuGet package provider"
            Install-PackageProvider NuGet -Force -ForceBootstrap | Out-Null
        }
    
        # Install required modules
        $requiredModules = @(
            @{ Name = 'Az.Resources' }
            @{ Name = 'MSAL.PS' }
        )
        if ($PSVersionTable.PSEdition -eq 'Core') {
            Get-PackageSource |? Location -eq 'https://www.poshtestgallery.com/api/v2/' | Unregister-PackageSource -Force
            Register-PackageSource -Name PoshTestGallery -Location https://www.poshtestgallery.com/api/v2/ -ProviderName PowerShellGet -Force | Out-Null
            $requiredModules += @{ Name = 'AzureAD.Standard.Preview'; RequiredVersion = '0.0.0.10'; Repository = 'PoshTestGallery' }
        }
        else {
            $requiredModules += @{ Name = 'AzureAD' }
        }

        foreach ($m in $requiredModules) {
            if (!$m.Repository) { $m.Repository = 'PSGallery' }
            if (!(Get-Module $m.Name -ListAvailable |? { !$m.RequiredVersion -or $m.RequiredVersion -eq $_.Version })) { 
                Write-Host "Installing module '$($m.Name)'"
                Install-Module @m -Scope CurrentUser -Force -AllowClobber -AcceptLicense | Out-Null
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

    $TenantIdCache = @{}
    function Resolve-AzureTenantId {
        param(
            [ValidateNotNullOrEmpty()]
            [string]$Tenant
        )
        # Resolves tenant domain name to id
        [Guid]$g = [Guid]::Empty
        if ([Guid]::TryParse($Tenant, [ref]$g)) { return $Tenant }
    
        if ($TenantIdCache.ContainsKey($Tenant)) { return $TenantIdCache[$Tenant] }
    
        $endpoint = (irm "https://login.microsoftonline.com/$Tenant/v2.0/.well-known/openid-configuration").token_endpoint
        $result = [uri]::new($endpoint).PathAndQuery -split '/' |? { $_ } | Select -First 1
        if (!$result) { throw "Could not resolve tenant id for $Tenant." }
        $TenantIdCache[$Tenant] = $result
        Write-Host "Resolved tenant id for '$Tenant' to '$result'"
        return $result
    }

    function Connect-Azure {
        param(
            [string]$Tenant,
            [switch]$Force
        )
    
        Install-AzureModule

        $TenantId = Resolve-AzureTenantId $Tenant

        while ($Force -or (Set-AzContext -Tenant $TenantId -WarningAction SilentlyContinue -EA SilentlyContinue).Tenant.Id -ne $TenantId) { 
            Wait-EnterKey "Connecting to Azure Tenant '$Tenant' - sign in using an account with the 'Global administrator' Azure Active Directory role and 'Contributor' access to an Azure Subscription" -ForegroundColor Green -NoNewline
            Connect-AzAccount -Tenant $TenantId | Out-Null
            $Force = $false
        }
    
        Set-AzContext -Tenant $TenantId | Out-Null
    
        Connect-AzureADUsingAzContext | Out-Null

        Write-Host "Connected to Azure tenant '$Tenant' using account '$((Get-AzContext).Account.Id)'"
    }

    function Test-AzureADCurrentUserRole {
        param(
            [ValidateNotNullOrEmpty()]
            [string]$Name        
        )    
        $token = Get-AzContextToken 'https://graph.microsoft.com'
        $value = @()
        $url = "https://graph.microsoft.com/beta/me/memberOf"
        while ($url) {
            $res = irm $url -Method Get -Headers @{ Authorization = "Bearer $token" }     
            if ($res.value) { $value += $res.value }
            $url = $res."@odata.nextLink"
        }
        return [bool]($value |? '@odata.type' -eq '#microsoft.graph.directoryRole' |? displayName -eq $Name)
    }

    function Get-SimeonTenantServiceAccountAzureSubscriptionId {
        param(
            [string]
            $Id
        )
        Get-AzSubscription -Tenant ((Get-AzContext).Tenant.Id) |? { $_.Name -ne 'Access to Azure Active Directory' -and $_.State -eq 'Enabled' -and (!$Id -or $Id -eq $_.Name -or $Id -eq $_.Id) } | Sort-Object Name | Select -First 1 -ExpandProperty Id
    }

    function Install-SimeonTenantServiceAccount {
        param(
            # The Azure tenant domain name to configure Simeon for
            [ValidateNotNullOrEmpty()]
            [string]$Tenant = (Read-Tenant),
            # The name or id of the subscription for Simeon to use
            [string]$Subscription       
        )
        # Creates/updates service account and required permissions

        Write-Host "Installing Simeon service account for tenant '$Tenant'"

        Connect-Azure $Tenant
    
        while (!(Test-AzureADCurrentUserRole 'Company Administrator')) {            
            Write-Warning "Could not access Azure Active Directory '$Tenant' with sufficient permissions - please make sure you signed in using an account with the 'Global administrator' role."
            Connect-Azure $Tenant -Force
        }

        # Create/update Azure AD user with random password
        $user = Get-AzureADUser -Filter "displayName eq 'Simeon Service Account'"
        $upn = "simeon@$Tenant"
        $password = [Guid]::NewGuid().ToString("N").Substring(0, 10) + "Ul!"
    
        if (!$user) {
            Write-Host "Creating account '$upn'"
            $user = New-AzureADUser -DisplayName 'Simeon Service Account' `
                -UserPrincipalName $upn `
                -MailNickName simeon -AccountEnabled $true `
                -PasswordProfile @{ Password = $password; ForceChangePasswordNextLogin = $false } -PasswordPolicies DisablePasswordExpiration
        }
        else {
            Write-Host "Account already exists - updating '$upn'"
            $user | Set-AzureADUser -UserPrincipalName $upn -PasswordProfile @{ Password = $password; ForceChangePasswordNextLogin = $false } -PasswordPolicies DisablePasswordExpiration
        }

        # this can sometimes fail on first request
        try { Get-AzureADDirectoryRole | Out-Null } catch { }

        # Make sure Directory Synchronization Accounts role is activated 
        if (!(Get-AzureADDirectoryRole |? DisplayName -eq 'Directory Synchronization Accounts')) { 
            Write-Host "Activating role 'Directory Synchronization Accounts'"
            Get-AzureADDirectoryRoleTemplate |? DisplayName -eq 'Directory Synchronization Accounts' | % { Enable-AzureADDirectoryRole -RoleTemplateId $_.ObjectId -EA SilentlyContinue | Out-Null }
        }

        # Add to Company Administrator (aka Global Admin) role for administration purposes and Directory Synchronization Accounts role so account is excluded from MFA 
        Get-AzureADDirectoryRole |? { $_.DisplayName -in @('Company Administrator', 'Directory Synchronization Accounts') } | % { 
            if (!(Get-AzureADDirectoryRoleMember -ObjectId $_.ObjectId |? ObjectId -eq $user.ObjectId)) {
                Write-Host "Adding to directory role '$($_.DisplayName)' to '$upn'"
                Add-AzureADDirectoryRoleMember -ObjectId $_.ObjectId -RefObjectId $user.ObjectId | Out-Null
            }
            else {
                Write-Host "Account already has directory role '$($_.DisplayName)'"
            }
        }

        # Find Azure RM subscription to use 
        $subscriptionId = Get-SimeonTenantServiceAccountAzureSubscriptionId $Subscription
        if (!$subscriptionId) {
            # Elevate access to see all subscriptions in the tenant and force re-login
            irm 'https://management.azure.com/providers/Microsoft.Authorization/elevateAccess?api-version=2016-07-01' -Method Post -Headers @{ Authorization = "Bearer $(Get-AzContextToken 'https://management.azure.com/')" } | Out-Null
    
            Write-Warning "Elevating access to allow assignment of subscription roles - you will need to sign in again" -ForegroundColor Yellow 
            Connect-Azure $Tenant -Force

            $subscriptionId = Get-SimeonTenantServiceAccountAzureSubscriptionId $Subscription
        }

        # Add as contributor to an Azure RM Subscription
        if (!(Get-AzRoleAssignment -SignInName $upn -RoleDefinitionName 'Contributor' -Scope "/subscriptions/$subscriptionId")) {
            Write-Host "Adding account to 'Contributor' role on subscription '$subscriptionId'"
            New-AzRoleAssignment -SignInName $upn -RoleDefinitionName 'Contributor' -Scope "/subscriptions/$subscriptionId" | Out-Null
        }
        else {
            Write-Host "Account already has 'Contributor' role on subscription '$subscriptionId'"
        }

        return @{ Username = $upn; Password = $password }
    }

    function Get-SimeonAzureDevOpsAccessToken {
        $simeonClientId = 'ae3b8772-f3f2-4c33-a24a-f30bc14e4904'
        $devOpsAppId = '499b84ac-1321-427f-aa17-267ca6975798'
        $msalAppArgs = @{ ClientId = $simeonClientId; RedirectUri = 'http://localhost:3546' }
        $app = Get-MsalClientApplication @msalAppArgs
        if (!$app) {
            $app = New-MsalClientApplication @msalAppArgs | Add-MsalClientApplication -PassThru -WarningAction SilentlyContinue | Enable-MsalTokenCacheOnDisk -PassThru -WarningAction SilentlyContinue 
        }
        (Get-MsalToken -PublicClientApplication $app -Scopes "$devOpsAppId/.default").AccessToken         
    }

    function Test-SimeonAzureDevOpsAccessToken {
        param(
            [ValidateNotNullOrEmpty()]
            [string]$Organization,
            [ValidateNotNullOrEmpty()]
            [string]$Project,
            [ValidateNotNullOrEmpty()]
            [string]$Token        
        )    
        $restProps = @{
            Headers = @{ Authorization = "Bearer $token" }
            ContentType = 'application/json'
        }
        $apiVersion = "api-version=5.1"
        $apiBaseUrl = "https://dev.azure.com/$Organization/$Project/_apis"

        try {
            $projects = irm @restProps "https://dev.azure.com/$Organization/_apis/projects?$apiVersion"   
            $projectId = $projects.value |? name -eq $Project | Select -ExpandProperty id
            if ($projectId) {
                return $true
            } 
            else {
                Write-Warning "Successfully authenticated with Azure DevOps, but could not access project '$Project' in organization '$Organization'"
            }
        } 
        catch {
            Write-Warning "Could not access with Azure DevOps organization '$Organization'"
        }
        Clear-MsalTokenCache -FromDisk
        return $false
    }

    function Install-SimeonTenantAzureDevOps {
        param(
            # The organization name that appears in DevOps - e.g. 'simeon-orgName'
            [string]$Organization,
            # The project name in DevOps - usually 'Tenants'
            [string]$Project,
            # Indicates the name for the repository and pipelines to create
            [string]$Name,
            # Indicates the baseline repository to use for pipelines
            [string]$Baseline,
            [string]$Username,
            [string]$Password
        )    

        # Creates repo and pipelines and stores service account password

        while (!$Organization) { $Organization = Read-Organization }
    
        if (!$Project) { $Project = 'Tenants' }

        if (!$PSBoundParameters.ContainsKey('Baseline') -and $Name -ne 'baseline') {
            if (Read-HostBooleanValue 'Are you setting up the default baseline (as opposed to a specific tenant)?') { 
                $PSBoundParameters.Baseline = ''  # no baseline
                $Name = 'baseline'
            }
            else {
                $PSBoundParameters.Baseline = Read-Host "Enter the name of the baseline repository to use or leave blank to use 'baseline'"
                if (!$PSBoundParameters.Baseline) { 
                    $PSBoundParameters.Baseline = 'baseline' 
                }
            }
        }

        if (!$Name) {
            if ($Username) { $Name = $Username.Split('@')[1] }
            else { $Name = Read-Tenant }
        }
   
        Write-Host "Installing Azure DevOps repository and pipelines for '$Name' in project '$Project' in organization '$Organization'"

        while (!$token -or !(Test-SimeonAzureDevOpsAccessToken -Organization $Organization -Project $Project -Token $token)) {            
            Wait-EnterKey "Connecting to Azure DevOps - if prompted, log in as an account with access to your Simeon organization '$Organization' and the '$Project' project"        
            $token = Get-SimeonAzureDevOpsAccessToken
        }
    
        $restProps = @{
            Headers = @{ Authorization = "Bearer $token" }
            ContentType = 'application/json'
        }
        $apiVersion = "api-version=5.1"
        $apiBaseUrl = "https://dev.azure.com/$Organization/$Project/_apis"

        $projects = irm @restProps "https://dev.azure.com/$Organization/_apis/projects?$apiVersion"   
        $projectId = $projects.value |? name -eq $Project | Select -ExpandProperty id

        $repos = irm @restProps "$apiBaseUrl/git/repositories?$apiVersion"
        $repoName = $Name

        $repo = $repos.value |? name -eq $repoName

        if (!$repo) {
            Write-Host "Creating repository '$repoName'"
            $repo = irm @restProps "$apiBaseUrl/git/repositories?$apiVersion" -Method Post -Body (@{
                    name = $repoName
                    project = @{
                        id = $projectId
                        name = $Project
                    }            
                } | ConvertTo-Json)
        }
        else {
            Write-Host "Repository '$repoName' already exists - will not create"
        }

        $serviceEndpoint = (irm @restProps "$apiBaseUrl/serviceendpoint/endpoints?$apiVersion-preview.1").value |? name -eq 'simeoncloud'
    
        if (!$serviceEndpoint) { throw "Could not find service connection to simeoncloud GitHub." }

        try {        
            $importUrl = 'https://github.com/simeoncloud/DefaultTenant.git'
    
            irm @restProps "$apiBaseUrl/git/repositories/$($repo.id)/importRequests?$apiVersion-preview.1" -Method Post -Body (@{
                    parameters = @{
                        gitSource = @{
                            overwrite = $false
                            url = $importUrl
                        }
                    }
                } | ConvertTo-Json) | Out-Null

            Write-Host "Importing repository contents from '$importUrl'"                
        }
        catch {
            if ($_.Exception.Response.StatusCode -ne 'Conflict') {
                throw
            }
            Write-Host "Repository is not empty - will not import"
        }
    
        $pipelines = irm @restProps "$apiBaseUrl/build/definitions?$apiVersion" -Method Get

        $pipelineVariables = @{}

        if ($Username) {
            $pipelineVariables['AadAuth:Username'] = @{
                allowOverride = $true
                value = $Username
            }
        }
        IF ($Password) {
            $pipelineVariables['AadAuth:Password'] = @{
                allowOverride = $true
                isSecret = $true
                value = $Password
            }
        }
        if ($PSBoundParameters.ContainsKey('Baseline')) {
            $pipelineVariables['BaselineRepository'] = @{
                allowOverride = $true
                value = $PSBoundParameters.Baseline
            }
        }
    
        foreach ($action in @('Deploy', 'Export')) { 
            $pipelineName = "$Name - $action"
        
            $pipeline = $pipelines.value |? name -eq $pipelineName

            $body = @{
                name = $pipelineName
                path = $Name
                process = @{
                    type = 2
                    yamlFilename = "M365Management$($action).yml"
                }
                queue = @{
                    name = "Azure Pipelines"
                    pool = @{
                        name = "Azure Pipelines"
                        isHosted = "true"
                    }
                }
                repository = @{
                    url = "https://github.com/simeoncloud/AzurePipelines.git"
                    name = "simeoncloud/AzurePipelines"
                    id = "simeoncloud/AzurePipelines"
                    type = "GitHub"
                    defaultBranch = "master"
                    properties = @{
                        connectedServiceId = $serviceEndpoint.Id
                    }
                }
                uri = "M365Management$($action).yml"
                variables = $pipelineVariables
            }

            if ($pipeline) {
                Write-Host "Pipeline '$pipelineName' already exists - updating"
            
                $definition = irm @restProps "$apiBaseUrl/build/definitions/$($pipeline.id)?revision=$($pipeline.revision)?$apiVersion" -Method Get
                $uri = "$apiBaseUrl/build/definitions/$($pipeline.id)?$apiVersion"
            
                $body.variables = $definition.variables

                if (!$body.variables) { 
                    $body.variables = [pscustomobject]@{}
                }

                foreach ($kvp in $pipelineVariables.GetEnumerator()) {
                    if (!($body.variables | gm $kvp.Key)) {
                        $body.variables | Add-Member $kvp.Key $kvp.Value
                    }
                    else {
                        $body.variables.$($kvp.key) = $kvp.Value
                    }
                }

                $body += @{
                    id = $pipeline.id
                    revision = $pipeline.revision
                    options = $definition.options
                    triggers = $definition.triggers                
                }
            
                irm @restProps $uri -Method Put -Body ($body | ConvertTo-Json -Depth 10) | Out-Null
            }
            else {
                Write-Host "Creating pipeline '$pipelineName'"
                $uri = "$apiBaseUrl/build/definitions?$apiVersion"
                irm @restProps  $uri -Method Post -Body ($body | ConvertTo-Json -Depth 10) | Out-Null
            }
        }    
    }

    function Install-SimeonTenantBaseline {
        param(
            [ValidateNotNullOrEmpty()]
            [string]$Repository,
            [ValidateNotNullOrEmpty()]
            [string]$Baseline      
        )      
            
        #git submodule add -b master -f --name Source/Baseline $Baseline Source/Baseline
    }

    function Install-SimeonTenant {
        param(
            [ValidateNotNullOrEmpty()]
            # The Azure tenant domain name to configure Simeon for
            [string]$Tenant = (Read-Tenant),        
            # The organization name that appears in DevOps - e.g. 'simeon-orgName'
            [string]$Organization,
            # The project name in DevOps - usually 'Tenants'
            [string]$Project,
            # Indicates the name for the repository and pipelines to create - defaults to the tenant name
            [string]$Name,
            # Indicates the baseline repository to use for pipelines
            [string]$Baseline
        )
        <#
    .SYNOPSIS
    Prepares a tenant for use with Simeon.
    - Creates/updates a service account named simeon@yourcompany.com with a random password
    - Adds the service account to the 'Global administrator' role
    - Adds the service account as a Contributor to the first available Azure RM subscription
    - Creates necessary DevOps repositories and pipelines and securely stores service account credentials
    #>
    
        $userInfo = Install-SimeonTenantServiceAccount -Tenant $Tenant

        $pipelineArgs = @{}
        @('Organization', 'Project', 'Name', 'Baseline') |? { $PSBoundParameters.ContainsKey($_) } | % {
            $pipelineArgs[$_] = $PSBoundParameters.$_ 
        }

        Install-SimeonTenantAzureDevOps @pipelineArgs @userInfo

        Write-Host "Completed successfully"
    }

    Export-ModuleMember -Function Install-SimeonTenant*

} | Import-Module -Force