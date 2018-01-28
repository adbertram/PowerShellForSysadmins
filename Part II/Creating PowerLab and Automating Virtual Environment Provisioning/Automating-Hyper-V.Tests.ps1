describe 'Automating Hyper-V Chapter Demo Work' {

	$createdVM = Get-Vm -Name 'LABDC' -ErrorAction SilentlyContinue

	context 'Virtual Switch' {
		it 'created a virtual switch called PowerLab' {
			Get-VmSwitch -Name 'PowerLab' -ErrorAction SilentlyContinue | should not benullorEmpty
		}
	}

	context 'Virtual Machine' {
		it 'created a virtual machine called LABDC' {
			$createdVM | should not benullorEmpty
		}
	}

	context 'Virtual Hard Disk' {
		it 'created a VHDX called LABDC at C:\PowerLab\VHDs' {
			'C:\PowerLab\VHDs\LABDC.vhdx' | should exist
		}

		it 'attached the LABDC VHDX to the LABDC VM' {
			$createdVM | Get-VMHardDiskDrive | Where-Object { $_.Path -eq 'C:\PowerLab\VHDs\LABDC.vhdx' } | should not benullorEmpty
		}
	}
}