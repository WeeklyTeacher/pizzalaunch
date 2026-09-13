# Pizza Launch development contract

Work only in this repository. Required overhaul branch: `feat/astra-overhaul-20260913-101719`.

## Safety

- Never reset, clean, force-push, merge main, use `git add .`, publish Roblox, enable production DataStore access, buy assets, or create paid products.
- Preserve unexplained changes. Stop for wrong branch, unexplained source edits, failed recovery integrity, or failed GitHub authentication.
- Canonical recovery inputs and the tracked recovery place are immutable. Generated places, Studio saves, screenshots, tools, and bulk QA evidence belong in ignored `.qa-artifacts`; never commit them.
- Preserve the pre-existing untracked `PizzaLaunch-Astra-Working_1_0.rbxl` untouched.
- Workspace must have no `$path`; `$ignoreUnknownInstances` must remain true. Never modify, replace, or delete `StudioRestaurant`.
- Map the Baseplate transform with `CFrame`, never `Position` alone: real fresh-build QA found that Position was lost in serialization. Run the actual binary ground-parity test after any mapping change.
- Keep the documented `Technology=Future` serialization seed alongside modern LightingStyle/quality properties until fresh Studio tests prove it unnecessary. Without it, Studio migration overwrote the modern settings (rbx-dom #637). Do not assign protected lighting controls from runtime scripts.
- Cosmetic pizza/customer/booth geometry must remain separate from unchanged competitive proxies. Validate new art in a fresh place as well as live sync; inspect actual assembly mass and target visibility when relevant.
- Stage exact intended paths. Review full diff, run checks, commit coherent passing slices, push immediately to the required branch, and verify the remote hash.

## Game contracts

- Exactly two launcher modes: FREE PLAY and 1-MINUTE RECORD RUN. One physical launcher prompt and one mounted picker. Free Play is untimed; Record Run has a three-second countdown and 60-second run.
- Server owns lease, character mounting, mode, time, physics, hits, scoring, rewards, customers, purchases, persistence, and cleanup. Client payloads are requests.
- A bystander must never alter the current operator's competitive state or physical lane. Walking activities have separate order state and award session coins only.
- Runner/queue/shared progress use `RestaurantActivity`, not the launcher's GameState handler. Preserve clearance corners around the far-side bin/bench and the crosswalk return route.
- Preserve `PizzaLaunch_RecordRun_AllTime_v1`, numeric historical records, all six table centers, ballistic anchors, and launch tuning unless a replacement is explicitly tested and documented.
- Preserve desktop, landscape touch, tablet, controller, immediate upgrades visibility, spawn route, and interior return cue.
- Cleanup is idempotent and invalidates stale asynchronous work across exit, death, removal, replacement, disconnect, mode switches, countdown cancellation, and results.

## Workflow and evidence

Read `docs/GAME_STATE.md`, `docs/COUNCIL_DECISIONS.md`, `docs/TEST_MATRIX.md`, `docs/LAUNCHER_SYSTEM.md`, and recent `BUILD_LOG.md` entries before editing. Earlier roadmap and build-log entries are historical and can contradict the current source.

Use the six Astra Ultra council specialties requested for this overhaul, in bounded parallel assignments with disjoint file ownership. Lead reconciles findings and reviews integrations. Agents must not commit independently.

Required checks: `scripts/Test-RecoverySafety.ps1`, `scripts/Test-RecoveryContracts.ps1`, all behavioral tests, `rojo build default.project.json` to an ignored output, and `git diff --check`.

Use the connected local test Studio when available; inspect Output. Never claim runtime tests from source checks or screenshots from previous runs. Record unavailable cases as NOT RUN. A source-only Rojo build cannot prove preservation of unknown Studio geometry. Do not use the recovery generator as the normal build path.

For geometry tests, pinned Lune 0.10.5 has a `CFrame.lookAt` convention mismatch; use a verified explicit right/up/back basis. Native Roblox uses its ordinary API. For mobile QA, use simulator ActualResolution and read the actual viewport and CoreUI inset; safe-content containment alone does not prove target visibility. Restore device simulation and temporary QA camera overrides after testing.

Maintain game state, council decisions, test matrix, and build log at each checkpoint. Record pushed commit hashes in the next documentation checkpoint, avoiding self-referential commit hashes.
