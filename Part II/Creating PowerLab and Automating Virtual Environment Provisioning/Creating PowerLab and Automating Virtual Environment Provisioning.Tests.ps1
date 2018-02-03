describe 'PowerLab setup' {
	context 'Virtual Switch' {
		it 'created a virtual switch called PowerLab' {
			Get-VmSwitch -Name 'PowerLab' -ErrorAction SilentlyContinue | should not benullorEmpty
		}
	}
}

describe 'LABDC VM' {

	$createdVM = Get-Vm -Name 'LABDC' -ErrorAction SilentlyContinue

	context 'Virtual Machine' {
		it 'created a virtual machine called LABDC' {
			$createdVM | should not benullorEmpty
		}
	}

	context 'Virtual Hard Disk' {
		it 'created a VHDX called MYVM at C:\PowerLab\VHDs' {
			'C:\PowerLab\VHDs\MYVM.vhdx' | should exist
		}

		it 'attached the MYVM VHDX to the MYVM VM' {
			$createdVM | Get-VMHardDiskDrive | Where-Object { $_.Path -eq 'C:\PowerLab\VHDs\MYVM.vhdx' } | should not benullorEmpty
		}
	}
}