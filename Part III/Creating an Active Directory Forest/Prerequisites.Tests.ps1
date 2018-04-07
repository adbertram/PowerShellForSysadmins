describe 'Automating Operating System Install Prerequisites' {

	$vmName = 'LABDC'

	it 'has an existing VM setup' {
		Get-Vm -Name $vmName | should not benullorEmpty
	}

	it 'the existing VM must be running' {
		(Get-VM -Name $vmName).State | should be 'Running'
	}

}