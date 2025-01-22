<#
.SYNOPSIS
Copies specified WIM files from a source folder to a destination folder.

.DESCRIPTION
This function copies one or more WIM files from a source folder to a destination folder.
It verifies the existence of source files and handles potential copy errors.

.PARAMETER sourceFolder
The path to the source folder containing WIM files.

.PARAMETER destinationFolder
The path to the destination folder where WIM files will be copied.

.PARAMETER versions
An array of strings representing the names of WIM files to copy.

.EXAMPLE
Copy-WimFiles -sourceFolder "C:\WIM\Source" -destinationFolder "D:\WIM\Dest" -versions @("win10.wim", "win11.wim")
#>

function Copy-WimFiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$sourceFolder,
        
        [Parameter(Mandatory = $true)]
        [string]$destinationFolder,
        
        [Parameter(Mandatory = $true)]
        [string[]]$versions
    )

    begin {
        Write-Verbose "$(Get-Timestamp) - Starting WIM file copy process"
    }

    process {
        foreach ($version in $versions) {
            $sourcePath = Join-Path $sourceFolder $version
            $destinationPath = Join-Path $destinationFolder $version
            
            if (Test-Path $sourcePath) {
                try {
                    Copy-Item -Path $sourcePath -Destination $destinationPath -Force
                    Write-Verbose "$(Get-Timestamp) - Successfully copied $version"
                }
                catch {
                    Write-Error "$(Get-Timestamp) - Failed to copy $version : $($_.Exception.Message)"
                }
            }
            else {
                Write-Warning "$(Get-Timestamp) - Source file not found: $sourcePath"
            }
        }
    }

    end {
        Write-Verbose "$(Get-Timestamp) - WIM file copy process completed"
    }
}
