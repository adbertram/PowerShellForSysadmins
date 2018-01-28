describe 'Creating and Configuring SQL Servers' {

	BeforeAll {
		$domainCred = Import-Clixml -Path C:\PowerLab\DomainCredential.xml
		$session = New-PSSession -VMName 'SQLSRV' -Credential $domainCred
	}

	AfterAll {
		$session | Remove-PSSession
	}

	context 'SQL Server installation' {

		it 'SQL Server is installed' {
			Invoke-Command -Session $session -ScriptBlock { Get-Service -Name 'MSSQLSERVER' } | should not benullorEmpty
		}
	}

	context 'SQL Server configuration' {

		it 'PowerLabUser holds the sysadmin role' {
			Invoke-Command -Session $session -ScriptBlock {  } | should not benullorEmpty
		}

		it 'the MSSQLSERVER is running under the PowerLabUser account' {
			Invoke-Command -Session $session -ScriptBlock { Get-CimInstance -Class Win32_Service -Filter 'Name = "MSSQLSERVER"'  } | should be 'PowerLabUser'
		}
	}
}