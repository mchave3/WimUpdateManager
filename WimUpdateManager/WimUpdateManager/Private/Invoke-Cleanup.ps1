<#
.SYNOPSIS
Performs cleanup operations on mounted WIM files.

.DESCRIPTION
This function checks for and cleans up any mounted WIM files at the specified mount point.
If a mounted image is found, it will be dismounted with the 'Discard' option to abandon any changes.
This is typically used in error handling scenarios where a clean state needs to be restored.

.PARAMETER mountDir
The directory where the WIM file might be mounted.

.EXAMPLE
Invoke-Cleanup -mountDir "C:\Mount"

.NOTES
This is an internal function that should not be called directly from outside the module.
The function will discard any changes made to the mounted image during cleanup.
#>
function Invoke-Cleanup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$mountDir
    )
    
    begin {
        Write-Verbose "$(Get-Timestamp) - Starting cleanup procedure..."
    }

    process {
        try {
            # Check if a mount point exists
            $mountedImages = Get-WindowsImage -Mounted
            if ($mountedImages.ImagePath -match $mountDir) {
                Write-Verbose "$(Get-Timestamp) - Found mounted image, attempting to unmount..."
                Dismount-WindowsImage -Path $mountDir -Discard
                Write-Verbose "$(Get-Timestamp) - Successfully unmounted image."
            }
        }
        catch {
            Write-Error "$(Get-Timestamp) - Failed to perform cleanup: $($_.Exception.Message)"
        }
    }

    end {
    }
}
