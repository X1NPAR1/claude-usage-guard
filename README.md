# claude-usage-guard

A Claude Code skill that keeps long, unattended tasks inside the **session usage
limit**. It reads *Current session* **from the terminal** by running `claude -p "/usage"`
in the background (no browser or Chrome extension needed), logs it, checks at every phase
start and around long steps, stops safely at **98%**, waits inside the same session until one
minute after the reset, and resumes with *"Kaldığın yerden profesyonel bir şekilde devam et"*.

## Why a skill, not an agent

The guard must pause the main session and be woken up again. A subagent cannot resume its
parent, so the guard is a protocol the main session follows.

## Install

Copy `skills/usage-guard` into a project's `.claude/skills/` (or `~/.claude/skills/`):

```
git clone https://github.com/X1NPAR1/claude-usage-guard
cp -r claude-usage-guard/skills/usage-guard <project>/.claude/skills/
```

Requirements: the `claude` CLI on `PATH` (signed in with the subscription) and PowerShell
(Windows PowerShell 5.1 or pwsh).

## Use

Ask Claude *"usage-guard ile limit takibini başlat"* or run `/usage-guard`. Manual check:

```
powershell -NoProfile -File .claude/skills/usage-guard/scripts/cli-usage.ps1
OK 32% resets Nov 24, 10:40pm
```

| File | Purpose |
|---|---|
| `SKILL.md` | The protocol: start, checks, 98% stop, in-session wait, resume |
| `scripts/cli-usage.ps1` | Runs `claude -p "/usage"`, logs the reading, prints `OK`, `STOP <resume-at> <seconds>` or `UNKNOWN` |
| `scripts/read-usage.js`, `scripts/record.ps1` | Optional browser fallback (Claude in Chrome, English/Turkish usage page) |

Set `USAGE_GUARD_DIR` to choose where `usage-log.txt` is written; `-LimitPercent` changes the 98% stop.

## Limits

- It depends on the `/usage` output format. If that changes, the script prints `UNKNOWN`
  and Claude reports it instead of guessing.
- Checks happen between work steps, so one very long step can overshoot slightly.
- It never bypasses permission prompts.

## License

MIT
