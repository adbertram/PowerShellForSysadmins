#region Authentication

## Create a PSCredential object from the application ID and password
$azureAppId = '<application id>'
$azureAppIdPasswordFilePath = 'C:\AzureAppPassword.txt'
$azureAppCred = (New-Object System.Management.Automation.PSCredential $azureAppId, (Get-Content -Path $azureAppIdPasswordFilePath | ConvertTo-SecureString))

## Use the subscription ID, tenant ID and password to authenticate
$subscriptionId = '<subscription id>'
$tenantId = '<tenant id>'
Add-AzAccount -ServicePrincipal -SubscriptionId $subscriptionId -TenantId $tenantId -Credential $azureAppCred

#endregion