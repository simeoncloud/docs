function Invoke-AzurePipeline
{
    param (
        [string]
        # The organization name that appears in DevOps - e.g. simeon-orgName
        $Organization = (Read-Host "Enter the organization name that appears in DevOps, example: simeon-orgName"),
        [string]
        # The project name that in DevOps - usually 'Tenants'
        $Project = 'Tenants',
        [string]
        # Baseline or the client name
        $Tenant = (Read-Host "Enter 'baseline' or the client name"),
        [string]
        [ValidateSet("Export", "Deploy")]
        # The desired action - Export or Deploy
        $Action = (Read-Host "Enter desired action: Export or Deploy"), 
        [string]
        # Azure DevOps Personal Access token with rights to trigger builds - for details see: https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops&tabs=preview-page
        $PersonalAccessToken = (Read-Host "Enter your Azure Devops Personal Access Token" -AsSecureString |% { [System.Net.NetworkCredential]::new('',$_).Password }),
        [string]
        # The Azure Active Directory user name to be used during export/deploy
        $TenantAadUserName = '',
        [string]
        # The Azure Active Directory password to be used during export/deploy
        $TenantAadPassword = ''
    )
    <#
    .SYNOPSIS
    Initiates the desired action (export/deploy) against the provided Azure AD tenant
    #>

    $ErrorActionPreference = 'Stop'

    $devOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PersonalAccessToken)")) }

    # Get Build Definition
    $pipelineName = "$Tenant - $Action"

    Write-Host "Getting pipeline definition for pipeline: $pipelineName"

    $pipelines = (Invoke-RestMethod -Uri "https://dev.azure.com/$Organization/$Project/_apis/build/definitions?api-version=5.0" -Method Get -Headers $devOpsAuthenicationHeader -ContentType "application/json").Value
    
    $pipelineDefintion = $pipelines |? name -eq $pipelineName
    
    if (!$pipelineDefintion) {
        throw "Counld not find pipeline for $pipelineName. Verify that the provided client name and that the pipeline has been created."
    }

    # Trigger build
    $body = @{
        definition = @{
            id = $pipelineDefintionId.id;
        };
        sourceBranch = "refs/heads/master";
        parameters = (@{ "AadAuth:UserName" = $TenantAadUserName; "AadAuth:Password" = $TenantAadPassword } | ConvertTo-Json)
    } | ConvertTo-Json -Depth 5
    
    $result = Invoke-RestMethod -Uri "https://dev.azure.com/$Organization/$Project/_apis/build/builds?api-version=5.0" `
        -Method Post -Headers $devOpsAuthenicationHeader -Body $body -ContentType "application/json"

    Write-Host "Started pipeline - for details see: https://dev.azure.com/$Organization/$Project/_build/results?buildId=$($result.id)&view=results"
}

$pipelineArgs = @{
    Organization = '<Your DevOps organization name (e.g. simeon-pcpros)>'
    Action = 'Deploy'
    PersonalAccessToken = '***'
}

<# Update the below #>
$pipelinesToRun = @(
    @{
        Tenant = 'baseline'
    }
    @{
        Tenant = '<Client domain name (e.g. myorg.com or myorg.onmicrosoft.com)>'
    }
)

$pipelinesToRun |% { Invoke-AzurePipeline @pipelineArgs @_ }
