function Install-Simeon {
    param(
        [ValidateNotNullOrEmpty()]
        [string]$Organization = (Read-Host 'Enter Azure DevOps organization name'),
        [ValidateNotNullOrEmpty()]
        [string]$TenantId = (Read-Host 'Enter tenant domain name or id')
    )

    $ErrorActionPreference = 'Stop'
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Install Azure AD module for Azure AD management (Allow AzureAD or AzureAD.Standard.Preview)
    $azureADModule = @{ Name = 'AzureAD' }
    if ($PSVersionTable.PSEdition -eq 'Core') {
        Register-PackageSource -Name PoshTestGallery -Location https://www.poshtestgallery.com/api/v2/ -ProviderName PowerShellGet -Force | Out-Null
        $azureADModule.Name = 'AzureAD.Standard.Preview'
        $azureADModule.RequiredVersion = '0.0.0.10'
    }

    if (!(Get-Module $azureADModule.Name -ListAvailable)) { 
        Write-Host "Installing module $($azureADModule.Name)"
        Install-Module @azureADModule -Scope CurrentUser -Force | Out-Null
    }
    Import-Module $azureADModule.Name

    # TODO: Install Az module for subscription management

    # Authenticate
    try {
        if (!(Get-AzureADCurrentSessionInfo |? { @($_.TenantId, $_.TenantDomain) -contains $TenantId })) {
            Connect-AzureAD -TenantId $TenantId
        }
    }
    catch { Connect-AzureAD -TenantId $TenantId }

    # Create/update Azure AD user with random password
    $password = [Guid]::NewGuid().ToString("N").Substring(0, 10) + "Ul!"
    $user = Get-AzureADUser -Filter "displayName eq 'Simeon Service Account'"
    $upn = "simeon@$(Get-AzureADDomain |? IsDefault -eq $true | Select -ExpandProperty Name)"
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
    try { Get-AzureADDirectoryRole | Out-Null } catch {}

    # Make sure Directory Synchronization Accounts role is activated 
    if (!(Get-AzureADDirectoryRole |? DisplayName -eq 'Directory Synchronization Accounts')) { 
        Write-Host "Activating role Directory Synchronization Accounts"
        Get-AzureADDirectoryRoleTemplate |? DisplayName -eq 'Directory Synchronization Accounts' |% { Enable-AzureADDirectoryRole -RoleTemplateId $_.ObjectId -EA SilentlyContinue | Out-Null }
    }

    # Add to Company Administrator (aka Global Admin) role for administration purposes and Directory Synchronization Accounts role so account is excluded from MFA 
    Get-AzureADDirectoryRole |? { $_.DisplayName -in @('Company Administrator', 'Directory Synchronization Accounts') } |% { 
        if (!(Get-AzureADDirectoryRoleMember -ObjectId $_.ObjectId |? ObjectId -eq $user.ObjectId)) {
            Write-Host "Adding to role $($_.DisplayName)"
            Add-AzureADDirectoryRoleMember -ObjectId $_.ObjectId -RefObjectId $user.ObjectId | Out-Null
        }
        else {
            Write-Host "Already a member of role $($_.DisplayName)"
        }
    }

    # Add as contributor to an Azure RM Subscription

    # Take password and set it in pipeline or library
}