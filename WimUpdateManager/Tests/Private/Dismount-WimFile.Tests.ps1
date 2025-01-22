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
    Describe "Dismount-WimFile" {
        BeforeAll {
            # Mock required functions
            Mock Dismount-WindowsImage { }
            Mock Write-Verbose { }
            Mock Write-Error { }
            Mock Get-Timestamp { return "2024-01-22 12:00:00" }

            # Test parameters
            $testMountDir = "TestDrive:\Mount"
        }

        It "Should dismount WIM file successfully" {
            # Act
            Dismount-WimFile -mountDir $testMountDir

            # Assert
            Should -Invoke Dismount-WindowsImage -Times 1 -ParameterFilter {
                $Path -eq $testMountDir -and
                $Save -eq $true
            }
            Should -Invoke Write-Error -Times 0
        }

        It "Should throw when dismounting fails" {
            # Arrange
            Mock Dismount-WindowsImage { throw "Dismount failed" }

            # Act & Assert
            { Dismount-WimFile -mountDir $testMountDir } | 
                Should -Throw
            Should -Invoke Write-Error -Times 1
        }

        It "Should throw when mandatory parameters are missing" {
            # Act & Assert
            { Dismount-WimFile } | Should -Throw
        }
    }
}
