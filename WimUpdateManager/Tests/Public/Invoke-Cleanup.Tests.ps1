$here = (Split-Path -Parent $MyInvocation.MyCommand.Path).Replace((Join-Path "Tests" Public), (Join-Path WimUpdateManager Public))
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")

. (Join-Path $here $sut)

# To make test runable from project root, and from test directory itself. Do quick validation.
$testsPath = Join-Path "Tests" "Public"
if ((Get-Location).Path -match [Regex]::Escape($testsPath)) {
    $psmPath = (Resolve-Path "..\..\WimUpdateManager\WimUpdateManager.psm1").Path    
} else {
    $psmPath = (Resolve-Path ".\WimUpdateManager\WimUpdateManager.psm1").Path
}

Import-Module $psmPath -Force -NoClobber

InModuleScope "WimUpdateManager" {

    Describe "Invoke-Cleanup" {
        Context "When using -WhatIf parameter" {
            BeforeAll {
                $testMountDir = "C:\TestMount"
                Mock Get-WindowsImage -MockWith {
                    @(
                        @{
                            ImagePath = "C:\TestMount\image.wim"
                            Path = "C:\TestMount"
                        }
                    )
                }
                Mock Dismount-WindowsImage {}
                Mock Write-Host {}
            }

            It "Should not unmount images when -WhatIf is specified" {
                Invoke-Cleanup -MountDir $testMountDir -WhatIf
                Should -Not -Invoke Dismount-WindowsImage
            }

            It "Should show WhatIf message for mounted image" {
                $output = Invoke-Cleanup -MountDir $testMountDir -WhatIf 4>&1
                $output | Should -Match "What if: .+Unmount Windows Image.+C:\\TestMount"
            }

            It "Should still check for mounted images with -WhatIf" {
                Invoke-Cleanup -MountDir $testMountDir -WhatIf
                Should -Invoke Get-WindowsImage -Times 1 -ParameterFilter { $Mounted -eq $true }
            }
        }
    }
}
