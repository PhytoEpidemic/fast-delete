# Set the required paths and icon
$scriptPath = $PSScriptRoot + "\FastDelete.ps1"
$shortcutPath = $PSScriptRoot + "\shortcut.lnk"
$iconPath = $PSScriptRoot + "\icon.ico"

# Create a new WScript Shell object
$shell = New-Object -ComObject WScript.Shell

# Create the shortcut object
$shortcut = $shell.CreateShortcut($shortcutPath)

# Set shortcut properties
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$scriptPath`" `"Install`""
$shortcut.IconLocation = $iconPath
$shortcut.WorkingDirectory = (Split-Path $scriptPath)

# Save the shortcut
$shortcut.Save()
