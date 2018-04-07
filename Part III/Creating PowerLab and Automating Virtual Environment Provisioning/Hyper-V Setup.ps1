## Run this on the server you want to be a Hyper-V host
Install-WindowsFeature -Name Hyper-V -IncludeManagementTools -Restart 

'C:\PowerLab', 'C:\PowerLab\VMs', 'C:\PowerLab\VHDs' | ForEach-Object {
	$null = mkdir -Path $_
}