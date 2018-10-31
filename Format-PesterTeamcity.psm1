function Format-PesterTeamcity {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        $TestResult
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

    foreach ($suiteName in $testSuiteNames) {
        Write-Output "##teamcity[testSuiteStarted name='$($suitename)']"

        $testsInSuite = @($TestResult | Where-Object {$_.Context -eq $suiteName})

        foreach ($test in $testsInSuite) {
            if ($test.result -eq "Passed") {
                Write-PassedTest $test
            } else {
                Write-FailedTest $test
            }
        }

        Write-Output "##teamcity[testSuiteFinished name='$($suitename)']"
    }
}