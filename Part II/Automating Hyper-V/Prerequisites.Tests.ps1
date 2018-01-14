describe 'Automating Hyper-V Chapter Prerequisites' {

	it 'Hyper-V host server should have the Hyper-V Windows feature installed' {
		Get-WindowsFeature -Name 'Hyper-V' | should not benullorEmpty
		$hyperVFeature.Installed | should be $true
	}
}