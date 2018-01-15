describe 'Automating Operating System Install Prerequisites' {

	$windowsIsoPath = 'C:\PowerLab\ISOs\en_windows_server_2016_x64_dvd_9718492.iso'
	$convertWimImageScriptPath = 'C:\PowerLab\Convert-WindowsImage.ps1'
	$vmName = 'SQLSRV1'
	
	it 'has the Windows ISO available' {
		$windowsIsoPath | should exist
	}

	it 'has the Convert-WindowsImage.ps1 PowerShell script available' {
		$convertWimImageScriptPath | should exist
	}

	it 'has an existing VM setup' {
		Get-Vm -Name $vmName | should not benullorEmpty
	}
}