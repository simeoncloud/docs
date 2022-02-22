#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

New-Module -Name 'SimeonInstaller' -ScriptBlock {
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

        git config core.longpaths true
        git config user.email "noreply@simeoncloud.com"
        git config user.name "Simeon"
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
            Write-Error "Please close this window and then re-run this script after completing the installation of Git" -EA Continue
            Exit
        }
        else {
            Write-Error "Please install Git from https://git-scm.com/downloads, close this window and then re-run this script" -EA Continue
            Exit
        }

        if (!(Get-Command git -EA SilentlyContinue)) { throw 'Could not automatically install Git - please install Git manually and then try running again - https://git-scm.com/downloads' }
        Write-Information "Git was successfully installed"
    }

    <#
    .SYNOPSIS
    Clones a git repository using a bearer access token. Returns the path of the cloned repository.
    #>
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

        if (Test-Path $Path) { Remove-Item $Path -Recurse -Force -EA SilentlyContinue }
        New-Item -ItemType Directory $Path -EA SilentlyContinue | Out-Null

        Write-Verbose "Cloning '$RepositoryUrl'"
        if ($AccessToken) { $gitConfig = "-c http.extraheader=`"AUTHORIZATION: bearer $AccessToken`"" }
        Invoke-CommandLine "git clone --single-branch -c core.longpaths=true $gitConfig $RepositoryUrl `"$Path`" 2>&1" | Write-Verbose

        Push-Location $Path
        try {
            Initialize-GitConfiguration
        }
        finally {
            Pop-Location
        }

        return $Path
    }

    function Install-RequiredModule {
        [CmdletBinding()]
        param()

        if ($SkipSimeonModuleInstallation) { return }

        if (!(Get-Module PowerShellGet -ListAvailable |? { $_.Version.Major -ge 2 })) {
            Write-Information "Updating PowerShellGet"
            Install-Module PowerShellGet -Force -Scope CurrentUser -Repository PSGallery -AllowClobber -SkipPublisherCheck -WarningAction SilentlyContinue
            Write-Warning "Update of PowerShellGet complete - please close this window and then re-run this script"
            Exit
        }

        if ($PSVersionTable.PSEdition -ne 'Core' -and !(Get-PackageProvider NuGet -ListAvailable)) {
            Write-Information "Installing NuGet package provider"
            Install-PackageProvider NuGet -Force -ForceBootstrap | Out-Null
        }

        # Install required modules
        $requiredModules = @(
            @{ Name = 'MSAL.PS' },
            @{ Name = 'powershell-yaml' }
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
                Install-Module @m -Scope CurrentUser -Force -AllowClobber -AcceptLicense -SkipPublisherCheck | Out-Null
            }
            $m.Remove('Repository')
            Import-Module @m
        }

        # don't install again
        $script:SkipSimeonModuleInstallation = $true
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
            Connect-AzureAD -AadAccessToken (Get-SimeonAzureADAccessToken -Resource AzureADGraph -Tenant $Tenant -Interactive:$Interactive) -AccountId $Tenant -TenantId $Tenant | Out-Null
        }
        catch {
            Write-Warning $_.Exception.Message
            Connect-AzureAD -AadAccessToken (Get-SimeonAzureADAccessToken -Resource AzureADGraph -Tenant $Tenant -Interactive) -AccountId $Tenant -TenantId $Tenant | Out-Null
        }
    }

    function Assert-AzureADCurrentUserRole {
        [CmdletBinding()]
        [OutputType([bool])]
        param(
            [ValidateNotNullOrEmpty()]
            [Parameter(Mandatory)]
            [string[]]$Name,
            [ValidateNotNullOrEmpty()]
            [Parameter(Mandatory)]
            [string]$Tenant
        )

        try {
            $value = @()
            $url = 'https://graph.windows.net/me/memberOf?$select=displayName,objectType&api-version=1.6'
            while ($url) {
                $res = irm $url -Method Get -Headers @{ Authorization = "Bearer $(Get-SimeonAzureADAccessToken -Resource AzureADGraph -Tenant $Tenant)" }
                if ($res.value) { $value += $res.value }
                $url = $res."@odata.nextLink"
            }
            if ($value |? objectType -eq 'Role' |? displayName -in $Name) {
                return
            }
        }
        catch {
            Write-Warning $_.Exception.Message
        }
        throw "Could not access Azure Active Directory '$Tenant' with sufficient permissions - please make sure you signed in using an account with the 'Global Administrator' role."
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
            [string]$Project = 'Tenants',
            [switch]$Interactive
        )

        if ($Project.Contains(" ")) {
            throw “Project name must not contain spaces”
        }

        $token = Get-SimeonAzureADAccessToken -Resource AzureDevOps -Interactive:$Interactive

        if ($Organization -and $Project) {
            Assert-SimeonAzureDevOpsAccessToken -Organization $Organization -Project $Project -Token $token
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
            # Resource to obtain a token for
            [Parameter(Mandatory)]
            [ValidateSet('AzureDevOps', 'AzureManagement', 'AzureADGraph', 'KeyVault')]
            [string]$Resource,
            # Tenant Id or name
            [ValidateNotNullOrEmpty()]
            [string]$Tenant = 'common',
            # Will force an interactive authentication
            [switch]$Interactive
        )

        $token = Get-Variable "$($Resource)AccessToken" -EA SilentlyContinue
        if ($token.Value) { return $token.Value }

        Install-RequiredModule

        $clientId = '9e956d26-4663-420a-9863-7afea8f94737' # Simeon Cloud PowerShell
        $interactiveMessage = "Connecting to Azure Tenant $Tenant - sign in using an account with the 'Global Administrator' Azure Active Directory role"
        switch ($Resource) {
            'AzureManagement' {
                $Scopes = 'https://management.core.windows.net//.default'
            }
            'AzureADGraph' {
                $Scopes = 'https://graph.windows.net/Directory.AccessAsUser.All'
            }
            'AzureDevOps' {
                $clientId = '1950a258-227b-4e31-a9cf-717495945fc2' # Azure PowerShell
                $Scopes = '499b84ac-1321-427f-aa17-267ca6975798/.default'
                $interactiveMessage = "Connecting to Azure DevOps - if prompted, log in as an account with access to your Simeon Azure DevOps organization"
            }
            'KeyVault' {
                $clientId = '1950a258-227b-4e31-a9cf-717495945fc2' # Azure PowerShell
                $Scopes = 'https://vault.azure.net/.default'
            }
        }

        $msalAppArgs = @{ ClientId = $clientId; TenantId = $Tenant }
        $app = Get-MsalClientApplication @msalAppArgs
        if (!$app) {
            $app = New-MsalClientApplication @msalAppArgs | Add-MsalClientApplication -PassThru -WarningAction SilentlyContinue | Enable-MsalTokenCacheOnDisk -PassThru -WarningAction SilentlyContinue
        }

        if ($Interactive -and $ConfirmPreference -ne 'None') {
            if ($interactiveMessage) { Wait-EnterKey $interactiveMessage }
            (Get-MsalToken -PublicClientApplication $app -Scopes "$clientId/.default" -Interactive -ForceRefresh) | Out-Null # get with all required permissions first
            $token = (Get-MsalToken -PublicClientApplication $app -Scopes $Scopes -Silent -ForceRefresh)
        }
        else {
            try {
                $token = (Get-MsalToken -PublicClientApplication $app -Scopes $Scopes -Silent)
            }
            catch {
                if ($ConfirmPreference -ne 'None') {
                    if ($interactiveMessage) { Wait-EnterKey $interactiveMessage }
                    $Interactive = $true
                    (Get-MsalToken -PublicClientApplication $app -Scopes "$clientId/.default" -Interactive -ForceRefresh) | Out-Null # get with all required permissions first
                    $token = (Get-MsalToken -PublicClientApplication $app -Scopes $Scopes -Silent -ForceRefresh)
                }
            }
        }

        if (!$token) {
            throw "Could not obtain a token for $Resource"
        }

        $hasConnectedVariable = "HasConnectedTo$($Resource)$Tenant"
        if ($Interactive -or !((Get-Variable $hasConnectedVariable -Scope Script -EA SilentlyContinue).Value)) {
            Write-Information "Connected to '$Resource' using account '$($token.Account.Username)'"
            Set-Variable $hasConnectedVariable $true -Scope Script
        }

        return $token.AccessToken
    }

    function Assert-SimeonAzureDevOpsAccessToken {
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

        if ($Project.Contains(" ")) {
            throw “Project name must not contain spaces”
        }

        $restProps = @{
            Headers = @{
                Authorization = "Bearer $Token"
                Accept = "application/json;api-version=5.1"
            }
            ContentType = 'application/json'
        }

        $projects = irm @restProps "https://dev.azure.com/$Organization/_apis/projects"
        $projectId = $projects.value |? name -eq $Project | Select -ExpandProperty id
        if (!$projectId) {
            throw "Successfully authenticated with Azure DevOps, but could not access project '$Organization\$Project' - found projects: $($projects.value.name -join ', '). Please check that you are installing into the correct organization."
        }
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

        if ($Project.Contains(" ")) {
            throw “Project name must not contain spaces”
        }

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
    Grants the specified scopes to the service principal with the specified AppId. Installs a ServicePrincipal for the AppId if it is not already.
    #>
    function Get-AzureADServicePrincipalId {
        [CmdletBinding()]
        param(
            # The Azure tenant domain name to configure
            [ValidateNotNullOrEmpty()]
            [string]$Tenant,
            # The AppId of the ServicePrincpal to get or install
            [ValidateNotNullOrEmpty()]
            [string]$AppId
        )
        $headers = @{ Authorization = "Bearer $(Get-SimeonAzureADAccessToken -Resource AzureADGraph -Tenant $Tenant)" }

        $apiVersion = 'api-version=1.6'
        $baseUrl = "https://graph.windows.net/$Tenant"

        $principalObjectId = (irm "$baseUrl/servicePrincipals?$apiVersion&`$filter=appId eq '$AppId'" -Headers $headers).value[0].objectId
        if (!$principalObjectId) {
            Write-Information "Installing AppId $AppId"
            $principalObjectId = (irm "$baseUrl/servicePrincipals?$apiVersion" -Method Post -ContentType 'application/json' -Headers $headers -Body (@{appId = $AppId } | ConvertTo-Json)).objectId
        }
        else {
            Write-Information "AppId $AppId is already installed"
        }
        return $principalObjectId
    }

    <#
    .SYNOPSIS
    Grants the specified scopes to the service principal with the specified AppId. Installs the ServicePrincipal if it is not already.
    #>
    function Grant-AzureADOAuth2Permission {
        [CmdletBinding()]
        param(
            # The Azure tenant domain name to configure
            [ValidateNotNullOrEmpty()]
            [string]$Tenant,
            # The AppId of the principal that needs permissions
            [ValidateNotNullOrEmpty()]
            [string]$ClientAppId,
            # The AppId resource for which scopes should be granted
            [ValidateNotNullOrEmpty()]
            [string]$ResourceAppId,
            # The scopes required for the ResourceAppId
            [ValidateNotNullOrEmpty()]
            [string[]]$ResourceScopes
        )
        $headers = @{ Authorization = "Bearer $(Get-SimeonAzureADAccessToken -Resource AzureADGraph -Tenant $Tenant)" }

        $apiVersion = 'api-version=1.6'
        $baseUrl = "https://graph.windows.net/$Tenant"

        $clientId = Get-AzureADServicePrincipalId $Tenant $ClientAppId
        $resourceId = Get-AzureADServicePrincipalId $Tenant $ResourceAppId
        $grant = (irm "$baseUrl/oauth2PermissionGrants?$apiVersion&`$filter=clientId eq '$clientId' and resourceId eq '$resourceId'" -Headers $headers).value[0]

        if ($grant) {
            Write-Information "Deleting existing permission grant for client $ClientAppId on resource $ResourceAppId"
            irm "$baseUrl/oauth2PermissionGrants/$($grant.objectId)?$apiVersion" -Method Delete -Headers $headers | Out-Null
        }

        Write-Information "Adding permission grant for client $ClientAppId on resource $ResourceAppId"
        irm "$baseUrl/oauth2PermissionGrants?$apiVersion" -Method Post -ContentType 'application/json' -Headers $headers -Body (@{
                clientId = $clientId
                consentType = "AllPrincipals"
                expiryTime = "9000-01-01T00:00:00"
                principalId = $null
                resourceId = $resourceId
                scope = ([string]::Join(' ', $ResourceScopes))
            } | ConvertTo-Json) | Out-Null
    }

    <#
    .SYNOPSIS
        Installs all permissions required to use Simeon in an Azure AD tenant.
    #>
    function Install-SimeonTenantAzureADAppPermission {
        [CmdletBinding()]
        param (
            # The Azure tenant domain name to configure
            [ValidateNotNullOrEmpty()]
            [string]$Tenant
        )

        $azurePowerShellAppId = "1950a258-227b-4e31-a9cf-717495945fc2"
        $msGraphPowerShellAppId = '14d82eec-204b-4c2f-b7e8-296a70dab67e'

        foreach ($clientAppId in @($azurePowerShellAppId, $msGraphPowerShellAppId)) {
            # MS Graph
            Grant-AzureADOAuth2Permission -Tenant $Tenant -ClientAppId $clientAppId -ResourceAppId '00000003-0000-0000-c000-000000000000' -ResourceScopes @(
                "Application.ReadWrite.All",
                "AppRoleAssignment.ReadWrite.All",
                "DeviceManagementApps.ReadWrite.All",
                "DeviceManagementConfiguration.ReadWrite.All",
                "DeviceManagementManagedDevices.ReadWrite.All",
                "DeviceManagementRBAC.ReadWrite.All",
                "DeviceManagementServiceConfig.ReadWrite.All",
                "Directory.AccessAsUser.All",
                "Directory.ReadWrite.All",
                "Files.ReadWrite.All",
                "Group.ReadWrite.All",
                "Organization.ReadWrite.All",
                "RoleManagement.ReadWrite.Directory",
                "Policy.Read.All",
                "Policy.ReadWrite.AuthenticationMethod",
                "Policy.ReadWrite.ConditionalAccess",
                "Policy.ReadWrite.DeviceConfiguration",
                "Policy.ReadWrite.FeatureRollout",
                "Policy.ReadWrite.PermissionGrant",
                "Policy.ReadWrite.TrustFramework",
                "Sites.ReadWrite.All",
                "User.ReadWrite.All"
            )
        }
    }

    <#
    .SYNOPSIS
        Invokes the given command block with retries on failure
    #>
    function Invoke-WithRetry {
        [CmdletBinding()]
        param(
            [ValidateNotNullOrEmpty()]
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
                    throw $ScriptBlock
                }
            }
        }
    }

    <#
    .SYNOPSIS
        If using PAT token use basic auth else use bearer token. PAT token not currently supported
    #>
    function Get-AzureDevOpsAuthHeader {
        [OutputType([hashtable])]
        [CmdletBinding()]
        param()

        $token = Get-SimeonAzureDevOpsAccessToken
        if ($token -match "^[a-zA-Z0-9\+/]*={0,2}$") {
            return @{ Authorization = "Basic $token" }
        }
        return @{ Authorization = "Bearer $token" }
    }

    <#
    .SYNOPSIS
        Sets Azure DevOps project permissions
    #>
    function Set-AzureDevOpsAccessControlEntry {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
        param(
            [ValidateNotNullOrEmpty()]
            [string]$Organization,
            [ValidateNotNullOrEmpty()]
            [string]$ProjectId,
            [ValidateNotNullOrEmpty()]
            [string]$SubjectGroupPrincipalName,
            [ValidateNotNullOrEmpty()]
            [string]$PermissionDescription,
            [ValidateNotNullOrEmpty()]
            [int]$PermissionNumber
        )

        $authenicationHeader = Get-AzureDevOpsAuthHeader

        $groups = (Invoke-WithRetry { Invoke-RestMethod -Header $authenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/groups?api-version=6.1-preview.1" -Method Get }).value

        Write-Information "Allowing $SubjectGroupPrincipalName to $PermissionDescription"
        $groupDescriptor = ($Groups |? principalName -eq $SubjectGroupPrincipalName).descriptor
        $identityDescriptor = ((Invoke-WithRetry { Invoke-RestMethod -Header $authenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/identities?api-version=6.0&subjectDescriptors=$groupDescriptor" -Method Get }).value).descriptor
        # 2e9eb7ed-3c0a-47d4-87c1-0ffdd275fd87 is the Git Repositories namespace
        Invoke-WithRetry { Invoke-RestMethod -Header $authenicationHeader -Uri "https://dev.azure.com/$Organization/_apis/AccessControlEntries/2e9eb7ed-3c0a-47d4-87c1-0ffdd275fd87?api-version=5.0" -Method Post -ContentType "application/json" -Body @"
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

    $azureDevOpsProjectIdCache = @{}
    <#
    .SYNOPSIS
        Gets the Azure DevOps project id for the given project
    #>
    function Get-AzureDevOpsProjectId {
        param(
            [ValidateNotNullOrEmpty()]
            [string]$Organization,
            [ValidateNotNullOrEmpty()]
            [string]$Project
        )

        if ($Project.Contains(" ")) {
            throw “Project name must not contain spaces”
        }

        $authenicationHeader = Get-AzureDevOpsAuthHeader

        if (!$azureDevOpsProjectIdCache.$Project) {
            Write-Information "Getting project id for Organization: $Organization project: $Project"
            $azureDevOpsProjectIdCache.$Project = ((Invoke-RestMethod -Header $authenicationHeader -Uri "https://dev.azure.com/$Organization/_apis/projects?api-version=6.1-preview.4" -Method Get).value |? { $_.name -eq "$Project" }).id
        }
        return $azureDevOpsProjectIdCache.$Project
    }


    <#
    .SYNOPSIS
        Gets a secret from Azure Key vault for a given secret url
    #>
    function Get-AzureKeyVaultSecret {
        param(
            [ValidateNotNullOrEmpty()]
            [string]$KeyVaultSecretUri
        )

        $token = Get-SimeonAzureADAccessToken -Resource 'KeyVault'
        Write-Information "Getting keyvault secret access token from Uri: $KeyVaultSecretUri"
        $secret = (Invoke-WithRetry { Invoke-RestMethod -Header @{Authorization = "Bearer $token" } -Uri "$KeyVaultSecretUri`?api-version=7.1" -Method Get }).Value

        return $secret
    }

    <#
    .SYNOPSIS
    Removes a service account named simeon@yourcompany.com
    #>
    function Remove-SimeonTenantServiceAccount {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
        [CmdletBinding()]
        param(
            # The Azure tenant domain name to configure Simeon for
            [ValidateNotNullOrEmpty()]
            [string]$Tenant
        )

        while (!$Tenant) { $Tenant = Read-Tenant }

        Connect-Azure $Tenant

        $user = Get-AzureADUser -Filter "userPrincipalName eq 'simeon@$Tenant'"
        if ($user) {
            Write-Information "Removing Simeon service account for tenant '$Tenant'"
            Remove-AzureADUser -ObjectId "simeon@$Tenant"
        }

    }

    <#
    .SYNOPSIS
    Creates/updates a service account named simeon@yourcompany.com with a random password and grants it access to necessary resources
    #>
    function Install-SimeonTenantServiceAccount {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
        [CmdletBinding()]
        [OutputType([pscredential])]
        param(
            # The Azure tenant domain name to configure Simeon for
            [ValidateNotNullOrEmpty()]
            [string]$Tenant,
            # The name or id of the subscription for Simeon to use
            [string]$Subscription
        )

        while (!$Tenant) { $Tenant = Read-Tenant }

        # Creates/updates service account and required permissions

        Write-Information "Installing Simeon service account for tenant '$Tenant'"

        Connect-Azure $Tenant

        Assert-AzureADCurrentUserRole -Name @('Global Administrator', 'Company Administrator') -Tenant $Tenant

        Install-SimeonTenantAzureADAppPermission -Tenant $Tenant

        if ((Get-AzureADDomain -Name $Tenant).AuthenticationType -eq 'Federated') {
            throw "Cannot install service account using a federated Azure AD domain"
        }

        $activeLicenses = (irm "https://graph.windows.net/$Tenant/subscribedSkus?api-version=1.6" -Method Get -Headers @{ Authorization = "Bearer $(Get-SimeonAzureADAccessToken -Resource AzureADGraph -Tenant $Tenant)" }).value |? capabilityStatus -eq "Enabled"
        $activeServicePlans = $activeLicenses.servicePlans
        Write-Verbose "Found active plans $($activeServicePlans | Out-String)."
        if (!($activeServicePlans | Select -ExpandProperty servicePlanName |? { $_ -and $_.Split('_')[0] -like "INTUNE*" })) {
            if ($activeServicePlans) {
                $activeServicePlansString = " - found: " + [string]::Join(', ', (@($activeServicePlans) | Sort-Object))
            }
            else {
                $activeServicePlansString = " - found no active service plans"
            }
            Write-Warning "The tenant does not have an enabled Intune license - see https://docs.microsoft.com/en-us/mem/intune/fundamentals/licenses for license information$activeServicePlansString"
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

        # Add to Global Administrator role for administration purposes and Directory Synchronization Accounts role so account is excluded from MFA
        # Include Company Administrator for legacy support
        Get-AzureADDirectoryRole |? { $_.DisplayName -in @('Global Administrator', 'Company Administrator', 'Directory Synchronization Accounts') } | % {
            if (!(Get-AzureADDirectoryRoleMember -ObjectId $_.ObjectId |? ObjectId -eq $user.ObjectId)) {
                Write-Information "Adding service account to directory role '$($_.DisplayName)'"
                Add-AzureADDirectoryRoleMember -ObjectId $_.ObjectId -RefObjectId $user.ObjectId | Out-Null
            }
            else {
                Write-Information "Service account already has directory role '$($_.DisplayName)'"
            }
        }

        $getAzureManagementHeaders = {
            @{ Authorization = "Bearer $(Get-SimeonAzureADAccessToken -Resource AzureManagement -Tenant $Tenant)" }
        }

        $getSubscriptionId = {
            try {
                $response = irm "https://management.azure.com/subscriptions?api-version=2019-06-01" -Headers (. $getAzureManagementHeaders)
                $subscriptions = $response.value |? { $Subscription -in @($_.displayName, $_.subscriptionId) }
            }
            catch {
                Write-Warning $_.Exception.Message
                throw "Could not list Azure subscriptions"
            }
            if ($subscriptions.Length -gt 1) {
                throw "Found multiple Azure subscriptions named '$Subscription'"
            }
            if ($subscriptions.Length -eq 1 -and $subscriptions[0].state -ne 'Enabled') {
                throw "Subscription '$Subscription' is not enabled - please install again using an active subscription"
            }
            return $subscriptions[0].subscriptionId
        }

        if (!$Subscription) {
            # Find Azure RM subscription to use
            Write-Information 'Skipping Azure subscription configuration because no subscription was specified'
        }
        else {
            $subscriptionId = . $getSubscriptionId
        }
        if ($Subscription -and !$subscriptionId) {
            # Elevate access to see all subscriptions in the tenant and force re-login
            irm 'https://management.azure.com/providers/Microsoft.Authorization/elevateAccess?api-version=2016-07-01' -Method Post -Headers (. $getAzureManagementHeaders) | Out-Null

            Write-Warning "Elevating access to allow assignment of subscription roles - you will need to sign in again"

            if ($ConfirmPreference -eq 'None') {
                Write-Warning "Tried to elevate access to allow assignment of subscription roles - please verify there is an Azure subscription in the tenant and re-run the install or if you do not want to use an Azure subscription, you can continue anyway, but configuration types that require a subscription will be skipped"
            }
            else {

                Clear-MsalTokenCache -FromDisk
                Clear-MsalTokenCache

                $subscriptionId = . $getSubscriptionId

                if (!$subscriptionId) {
                    Write-Warning "Could not find a subscription to use - please make sure you have signed up for an Azure subscription or if you do not want to use an Azure subscription, you can continue anyway, but configuration types that require a subscription will be skipped"
                }
            }
        }

        if ($subscriptionId) {
            try {
                $contributorRoleId = (irm "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.Authorization/roleDefinitions?`$filter=roleName eq 'Contributor'&api-version=2018-01-01-preview" -Headers (. $getAzureManagementHeaders)).value.id
                $roleAssignments = (irm "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.Authorization/roleAssignments?`$filter=principalId eq '$($user.ObjectId)'&api-version=2018-09-01-preview" -Headers (. $getAzureManagementHeaders)).value |? { $_.properties.roleDefinitionId -eq $contributorRoleId }
            }
            catch {
                Write-Warning $_.Exception.Message
                throw "Could not access subscription '$subscriptionId' - make sure your user has the 'Owner' role on the subscription"
            }
            # Add as contributor to an Azure RM Subscription
            if (!$roleAssignments) {
                Write-Information "Adding service account to 'Contributor' role on subscription '$subscriptionId'"
                try {
                    irm "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.Authorization/roleAssignments/$([guid]::NewGuid())?api-version=2018-09-01-preview" -Method Put -ContentType 'application/json' -Headers (. $getAzureManagementHeaders) -Body @"
{
    "properties": {
        "roleDefinitionId": "$contributorRoleId",
        "principalId": "$($user.ObjectId)",
    }
}
"@| Out-Null
                }
                catch {
                    Write-Warning $_.Exception.Message
                    throw "Could not add 'Contributor' role for service account to subscription '$subscriptionId' - make sure your user has the 'Owner' role on the subscription"
                }
            }
            else {
                Write-Information "Service account already has 'Contributor' role on subscription '$subscriptionId'"
            }
        }

        $cred = [pscredential]::new($upn, (ConvertTo-SecureString -AsPlainText -Force $password))

        try {
            irm "https://login.microsoftonline.com/$Tenant/oauth2/v2.0/token/" -Method Post -Body @{
                client_id = '1950a258-227b-4e31-a9cf-717495945fc2'
                username = $cred.UserName
                password = $cred.GetNetworkCredential().Password
                grant_type = 'password'
                scope = 'https://management.core.windows.net//.default'
            } | Out-Null
        }
        catch {
            $message = $_.Exception.Message
            try { $message = $_.ErrorDetails.Message | ConvertFrom-Json | Select -ExpandProperty error_description | % { $_.Split("`n")[0].Trim() } }
            catch { Write-Error -ErrorRecord $_ -ErrorAction Continue }
            throw "Could not acquire token using the Simeon service account - please ensure that no conditional access policies are blocking $upn (Microsoft 365 Management Service Account) and then install again - $message"
        }

        return $cred
    }

    <#
    .SYNOPSIS
    Creates necessary DevOps repositories and pipelines and securely stores service account credentials
    #>
    function Install-SimeonTenantAzureDevOps {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
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
            # Url of the template git repository to use when creating the repository
            [string]$TemplateRepositoryUrl,
            # The Azure tenant service account credentials to use for running pipelines
            [pscredential]$Credential,
            # Specify to true to require approval when deploying
            [switch]$DisableDeployApproval,
            # Used to create a GitHub service connection to simeoncloud if one doesn't already exist
            [string]$GitHubAccessToken,
            # Settings to write to the pipeline variables
            [hashtable]$PipelineVariables
        )

        if ($Project.Contains(" ")) {
            throw “Project name must not contain spaces”
        }

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

        if (!$PipelineVariables) { $PipelineVariables = @{} }
        $PipelineVariables['ResourceContext:TenantName'] = @{
            allowOverride = $false
            value = $Name
        }

        if (!$TemplateRepositoryUrl) {
            if (!$Baseline) {
                # start with Simeon baseline
                $TemplateRepositoryUrl = 'https://github.com/simeoncloud/Baseline.git'
            }
            else {
                $TemplateRepositoryUrl = 'https://github.com/simeoncloud/DefaultTenant.git'
            }
        }

        Install-SimeonTenantRepository -Organization $Organization -Project $Project -Name $Name -TemplateRepositoryUrl $TemplateRepositoryUrl

        Install-SimeonTenantBaseline -Organization $Organization -Project $Project -Repository $Name -Baseline $Baseline

        Install-SimeonGitHubServiceConnection -Organization $Organization -Project $Project -GitHubAccessToken $GitHubAccessToken

        $environmentArgs = @{}
        @('DisableDeployApproval') | % {
            if ($PSBoundParameters.ContainsKey($_)) { $environmentArgs[$_] = $PSBoundParameters.$_ }
        }

        Install-SimeonTenantPipeline -Organization $Organization -Project $Project -Name $Name -Credential $Credential -PipelineVariables $PipelineVariables @environmentArgs

        Install-SimeonSyncVariableGroup -Organization $Organization -Project $Project
    }

    <#
    .SYNOPSIS
    Creates/updates a shared library for an organization in Azure DevOps
    #>
    function Install-SimeonSyncVariableGroup {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function')]
        [CmdletBinding()]
        param(
            # The Azure DevOps organization name
            [ValidateNotNullOrEmpty()]
            [string]$Organization,
            # The project name in DevOps
            [ValidateNotNullOrEmpty()]
            [string]$Project = 'Tenants'
        )

        $token = Get-SimeonAzureDevOpsAccessToken -Organization $Organization -Project $Project
        $projectsApi = "https://dev.azure.com/$Organization/_apis/projects"
        $restProps = @{
            Headers = @{
                Authorization = "Bearer $token"
                Accept = "application/json;api-version=5.1-preview.1"
            }
            ContentType = 'application/json'
        }

        $projectId = ''
        $projects = irm @restProps $projectsApi -Method Get
        foreach ($prj in $projects.value) {
            if ($prj.name -eq $Project) {
                $projectId = $prj.id
            }
        }

        $variableGroupsApi = "https://dev.azure.com/$Organization/$projectId/_apis/distributedtask/variablegroups"
        $variableGroups = (irm @restProps $variableGroupsApi -Method Get).value
        $createVariableGroup = $true;
        if ($variableGroups) {
            foreach ($variableGroup in $variableGroups) {
                if ($variableGroup.name -eq 'Sync') {
                    $createVariableGroup = $false;
                    break;
                }
            }
        }

        if ($createVariableGroup) {
            $messageBody = (@{
                    description = 'Simeon Sync shared variables'
                    name = 'Sync'
                    providerData = $null
                    type = 'Vsts'
                    variables = @{
                        M365ManagementToolVersion = @{
                            isSecret = $false
                            value = '*'
                        }
                    }
                    variableGroupProjectReferences = @(
                        @{
                            description = 'Sync'
                            name = 'Sync'
                            projectReference = @{
                                id = $projectId
                                name = ''
                            }
                        }
                    )
                } | ConvertTo-Json -Depth 100)

            $newVariableGroup = irm @restProps $variableGroupsApi -Method Post -Body $messageBody

            $newVariableGroupId = $newVariableGroup.id;

            $permissionsApi = "https://dev.azure.com/$Organization/$projectId/_apis/pipelines/pipelinePermissions/variablegroup/$newVariableGroupId"
            $permissionBody = (@{
                    resource = @{
                        id = "$newVariableGroupId"
                        type = 'variablegroup'
                    }
                    pipelines = @()
                    allPipelines = @{
                        authorized = $true
                        authorizedBy = $null
                        authorizedOn = $null
                    }
                } | ConvertTo-Json -Depth 100)
            irm @restProps $permissionsApi -Method Patch -Body $permissionBody
        }

    }

    <#
    .SYNOPSIS
    Creates/updates a repository for a tenant in Azure DevOps
    #>
    function Install-SimeonTenantRepository {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
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
            # Url of the template git repository to use when creating the repository
            [string]$TemplateRepositoryUrl
        )

        if ($Project.Contains(" ")) {
            throw “Project name must not contain spaces”
        }

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

        # Can't use shared function here since it throws error if repo doesn't exist
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

        if (!$repo.defaultBranch) {
            if ($TemplateRepositoryUrl -like 'https://github.com/simeoncloud/*') {
                $accessToken = $env:GITHUB_TOKEN
            }

            Push-Location (Get-GitRepository $TemplateRepositoryUrl -AccessToken $accessToken)
            try {
                if ($token) { $gitConfig = "-c http.extraheader=`"AUTHORIZATION: bearer $token`"" }

                Write-Verbose "Deleting existing .git directory"
                Remove-Item '.\.git' -Recurse -Force

                if (Test-Path -Path '.\.github') {
                    Write-Verbose "Deleting existing .github directory"
                    Remove-Item '.\.github' -Recurse -Force
                }

                Write-Verbose "Initializing new git repository with existing contents"
                Invoke-CommandLine "git init 2>&1" | Write-Verbose
                Initialize-GitConfiguration
                Invoke-CommandLine "git remote add origin $($repo.remoteUrl) 2>&1" | Write-Verbose
                Invoke-CommandLine "git add . 2>&1" | Write-Verbose
                Invoke-CommandLine "git commit -m 'Created Repository' 2>&1" | Write-Verbose

                Write-Verbose "Pushing new repository to remote"
                Invoke-CommandLine "git $gitConfig push --force -u origin --all 2>&1" | Write-Verbose
            }
            finally {
                Pop-Location
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

        if ($Project.Contains(" ")) {
            throw “Project name must not contain spaces”
        }

        Write-Information "Setting baseline for '$Repository'"

        if (!([uri]$Repository).IsAbsoluteUri) {
            $Repository = (Get-AzureDevOpsRepository -Organization $Organization -Project $Project -Name $Repository).remoteUrl
        }
        if ($Baseline -and !([uri]$Baseline).IsAbsoluteUri) {
            $Baseline = (Get-AzureDevOpsRepository -Organization $Organization -Project $Project -Name $Baseline).remoteUrl
        }

        if ($Repository -eq $Baseline) {
            throw "A repository cannot use itself as a baseline"
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
                @($baselinePath, ".git/modules/$baselinePath", ".gitmodules") |? { Test-Path $_ } | Remove-Item -Force -Recurse -EA SilentlyContinue
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

        if ($Project.Contains(" ")) {
            throw “Project name must not contain spaces”
        }

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
        $gitHubConnectionBody = @"
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

        if (!$serviceEndpoint) {
            Write-Information "Creating 'simeoncloud' GitHub service connection"
            while (!$GitHubAccessToken -and $ConfirmPreference -ne 'None') { $GitHubAccessToken = Read-Host 'Enter GitHub access token provided by Simeon support' }
            if (!$GitHubAccessToken) { throw "GitHubAccessToken not specified" }
            $serviceEndpoint = irm @restProps "$apiBaseUrl/$Project/_apis/serviceendpoint/endpoints" -Method Post -Body $gitHubConnectionBody
        }
        elseif ($GitHubAccessToken) {
            Write-Information "Updating access token for GitHub service connection 'simeoncloud'"
            $serviceEndpoint = irm @restProps "$apiBaseUrl/$Project/_apis/serviceendpoint/endpoints/$($serviceEndpoint.id)" -Method Put -Body $gitHubConnectionBody
        }
        else {
            Write-Information "GitHub service connection 'simeoncloud' already exists and does not require an update"
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
        $packagesConnectionBody = @"
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

        if (!$serviceEndpoint) {
            Write-Information "Creating 'simeoncloud-packages' GitHub service connection"
            while (!$GitHubAccessToken -and $ConfirmPreference -ne 'None') { $GitHubAccessToken = Read-Host 'Enter GitHub access token provided by Simeon support' }
            if (!$GitHubAccessToken) { throw "GitHubAccessToken not specified" }
            $serviceEndpoint = irm @restProps "$apiBaseUrl/$Project/_apis/serviceendpoint/endpoints" -Method Post -Body $packagesConnectionBody
        }
        elseif ($GitHubAccessToken) {
            Write-Information "Updating access token for GitHub service connection 'simeoncloud-packages'"
            $serviceEndpoint = irm @restProps "$apiBaseUrl/$Project/_apis/serviceendpoint/endpoints/$($serviceEndpoint.id)" -Method Put -Body $packagesConnectionBody
        }
        else {
            Write-Information "GitHub service connection 'simeoncloud-packages' already exists and does not require an update"
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
    Creates/updates the pipeline used to send organization summary emails
    #>
    function Install-SimeonReportingPipeline {
        param(
            # The Azure DevOps organization name
            [ValidateNotNullOrEmpty()]
            [string]$Organization,
            # The project name in DevOps
            [ValidateNotNullOrEmpty()]
            [string]$Project = 'Tenants',
            # Email address used to send emails from
            [string]$FromEmailAddress,
            # Password for authenticating to smtp server
            [ValidateNotNullOrEmpty()]
            [string]$SmtpUserPassword,
            # Use this user for smtp credential object if specified, if not will use FromEmailAddress
            [string]$SmtpUser,
            # Semicolon delimited list of email addresses to send the summary email, if not provided uses all non-Simeon orginzation users
            [string]$SendSummaryEmailToAddresses,
            # Semicolon delimited list of email addresses to include in the CC for the summary email
            [string]$ToCCAddress,
            # Semicolon delimited list of email addresses to include in the BCC for the summary email
            [string]$ToBccAddress,
            # By default the email will be sent to all non-simeon users in the devops org, this can be used to exclude users
            [string]$ExcludeUsersFromSummaryEmail,
            # By default the email will be generated for all pipelines in the org, this can be used to exclude pipelines
            [string]$ExcludePipelinesFromEmail,
            # The server used to send emails from, defaults to smtp.office365.com
            [string]$SmtpServer = "smtp.office365.com",
            # The port used to send emails from, defaults to 587
            [int]$SmtpPort = 587
        )

        if ($Project.Contains(" ")) {
            throw “Project name must not contain spaces”
        }

        $token = Get-SimeonAzureDevOpsAccessToken -Organization $Organization -Project $Project

        $restProps = @{
            Headers = @{
                Authorization = "Bearer $token"
                Accept = "application/json;api-version=5.1-preview"
            }
            ContentType = 'application/json'
        }

        $apiBaseUrl = "https://dev.azure.com/$Organization/$Project/_apis"
        $pipelineName = "SummaryEmail"
        $pipeline = (irm @restProps "$apiBaseUrl/build/definitions" -Method Get).value |? name -eq $pipelineName

        $pipelineVariables = @{
            FromEmailAddress = @{
                value = $FromEmailAddress
            }
            SmtpUserPassword = @{
                value = $SmtpUserPassword
                isSecret = $true
            }
            ToCCAddress = @{
                value = $ToCCAddress
            }
            ToBccAddress = @{
                value = $ToBccAddress
            }
            ExcludeUsersFromSummaryEmail = @{
                value = $ExcludeUsersFromSummaryEmail
            }
            SendSummaryEmailToAddresses = @{
                value = $SendSummaryEmailToAddresses
            }
            ExcludePipelinesFromEmail = @{
                value = $ExcludePipelinesFromEmail
            }
            SmtpServer = @{
                value = $SmtpServer
            }
            SmtpPort = @{
                value = "$SmtpPort"
            }
            SmtpUser = @{
                value = $SmtpUser
            }
        }
        $queueName = $poolName = "Azure Pipelines"
        $queueId = ((irm @restProps "$apiBaseUrl/distributedtask/queues?api-version=6.1-preview.1").Value |? Name -eq $queueName).id
        $poolId = ((irm @restProps "https://dev.azure.com/$Organization/_apis/distributedtask/pools").Value |? Name -eq $poolName).id
        Install-SimeonTenantRepository -Organization $Organization -Project $Project -Name "Jobs" -TemplateRepositoryUrl 'https://github.com/simeoncloud/OrganizationJobs.git'
        $repo = Get-AzureDevOpsRepository -Organization $Organization -Project $Project -Name "Jobs"

        #$set scheduled on pipeline
        $body = @{
            name = $pipelineName
            process = @{
                type = 2
                yamlFilename = "$pipelineName.yml"
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
            uri = "$pipelineName.yml"
            variables = $pipelineVariables
        }

        if ($pipeline) {
            $definition = irm @restProps "$apiBaseUrl/build/definitions/$($pipeline.id)?revision=$($pipeline.revision)" -Method Get

            $body.variables = $definition.variables
            # disabled or enabled
            $body.queueStatus = $definition.queueStatus
            # keep schedule already defined
            if ($definition.triggers) {
                $body.triggers = $definition.triggers
            }

            if (!$body.variables) {
                $body.variables = [pscustomobject]@{}
            }

            # if a variable doesn't exist add, if they key exists don't update value
            foreach ($kvp in $pipelineVariables.GetEnumerator()) {
                if (!($body.variables | gm $kvp.Key)) {
                    $body.variables | Add-Member $kvp.Key $kvp.Value
                }
            }

            $body += @{
                id = $pipeline.id
                revision = $pipeline.revision
                options = $definition.options
            }

            irm @restProps "$apiBaseUrl/build/definitions/$($pipeline.id)" -Method Put -Body ($body | ConvertTo-Json -Depth 10) | Out-Null
        }
        else {
            Write-Information "Creating pipeline '$pipelineName'"
            irm @restProps "$apiBaseUrl/build/definitions" -Method Post -Body ($body | ConvertTo-Json -Depth 10) | Out-Null
        }
    }

    <#
    .SYNOPSIS
    Creates/updates the pipeline used to retry failed pipelines
    #>
    function Install-SimeonRetryPipeline {
        param(
            # The Azure DevOps organization name
            [ValidateNotNullOrEmpty()]
            [string]$Organization,
            # The project name in DevOps
            [ValidateNotNullOrEmpty()]
            [string]$Project = 'Tenants'
        )

        if ($Project.Contains(" ")) {
            throw “Project name must not contain spaces”
        }

        $token = Get-SimeonAzureDevOpsAccessToken -Organization $Organization -Project $Project

        $restProps = @{
            Headers = @{
                Authorization = "Bearer $token"
                Accept = "application/json;api-version=5.1-preview"
            }
            ContentType = 'application/json'
        }

        $apiBaseUrl = "https://dev.azure.com/$Organization/$Project/_apis"
        $pipelineName = "RetryPipelines"
        $pipeline = (irm @restProps "$apiBaseUrl/build/definitions" -Method Get).value |? name -eq $pipelineName

        $queueName = $poolName = "Azure Pipelines"
        $queueId = ((irm @restProps "$apiBaseUrl/distributedtask/queues?api-version=6.1-preview.1").Value |? Name -eq $queueName).id
        $poolId = ((irm @restProps "https://dev.azure.com/$Organization/_apis/distributedtask/pools").Value |? Name -eq $poolName).id

        Install-SimeonTenantRepository -Organization $Organization -Project $Project -Name "Jobs" -TemplateRepositoryUrl 'https://github.com/simeoncloud/OrganizationJobs.git'
        $repo = Get-AzureDevOpsRepository -Organization $Organization -Project $Project -Name "Jobs"


        $body = @{
            name = $pipelineName
            process = @{
                type = 2
                yamlFilename = "$pipelineName.yml"
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
            uri = "$pipelineName.yml"
        }

        if ($pipeline) {
            $definition = irm @restProps "$apiBaseUrl/build/definitions/$($pipeline.id)?revision=$($pipeline.revision)" -Method Get

            $body.variables = $definition.variables
            # disabled or enabled
            $body.queueStatus = $definition.queueStatus
            # keep schedule already defined
            if ($definition.triggers) {
                $body.triggers = $definition.triggers
            }

            if (!$body.variables) {
                $body.variables = [pscustomobject]@{}
            }

            $body += @{
                id = $pipeline.id
                revision = $pipeline.revision
                options = $definition.options
            }

            irm @restProps "$apiBaseUrl/build/definitions/$($pipeline.id)" -Method Put -Body ($body | ConvertTo-Json -Depth 10) | Out-Null
        }
        else {
            Write-Information "Creating pipeline '$pipelineName'"
            irm @restProps "$apiBaseUrl/build/definitions" -Method Post -Body ($body | ConvertTo-Json -Depth 10) | Out-Null
        }
    }

    <#
    .SYNOPSIS
    Creates/updates pipelines for a Simeon tenant
    #>
    function Install-SimeonTenantPipeline {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
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
            [switch]$DisableDeployApproval,
            # Settings to write to the pipeline variables
            [hashtable]$PipelineVariables
        )

        if ($Project.Contains(" ")) {
            throw “Project name must not contain spaces”
        }

        $Name = $Name.ToLower()

        Install-SimeonTenantPipelineTemplateFile -Organization $Organization -Project $Project -Repository $Name -UseServiceAccount ([boolean]$Credential)

        $environmentArgs = @{}
        @('DisableDeployApproval') | % {
            if ($PSBoundParameters.ContainsKey($_)) { $environmentArgs[$_] = $PSBoundParameters.$_ }
        }

        Install-SimeonTenantPipelineEnvironment -Organization $Organization -Project $Project -Name $Name @environmentArgs

        Write-Information "Installing pipelines for '$Name'"

        $token = Get-SimeonAzureDevOpsAccessToken -Organization $Organization -Project $Project

        $restProps = @{
            Headers = @{
                Authorization = "Bearer $token"
                Accept = "application/json;api-version=5.1-preview"
            }
            ContentType = 'application/json'
        }
        $apiBaseUrl = "https://dev.azure.com/$Organization/$Project/_apis"

        $pipelines = irm @restProps "$apiBaseUrl/build/definitions" -Method Get

        if (!$PipelineVariables) { $PipelineVariables = @{} }

        if ($Credential.UserName) {
            $PipelineVariables['AadAuth:Username'] = @{
                allowOverride = $false
                value = $Credential.UserName
            }
        }
        if ($Credential -and $Credential.GetNetworkCredential().Password) {
            $PipelineVariables['AadAuth:Password'] = @{
                allowOverride = $false
                isSecret = $true
                value = $Credential.GetNetworkCredential().Password
            }
        }

        $repo = Get-AzureDevOpsRepository -Organization $Organization -Project $Project -Name $Name

        $queueName = $poolName = "Azure Pipelines"
        $queueId = ((irm @restProps "$apiBaseUrl/distributedtask/queues?api-version=6.1-preview.1").Value |? Name -eq $queueName).id
        $poolId = ((irm @restProps "https://dev.azure.com/$Organization/_apis/distributedtask/pools").Value |? Name -eq $poolName).id

        foreach ($action in @('Sync')) {
            $pipelineName = "$Name - $action"

            $pipeline = $pipelines.value |? name -eq $pipelineName

            $body = @{
                name = $pipelineName
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
                if (!$Credential) { $body.variables | gm |? Name -in @('AadAuth:Username', 'AadAuth:Password', 'AadAuth:TenantId', 'AzureManagement:SubscriptionId') | % { $body.variables.PSObject.Properties.Remove($_.Name) } }
                $body.queueStatus = $definition.queueStatus

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
                $pipeline = Invoke-WithRetry { irm @restProps "$apiBaseUrl/build/definitions" -Method Post -Body ($body | ConvertTo-Json -Depth 10) }
            }

            if (!$Credential) {
                $cachePath = [System.IO.Path]::GetTempFileName()

                #zip cache
                Compress-Archive $cachePath "$cachePath.zip" -CompressionLevel Optimal -Force | Out-Null

                $secureFileName = "$pipelineName"
                $secureFilesUri = "$apiBaseUrl/distributedtask/securefiles"

                # can't update existing secure files - delete and recreate
                $secureFileId = Invoke-WithRetry { ((Invoke-RestMethod @restProps "$secureFilesUri" -Method Get).value |? name -eq $secureFileName).id }
                if ($secureFileId) {
                    Write-Information "Deleting existing secure file $secureFileName ($secureFileId)"
                    Invoke-WithRetry { Invoke-RestMethod @restProps "$secureFilesUri/$secureFileId" -Method Delete | Out-Null }
                }

                Write-Information "Creating secure file $secureFileName"
                $createSecureFileUri = "$secureFilesUri`?name=$([System.Net.WebUtility]::UrlEncode($secureFileName))"
                $secureFileCreateRestProps = $restProps.Clone()
                $secureFileCreateRestProps['ContentType'] = 'application/octet-stream'
                $secureFile = Invoke-WithRetry { (Invoke-RestMethod @secureFileCreateRestProps $createSecureFileUri -Method Post -InFile "$cachePath.zip") }
                $secureFileId = $secureFile.id
                Write-Information "Created secure file $secureFileId"

                Write-Information "Setting secure file $secureFileId to be accessible by pipeline $($pipeline.id)"
                Invoke-WithRetry { Invoke-RestMethod @restProps "$apiBaseUrl/pipelines/pipelinePermissions/securefile/$secureFileId" -Method Patch -Body (@{
                            resources = @{}
                            pipelines = @(@{ authorized = $true; id = $($pipeline.id) })
                        } | ConvertTo-Json -Depth 100) | Out-Null }

                # Set Role Assignment
                foreach ($user in @("$Project Build Service", "Project Collection Build Service")) {
                    $projectId = Get-AzureDevOpsProjectId -Organization $Organization -Project $Project
                    $identities = Invoke-WithRetry { Invoke-RestMethod @restProps "https://dev.azure.com/$Organization/_apis/IdentityPicker/Identities" -Method Post -Body @"
                        {
                            "query": "$user",
                            "identityTypes": [
                                "user"
                            ],
                            "operationScopes": [
                                "ims",
                                "source"
                            ],
                            "options": {
                                "MinResults": 1,
                                "MaxResults": 1000
                            },
                            "properties": [
                                "DisplayName"
                            ]
                        }
"@ }
                    $userDisplayName = "$user ($Organization)"
                    $userId = $identities.results.identities |? displayName -eq $userDisplayName | Select -ExpandProperty localId
                    Write-Information "Making $userDisplayName ($userId) admin for secure file $secureFileId"

                    Invoke-WithRetry { Invoke-RestMethod @restProps -Method Put "https://dev.azure.com/$Organization/_apis/securityroles/scopes/distributedtask.securefile/roleassignments/resources/$projectId`$$($secureFileId)?api-version=6.0-preview" -Body @"
                    [
                        {
                            "roleName": "Administrator",
                            "userId": "$userId"
                        }
                    ]
"@ | Out-Null }
                }
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
            [switch]$DisableDeployApproval
        )

        if ($Project.Contains(" ")) {
            throw “Project name must not contain spaces”
        }

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

        $environment = $environments.value |? name -eq $Name

        if (!$environment) {
            Write-Information "Creating environment '$Name'"

            $environment = irm @restProps "$apiBaseUrl/distributedtask/environments" -Method Post -Body @"
{"description": "", "name": "$Name"}
"@
        }
        else {
            Write-Information "Environment '$Name' already exists"
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
                    "MaxResults": 1000
                },
                "properties": [
                    "DisplayName"
                ]
            }
"@

        $contributorsDisplayName = "[$Project]\Contributors"
        $contributorsId = $identities.results.identities |? displayName -eq $contributorsDisplayName | Select -ExpandProperty localId
        if (!$contributorsId) { throw "Could not find Contributors group for project $Project - response was:`r`n$($identities | ConvertTo-Json -Depth 100)" }

        irm @restProps "https://dev.azure.com/$Organization/_apis/securityroles/scopes/distributedtask.environmentreferencerole/roleassignments/resources/$($environment.project.id)_$($environment.id)" -Method Put -Body @"
            [{"userId":"$contributorsId","roleName":"Administrator"}]
"@ | Out-Null

        $approvals = irm @restProps "$apiBaseUrl/pipelines/checks/configurations?resourceType=environment&resourceId=$($environment.id)"
        $approvalUrl = $approvals.value |? { $_.type.name -eq 'Approval' } | Select -ExpandProperty url
        if ($approvalUrl -and $DisableDeployApproval) {
            Write-Information "Removing existing approval check"
            irm @restProps $approvalUrl -Method Delete | Out-Null
        }
        elseif (!$approvalUrl -and !$DisableDeployApproval) {
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

        # Allow pipeline to use environment
        $environmentPermissionsUrl = "$apiBaseUrl/pipelines/pipelinepermissions/environment/$($environment.id)"
        Invoke-WithRetry { Invoke-RestMethod @restProps -Uri $environmentPermissionsUrl -Method Patch -Body @"
        {
            "resource":{"type":"environment","id":"$($environment.id)"},
            "pipelines":[],
            "allPipelines":{"authorized":true,"authorizedBy":null,"authorizedOn":null}
        }
"@ } | Out-Null
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
            [string]$Repository,
            [boolean]$UseServiceAccount
        )

        if ($Project.Contains(" ")) {
            throw “Project name must not contain spaces”
        }

        Write-Information "Installing pipeline template files for '$Organization'"

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
            $('Sync') | % {
                Write-Verbose "Downloading $_.yml from Simeon Repo $ymlRepo"
                if (Test-Path "$_.yml") { Remove-Item "$_.yml" -Force -EA SilentlyContinue }
                irm "https://raw.githubusercontent.com/simeoncloud/$ymlRepo/master/$_.yml" -OutFile "$_.yml"
            }

            if (!$UseServiceAccount) {
                Write-Verbose "Writing Cache parameter to Sync.yml"
                $syncYaml = Get-Content -Raw 'Sync.yml' | ConvertFrom-Yaml -Ordered
                $syncYaml.stages[0].parameters.UseCache = $true

                $output = (ConvertTo-Yaml $syncYaml)
                # This is required becuase the ConvertTo-Yaml adds single quotes around double quotes
                $output.Replace("""'", '"').Replace("'""", '"') | Set-Content 'Sync.yml' -Force
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
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
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
            # Url of the template git repository to use when creating the repository
            [string]$TemplateRepositoryUrl,
            # Indicates the Azure subscription to use
            [string]$Subscription,
            # Specify to true to not require deploy approval
            [switch]$DisableDeployApproval,
            # Used to create a GitHub service connection to simeoncloud if one doesn't already exist
            [string]$GitHubAccessToken,
            # Install a Simeon Service account vs. use Delegated Auth
            [boolean]$UseServiceAccount
        )

        if ($Project.Contains(" ")) {
            throw “Project name must not contain spaces”
        }

        while (!$Tenant) { $Tenant = Read-Tenant }

        $credential = $null
        if ($UseServiceAccount) {
            $credential = Install-SimeonTenantServiceAccount -Tenant $Tenant -Subscription $Subscription
        }
        else {
            Remove-SimeonTenantServiceAccount -Tenant $Tenant
            Install-SimeonTenantAzureADAppPermission -Tenant $Tenant
        }

        $devOpsArgs = @{}
        @('Organization', 'Project', 'Name', 'Baseline', 'DisableDeployApproval', 'TemplateRepositoryUrl') |? { $PSBoundParameters.ContainsKey($_) } | % {
            $devOpsArgs[$_] = $PSBoundParameters.$_
        }

        $pipelineVariables = @{}
        $pipelineVariables['AzureManagement:SubscriptionId'] = @{
            allowOverride = $false
            value = $Subscription ?? ' '
        }

        if (!$UseServiceAccount) {
            $pipelineVariables['AadAuth:TenantId'] = @{
                allowOverride = $false
                value = $Tenant
            }
        }

        Install-SimeonTenantAzureDevOps @devOpsArgs -Credential $credential -PipelineVariables $pipelineVariables

        Write-Information "Completed installing tenant"
    }

    <#
    .SYNOPSIS
        Creates and/or configures the provided Azure DevOps organization to be compatible with Simeon Cloud
    #>
    function Install-SimeonDevOpsOrganization {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
        param (
            [ValidateNotNullOrEmpty()]
            [string]$Organization,
            # Disconnects the Dev Ops organization from Azure AD (Beware when using this option as you can lose access to the org)
            [switch]$DisconnectDevOpsOrganizationFromAzureAd,
            [string]$Project = "Tenants",
            [string]$DevOpsRegion = "CUS",
            [string]$GitHubAccessTokenKeyVaultUrl = "https://installer.vault.azure.net/secrets/$Organization",
            [string]$ReportingEmailPasswordKeyVaultUrl = "https://installer.vault.azure.net/secrets/ReportingEmailPw",
            # List of user email addresses to invite to the DevOps organization and make project collection admins
            [string[]]$InviteToOrgAsAdmin = "devops@simeoncloud.com",
            [string]$PipelineNotificationEmail = "pipelinenotifications@simeoncloud.com"
        )

        if ($Project.Contains(" ")) {
            throw “Project name must not contain spaces”
        }

        Write-Information "Getting required values from Key Vault"
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

        $authenicationHeader = Get-AzureDevOpsAuthHeader

        # Check for org, create if it doesn't exist
        Write-Information "Validating DevOps organization"
        Invoke-Command -ScriptBlock {
            Write-Information "Checking if Organization: $Organization is available"
            $existingOrg = Invoke-WithRetry { Invoke-RestMethod -Header $authenicationHeader -Uri "https://aex.dev.azure.com/_apis/HostAcquisition/NameAvailability/$Organization" -Method Get }
            if (!$existingOrg.isAvailable) {
                $currentUserId = (Invoke-WithRetry { Invoke-RestMethod -Header $authenicationHeader -Uri "https://app.vssps.visualstudio.com/_apis/profile/profiles/me?api-version=5.1" -Method Get }).id
                $accessToOrgs = (Invoke-WithRetry { Invoke-RestMethod -Header $authenicationHeader -Uri "https://app.vssps.visualstudio.com/_apis/accounts?memberId=$currentUserId&api-version=5.1" -Method Get }).value
                if ($accessToOrgs.accountName -contains "$Organization") {
                    Write-Information "DevOps Organization: $Organization exists and current user has access"
                }
                else {
                    throw "DevOps Organization: $Organization exists but the current user does not have access to $Organization"
                }
            }
            else {
                Write-Information "Creating DevOps Organization: $Organization"
                Invoke-WithRetry { Invoke-RestMethod -Headers $authenicationHeader -ContentType "application/json" -Method Post -Uri "https://aex.dev.azure.com/_apis/HostAcquisition/Collections?collectionName=$Organization`&preferredRegion=$DevOpsRegion&api-version=5.0-preview.2" -Body @"
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

        # Even though this property is set to true on org creation, setting setting is not always correct for the org
        Write-Information "Checking box to use new URL"
        Invoke-Command -ScriptBlock {
            Invoke-WithRetry { Invoke-RestMethod -Headers $authenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/NewDomainUrlOrchestration?codexDomainUrls=true&api-version=5.0-preview.1" -Method Post -ContentType "application/json" } | Out-Null
        }

        Write-Information "Inviting users to org and setting permissions."
        Invoke-Command -ScriptBlock {
            $groups = (Invoke-WithRetry { Invoke-RestMethod -Header $authenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/groups?api-version=6.1-preview.1" -Method Get }).value
            $users = (Invoke-WithRetry { Invoke-RestMethod -Header $authenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/users?api-version=6.1-preview.1" -Method Get }).value
            foreach ($userToInvite in $InviteToOrgAsAdmin) {
                if ($users.principalName -notcontains $userToInvite) {
                    # Send invite to org
                    Write-Information "Sending invite to DevOps Organization: $Organization for user: $userToInvite"
                    Invoke-WithRetry { Invoke-RestMethod -Header $authenicationHeader -Uri "https://vsaex.dev.azure.com/$Organization/_apis/UserEntitlements?api-version=5.1-preview.3" -Method Patch -ContentType "application/json-patch+json" -Body @"
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
                }

                # assign project collection admin
                if ($userToInvite) {
                    Write-Information "Making user: $userToInvite Project Collection Admin"
                    $projectCollectionAdminGroupDescriptor = ($groups |? displayname -eq "Project Collection Administrators").descriptor
                    $userToInviteDescriptor = ((Invoke-WithRetry { Invoke-RestMethod -Header $authenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/users?api-version=6.1-preview.1" -Method Get }).value |? { $_.principalName -eq "$userToInvite" -and $_.origin -eq "aad" }).descriptor
                    Invoke-WithRetry { Invoke-RestMethod -Header $authenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/memberships/$userToInviteDescriptor/$projectCollectionAdminGroupDescriptor`?api-version=6.1-preview.1" -Method Put } | Out-Null
                }
            }
        }

        # Organization Settings > Pipelines > Settings > uncheck Limit job authorization scope to current project for non-release pipelines (enforceReferencedRepoScopedToken), Limit job authorization scope to referenced Azure DevOps repositories (enforceJobAuthScope), and Limit variables that can be set at queue time (enforceSettableVar)
        Write-Information "Unchecking Limit job authorization scope to current project for non-release pipelines"
        Invoke-Command -ScriptBlock {
            Invoke-WithRetry { Invoke-RestMethod -Header $authenicationHeader -Uri "https://dev.azure.com/$Organization/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1" -Method Post -ContentType "application/json" -Body @"
            {
                "contributionIds": [
                    "ms.vss-build-web.pipelines-org-settings-data-provider"
                ],
                "dataProviderContext": {
                    "properties": {
                        "enforceSettableVar": "false",
                        "enforceJobAuthScope": "false",
                        "enforceReferencedRepoScopedToken": "false",
                        "sourcePage": {
                            "url": "https://dev.azure.com/$Organization/_settings/pipelinessettings",
                            "routeId": "ms.vss-admin-web.collection-admin-hub-route",
                            "routeValues": {
                                "adminPivot": "pipelinessettings",
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

        Write-Information "Setting project information"
        Invoke-Command -ScriptBlock {
            # Set or get Project id
            $projectId = (Get-AzureDevOpsProjectId -Organization $Organization -Project $Project)
            if (!$projectId) {
                Write-Information "Creating project: $Project"
                Invoke-WithRetry { Invoke-RestMethod -Header $authenicationHeader -Uri "https://dev.azure.com/$Organization/_apis/projects?api-version=6.1-preview.4" -Method Post -ContentType "application/json" -Body @"
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
                $projectId = (Get-AzureDevOpsProjectId -Organization $Organization -Project $Project)
                # Repositories > rename $Project to default
                Write-Information "Renaming the repository: $Project to default"
                $repos = (Invoke-WithRetry { Invoke-RestMethod -Header $authenicationHeader -Uri "https://dev.azure.com/$Organization/$projectId/_apis/git/repositories?api-version=6.0" -Method Get }).value
                if ($repos.name -contains "$Project") {
                    $repoId = ($repos |? { $_.name -eq "$Project" }).id
                    Invoke-WithRetry { Invoke-RestMethod -Headers $authenicationHeader -Uri "https://dev.azure.com/$Organization/$projectId/_apis/git/repositories/$repoId`?api-version=5.0" -Method Patch -Body '{"name":"default"}' -ContentType "application/json" } | Out-Null
                }
            }
            # Overview > uncheck Boards and Test Plans
            Write-Information "Updating project settings turning off Boards and Test Plans"
            Invoke-WithRetry { Invoke-RestMethod -Header $authenicationHeader -Uri "https://dev.azure.com/$Organization/_apis/FeatureManagement/FeatureStates/host/project/$projectId/ms.vss-work.agile?api-version=4.1-preview.1" -Method Patch -ContentType "application/json" -Body @"
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
            Invoke-WithRetry { Invoke-RestMethod -Header $authenicationHeader -Uri "https://dev.azure.com/$Organization/_apis/FeatureManagement/FeatureStates/host/project/$projectId/ms.feed.feed?api-version=4.1-preview.1" -Method Patch -ContentType "application/json" -Body @"
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

        ## Project settings
        Write-Information "Configuring pipeline settings"
        Invoke-Command -ScriptBlock {
            # Pipelines > Settings > uncheck Limit job authorization scope to current project for non-release pipelines (enforceReferencedRepoScopedToken), Limit job authorization scope to referenced Azure DevOps repositories (enforceJobAuthScope), and Limit variables that can be set at queue time (enforceSettableVar)
            Write-Information "Updating general pipeline settings"
            Invoke-WithRetry { Invoke-RestMethod -Header $authenicationHeader -Uri "https://dev.azure.com/$Organization/_apis/Contribution/HierarchyQuery?api-version=5.0-preview.1" -Method Post -ContentType "application/json" -Body @"
                {
                    "contributionIds": [
                        "ms.vss-build-web.pipelines-general-settings-data-provider"
                    ],
                    "dataProviderContext": {
                        "properties": {
                            "enforceSettableVar": "false",
                            "enforceJobAuthScope": "false",
                            "enforceReferencedRepoScopedToken": "false",
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
            $projectId = (Get-AzureDevOpsProjectId -Organization $Organization -Project $Project)
            $users = (Invoke-WithRetry { Invoke-RestMethod -Header $authenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/users?api-version=6.1-preview.1" -Method Get }).value
            $groups = (Invoke-WithRetry { Invoke-RestMethod -Header $authenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/groups?api-version=6.1-preview.1" -Method Get }).value

            #  Permissions > Contributors > Members > Add > $Project Build Service
            ### Contributors group actions
            Write-Information "Configuring permissions for Contributors group"
            Write-Information "Adding $Project Build Service ($Organization)"
            $contributorsgroupDescriptor = ($groups |? principalName -eq "[$Project]\Contributors").descriptor
            $buildServiceUserDescriptor = ($users |? displayName -like "$Project Build Service (*").descriptor
            Invoke-WithRetry { Invoke-RestMethod -Header $authenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/memberships/$buildServiceUserDescriptor/$contributorsgroupDescriptor`?api-version=6.1-preview.1" -Method Put } | Out-Null

            # Add project collection build service user to tenants contributors
            Write-Information "Adding Project Collection Build Service ($Organization)"
            $collectionBuildService = ($users |? displayName -like "Project Collection Build Service (*").descriptor
            Invoke-WithRetry { Invoke-RestMethod -Header $authenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/memberships/$collectionBuildService/$contributorsgroupDescriptor`?api-version=6.1-preview.1" -Method Put } | Out-Null

            # Repositories > Permissions > Contributors > allow Create repository
            Set-AzureDevOpsAccessControlEntry -Organization $Organization -ProjectId $projectId -SubjectGroupPrincipalName "[$Project]\Contributors" -PermissionNumber 256 -PermissionDescription "Create Repository"
            Set-AzureDevOpsAccessControlEntry -Organization $Organization -ProjectId $projectId -SubjectGroupPrincipalName "[$Project]\Contributors" -PermissionNumber 8 -PermissionDescription "Force Push"
            Set-AzureDevOpsAccessControlEntry -Organization $Organization -ProjectId $projectId -SubjectGroupPrincipalName "[$Project]\Contributors" -PermissionNumber 16384 -PermissionDescription "Administer build permissions"
        }

        # Invite users to tenants contributor group
        if ($InviteToOrgAsAdmin) {
            foreach ($user in $InviteToOrgAsAdmin) {
                Invoke-Command -ScriptBlock {
                    Write-Information "Adding user $user to Contributors group"
                    $groups = (Invoke-WithRetry { Invoke-RestMethod -Header $authenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/groups?api-version=6.1-preview.1" -Method Get }).value
                    $contributorsgroupDescriptor = ($groups |? principalName -eq "[$Project]\Contributors").descriptor
                    $userDescriptor = ((Invoke-WithRetry { Invoke-RestMethod -Header $authenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/users?api-version=6.1-preview.1" -Method Get }).value |? { $_.principalName -eq "$user" -and $_.origin -eq "aad" }).descriptor
                    Invoke-WithRetry { Invoke-RestMethod -Header $authenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/memberships/$userDescriptor/$contributorsgroupDescriptor`?api-version=6.1-preview.1" -Method Put } | Out-Null
                }
            }
        }

        # Create Service connection
        Write-Information "Creating GitHub Service connection"
        Install-SimeonGitHubServiceConnection -Organization $Organization -Project $Project -GitHubAccessToken $gitHubAccessToken

        # Install Retry failed Pipelines
        Write-Information "Installing retry pipelines"
        Install-SimeonRetryPipeline -Organization $Organization

        # Install SummaryReport pipeline
        Write-Information "Installing reporting pipeline"
        Install-SimeonReportingPipeline -FromEmailAddress 'noreply@simeoncloud.com' -SmtpUserPassword $reportingEmailPw -ToBccAddress '70e1ed48.simeoncloud.com@amer.teams.ms' -Organization $Organization

        Write-Information "Updating permissions for GitHub service connection and project library"
        Invoke-Command -ScriptBlock {
            $projectId = (Get-AzureDevOpsProjectId -Organization $Organization -Project $Project)
            $groups = (Invoke-WithRetry { Invoke-RestMethod -Header $authenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/groups?api-version=6.1-preview.1" -Method Get }).value

            # Navigate to Project settings > Service connections > ... > Security > Add > Contributors > set role to Administrator > Add
            Write-Information "Making Contributors admin for GitHub service connection"
            $contributorsGroupId = ($groups |? principalName -eq "[$Project]\Contributors").originId
            Invoke-WithRetry { Invoke-RestMethod -Header $authenicationHeader -Uri "https://dev.azure.com/$Organization/_apis/securityroles/scopes/distributedtask.project.serviceendpointrole/roleassignments/resources/$projectId`?api-version=5.0-preview.1" -Method Put -ContentType "application/json" -Body @"
                [
                    {
                        "roleName": "Administrator",
                        "userId": "$contributorsGroupId"
                    }
                ]
"@
            } | Out-Null
        }



        $identities = Invoke-WithRetry { Invoke-RestMethod -Header $authenicationHeader -Uri "https://dev.azure.com/$Organization/_apis/IdentityPicker/Identities`?api-version=5.0-preview.1" -Method Post -ContentType "application/json" -Body @"
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
                "MaxResults": 1000
            },
            "properties": [
                "DisplayName"
            ]
        }
"@
        }

        $contributorsDisplayName = "[$Project]\Contributors"
        $contributorsId = $identities.results.identities |? displayName -eq $contributorsDisplayName | Select -ExpandProperty localId
        $projectId = (Get-AzureDevOpsProjectId -Organization $Organization -Project $Project)

        Write-Information "Making Contributors admin for project library"
        Invoke-WithRetry { Invoke-RestMethod -Header $authenicationHeader -Uri "https://dev.azure.com/$Organization/_apis/securityroles/scopes/distributedtask.library/roleassignments/resources/$projectId`$0`?api-version=6.1-preview.1" -Method Put -ContentType "application/json" -Body @"
        [
            {
                "roleName": "Administrator",
                "userId": "$contributorsId"
            }
        ]
"@
    } | Out-Null

        # Install code search Organization settings > Extensions > Browse marketplace > search for Code Search > Get it free
        Write-Information "Installing code search"
        Invoke-Command -ScriptBlock {
            Invoke-WithRetry { Invoke-RestMethod -Header $authenicationHeader -Uri "https://extmgmt.dev.azure.com/$Organization/_apis/ExtensionManagement/AcquisitionRequests?api-version=6.1-preview.1" -Method Post -ContentType "application/json" -Body @"
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
            $projectId = (Get-AzureDevOpsProjectId -Organization $Organization -Project $Project)
            $groups = (Invoke-WithRetry { Invoke-RestMethod -Header $authenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/graph/groups?api-version=6.1-preview.1" -Method Get }).value

            # Project settings > Notifications > New subscription > Build > A build completes > Next > change 'Deliver to' to custom email address > pipelinenotifications@simeoncloud.com
            $existingSubscriptions = (Invoke-WithRetry { Invoke-RestMethod -Header $authenicationHeader -Uri "https://dev.azure.com/$Organization/_apis/notification/Subscriptions?api-version=6.1-preview.1" -Method Get }).value
            # Need to get address long way due to this https://github.com/PowerShell/PowerShell/issues/8105
            $subExists = ((($existingSubscriptions |? { $_.description -eq "A build completes" }).channel | Select -Property address) |? { $_ -match "$PipelineNotificationEmail" })
            if (!$subExists) {
                Write-Information "Creating build completed notification for $PipelineNotificationEmail"
                $projectTeamGroupId = ($groups |? { $_.PrincipalName -eq "[$Project]\$Project Team" }).originId
                Invoke-WithRetry { Invoke-RestMethod -Header $authenicationHeader -Uri "https://dev.azure.com/$Organization/_apis/notification/Subscriptions?api-version=6.1-preview.1" -Method Post -ContentType "application/json" -Body @"
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
            $projectTeamGroupId = ($groups |? { $_.PrincipalName -eq "[$Project]\$Project Team" }).originId
            Invoke-WithRetry { Invoke-RestMethod -Header $authenicationHeader -Uri "https://dev.azure.com/$Organization/_apis/notification/Subscriptions/ms.vss-build.build-requested-personal-subscription/UserSettings/$projectTeamGroupId`?api-version=6.1-preview.1" -Method Put -ContentType "application/json" -Body '{"optedOut":true}' }| Out-Null
            # Pull requests
            Write-Information "Disabling pull request pipeline notifications"
            Invoke-WithRetry { Invoke-RestMethod -Header $authenicationHeader -Uri "https://dev.azure.com/$Organization/_apis/notification/Subscriptions/ms.vss-code.pull-request-updated-subscription/UserSettings/$projectTeamGroupId`?api-version=6.1-preview.1" -Method Put -ContentType "application/json" -Body '{"optedOut":true}' }| Out-Null
        }

        # If setting DisconnectDevOpsOrganizationFromAzureAd is set, disconnect from Azure AD
        if ($DisconnectDevOpsOrganizationFromAzureAd) {
            Invoke-Command -ScriptBlock {
                Write-Information "Disconnecting Organization from Azure Active Directory"
                # Remove from AAD, but retain access
                Invoke-WithRetry { Invoke-RestMethod -Headers $authenicationHeader -Uri "https://vssps.dev.azure.com/$Organization/_apis/Organization/Organizations/Me?api-version=6.1-preview.1" -ContentType "application/json-patch+json" -Method "Patch" -Body @"
            [
                {
                    "from": "",
                    "op": 2,
                    "path": "/TenantId",
                    "value": "00000000-0000-0000-0000-000000000000"
                }
            ]
"@ | Out-Null
                }
            }
            Write-Warning "Accept the DevOps email invite in an incognito browser"
        }
    }

    Export-ModuleMember -Function Install-Simeon*, Get-Simeon*

} | Import-Module -Force -PassThru
