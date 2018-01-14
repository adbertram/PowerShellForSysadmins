$hyperVHostName = 'HYPERVSRV'

describe 'Automating Hyper-V Chapter Prerequisites' {

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

describe 'Automating Operating System Install Prerequisites' {

	$windowsIsoPath = '\\HYPERVSRV\c$\PowerLab\ISOs\en_windows_server_2016_x64_dvd_9718492.iso'
	$convertWimImageScriptPath = '\\HYPERVSRV\c$\PowerLab\Convert-WindowsImage.ps1'
	$vmName = 'SQLSRV1'
	
	it 'has the Windows ISO available' {
		$windowsIsoPath | should exist
	}

	it 'has the Convert-WindowsImage.ps1 PowerShell script available' {
		$convertWimImageScriptPath | should exist
	}

	it 'has an existing VM setup' {
		Get-Vm -Name $vmName -ComputerName $hyperVHostName | should not benullorEmpty
	}
}