function Test-Prerequisites {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$workFolder
    )

    $requirements = @{
        "Admin Rights" = { ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) }
    }

    # Add disk space check only after workFolder is defined
    if ($workFolder) {
        $requirements["Disk Space"] = { (Get-PSDrive -Name $workFolder[0]).Free -gt 10GB }
    }

    $failed = @()
    foreach ($req in $requirements.GetEnumerator()) {
        if (-not (& $req.Value)) {
            $failed += $req.Key
        }
    }
    
    return $failed
}
