#region One-time only

## Authenticate interactively. Use -SubscriptionId if you have multiple subscriptions
Add-AzAccount

## Encrypt the Azure application password in memory
$secPassword = ConvertTo-SecureString -AsPlainText -Force -String '<your password here>'

## Create the application
$myApp = New-AzADApplication -DisplayName AppForServicePrincipal -IdentifierUris 'http://appforserviceprincipal' -Password $secPassword

## Create the service principal
$sp = New-AzADServicePrincipal -ApplicationId $myApp.ApplicationId

## Create the role assignment
New-AzRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $sp.ServicePrincipalNames[0]

## Save the encrypted application password to disk
$azureAppIdPasswordFilePath = 'C:\AzureAppPassword.txt'
$secPassword | ConvertFrom-SecureString | Out-File -FilePath $azureAppIdPasswordFilePath

#endregion

#region This goes in any script thereafter you need to authenticate to Azure into

## Create a PSCredential object from the application ID and password
$azureAppCred = (New-Object System.Management.Automation.PSCredential $myApp.ApplicationId, (Get-Content -Path $azureAppIdPasswordFilePath | ConvertTo-SecureString))

## Use the subscription ID, tenant ID and password to authenticate
$subscription = Get-AzSubscription -SubscriptName '<your subscription name>'
Add-AzAccount -ServicePrincipal -SubscriptionId $subscription.Id -TenantId $subscription.TenantId -Credential $azureAppCred
#endregion