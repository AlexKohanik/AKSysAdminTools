# Check if script is running as administrator, if not, relaunch as administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Windows.Forms.DataVisualization

# Function to display command results in a scrollable view
function ShowResults($resultText) {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Results"
    $form.Size = New-Object System.Drawing.Size(800, 600)
    $form.StartPosition = "CenterScreen"

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Size = New-Object System.Drawing.Size(780, 500)
    $textBox.Multiline = $true
    $textBox.ScrollBars = 'Vertical'
    $textBox.Text = $resultText
    $form.Controls.Add($textBox)

    $form.ShowDialog()
}

# Function to parse and format command output
function ParseCommandOutput($commandResult) {
    $parsedInfo = $commandResult -split "\n" | ForEach-Object {
        if ($_ -match '^([^:]+):\s*(.*)$') {
            "INFO: $($Matches[1].Trim()) - $($Matches[2].Trim())"
        } else {
            $_
        }
    }
    return $parsedInfo -join "`r`n"
}

# Function to execute IPCONFIG command and display parsed information
function ShowIPConfig {
    $progressBar.Style = 'Marquee'
    $ipconfigResult = ipconfig /all
    $formattedInfo = ParseCommandOutput $ipconfigResult
    $progressBar.Style = 'Blocks'
    ShowResults $formattedInfo
}

# Function to execute SYSTEMINFO command and display parsed information
function ShowSystemInfo {
    $progressBar.Style = 'Marquee'
    $systemInfoResult = systeminfo
    $formattedInfo = ParseCommandOutput $systemInfoResult
    $progressBar.Style = 'Blocks'
    ShowResults $formattedInfo
}

# Function to run CHKDSK in a separate cmd window
function RunCHKDSK {
    Start-Process "cmd.exe" "/c chkdsk"
}

# Function to Generate Battery report
function GenerateBatteryReport {
    $reportPath = "$env:USERPROFILE\battery-report.html"
    Start-Process "cmd.exe" "/c powercfg /batteryreport"
    Start-Sleep -Seconds 2  # Give it some time to generate the report
    if (Test-Path $reportPath) {
        Start-Process $reportPath
    } else {
        [System.Windows.Forms.MessageBox]::Show("Battery Report generation failed.", "Error", "OK", [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}


# Function to run DISM Check Health in a separate cmd window
function RunDISMCheckHealth {
    Start-Process "cmd.exe" "/c DISM /online /cleanup-image /checkhealth"
}

# Function to run DISM Scan Health in a separate cmd window
function RunDISMScanHealth {
    Start-Process "cmd.exe" "/c DISM /online /cleanup-image /scanhealth"
}

# Function to run DISM Restore Health in a separate cmd window
function RunDISMRestoreHealth {
    Start-Process "cmd.exe" "/c DISM /online /cleanup-image /restorehealth"
}

# Function to run RegisterDNS (ipconfig /registerdns) and display parsed information
function RunRegisterDNS {
    $progressBar.Style = 'Marquee'
    $registerDNSResult = ipconfig /registerdns
    $formattedInfo = ParseCommandOutput $registerDNSResult
    $progressBar.Style = 'Blocks'
    ShowResults $formattedInfo
}

# Function to restart a specified Windows service
function RestartService {
    $serviceName = Read-Host "Enter the service name to restart"
    if ($serviceName -ne $null -and $serviceName -ne "") {
        Restart-Service $serviceName -Force
    }
}

# Function to restart the Printer Spooler service
function RestartPrinterSpooler {
    $progressBar.Style = 'Marquee'
    Restart-Service -Name "Spooler" -Force
    $progressBar.Style = 'Blocks'
    ShowResults "Printer Spooler service restarted."
}

# Function to kill a task in Task Manager
function KillTask {
    $taskName = Read-Host "Enter the task name to be ended in Task Manager"
    if ($taskName -ne $null -and $taskName -ne "") {
        Stop-Process -Name $taskName -Force
    }
}

# Function to release and renew IPConfig
# Function to release and renew IPConfig
function ReleaseRenewIPConfig {
    $releaseProcess = Start-Process "cmd.exe" "/c ipconfig /release" -PassThru -WindowStyle Hidden -RedirectStandardOutput "C:\Temp\ReleaseOutput.txt" -RedirectStandardError "C:\Temp\ReleaseError.txt" -Wait
    $releaseExitCode = $releaseProcess.ExitCode

    if ($releaseExitCode -eq 0) {
        $renewProcess = Start-Process "cmd.exe" "/c ipconfig /renew" -PassThru -WindowStyle Hidden -RedirectStandardOutput "C:\Temp\RenewOutput.txt" -RedirectStandardError "C:\Temp\RenewError.txt" -Wait
        $renewExitCode = $renewProcess.ExitCode

        if ($renewExitCode -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("IPConfig Renewal Successful.", "Success", "OK", [System.Windows.Forms.MessageBoxIcon]::Information)
        } else {
            $renewError = "Renew Error:`n"
            $renewError += $renewProcess.StandardError.ReadToEnd()
            [System.Windows.Forms.MessageBox]::Show("IPConfig Renewal Failed.`n`n$renewError", "Failure", "OK", [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    } else {
        $releaseError = "Release Error:`n"
        $releaseError += $releaseProcess.StandardError.ReadToEnd()
        [System.Windows.Forms.MessageBox]::Show("IPConfig Release Failed.`n`n$releaseError", "Failure", "OK", [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}


# GUI Creation
$form = New-Object System.Windows.Forms.Form
$form.Text = "AKohanik SysAdmin Tool v6.8"
$form.Size = New-Object System.Drawing.Size(1200, 600) # Adjusted size
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(173, 216, 230)  # Set background color to blue

# Title Label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "AKohanik SysAdmin Tools v6.8"
$titleLabel.AutoSize = $true
$titleLabel.Font = New-Object System.Drawing.Font("Arial",16,[System.Drawing.FontStyle]::Bold)
$titleLabel.Location = New-Object System.Drawing.Point(400, 400) # Adjusted position
$titleLabel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle # Underline effect
$form.Controls.Add($titleLabel)

$buttonWidth = 250
$buttonHeight = 30
$padding = 10

$buttonColumn1 = 50
$buttonColumn2 = $buttonColumn1 + $buttonWidth + $padding
$buttonColumn3 = $buttonColumn2 + $buttonWidth + $padding

$buttonRow1 = 50
$buttonRow2 = $buttonRow1 + $buttonHeight + $padding
$buttonRow3 = $buttonRow2 + $buttonHeight + $padding
$buttonRow4 = $buttonRow3 + $buttonHeight + $padding
$buttonRow5 = $buttonRow4 + $buttonHeight + $padding
$buttonRow6 = $buttonRow5 + $buttonHeight + $padding
$buttonRow7 = $buttonRow6 + $buttonHeight + $padding
$buttonRow8 = $buttonRow7 + $buttonHeight + $padding  # Adjusted row for the new button

$buttonSize = New-Object System.Drawing.Size($buttonWidth, $buttonHeight)

# Troubleshoot Column
$troubleshootLabel = New-Object System.Windows.Forms.Label
$troubleshootLabel.Text = "Troubleshoot"
$troubleshootLabel.AutoSize = $true
$troubleshootLabel.Font = New-Object System.Drawing.Font("Arial",14,[System.Drawing.FontStyle]::Bold)
$troubleshootLabel.Location = New-Object System.Drawing.Point($buttonColumn1, 20)
$form.Controls.Add($troubleshootLabel)

$ipconfigButton = New-Object System.Windows.Forms.Button
$ipconfigButton.Text = "IPConfig"
$ipconfigButton.Size = $buttonSize
$ipconfigButton.Location = New-Object System.Drawing.Point($buttonColumn1, $buttonRow1)
$ipconfigButton.Add_Click({ ShowIPConfig })
$form.Controls.Add($ipconfigButton)
$ipconfigButton.BackColor = [System.Drawing.Color]::LightCoral  # Red

# New IPConfig Release/Renew Button
$ipReleaseRenewButton = New-Object System.Windows.Forms.Button
$ipReleaseRenewButton.Text = "IPConfig Release/Renew"
$ipReleaseRenewButton.Size = $buttonSize
$ipReleaseRenewButton.Location = New-Object System.Drawing.Point($buttonColumn1, $buttonRow6)
$ipReleaseRenewButton.Add_Click({ ReleaseRenewIPConfig })
$form.Controls.Add($ipReleaseRenewButton)
$ipReleaseRenewButton.BackColor = [System.Drawing.Color]::LightCoral  # Red

$systemInfoButton = New-Object System.Windows.Forms.Button
$systemInfoButton.Text = "SystemInfo"
$systemInfoButton.Size = $buttonSize
$systemInfoButton.Location = New-Object System.Drawing.Point($buttonColumn1, $buttonRow2)
$systemInfoButton.Add_Click({ ShowSystemInfo })
$form.Controls.Add($systemInfoButton)
$systemInfoButton.BackColor = [System.Drawing.Color]::LightCoral  # Red

$batteryReportButton = New-Object System.Windows.Forms.Button
$batteryReportButton.Text = "BatteryReport"
$batteryReportButton.Size = $buttonSize
$batteryReportButton.Location = New-Object System.Drawing.Point($buttonColumn1, $buttonRow3)
$batteryReportButton.Add_Click({ GenerateBatteryReport })
$form.Controls.Add($batteryReportButton)
$batteryReportButton.BackColor = [System.Drawing.Color]::LightCoral  # Red

$chkdskButton = New-Object System.Windows.Forms.Button
$chkdskButton.Text = "CHKDSK"
$chkdskButton.Size = $buttonSize
$chkdskButton.Location = New-Object System.Drawing.Point($buttonColumn1, $buttonRow4)
$chkdskButton.Add_Click({ RunCHKDSK })
$form.Controls.Add($chkdskButton)
$chkdskButton.BackColor = [System.Drawing.Color]::LightCoral  # Red

$registerDNSButton = New-Object System.Windows.Forms.Button
$registerDNSButton.Text = "RegisterDNS"
$registerDNSButton.Size = $buttonSize
$registerDNSButton.Location = New-Object System.Drawing.Point($buttonColumn1, $buttonRow5)
$registerDNSButton.Add_Click({ RunRegisterDNS })
$form.Controls.Add($registerDNSButton)
$registerDNSButton.BackColor = [System.Drawing.Color]::LightCoral  # Red

# DISM Column
$dismLabel = New-Object System.Windows.Forms.Label
$dismLabel.Text = "DISM"
$dismLabel.AutoSize = $true
$dismLabel.Font = New-Object System.Drawing.Font("Arial",14,[System.Drawing.FontStyle]::Bold)
$dismLabel.Location = New-Object System.Drawing.Point($buttonColumn2, 20)
$form.Controls.Add($dismLabel)

$checkHealthButton = New-Object System.Windows.Forms.Button
$checkHealthButton.Text = "DISM Check Health"
$checkHealthButton.Size = $buttonSize
$checkHealthButton.Location = New-Object System.Drawing.Point($buttonColumn2, $buttonRow1)
$checkHealthButton.Add_Click({ RunDISMCheckHealth })
$form.Controls.Add($checkHealthButton)
$checkHealthButton.BackColor = [System.Drawing.Color]::LightGreen  # Green

$scanHealthButton = New-Object System.Windows.Forms.Button
$scanHealthButton.Text = "DISM Scan Health"
$scanHealthButton.Size = $buttonSize
$scanHealthButton.Location = New-Object System.Drawing.Point($buttonColumn2, $buttonRow2)
$scanHealthButton.Add_Click({ RunDISMScanHealth })
$form.Controls.Add($scanHealthButton)
$scanHealthButton.BackColor = [System.Drawing.Color]::LightGreen  # Green

$restoreHealthButton = New-Object System.Windows.Forms.Button
$restoreHealthButton.Text = "DISM Restore Health"
$restoreHealthButton.Size = $buttonSize
$restoreHealthButton.Location = New-Object System.Drawing.Point($buttonColumn2, $buttonRow3)
$restoreHealthButton.Add_Click({ RunDISMRestoreHealth })
$form.Controls.Add($restoreHealthButton)
$restoreHealthButton.BackColor = [System.Drawing.Color]::LightGreen  # Green

# Tasks/Service Column
$tasksLabel = New-Object System.Windows.Forms.Label
$tasksLabel.Text = "Tasks/Service"
$tasksLabel.AutoSize = $true
$tasksLabel.Font = New-Object System.Drawing.Font("Arial",14,[System.Drawing.FontStyle]::Bold)
$tasksLabel.Location = New-Object System.Drawing.Point($buttonColumn3, 20)
$form.Controls.Add($tasksLabel)

$killTaskButton = New-Object System.Windows.Forms.Button
$killTaskButton.Text = "Kill Task"
$killTaskButton.Size = $buttonSize
$killTaskButton.Location = New-Object System.Drawing.Point($buttonColumn3, $buttonRow1)
$killTaskButton.Add_Click({ KillTask })
$form.Controls.Add($killTaskButton)
$killTaskButton.BackColor = [System.Drawing.Color]::Yellow  # Yellow

$restartServiceButton = New-Object System.Windows.Forms.Button  # New Restart Service button
$restartServiceButton.Text = "Restart Service"
$restartServiceButton.Size = $buttonSize
$restartServiceButton.Location = New-Object System.Drawing.Point($buttonColumn3, $buttonRow2)
$restartServiceButton.Add_Click({ RestartService })
$form.Controls.Add($restartServiceButton)
$restartServiceButton.BackColor = [System.Drawing.Color]::Yellow  # Yellow

$printerFixButton = New-Object System.Windows.Forms.Button  # New PrinterFix button
$printerFixButton.Text = "PrinterFix"
$printerFixButton.Size = $buttonSize
$printerFixButton.Location = New-Object System.Drawing.Point($buttonColumn3, $buttonRow3)
$printerFixButton.Add_Click({ RestartPrinterSpooler })
$form.Controls.Add($printerFixButton)
$printerFixButton.BackColor = [System.Drawing.Color]::Yellow  # Yellow

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Style = 'Blocks'
$progressBar.Size = New-Object System.Drawing.Size(1000, 20) # Adjusted size
$progressBar.Location = New-Object System.Drawing.Point($buttonColumn1, $buttonRow8) # Adjusted row
$form.Controls.Add($progressBar)

# Function to create and run user commands
function RunUserCommand {
    param(
        [string]$command
    )
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo.FileName = "cmd.exe"
    $process.StartInfo.Arguments = "/c $command"
    $process.StartInfo.RedirectStandardOutput = $true
    $process.StartInfo.RedirectStandardError = $true
    $process.StartInfo.UseShellExecute = $false
    $process.StartInfo.CreateNoWindow = $true

    $process.Start() | Out-Null
    $output = $process.StandardOutput.ReadToEnd()
    $failed = $process.StandardError.ReadToEnd()
    $process.WaitForExit()

    if ($process.ExitCode -eq 0) {
        return $output
    } else {
        return $failed
    }
}

# Textbox for user input
$inputTextBox = New-Object System.Windows.Forms.TextBox
$inputTextBox.Size = New-Object System.Drawing.Size(1000, 3000)
$inputTextBox.Location = New-Object System.Drawing.Point(45, 450)
$inputTextBox.BackColor = [System.Drawing.Color]::Black
$inputTextBox.ForeColor = [System.Drawing.Color]::Green
$inputTextBox.Font = New-Object System.Drawing.Font("Arial", 10)
$form.Controls.Add($inputTextBox)

# Output textbox for command execution results
$outputTextBox = New-Object System.Windows.Forms.TextBox
$outputTextBox.Size = New-Object System.Drawing.Size(1000, 200)
$outputTextBox.Location = New-Object System.Drawing.Point(50, 570)
$outputTextBox.BackColor = [System.Drawing.Color]::Black
$outputTextBox.ForeColor = [System.Drawing.Color]::Green
$outputTextBox.Font = New-Object System.Drawing.Font("Arial", 10)
$outputTextBox.Multiline = $true
$outputTextBox.ScrollBars = 'Vertical'
$outputTextBox.ReadOnly = $true
$form.Controls.Add($outputTextBox)

# Action to perform when Enter key is pressed in the textbox
$inputTextBox.Add_KeyDown({
    param($sender, $e)
    if ($e.KeyCode -eq "Enter") {
        $cmd = $sender.Text
        $output = RunUserCommand -command $cmd
        $outputTextBox.Text = $output
        $sender.Clear()  # Clear the textbox after command execution
    }
})


$form.WindowState = "Maximized"
$form.ShowDialog()



