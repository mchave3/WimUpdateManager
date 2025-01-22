function Get-Timestamp {
    [CmdletBinding()]
    param()
    
    return Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
}
