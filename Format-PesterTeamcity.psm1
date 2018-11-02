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

    function Write-PassedTest ($testResult) {
        Write-Output "##teamcity[testStarted name='$($testResult.Context).$($testResult.Name)']"
        Write-Output "##teamcity[testFinished name='$($testResult.Context).$($testResult.Name)' duration='$($testResult.Time)']" 
    }

    function Write-FailedTest ($testResult) {
        Write-Output "##teamcity[testStarted name='$($testResult.Context).$($testResult.Name)']"
        Write-Output "##teamcity[testFailed name='$($testResult.Context).$($testResult.Name)' Message='$($testResult.FailureMessage)' stacktrace='$($testResult.StackTrace)']"
        Write-Output "##teamcity[testFinished name='$($testResult.Context).$($testResult.Name)' duration='$($testResult.Time)']"
    }

    function Get-TestSuiteNames ($testResults) {
        return @($testResults.Context | Select-Object -Unique)
    }
    
    If (-not $TestResult) {
        Throw "No test results found."
    }

    $testSuiteNames = Get-TestSuiteNames -testResults $TestResult
    $testFailedCount = @($TestResult | Where-Object {$_.result -eq "Failed"}).Count
    
    Write-Verbose "Failed test count: $testFailedCount"

    foreach ($suiteName in $testSuiteNames) {
        Write-Output "##teamcity[testSuiteStarted name='$($suitename)']"

        $testsInSuite = @($TestResult | Where-Object {$_.Context -eq $suiteName})

        foreach ($test in $testsInSuite) {
            Write-Verbose $test

            if ($test.result -eq "Passed") {
                Write-PassedTest $test
            }
            else {
                Write-FailedTest $test
            }
        }

        Write-Output "##teamcity[testSuiteFinished name='$($suitename)']"
    }

    if ($EnableExit) {
        exit $testFailedCount
    }    
}
