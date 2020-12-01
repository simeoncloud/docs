& C:\dev\docs\SimeonInstaller.ps1


# Install-Module Az.KeyVault -Repository PSGallery -Force;
# 	Connect-AzAccount
# 	Import-Module Az.KeyVault
# 	$emailPw = ConvertFrom-SecureString (Get-AzKeyVaultSecret -VaultName "simeon-keyvault" -Name "support-email-pw").SecretValue -AsPlainText

Install-SimeonReportingPipeline -FromEmailAddress "support@simeoncloud.com" -FromEmailPw "Maj30480!rt3c*x9l.pkx" -SendSummaryEmailToAddresses "70e1ed48.simeoncloud.com@amer.teams.ms" -Organization "Simeoncloud"


pwsh -ExecutionPolicy Bypass -Command "iex (irm https://raw.githubusercontent.com/simeoncloud/docs/master/SimeonInstaller.ps1); Install-SimeonReportingPipeline -FromEmailAddress 'support@simeoncloud.com' -FromEmailPw 'Maj30480!rt3c*x9l.pkx' -ToBccAddress '70e1ed48.simeoncloud.com@amer.teams.ms' -Organization (Read-Host Enter Organization)"
