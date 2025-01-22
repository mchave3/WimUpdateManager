<#
.SYNOPSIS
    Performs cleanup operations for mounted Windows images.
.DESCRIPTION
    This function performs cleanup operations by safely unmounting any Windows images
    that are mounted at the specified mount directory. Use -WhatIf to simulate operations.
.EXAMPLE
    Invoke-Cleanup -MountDir "C:\Mount" -WhatIf
    Shows what would happen if the command runs without actually unmounting images.
.PARAMETER MountDir
    The directory where Windows images are mounted.
.OUTPUTS
    None
.NOTES
    Author:  Mickaël CHAVE
    Date:    2025-01-22
    Version: 1.1
#>
function Invoke-Cleanup {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$MountDir
    )
    
    begin {
        Write-Host "$(Get-Timestamp) - Starting cleanup procedure..."
    }
    
    process {
        try {
            # Check if a mount point exists using PowerShell
            $mountedImages = Get-WindowsImage -Mounted
            if ($mountedImages.ImagePath -match $MountDir) {
                Write-Host "$(Get-Timestamp) - Found mounted image at $MountDir"
                
                if ($PSCmdlet.ShouldProcess($MountDir, "Unmount Windows Image")) {
                    Write-Host "$(Get-Timestamp) - Unmounting image from $MountDir"
                    Dismount-WindowsImage -Path $MountDir
                    Write-Host "$(Get-Timestamp) - Successfully unmounted image."
                }
            }
        }
        catch {
            Write-Error "$(Get-Timestamp) - Failed to perform cleanup: $($_.Exception.Message)"
        }
    }
    
    end {
    }
}