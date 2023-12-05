# Check if the script is running as an administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    # Relaunch the script with elevated permissions
    Start-Process powershell.exe -Verb RunAs -ArgumentList ("-File", $MyInvocation.MyCommand.Path)
    Exit
}

Add-Type -AssemblyName System.Windows.Forms

# Create a form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Local Admin Commander Suite"
$form.Size = New-Object System.Drawing.Size(600,400)
$form.StartPosition = "CenterScreen"
$form.BackColor = "LightGray"  # Change the form's background color

# Function to create labels and textboxes
function Add-LabelTextBox($labelText, $x, $y, $labelWidth, $textBoxX, $isPassword = $false) {
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point($x, $y)
    $label.Size = New-Object System.Drawing.Size($labelWidth,20)
    $label.Text = $labelText
    $label.BackColor = "LightGray"  # Change label background color
    $label.ForeColor = "DarkBlue"   # Change label text color
    $form.Controls.Add($label)

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point($textBoxX, $y)
    $textBox.Size = New-Object System.Drawing.Size(200,20)
    if ($isPassword) {
        $textBox.PasswordChar = "*"   # Mask password input
    }
    $textBox.BackColor = "White"  # Change textbox background color
    $textBox.ForeColor = "Black"  # Change textbox text color
    $form.Controls.Add($textBox)

    return $textBox
}

# Title label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Location = New-Object System.Drawing.Point(10, 5)
$titleLabel.Size = New-Object System.Drawing.Size(400,30)
$titleLabel.Text = "Local Admin Commander Suite"
$titleLabel.Font = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = "DarkBlue"
$form.Controls.Add($titleLabel)

# Developer attribution label
$developerLabel = New-Object System.Windows.Forms.Label
$developerLabel.Location = New-Object System.Drawing.Point(10, 35)
$developerLabel.Size = New-Object System.Drawing.Size(400,15)
$developerLabel.Text = "Written and Developed by Alexander Kohanik"
$developerLabel.Font = New-Object System.Drawing.Font("Arial", 8)
$developerLabel.ForeColor = "DarkGray"
$form.Controls.Add($developerLabel) 

# Add domain input
$domainTextbox = Add-LabelTextBox "Domain:" 10 60 70 100
$domainTextbox.Text = "defaultDomain.local" #Replace defaultDomain.local with your domain. 

# Add username input
$userTextbox = Add-LabelTextBox "Username:" 10 80 70 100

# Add password input with asterisks
$passwordTextbox = Add-LabelTextBox "Password:" 10 100 70 100 -isPassword $true

# Add machine names input
$machineTextbox = Add-LabelTextBox "Machine Name or IP Address:" 10 160 180 200

# Add admin to remove input
$removeAdminTextbox = Add-LabelTextBox "Admin to Remove:" 10 200 150 200

# Add admin to add input
$addAdminTextbox = Add-LabelTextBox "Admin to Add:" 10 240 150 200

# Create buttons
$checkButton = New-Object System.Windows.Forms.Button
$checkButton.Location = New-Object System.Drawing.Point(400,155)
$checkButton.Size = New-Object System.Drawing.Size(150,30)
$checkButton.Text = "Check Admins"
$checkButton.BackColor = "ForestGreen"  # Change button background color
$checkButton.ForeColor = "White"        # Change button text color
$checkButton.Add_Click({
    $domain = $domainTextbox.Text
    $username = $userTextbox.Text
    $password = $passwordTextbox.Text | ConvertTo-SecureString -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($username, $password)
    $machine = $machineTextbox.Text

    try {
        $checkCommand = {
            $adminGroup = [ADSI]"WinNT://./Administrators,group"
            $adminMembers = $adminGroup.Invoke('Members') | ForEach-Object {
                $_.GetType().InvokeMember('Name', 'GetProperty', $null, $_, $null)
            }
            [PSCustomObject]@{
                MachineName = $env:COMPUTERNAME
                GroupName = $adminGroup.Name
                Members = $adminMembers
            }
        }

        $result = Invoke-Command -ComputerName $machine -Credential $credential -ScriptBlock $checkCommand -ErrorAction Stop

        $adminList = "Local Administrators Group on $machine :`n`nGroup Name: $($result.GroupName)`nMembers:`n$($result.Members -join "`n")"
        [System.Windows.Forms.MessageBox]::Show($adminList, "Local Administrators - $machine")
    } catch {
        $errorMsg = "Failed to retrieve local administrators on $machine.`nError: $_"
        [System.Windows.Forms.MessageBox]::Show($errorMsg, "Error - Check Admins")
    }
})
$form.Controls.Add($checkButton)

$removeButton = New-Object System.Windows.Forms.Button
$removeButton.Location = New-Object System.Drawing.Point(400,195)
$removeButton.Size = New-Object System.Drawing.Size(150,30)
$removeButton.Text = "Remove Admin"
$removeButton.BackColor = "Firebrick"   # Change button background color
$removeButton.ForeColor = "White"       # Change button text color
$removeButton.Add_Click({
    $domain = $domainTextbox.Text
    $username = $userTextbox.Text
    $password = $passwordTextbox.Text | ConvertTo-SecureString -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($username, $password)
    $machine = $machineTextbox.Text
    $adminToRemove = $removeAdminTextbox.Text

    try {
        $removeCommand = {
            param($adminToRemove)
            try {
                $adminGroup = [ADSI]"WinNT://$env:COMPUTERNAME/Administrators,group"
                $adminGroup.Remove("WinNT://$env:USERDOMAIN/$adminToRemove")
                return "Admin '$adminToRemove' successfully removed from Administrators group on $env:COMPUTERNAME."
            } catch {
                return "Error removing admin '$adminToRemove': $_"
            }
        }

        $session = New-PSSession -ComputerName $machine -Credential $credential
        Invoke-Command -Session $session -ScriptBlock $removeCommand -ArgumentList $adminToRemove -ErrorAction Stop

        Remove-PSSession -Session $session

        [System.Windows.Forms.MessageBox]::Show("Admin '$adminToRemove' successfully removed from Administrators group on $machine.", "Admin Removal")
    } catch {
        $errorMsg = "Failed to remove admin '$adminToRemove' on $machine.`nError: $_"
        [System.Windows.Forms.MessageBox]::Show($errorMsg, "Error - Admin Removal")
    }
})
$form.Controls.Add($removeButton)

$addButton = New-Object System.Windows.Forms.Button
$addButton.Location = New-Object System.Drawing.Point(400,235)  # Adjusted position
$addButton.Size = New-Object System.Drawing.Size(150,30)
$addButton.Text = "Add Local Admin"
$addButton.BackColor = "DodgerBlue"    # Change button background color
$addButton.ForeColor = "White"         # Change button text color
$addButton.Add_Click({
    $domain = $domainTextbox.Text
    $username = $userTextbox.Text
    $password = $passwordTextbox.Text | ConvertTo-SecureString -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($username, $password)
    $machine = $machineTextbox.Text
    $userToAdd = $addAdminTextbox.Text

    try {
        $addCommand = {
            param($userToAdd)
            try {
                $adminGroup = [ADSI]"WinNT://$env:COMPUTERNAME/Administrators,group"
                $adminGroup.Add("WinNT://$env:USERDOMAIN/$userToAdd")
                return "User '$userToAdd' successfully added as a local admin on $env:COMPUTERNAME."
            } catch {
                return "Error adding user '$userToAdd' as a local admin: $_"
            }
        }

        $session = New-PSSession -ComputerName $machine -Credential $credential
        Invoke-Command -Session $session -ScriptBlock $addCommand -ArgumentList $userToAdd -ErrorAction Stop

        Remove-PSSession -Session $session

        [System.Windows.Forms.MessageBox]::Show("User '$userToAdd' successfully added as a local admin on $machine.", "Add Local Admin")
    } catch {
        $errorMsg = "Failed to add user '$userToAdd' as a local admin on $machine.`nError: $_"
        [System.Windows.Forms.MessageBox]::Show($errorMsg, "Error - Add Local Admin")
    }
})
$form.Controls.Add($addButton)

# Show the form
$form.ShowDialog()
