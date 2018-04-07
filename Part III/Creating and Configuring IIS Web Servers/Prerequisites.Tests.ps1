describe 'Creating and Configuring IIS Web Servers Prerequisites' {

	$vmName = 'WEBSRV'

	it 'has a VM called WEBSRV setup' {
		Get-Vm -Name $vmName | should not benullorEmpty
	}

	it 'WEBSRV must be running' {
		(Get-VM -Name $vmName).State | should be 'Running'
	}

	it 'must have a domain credential stored locally' {
		'C:\PowerLab\DomainCredential.xml' | should exist
	}

	it 'the PowerLab module must be installed' {
		'C:\Program Files\WindowsPowerShell\Modules\PowerLab\PowerLab.psm1' | should exist
	}
}