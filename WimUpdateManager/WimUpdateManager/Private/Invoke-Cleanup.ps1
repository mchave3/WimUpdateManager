function Invoke-Cleanup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$mountDir
    )
    
    Write-Verbose "$(Get-Timestamp) - Starting cleanup procedure..."
    
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
