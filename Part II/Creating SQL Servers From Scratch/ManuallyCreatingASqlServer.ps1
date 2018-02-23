New-PowerLabVm -Name 'SQLSRV'
Install-PowerLabOperatingSystem -VmName 'SQLSRV'
Start-VM -Name SQLSRV

$vmCred = Import-CliXml -Path 'C:\PowerLab\VMCredential.xml'

while (-not (Invoke-Command -VmName SQLSRV -ScriptBlock { 1 } -Credential $vmCred -ErrorAction Ignore)) {
	Start-Sleep -Seconds 10
	Write-Host 'Waiting for SQLSRV to come up...'
}

$domainCred = Import-CliXml -Path 'C:\PowerLab\DomainCredential.xml'
$addParams = @{
	DomainName = 'powerlab.local'
	Credential = $domainCred
	Restart    = $true
	Force      = $true
}
Invoke-Command -VMName SQLSRV -ScriptBlock { Add-Computer @using:addParams } -Credential $vmCred

while (Invoke-Command -VmName SQLSRV -ScriptBlock { 1 } -Credential $vmCred -ErrorAction Ignore) {
	Start-Sleep -Seconds 10
	Write-Host 'Waiting for SQLSRV to go down...'
}

while (-not (Invoke-Command -VmName SQLSRV -ScriptBlock { 1 } -Credential $domainCred -ErrorAction Ignore)) {
	Start-Sleep -Seconds 10
	Write-Host 'Waiting for SQLSRV to come up...'
}

$session = New-PSSession -VMName 'SQLSRV' -Credential $domainCred
$sqlServerAnswerFilePath = "C:\Program Files\WindowsPowerShell\Modules\PowerLab\SqlServer.ini"
$tempFile = Copy-Item -Path $sqlServerAnswerFilePath -Destination "C:\Program Files\WindowsPowerShell\Modules\PowerLab\temp.ini" -PassThru

$configContents = Get-Content -Path $tempFile.FullName -Raw
$configContents = $configContents.Replace('SQLSVCACCOUNT=""', 'SQLSVCACCOUNT="PowerLabUser"')
$configContents = $configContents.Replace('SQLSVCPASSWORD=""', 'SQLSVCPASSWORD="P@$$w0rd12"')
$configContents = $configContents.Replace('SQLSYSADMINACCOUNTS=""', 'SQLSYSADMINACCOUNTS="PowerLabUser"')
Set-Content -Path $tempFile.FullName -Value $configContents

$copyParams = @{
	Path        = $tempFile.FullName
	Destination = 'C:\'
	ToSession   = $session
}
Copy-Item @copyParams
Remove-Item -Path $tempFile.FullName -ErrorAction Ignore
Copy-Item -Path 'C:\PowerLab\ISOs\en_sql_server_2016_standard_x64_dvd_8701871.iso' -Destination 'C:\' -Force -ToSession $session

$icmParams = @{
	Session      = $session
	ArgumentList = $tempFile.Name
	ScriptBlock  = {
		$image = Mount-DiskImage -ImagePath 'C:\en_sql_server_2016_standard_x64_dvd_8701871.iso' -PassThru
		$installerPath = "$(($image | Get-Volume).DriveLetter):"
		$null = & "$installerPath\setup.exe" "/CONFIGURATIONFILE=C:\$($using:tempFile.Name)"
		$image | Dismount-DiskImage
	}
}
Invoke-Command @icmParams

$scriptBlock = { Remove-Item -Path 'C:\en_sql_server_2016_standard_x64_dvd_8701871.iso', "C:\$($using:tempFile.Name)" -Recurse -ErrorAction Ignore }
Invoke-Command -ScriptBlock $scriptBlock -Session $session
$session | Remove-PSSession