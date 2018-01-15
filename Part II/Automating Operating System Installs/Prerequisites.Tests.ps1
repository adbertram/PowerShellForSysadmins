describe 'Automating Operating System Install Prerequisites' {

	$isosPath = 'C:\PowerLab\ISOs'
	$windowsIsoPath = "$isosPath\en_windows_server_2016_x64_dvd_9718492.iso"
	$convertWimImageScriptPath = 'C:\PowerLab\Convert-WindowsImage.ps1'
	$vmName = 'LABDC'

	it 'has an ISOs folder created' {
		$isosPath | should exist
	}
	
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