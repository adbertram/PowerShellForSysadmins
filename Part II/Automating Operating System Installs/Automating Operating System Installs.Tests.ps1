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
		it 'deploys the expected Windows version' {

		}

		it 'deploys the expected Windows edition' {

		}
	}
}