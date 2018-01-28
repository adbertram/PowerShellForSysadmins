describe 'Creating and Configuring SQL Servers Prerequisites' {

	$vmName = 'LABDC'

	it 'has a VM called LABDC setup' {
		Get-Vm -Name $vmName | should not benullorEmpty
	}

	it 'LABDC must be running' {
		(Get-VM -Name $vmName).State | should be 'Running'
	}

	it 'must have a domain credential stored locally' {
		'C:\PowerLab\DomainCredential.xml' | should exist
	}

	it 'LABDC must be a domain controller' {
		$icmParams = @{
			VMName      = $vmName
			Credential  = (Import-CliXml -path C:\PowerLab\DomainCredential.xml)
			ScriptBlock = { (Get-AddomainController).Name }
		}
		Invoke-Command @icmParams | should be $vmName
	}

	it 'the PowerLab module must be installed' {
		'C:\Program Files\WindowsPowerShell\Modules\PowerLab\PowerLab.psm1' | should exist
	}

	it 'the SQLServer.ini answer file template must exist' {
		'C:\Program Files\WindowsPowerShell\Modules\PowerLab\SQLServer.ini' | should exist
	}

	it 'the SQL server 2016 ISO file must exist' {
		'C:\PowerLab\ISOs\en_sql_server_2016_standard_x64_dvd_8701871.iso' | should exist
	}
}