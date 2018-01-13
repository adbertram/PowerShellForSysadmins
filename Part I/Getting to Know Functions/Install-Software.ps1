function Install-Software {
    param(
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [ValidateSet('1','2')]
        [string]$Version,

        [Parameter(ValueFromPipelineByPropertyName)]
	  [string]$ComputerName
    )

    process {
        <#>
        ## Connect to the remote with some code here
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            ## Do stuff to install the version of the software on this computer here
            Start-Process -FilePath 'msiexec.exe' -ArgumentList 'C:\Setup\SoftwareV{0}.msi' -f $using:Version
        }
        #>
        Write-Host "I am installing software version [$Version] on computer [$ComputerName]"
    }
}
