describe 'Automating Hyper-V Chapter Prerequisites' {

	it 'Hyper-V host server should have the Hyper-V Windows feature installed' {
		$feature = Get-WindowsFeature -Name 'Hyper-V'
		$feature | should not benullorEmpty
		$feature.Installed | should be $true
	}

	it 'Hyper-V host server is Windows Server 2016' {
		(Get-CimInstance -Class Win32_OperatingSystem).Caption | should belike 'Microsoft Windows Server 2016'
	}
}