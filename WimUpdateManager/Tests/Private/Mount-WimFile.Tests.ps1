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
    Describe "Mount-WimFile" {
        BeforeAll {
            # Mock required functions
            Mock Mount-WindowsImage { }
            Mock Write-Verbose { }
            Mock Write-Error { }
            Mock Get-Timestamp { return "2024-01-22 12:00:00" }

            # Test parameters
            $testWimPath = "TestDrive:\test.wim"
            $testMountDir = "TestDrive:\Mount"
        }

        It "Should mount WIM file successfully" {
            # Act
            Mount-WimFile -wimPath $testWimPath -mountDir $testMountDir

            # Assert
            Should -Invoke Mount-WindowsImage -Times 1 -ParameterFilter {
                $ImagePath -eq $testWimPath -and
                $Path -eq $testMountDir -and
                $Index -eq 1
            }
            Should -Invoke Write-Error -Times 0
        }

        It "Should throw when mounting fails" {
            # Arrange
            Mock Mount-WindowsImage { throw "Mount failed" }

            # Act & Assert
            { Mount-WimFile -wimPath $testWimPath -mountDir $testMountDir } | 
                Should -Throw
            Should -Invoke Write-Error -Times 1
        }

        It "Should throw when mandatory parameters are missing" {
            # Act & Assert
            { Mount-WimFile -wimPath $testWimPath } | Should -Throw
            { Mount-WimFile -mountDir $testMountDir } | Should -Throw
        }
    }
}
