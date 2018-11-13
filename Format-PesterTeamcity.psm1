<#
.SYNOPSIS
    Format Pester test output into something Teamcity can understand from the build logs.
.EXAMPLE
    Invoke-Pester -passthru | Format-PesterTeamcity
.EXAMPLE
    $testResult = Invoke-Pester -passthru | Format-PesterTeamcity

.INPUTS
    Teamcity test object
.OUTPUTS
    Formatted test output in Teamcity format
#>
function Format-PesterTeamcity {
    [CmdletBinding()]
    param (
        # TestResult object output from Pester.
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        $TestResult,
        # Output an exit code based on the number of failed tests.
        [switch]$EnableExit
    )

    begin {}

    process {
        function Get-TestSuiteNames ($testResults) {
            return @($testResults.Describe | Select-Object -Unique)
        }

        function Format-TCMessage ($message) {
            return $message -replace [Regex]::Escape("|"), "||" `
                            -replace [Regex]::Escape("'"), "|'" `
                            -replace [Regex]::Escape("["), "|[" `
                            -replace [Regex]::Escape("]"), "|]" `
                            -replace [Regex]::Escape("`r`n"), "|n" `
                            -replace [Regex]::Escape("`n"), "|n" `
                            -replace [Regex]::Escape("`r"), "|r" `
                            -replace [Regex]::Escape("[char]u0085"), "|x" `
                            -replace [Regex]::Escape("[char]u2029"), "|p" `
                            -replace [Regex]::Escape("[char]u2028"), "|l"
        }

        If (-not $TestResult) {
            Throw "No test results found."
        }

        $testSuiteNames = Get-TestSuiteNames -testResults $TestResult
        $failedTestCount = @($TestResult | Where-Object {$_.result -eq "Failed"}).Count

        Write-Verbose "Failed test count: $failedTestCount"

        foreach ($suiteName in $testSuiteNames) {
            $suiteName = Format-TCMessage -message $suiteName

            Write-Output "##teamcity[testSuiteStarted name='$($suitename)']"

            $testsInSuite = @($TestResult | Where-Object {$_.Describe -eq $suiteName})

            foreach ($test in $testsInSuite) {
                Write-Verbose $test
                $testName = Format-TCMessage -message "$($test.Describe).$($test.Name)"

                if ($test.result -eq "Passed") {
                    Write-Output "##teamcity[testStarted name='$($testName)']"
                    Write-Output "##teamcity[testFinished name='$($testName)' duration='$($test.Time)']"
                }
                else {
                    $failureMessage = Format-TCMessage -message $($test.FailureMessage)
                    $stackTraceMessage = Format-TCMessage -message $($test.StackTrace)

                    Write-Output "##teamcity[testStarted name='$($testName)']"
                    Write-Output "##teamcity[testFailed name='$($testName)' Message='$($failureMessage)' stacktrace='$($stackTraceMessage)']"
                    Write-Output "##teamcity[testFinished name='$($testName)' duration='$($test.Time)']"
                }
            }

            Write-Output "##teamcity[testSuiteFinished name='$($suitename)']"
        }
    }

    end {
        if ($EnableExit) {
            exit $failedTestCount
        }
    }
}
