<#
.SYNOPSIS
    Reads the Claude session usage from the terminal (claude -p "/usage") instead of Chrome.
    Prints "OK <percent>% resets <time>" or "STOP <resume-at ISO> <seconds>" at or above the limit percent,
    and appends the reading to usage-log.txt (USAGE_GUARD_DIR or the skill folder).
#>
[CmdletBinding()]
param([int] $LimitPercent = 98)

$ErrorActionPreference = 'Stop'
$text = (& claude -p '/usage' 2>&1 | Out-String)
$match = [regex]::Match($text, 'Current session:\s*(\d+)%\s*used\W+resets\s*([^\r\n(]+)')
if (-not $match.Success) {
    Write-Output "UNKNOWN usage output: $($text.Trim())"
    exit 2
}

$percent = [int]$match.Groups[1].Value
$resetText = $match.Groups[2].Value.Trim()
$logDir = if ($env:USAGE_GUARD_DIR) { $env:USAGE_GUARD_DIR } else { Split-Path -Parent $PSScriptRoot }
Add-Content -Path (Join-Path $logDir 'usage-log.txt') -Value ("{0:s} {1}% resets {2}" -f (Get-Date), $percent, $resetText)

if ($percent -lt $LimitPercent) {
    Write-Output "OK $percent% resets $resetText"
    exit 0
}

# "Nov 24, 10:40pm" → local DateTime; resume one minute after the reset.
$culture = [Globalization.CultureInfo]::InvariantCulture
$formats = @('MMM d, h:mmtt', 'MMM d, htt', 'MMM d, h:mm tt', 'MMM d, h tt')
$reset = [datetime]::MinValue
if (-not [datetime]::TryParseExact($resetText, [string[]]$formats, $culture, 'AllowWhiteSpaces', [ref]$reset)) {
    Write-Output "STOP unknown-reset 3600"
    exit 1
}

$reset = $reset.AddYears((Get-Date).Year - $reset.Year)
if ($reset -lt (Get-Date).AddHours(-1)) { $reset = $reset.AddYears(1) }
$resume = $reset.AddMinutes(1)
$seconds = [Math]::Max(60, [int]($resume - (Get-Date)).TotalSeconds)
Write-Output ("STOP {0:s} {1}" -f $resume, $seconds)
exit 1
