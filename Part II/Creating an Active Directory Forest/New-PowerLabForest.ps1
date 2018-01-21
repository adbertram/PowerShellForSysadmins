PS> $cred = Import-CliXml -Path C:\PowerLab\VMCredential.xml
PS> $safeModePw = Import-CliXml -Path C:\PowerLab\SafeModeAdministratorPassword.xml
PS> Invoke-Command -VMName 'LABDC' -Credential $cred -ScriptBlock {
	$forestParams = @{
		DomainName                    = 'powerlab.local'
		DomainMode                    = 'WinThreshold'
		ForestMode                    = 'WinThreshold'
		Confirm                       = $false
		SafeModeAdministratorPassword = (ConvertTo-SecureString -AsPlainText -String $using:safeModePw -Force)
		WarningAction                 = 'Ignore'
	}
	$null = Install-ADDSForest @forestParams
}