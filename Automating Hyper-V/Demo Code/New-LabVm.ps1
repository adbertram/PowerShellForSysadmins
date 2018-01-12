param(
	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$Name,

	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$Path,

	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[Int64]$Memory,

	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$Switch,

	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[ValidateRange(1, 2)]
	[int]$Generation,

	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$ComputerName
)

if (-not (Get-Vm -ComputerName $ComputerName -Name $Name -ErrorAction SilentlyContinue)) {
	$netAdapterName = (Get-NetAdapter -CimSession $HyperVHost -Physical | Where-Object { $_.Status -eq 'Up' }).Name
	$null = New-VM -Name $Name -Path $Path -MemoryStartupBytes $Memory -Switch $Switch -Generation $Generation -ComputerName $ComputerName
} else {
	Write-Verbose -Message "The VM [$($Name)] has already been created."
}