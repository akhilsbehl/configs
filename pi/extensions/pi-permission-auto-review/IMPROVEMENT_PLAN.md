# Permission auto-review improvement plan

## Objective

Make the fork's built-in default policy the authoritative operator policy, while preserving optional `additionalPolicy` support for future per-install or project-specific additions. Add an explicit advisory mode in which a model's negative assessment defers to the normal Pi permission prompt instead of hard-blocking the action.

The active settings file should no longer need to carry the full operator policy. Once the fork is activated, remove that duplicated `additionalPolicy` value from `pi/auto-review-config.json`; retain only settings that genuinely vary by installation.

The desired behavior is:

| Reviewer result | Strict mode | Advisory mode |
|---|---|---|
| `allow` | `{ kind: "allow" }` | `{ kind: "allow" }` |
| `deny` | `{ kind: "deny" }` | `{ kind: "defer" }` |
| invalid/provider failure | `{ kind: "defer" }` | `{ kind: "defer" }` |
| circuit breaker open | `{ kind: "deny" }` | `{ kind: "defer" }` |

## Important boundary

This change controls only decisions made by `pi-permission-auto-review`.

The underlying `pi-permission-system` can still produce a deterministic `deny` before the authorizer chain runs. Therefore “no hard denies ever” requires both:

1. advisory handling in this fork; and
2. removal or conversion of `deny` rules in `pi-permission-system` configuration.

The permission-system delegation envelope can also downgrade an auto-review `allow` to `defer` for `path` and `external_directory`; that behavior is intentional and remains outside this fork.

Do not silently reinterpret underlying system denies as reviewer deferrals. That would make the extension appear permissive while the actual gate remains restrictive.

## Phase 1 — Establish the contract

### 1. Move the operator policy into the package default

Replace the current built-in policy in `src/policy.ts` with the operator policy currently stored in `pi/auto-review-config.json`. This becomes the package's default policy, not an `additionalPolicy` supplied by settings.

Keep the existing `additionalPolicy` field and concatenation logic. It remains an optional extension point for narrow overrides or future deployments, but it should not be required for the normal configuration.

Set the normal defaults so that:

- the built-in operator policy is enabled by default;
- `additionalPolicy` is omitted unless specifically needed;
- the default policy contains the corrected `medium` spelling and the intended `defer`/advisory semantics;
- tests cover the no-configuration path, not only the settings-file path.

Update `src/policy.ts`, `src/config.ts`, the package schema, the example config, and `README.md` accordingly. Do not delete the code path that appends `additionalPolicy`.

### 2. Add an explicit configuration option

Add a field to `src/config.ts` and the package schema:

```json
"denyBehavior": "deny" | "defer"
```

Recommended default: `"deny"`.

Rationale:

- Existing users retain current security behavior.
- Advisory behavior is an explicit opt-in.
- The setting describes the extension's handling of a model verdict, not the global permission system.

Update:

- `src/config.ts` — runtime type, defaults, validation, global/project merge behavior.
- `schemas/config.schema.json` — accepted values and default.
- `config/config.example.json` — document both modes.
- `README.md` — explain the boundary and examples.
- `src/command.ts` / config command — show and edit the setting if the interactive configuration command exposes extension fields.

Use one name consistently. Do not call it `ask`; `ask` is the permission-system policy state, while `defer` is the authorizer-chain verdict.

### 2. Expand the reviewer output contract

Do not require the model to emit `defer`. The model should continue to return only its assessment:

```json
{
  "risk_level": "low|medium|high|critical",
  "user_authorization": "unknown|low|medium|high",
  "outcome": "allow|deny",
  "rationale": "..."
}
```

`defer` is an extension-side handling decision. This is safer because the model cannot directly choose whether a denial becomes a human prompt or a terminal block.

Update `src/policy.ts` to make this explicit in the fixed protocol:

- retain model outcomes `allow` and `deny`;
- state that the extension maps `deny` according to `denyBehavior`;
- remove any suggestion that the model should emit `ask`.

Retain the operator policy's risk vocabulary, but correct `medium` spelling in examples and documentation.

## Phase 2 — Implement the behavior

### 3. Centralize verdict mapping

Add a small pure function, preferably in `src/reviewer.ts` or a new `src/verdict-handling.ts`:

```ts
function mapAssessmentToAuthorizerVerdict(
  assessment: ReviewAssessment,
  denyBehavior: 'deny' | 'defer',
): AuthorizerVerdict
```

Rules:

- `allow` always returns `{ kind: 'allow' }`.
- `deny` returns `{ kind: 'deny', reason }` in strict mode.
- `deny` returns `{ kind: 'defer' }` in advisory mode.
- Record the model rationale in the review log in both modes.
- Do not include a denial reason in a `defer` verdict; it is not a terminal denial, although the rationale can be logged or surfaced as prompt context if the permission-system API supports that separately.

This avoids duplicating mode logic in the main callback and makes the security-sensitive rule unit-testable.

### 4. Change circuit-breaker behavior consistently

Current circuit-breaker-open handling returns `{ kind: 'deny' }` directly. In advisory mode it must return `{ kind: 'defer' }`, otherwise the package still hard-denies after repeated denials.

Keep the existing strict-mode behavior unchanged.

Log distinct outcomes:

- `outcome: "deny"` for strict terminal blocks;
- `outcome: "defer"` plus a category such as `advisory-deny` for advisory-mode model denials;
- `outcome: "defer"` with the existing failure category for provider/parse failures.

Do not count advisory-mode model denials as terminal denials for a circuit breaker whose purpose is to stop repeated hard blocks. Decide separately whether repeated advisory denials should still open a “review degraded” circuit; the safer default for the requested UX is to record them but defer rather than block.

## Phase 3 — Configuration and loading

### 5. Validate policy defaults and scope merging

The package supports global and project configuration. Verify that the built-in operator policy is used when no `additionalPolicy` is configured. Verify that `additionalPolicy` is appended only when present and does not replace the built-in policy unexpectedly.

Verify that `denyBehavior` follows the same precedence rules as the other scalar settings:

- project value overrides global value;
- invalid configuration disables automatic decisions or falls through safely;
- missing value defaults to strict `deny`.

Avoid a permissive fallback when the new field is malformed. A malformed advisory setting should not accidentally enable or disable terminal denial.

### 6. Keep package and extension identities coherent

The vendored package currently has the unscoped name:

```json
"name": "pi-permission-auto-review"
```

The Pi package entry still points to the installed npm package. Do not switch Pi to the fork until the fork builds and tests successfully. When switching later, remove the npm auto-review entry and add the local package path; never load both registrations simultaneously.

## Phase 4 — Tests

### 7. Unit-test verdict mapping

Add tests for:

- allow in strict mode → allow;
- allow in advisory mode → allow;
- deny in strict mode → deny with rationale;
- deny in advisory mode → defer;
- circuit open in strict mode → deny;
- circuit open in advisory mode → defer;
- provider failure → defer in both modes;
- invalid JSON/schema response → defer in both modes;
- unknown configuration value → validation failure, not advisory behavior.

These tests must exercise the public authorizer callback or the extracted mapping function. Do not test only string constants.

### 8. Test the actual chain boundary

Add an integration-style test using the permission-system authorizer contract:

1. resolve an `ask` request;
2. run the forked authorizer;
3. verify that advisory model denial reaches the terminal human prompt as `defer`;
4. verify that strict model denial becomes a terminal denial;
5. verify that an underlying deterministic `deny` never invokes the reviewer.

The last test prevents a false claim that this fork can override the permission system's own deny rules.

### 9. Test prompt and policy behavior

Test that the generated system prompt:

- accepts only `allow` and `deny` model outcomes;
- does not contain the invalid `medim` spelling;
- explains that advisory mode maps a model denial to `defer`;
- still treats transcript and tool content as untrusted evidence.

## Phase 5 — Operational validation

### 10. Build and load the local package

Before changing Pi's package reference:

- install or expose the package's declared build dependencies using the repository's supported package workflow;
- run typecheck;
- run tests;
- build `dist/`;
- confirm the generated `dist/index.js` contains the new built-in policy and behavior;
- start Pi with the local package in an isolated test configuration.

Do not hand-edit `dist/index.js`; treat it as a build output.

### 11. Validate with a test matrix

Exercise at least:

| Action | Expected advisory behavior |
|---|---|
| read-only local command | allow or normal prompt according to policy |
| bounded file edit | model deny becomes prompt, not block |
| `git reset --hard` | only prompt if the underlying permission policy does not deny it |
| secret-file read | underlying deterministic deny remains a deny unless that rule is removed |
| external-directory access | reviewer allow may still defer because of permission-system caps |
| provider timeout | normal prompt |
| malformed reviewer response | normal prompt |
| repeated reviewer denials | normal prompt in advisory mode |

This matrix exposes the difference between reviewer advisory behavior and permission-system hard policy.

## Phase 6 — Decide what “no hard denies” means

There are two possible end states:

### A. No hard denies from the model reviewer — recommended

- Set `denyBehavior` to `defer`.
- Retain hard denies in `pi-permission-system` for secrets and catastrophic commands.
- The model can never block; deterministic safety rules still can.

This preserves a safety floor while eliminating the current frustrating model-driven blocks.

### B. No hard denies anywhere — not recommended

- Set `denyBehavior` to `defer`.
- Remove or convert every `deny` rule in `pi-permission-system`.
- Verify no path, bash, MCP, skill, external-directory, or subagent rule adds a deny.
- Accept that every model and tool mistake reaches the human prompt only if a prompt-capable execution context exists; headless contexts may still fail closed or deny.

This is functionally close to YOLO with prompts removed from the model-review layer. It is not a meaningful security boundary.

## Recommended implementation order

1. Add `denyBehavior`, defaulting to `deny`.
2. Centralize model-verdict mapping.
3. Make circuit-breaker-open mode-aware.
4. Add unit and chain-boundary tests.
5. Fix policy/schema spelling and documentation.
6. Build and run the local package without changing Pi's active package reference.
7. Switch Pi to the local package only after validation.
8. Remove the duplicated policy text from `pi/auto-review-config.json` only when the local package is activated.
9. Enable advisory mode.
10. Keep deterministic permission-system denies unless you explicitly choose the higher-risk end state.

## Revision Log

- 2026-08-04: Initial plan. Defined strict versus advisory handling, separated model verdicts from permission-system `defer`, and documented the underlying deterministic-deny boundary.
- 2026-08-04: Revised policy placement. The current operator policy will become the fork's built-in default; `additionalPolicy` remains supported but is no longer required in settings.
