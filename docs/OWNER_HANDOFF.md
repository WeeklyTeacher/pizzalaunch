# Owner handoff

Required branch: `feat/astra-overhaul-20260913-101719`. Final gameplay source checkpoint: `0088c7079be15bfc8b03a40db15496f0c74f0a01`; subsequent commits document monetization preparation and verification. Use the branch HEAD for the complete records. Nothing was published or merged into main.

## What is implemented

Correctness repairs cover immutable Record Run submissions, safe best-score retries, owner-only hitbox policy, picker/rejected-shot recovery, round prop visibility, character/lease cleanup and avatar projectile isolation. Focused modules now own launcher lease, shot policy/physics, delivery resolution/scoring, progression, persistence, input, camera, UI, onboarding and feedback.

Walking players have independent Takeout Runner orders, 8 coins plus an optional 2 for quick delivery, two short destinations, FIFO launcher reservations, honest unlimited Free Play status, NOW PLAYING and contributor-only restaurant rewards. No third launcher mode or paid priority was added.

The art checkpoint reveals the floor, simplifies signage, adds an oven hero, detailed pizzas, six articulated customers and quiet booth palettes. Responsive components cover walking, modes, competitive play, results, upgrades, runner/queue and Chef Book. Chef Book adds mastery, service stamps, completed-run tiers and four earned nameplates; coins and upgrades remain session-only.

## Verified evidence

All 49 source files compile, 31 behavioral specs pass, recovery safety/contracts pass and a fresh Rojo build succeeds. Fault tests cover profile load failure, serialized writes, uncertain responses, session fencing, rapid rejoin and shutdown. Actual module integration uses four player boundaries, but this is not a four-client Studio test.

Native Studio checks include physical mount/picker, launches/rejection recovery, countdown and natural Record Run completion, results/exit/death/respawn, full customer service lifecycle, ground/lighting and projectile mass/collision. Real two-client tests covered occupied Free Play, reservations, pass/approach and runner rewards during another player's Record Run. Five real walking deliveries unlocked and equipped Tomato Chef. Final extracted delivery code produced three Perfects, 91 coins, round two and mastery stamps in a fresh build; the synchronized place also completed a delivery.

Layouts were inspected at exact 667x375 and 874x402 landscape, 1024x768 tablet, desktop and console simulation. These are host Studio simulations. Detailed evidence, qualifications and Output observations are in [TEST_MATRIX](TEST_MATRIX.md).

## Owner's next validation

1. Test four actual players: unlimited Free Play contention, queue cancellation/reservation/death/disconnect, and repeated runner play. The available four-client launch stalled before usable connections; human abandonment is unmeasured. Add a separate practice lane only if this evidence justifies one.
2. Test physical mobile two-finger aim/charge/release, controller navigation/buttons, safe areas and sustained frame time with four avatars and effects. Controller layout/focus was checked, but the tool could not inject reserved controller buttons. Desktop frame samples do not prove low-end phone performance.
3. In a separately approved test experience, validate real profile load/save budgets, two-server handoff, reconnect, shutdown and analytics ingestion. This run never enabled production access. Unconfirmed gains can be lost during a crash/outage; saved history is protected. A profile may wait for its 120-second lease plus retry delay/service latency.
4. Verify the owner-authored place separately. Source-only builds omit unknown Studio geometry. The original working session kept Soft lighting while fresh builds verified Realistic using the documented serialization seed. Never replace Workspace or StudioRestaurant to force parity.

## Reproduction and boundaries

Run `scripts/Test-RecoverySafety.ps1`, `scripts/Test-RecoveryContracts.ps1`, then `rojo build default.project.json -o .qa-artifacts/PizzaLaunch-review.rbxl`. The expected live-sync server is `127.0.0.1:34872`. Bulk evidence, generated places and draft files remain ignored under `.qa-artifacts`; original owner/recovery files are preserved.

Read [GAME_STATE](GAME_STATE.md), [PROFILE_SYSTEM](PROFILE_SYSTEM.md), [ART_PROVENANCE](ART_PROVENANCE.md) and [MONETIZATION_PREPARATION](MONETIZATION_PREPARATION.md) before extending the systems. GameService and the client bootstrap still contain integration/trajectory code; this is modularized code, not a claim that every large function has disappeared.

Paid fulfillment, products, passes, IDs, prices, prompts and live sale configuration remain absent. Future cosmetic ownership requires explicit approval, durable restoration and neutral physics/visibility. Do not publish, enable production stores, merge main or spend Robux as an implied follow-up.
