#
# Written by Kim Johansson https://github.com/maxiepax/letsencrypt-horizon-cert-automation
# 

# install modules if not already installed
if(-not (Get-Module Posh-ACME -ListAvailable)){
Install-Module -Name Posh-ACME -Confirm:$false
}

# uncomment for production
# Set-PAServer LE_PROD
# Write-Host "LOG: Using LE production servers" -ForegroundColor green -BackgroundColor black

# uncomment for testing
Set-PAServer LE_STAGE
Write-Host "LOG: Using LE staging servers" -ForegroundColor green -BackgroundColor black



# replace everything with CAPS.
$domain = '*.DOMAIN.COM','DOMAIN.COM'
$le_password = ConvertTo-SecureString "PASSWORD" -AsPlainText -Force
$le_username = 'USERNAME@loopiaapi'
$email = 'USERNAME@DOMAIN.COM'

$uag_username = "admin"
$uag_password = "PASSWORD"
$uag_hostname = "HZUAG01.DOMAIN.COM"

# no need to change anything below this comment line.

$pArgs = @{
    LoopiaUser = $le_username
    LoopiaPass = $le_password
}

# get the new certificate
Set-Location C:
Write-Host "LOG: Getting new certificate" -ForegroundColor green -BackgroundColor black
New-PACertificate $domain -AcceptTOS -Plugin Loopia -PluginArgs $pArgs -Contact $email -Verbose -Force

# Install certificate to Unified Access Gateway
$PACert = Get-PACertificate
$key_multiline = [IO.File]::ReadAllText($PACert.KeyFile)
$key_oneline = $key_multiline.Replace("`n",'\n')
$cert_multiline = [IO.File]::ReadAllText($PACert.FullChainFile)
$cert_oneline = $cert_multiline.Replace("`n",'\n')

# convert username:password to base64
[string]$uag_user_pass = $uag_username+":"+$uag_password
$base64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($uag_user_pass))

$API_Settings = @{
    Headers     = @{ "Authorization" = "Basic $base64" }
    Method      = "PUT"
    Body        = $json_uag
    ContentType = "application/json"
}
# create json string and make api call
$json_uag = '{"privateKeyPem":"' + $key_oneline + '","certChainPem":"' + $cert_oneline + '"}'
$API_Endpoint = "https://" + $uag_hostname + ":9443/rest/v1/config/certs/ssl"
Write-Host "LOG: Installing certificate to UAG" -ForegroundColor green -BackgroundColor black
Invoke-RestMethod $API_Endpoint @API_Settings


# install certificate locally on Horizon Connection Server
Write-Host "LOG: Installing certificate to windows certificate store" -ForegroundColor green -BackgroundColor black
Install-PACertificate

# rename the old certificate
Set-Location cert:\LocalMachine\My
$old_certs = Get-Childitem |Where-Object {$_.FriendlyName -eq 'vdm'}
Write-Host "LOG: Renaming old certificate" -ForegroundColor green -BackgroundColor black
ForEach ($old_cert in $old_certs){
$old_cert.FriendlyName = "Replaced $(Get-Date -format 'u')"
}
 
# set new certificate friendly name to vdm
$cert_thumbprint_dirty = Get-PACertificate |fl Thumbprint
$cert_thumbprint = Out-String -InputObject $cert_thumbprint_dirty -Width 100
$cert = gci $cert_thumbprint.Substring(17)
$cert.FriendlyName = "vdm"
 
# restart horizon service to use new certificate 
Restart-Service -Name wsbroker
Set-Location C: 

