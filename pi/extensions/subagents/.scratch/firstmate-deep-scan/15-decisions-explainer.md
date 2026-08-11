# Ticket 15 — six decisions, explained plainly

Context: you asked for a second round of firstmate research to feed `spec.md`. Six findings came back. Each needs a yes/no (or a choice) from you before I fold it into the spec. Below: what each thing is, a concrete example, the trade-offs, and my pick.

---

## 1. Correlation ID

**What it is.** Right now, when you launch a subagent, `pi-subagents` writes a `status.json` file for it, but nothing ties that subagent's activity together with *its own* sub-work if it, say, forks another agent, or if you relaunch it with a different model. A "correlation ID" is just a random string (like `a1b2c3d4`) stamped on the subagent at birth, written into its status file, and kept unchanged even if you relaunch it later with `subagents_launch`'s `relaunch` verb.

**Example.** You launch a `codex` subagent to refactor a module, worktree `id=42`. Twenty minutes in, it's misbehaving, so you relaunch it with a different model. Without a correlation ID, the new process is just "subagent 42, take 2" — if you're looking at `/tmp/pi-subagents/42/output.log`, you can't tell where the first attempt's output ends and the second begins without eyeballing timestamps. With a correlation ID, every log line and status update from both the first and second attempt carries the same tag, so tooling (or you, grepping) can cleanly pull "everything that happened for this one piece of work" regardless of how many times it got relaunched.

**Pros:**
- Cheap to add now (one extra field in a JSON file you're already writing); expensive to bolt on later once other tools depend on the file's shape.
- Makes debugging relaunches and multi-subagent chains much easier — you can grep one ID and get the full story.
- If you ever build the fleet-status TUI widget with history ("this subagent has been relaunched 3 times"), the ID is what groups those rows together.

**Cons:**
- It's one more field to maintain, and until you actually hit a debugging session where you *need* it, it's unused weight.
- If `agy` doesn't have a way to log a supplied token, the ID is only useful at the pi-subagents layer, not inside the engine's own transcript — you can't grep `agy`'s own thoughts for it, only the wrapper's IPC files.

**My recommendation:** Add it now, as a simple opaque random string (not the full W3C trace format Firstmate uses — that's built for OpenTelemetry-style distributed tracing across many services, which you don't have; you have one wrapper process per subagent). A plain `id` field you already assign at launch, reused verbatim across relaunches, gets you 90% of the value for near-zero cost.

---

## 2. "Steer" action in the TUI widget

**What it is.** The plan already includes a status widget listing subagents that are running or waiting. Firstmate's version of this widget has a one-click "steer" action next to each row — a way to send a quick instruction to that subagent without leaving the widget. The question is: what should clicking "steer" on a pi-subagents row actually *do*, mechanically?

There are two "channels" a message could travel through:
- **inbox.jsonl** — a file the subagent's runner wrapper polls, already used by `subagents_send`. Writing to it is like leaving a note in someone's inbox — durable, they'll see it when they check, and there's a record of it even if you close everything.
- **Direct pane injection** — typing text straight into the Zellij terminal pane the subagent is running in, as if you'd walked up and typed it yourself. No file record; if the pane is showing a permission prompt, your text could land in the wrong place.

**Example.** A `claude` subagent is deep in a refactor and you want to add "also update the README." If "steer" writes to `inbox.jsonl`, the runner picks it up cleanly next time it polls, same as any other message — reliable, but there's a small delay (however long the poll interval is). If "steer" injects keystrokes directly, it's instant, but if the subagent happens to be mid-way through typing a tool-permission response, your injected text could get mixed in with its input and cause a mess (this is exactly the TTY collision problem the earlier round of research flagged).

**Pros of inbox.jsonl (recommended):**
- Reuses a mechanism you're already building (`subagents_send`) — no new code path.
- Durable — if pi-subagents crashes right after you click "steer," the message is still sitting in the file waiting to be delivered.
- Safe against the TTY collision problem.

**Cons of inbox.jsonl:**
- Not instant — there's a small delay until the runner's poll loop picks it up.

**Pros of direct pane injection:**
- Feels instant/interactive, like typing directly into the tab yourself.

**Cons of direct pane injection:**
- New code path to write and test.
- Risk of colliding with whatever the subagent's terminal is currently doing (this is the exact bug class Round 1 research already found and fixed for the `interrupt` command — you'd be reopening that risk for a different command).

**My recommendation:** Route "steer" through `inbox.jsonl`, same as `subagents_send`. It's actually just the same underlying action wearing a friendlier button in the widget — you're not building a second way to talk to a subagent, just giving the existing one a one-click shortcut in the UI.

---

## 3. Stuck/wedge recovery ladder

**What it is.** Today's plan can tell if a subagent's *process* has died (the PID is gone) — that's easy, the OS tells you. What it *can't* tell is if a subagent is alive but stuck: the process is still running, but it's not doing anything useful — maybe it's frozen waiting on something, maybe its terminal stopped responding to input. Firstmate handles this with an escalating sequence of responses instead of just "is it dead, yes/no":

1. **Peek** — look at the last few lines of its output, cheaply, to see what's going on.
2. **Redirect** — send it a message nudging it back on track (via the inbox, per decision #2).
3. **Interrupt** — if that doesn't work, send a harder "stop what you're doing" signal.
4. **Forced relaunch** — if it's still stuck, kill the process and start a fresh one *in the same worktree, with the same branch*, telling the new one "you're picking up from where the last one got stuck."
5. **Give up** — if that still doesn't work (Firstmate tries this twice, then stops), mark it failed and tell you, rather than looping forever.

**Example.** You launch a `codex` subagent to run a long migration script, and after 20 minutes the terminal shows the same unchanged screen — no crash, no error, just... nothing. Right now, pi-subagents would have no way to notice this at all (the process is alive, so it looks "running" forever). With the ladder, after a timeout, it'd peek at the pane, see nothing's moved, try nudging it, then interrupting it, and if that fails twice, relaunch it fresh into the same worktree with a note like "previous attempt got stuck after X, here's where it left off" — and if *that* fails too, it stops trying and flags it to you instead of silently spinning.

**Pros:**
- Catches a real failure mode that pure PID-checking is blind to — "stuck but not dead" is probably going to happen with real engines and real long tasks.
- Doesn't throw away work: relaunching into the same worktree/branch means you don't lose whatever the stuck subagent had already committed.
- The "give up after N tries" cap means it fails loudly instead of looping forever and burning your Zellij session on a ghost.

**Cons:**
- It's the most complex of the six decisions to build — needs pane-reading, a timeout policy, and a relaunch-with-context mechanism.
- Auto-relaunching a subagent mid-task is itself a slightly risky move — if the "stuck" state was actually the subagent legitimately thinking hard (not literally stuck), an aggressive timeout could kill useful work in progress. Getting the timeout threshold right matters and you'll probably need to tune it after living with it a bit.

**My recommendation:** Adopt the ladder, cap relaunches at 2 (Firstmate's number, and a sane "try twice, then admit defeat" default). This is worth the build cost because "alive but doing nothing" is a real and annoying failure mode you will hit, and the alternative (nothing) means you'd only ever discover a stuck subagent by noticing it yourself.

---

## 4. Unknown busy-state for `agy` and `codex`

**What it is.** For the widget/supervision loop to know if a subagent is "busy" (still working) or "idle" (waiting for you), it needs some signal from the engine. `claude` and `pi` both have built-in hooks that fire reliably when they start/stop working — pi-subagents can trust those. `codex` and `agy` don't have anything nearly as reliable: even Firstmate — a far more mature project — never got a trustworthy busy signal working for `codex`, and nobody's ever built one for `agy` because it's a much newer/rarer CLI.

The question is: for these two engines, do you (a) just say "we don't know" (`unknown`) until someone proves a real signal exists, or (b) guess based on scraping the terminal's visible text for some pattern (e.g., "if the screen shows a spinner character, it's busy")?

**Example.** You launch an `agy` subagent. Is it thinking, or has it silently finished and is just sitting there? Option (a): the widget honestly shows "unknown" for that row — you don't get a false "idle" telling you it's ready when it's actually still working. Option (b): the widget tries to guess by watching the terminal text, e.g. "if I don't see a specific prompt string, assume it's busy" — this works most of the time but can be fooled (a genuinely idle screen that happens to still show old text would get misread as busy, or vice versa).

**Pros of "accept unknown" (recommended):**
- Honest. `unknown` never lies to you — your Turn-End Guard and TUI already treat `unknown` explicitly (a separate legitimate state, not an error), so this isn't even new machinery, it's just letting these two engines land in a bucket you've already built for exactly this situation.
- No wasted effort building a heuristic that might be wrong in ways that quietly cost you trust in the tool.

**Cons of "accept unknown":**
- Less convenient day-to-day: for those two engines, the widget won't tell you "it's done, go look" — you'll have to check yourself.

**Pros of "add a stopgap regex":**
- Better UX right away if it happens to work reliably for your actual terminal setup.

**Cons of "add a stopgap regex":**
- False positives/negatives are a real risk — a "busy" guess that's wrong could make the Turn-End Guard tell you a subagent needs attention when it doesn't, or (worse) tell you nothing's wrong when it's actually stuck.
- Extra code for something you already have a graceful fallback for.

**My recommendation:** Accept `unknown` for v1. You already built the "fail closed, never guess" philosophy into this spec for the *status file* (item 5 in the original decisions) — extending that same philosophy to *engines with no reliable signal* is consistent, not a compromise. If, after using it for a while, "not knowing agy's status" turns out to actually bug you in practice, that's the moment to invest in a heuristic — with real evidence about what actually correlates with busy/idle for that CLI, not a guess made now.

---

## 5. How explicit should spec.md be about reusing Firstmate's Pi-extension code?

**What it is.** This one isn't really a design decision about *behavior* — it's about how much of a hint to leave yourself (or whoever implements this) about *where to start coding*. Round 2 found that Firstmate already has working, tested Pi extension code doing very similar things to what you're planning to build — e.g., a piece of code that intercepts a tool call and blocks it, and a piece of code that safely sends a follow-up message to the user without re-triggering itself in a loop. These are exactly the mechanisms your spec calls for (the "Primary Dispatch Guard" and "Driver Turn-End Guard").

**Example.** When someone (you, or a future agent session) sits down to actually write the Primary Dispatch Guard, they have two options: (a) work it out from scratch by reading Pi's extension API docs and experimenting, or (b) open `~/warchives/firstmate/.pi/extensions/fm-primary-turnend-guard.ts` and see a working example of exactly this pattern, already fighting through the edge cases (like "how do I stop my own alert from re-triggering the alert"). Option (b) is obviously faster and lower-risk *if* the implementer knows to look there.

**Pros of naming it explicitly in spec.md:**
- Whoever implements this (probably you, in a future session, possibly with a fresher agent that has no memory of this conversation) gets pointed straight at working reference code instead of rediscovering the same pitfalls Firstmate already solved.
- Low cost — it's just a sentence or two per relevant section.

**Cons:**
- Spec.md is meant to describe *what* to build, not *how* — mixing in "go copy this file's pattern" nudges it slightly toward an implementation guide. Not a big deal, but worth naming.

**My recommendation:** Add a short one-line pointer under each relevant Implementation Decision (Primary Dispatch Guard, Driver Turn-End Guard) — not full code, just "model this on `firstmate`'s `fm-primary-turnend-guard.ts` `tool_call`/`agent_settled` handlers." That's the cheapest possible way to make sure this genuinely high-value finding doesn't get lost in a ticket nobody rereads.

---

## 6. Decisions-backlog draining (`/sa-decisions-backlog`)

**What it is.** This is about the *mechanics* of how the decisions-backlog side-loop checks for pending prompts across all your subagents. Two sub-questions bundled together:

- **Incremental scanning**: when the backlog loop wakes up to check "does anyone need my attention," does it re-read *everything* each subagent has ever logged, or does it remember where it left off last time and only look at what's new?
- **Ack-through**: after you respond to a prompt, does the system wait for positive confirmation the response was actually delivered before considering that prompt "handled," or does it just assume it worked once you've answered?

**Example — incremental scanning.** If you have 5 subagents each with a growing output log, and the backlog loop re-reads all 5 full logs every time it checks for new prompts, that gets slower and slower the longer your subagents run. Remembering "I already read up to byte 4,200 of subagent 3's log" means each check only costs you the *new* output since last time — cheap regardless of how long the subagent has been running.

**Example — ack-through.** You answer a permission prompt from a subagent ("yes, allow that file write"). If pi-subagents crashes or the message gets lost right after you hit send, does the backlog loop know to show you that prompt again (because it never got confirmation it was delivered), or does it just assume "I displayed it, you answered, done" and move on — potentially leaving the subagent still stuck waiting, with you never finding out?

**Pros of doing both:**
- Incremental scanning keeps the backlog loop fast no matter how long your subagents have been running or how many you have.
- Ack-through means a crash or lost message can't silently strand a subagent waiting forever without you knowing.

**Cons of doing both:**
- More bookkeeping (a small cursor file per subagent, and a "confirmed delivered" flag per response) — not hard, but it's more moving parts than "just re-read everything and hope."

**Cons of skipping either:**
- Skipping incremental scanning: fine while you only have a couple of subagents; becomes a real drag if you're running many at once or leaving them running for hours.
- Skipping ack-through: the actual risk here is silent — a response that didn't land leaves a subagent stuck, and *you'd have no way of knowing* unless you separately noticed it was still idle.

**My recommendation:** Do both — given how cheap they are relative to the failure mode they prevent (a subagent silently stuck forever because a response got lost), and given this is exactly the kind of thing that's annoying to retrofit once `/sa-decisions-backlog` already exists and you're relying on it daily.

---

## Summary table

| # | Decision | My pick |
|---|---|---|
| 1 | Correlation ID | Add now, simple opaque string, not full W3C traceparent |
| 2 | "Steer" action | Route through `inbox.jsonl`, same as `subagents_send` |
| 3 | Stuck/wedge recovery | Adopt full ladder, cap at 2 relaunches |
| 4 | Unknown busy-state (agy/codex) | Accept `unknown` for v1, no heuristic guess |
| 5 | Code-reuse documentation | Name specific firstmate files/patterns in spec.md |
| 6 | Backlog draining | Do both: incremental scan + ack-through |
