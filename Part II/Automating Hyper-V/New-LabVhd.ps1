param
(
	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$Name,
		
	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[ValidateRange(512MB, 1TB)]
	[int64]$Size,
	
	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[ValidateSet('Dynamic', 'Fixed')]
	[string]$Sizing,

	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$Path,

	[Parameter()]
	[ValidateNotNullOrEmpty()]
	[string]$AttachToVm
)

$vhdxFileName = "$Name.vhdx"
$vhdxFilePath = Join-Path -Path $Path -ChildPath "$Name.vhdx"

## Ensure we don't try to create a VHD when there's already one there
if (-not (Test-Path -Path $vhdxFilePath -PathType Leaf)) {
	$params = @{
		SizeBytes = $Size
		Path      = $vhdxFilePath
	}
	if ($Sizing -eq 'Dynamic') {
		$params.Dynamic = $true
	} elseif ($Sizing -eq 'Fixed') {
		$params.Fixed = $true
	}

	New-VHD @params
	Write-Verbose -Message "Created new VHD at path [$($vhdxFilePath)]"
}

## Attach either the newly created VHD or the one that was already there to the VM.
if ($PSBoundParameters.ContainsKey('AttachToVm')) {
	if (-not ($vm = Get-VM -Name $AttachToVm -ErrorAction SilentlyContinue)) {
		Write-Warning -Message "The VM [$($AttachToVm)] does not exist. Unable to attach VHD."
	} elseif (-not ($vm | Get-VMHardDiskDrive | Where-Object { $_.Path -eq $vhdxFilePath })) {
		$vm | Add-VMHardDiskDrive -Path $vhdxFilePath
		Write-Verbose -Message "Attached VHDX [$($vhdxFilePath)] to VM [$($AttachToVM)]."
	} else {
		Write-Verbose -Message "VHDX [$($vhdxFilePath)] already attached to VM [$($AttachToVM)]."
	}
}