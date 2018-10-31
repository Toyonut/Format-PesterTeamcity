Describe "The computer should be running Linux." {
    Context "We like Linux." {
        It "Should be running Linux." {
            $IsLinux | Should Be $true
        }

        It "Should not be running MacOs." {
            $IsMacOS | Should Be $false
        }

        It "Should not be running Windows." {
            $IsWindows | Should Be $false
        }
    }
}

Describe "Some failing tests" {
    Context "We want to test some failures." {
        It "Should prove true really is true" {
            $true | Should Be $false
        }

        It "Should show time is linear" {
            (Get-Date).AddSeconds(60) -lt (Get-Date) | Should Be $true
        }
    }
}