#Requires -Version 5

<#
.SYNOPSIS
    BrowserCredentialReport

.DESCRIPTION
    Creates a list of all credentials saved in Internet Explorer, Edge, Chrome or Firefox using tools from Nir Sofer.

.LINK
    GitHub: https://github.com/MichaelSchoenburg/BrowserCredentialReport

.NOTES
    Author: Michael Schönburg

    The script is intended solely for legal use.
    Script runs fully automatic. No input needed. Output comes in form of text (csv) since it is meant to be used in remote monitoring and management solutions.

    This projects code loosely follows the PowerShell Practice and Style guide, as well as Microsofts PowerShell scripting performance considerations.
    Style guide: https://poshcode.gitbook.io/powershell-practice-and-style/
    Performance Considerations: https://docs.microsoft.com/en-us/powershell/scripting/dev-cross-plat/performance/script-authoring-considerations?view=powershell-7.1
#>

#region INITIALIZATION
<# 
    Libraries, Modules, ...
#>

#endregion INITIALIZATION
#region DECLARATIONS
<#
    Declare local variables and global variables
#>

$ErrorActionPreference = 'Stop' # Stop the script as soon as any error is thrown
$ToolPath = "C:\TSD.CenterVision\Software\Passworttools"
$UserFolders = Get-ChildItem -Path C:\Users
$Header = "Record Index", "URL", "User Name", "Password", "User Name Field", "Password Field", "Signons File", "HTTP Realm", "Password Strength", "Firefox Version", "Created Time", "Last Time Used", "Password Change Time", "Pasword Use Count"

#endregion DECLARATIONS
#region FUNCTIONS
<# 
    Declare Functions
#>

function Write-ConsoleLog {
    <#
    .SYNOPSIS
    Logs an event to the console.
    
    .DESCRIPTION
    Writes text to the console with the current date (US format) in front of it.
    
    .PARAMETER Text
    Event/text to be outputted to the console.
    
    .EXAMPLE
    Write-ConsoleLog -Text 'Subscript XYZ called.'
    
    Long form
    .EXAMPLE
    Log 'Subscript XYZ called.
    
    Short form
    #>
    [alias('Log')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
        Position = 0)]
        [string]
        $Text
    )

    # Save current VerbosePreference
    $VerbosePreferenceBefore = $VerbosePreference

    # Enable verbose output
    $VerbosePreference = 'Continue'

    # Write verbose output
    Write-Verbose "$(Get-Date -Format 'MM/dd/yyyy HH:mm:ss') - $($Text)"

    # Restore current VerbosePreference
    $VerbosePreference = $VerbosePreferenceBefore
}

# I've put the big Base64 strings each into a function so they can be collapsed in Visual Studio Code and don't disturb.

function Set-WebBrowserPassViewExe {
    $Base64WebBrowserPassView = # Paste Base64 string from the other script here
    $ContentWebBrowserPassView = [System.Convert]::FromBase64String($Base64WebBrowserPassView)
    Set-Content -Path "$($ToolPath)\WebBrowserPassView.exe" -Value $ContentWebBrowserPassView -Encoding Byte
}

function Set-PasswordFoxExe {
    $Base64PasswordFox = # Paste Base64 string from the other script here
    $ContentPasswordFox = [System.Convert]::FromBase64String($Base64PasswordFox)
    Set-Content -Path "$($ToolPath)\PasswordFox.exe" -Value $ContentPasswordFox -Encoding Byte
}

#endregion FUNCTIONS
#region EXECUTION
<# 
    Script entry point
#>

Log "Checking if path already exists..."
if (-not (Test-Path -Path $ToolPath)) {
    Log "Creating path..."
    New-Item -ItemType Directory -Force -Path $ToolPath
    Log "Making sure that the path exists now..."
    if (-not (Test-Path -Path $ToolPath)) {
        Exit 1
    }
}

<# 
    Extraction of Nir Soft tools
#>    

Log "Writing Nir Soft tools..."
Set-WebBrowserPassViewExe
Set-PasswordFoxExe

<# 
    Export credentials from browsers
#>

Log "Exporting credentials from browsers..."
foreach ($u in $UserFolders) {
    # Chrome
    if (Test-Path -Path $ChromePath) {
        $ChromePath = "C:\Users\$($u.Name)\AppData\Local\Google\Chrome\User Data\Default"
        Log "Processing Chrome for $($u.Name) at $ChromePath"
        & "$($ToolPath)\WebBrowserPassView.exe" /LoadPasswordsIE 0 /LoadPasswordsChrome 1 /UseChromeProfileFolder 1 /ChromeProfileFolder $ChromePath /LoadPasswordsFirefox 0 /scomma "C:\TSD.CenterVision\Software\Passworttools\$u-chrome.csv"
    } else {
        Log "No Chrome profile found for $($u.Name) at $ChromePath"
    }

    # Internet Explorer & MS Edge
    $EdgePath = "C:\Users\$($u.Name)\AppData\Local\Microsoft\Edge\User Data\Default"
    if (Test-Path -Path $EdgePath) {
        Log "Processing Edge for $($u.Name) at $EdgePath"
        & "$($ToolPath)\WebBrowserPassView.exe" /LoadPasswordsIE 0 /LoadPasswordsChrome 1 /UseChromeProfileFolder 1 /ChromeProfileFolder $EdgePath /LoadPasswordsFirefox 0 /scomma "C:\TSD.CenterVision\Software\Passworttools\$u-edge.csv"
    } else {
        Log "No Edge profile found for $($u.Name) at $EdgePath"
    }

    # Firefox
    if (Test-Path -Path $FirefoxPath) {
        $FirefoxPath = "C:\Users\$($u.Name)\AppData\Roaming\Mozilla\Firefox\Profiles"
        $FirefoxExactPath = (Get-ChildItem -Path $FirefoxPath).Where({$_ -like "*default-release"}).FullName
        Log "Processing Firefox for $($u.Name) at $FirefoxExactPath"
        & "$($ToolPath)\PasswordFox.exe" /Profile $FirefoxExactPath /scomma "C:\TSD.CenterVision\Software\Passworttools\$u-firefox.csv"
    } else {
        Log "No Firefox profile found for $($u.Name) at $FirefoxExactPath"
    }
}

<# 
    Read/import the exported data
#>

Log "Importing the exported data..."
$Files = Get-ChildItem -Path $ToolPath -Filter *.csv
$CSV = @()

# Chrome
$Properties = "URL", @{N="Web Browser"; E={"Chrome"}}, "User Name", "Password", @{N="Windows-Benutzer"; E={$csvfile.Name.Split('-')[0]}}
foreach ($csvfile in $Files.Where({$_.Name -like "*chrome*"})) {
    $content = Import-Csv -Path $csvfile.FullName -Delimiter ','
    $csv += $content | Select-Object $Properties
}

# Firefox
$Properties = "URL", @{N="Web Browser"; E={"Firefox"}}, "User Name", "Password", @{N="Windows-Benutzer"; E={$csvfile.Name.Split('-')[0]}}
foreach ($csvfile in $Files.Where({$_.Name -like "*firefox*"})) {
    $content = Import-Csv -Path $csvfile.FullName -Delimiter ',' -Header $Header
    $csv += $content | Select-Object $Properties
}

# Edge
$Properties = "URL", @{N="Web Browser"; E={"Edge"}}, "User Name", "Password", @{N="Windows-Benutzer"; E={$csvfile.Name.Split('-')[0]}}
foreach ($csvfile in $Files.Where({$_.Name -like "*edge*"})) {
    $content = Import-Csv -Path $csvfile.FullName -Delimiter ','
    $csv += $content | Select-Object $Properties
}

<# 
    Prepare final output
#>

Log "Final output:"
$Properties = @{N="Gerätename"; E={$env:COMPUTERNAME}}, "Windows-Benutzer", @{N="Internet Browser"; E={$_.'Web Browser'}}, @{N="Domain"; E={
    $s = $_.URL
    
    if ($s -like '*//*') {
        $s = $s.split('//')[2]
    }

    if ($s -like '*.*') {
        $s = $s.split('.')
        $s = $s[($s.Count-2)..($s.Count-1)] -join '.'
    }

    $s
}}, @{N="URL"; E={$_.'URL'}}, @{N="Benutzername"; E={$_.'User Name'}}, @{N="Passwort"; E={$_.'Password'}}
$CSV | Select-Object -Property $Properties -Unique | Sort-Object -Property Domain, Benutzername | ConvertTo-CSV -NoTypeInformation -Delimiter ';' | ForEach-Object {$_ -replace '"',''}

<# 
    Clean up the tools and data
#>

Log "Cleaning up..."
Start-Sleep -Seconds 3
Get-ChildItem -Path $ToolPath | Remove-Item -Force -Confirm:$false

#endregion EXECUTION
