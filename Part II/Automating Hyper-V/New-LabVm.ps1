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
	[int]$Generation
)

if (-not (Get-Vm -Name $Name -ErrorAction SilentlyContinue)) {
	$null = New-VM -Name $Name -Path $Path -MemoryStartupBytes $Memory -Switch $Switch -Generation $Generation
} else {
	Write-Verbose -Message "The VM [$($Name)] has already been created."
}