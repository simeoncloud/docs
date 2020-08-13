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

    function Get-AzureManagementAccessToken {
        param(
            [ValidateNotNullOrEmpty()]
            [string]$Tenant
        )
        # Set well-known client ID for Azure PowerShell
        $clientId = "1950a258-227b-4e31-a9cf-717495945fc2" 
        New-MsalClientApplication -ClientId $clientId -TenantId $Tenant | `
            Enable-MsalTokenCacheOnDisk -PassThru -WarningAction SilentlyContinue | % { 
            (Get-MsalToken -PublicClientApplication $_ -Scopes @('https://management.core.windows.net//user_impersonation', 'https://graph.microsoft.com/.default')).AccessToken 
        }
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
        param(
            [switch]$LaunchBrowser,
            [switch]$PromptForLogin
        )

        # Gets an OAuth token to make API calls to Azure DevOps
        # Needs to run as a job (external process) because a bug in .NET Core keeps a reservation on the http endpoint even after the http listener is disposed (until process exits)

        if ($env:SimeonAzureDevOpsAccessToken) { return $env:SimeonAzureDevOpsAccessToken }

        $job = Start-Job -ScriptBlock {
            $port = 3546
            if (Get-Command Get-NetTCPConnection -EA SilentlyContinue) {
                Get-NetTCPConnection -LocalPort $port -EA SilentlyContinue | Select -ExpandProperty OwningProcess | % {
                    Write-Warning "Terminating existing process '$_' listening on port '$port'"
                    $_ | Stop-Process -Force -EA SilentlyContinue
                }
            }

            $http = [System.Net.HttpListener]::new() 
            $http.Prefixes.Add("http://localhost:$port/")
            $http.Start()
            try {
                # initiate browser request for token
                $appId = '26D8E4BF-3432-4640-B58E-2ADA3FEC36B4'
                $redirectUri = 'https://simeondevopsapi.azurewebsites.net/api/oauth2/callback'
                $scope = 'vso.analytics vso.auditlog vso.build_execute vso.code_full vso.code_status vso.connected_server vso.dashboards_manage vso.entitlements vso.environment_manage vso.extension.data_write vso.extension_manage vso.gallery_acquire vso.gallery_manage vso.graph_manage vso.identity_manage vso.loadtest_write vso.machinegroup_manage vso.memberentitlementmanagement_write vso.notification_diagnostics vso.notification_manage vso.packaging_manage vso.profile_write vso.project_manage vso.release_manage vso.securefiles_manage vso.security_manage vso.serviceendpoint_manage vso.symbols_manage vso.taskgroups_manage vso.test_write vso.tokenadministration vso.tokens vso.variablegroups_manage vso.wiki_write vso.work_full'
                $state = [Guid]::NewGuid().ToString()
                $authorizeUrl = "https://app.vssps.visualstudio.com/oauth2/authorize?client_id=$appId&response_type=Assertion&state=$state&scope=$scope&redirect_uri=$redirectUri"
            
                if ($using:PromptForLogin) {
                    # can't pass prompt=login to vssps authorize url - so need to go directly to the AAD login url that vssps redirects to and add prompt=login 
                    $scope = $scope -replace ' ', '%252520'
                    $authorizeUrl = "https://login.microsoftonline.com/common/oauth2/authorize?client_id=499b84ac-1321-427f-aa17-267ca6975798&site_id=501454&response_mode=form_post&response_type=code+id_token&redirect_uri=https%3A%2F%2Fapp.vssps.visualstudio.com%2F_signedin&nonce=$state&state=realm%3Dapp.vssps.visualstudio.com%26reply_to%3Dhttps%253A%252F%252Fapp.vssps.visualstudio.com%252Foauth2%252Fauthorize%253Fclient_id%253D$appId%2526response_type%253DAssertion%2526state%253D$state%2526scope%253D$scope%2526redirect_uri%253Dhttps%25253A%25252F%25252Fsimeondevopsapi.azurewebsites.net%25252Fapi%25252Foauth2%25252Fcallback%26ht%3D3%26nonce%3D$state&resource=https%3A%2F%2Fmanagement.core.windows.net%2F&cid=6706a22e-cb71-42f6-98e1-acf49624393a&wsucxt=1&githubsi=true&msaoauth2=true&prompt=login"
                }

                if ($using:LaunchBrowser) {
                    Start-Process $authorizeUrl
                } 
                else {
                    Write-Host $authorizeUrl -ForegroundColor Green
                }

                # listen for callback
                while ($http.IsListening) {
                    Start-Sleep -Milliseconds 100
                    $context = $http.GetContext()

                    $inputData = [System.IO.StreamReader]::new($context.Request.InputStream).ReadToEnd()
   
                    if ($context.Request.QueryString['state'] -and $context.Request.QueryString['state'] -ne $state) {
                        $html = "<html><body><h3>Invalid state in query: received $($context.Request.QueryString['state']) but expected $state</h3></body></html>"
                    }
                    elseif ($inputData -like 'access_token=*') { 
                        $accessToken = $inputData.Substring('access_token='.Length)

                        $suffix = 'you may close this window'
                        if ($using:LaunchBrowser) { $suffix = "this window will close momentarily or $suffix manually" }

                        $html = "<html><body><h3>Azure DevOps authentication successful - $suffix and return to the PowerShell window.</h3></body></html>" 
                    } 
                    else {
                        $html = "<html><body><h3>Could not obtain Azure DevOps access token</h3></body></html>"
                    }

                    $html += @"
<script type='text/javascript'>
    setTimeout(function() { window.close() }, 2500);
</script> 
"@

                    $buffer = [System.Text.Encoding]::UTF8.GetBytes($html) 
                    $context.Response.ContentLength64 = $buffer.Length
                    $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
                    $context.Response.OutputStream.Close()            

                    if ($accessToken) {
                        return $accessToken
                    }
                } 
            }
            finally {
                $http.Dispose()
            }
        } 
        try {
            while ($job.State -eq 'Running') {
                $job | Receive-Job
                Start-Sleep -Milliseconds 100
            }
            $job | Receive-Job -Wait -AutoRemoveJob
        }
        finally {
            # handle ctrl+c
            if (Get-Command gwmi -EA SilentlyContinue) {
                gwmi win32_process -filter "Name='powershell.exe' AND ParentProcessId=$PID" | Select -ExpandProperty ProcessId | % { Stop-Process -Id $_ -Force }
            }
        }
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

        if (!$Organization) { $Organization = Read-Organization }
    
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
            $token = Get-SimeonAzureDevOpsAccessToken -PromptForLogin
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