function PrepareSqlServerInstallConfigFile {
	[OutputType('void')]
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Path
	)

	$ErrorActionPreference = 'Stop'

	$sqlConfig = $script:LabConfiguration.DefaultServerConfiguration.SQL

	$configContents = Get-Content -Path $Path -Raw
	$configContents = $configContents.Replace('SQLSVCACCOUNT=""', ('SQLSVCACCOUNT="{0}"' -f $sqlConfig.ServiceAccount.Name))
	$configContents = $configContents.Replace('SQLSVCPASSWORD=""', ('SQLSVCPASSWORD="{0}"' -f $sqlConfig.ServiceAccount.Password))
	$configContents = $configContents.Replace('SQLSYSADMINACCOUNTS=""', ('SQLSYSADMINACCOUNTS="{0}"' -f $sqlConfig.SystemAdministratorAccount.Name))
	Set-Content -Path $Path -Value $configContents
	
}