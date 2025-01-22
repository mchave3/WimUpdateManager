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
    Describe "Test-Prerequisites" {
        BeforeAll {
            # Mock IsInRole for admin check
            $mockWindowsPrincipal = [PSCustomObject]@{
                IsInRole = { param($role) $script:IsAdmin }
            }
            Mock Get-PSDrive {
                return [PSCustomObject]@{
                    Free = $script:DiskSpace
                }
            }
            Mock New-Object { return $mockWindowsPrincipal } -ParameterFilter { 
                $TypeName -eq 'Security.Principal.WindowsPrincipal' 
            }
        }

        It "Should pass all checks when prerequisites are met" {
            # Arrange
            $script:IsAdmin = $true
            $script:DiskSpace = 20GB
            
            # Act
            $result = Test-Prerequisites -workFolder "C:"

            # Assert
            $result | Should -BeNullOrEmpty
        }

        It "Should fail admin check when not running as admin" {
            # Arrange
            $script:IsAdmin = $false
            $script:DiskSpace = 20GB

            # Act
            $result = Test-Prerequisites -workFolder "C:"

            # Assert
            $result | Should -Contain "Admin Rights"
        }

        It "Should fail disk space check when insufficient space" {
            # Arrange
            $script:IsAdmin = $true
            $script:DiskSpace = 5GB

            # Act
            $result = Test-Prerequisites -workFolder "C:"

            # Assert
            $result | Should -Contain "Disk Space"
        }

        It "Should not check disk space when workFolder is not provided" {
            # Arrange
            $script:IsAdmin = $true
            $script:DiskSpace = 5GB

            # Act
            $result = Test-Prerequisites

            # Assert
            $result | Should -Not -Contain "Disk Space"
        }

        It "Should fail multiple checks when multiple prerequisites are not met" {
            # Arrange
            $script:IsAdmin = $false
            $script:DiskSpace = 5GB

            # Act
            $result = Test-Prerequisites -workFolder "C:"

            # Assert
            $result | Should -Contain "Admin Rights"
            $result | Should -Contain "Disk Space"
            $result.Count | Should -Be 2
        }
    }
}
