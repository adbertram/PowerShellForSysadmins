if ((cmdkey /list:LABDC) -match '\* NONE \*') {
	$null = cmdkey /add:LABDC /user:PowerLabUser /pass:P@$$w0rd12
}

describe 'Automating Operating System Installs' {

	context 'Virtual Disk' {
		
		$expectedVhdPath = 'C:\PowerLab\VHDs\LABDC.vhdx'

		it 'created a VHDX called LABDC in the expected location' {
			$expectedVhdPath | should exist
		}

		it 'attached the virtual disk to the expected VM' {
			Get-VM -Name LABDC | Get-VMHardDiskDrive | Where-Object { $_.Path -eq $expectedVhdPath } | should not benullorEmpty
		}

		it 'creates the expected VHDX format' {
			(Get-VHD -Path $expectedVhdPath).VhdFormat | should be 'VHDX'
		}

		it 'creates the expected VHDX partition style' {

		}

		it 'creates the expected VHDX type' {
			(Get-VHD -Path $expectedVhdPath).Type | should be 'Dynamic'
		}

		it 'creates the VHDDX of the expected size' {
			(Get-VHD -Path $expectedVhdPath).Size / 1GB | should be 40
		}
	}

	context 'Operating System' {

		it 'sets the expected IP defined in the unattend XML file' {
			Invoke-Command -ComputerName '10.0.0.10' -ScriptBlock { hostname } | should be 'LABDC'
		}

		it 'deploys the expected Windows version' {
			(Get-CimInstance -ComputerName LABDC).Caption | should be 'foo'

		}

		it 'deploys the expected Windows edition' {
			(Get-CimInstance -ComputerName LABDC).Something | should be 'foo'
		}
	}
}