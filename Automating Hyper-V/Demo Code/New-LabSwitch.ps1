param(
	[Parameter()]
	[ValidateNotNullOrEmpty()]
	[string]$SwitchName,

	[Parameter()]
	[ValidateNotNullOrEmpty()]
	[string]$SwitchType,

	[Parameter()]
	[ValidateNotNullOrEmpty()]
	[string]$HyperVHost
)

if (-not (Get-VmSwitch -Name $SwitchName -SwitchType $SwitchType -ComputerName $HyperVHost -ErrorAction SilentlyContinue)) {
	$netAdapterName = (Get-NetAdapter -CimSession $HyperVHost -Physical | Where-Object { $_.Status -eq 'Up' }).Name
	$null = New-VMSwitch -Name $SwitchName -NetAdapterName $netAdapterName -ComputerName $HyperVHost
} else {
	Write-Verbose -Message "The switch [$($SwitchName)] has already been created."
}