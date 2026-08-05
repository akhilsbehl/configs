# Permission auto-review improvement plan

## Objective

Make this fork behave as Akhil's personal permission reviewer:

- ordinary actions are auto-allowed when the policy says they are low-risk;
- the reviewer may assess an action as risky, but **never hard-denies it**;
- every reviewer-level denial becomes `defer`, so the underlying permission system shows its normal user prompt;
- the existing `additionalPolicy` code remains available, but the normal installation does not need to supply one.

This is one workflow, not a configurable strict/advisory product. Do not add `denyBehavior`, modes, or extra policy switches.

## Policy design

Build the fork's default review policy from three sources:

1. the current extension's built-in policy;
2. Akhil's current `additionalPolicy` in `pi/auto-review-config.json`;
3. an abstracted, model-facing interpretation of `pi/permissions-config.json`.

The third source is not a literal copy of the permission-system configuration. Translate its rules into risk guidance:

- preserve the distinctions between `allow`, `ask`, and `deny` as risk signals;
- interpret every lower-level `deny` as `ask` in the review policy;
- use the patterns to explain what is sensitive, destructive, external, or otherwise worth user confirmation;
- do not tell the model that any action is an unreviewable hard deny.

The resulting policy belongs in `src/policy.ts` as the fork's built-in default. Keep support for appending `additionalPolicy` for future use, but remove the duplicated full policy from `pi/auto-review-config.json` when the local fork becomes active.

Correct the existing `medium` spelling and ensure the fixed protocol does not instruct the model to return unsupported values.

## Minimal code change

Keep the model response contract simple:

```json
{
  "risk_level": "low|medium|high|critical",
  "user_authorization": "unknown|low|medium|high",
  "outcome": "allow|deny",
  "rationale": "..."
}
```

Do not make the model return `ask` or `defer`. The extension handles that mapping.

Change `src/reviewer.ts`:

1. Keep `allow` mapped to `{ kind: "allow" }`.
2. Change the current model-`deny` branch from `{ kind: "deny" }` to `{ kind: "defer" }`.
3. Keep the rationale in the review log and, where useful, in diagnostics.
4. Change the circuit-breaker-open branch from `{ kind: "deny" }` to `{ kind: "defer" }`.
5. Keep provider failures, invalid responses, and internal failures as `{ kind: "defer" }`.
6. Remove or bypass the hard-denial counter logic if it only exists to trigger reviewer denials. It must not create a later hard deny.

The package may continue parsing the model word `deny`; it simply treats that assessment as “ask the user” at the authorizer boundary.

## Base permission-system sequencing

After the fork is working, audit `pi/permissions-config.json` against the base permission-system behavior. The goal is to avoid spending auto-review tokens on actions that deterministic rules already allow.

Later, in a separate batch:

- change every permission-system `deny` rule to `ask`;
- retain the existing patterns as prompts/risk signals;
- verify that no lower-level rule can still hard-deny;
- verify that `read`, `grep`, `find`, `ls`, and explicitly allowed commands bypass auto-review as intended;
- verify that only effective `ask` requests reach `auto-review`.

Do not make those permission-system changes as part of the extension implementation. They are a follow-up batch after this fork is tested.

## Tests

Keep the test scope small and behavioral:

1. Model `allow` returns `{ kind: "allow" }`.
2. Model `deny` returns `{ kind: "defer" }`.
3. Circuit breaker open returns `{ kind: "defer" }`.
4. Invalid/provider/internal failures return `{ kind: "defer" }`.
5. A low-risk read that the permission system already allows does not invoke the reviewer.
6. A genuine `ask` reaches the reviewer, and a reviewer denial reaches the normal user prompt.
7. The generated default policy contains the merged guidance and no `medim` typo.
8. Optional `additionalPolicy` is still appended when supplied.

Do not add strict-mode tests or configuration tests; strict hard-deny behavior is no longer a supported behavior of this personal fork.

## Implementation sequence

1. Replace the default policy in `src/policy.ts` with the merged policy described above.
2. Keep `additionalPolicy` support but make it unnecessary for the normal configuration.
3. Change model denials and circuit-breaker-open decisions to `defer`.
4. Add the focused behavioral tests.
5. Build the fork and verify the generated `dist/` output.
6. Switch Pi from the npm auto-review package to this local package only after the build passes.
7. Remove the duplicated policy from `pi/auto-review-config.json`.
8. Separately audit and then change `deny` to `ask` in `pi/permissions-config.json`.

## Revision Log

- 2026-08-04: Initial plan.
- 2026-08-04: Simplified per review comments. Removed strict/advisory modes and made reviewer denial always defer. Added merged default-policy sources and deferred the base permission-system deny-to-ask migration to a separate batch.
