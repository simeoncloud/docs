$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Install-AzureModule {
    if ($PSVersionTable.PSEdition -ne 'Core' -and !(Get-PackageProvider NuGet -ListAvailable)) {
        Install-PackageProvider NuGet -Force -ForceBootstrap | Out-Null
    }

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
        if (!(Get-Module $m.Name -ListAvailable |? { !$m.RequiredVersion -or $m.RequiredVersion -eq $_.Version })) { 
            Write-Host "Installing module '$($m.Name)'"
            Install-Module @m -Scope CurrentUser -Force -AllowClobber | Out-Null
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
        [string]$TenantId
    )
    # Resolves tenant domain name to id
    [Guid]$g = [Guid]::Empty
    if ([Guid]::TryParse($TenantId, [ref]$g)) { return $TenantId }
    $endpoint = (irm "https://login.microsoftonline.com/$TenantId/v2.0/.well-known/openid-configuration").token_endpoint
    $result = [uri]::new($endpoint).PathAndQuery -split '/' |? { $_ } | Select -First 1
    if (!$result) { throw "Could not resolve tenant id for $TenantId." }
    Write-Host "Resolved tenant id from '$TenantId' to '$result'"
    return $result
}

function Connect-Azure {
    param(
        [string]$Tenant        
    )
    
    Install-AzureModule

    $TenantId = Resolve-AzureTenantId $Tenant

    while (!(Get-AzContext -WarningAction SilentlyContinue) -or (Set-AzContext -Tenant $TenantId -WarningAction SilentlyContinue).Tenant.Id -ne $TenantId) { 
        Write-Warning "Connecting to Azure Tenant '$Tenant' - please sign in using an account with the 'Global administrator' role in Azure Active Directory and Contributor access to an Azure Subscription in that tenant - press any key to continue"
        $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') | Out-Null
        Connect-AzAccount -Tenant $TenantId | Out-Null
    }
    
    Set-AzContext -Tenant $TenantId | Out-Null
    
    Connect-AzureADUsingAzContext | Out-Null

    Write-Host "Connected to Azure tenant '$Tenant' using account '$((Get-AzContext).Account.Id)'"
}

function Install-SimeonTenantServiceAccount {
    param(
        [ValidateNotNullOrEmpty()]
        [string]$Organization,
        [ValidateNotNullOrEmpty()]
        [string]$Project,
        [ValidateNotNullOrEmpty()]
        [string]$Tenant        
    )
    # Creates/updates service account and required permissions

    Connect-Azure $Tenant

    try {
        # TODO: check if global admin
    }
    catch {
        Disconnect-AzAccount
        Clear-AzContext -Force
        throw "Could not access Azure Active Directory '$Tenant' with sufficient permissions - please make sure you signed in using an account with the 'Global administrator' role."
    }

    # Create/update Azure AD user with random password
    $user = Get-AzureADUser -Filter "displayName eq 'Simeon Service Account'"
    $upn = "simeon@$(Get-AzureADDomain |? IsDefault -eq $true | Select -ExpandProperty Name)"
    $password = [Guid]::NewGuid().ToString("N").Substring(0, 10) + "Ul!"
    
    if (!$user) {
        Write-Host "Creating account '$upn'"
        $user = New-AzureADUser -DisplayName 'Simeon Service Account' `
            -UserPrincipalName $upn `
            -MailNickName simeon -AccountEnabled $true `
            -PasswordProfile @{ Password = $password; ForceChangePasswordNextLogin = $false } -PasswordPolicies DisablePasswordExpiration
    }
    else {
        Write-Host "Account '$upn' already exists - updating"
        $user | Set-AzureADUser -PasswordProfile @{ Password = $password; ForceChangePasswordNextLogin = $false } -PasswordPolicies DisablePasswordExpiration
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
    $subscriptionId = Get-AzSubscription -Tenant ((Get-AzContext).Tenant.Id) |? Name -ne 'Access to Azure Active Directory' |? State -eq Enabled | Sort-Object Name | Select -First 1 -ExpandProperty Id
    if (!$subscriptionId) {
        # Elevate access to see all subscriptions in the tenant and force re-login
        irm 'https://management.azure.com/providers/Microsoft.Authorization/elevateAccess?api-version=2016-07-01' -Method Post -Headers @{ Authorization = "Bearer $(Get-AzContextToken 'https://management.azure.com/')" }
    
        Disconnect-AzAccount
        Clear-AzContext -Force
        Write-Warning "Elevating access to allow assignment of subscription roles - you will need to sign in again"
        $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') | Out-Null
        Connect-Azure $Tenant

        $subscriptionId = Get-AzSubscription -Tenant ((Get-AzContext).Tenant.Id) |? State -eq Enabled | Sort-Object Name | Select -First 1 -ExpandProperty Id
    }

    # Add as contributor to an Azure RM Subscription
    if (!(Get-AzRoleAssignment -SignInName $upn -RoleDefinitionName 'Contributor' -Scope "/subscriptions/$subscriptionId")) {
        Write-Host "Adding account to 'Contributor' role on subscription '$subscriptionId'"
        New-AzRoleAssignment -SignInName $upn -RoleDefinitionName 'Contributor' -Scope "/subscriptions/$subscriptionId" | Out-Null
    }
    else {
        Write-Host "Account already has 'Contributor' role on subscription '$subscriptionId'"
    }

    return $password
}

function Get-SimeonAzureDevOpsAccessToken {
    param(
        [switch]$LaunchBrowser,
        [switch]$PromptForLogin
    )

    # Gets an OAuth token to make API calls to Azure DevOps
    # Needs to run as a job (external process) because a bug in .NET Core keeps a reservation on the http endpoint even after the http listener is disposed (until process exits)

    $job = Start-Job -ScriptBlock {
        $port = 3546
        if (Get-Command Get-NetTCPConnection -EA SilentlyContinue) {
            Get-NetTCPConnection -LocalPort $port -EA SilentlyContinue | Select -ExpandProperty OwningProcess |% {
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
   
                if ($context.Request.QueryString['state'] -ne $state) {
                    $html = "<html><body><h3>Invalid state in query: received $($context.Request.QueryString['state']) but expected $state</h3></body></html>"
                }
                elseif ($inputData -like 'access_token=*') { 
                    $accessToken = $inputData.Substring('access_token='.Length)

                    $suffix = 'you may close this window'
                    if ($using:LaunchBrowser) { $suffix = 'this window will close momentarily' }

                    $html = "<html><body><h3>Azure DevOps authentication successful - $suffix - return to the running PowerShell script window</h3></body></html>" 
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
    return $false
}

function Install-SimeonTenantPipelines {
    param(
        [ValidateNotNullOrEmpty()]
        [string]$Organization,
        [ValidateNotNullOrEmpty()]
        [string]$Project,
        [ValidateNotNullOrEmpty()]
        [string]$Tenant,
        [string]$Baseline,
        [string]$Password        
    )    
    # Creates repo and pipelines and stores service account password
   
    $loginInstructions = "log in as an account with access to your Simeon organization '$Organization' and the '$Project' project - press any key to continue"
    
    Write-Warning "Connecting to Azure DevOps - if prompted, $loginInstructions"
    $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') | Out-Null
    $token = Get-SimeonAzureDevOpsAccessToken -LaunchBrowser
    
    if (!(Test-SimeonAzureDevOpsAccessToken -Organization $Organization -Project $Project -Token $token)) {
        Write-Warning "Retrying Azure DevOps login - $loginInstructions"
        $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') | Out-Null
        $token = Get-SimeonAzureDevOpsAccessToken -LaunchBrowser -PromptForLogin
    }
    
    if (!(Test-SimeonAzureDevOpsAccessToken -Organization $Organization -Project $Project -Token $token)) {
        Write-Warning "Retrying Azure DevOps login - please copy the below url, paste into an incognito/private browser window and $loginInstructions"
        $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') | Out-Null
        $token = Get-SimeonAzureDevOpsAccessToken
    }

    if (!(Test-SimeonAzureDevOpsAccessToken -Organization $Organization -Project $Project -Token $token)) {
        throw "Could not access Azure DevOps project '$Project' in organization '$Organization' - ensure the organization and project exists and that you have access."
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

    $pipelineVariables = @{
        'AadAuth:Username' = @{
            allowOverride = $true
            value = "simeon@$Tenant"
        }
        'AadAuth:Password' = @{
            allowOverride = $true
            isSecret = $true
            value = $Password
        }
        'BaselineRepository' = @{
            allowOverride = $true
            value = $Baseline
        }
    }
    
    foreach ($action in @('Deploy', 'Export')) { 
        $pipelineName = "$Name - $action"
        
        $pipeline = $pipelines.value |? name -eq $pipelineName

        if ($pipeline) {
            Write-Host "Pipeline '$pipelineName' already exists - deleting"            
            irm @restProps "$apiBaseUrl/build/definitions/$($pipeline.id)?$apiVersion" -Method Delete | Out-Null
        }

        Write-Host "Creating pipeline '$pipelineName'"      
        irm @restProps "$apiBaseUrl/build/definitions?$apiVersion" -Method Post -Body (@{
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
            } | ConvertTo-Json -Depth 3) | Out-Null              
    }    
}

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

function Install-SimeonTenant {
    param(
        # The organization name that appears in DevOps - e.g. 'simeon-orgName'
        [ValidateNotNullOrEmpty()]
        [string]$Organization = (& { if ($script:Organization) { $script:Organization } else { Read-Host 'Enter Azure DevOps organization name' } }),
        # The project name in DevOps - usually 'Tenants'
        [ValidateNotNullOrEmpty()]
        [string]$Project = 'Tenants',
        [ValidateNotNullOrEmpty()]
        # The Azure tenant domain name to configure Simeon for
        [string]$Tenant = (Read-Host 'Enter tenant primary domain name (e.g. contoso.com or contoso.onmicrosoft.com)'),
        # Indicates the name for the repository and pipelines to create - defaults to the tenant name
        [string]$Name = $Tenant,
        # Indicates the baseline repository to use for pipelines
        [string]$Baseline
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

    if (!$PSBoundParameters.ContainsKey('Baseline') -and $Name -ne 'baseline') {
        if (Read-HostBooleanValue 'Is this the default baseline for the organization?') { 
            $Baseline = ''  # no baseline
            $Name = 'baseline'
        }
        else {
            $Baseline = Read-Host 'Enter the name of the baseline repository to use (if none is specified, the default baseline for the organization will be used)'
            if (!$Baseline) { $Baseline = 'baseline' }
        }
    }

    $password = Install-SimeonTenantServiceAccount -Organization $Organization -Project $Project -Tenant $Tenant

    Install-SimeonTenantPipelines -Organization $Organization -Project $Project -Tenant $Tenant -Name $Name -Password $password -Baseline $Baseline

    Write-Host "Completed successfully"
}