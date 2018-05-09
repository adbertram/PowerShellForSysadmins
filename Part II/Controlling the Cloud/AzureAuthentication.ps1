#region One-time only

## Authenticate interactively. Use -SubscriptionId if you have multiple subscriptions
Add-AzureRmAccount

## Encrypt the Azure application password in memory
$secPassword = ConvertTo-SecureString -AsPlainText -Force -String '<your password here>'

## Create the application
$myApp = New-AzureRmADApplication -DisplayName AppForServicePrincipal -IdentifierUris 'http://appforserviceprincipal' -Password $secPassword

## Create the service principal
$sp = New-AzureRmADServicePrincipal -ApplicationId $myApp.ApplicationId

## Create the role assignment
New-AzureRmRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $sp.ServicePrincipalNames[0]

## Save the encrypted application password to disk
$secPassword | ConvertFrom-SecureString | Out-File -FilePath C:\AzureAppPassword.txt

#endregion

#region This goes in any script thereafter you need to authenticate to Azure into

## Create a PSCredential object from the application ID and password
$azureAppId = '<application id>'
$azureAppIdPasswordFilePath = 'C:\AzureAppPassword.txt'
$azureAppCred = (New-Object System.Management.Automation.PSCredential $azureAppId, (Get-Content -Path $azureAppIdPasswordFilePath | ConvertTo-SecureString))

## Use the subscription ID, tenant ID and password to authenticate
$subscriptionId = '<subscription id>'
$tenantId = '<tenant id>'
Add-AzureRmAccount -ServicePrincipal -SubscriptionId $subscriptionId -TenantId $tenantId -Credential $azureAppCred

#endregion