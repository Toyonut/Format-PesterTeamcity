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
                            -replace [Regex]::Escape("`r`n"), "|n"
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
                    Write-Output "##teamcity[testStarted name='$($testname)']"
                    Write-Output "##teamcity[testFinished name='$($testname)' duration='$($test.Time)']"
                }
                else {
                    $failureMessage = Format-TCMessage -message $($test.FailureMessage)
                    $stackTraceMessage = Format-TCMessage -message $($test.StackTrace)

                    Write-Output "##teamcity[testStarted name='$($testname)']"
                    Write-Output "##teamcity[testFailed name='$($testname)' Message='$($failureMessage)' stacktrace='$($stackTraceMessage)']"
                    Write-Output "##teamcity[testFinished name='$($testname)' duration='$($test.Time)']"
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
