describe 'Automating Hyper-V Chapter Demo Work' {

	$sharedVmParams = @{
		ComputerName = 'HYPERVSRV'
	}

	$createdVM = Get-Vm @sharedVmParams -Name 'SQLSRV' -ErrorAction SilentlyContinue

	context 'Virtual Switch' {
		it 'created a virtual switch called ExternalSwitch' {
			Get-VmSwitch @sharedVmParams -Name 'ExternalSwitch' -ErrorAction SilentlyContinue | should not benullorEmpty
		}
	}

	context 'Virtual Machine' {
		it 'created a virtual machine called SQLSRV' {
			$createdVM | should not benullorEmpty
		}
	}

	context 'Virtual Hard Disk' {
		it 'created a VHDX called SQLSRV at C:\PowerLab\VHDs' {
			"\\$($sharedVmParams.ComputerName)\C$\PowerLab\VHDs\SQLSRV.vhdx" | should exist
		}

		it 'attached the SQLSRV VHDX to the SQLSRV VM' {
			$createdVM | Get-VMHardDiskDrive | Where-Object { $_.Path -eq 'C:\PowerLab\VHDs\SQLSRV.vhdx' } | should not benullorEmpty
		}
	}
}