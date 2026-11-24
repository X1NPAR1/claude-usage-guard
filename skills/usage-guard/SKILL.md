---
name: usage-guard
description: Keep a long Claude Code task inside the session usage limit. Reads the "Current session" percentage and reset time from the terminal by running `claude -p "/usage"` in the background (no browser needed), logs it, checks at every phase start and around long steps, stops safely at 98%, sleeps in-session until one minute after the reset, then resumes with "Kaldığın yerden profesyonel bir şekilde devam et". Use when the user asks to watch, track or guard the Claude session limit, or to keep working unattended across a limit reset.
---

# Usage guard

Protocol for unattended work that must not run into the Claude session limit.
The limit is read **from the terminal**: `scripts/cli-usage.ps1` runs `claude -p "/usage"` as a separate,
non-interactive process and parses its output. No Chrome extension or browser is needed.

## 1. Start (beginning of the next phase or task)

1. Run the check once and tell the user the percentage and reset time:
   ```
   powershell -NoProfile -File <skill>/scripts/cli-usage.ps1
   ```
2. Write these rules into the project's memory/progress file so a resumed turn knows them.

## 2. Check

Run the same command:

- at the start of every phase or task step,
- before and after every long tool call (builds, Unity/batch runs, tests, uploads, CI waits),
- at least every few minutes during long stretches of edits.

| Output | Meaning |
|---|---|
| `OK <n>% resets <time>` | Below the limit; continue. From 90% on, take only small steps and check after each one. |
| `STOP <resume-at ISO time> <seconds>` | At or above the limit (default 98%, `-LimitPercent` to change). Go to step 3. |
| `UNKNOWN usage output: ...` | The `/usage` text changed or the CLI failed. Tell the user in one line, keep steps small, retry at the next step. Never guess. |

Each reading is appended to `usage-log.txt` (`USAGE_GUARD_DIR`, default: the skill folder).

## 3. Stop at the limit (no user confirmation)

When the check prints `STOP`:

1. Finish only the current atomic step. Do not start new work.
2. Save state: commit work in progress and update the memory/progress file with
   exactly what comes next.
3. Start the wait with a background shell command, using the printed seconds:
   ```
   sleep <seconds>; echo "Kaldığın yerden profesyonel bir şekilde devam et"
   ```
   The harness re-invokes the session when this command exits (reset + 1 minute).
   Do not poll; end the turn with a one-line Turkish status.
4. When the notification arrives, treat its output line as the instruction to resume:
   re-read the memory/progress file, check usage again (step 2), and continue.

## 4. User overrides

Users often add rules such as "if the reset is more than 40 minutes away, stop and
shut down instead" or "never work past 07:30". These take precedence. Record them in
the memory file next to the limit rule and apply them at every check.

## Browser fallback (optional)

If the `claude` CLI is unavailable, the browser method still works when Claude in Chrome is
connected: open `https://claude.ai/new#settings/usage`, run `scripts/read-usage.js` with
`javascript_tool`, then log with
`powershell -NoProfile -File <skill>/scripts/record.ps1 -Percent <percent> -ResetTime "<resets>" [-Relative]`.

## Notes

- `claude -p "/usage"` prints `Current session: 32% used · resets Nov 24, 10:40pm (Europe/Istanbul)`;
  the script parses the percent and the `MMM d, h:mmtt` reset time.
- Each check starts a separate CLI process; do not run it in a tight loop.
- Checks happen between steps, so a single very long step can overshoot slightly; keep
  steps short near the limit.
