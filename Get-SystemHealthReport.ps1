[CmdletBinding()]
param(
    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot "system-health-report.txt"),

    [Parameter()]
    [ValidateRange(1, 30)]
    [int]$RecentErrorDays = 7
)

$ErrorActionPreference = "Continue"

function Add-Section {
    param([string]$Title)
    Add-Content -Path $script:OutputPath -Value "`r`n$('=' * 72)`r`n$Title`r`n$('=' * 72)"
}

function Add-Line {
    param([string]$Text = "")
    Add-Content -Path $script:OutputPath -Value $Text
}

try {
    $parent = Split-Path -Parent $OutputPath
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $script:OutputPath = $OutputPath
    "WINDOWS SYSTEM HEALTH REPORT`r`nGenerated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`r`nComputer: $env:COMPUTERNAME" |
        Set-Content -Path $script:OutputPath -Encoding UTF8

    Add-Section "SYSTEM"
    $os = Get-CimInstance Win32_OperatingSystem
    $computer = Get-CimInstance Win32_ComputerSystem
    Add-Line "Computer name : $($computer.Name)"
    Add-Line "Manufacturer  : $($computer.Manufacturer)"
    Add-Line "Model         : $($computer.Model)"
    Add-Line "OS            : $($os.Caption)"
    Add-Line "Version       : $($os.Version)"
    Add-Line "Last boot     : $($os.LastBootUpTime)"
    Add-Line ("Uptime        : {0:N1} days" -f ((Get-Date) - $os.LastBootUpTime).TotalDays)

    Add-Section "PROCESSOR AND MEMORY"
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    Add-Line "CPU           : $($cpu.Name)"
    Add-Line "Logical CPUs  : $($cpu.NumberOfLogicalProcessors)"
    Add-Line ("Total RAM     : {0:N2} GB" -f ($computer.TotalPhysicalMemory / 1GB))
    $memory = Get-CimInstance Win32_OperatingSystem
    Add-Line ("Free RAM      : {0:N2} GB" -f ($memory.FreePhysicalMemory / 1MB))

    Add-Section "STORAGE"
    Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" |
        ForEach-Object {
            $size = if ($_.Size) { $_.Size / 1GB } else { 0 }
            $free = if ($_.FreeSpace) { $_.FreeSpace / 1GB } else { 0 }
            $usedPct = if ($size -gt 0) { 100 * (1 - ($free / $size)) } else { 0 }
            Add-Line ("{0}  Size: {1:N1} GB  Free: {2:N1} GB  Used: {3:N0}%" -f $_.DeviceID, $size, $free, $usedPct)
        }

    Add-Section "NETWORK CONFIGURATION"
    Get-NetIPConfiguration -ErrorAction SilentlyContinue |
        ForEach-Object {
            Add-Line "Interface     : $($_.InterfaceAlias)"
            Add-Line "IPv4          : $((($_.IPv4Address | ForEach-Object IPAddress) -join ', '))"
            Add-Line "Gateway       : $((($_.IPv4DefaultGateway | ForEach-Object NextHop) -join ', '))"
            Add-Line ""
        }

    Add-Section "DNS SERVERS"
    Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object { $_.ServerAddresses } |
        ForEach-Object {
            Add-Line ("{0}: {1}" -f $_.InterfaceAlias, ($_.ServerAddresses -join ", "))
        }

    Add-Section "AUTOMATIC SERVICES"
    Get-CimInstance Win32_Service -Filter "StartMode='Auto'" |
        Sort-Object State, Name |
        Select-Object -First 30 |
        ForEach-Object {
            Add-Line ("{0,-35} {1,-10} {2}" -f $_.Name, $_.State, $_.StartName)
        }

    Add-Section "RECENT SYSTEM ERRORS"
    try {
        $since = (Get-Date).AddDays(-$RecentErrorDays)
        $events = Get-WinEvent -FilterHashtable @{
            LogName = "System"
            Level = 2
            StartTime = $since
        } -MaxEvents 20 -ErrorAction Stop

        if ($events) {
            $events | ForEach-Object {
                Add-Line ("{0} | Event ID {1} | {2}" -f $_.TimeCreated, $_.Id, $_.ProviderName)
                Add-Line ("  {0}" -f (($_.Message -replace '\s+', ' ').Trim()))
            }
        }
        else {
            Add-Line "No system error events found in the selected period."
        }
    }
    catch {
        Add-Line "Could not read System event log. Try running PowerShell as Administrator."
        Add-Line "Details: $($_.Exception.Message)"
    }

    Add-Section "END OF REPORT"
    Add-Line "Report saved to: $OutputPath"
    Write-Host "Health report created: $OutputPath" -ForegroundColor Green
}
catch {
    Write-Error "Failed to create the health report: $($_.Exception.Message)"
    exit 1
}
