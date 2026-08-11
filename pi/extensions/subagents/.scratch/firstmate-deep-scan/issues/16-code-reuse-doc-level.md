Type: grilling
Status: resolved
Blocked by: none

## Question

Ticket 10 found that Firstmate already ships working native Pi extensions covering patterns pi-subagents needs (tool_call veto for the Primary Dispatch Guard, an agent_settled re-entrancy-guarded followUp for the Driver Turn-End Guard, a visibility-predicate pattern, a tool-shell box pattern). How explicit should `spec.md` be about pointing implementers at this reference code — a one-line pointer per relevant Implementation Decision, something more detailed, or left out of spec.md entirely and only in Ticket 10? Akhil wants to discuss this further before deciding (deferred from Ticket 15).

## Answer

Resolved via a candid build-vs-adopt discussion, not a plain grilling round. Akhil's underlying concern wasn't the doc-level question itself but whether reimplementing instead of adopting Firstmate outright was a mistake. Verified two facts before answering: (1) Firstmate's Zellij backend is genuinely secondary within Firstmate itself — 700 lines / 4 test files versus its own bespoke Herdr multiplexer backend at 3,297 lines / 21 test files, so Firstmate's center of gravity is Herdr, not Zellij; (2) Firstmate is MIT-licensed, so porting specific files is a one-time copy with attribution, not a live dependency exposed to Firstmate's future roadmap.

**Conclusion**: pi-subagents should not adopt Firstmate wholesale (Zellij is under-invested there relative to Akhil's daily-driver needs) and should not reimplement from a blank page either (nearly every Implementation Decision reached across Tickets 01-14 independently converged on Firstmate's design — control/data-plane split, decision-hold lifecycle, wedge-recovery ladder, dispatch config, correlation IDs — none of which is Zellij-specific). The right scope is: mine Firstmate for backend-agnostic design (already done, Tickets 01-14), literally port the handful of small MIT-licensed native Pi-extension `.ts` files Ticket 10 found (already in TS, already against Pi's own extension API, so "upstream drift" risk is moot once copied), and write everything Zellij/engine-specific fresh, scoped to 4 engines instead of Firstmate's 8+ and 1 backend instead of its 5.

**Doc-level decision**: `spec.md` gets one-line pointers at the specific Firstmate files/patterns under the Implementation Decisions they inform (Primary Dispatch Guard, Driver Turn-End Guard, Fleet Status Widget) — enough for a future implementer to go straight to working reference code — plus a short attribution note in Further Notes given the MIT license. Full pattern detail and file paths stay in the wayfinder tickets (09-14), not duplicated into spec.md.
