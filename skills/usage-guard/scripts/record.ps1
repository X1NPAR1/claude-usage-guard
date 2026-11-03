# Logs one usage reading and decides whether to stop.
# Usage: record.ps1 -Percent 74 -ResetTime "5:40 AM" [-Relative] [-Threshold 98] [-IntervalMinutes 1]
# ResetTime accepts the English or Turkish usage page text, for example:
#   "5:40 AM", "Fri 3:10 AM", "17:10", "Cuma 03:10", "2 hr 10 min", "2 sa 10 dk" (with -Relative)
param(
  [Parameter(Mandatory)][int]$Percent,
  [Parameter(Mandatory)][string]$ResetTime,
  [switch]$Relative,
  [int]$Threshold = 98,
  [int]$IntervalMinutes = 1
)
$dir = if ($env:USAGE_GUARD_DIR) { $env:USAGE_GUARD_DIR } else { Split-Path $PSScriptRoot -Parent }
New-Item -ItemType Directory -Force $dir | Out-Null
$log = Join-Path $dir 'usage-log.txt'
$now = Get-Date
$text = $ResetTime.Trim()

# Minutes since the previous reading, so a missed check is visible.
$since = $null
if (Test-Path $log) {
  $last = Get-Content $log -Tail 1
  if ($last -match '^(\S+) ') {
    $prev = [datetime]::Parse($Matches[1], [Globalization.CultureInfo]::InvariantCulture)
    $since = [int]($now - $prev).TotalMinutes
  }
}

if ($Relative) {
  # "2 hr 10 min", "45 min", "2 sa 10 dk", "45 dakika"
  $h = if ($text -match '(\d+)\s*(h|hr|hour|sa|saat)') { [int]$Matches[1] } else { 0 }
  $m = if ($text -match '(\d+)\s*(m|min|minute|dk|dakika)') { [int]$Matches[1] } else { 0 }
  $reset = $now.AddHours($h).AddMinutes($m)
} else {
  # Optional weekday prefix in either language, mapped to [DayOfWeek].
  $days = @{
    'sun'=0;'sunday'=0;'paz'=0;'pazar'=0
    'mon'=1;'monday'=1;'pzt'=1;'pazartesi'=1
    'tue'=2;'tuesday'=2;'sal'=2;'salı'=2;'sali'=2
    'wed'=3;'wednesday'=3;'çar'=3;'çarşamba'=3;'car'=3;'carsamba'=3
    'thu'=4;'thursday'=4;'per'=4;'perşembe'=4;'persembe'=4
    'fri'=5;'friday'=5;'cum'=5;'cuma'=5
    'sat'=6;'saturday'=6;'cmt'=6;'cumartesi'=6
  }
  $weekday = $null
  if ($text -match '^(\p{L}+)\.?\s+(.+)$' -and $days.ContainsKey($Matches[1].ToLowerInvariant())) {
    $weekday = $days[$Matches[1].ToLowerInvariant()]; $text = $Matches[2]
  }
  if ($text -notmatch '^(\d{1,2})[:.](\d{2})\s*(AM|PM|ÖÖ|ÖS)?$') { throw "Unrecognised reset time: $ResetTime" }
  $hour = [int]$Matches[1]; $minute = [int]$Matches[2]; $half = $Matches[3]
  if ($half -in 'PM','ÖS' -and $hour -lt 12) { $hour += 12 }
  if ($half -in 'AM','ÖÖ' -and $hour -eq 12) { $hour = 0 }
  $reset = $now.Date.AddHours($hour).AddMinutes($minute)
  if ($null -ne $weekday) {
    while ([int]$reset.DayOfWeek -ne $weekday -or $reset -lt $now) { $reset = $reset.AddDays(1) }
  } elseif ($reset -lt $now) { $reset = $reset.AddDays(1) }
}

"$($now.ToString('s')) used=$Percent% reset=$($reset.ToString('s'))" | Add-Content $log
if ($Percent -ge $Threshold) {
  # Resume one minute after the reset so the new window is certainly open.
  $resume = $reset.AddMinutes(1)
  $seconds = [math]::Max(60, [int]($resume - $now).TotalSeconds)
  "STOP $($resume.ToString('s')) $seconds"
} else {
  $note = if ($since -eq $null) { 'first check' } elseif ($since -gt $IntervalMinutes) { "OVERDUE: $since min since last check (limit $IntervalMinutes)" } else { "$since min since last check" }
  "OK $Percent% ($note)"
}
