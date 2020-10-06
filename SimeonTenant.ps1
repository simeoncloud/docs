#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

New-Module -Name 'SimeonTenant' -ScriptBlock {
    $ErrorActionPreference = 'Stop'
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    function Invoke-CommandLine {
        [CmdletBinding()]
        param(
            [ValidateNotNullOrEmpty()]
            [string]$Expression
        )

        $ErrorActionPreference = 'Continue'
        iex $Expression
        if ($lastexitcode -ne 0) { throw "$Expression exited with code $lastexitcode" }
    }

    function Read-HostBooleanValue {
        [CmdletBinding()]
        [OutputType([bool])]
        param(
            [ValidateNotNullOrEmpty()]
            [string]$Prompt,
            [bool]$Default = $false
        )

        if ($ConfirmPreference -eq 'None') {
            return $Default
        }

        $defaultString = "'No'"
        if ($Default) {
            $defaultString = "'Yes'"
        }

        $line = ''
        while ($line -notin @('y', 'n')) {
            Write-Host $Prompt
            $line = Read-Host "Y [Yes]  N [No] (Press Enter to use default value of $defaultString)"
            if (!$line -and $PSBoundParameters.ContainsKey('Default')) { return $Default }
        }
        if ($line -eq 'Y') { return $true }
        return $false
    }

    function Read-Tenant {
        [CmdletBinding()]
        param()

        if ($ConfirmPreference -eq 'None') { throw "Tenant not specified" }
        Read-Host 'Enter tenant primary domain name (e.g. contoso.com or contoso.onmicrosoft.com if no custom domain name is set)'
    }

    function Read-Organization {
        [CmdletBinding()]
        param()

        if ($ConfirmPreference -eq 'None') { throw "Organization not specified" }
        Read-Host 'Enter Azure DevOps organization name'
    }

    function Wait-EnterKey {
        [CmdletBinding()]
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

    function Get-ParentUri {
        [CmdletBinding()]
        param(
            [ValidateNotNullOrEmpty()]
            [string]$Uri
        )

        $u = [uri]$Uri
        $u.AbsoluteUri.Remove($u.AbsoluteUri.Length - ($u.Segments | Select -Last 1).Length)
    }

    function Initialize-GitConfiguration {
        [CmdletBinding()]
        param()

        if (!(git config --global user.email)) { git config --global user.email "noreply@simeoncloud.com" }
        if (!(git config --global user.name)) { git config --global user.name "Simeon" }
    }

    function Install-Git {
        [CmdletBinding()]
        param()

        if (Get-Command git -EA SilentlyContinue) {
            return
        }

        $ProgressPreference = 'SilentlyContinue'

        if ($IsWindows -or $PSVersionTable.PSEdition -ne 'Core') {
            Write-Host "Downloading and installing Git - please click Yes if prompted" -ForegroundColor Green
            $url = 'https://github.com/git-for-windows/git/releases/download/v2.28.0.windows.1/Git-2.28.0-32-bit.exe'
            if ([System.Environment]::Is64BitOperatingSystem) {
                $url = 'https://github.com/git-for-windows/git/releases/download/v2.28.0.windows.1/Git-2.28.0-64-bit.exe'
            }

            $outFile = "$([IO.Path]::GetTempPath())/git-install.exe"
            irm $url -OutFile $outFile

            $infPath = "$([IO.Path]::GetTempPath())/git-install.inf"
            @'
[Setup]
Lang=default
Dir=$env:ProgramFiles\Git
Group=Git
NoIcons=0
SetupType=default
Components=
Tasks=
PathOption=Cmd
SSHOption=OpenSSH
CRLFOption=CRLFAlways
'@ | Out-File $infPath

            Start-Process $outFile -Wait -ArgumentList "/SILENT", "/SUPPRESSMSGBOXES", "/NORESTART", "/NOCANCEL", "/SP-", "LOADINF", $infPath

            $env:Path = "$env:ProgramFiles\Git\cmd;" + $env:Path
        }
        elseif ($IsMacOS) {
            Wait-EnterKey "Attempting to download and install Git - double click the pkg file and continue through the setup wizard as prompted"
            $url = 'https://iweb.dl.sourceforge.net/project/git-osx-installer/git-2.15.0-intel-universal-mavericks.dmg'
            $outFile = "$([IO.Path]::GetTempPath())/git-install.dmg"
            irm $url -OutFile $outFile
            & $outFile
            Write-Error "Please close this window and then re-run this script after completing the installation of Git"
            Exit
        }
        else {
            Write-Error "Please install Git from https://git-scm.com/downloads, close this window and then re-run this script"
            Exit
        }

        if (!(Get-Command git -EA SilentlyContinue)) { throw 'Could not automatically install Git - please install Git manually and then try running again - https://git-scm.com/downloads' }
        Write-Information "Git was successfully installed"

        Initialize-GitConfiguration
    }

    function Get-GitRepository {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [ValidateNotNullOrEmpty()]
            [string]$RepositoryUrl,
            [string]$AccessToken,
            [string]$Path = (Join-Path ([IO.Path]::GetTempPath()) $RepositoryUrl.Split('/')[-1])
        )

        Install-Git

        Remove-Item $Path -Recurse -Force -EA SilentlyContinue
        New-Item -ItemType Directory $Path -EA SilentlyContinue | Out-Null

        Write-Verbose "Cloning '$RepositoryUrl'"
        if ($AccessToken) { $gitConfig = "-c http.extraheader=`"AUTHORIZATION: bearer $AccessToken`"" }
        Invoke-CommandLine "git clone --single-branch -c core.longpaths=true $gitConfig $RepositoryUrl `"$Path`" 2>&1" | Write-Verbose
        return $Path
    }

    function Install-RequiredModule {
        [CmdletBinding()]
        param()

        if (!(Get-Module PowerShellGet -ListAvailable |? { $_.Version.Major -ge 2 })) {
            Write-Information "Updating PowerShellGet"
            Install-Module PowerShellGet -Force -Scope CurrentUser -Repository PSGallery -AllowClobber -WarningAction SilentlyContinue
            Write-Warning "Update of PowerShellGet complete - please close this window and then re-run this script"
            Exit
        }

        if ($PSVersionTable.PSEdition -ne 'Core' -and !(Get-PackageProvider NuGet -ListAvailable)) {
            Write-Information "Installing NuGet package provider"
            Install-PackageProvider NuGet -Force -ForceBootstrap | Out-Null
        }

        # Install required modules
        $requiredModules = @(
            @{ Name = 'MSAL.PS' }
        )
        if ($PSVersionTable.PSEdition -eq 'Core') {
            Get-PackageSource |? { $_.Location -eq 'https://www.poshtestgallery.com/api/v2/' -and $_.Name -ne 'PoshTestGallery' } | Unregister-PackageSource -Force
            if (!(Get-PackageSource PoshTestGallery -EA SilentlyContinue)) { Register-PackageSource -Name PoshTestGallery -Location https://www.poshtestgallery.com/api/v2/ -ProviderName PowerShellGet -Force | Out-Null }
            $requiredModules += @{ Name = 'AzureAD.Standard.Preview'; RequiredVersion = '0.0.0.10'; Repository = 'PoshTestGallery' }
        }
        else {
            $requiredModules += @{ Name = 'AzureAD' }
        }

        foreach ($m in $requiredModules) {
            if (!$m.Repository) { $m.Repository = 'PSGallery' }
            if (!(Get-Module $m.Name -ListAvailable |? { !$m.RequiredVersion -or $m.RequiredVersion -eq $_.Version })) {
                Write-Information "Installing module '$($m.Name)'"
                Install-Module @m -Scope CurrentUser -Force -AllowClobber -AcceptLicense | Out-Null
            }
            $m.Remove('Repository')
            Import-Module @m
        }
    }

    function Connect-Azure {
        [CmdletBinding()]
        param(
            [ValidateNotNullOrEmpty()]
            [Parameter(Mandatory)]
            [string]$Tenant,
            [switch]$Interactive
        )

        Install-RequiredModule

        try {
            Connect-AzureAD -AadAccessToken (Get-SimeonAzureADAccessToken -Scope AzureADGraph -Tenant $Tenant -Interactive:$Interactive) -AccountId $Tenant -TenantId $Tenant | Out-Null
        }
        catch {
            Write-Warning $_.Exception.Message
            Connect-AzureAD -AadAccessToken (Get-SimeonAzureADAccessToken -Scope AzureADGraph -Tenant $Tenant -Interactive) -AccountId $Tenant -TenantId $Tenant | Out-Null
        }
    }

    function Test-AzureADCurrentUserRole {
        [CmdletBinding()]
        [OutputType([bool])]
        param(
            [ValidateNotNullOrEmpty()]
            [Parameter(Mandatory)]
            [string]$Name,
            [ValidateNotNullOrEmpty()]
            [Parameter(Mandatory)]
            [string]$Tenant
        )

        try {
            $value = @()
            $url = 'https://graph.windows.net/me/memberOf?$select=displayName,objectType&api-version=1.6'
            while ($url) {
                $res = irm $url -Method Get -Headers @{ Authorization = "Bearer $(Get-SimeonAzureADAccessToken -Scope AzureADGraph -Tenant $Tenant)" }
                if ($res.value) { $value += $res.value }
                $url = $res."@odata.nextLink"
            }
            return [bool]($value |? objectType -eq 'Role' |? displayName -eq $Name)
        }
        catch {
            Write-Warning $_.Exception.Message
            return $false
        }
    }

    <#
    .SYNOPSIS
    Gets a Bearer token to access Azure DevOps APIs. If an Organization and Project is specified, ensures the retrieved access token has access to that organization and project.
    #>
    function Get-SimeonAzureDevOpsAccessToken {
        [OutputType([string])]
        [CmdletBinding()]
        param(
            [string]$Organization,
            [string]$Project = 'Tenants'
        )

        $token = Get-SimeonAzureADAccessToken -Scope AzureDevOps

        if ($Organization -and $Project) {
            while (!(Test-SimeonAzureDevOpsAccessToken -Organization $Organization -Project $Project -Token $token)) {
                Write-Warning "Successfully authenticated with Azure DevOps as $($token.Account.Username), but could not access project '$Organization\$Project'"
                $token = Get-SimeonAzureADAccessToken -Scope AzureDevOps -Interactive
            }
        }


        return $token
    }

    <#
    .SYNOPSIS
    Gets a Bearer token to access Azure AD secured resources.
    #>
    function Get-SimeonAzureADAccessToken {
        [CmdletBinding()]
        param (
            # Scopes to obtain a token for
            [Parameter(Mandatory)]
            [ValidateSet('AzureDevOps', 'AzureManagement', 'AzureADGraph')]
            [string]$Scope,
            # Tenant Id or name
            [ValidateNotNullOrEmpty()]
            [string]$Tenant = 'common',
            # Will force an interactive authentication
            [switch]$Interactive
        )

        $token = Get-Variable "$($Scope)AccessToken" -EA SilentlyContinue
        if ($token.Value) { return $token.Value }

        Install-RequiredModule

        $clientId = '1950a258-227b-4e31-a9cf-717495945fc2' # Azure PowerShell
        $interactiveMessage = "Connecting to Azure Tenant $Tenant - sign in using an account with the 'Global administrator' Azure Active Directory role"
        switch ($Scope) {
            'AzureDevOps' {
                $clientId = 'ae3b8772-f3f2-4c33-a24a-f30bc14e4904' # Simeon Cloud PowerShell
                $Scopes = '499b84ac-1321-427f-aa17-267ca6975798/.default'
                $interactiveMessage = "Connecting to Azure DevOps - if prompted, log in as an account with access to your Simeon Azure DevOps organization"
            }
            'AzureManagement' {
                $Scopes = 'https://management.core.windows.net//.default'
            }
            'AzureADGraph' {
                $Scopes = 'https://graph.windows.net/Directory.AccessAsUser.All'
            }
        }

        $msalAppArgs = @{ ClientId = $clientId; RedirectUri = 'http://localhost:3546'; TenantId = $Tenant }
        $app = Get-MsalClientApplication @msalAppArgs
        if (!$app) {
            $app = New-MsalClientApplication @msalAppArgs | Add-MsalClientApplication -PassThru -WarningAction SilentlyContinue | Enable-MsalTokenCacheOnDisk -PassThru -WarningAction SilentlyContinue
        }

        if ($Interactive -and $ConfirmPreference -ne 'None') {
            if ($interactiveMessage) { Wait-EnterKey $interactiveMessage }
            (Get-MsalToken -PublicClientApplication $app -Scopes "$clientId/.default" -Interactive -ForceRefresh) # get with all required permissions first
            $token = (Get-MsalToken -PublicClientApplication $app -Scopes $Scopes -Silent)
        }
        else {
            try {
                $token = (Get-MsalToken -PublicClientApplication $app -Scopes $Scopes -Silent)
            }
            catch {
                if ($ConfirmPreference -ne 'None') {
                    if ($interactiveMessage) { Wait-EnterKey $interactiveMessage }
                    $Interactive = $true
                    (Get-MsalToken -PublicClientApplication $app -Scopes "$clientId/.default" -Interactive -ForceRefresh) # get with all required permissions first
                    $token = (Get-MsalToken -PublicClientApplication $app -Scopes $Scopes -Silent)
                }
            }
        }

        if (!$token) {
            throw "Could not obtain a token for $Scope"
        }

        $hasConnectedVariable = "HasConnectedTo$($Scope)$Tenant"
        if ($Interactive -or !((Get-Variable $hasConnectedVariable -Scope Script -EA SilentlyContinue).Value)) {
            Write-Information "Connected to $Scope using account '$($token.Account.Username)'"
            Set-Variable $hasConnectedVariable $true -Scope Script
        }

        return $token.AccessToken
    }

    function Test-SimeonAzureDevOpsAccessToken {
        [CmdletBinding()]
        [OutputType([bool])]
        param(
            [ValidateNotNullOrEmpty()]
            [string]$Organization,
            [ValidateNotNullOrEmpty()]
            [string]$Project = 'Tenants',
            [ValidateNotNullOrEmpty()]
            [string]$Token
        )

        $restProps = @{
            Headers = @{
                Authorization = "Bearer $Token"
                Accept = "application/json;api-version=5.1"
            }
            ContentType = 'application/json'
        }

        $projects = irm @restProps "https://dev.azure.com/$Organization/_apis/projects"
        $projectId = $projects.value |? name -eq $Project | Select -ExpandProperty id
        if ($projectId) {
            return $true
        }
        return $false
    }

    function Get-AzureDevOpsRepository {
        [CmdletBinding()]
        param(
            [ValidateNotNullOrEmpty()]
            [string]$Organization,
            [ValidateNotNullOrEmpty()]
            [string]$Project = 'Tenants',
            [ValidateNotNullOrEmpty()]
            [string]$Name
        )

        $token = Get-SimeonAzureDevOpsAccessToken -Organization $Organization -Project $Project

        $restProps = @{
            Headers = @{
                Authorization = "Bearer $token"
                Accept = "application/json;api-version=5.1"
            }
            ContentType = 'application/json'
        }
        $apiBaseUrl = "https://dev.azure.com/$Organization/$Project/_apis"

        $repos = irm @restProps "$apiBaseUrl/git/repositories"

        $repo = $repos.value |? name -eq $Name

        if (!$repo) {
            throw "Could not find repository $Name"
        }

        return $repo
    }

    <#
    .SYNOPSIS
    Creates/updates a service account named simeon@yourcompany.com with a random password and grants it access to necessary resources
    #>
    function Install-SimeonTenantServiceAccount {
        [CmdletBinding()]
        [OutputType([pscredential])]
        param(
            # The Azure tenant domain name to configure Simeon for
            [ValidateNotNullOrEmpty()]
            [string]$Tenant,
            # The name or id of the subscription for Simeon to use - defaults to the first subscription available
            [string]$Subscription
        )

        while (!$Tenant) { $Tenant = Read-Tenant }

        # Creates/updates service account and required permissions

        Write-Information "Installing Simeon service account for tenant '$Tenant'"

        Connect-Azure $Tenant

        while (!(Test-AzureADCurrentUserRole 'Company Administrator' $Tenant)) {
            Write-Warning "Could not access Azure Active Directory '$Tenant' with sufficient permissions - please make sure you signed in using an account with the 'Global administrator' role."
            Connect-Azure $Tenant -Interactive
        }

        # Create/update Azure AD user with random password
        $upn = "simeon@$Tenant"
        $user = Get-AzureADUser -Filter "userPrincipalName eq '$upn'"
        $password = [Guid]::NewGuid().ToString("N").Substring(0, 15) + "Ul!"

        if (!$user) {
            Write-Information "Creating account '$upn'"
            $user = New-AzureADUser -DisplayName 'Microsoft 365 Management Service Account' `
                -UserPrincipalName $upn `
                -MailNickName simeon -AccountEnabled $true `
                -PasswordProfile @{ Password = $password; ForceChangePasswordNextLogin = $false } -PasswordPolicies DisablePasswordExpiration
        }
        else {
            Write-Information "Service account already exists - updating '$upn'"
            $user | Set-AzureADUser -UserPrincipalName $upn -DisplayName 'Microsoft 365 Management Service Account' -PasswordProfile @{ Password = $password; ForceChangePasswordNextLogin = $false } -PasswordPolicies DisablePasswordExpiration
        }

        # this can sometimes fail on first request
        try { Get-AzureADDirectoryRole | Out-Null } catch { Write-Verbose "Initial request for directory roles failed - will try again" }

        # Make sure Directory Synchronization Accounts role is activated
        if (!(Get-AzureADDirectoryRole |? DisplayName -eq 'Directory Synchronization Accounts')) {
            Write-Information "Activating role 'Directory Synchronization Accounts'"
            Get-AzureADDirectoryRoleTemplate |? DisplayName -eq 'Directory Synchronization Accounts' | % { Enable-AzureADDirectoryRole -RoleTemplateId $_.ObjectId -EA SilentlyContinue | Out-Null }
        }

        # Add to Company Administrator (aka Global Admin) role for administration purposes and Directory Synchronization Accounts role so account is excluded from MFA
        Get-AzureADDirectoryRole |? { $_.DisplayName -in @('Company Administrator', 'Directory Synchronization Accounts') } | % {
            if (!(Get-AzureADDirectoryRoleMember -ObjectId $_.ObjectId |? ObjectId -eq $user.ObjectId)) {
                Write-Information "Adding service account to directory role '$($_.DisplayName)'"
                Add-AzureADDirectoryRoleMember -ObjectId $_.ObjectId -RefObjectId $user.ObjectId | Out-Null
            }
            else {
                Write-Information "Service account already has directory role '$($_.DisplayName)'"
            }
        }

        $getAzureManagementHeaders = {
            @{ Authorization = "Bearer $(Get-SimeonAzureADAccessToken -Scope AzureManagement -Tenant $Tenant)" }
        }

        $getSubscriptionId = {
            $response = irm "https://management.azure.com/subscriptions?api-version=2019-06-01" -Headers (. $getAzureManagementHeaders)
            $response.value |? { $_.name -ne 'Access to Azure Active Directory' -and $_.state -eq 'Enabled' -and (!$Subscription -or $Subscription -in @($_.displayName, $_.subscriptionId)) } | Sort-Object name | Select -First 1 -ExpandProperty subscriptionId
        }

        # Find Azure RM subscription to use
        $subscriptionId = . $getSubscriptionId
        if (!$subscriptionId) {
            # Elevate access to see all subscriptions in the tenant and force re-login
            irm 'https://management.azure.com/providers/Microsoft.Authorization/elevateAccess?api-version=2016-07-01' -Method Post -Headers (. $getAzureManagementHeaders) | Out-Null

            Write-Warning "Elevating access to allow assignment of subscription roles - you will need to sign in again"
            Connect-Azure $Tenant -Interactive

            $subscriptionId = . $getSubscriptionId

            if (!$subscriptionId) {
                throw "Could not find a subscription to use - please make sure you have signed up for an Azure subscription"
            }
        }

        $contributorRoleId = (irm "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.Authorization/roleDefinitions?`$filter=roleName eq 'Contributor'&api-version=2018-01-01-preview" -Headers (. $getAzureManagementHeaders)).value.id
        $roleAssignments = (irm "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.Authorization/roleAssignments?`$filter=principalId eq '$($user.ObjectId)'&api-version=2018-09-01-preview" -Headers (. $getAzureManagementHeaders)).value |? { $_.properties.roleDefinitionId -eq $contributorRoleId }
        # Add as contributor to an Azure RM Subscription
        if (!$roleAssignments) {
            Write-Information "Adding service account to 'Contributor' role on subscription '$subscriptionId'"
            irm "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.Authorization/roleAssignments/$([guid]::NewGuid())?api-version=2018-09-01-preview" -Method Put -ContentType 'application/json' -Headers (. $getAzureManagementHeaders) -Body @"
{
    "properties": {
        "roleDefinitionId": "$contributorRoleId",
        "principalId": "$($user.ObjectId)",
    }
}
"@| Out-Null
        }
        else {
            Write-Information "Service account already has 'Contributor' role on subscription '$subscriptionId'"
        }

        return [pscredential]::new($upn, (ConvertTo-SecureString -AsPlainText -Force $password))
    }

    <#
    .SYNOPSIS
    Creates necessary DevOps repositories and pipelines and securely stores service account credentials
    #>
    function Install-SimeonTenantAzureDevOps {
        [CmdletBinding()]
        param(
            # The Azure DevOps organization name (e.g. 'Simeon-MyOrganization')
            [string]$Organization,
            # The project name in DevOps (defaults to 'Tenants')
            [string]$Project = 'Tenants',
            # The name of the repository and pipelines to create
            [string]$Name,
            # The baseline repository to use for pipelines (an empty string indicates to use no baseline) (may be the name of another repository DevOps or a full repository url)
            [string]$Baseline,
            # The Azure tenant service account credentials to use for running pipelines
            [pscredential]$Credential,
            # Specify to true to require approval when deploying
            [switch]$RequireDeployApproval,
            # Specify to true to require approval when exporting
            [switch]$RequireExportApproval,
            # Used to create a GitHub service connection to simeoncloud if one doesn't already exist
            [string]$GitHubAccessToken
        )

        # Creates repo and pipelines and stores service account password

        while (!$Organization) { $Organization = Read-Organization }

        if (!$PSBoundParameters.ContainsKey('Baseline') -and $ConfirmPreference -ne 'None') {
            $Baseline = Read-Host "Enter the name of the baseline repository to use or leave blank to proceed without a baseline"
        }

        if (!$Name) {
            if ($Credential.UserName) { $Name = $Credential.UserName.Split('@')[-1].Split('.')[0] }
            else { $Name = (Read-Tenant).Split('.')[0] }
        }
        $Name = $Name.ToLower()

        if ($Name.Contains('.')) {
            throw "Name must not contain any special characters"
        }

        Write-Information "Installing Azure DevOps repository and pipelines for '$Name' in project '$Organization\$Project'"

        Install-SimeonTenantRepository -Organization $Organization -Project $Project -Name $Name -GetImportUrl {
            if (!$Baseline -and (Read-HostBooleanValue 'This repository is empty - do you want to start with the Simeon baseline?' -Default $true)) {
                # start with Simeon baseline
                return 'https://github.com/simeoncloud/Baseline.git'
            }
            return 'https://github.com/simeoncloud/DefaultTenant.git'
        }

        Install-SimeonTenantBaseline -Organization $Organization -Project $Project -Repository $Name -Baseline $Baseline

        Install-SimeonGitHubServiceConnection -Organization $Organization -Project $Project -GitHubAccessToken $GitHubAccessToken

        $environmentArgs = @{}
        @('RequireDeployApproval', 'RequireExportApproval') | % {
            if ($PSBoundParameters.ContainsKey($_)) { $environmentArgs[$_] = $PSBoundParameters.$_ }
        }

        Install-SimeonTenantPipeline -Organization $Organization -Project $Project -Name $Name -Credential $Credential @environmentArgs
    }

    <#
    .SYNOPSIS
    Creates/updates a repository for a tenant in Azure DevOps
    #>
    function Install-SimeonTenantRepository {
        [CmdletBinding()]
        param(
            # The Azure DevOps organization name
            [ValidateNotNullOrEmpty()]
            [string]$Organization,
            # The project name in DevOps
            [ValidateNotNullOrEmpty()]
            [string]$Project = 'Tenants',
            # The name of the repository
            [ValidateNotNullOrEmpty()]
            [string]$Name,
            # A function that returns a url to import this repository from if it is empty
            [scriptblock]$GetImportUrl
        )

        $Name = $Name.ToLower()

        Write-Information "Installing repository for '$Name'"

        $token = Get-SimeonAzureDevOpsAccessToken -Organization $Organization -Project $Project

        $restProps = @{
            Headers = @{
                Authorization = "Bearer $token"
                Accept = "application/json;api-version=5.1-preview.1"
            }
            ContentType = 'application/json'
        }
        $apiBaseUrl = "https://dev.azure.com/$Organization/$Project/_apis"

        $projects = irm @restProps "https://dev.azure.com/$Organization/_apis/projects"
        $projectId = $projects.value |? name -eq $Project | Select -ExpandProperty id

        $repos = irm @restProps "$apiBaseUrl/git/repositories"

        $repo = $repos.value |? name -eq $Name

        if (!$repo) {
            Write-Information "Creating repository"
            $repo = irm @restProps "$apiBaseUrl/git/repositories" -Method Post -Body (@{
                    name = $Name
                    project = @{
                        id = $projectId
                        name = $Project
                    }
                } | ConvertTo-Json)
        }
        else {
            Write-Information "Repository already exists - will not create"
        }

        if (!$repo.defaultBranch -and $GetImportUrl) {
            $importUrl = . $GetImportUrl

            if ($importUrl) {
                Write-Information "Importing repository contents from '$importUrl'"

                $importOperation = irm @restProps "$apiBaseUrl/git/repositories/$($repo.id)/importRequests" -Method Post -Body (@{
                        parameters = @{
                            gitSource = @{
                                overwrite = $false
                                url = $importUrl
                            }
                        }
                    } | ConvertTo-Json)

                while ($importOperation.status -ne 'completed') {
                    if ($importOperation.status -eq 'failed') { throw "Importing repository from $importUrl failed" }
                    $importOperation = irm @restProps $importOperation.url
                    Start-Sleep -Seconds 1
                }
            }
            else {
                Write-Information "No import url was provider - will not import initial repository contents"
            }
        }
    }

    <#
    .SYNOPSIS
    Sets the baseline in a tenant repository
    #>
    function Install-SimeonTenantBaseline {
        [CmdletBinding()]
        param(
            [ValidateNotNullOrEmpty()]
            [string]$Organization,
            [ValidateNotNullOrEmpty()]
            [string]$Project = 'Tenants',
            [ValidateNotNullOrEmpty()]
            [string]$Repository,
            [string]$Baseline
        )
        Write-Information "Setting baseline for '$Name'"

        if (!([uri]$Repository).IsAbsoluteUri) {
            $Repository = (Get-AzureDevOpsRepository -Organization $Organization -Project $Project -Name $Repository).remoteUrl
        }
        if ($Baseline -and !([uri]$Baseline).IsAbsoluteUri) {
            $Baseline = (Get-AzureDevOpsRepository -Organization $Organization -Project $Project -Name $Baseline).remoteUrl
        }

        $token = Get-SimeonAzureDevOpsAccessToken

        $repositoryPath = (Get-GitRepository -Repository $Repository -AccessToken $token)
        Push-Location $repositoryPath
        try {
            $baselinePath = 'Baseline'

            $gitModules = git config --file .gitmodules --get-regexp submodule\.Baseline\.url
            $submodule = git submodule |? { ($_.Trim().Split(' ') | Select -Skip 1 -First 1) -eq 'Baseline' }

            if ($gitModules -eq "submodule.Baseline.url $Baseline" -and $submodule -and (Test-Path $baselinePath)) {
                Write-Information "Baseline is already configured to use '$($PSBoundParameters.Baseline)'"
                return
            }

            if (!$Baseline -and !$gitModules -and !$submodule -and !(Test-Path $baselinePath)) {
                Write-Information "Repository already has no baseline - no change is required"
                return
            }

            if (Test-Path $baselinePath) {
                Invoke-CommandLine "git submodule deinit -f . 2>&1" | Write-Verbose
                Remove-Item $baselinePath -Force -Recurse -EA SilentlyContinue
                Remove-Item ".git/modules/$baselinePath" -Force -Recurse -EA SilentlyContinue
                Remove-Item .gitmodules -Force -EA SilentlyContinue
            }

            if (([uri]$Baseline).Host -ne 'dev.azure.com') {
                $token = $null
            }

            if ($Baseline) {
                Write-Information "Setting baseline to '$Baseline'"
                "" | Set-Content .gitmodules
                if ($token) { $gitConfig = "-c http.extraheader=`"AUTHORIZATION: bearer $token`"" }
                Invoke-CommandLine "git $gitConfig -c core.longpaths=true submodule add -b master -f $Baseline `"$baselinePath`" 2>&1" | Write-Verbose
            }
            else {
                Write-Information "Setting repository to have no baseline"
            }
            Invoke-CommandLine "git add . 2>&1" | Write-Verbose

            git diff-index --quiet HEAD --
            if ($lastexitcode -eq 0) {
                Write-Information "Baseline is unchanged - repository was already up to date"
            }
            else {
                Write-Information "Committing changes"
                $message = "Set baseline repository to $Baseline"
                if (!$Baseline) {
                    $message = "Set repository to have no baseline"
                }
                Invoke-CommandLine "git commit -m `"$message`" -m `"[skip ci]`" 2>&1" | Write-Verbose

                Write-Information "Pushing changes to remote repository"
                Invoke-CommandLine 'git push origin master 2>&1' | Write-Verbose
            }
        }
        finally {
            Pop-Location

            if (Test-Path $repositoryPath) {
                Remove-Item $repositoryPath -Recurse -Force
            }
        }
    }

    <#
    .SYNOPSIS
    Ensures a service connection exists to GitHub and creates one if it does not
    #>
    function Install-SimeonGitHubServiceConnection {
        [CmdletBinding()]
        param(
            # The Azure DevOps organization name
            [ValidateNotNullOrEmpty()]
            [string]$Organization,
            # The project name in DevOps
            [ValidateNotNullOrEmpty()]
            [string]$Project = 'Tenants',
            # Used to create a GitHub service connection to simeoncloud if one doesn't already exist
            [string]$GitHubAccessToken
        )

        Write-Information "Ensuring GitHub service connections are configured for project '$Organization\$Project'"

        $token = Get-SimeonAzureDevOpsAccessToken -Organization $Organization -Project $Project

        $restProps = @{
            Headers = @{
                Authorization = "Bearer $token"
                Accept = "application/json;api-version=5.1-preview.1"
            }
            ContentType = 'application/json'
        }
        $apiBaseUrl = "https://dev.azure.com/$Organization"

        $projects = irm @restProps "$apiBaseUrl/_apis/projects"
        $projectId = $projects.value |? name -eq $Project | Select -ExpandProperty id

        # endpoint for pipeline templates in GitHub
        $serviceEndpoint = (irm @restProps "$apiBaseUrl/$Project/_apis/serviceendpoint/endpoints").value |? name -eq 'simeoncloud'

        if (!$serviceEndpoint) {
            Write-Information "Creating 'simeoncloud' GitHub service connection"
            while (!$GitHubAccessToken -and $ConfirmPreference -ne 'None') { $GitHubAccessToken = Read-Host 'Enter GitHub access token provided by Simeon support' }
            if (!$GitHubAccessToken) { throw "GitHubAccessToken not specified" }
            $serviceEndpoint = irm @restProps "$apiBaseUrl/$Project/_apis/serviceendpoint/endpoints" -Method Post -Body @"
            {
                "authorization": {
                    "scheme": "Token",
                    "parameters": {
                        "AccessToken": "$GitHubAccessToken"
                    }
                },
                "name": "simeoncloud",
                "serviceEndpointProjectReferences": [
                    {
                        "description": "",
                        "name": "simeoncloud",
                        "projectReference": {
                            "id": "$projectId",
                            "name": "$Project"
                        }
                    }
                ],
                "type": "github",
                "url": "https://github.com",
                "isShared": false,
                "owner": "library"
            }
"@
        }
        else {
            Write-Information "GitHub service connection 'simeoncloud' already exists"
        }

        irm @restProps "$apiBaseUrl/$Project/_apis/pipelines/pipelinePermissions/endpoint/$($serviceEndpoint.id)" -Method Patch -Body @"
        {
            "resource": {
                "id": "$($serviceEndpoint.id)",
                "type": "endpoint"
            },
            "allPipelines": {
                "authorized": true
            }
        }
"@ | Out-Null

        # NuGet packages endpoint
        $serviceEndpoint = (irm @restProps "$apiBaseUrl/$Project/_apis/serviceendpoint/endpoints").value |? name -eq 'simeoncloud-packages'

        if (!$serviceEndpoint) {
            Write-Information "Creating 'simeoncloud-packages' GitHub service connection"
            while (!$GitHubAccessToken -and $ConfirmPreference -ne 'None') { $GitHubAccessToken = Read-Host 'Enter GitHub access token provided by Simeon support' }
            if (!$GitHubAccessToken) { throw "GitHubAccessToken not specified" }
            $serviceEndpoint = irm @restProps "$apiBaseUrl/$Project/_apis/serviceendpoint/endpoints" -Method Post -Body @"
            {
                "authorization": {
                    "scheme": "UsernamePassword",
                    "parameters": {
                        "username": "simeoncloud",
                        "password": "$GitHubAccessToken"
                    }
                },
                "name": "simeoncloud-packages",
                "serviceEndpointProjectReferences": [
                    {
                        "description": "",
                        "name": "simeoncloud-packages",
                        "projectReference": {
                            "id": "$projectId",
                            "name": "$Project"
                        }
                    }
                ],
                "type": "externalnugetfeed",
                "url": "https://nuget.pkg.github.com/simeoncloud/index.json",
                "isShared": false,
                "owner": "library"
            }
"@
        }
        else {
            Write-Information "GitHub service connection 'simeoncloud-packages' already exists"
        }

        irm @restProps "$apiBaseUrl/$Project/_apis/pipelines/pipelinePermissions/endpoint/$($serviceEndpoint.id)" -Method Patch -Body @"
        {
            "resource": {
                "id": "$($serviceEndpoint.id)",
                "type": "endpoint"
            },
            "allPipelines": {
                "authorized": true
            }
        }
"@ | Out-Null
    }

    <#
    .SYNOPSIS
    Creates/updates pipelines for a Simeon tenant
    #>
    function Install-SimeonTenantPipeline {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function')]
        [CmdletBinding()]
        param(
            # The Azure DevOps organization name
            [ValidateNotNullOrEmpty()]
            [string]$Organization,
            # The project name in DevOps
            [ValidateNotNullOrEmpty()]
            [string]$Project = 'Tenants',
            # The name of the repository
            [ValidateNotNullOrEmpty()]
            [string]$Name,
            # The Azure tenant service account credentials to use for running pipelines
            [pscredential]$Credential,
            # Specify to true to require approval when deploying
            [switch]$RequireDeployApproval,
            # Specify to true to require approval when exporting
            [switch]$RequireExportApproval
        )

        $Name = $Name.ToLower()

        Install-SimeonTenantPipelineTemplateFile -Organization $Organization -Project $Project -Repository $Name

        $environmentArgs = @{}
        @('RequireDeployApproval', 'RequireExportApproval') | % {
            if ($PSBoundParameters.ContainsKey($_)) { $environmentArgs[$_] = $PSBoundParameters.$_ }
        }

        Install-SimeonTenantPipelineEnvironment -Organization $Organization -Project $Project -Name $Name @environmentArgs

        Write-Information "Installing pipelines for '$Name'"

        $token = Get-SimeonAzureDevOpsAccessToken -Organization $Organization -Project $Project

        $restProps = @{
            Headers = @{
                Authorization = "Bearer $token"
                Accept = "application/json;api-version=5.1"
            }
            ContentType = 'application/json'
        }
        $apiBaseUrl = "https://dev.azure.com/$Organization/$Project/_apis"

        $pipelines = irm @restProps "$apiBaseUrl/build/definitions" -Method Get

        $pipelineVariables = @{}

        if ($Credential.UserName) {
            $pipelineVariables['AadAuth:Username'] = @{
                allowOverride = $true
                value = $Credential.UserName
            }
        }
        if ($Credential -and $Credential.GetNetworkCredential().Password) {
            $pipelineVariables['AadAuth:Password'] = @{
                allowOverride = $true
                isSecret = $true
                value = $Credential.GetNetworkCredential().Password
            }
        }

        $repos = irm @restProps "$apiBaseUrl/git/repositories"

        $repo = $repos.value |? name -eq $Name

        if (!$repo) {
            throw "Could not find repository $Name"
        }

        $queueName = $poolName = "Azure Pipelines"
        $queueId = ((irm @restProps "$apiBaseUrl/distributedtask/queues?api-version=6.1-preview.1").Value |? Name -eq $queueName).id
        $poolId = ((irm @restProps "https://dev.azure.com/$Organization/_apis/distributedtask/pools").Value |? Name -eq $poolName).id

        foreach ($action in @('Deploy', 'Export')) {
            $pipelineName = "$Name - $action"

            $pipeline = $pipelines.value |? name -eq $pipelineName

            $body = @{
                name = $pipelineName
                path = $Name
                process = @{
                    type = 2
                    yamlFilename = "$action.yml"
                }
                queue = @{
                    name = $queueName
                    id = $queueId
                    pool = @{
                        name = $poolName
                        id = $poolId
                        isHosted = "true"
                    }
                }
                repository = @{
                    url = $repo.remoteUrl
                    id = $repo.id
                    name = $repo.name
                    type = "tfsgit"
                    defaultBranch = "master"
                }
                uri = "$action.yml"
                variables = $pipelineVariables
            }

            if ($pipeline) {
                Write-Information "Pipeline '$pipelineName' already exists - updating"

                $definition = irm @restProps "$apiBaseUrl/build/definitions/$($pipeline.id)?revision=$($pipeline.revision)" -Method Get

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

                irm @restProps "$apiBaseUrl/build/definitions/$($pipeline.id)" -Method Put -Body ($body | ConvertTo-Json -Depth 10) | Out-Null
            }
            else {
                Write-Information "Creating pipeline '$pipelineName'"
                irm @restProps "$apiBaseUrl/build/definitions" -Method Post -Body ($body | ConvertTo-Json -Depth 10) | Out-Null
            }
        }
    }

    <#
    .SYNOPSIS
    Creates/updates pipeline environments for a Simeon tenant
    #>
    function Install-SimeonTenantPipelineEnvironment {
        [CmdletBinding()]
        param(
            # The Azure DevOps organization name
            [ValidateNotNullOrEmpty()]
            [string]$Organization,
            # The project name in DevOps
            [ValidateNotNullOrEmpty()]
            [string]$Project = 'Tenants',
            # The name of the repository
            [ValidateNotNullOrEmpty()]
            [string]$Name,
            # Specify to true to require approval when deploying
            [switch]$RequireDeployApproval,
            # Specify to true to require approval when exporting
            [switch]$RequireExportApproval
        )

        $Name = $Name.ToLower()

        Write-Information "Installing pipeline environments for '$Name'"

        $token = Get-SimeonAzureDevOpsAccessToken -Organization $Organization -Project $Project

        $restProps = @{
            Headers = @{
                Authorization = "Bearer $token"
                Accept = "application/json;api-version=5.1-preview"
            }
            ContentType = 'application/json'
        }
        $apiBaseUrl = "https://dev.azure.com/$Organization/$Project/_apis"

        $environments = irm @restProps "$apiBaseUrl/distributedtask/environments"

        foreach ($action in @('Deploy', 'Export')) {
            $environmentName = "$Name - $action"

            $environment = $environments.value |? name -eq $environmentName

            if (!$environment) {
                Write-Information "Creating environment '$environmentName'"

                $environment = irm @restProps "$apiBaseUrl/distributedtask/environments" -Method Post -Body @"
{"description": "", "name": "$environmentName"}
"@
            }
            else {
                Write-Information "Environment '$environmentName' already exists"
            }

            $identities = irm @restProps "https://dev.azure.com/$Organization/_apis/IdentityPicker/Identities" -Method Post -Body @"
            {
                "query": "Contributors",
                "identityTypes": [
                    "group"
                ],
                "operationScopes": [
                    "ims",
                    "source"
                ],
                "options": {
                    "MinResults": 1,
                    "MaxResults": 20
                },
                "properties": [
                    "DisplayName"
                ]
            }
"@

            $contributorsDisplayName = "[$Project]\Contributors"
            $contributorsId = $identities.results.identities |? displayName -eq $contributorsDisplayName | Select -ExpandProperty localId
            if (!$contributorsId) { throw "Could not find Contributors group for project $Project" }

            irm @restProps "https://dev.azure.com/$Organization/_apis/securityroles/scopes/distributedtask.environmentreferencerole/roleassignments/resources/$($environment.project.id)_$($environment.id)" -Method Put -Body @"
            [{"userId":"$contributorsId","roleName":"Administrator"}]
"@ | Out-Null

            if ($action -eq 'Deploy' -and $PSBoundParameters.ContainsKey('RequireDeployApproval')) {
                $requireApproval = $RequireDeployApproval
            }
            elseif ($action -eq 'Export' -and $PSBoundParameters.ContainsKey('RequireExportApproval')) {
                $requireApproval = $RequireExportApproval
            }
            else {
                $requireApproval = Read-HostBooleanValue "Do you want to require approval before running '$($environmentName)'?" -Default ($action -eq 'Deploy' -and $Name -notlike '*baseline*')
            }
            $approvals = irm @restProps "$apiBaseUrl/pipelines/checks/configurations?resourceType=environment&resourceId=$($environment.id)"
            $approvalUrl = $approvals.value |? { $_.type.name -eq 'Approval' } | Select -ExpandProperty url
            if ($approvalUrl -and !$requireApproval) {
                Write-Information "Removing existing approval check"
                irm @restProps $approvalUrl -Method Delete | Out-Null
            }
            elseif (!$approvalUrl -and $requireApproval) {
                Write-Information "Adding approval check"

                # well known check type 8C6F20A7-A545-4486-9777-F762FAFE0D4D is for "Approval"
                irm @restProps "$apiBaseUrl/pipelines/checks/configurations" -Method Post -Body @"
                {
                    "type": {
                        "id": "8C6F20A7-A545-4486-9777-F762FAFE0D4D",
                        "name": "Approval"
                    },
                    "settings": {
                        "approvers": [
                            {
                                "displayName": $(ConvertTo-Json $contributorsDisplayName),
                                "id": "$contributorsId"
                            }
                        ],
                        "executionOrder": 1,
                        "instructions": "",
                        "minRequiredApprovers": 0,
                        "requesterCannotBeApprover": false
                    },
                    "resource": {
                        "type": "environment",
                        "id": "$($environment.id)",
                        "name": "$($environment.name)"
                    },
                    "timeout": 43200
                }
"@ | Out-Null
            }
            elseif ($approvalUrl) {
                Write-Information "Approval already exists - will not update"
            }
            else {
                Write-Information "Approval does not exist - no change is required"
            }
        }

    }

    <#
    .SYNOPSIS
    Installs the necessary pipeline template files in a tenant repository
    #>
    function Install-SimeonTenantPipelineTemplateFile {
        [CmdletBinding()]
        param(
            [ValidateNotNullOrEmpty()]
            [string]$Organization,
            [ValidateNotNullOrEmpty()]
            [string]$Project = 'Tenants',
            [ValidateNotNullOrEmpty()]
            [string]$Repository
        )

        Write-Information "Installing pipeline template files for '$Name'"

        if (!([uri]$Repository).IsAbsoluteUri) {
            $Repository = (Get-AzureDevOpsRepository -Organization $Organization -Project $Project -Name $Repository).remoteUrl
        }

        $token = Get-SimeonAzureDevOpsAccessToken

        $repositoryPath = (Get-GitRepository -Repository $Repository -AccessToken $token)
        Push-Location $repositoryPath
        if (Test-Path Baseline) {
            $ymlRepo = "DefaultTenant"
        }
        else {
            $ymlRepo = "Baseline"
        }
        try {
            $('Deploy', 'Export') | % {
                Write-Verbose "Downloading $_.yml from Simeon Repo $ymlRepo"
                Remove-Item "$_.yml" -Force -EA SilentlyContinue
                irm "https://raw.githubusercontent.com/simeoncloud/$ymlRepo/master/$_.yml" -OutFile "$_.yml"
            }
            Invoke-CommandLine "git add . 2>&1" | Write-Verbose

            git diff-index --quiet HEAD --
            if ($lastexitcode -eq 0) {
                Write-Information "Pipeline templates files are already up to date"
            }
            else {
                Write-Information "Committing changes"
                Invoke-CommandLine "git commit -m `"Updating pipeline template files`" -m `"[skip ci]`" 2>&1" | Write-Verbose

                Write-Information "Pushing changes to remote repository"
                Invoke-CommandLine 'git push origin master 2>&1' | Write-Verbose
            }
        }
        finally {
            Pop-Location
        }

        if (Test-Path $repositoryPath) {
            Remove-Item $repositoryPath -Recurse -Force
        }
    }

    <#
    .SYNOPSIS
    Prepares a tenant for use with Simeon
    - Creates/updates a service account named simeon@yourcompany.com with a random password and grants it access to necessary resources
    - Creates necessary DevOps repositories and pipelines and securely stores service account credentials
    #>
    function Install-SimeonTenant {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function')]
        [CmdletBinding()]
        param(
            # The Azure tenant domain name to configure Simeon for
            [string]$Tenant,
            # The Azure DevOps organization name - e.g. 'simeon-orgName'
            [string]$Organization,
            # The project name in DevOps - usually 'Tenants'
            [string]$Project = 'Tenants',
            # Indicates the name for the repository and pipelines to create - defaults to the tenant name up to the first .
            [string]$Name,
            # Indicates the baseline repository to use for pipelines
            [string]$Baseline,
            # Specify to true to require approval when deploying
            [switch]$RequireDeployApproval,
            # Specify to true to require approval when exporting
            [switch]$RequireExportApproval,
            # Used to create a GitHub service connection to simeoncloud if one doesn't already exist
            [string]$GitHubAccessToken
        )

        while (!$Tenant) { $Tenant = Read-Tenant }

        $credential = Install-SimeonTenantServiceAccount -Tenant $Tenant

        $devOpsArgs = @{}
        @('Organization', 'Project', 'Name', 'Baseline', 'RequireDeployApproval', 'RequireExportApproval') |? { $PSBoundParameters.ContainsKey($_) } | % {
            $devOpsArgs[$_] = $PSBoundParameters.$_
        }

        Install-SimeonTenantAzureDevOps @devOpsArgs -Credential $credential

        Write-Information "Completed installing tenant"
    }

    Export-ModuleMember -Function Install-Simeon*, Get-Simeon*

} | Import-Module -Force