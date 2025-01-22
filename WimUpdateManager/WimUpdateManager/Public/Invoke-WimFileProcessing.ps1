function Invoke-WimFileProcessing {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$wimFile,
        
        [Parameter()]
        [int]$parentProgress = 0
    )

    begin {
        Write-Verbose "$(Get-Timestamp) - Starting WIM file processing for $($wimFile.Name)"
        $mountDir = Join-Path $env:TEMP "WimMount"
        
        if (-not (Test-Path $mountDir)) {
            New-Item -Path $mountDir -ItemType Directory -Force | Out-Null
        }
    }

    process {
        try {
            # Mount the WIM file
            Mount-WimFile -wimPath $wimFile.FullName -mountDir $mountDir

            # Determine Windows version and get appropriate updates
            $windowsVersion = Get-WindowsVersion -mountDir $mountDir
            $updates = Get-WindowsUpdates -windowsVersion $windowsVersion

            if ($updates) {
                # Add updates
                Add-Updates -wimName $wimFile.Name -mountDir $mountDir -updates $updates -parentProgress $parentProgress
            }
            else {
                Write-Warning "$(Get-Timestamp) - No updates found for $($wimFile.Name)"
            }

            # Unmount the WIM file
            Dismount-WimFile -mountDir $mountDir
        }
        catch {
            Write-Error "$(Get-Timestamp) - Error processing $($wimFile.Name): $($_.Exception.Message)"
            Invoke-Cleanup -mountDir $mountDir
        }
    }

    end {
        Write-Verbose "$(Get-Timestamp) - WIM file processing completed for $($wimFile.Name)"
        if (Test-Path $mountDir) {
            Remove-Item -Path $mountDir -Force -Recurse -ErrorAction SilentlyContinue
        }
    }
}
