describe 'Automating Hyper-V Chapter Prerequisites' {

	it 'Hyper-V host server should have the Hyper-V Windows feature installed' {
		$feature = Get-WindowsFeature -Name 'Hyper-V'
		$feature | should not benullorEmpty
		$feature.Installed | should be $true
	}

	it 'Hyper-V host server is Windows Server 2016' {
		(Get-CimInstance -Class Win32_OperatingSystem).Caption | should belike 'Microsoft Windows Server 2016*'
	}

	it 'Hyper-V host server shoud have at least 100GB of available storage' {
		(Get-CimInstance -Class Win32_LogicalDisk -Filter "DeviceId = 'C:'").FreeSpace /1GB | should begreaterthan 100
	}

	it 'has a PowerLab folder at the root of C' {
		'C:\PowerLab' | should exist
	}

	it 'has a PowerLab\VMs folder at the root of C' {
		'C:\PowerLab\VMs' | should exist
	}

	it 'has a PowerLab\VHDs folder at the root of C' {
		'C:\PowerLab\VHDs' | should exist
	}
}