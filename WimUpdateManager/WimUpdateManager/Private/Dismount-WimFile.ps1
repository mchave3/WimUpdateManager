<#
.SYNOPSIS
Dismounts a previously mounted Windows Image (WIM) file.

.DESCRIPTION
This function safely dismounts a Windows Image from its mount point, saving any changes made.
It includes error handling and logging capabilities.

.PARAMETER mountDir
The directory where the WIM file is currently mounted.

.EXAMPLE
Dismount-WimFile -mountDir "C:\Mount"

.NOTES
This is an internal function that should not be called directly from outside the module.
The function will save any changes made to the mounted image before dismounting.
#>
function Dismount-WimFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$mountDir
    )
    
    begin {
        Write-Verbose "$(Get-Timestamp) - Unmounting $mountDir"
    }

    process {
        try {
            Dismount-WindowsImage -Path $mountDir -Save
            Write-Verbose "$(Get-Timestamp) - $mountDir unmounted successfully."
        }
        catch {
            Write-Error "$(Get-Timestamp) - Error occurred while unmounting: $($_.Exception.Message)"
            throw
        }
    }

    end {
    }
}
