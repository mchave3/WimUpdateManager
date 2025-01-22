function Mount-WimFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$wimPath,
        
        [Parameter(Mandatory = $true)]
        [string]$mountDir
    )
    
    Write-Verbose "$(Get-Timestamp) - Mounting $wimPath"
    try {
        Mount-WindowsImage -ImagePath $wimPath -Index 1 -Path $mountDir
        Write-Verbose "$(Get-Timestamp) - $wimPath mounted successfully."
    }
    catch {
        Write-Error "$(Get-Timestamp) - Error occurred while mounting: $($_.Exception.Message)"
        throw
    }
}
