# FastDelete.ps1
# Required files:
# icon.ico
# mkshortcut.ps1
# runInstall.bat

$AppDataFolder = [Environment]::GetFolderPath('ApplicationData')
$FastDeleteFolder = Join-Path -Path $AppDataFolder -ChildPath "FastDelete"
$ToDeleteFolder = Join-Path -Path $FastDeleteFolder -ChildPath "ToDelete"

Function Add-FastDeleteContextMenu {
	
	
	New-Item -Path ($FastDeleteFolder) -ItemType Directory -Force | Out-Null
	New-Item -Path ($ToDeleteFolder) -ItemType Directory -Force | Out-Null
	copy "icon.ico" "$FastDeleteFolder\icon.ico"
	copy "FastDelete.ps1" "$FastDeleteFolder\FastDelete.ps1"
	$scriptPath = (Join-Path -Path $FastDeleteFolder -ChildPath "FastDelete.ps1")
	$IconPath = (Join-Path -Path $FastDeleteFolder -ChildPath "icon.ico")
    $baseRegPath = "Registry::HKEY_CURRENT_USER\Software\Classes"

    # Add context menu for files
    $fileRegPath = "$baseRegPath\*\shell\FastDelete"
    New-Item -Path $fileRegPath -Force | Out-Null
	New-ItemProperty -Path $fileRegPath -Name "Icon" -Value $IconPath -PropertyType String -Force | Out-Null
    Set-ItemProperty -Path $fileRegPath -Name "MUIVerb" -Value "Fast Delete"
    Set-ItemProperty -Path $fileRegPath -Name "MultiSelectModel" -Value "Document"
    $fileCmdPath = "$fileRegPath\command"
    New-Item -Path $fileCmdPath -Force | Out-Null
    Set-ItemProperty -Path $fileCmdPath -Name "(Default)" -Value "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`" `"%V`""

    # Add context menu for directories
    $dirRegPath = "$baseRegPath\Directory\shell\FastDelete"
    New-Item -Path $dirRegPath -Force | Out-Null
	New-ItemProperty -Path $dirRegPath -Name "Icon" -Value $IconPath -PropertyType String -Force | Out-Null
    Set-ItemProperty -Path $dirRegPath -Name "MUIVerb" -Value "Fast Delete"
    Set-ItemProperty -Path $dirRegPath -Name "MultiSelectModel" -Value "Document"
	
    $dirCmdPath = "$dirRegPath\command"
    New-Item -Path $dirCmdPath -Force | Out-Null
    Set-ItemProperty -Path $dirCmdPath -Name "(Default)" -Value "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`" `"%V`""
}


Function Remove-FastDeleteContextMenu {
    $baseRegPath = "Registry::HKEY_CURRENT_USER\Software\Classes"

    # Remove context menu for files
    $fileRegPath = "$baseRegPath\*\shell\FastDelete"
    Remove-Item -Path $fileRegPath -Recurse -Force -ErrorAction SilentlyContinue

    # Remove context menu for directories
    $dirRegPath = "$baseRegPath\Directory\shell\FastDelete"
    Remove-Item -Path $dirRegPath -Recurse -Force -ErrorAction SilentlyContinue
    
	
	$AppDataFolder = [Environment]::GetFolderPath('ApplicationData')
	$FastDeleteFolder = Join-Path -Path $AppDataFolder -ChildPath "FastDelete"
	Remove-Item -Path $FastDeleteFolder -Recurse -Force -ErrorAction SilentlyContinue
}


Function Show-CustomMessageBox {
    param (
        [string]$Message,
        [string]$Title,
        [string]$Button1Text = "OK",
        [string]$Button2Text = "",
        [string]$Button3Text = "",
        [string]$Icon = "icon.ico"
    )

    Add-Type -AssemblyName PresentationFramework

    $Window = New-Object System.Windows.Window
    $Window.Title = $Title
    $Window.Icon = $Icon
    $Window.SizeToContent = "WidthAndHeight"
    $Window.WindowStartupLocation = "CenterScreen"
    $Window.ResizeMode = "NoResize"
    $Window.Topmost = $true

    $StackPanel = New-Object System.Windows.Controls.StackPanel
    $StackPanel.Orientation = "Vertical"

    $TextBlock = New-Object System.Windows.Controls.TextBlock
    $TextBlock.Text = $Message
    $TextBlock.Margin = "10"
    $TextBlock.TextWrapping = "Wrap"
    $StackPanel.Children.Add($TextBlock)

    $ButtonPanel = New-Object System.Windows.Controls.StackPanel
    $ButtonPanel.Orientation = "Horizontal"
    $ButtonPanel.HorizontalAlignment = "Center"
    $ButtonPanel.Margin = "10"

    $Button1 = New-Object System.Windows.Controls.Button
    $Button1.Content = $Button1Text
    $Button1.Width = 75
    $Button1.Margin = "5"
    $Button1.Add_Click({
        $Window.Tag = $Button1Text
        $Window.Close()
    })
    $ButtonPanel.Children.Add($Button1)
	if ($Button2Text -ne "") {
		$Button2 = New-Object System.Windows.Controls.Button
		$Button2.Content = $Button2Text
		$Button2.Width = 75
		$Button2.Margin = "5"
		$Button2.Add_Click({
			$Window.Tag = $Button2Text
			$Window.Close()
		})
		$ButtonPanel.Children.Add($Button2)
	}
	if ($Button3Text -ne "") {
		$Button3 = New-Object System.Windows.Controls.Button
		$Button3.Content = $Button3Text
		$Button3.Width = 75
		$Button3.Margin = "5"
		$Button3.Add_Click({
			$Window.Tag = $Button3Text
			$Window.Close()
		})
		$ButtonPanel.Children.Add($Button3)
	}
	
	
	
    $StackPanel.Children.Add($ButtonPanel)

    $Window.Content = $StackPanel
    $Window.ShowDialog() | Out-Null

    return $Window.Tag
}

$InstallCommand = $args[0] -eq "Install"

if ($InstallCommand) {

    Add-Type -AssemblyName PresentationFramework

    $baseRegPath = "Registry::HKEY_CURRENT_USER\Software\Classes"

    $fileRegPath = "$baseRegPath\*\shell\FastDelete"
    $dirRegPath = "$baseRegPath\Directory\shell\FastDelete"

    $contextMenuExists = (Test-Path $fileRegPath) -or (Test-Path $dirRegPath)

    if ($contextMenuExists) {
        $message = "Fast Delete is already installed. Would you like to remove it?"
        $caption = "Fast Delete Installer"
        $result = Show-CustomMessageBox -Message $message -Title $caption -Button1Text "Remove" -Button2Text "Repair" -Button3Text "Cancel"

        if ($result -eq "Remove") {
            Remove-FastDeleteContextMenu
            Show-CustomMessageBox -Message "Fast Delete has been removed from your system." -Title "Fast Delete" -Button1Text "OK"
        } elseif ($result -eq "Repair") {
			Remove-FastDeleteContextMenu
			Add-FastDeleteContextMenu
			Show-CustomMessageBox -Message "Fast Delete has been repaired." -Title "Fast Delete" -Button1Text "OK"
		}
    } else {
        $message = "Would you like to install Fast Delete and add it to the context menu?"
        $caption = "Fast Delete Installer"
        $result = Show-CustomMessageBox -Message $message -Title $caption -Button1Text "Install" -Button2Text "Cancel"

        if ($result -eq "Install") {
            Add-FastDeleteContextMenu
            Show-CustomMessageBox -Message "Fast Delete has been installed." -Title "Fast Delete" -Button1Text "OK"
        }
    }
	
    Exit
}


$mutexName = "Global\FastDeleteMutex"

Add-Type -AssemblyName System.Threading

$mutex = New-Object System.Threading.Mutex($false, $mutexName)

try {
	$acquired = $mutex.WaitOne(20000)

    if ($acquired) {
        $runningFilePath = Join-Path -Path $ToDeleteFolder -ChildPath "Running.txt"
        if (Test-Path -Path $runningFilePath) {
            $uniqueFileName = [Guid]::NewGuid().ToString() + ".txt"
            $filePath = Join-Path -Path $ToDeleteFolder -ChildPath $uniqueFileName
            $args[0] | Out-File -FilePath $filePath -Encoding UTF8
			$mutex.ReleaseMutex()
			Exit
        } else {
			Add-Type -AssemblyName PresentationFramework

            $args[0] | Out-File -FilePath $runningFilePath -Encoding UTF8

            $mutex.ReleaseMutex()

            $initialFileCount = (Get-ChildItem -Path $ToDeleteFolder -File).Count

            while ($true) {
                Start-Sleep -Milliseconds 500
                $currentFileCount = (Get-ChildItem -Path $ToDeleteFolder -File).Count
                if ($currentFileCount -eq $initialFileCount) {
                    # No new files have been added in the last 500 milliseconds
                    break
                }
                $initialFileCount = $currentFileCount
            }

			$process = [System.Diagnostics.Process]::GetCurrentProcess()
			$process.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::Idle

			$thread = [System.Threading.Thread]::CurrentThread
			$thread.Priority = [System.Threading.ThreadPriority]::Lowest
			$acquired = $mutex.WaitOne(20000)

            if ($acquired) {
                $Items = @()
                foreach ($file in Get-ChildItem -Path $ToDeleteFolder -File) {
                    $content = Get-Content -Path $file.FullName
                    $Items += $content
					Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
                }

                $FileCount = $Items.Count
				$ItemsList = "$FileCount" + " items`n`n"
				$ItemsList = $ItemsList + ($Items -join "`n")
				$message = "Are you sure you want to permanently delete the following items:`n`n$ItemsList"
                $caption = "Fast Delete Confirmation"
                $Confirmation = Show-CustomMessageBox -Message $message -Title $caption -Button1Text "Yes" -Button2Text "No" -Icon (Join-Path -Path $FastDeleteFolder -ChildPath "icon.ico")

                if ($Confirmation -eq "Yes") {
                    foreach ($Item in $Items) {
                        $Item = $Item.Trim('"')  # Remove surrounding quotes
                        if (Test-Path -LiteralPath $Item) {
                            $ItemPath = '"' + $Item + '"'
                            if (Test-Path -LiteralPath $Item -PathType Container) {
                                # It's a directory
                                Start-Process -FilePath 'cmd.exe' -ArgumentList "/c rd /s /q $ItemPath" -WindowStyle Hidden -Wait
                            } else {
                                # It's a file
                                Start-Process -FilePath 'cmd.exe' -ArgumentList "/c del /f /s /q $ItemPath" -WindowStyle Hidden
                            }
                        }
                    }
                }
				
            }
        }
    }
} finally {
	if ($mutex.WaitOne(0)) {
        $mutex.ReleaseMutex()
    }
	
    $mutex.Dispose()
}








