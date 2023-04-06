# Download the tools from here (search for "1. Click this download link."): https://www.nirsoft.net/password_recovery_tools.html

$Path = "$($env:USERPROFILE)\Downloads" # Paste Path to the downloaded tools here. Both tools should be in the same folder.

$Content = Get-Content -Path "$($Path)\WebBrowserPassView.exe" -Encoding Byte
$Base64 = [System.Convert]::ToBase64String($Content)
$Base64 | Clip # Will copy the Byte64 string into your clipboard so you can paste it into the other script inside the variable Base64WebBrowserPassView

Pause

$Content = Get-Content -Path "$($Path)\PasswordFox.exe" -Encoding Byte
$Base64 = [System.Convert]::ToBase64String($Content)
$Base64 | Clip # Will copy the Byte64 string into your clipboard so you can paste it into the other script inside the variable ContentPasswordFox
