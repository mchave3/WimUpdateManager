$here = (Split-Path -Parent $MyInvocation.MyCommand.Path).Replace((Join-Path "Tests" Private), (Join-Path WimUpdateManager Private))
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")

. (Join-Path $here $sut)

# To make test runable from project root, and from test directory itself. Do quick validation.
$testsPath = Join-Path "Tests" "Private"
if ((Get-Location).Path -match [Regex]::Escape($testsPath)) {
    $psmPath = (Resolve-Path "..\..\WimUpdateManager\WimUpdateManager.psm1").Path    
} else {
    $psmPath = (Resolve-Path ".\WimUpdateManager\WimUpdateManager.psm1").Path
}

Import-Module $psmPath -Force -NoClobber

InModuleScope "WimUpdateManager" {
    Describe "Show-Progress" {
        BeforeAll {
            # Mock Write-Progress to capture its parameters
            Mock Write-Progress { }
        }

        It "Should show WIM processing progress correctly" {
            # Act
            Show-Progress -Current 2 -Total 5 -Status "Processing file2.wim"

            # Assert
            Should -Invoke Write-Progress -Times 1 -ParameterFilter {
                $Activity -eq "Processing WIM Files" -and
                $Status -eq "Processing file2.wim" -and
                $PercentComplete -eq 40  # (2/5) * 100
            }
        }

        It "Should show update progress with parent progress correctly" {
            # Act
            Show-Progress -Current 3 -Total 10 -Status "Installing KB123456" -IsUpdate -ParentPercentComplete 50

            # Assert
            Should -Invoke Write-Progress -Times 1 -ParameterFilter {
                $Activity -eq "Installing Updates" -and
                $Status -eq "Installing KB123456" -and
                $PercentComplete -eq 53  # 50 + ((3/10) * 100)/10
            }
        }

        It "Should handle zero total gracefully" {
            # Act & Assert
            { Show-Progress -Current 1 -Total 0 -Status "Test" } | Should -Throw
        }

        It "Should throw when mandatory parameters are missing" {
            # Act & Assert
            { Show-Progress -Current 1 -Total 5 } | Should -Throw
            { Show-Progress -Current 1 -Status "Test" } | Should -Throw
            { Show-Progress -Total 5 -Status "Test" } | Should -Throw
        }

        It "Should handle current greater than total" {
            # Act
            Show-Progress -Current 6 -Total 5 -Status "Test"

            # Assert
            Should -Invoke Write-Progress -Times 1 -ParameterFilter {
                $PercentComplete -eq 100  # Should cap at 100%
            }
        }
    }
}
