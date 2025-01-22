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
