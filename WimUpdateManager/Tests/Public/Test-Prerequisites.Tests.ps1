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

    Describe "Test-Prerequisites" {
        BeforeAll {
            Mock ([Security.Principal.WindowsPrincipal]).IsInRole { return $false }
            Mock Get-PSDrive { return @{ Free = 5GB } }
        }

        Context "When running without admin rights" {
            It "Should return 'Admin Rights' as failed requirement" {
                $result = Test-Prerequisites
                $result | Should -Contain "Admin Rights"
            }
        }

        Context "When checking disk space" {
            It "Should return 'Disk Space' as failed requirement when space is insufficient" {
                $result = Test-Prerequisites -WorkFolder "C:"
                $result | Should -Contain "Disk Space"
            }

            It "Should not return 'Disk Space' when space is sufficient" {
                Mock Get-PSDrive { return @{ Free = 20GB } }
                $result = Test-Prerequisites -WorkFolder "C:"
                $result | Should -Not -Contain "Disk Space"
            }
        }

        Context "When all prerequisites are met" {
            BeforeEach {
                Mock ([Security.Principal.WindowsPrincipal]).IsInRole { return $true }
                Mock Get-PSDrive { return @{ Free = 20GB } }
            }

            It "Should return empty array when no WorkFolder is specified" {
                $result = Test-Prerequisites
                $result | Should -BeNullOrEmpty
            }

            It "Should return empty array when WorkFolder is specified and has sufficient space" {
                $result = Test-Prerequisites -WorkFolder "C:"
                $result | Should -BeNullOrEmpty
            }
        }
    }

}
