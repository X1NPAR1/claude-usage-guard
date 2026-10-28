# claude-usage-guard

A Claude Code skill that keeps long, unattended tasks inside the **session usage
limit**. Before each work step it reads *Current session* from
`claude.ai/settings/usage` in Chrome, logs it, checks at least **every 5 minutes** (and around long steps), stops safely at **98%**, waits inside
the same session until one minute after the reset, and resumes with
*"Kaldığın yerden profesyonel bir şekilde devam et"*.

## Why a skill, not an agent

The checks need Claude in Chrome and the ability to pause and be woken up again. Both
live in the main session. A subagent cannot keep a browser watch running or resume its
parent, so the guard is a protocol the main session follows.

## Install

Copy `skills/usage-guard` into a project's `.claude/skills/` (or `~/.claude/skills/`):

```
git clone https://github.com/X1NPAR1/claude-usage-guard
cp -r claude-usage-guard/skills/usage-guard <project>/.claude/skills/
```

Requirements: Claude Code with the Claude in Chrome extension, signed in to claude.ai,
and PowerShell (Windows PowerShell 5.1 or pwsh) for `record.ps1`.

## Use

Ask Claude *"usage-guard ile limit takibini başlat"* or run `/usage-guard`.

| File | Purpose |
|---|---|
| `SKILL.md` | The protocol: start, per-step check, 98% stop, in-session wait, resume |
| `scripts/read-usage.js` | Reads the percentage and reset time from the usage page |
| `scripts/record.ps1` | Logs a reading, prints `OK` or `STOP <resume-at> <seconds>` |

Set `USAGE_GUARD_DIR` to choose where `usage-log.txt` is written.

## Limits

- It depends on the claude.ai usage page layout. If that changes, `read-usage.js`
  returns `null` and Claude reports it instead of guessing.
- Checks happen between work steps, so one very long step can overshoot slightly. `record.ps1` reports
  minutes since the previous check and flags `OVERDUE` when the 5-minute rule was missed.
- It never launches external `claude` processes or bypasses permission prompts.

## License

MIT
