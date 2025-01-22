<#
.SYNOPSIS
Mounts a Windows Image (WIM) file to a specified directory.

.DESCRIPTION
This function mounts a WIM file to a specified directory using the Mount-WindowsImage cmdlet.
It includes error handling and logging capabilities.

.PARAMETER wimPath
The full path to the WIM file to be mounted.

.PARAMETER mountDir
The directory where the WIM file should be mounted.

.EXAMPLE
Mount-WimFile -wimPath "C:\Images\windows.wim" -mountDir "C:\Mount"

.NOTES
This is an internal function that should not be called directly from outside the module.
#>
function Mount-WimFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$wimPath,
        
        [Parameter(Mandatory = $true)]
        [string]$mountDir
    )
    
    begin {
        Write-Verbose "$(Get-Timestamp) - Mounting $wimPath"
    }

    process {
        try {
            Mount-WindowsImage -ImagePath $wimPath -Index 1 -Path $mountDir
            Write-Verbose "$(Get-Timestamp) - $wimPath mounted successfully."
        }
        catch {
            Write-Error "$(Get-Timestamp) - Error occurred while mounting: $($_.Exception.Message)"
            throw
        }
    }

    end {
    }
}
