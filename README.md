# Format-PesterTeamcity

This module is to help me learn more about powershell, and all of us get get our pester tests into TeamCity.

## Use case

You can use `invoke-pester -OutputFile ./tests.xml -OutputFormat NUnitXml` to output an NUnit compatible xml file which Teamcity can read, but what if you are not able to fetch the file due to it being on a different machine such as during a packer build?

If all you have is console output, you can use this script to output the test results in a format Teamcity can use.

## How to use

You will need `-passthru` to generate the test output object.
You can then pipe that through to the Format-PesterTeamcity module like `Invoke-Pester -Passthru | Format-PesterTeamcity`

## More information

[Teamcity test message format.](https://confluence.jetbrains.com/display/TCD18/Build+Script+Interaction+with+TeamCity)