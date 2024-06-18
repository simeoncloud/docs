# usage .\Build-ApplicationScopesMarkdown.ps1 -TenantId "your-tenant-id" -Username "your-username" -Password "your-password" -ClientId "your-client-id" -ClientSecret "your-client-secret"
# The credentials are used to acquire an access token to query the Microsoft Graph API for the application scopes names
# The credentials should be from a tenant that has the Simeon Cloud Sync app installed.
param (
    $OutputPath = "application-scopes.md",
    [string]$TenantId,
    [string]$Username,
    [string]$Password,
    [string]$ClientId,
    [string]$ClientSecret
)
$ErrorActionPreference = 'Stop'

function Get-AccessToken
{
    param(
        [string]$Scope
    )

    $tokenUrl = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
    $body = @{
        grant_type = "password"
        client_id = $ClientId
        client_secret = $ClientSecret
        scope = $Scope
        username = $Username
        password = $Password
    }

    $bodyEncoded = ""
    foreach ($key in $body.Keys)
    {
        $bodyEncoded += [System.Web.HttpUtility]::UrlEncode($key) + "=" + [System.Web.HttpUtility]::UrlEncode($body[$key]) + "&"
    }
    $bodyEncoded = $bodyEncoded.TrimEnd("&")

    # Make a POST request to acquire the token
    $tokenResponse = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $bodyEncoded -ContentType "application/x-www-form-urlencoded"

    return $tokenResponse.access_token
}

function Add-Result($Item)
{
    foreach ($pair in $Item.GetEnumerator())
    {
        $sb.Append("".PadLeft($script:indent) + "- ") | Out-Null
        $sb.AppendLine($pair.Key) | Out-Null
        if ($pair.Value)
        {
            $script:indent += 2
            Add-Result $pair.Value
            $script:indent -= 2
        }
    }
}

$msGraphAccessToken = Get-AccessToken -Scope "https://graph.microsoft.com/.default"
$msGraphRestProps = @{
    Headers = @{
        Authorization = "Bearer $msGraphAccessToken"
        Accept = "application/json"
    }
}

$application = Get-Content './Resources/Content/MSGraph/Applications/Simeon Cloud Sync.json' | ConvertFrom-Json
$requiredResources = $application.requiredResourceAccess
$resourceDescriptions = @()

foreach ($requiredResource in $requiredResources)
{
    $resourceAppId = $requiredResource.resourceAppId
    $servicePrincipalUrl = "https://graph.microsoft.com/beta/servicePrincipals?`$filter=appId eq '$resourceAppId'"
    $servicePrincipalResponse = Invoke-RestMethod @msGraphRestProps -Uri $servicePrincipalUrl -Method Get -ContentType "application/json"
    $servicePrincipal = $servicePrincipalResponse.value[0]
    foreach ($resource in $requiredResource.resourceAccess)
    {
        $resourceDescription = @{
            application = $servicePrincipal.displayName
            type = $resource.type
            target = ""
            value = ""
            description = ""
        }
        if ($resource.type -eq "Role")
        {
            $query = $servicePrincipal.appRoles | where { $_.id -eq $resource.id }
            $resourceDescription.description = $query[0].displayName
            $resourceDescription.value = $query[0].value
            $resourceDescription.target = "Application scope"
        }
        else
        {
            $query = $servicePrincipal.publishedPermissionScopes | where { $_.id -eq $resource.id }
            $resourceDescription.description = $query[0].userConsentDisplayName
            $resourceDescription.value = $query[0].value
            $resourceDescription.target = "Delegated scope"
        }
        $resourceDescriptions += $resourceDescription
    }
}

$applications = $resourceDescriptions.application | Select -Unique | Sort-Object
$sb = [System.Text.StringBuilder]::new()
$script:indent = 0
foreach ($application in $applications)
{
    $sb.Append("".PadLeft($script:indent) + "- ") | Out-Null
    $sb.AppendLine($application) | Out-Null
    $applicationRespourceDescriptions = $resourceDescriptions | where { $_.application -eq $application }
    foreach ($applicationRespourceDescription in $applicationRespourceDescriptions)
    {
        $script:indent += 2
        $sb.Append("".PadLeft($script:indent) + "- ") | Out-Null
        $sb.AppendLine("$($applicationRespourceDescription.target) - $( $applicationRespourceDescription.value ) ($( $applicationRespourceDescription.description ))") | Out-Null
        $script:indent -= 2
    }
}
$stringContent = $sb.ToString()

if ($OutputPath)
{
    Write-Host "Saving markdown file to $OutputPath"
    $stringContent | Out-File $OutputPath
}
else
{
    return $stringContent
}

