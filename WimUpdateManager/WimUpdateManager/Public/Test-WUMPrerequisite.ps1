
<#
.SYNOPSIS
    Tests if all prerequisites are met for the WIM Update Manager.
.DESCRIPTION
    This function checks if the following prerequisites are met:
    - Administrator rights
    - Sufficient disk space (if workFolder parameter is provided)
.EXAMPLE
    Test-Prerequisites
    Returns an array of failed prerequisites.
.EXAMPLE
    Test-Prerequisites -WorkFolder "E:"
    Returns an array of failed prerequisites including disk space check for drive E:.
.PARAMETER WorkFolder
    Optional. The drive letter or path to check for disk space requirements.
.OUTPUTS
    System.String[]. Returns an array of failed prerequisite names.
.NOTES
    Author:  Mickaël CHAVE
    Date:    2025-01-22
    Version: 1.0
#>
function Test-WUMPrerequisite {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$WorkFolder
    )
    
    begin {
        $requirements = @{
            "Admin Rights" = { ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) }
        }

        if ($WorkFolder) {
            $requirements["Disk Space"] = { (Get-PSDrive -Name $WorkFolder[0]).Free -gt 10GB }
        }
    }
    
    process {
        $failed = @()
        foreach ($req in $requirements.GetEnumerator()) {
            if (-not (& $req.Value)) {
                $failed += $req.Key
            }
        }
        return $failed
    }
    
    end {
    }
}