<#
    .SYNOPSIS
#>
Param (
     [Parameter(Mandatory=$false,Position=1)] [string]$RegistrationCode,
     [Parameter(Mandatory=$true,Position=1)] [string]$UserName,
     [Parameter(Mandatory=$true,Position=2)] [string]$Password,
     [Parameter(Mandatory=$false,Position=1)] [string]$Domain,
     [Parameter(Mandatory=$false,Position=3)] [string]$WorkspaceName,
     [Parameter(Mandatory=$false)] [int]$SleepBeforeLogoff = 5,
     [Parameter(Mandatory=$false)] [int]$NumberOfRetries = 30,
     [Parameter(Mandatory=$false)] [string]$LogFilePath = "$env:TEMP",
     [Parameter(Mandatory=$false)] [string]$LogFileName = "AWS_Workspace_Client_$($UserName.Replace('\','_')).log",
     [Parameter(Mandatory=$false)] [switch]$NoLogFile,
     [Parameter(Mandatory=$false)] [switch]$NoConsoleOutput
 )

 $debug=$true

# Include Functions
if ($MyInvocation.MyCommand.CommandType -eq "ExternalScript"){
  $ScriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
}else{
  $ScriptPath = Split-Path -Parent -Path ([Environment]::GetCommandLineArgs()[0])
  if (!$ScriptPath){ $ScriptPath = "." }
}
Write-Host "Running from $ScriptPath"
. "$ScriptPath\Functions.ps1"

Write-Host "Loading Assemblies"
Load-Assemblies

################
# App Definition
################
$appProcessName = 'workspaces'
$appMainWindowTitle = 'Amazon WorkSpaces'
$appExecutablePath = 'C:\Program Files\Amazon Web Services, Inc\Amazon WorkSpaces\workspaces.exe'
$appWorkingDirectory = 'C:\Program Files\Amazon Web Services, Inc\Amazon WorkSpaces'
$appArgs = ''

###################
# Start Application
###################
if($debug){Write-Host "[DEBUG]: Launching App"}
$appProcess = [Diagnostics.Process]::Start($appExecutablePath)
$appProcess.WaitForInputIdle(5000) | Out-Null

#####################
# Get PID of instance
#####################
$appProcessId = ((Get-Process).where{ $_.id -eq $appProcess.Id })[0].Id

###############################
# Set Automation Root (Desktop)
###############################
$uia = [FlaUI.UIA3.UIA3Automation]::new()
$cf = $uia.ConditionFactory
$desktopSession = $uia.GetDesktop()

##########################
# Get Main Window Instance
##########################
Wait-Action { $desktopSession.FindFirstDescendant($cf.ByProcessId($appProcessId)) }
$mainWindow = $desktopSession.FindFirstDescendant($cf.ByProcessId($appProcessId))
if($debug){Write-Host "[DEBUG]: Main Window: "$mainWindow.Name}

#####################
# Wait for Connection
#####################
Wait-Action { $mainWindow.FindFirstDescendant($cf.ByAutomationID('login_display_header')) }

###################
# Username
###################
# SetValue on Edit "Username"
Write-Host("Set Value of Edit 'Username'")
Wait-Action { $mainWindow.FindFirstDescendant($cf.ByName("Username")) }
$winElem_SetValueEditUsername = $mainWindow.FindFirstDescendant($cf.ByName("Username"))

if ($winElem_SetValueEditPassword -ne $null){
    $winElem_SetValueEditPassword.Patterns.Value.Pattern.SetValue("$Username")
}else{
    Write-Host("Failed to set element value: $winElem_SetValueEditUsername")
    Exit 1
}

###################
# Password
###################
# SetValue on Edit "Password"
Write-Host("Set Value of Edit 'Password'")

Wait-Action { $mainWindow.FindFirstDescendant($cf.ByName("Password")) }
$winElem_SetValueEditPassword = $mainWindow.FindFirstDescendant($cf.ByName("Password"))

if ($winElem_SetValueEditPassword -ne $null){
    $winElem_SetValueEditPassword.Patterns.Value.Pattern.SetValue("$Password")
}else{
    Write-Host("Failed to set element value: $winElem_SetValueEditPassword")
    Exit 1
}

##############
# Login Button
##############
# Click on Button "Sign In"
Write-Host("LeftClick on Button 'Sign In'")

$winElem_LeftClickButtonSignIn = $mainWindow.FindFirstDescendant($cf.ByName("Sign In"))
if ($winElem_LeftClickButtonSignIn -ne $null){
    $winElem_LeftClickButtonSignIn.Click()
    $LASTERRORCODE
}else{
    Write-Host("Failed to find element.")
    Exit 1
}
#####################
# Wait for Connection
#####################
