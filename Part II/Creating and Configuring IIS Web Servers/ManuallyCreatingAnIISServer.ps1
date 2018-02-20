New-PowerLabVm -Name 'WEBSRV'
Install-PowerLabOperatingSystem -VmName 'WEBSRV'
Start-VM -Name WEBSRV

$vmCred = Import-CliXml -Path 'C:\PowerLab\VMCredential.xml'

while (-not (Invoke-Command -VmName WEBSRV -ScriptBlock { 1 } -Credential $vmCred -ErrorAction Ignore)) {
	Start-Sleep -Seconds 10
	Write-Host 'Waiting for WEBSRV to come up...'
}

$domainCred = Import-CliXml -Path 'C:\PowerLab\DomainCredential.xml'
$addParams = @{
	DomainName = 'powerlab.local'
	Credential = $domainCred
	Restart    = $true
	Force      = $true
}
Invoke-Command -VMName WEBSRV -ScriptBlock { Add-Computer @using:addParams } -Credential $vmCred

while (Invoke-Command -VmName WEBSRV -ScriptBlock { 1 } -Credential $vmCred -ErrorAction Ignore) {
	Start-Sleep -Seconds 10
	Write-Host 'Waiting for WEBSRV to go down...'
}

while (-not (Invoke-Command -VmName WEBSRV -ScriptBlock { 1 } -Credential $domainCred -ErrorAction Ignore)) {
	Start-Sleep -Seconds 10
	Write-Host 'Waiting for WEBSRV to come up...'
}

$session = New-PSSession -VMName 'WEBSRV' -Credential $domainCred

## Enable the IIS Windows feature


$session | Remove-PSSession