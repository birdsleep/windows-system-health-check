# Windows System Health Check

A small PowerShell tool for collecting a basic Windows workstation/server health report.

## Purpose

This project demonstrates practical Windows administration fundamentals:
- Operating system and computer information
- CPU and memory overview
- Disk capacity and free-space checks
- IP configuration and default gateway
- DNS configuration
- Running services overview
- Recent system errors from the Windows event log

The script is read-only: it gathers information and writes a report. It does not change system settings, stop services, or modify the registry.

## Requirements

- Windows 10/11 or Windows Server
- Windows PowerShell 5.1 or PowerShell 7+
- Some event-log details may require running PowerShell as Administrator

## Usage

Open PowerShell in the project folder and run:

```powershell
.\Get-SystemHealthReport.ps1
```

To save the report somewhere specific:

```powershell
.\Get-SystemHealthReport.ps1 -OutputPath "$env:USERPROFILE\Desktop\health-report.txt"
```

## Example report sections

- System
- Processor and memory
- Storage
- Network configuration
- DNS servers
- Automatic services
- Recent system errors

## Implementation notes

The script uses built-in PowerShell cmdlets and CIM/WMI queries. It includes basic error handling for event-log access and creates the output directory when necessary.

## Scope and limitations

This is an educational administration utility, not a full monitoring platform. It does not perform security auditing, vulnerability scanning, remediation, or continuous monitoring. Results depend on the permissions and Windows version of the machine where it runs.

## Possible improvements

- Export results to JSON or CSV
- Add configurable disk-space warning thresholds
- Add a scheduled-task mode
- Add HTML report output
- Add unit tests with Pester
