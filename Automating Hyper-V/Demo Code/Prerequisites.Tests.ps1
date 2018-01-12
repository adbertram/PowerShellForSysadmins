describe 'Automating Hyper-V Chapter Prerequisites' {

	$hyperVHostName = 'HYPERVSRV'

	it 'Hyper-V host server name should resolve to an IP' {
		Resolve-DnsName -Name $hyperVHostName -Type A -ErrorAction SilentlyContinue | should not benullorEmpty
	}

	it 'Hyper-V host server should be pingable' {
		Test-Connection -ComputerName $hyperVHostName -Count 1 -Quiet | should be $true
	}

	it 'Hyper-V host server should have the Hyper-V Windows feature installed' {
		$hyperVFeature = Get-WindowsFeature -ComputerName $hyperVHostName -Name 'Hyper-V'
		$hyperVFeature | should not benullorEmpty
		$hyperVFeature.Installed | should be $true
	}

	it 'logged in user should be able to remotely run a command on the Hyper-V host' {
		Invoke-Command -ComputerName $hyperVHostName -ScriptBlock {hostname} | should be $hyperVHostName
	}

	it 'local computer has the Hyper-V PowerShell module v1.1 installed' {
		Get-Module -Name 'Hyper-V' -ListAvailable | Where-Object { $_.Version -eq '1.1' } | should not benullorEmpty
	}
}