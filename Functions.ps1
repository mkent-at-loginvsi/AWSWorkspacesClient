# Logging
Write-Host "Initializing"
<# Function Write-HostHeader {
    $infoMessage = @"
                           *****************************************************
                           *****        Custom Connector                   *****
                           *****        -Console output:     {0,-6}        *****
                           *****        -Log output:         {1,-6}        *****
                           *****************************************************
"@ -f $(-not $NoConsoleOutput), $(-not $NoLogFile)
    Write-Host $infoMessage
}

Function Write-Host {
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)] [string]$Message,
        [Parameter(Mandatory = $false)] [string]$LogFile = $($LogFilePath.TrimEnd('\') + "\$LogFileName"),
        [Parameter(Mandatory = $false)] [bool]$NoConsoleOutput = $false,
        [Parameter(Mandatory = $false)] [bool]$NoLogFile = $false
    )
    Begin {
        if (Test-Path $LogFile -IsValid) {
            if (!(Test-Path "$LogFile" -PathType Leaf)) {
                New-Item -Path $LogFile -ItemType "file" -Force -ErrorAction Stop | Out-Null
            }
        }
        else {
            throw "Log file path is invalid"
        }
    }
    Process {
        $Message = [DateTime]::Now.ToString("[MM/dd/yyy HH:mm:ss.fff]: ") + $Message

        if (-not $NoConsoleOutput){
            Write-Host $Message
        }

        if (-not $NoLogFile) {
            $Message | Out-File -FilePath $LogFile -Append
        }
    }
}
#>
# Load Assemblies
Function Load-Assemblies {
    Write-Host "START: Load Assemblies from $ScriptPath"

    $libs = @(
        "$ScriptPath\FlaUI.UIA3.dll",
        "$ScriptPath\FlaUI.UIA2.dll",
        "$ScriptPath\FlaUI.Core.dll",
        "$ScriptPath\Interop.UIAutomationClient.dll"
    )

    foreach($lib in $libs){
        $FileToLoad = $lib

        if (-not (Test-Path "$FileToLoad" -PathType Leaf))
        {
            Throw "Can't find or open file ${FileToLoad}."

        }
        else{
            Write-Host "Loading Library: $FileToLoad"
            [System.Reflection.Assembly]::LoadFrom($FileToLoad) | Out-Null
        }

    }
    Write-Host "END: Load Assemblies"
}

function Wait-Action {
  [OutputType([void])]
  [CmdletBinding()]
  param
  (
      [Parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [scriptblock]$Condition,

      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [int]$Timeout = 30,

      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [object[]]$ArgumentList,

      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [int]$RetryInterval = 1
  )

    try {
        $timer = [Diagnostics.Stopwatch]::StartNew()
        while (($timer.Elapsed.TotalSeconds -lt $Timeout) -and (-not (& $Condition $ArgumentList))) {
            Start-Sleep -Seconds $RetryInterval
            $totalSecs = [math]::Round($timer.Elapsed.TotalSeconds, 0)
            Write-Verbose -Message "Still waiting for action to complete after [$totalSecs] seconds..."
        }
        $timer.Stop()
        if ($timer.Elapsed.TotalSeconds -gt $Timeout) {
            throw 'Action did not complete before timeout period.'
        } else {
            Write-Verbose -Message 'Action completed before timeout period.'
        }
    } catch {
        Write-Error -Message $_.Exception.Message
    }
}

function WaitElement {
    param (
         [string]$xpath,
         [int] $Timeout = 30
    )

    try {$el = $desktop.FindFirstByXPath($xpath) }catch{}
    $count = 1
    while (!$el.IsAvailable){
        if ($count -eq $Timeout){
            Write-Error "Timeout ($($Timeout)s) to found element witn XPATH : $($xpath)"
            exit 1
        }
        try {$el = $desktop.FindFirstByXPath($xpath) }catch{}
        Start-Sleep -Seconds 1
        $count ++
    }
    return $el
}


function RunAction {
    param ( $item)

    switch ($item.Action) {
        Click {
            $el = WaitElement -xpath $item.Xpath -Timeout $item.Timeout
            $el.Click()
        }

        DClick {
            $el = WaitElement -xpath $item.Xpath -Timeout $item.Timeout
            $el.DoubleClick()
        }
        Type {
            $el = WaitElement -xpath $item.Xpath -Timeout $item.Timeout
            $el.Patterns.Value.Pattern.SetValue($item.Value)
        }
        Key {

            for ($i=1; $i -le $item.xpath; $i++){
                [System.Windows.Forms.SendKeys]::SendWait($item.Value)
            }

        }
    }
}
