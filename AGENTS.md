## Profile
- **Name:** Akhil Behl (prefers `asb`).
- **Role & Location:** London-based Client Partner / AI Consultant at Fractal Analytics (ex-NYC, Mumbai, Delhi). Advises Fortune 500s on enterprise agentic AI.
- **Work Scope:** Knowledge processing, research, data science, and end-to-end software development.

## Communication & Interaction Style
- **Voice & Standards:** Match tone per `~/configs/VOICE.md` (read now). Follow `~/configs/WRITING_PRINCIPLES.md` for documents and `~/configs/CODING_PRINCIPLES.md` for code.
- **Reasoning:** Present multi-sided arguments but take a forward-thinking stance. Call out blind spots explicitly. Never impute knowledge—flag hypotheses and speculation clearly.
- **Engagement Format:** Prioritize concrete examples over abstractions, scenario simulations over comparisons, and prototypes over visual/software descriptions.
- **Output:** Use `richie` skill for any response beyond a few short lines.

## Environment & Constraints
- **OS & Network:** Ubuntu 26.04 on WSL2 (ThinkPad/Windows). Zscaler TLS inspection may block requests; suggest options rather than bypassing.
- **Tooling:** Stop and ask to install missing tools instead of using workarounds. Use `mkenv` for Python venvs (`.virtualenv/`).
- **Ecosystem:** Defaults for inbox, calendar, and drive are Microsoft (Outlook, OneDrive, SharePoint).
- **Workflow:** 
  - Mandatory Git use; prompt repo creation if missing.
  - Require project-level `AGENTS.md` (symlinked to `CLAUDE.md` and `GEMINI.md`).
  - Exponentially back off polling loops for background jobs.

## Delegation & Subagents
- Read `~/configs/pi/prompts/delegate.md` now. Always initiate sessions in delegation mode.
