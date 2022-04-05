
# to find your app in the portal afterward
# azure ad > app registrations > all applications > search for app name

# install and import
#Install-Module AzureAD
#Import-Module AzureAD

# connect
$azuread = Connect-AzureAD

# conntect to specific tenant if necessary
# Connect-AzureAD -TenantId *Insert Directory ID here*

# create app. don't know how to set owner. Add-AzureADApplicationOwner did not work for me
# https://techcommunity.microsoft.com/t5/itops-talk-blog/powershell-basics-how-to-create-an-azure-ad-app-registration/ba-p/811570
$appName = "TailwindTradersSalesApp"
$appReplyURLs = @('https://localhost:1234')
if(!($myApp = Get-AzureADApplication -Filter "DisplayName eq '$($appName)'" -ErrorAction SilentlyContinue))
{
    $myApp = New-AzureADApplication -DisplayName $appName -ReplyUrls $appReplyURLs
}

# create client secret for the app
# https://www.reddit.com/r/PowerShell/comments/mvm1u2/adding_api_permissions_to_azure_ad_apps_with/
$aadAppsecret01 = New-AzureADApplicationPasswordCredential -ObjectId $myApp.ObjectID -CustomKeyIdentifier "$appName-Secret" -StartDate (Get-Date) -EndDate (Get-Date).AddYears(3)
Write-Host "Keep it secret. Keep it safe:`r`n$($aadAppsecret01.value)"

<# i used client secret instead of this
# create credential
# https://techcommunity.microsoft.com/t5/itops-talk-blog/powershell-basics-how-to-create-an-azure-ad-app-registration/ba-p/811570
$Guid = New-Guid
$startDate = Get-Date
$PasswordCredential = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordCredential
$PasswordCredential.StartDate = $startDate
$PasswordCredential.EndDate = $startDate.AddYears(1)
$PasswordCredential.KeyId = $Guid
$PasswordCredential.Value = ([System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(($Guid))))
#>

# add api permission
# https://rajanieshkaushikk.com/2019/07/31/how-to-assign-permissions-to-azure-ad-app-by-using-powershell/
# https://www.reddit.com/r/PowerShell/comments/mvm1u2/adding_api_permissions_to_azure_ad_apps_with/
# https://docs.microsoft.com/en-us/dotnet/api/microsoft.azure.management.graph.rbac.fluent.models.resourceaccess.-ctor?view=azure-dotnet#microsoft-azure-management-graph-rbac-fluent-models-resourceaccess-ctor(system-string-system-collections-generic-idictionary((system-string-system-object))-system-string)
#$DelegatedPermission1 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList "e1fe6dd8-ba31-4d61-89e7-88639da4683d","Scope" # User.Read
$ApplicationPermission1 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList "df021288-bdef-4463-88db-98f22de89214","Role" # User.Read.All
$Graph = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
#$Graph.ResourceAppId = $myapp.AppId
$Graph.ResourceAppId = '00000003-0000-0000-c000-000000000000' # app id should be that of "Microsoft Graph" for when we "grant consent" later
$Graph.ResourceAccess = $ApplicationPermission1 #, $DelegatedPermission1

# for app roles if you need em
# https://azurescene.com/2019/11/20/microsoft-graph-permission-role-ids/
# https://github.com/mjisaak/azure-active-directory/blob/master/README.md
#$UserReadAll = (Get-AzureAdServicePrincipal -filter "DisplayName eq 'Microsoft Graph'").AppRoles | ? id -eq 'df021288-bdef-4463-88db-98f22de89214'

# apply api permissions and app roles to our new app
Set-AzureADApplication -ObjectId $myapp.ObjectId -RequiredResourceAccess $Graph # -AppRoles $UserReadAll

<# i did not need to create service principal?
# https://stackoverflow.com/questions/68128737/grant-admin-consent-programmatically-on-newly-created-app-registration
# https://docs.microsoft.com/en-us/graph/api/serviceprincipal-post-serviceprincipals?view=graph-rest-1.0&tabs=powershell
# connect-graph does not work in ise. connect in other terminal first, then you can call it in ise
# https://github.com/microsoftgraph/msgraph-sdk-powershell/issues/247
#Import-Module Microsoft.Graph.Applications
Connect-Graph
$params = @{ AppId = $myApp.AppId }
New-MgServicePrincipal -BodyParameter $params
#>

# to detroy the app and start over. I don't know how to remove api permissions or app roles
# Remove-AzureADApplication -ObjectId $myApp.ObjectId

# behold your creation
# Get-AzureADApplication -Filter "DisplayName eq '$($appName)'" | fl *

# * YOU WILL NEED TO MANUALLY CLICK THE "Grant Admin Consent" BUTTON
# Could not grant admin consent. Your organization does not have a subscription (or service principal) for the following API(s): TailwindTradersSalesApp
# https://www.reddit.com/r/PowerShell/comments/mvm1u2/adding_api_permissions_to_azure_ad_apps_with/
$consentURL = "https://aad.portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/CallAnAPI/appId/$($myApp.AppId)/isMSAApp/"
Start-Process $consentURL

return

#####
# app is created. here's how to use it
#####


#$tenant = Read-Host 'Enter your Tenant Name (domain.com)'
$tenant = $azuread.TenantDomain
$openid = Invoke-RestMethod -uri "https://login.microsoftonline.com/$tenant/.well-known/openid-configuration"
$tokenendpoint = $openid.token_endpoint

$body = @{
    client_id = $myApp.AppId
    client_secret = $aadAppsecret01.value
    redirect_uri = 'https://localhost:1234'
    grant_type = 'client_credentials'
    resource = 'https://graph.microsoft.com'
    tenant = $tenant
}

# get our access token
$request = Invoke-RestMethod -Uri $tokenendpoint -Body $body -Method Post

$graph = 'https://graph.microsoft.com/beta/users'
$api = Invoke-RestMethod -Headers @{Authorization = "Bearer $($request.access_token)"} -Uri $graph -Method Get
$users = $api.value

# view results
# $users | select userprincipalname, accountenabled

