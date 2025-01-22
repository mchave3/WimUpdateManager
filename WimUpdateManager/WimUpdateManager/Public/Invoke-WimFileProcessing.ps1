<#
.SYNOPSIS
Processes a WIM file by mounting it, applying updates, and dismounting it safely.

.DESCRIPTION
This function handles the complete lifecycle of WIM file processing:
1. Creates a temporary mount directory
2. Mounts the WIM file
3. Determines the Windows version
4. Applies appropriate updates if available
5. Safely dismounts the WIM file
6. Cleans up temporary resources

The function includes error handling and cleanup procedures to ensure system stability.

.PARAMETER wimFile
A FileInfo object representing the WIM file to process.

.PARAMETER parentProgress
Optional. The progress percentage of the parent operation, used for nested progress bars.
Default is 0.

.EXAMPLE
$wim = Get-Item "C:\Images\windows.wim"
Invoke-WimFileProcessing -wimFile $wim

.EXAMPLE
Invoke-WimFileProcessing -wimFile $wim -parentProgress 50 -Verbose
#>
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
            Dismount-WimFile -mountDir $mountDir -save $true
        }
        catch {
            Write-Error "$(Get-Timestamp) - Error processing WIM file: $($_.Exception.Message)"
            # Attempt to cleanup even if there's an error
            Invoke-Cleanup -mountDir $mountDir
            throw
        }
        finally {
            # Remove the mount directory if it exists
            if (Test-Path $mountDir) {
                Remove-Item -Path $mountDir -Force -Recurse -ErrorAction SilentlyContinue
            }
        }
    }

    end {
        Write-Verbose "$(Get-Timestamp) - WIM file processing completed for $($wimFile.Name)"
    }
}
