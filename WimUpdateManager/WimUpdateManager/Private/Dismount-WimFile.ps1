function Dismount-WimFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$mountDir
    )
    
    Write-Verbose "$(Get-Timestamp) - Unmounting $mountDir"
    try {
        Dismount-WindowsImage -Path $mountDir -Save
        Write-Verbose "$(Get-Timestamp) - $mountDir unmounted successfully."
    }
    catch {
        Write-Error "$(Get-Timestamp) - Error occurred while unmounting: $($_.Exception.Message)"
        throw
    }
}
