param(
	[Parameter()]
	[ValidateNotNullOrEmpty()]
	[string]$SwitchName,

	[Parameter()]
	[ValidateNotNullOrEmpty()]
	[string]$SwitchType
)

if (-not (Get-VmSwitch -Name $SwitchName -SwitchType $SwitchType -ErrorAction SilentlyContinue)) {
	$netAdapterName = (Get-NetAdapter -Physical | Where-Object { $_.Status -eq 'Up' }).Name
	$null = New-VMSwitch -Name $SwitchName -NetAdapterName $netAdapterName
} else {
	Write-Verbose -Message "The switch [$($SwitchName)] has already been created."
}