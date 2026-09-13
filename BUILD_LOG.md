# Pizza Launch Build Log

## 2026-09-13 — Astra overhaul baseline and Milestone 0 in progress

- Required branch confirmed: `feat/astra-overhaul-20260913-101719`; starting HEAD and GitHub branch both `81e3f930b6210359e6ee4c64a90f0b83e9c7dac8`. Origin is WeeklyTeacher/pizzalaunch. Git push dry-run passed; GitHub CLI is absent, so Git verifies access directly.
- No pre-existing tracked/staged changes. Preserved the untracked local `PizzaLaunch-Astra-Working_1_0.rbxl`; it is not a build target or staging input.
- Read all tracked source and testing/recovery scripts, requested project documentation/configuration, recent history/tags, and historical screenshot evidence before edits. Six Astra Ultra council specialties audited actual source in bounded waves. Current decisions and acceptance criteria are in `docs/COUNCIL_DECISIONS.md`.
- Baseline recovery safety and contract tests passed. Transfer SHA-256 remains `73B3D5DF3B72F9B13350790759B715BC0E510BB7A41FED3C895F58BD17F11088`; tracked recovery artifact remains `8C1C1B815626970FE6C228247338D52637B15B379022BD5A217AE936B976EE4B`.
- Rojo 7.7.0 responds at `127.0.0.1:34872`. Read-only connected Studio inspection found unpublished `pizzalaunch` in Edit mode, server source present, mapped Baseplate, no `StudioRestaurant`. Initial Output has an existing MaterialManager plugin profiling stack; no gameplay runtime test has yet been performed.
- Added durable agent instructions, game state, council decisions, and test matrix. These supersede conflicting historical plans, not historical test evidence.
- First implementation: LayoutService captures authored presentation once and owns round activation; PropService restores pose then reapplies current layout, with monotonic reset tokens. Actual Luau behavioral test passed for rounds 1/3/4, downward transitions, repeated startup/reset, inactive knock rejection, and stale delayed resets. The two frozen source hashes were replaced by this executable regression test; canonical integrity/mapping guards remain.
- Milestone 0 is IN PROGRESS, not released. Studio runtime regressions, complete integrated checks, fresh build, review, commit and push remain pending. No publishing, paid products, live DataStore access, recovery-input changes, or StudioRestaurant edits.

## 2026-09-05 — surgical launcher onboarding correction

### User-reported failures and root cause

- The visible `HOW TO PLAY` button did nothing useful and was no longer wanted. Its replay-only button, click connection, and replay state were removed; the nonblocking automatic first-visit route remains.
- `UPGRADES` was missing at first spawn and appeared only after gameplay. The root cause was `updateRecordUI()` gating the button on `(operating or onboardingCompleted)` and also hiding it for any timed session. `onboardingCompleted` becomes true only after a server-accepted launch, which directly caused the delayed appearance.
- Launcher guidance still failed from inside the restaurant. The spawn-side route existed, but it ended outside and had no reliably visible interior-camera direction sign or interior return route.

### Focused correction

- `src/client/init.client.luau`: removed the HOW TO PLAY control/handler/replay state; initialized UPGRADES visible on creation and made only the mounted mode picker temporarily hide it; added a raycasted interior return route tied to the authoritative launcher anchor; hid first-visit interior guidance on mount; reset stale Record Run fire-button state when the mode picker opens.
- `src/server/WorldBuilder.luau`: added a camera-facing, distance-limited interior `PIZZA LAUNCHER / TURN AROUND / FOLLOW THE ARROWS` sign and an exact-anchor `STEP HERE TO PLAY` label. The existing `USE LAUNCHER` prompt remains keyboard `E`, controller `X`, and touch-clickable.
- `scripts/Test-RecoveryContracts.ps1`: replaced the obsolete HOW TO PLAY contracts with absence, deterministic persistent-menu, interior-camera guidance, mount-label, and mode-restart contracts.
- `E:\projects\roblox\LAUNCHER_SYSTEM.md`: added the reusable deterministic-menu, real-camera validation, dead-tutorial removal, and persistent-UI/state-boundary rules.

### Verification performed

- `Test-RecoverySafety.ps1`: PASS. `Test-RecoveryContracts.ps1`: PASS.
- `rojo build`, `rojo sourcemap`, and `git diff --check`: PASS. Final artifact `.qa-artifacts/surgical-correction-final.rbxlx` SHA-256 is `0B274E1CBF543FC65BDFECF04EA612ED75A5882994CA23A490E4AAA8892C43A2`. Rojo remained available at `127.0.0.1:34872`.
- Disposable Studio, desktop viewport: PASS for fresh spawn with HOW TO PLAY absent, immediate UPGRADES visibility, opening the real upgrades panel before gameplay, and a readable interior direction sign from the player camera.
- Studio iPhone 17 Pro landscape: PASS for fresh spawn, HOW TO PLAY absence, immediate UPGRADES, interior sign and floor arrows, `STEP HERE TO PLAY`, touch `USE LAUNCHER`, mode picker, Free Play launch, exit with UPGRADES restored, full 60-second Record Run expiry, compact results, Choose Mode, and entering another mode. Screenshots are in `.qa-artifacts/surgical-screenshots/`.
- Studio Output: no game-script exception or stack trace. The unpublished disposable place produced the expected OrderedDataStore-unavailable warning and used the existing Studio fallback; no live persistence claim is made.
- During the run, switching from completed Record Run to Free Play exposed a stale `TIME!` fire-button label. The picker now calls the existing input reset before another mode; the final contract and follow-up play check cover the clean next-mode state.

### Not completed in this correction pass

- A new two-client Studio session and controller-emulator pass were not repeated because this correction did not change ownership or controller bindings. Their existing server/input contracts remain passing. No push or publish was performed.

## 2026-09-05 — launcher onboarding and unified mode selection

### Investigation and decisions

- Audited the Rojo mappings, all launcher/mount/prompt/UI/arrow/trajectory/timer/Record Run/leaderboard paths, current git state, parent Roblox documentation, and a disposable Studio build before editing. Preserved the pre-existing QA checkpoint edits, `.qa-artifacts/`, and `recovery/PizzaLaunch-before-QA.rbxl`.
- The launcher previously exposed two separate prompts that silently chose Free Play or Record Run. The operator pose was behind/inside decorative press geometry, and another player could not see a useful busy state because the shared prompt was disabled.
- `TRAIL READY 42` was client debug output: seven decorative arrows with six parts each (shaft, two heads, and three pepperoni), not gameplay state. A second per-frame diagnostic also replaced the walk hint with player/arrow coordinates. Both player-facing debug paths are removed.
- Council decision: retain one server-owned launcher lease and outer mount state, then add the explicit mounted submodes `select`, `freePlay`, and `recordRun`. Both modes now share mount, aim, launch, projectile, cleanup, camera, and exit behavior.

### Implementation

- Added permanent `PIZZA LAUNCHER / WALK HERE TO PLAY` signage, an exact pizza-shaped use pad, one `USE LAUNCHER` prompt (`E`, controller `X`, and clickable touch), and six client-local pizza arrows raycast onto approved walkable surfaces. The last waypoint, highlight, prompt, distance validation, use pad, and mounted pose all resolve to the same authoritative interaction anchor at the clear approach point.
- Replaced the competing world Record Run prompt with a noninteractive two-mode explanation. Mounting now opens an equal two-choice picker: `FREE PLAY — Practice launches with no time limit.` and `1-MINUTE RECORD RUN — Score as many points as you can in 60 seconds.`
- Added visible Change Mode and Exit actions, explicit `FREE PLAY • NO TIMER`, compact timed HUD/countdown/results, post-run Choose Mode, gamepad focus/aim/RT launch/B exit, touch-responsive picker and controls, cleanup epochs for delayed callbacks, death cleanup, and server validation for lease, pose, mode transitions, countdown/run phase, and permitted launches.
- The occupied prompt remains visible as `OCCUPIED / ANOTHER CHEF IS PLAYING`; the server rejects non-owner mounting without mutating the owner's state.
- Kept first-visit completion session-local because the only persistence store is the competitive ordered record store. Guidance fades after the first server-accepted launch; the permanent sign/pad and How to Play replay remain.
- Fixed an Output-audit regression in the pre-existing Studio leaderboard fallback by forward-declaring `setBoardText` before `setSampleBoard` calls it.
- Updated `README.md`, expanded launcher/recovery contracts, and created shared reusable guidance at `E:\projects\roblox\LAUNCHER_SYSTEM.md` without moving live Pizza Launch code or changing Rojo mappings.

### Verification performed

- `Test-RecoverySafety.ps1`: PASS.
- `Test-RecoveryContracts.ps1`: PASS, including prompt uniqueness, anchor/pad agreement, raycast placement, debug-text absence, server mode gates, occupied behavior, controller bindings/focus, and the Record Run board-helper ordering regression.
- `rojo build` and `rojo sourcemap`: PASS. Final artifact `.qa-artifacts/onboarding-final-fixed.rbxlx` is 245,770 bytes, SHA-256 `399BCB714D70C1181F1B694B0528B4A9B57A0029C0F0BF1E0C666870DBD562BC`.
- `git diff --check`: PASS. Rojo remained reachable on `127.0.0.1:34872`.
- Disposable Roblox Studio desktop play: PASS for fresh-spawn attraction visibility, following the real route, final prompt, mount/orientation, equal mode picker, Free Play/no-timer HUD, five accepted Free Play launches, exit, reduced returning-player guidance, How to Play replay, Record Run 3-2-1 and 1:00 timer, three accepted timed launches, full 60-second expiry, compact results, Choose Mode, and switching directly to Free Play without remounting. The final countdown was rechecked after removing an overlapping duplicate toast.
- Studio iPhone 17 Pro landscape simulation: PASS for entrance/sign/route readability, responsive picker, touch Free Play selection, aim pad, charged launch/reload, and touch exit.
- Studio Controller Emulator: PASS for controller X mounting, initial picker focus, Button A mode activation, left-stick aim, RT charged launch, and Button B exit.
- Latest clean final-artifact Studio log: no game-script error/stack patterns. The earlier `RecordRunService:41` error was reproduced, fixed, contract-protected, rebuilt, and absent from the clean rerun.

### Remaining verification limits

- Automated aiming produced accepted projectiles but did not land a scored delivery; delivery score changes and leaderboard persistence retain their existing server code/contracts but were not newly demonstrated by this UI automation.
- Studio's Server and Clients command was exercised, but this installation spawned only the server process and would not add client windows. A genuine two-client occupied-state interaction was therefore not completed; ownership isolation is covered by the server validation and automated contracts.
- Live OrderedDataStore access was unavailable in the unpublished disposable place. The session-best fallback/result copy was exercised; live global record writes were not claimed.
- No push, publish, DataStore migration, Rojo mapping change, or unrelated feature removal was performed.

## 2026-08-31 — Studio Play usability QA checkpoint

- Clean source baseline: pushed commit `9f70415c578542b69ddbc64a45201e185d1e5e1a` on `feature/sightline-onboarding-20260831`.
- Restore checkpoint: pushed annotated tag `checkpoint/before-studio-qa-20260831`; focused branch `qa/studio-play-usability-20260831`.
- Required pre-edit backup: `recovery/PizzaLaunch-before-QA.rbxl`, SHA-256 `FB7F35AF38E31C08B1014084FDE5767A580FB35906C248C8036E81667679508A`. Existing Transfer and merged-recovery backups were not edited.
- Test-access gate: Roblox Studio is installed and controllable in this session. The restored path builds a disposable QA place, opens that copy in a separate Studio process without Rojo sync, enters Play mode, captures the Play viewport, and inspects the captured image. The user's already-open Studio process remains untouched.
- Actual baseline Play evidence found the two reported failures: no usable floor arrows were visible at fresh spawn, and the small control below `UPGRADES` rendered as unreadable symbols. Source tracing found the arrow parts centered at `Y=-0.39` below the generated Baseplate's `Y=0` top surface.
- Fix: moved the complete arrow geometry above the floor, enlarged its cheese and pepperoni silhouette, and replaced the mystery control with a wide, high-contrast `HOW TO PLAY` GothamBold button. The route, final marker, highlight, proximity state, and replay continue to derive only from the authoritative `LauncherInteractionAnchor` attached to the real `LauncherPrompt`.
- Scope protection: no Workspace mapping, world layout, launcher physics, camera coordinates, customer logic, scoring, upgrades, Record Run, persistence, restaurant, or street source was changed.

`AUTOMATED TEST: PENDING`

`STUDIO PLAY VISUAL TEST: PENDING`

`MANUAL USER TEST STILL NEEDED: yes`

## 2026-08-31 — Pizza Trail destination correction

- Clean starting state: pushed commit `5251bbbbc31539edcf18f7093f9795a0643e75a6` on `feature/sightline-onboarding-20260831` with no local changes.
- Root cause: the prior final marker ended at `Z=74.2` and the old green `OperatorSpot` ring was at `Z=73`, both underneath the decorative `MAMA MIA PIZZA PRESS`, whose body reaches forward to `Z=80`.
- Added one explicit `LauncherInteractionAnchor` on the clear approach floor at `(0, 2.4, 84)`, one player-step in front of the press. The actual `LauncherPrompt` is now a child of this anchor, and the server's mount-distance validation uses the same anchor.
- Removed the obsolete under-press `OperatorSpot`. All seven trail positions are now generated from fixed safe offsets relative to `LauncherInteractionAnchor`; the final offset is zero, the final arrow points toward the cannon, and the local interaction highlight and proximity check use only that anchor. The onboarding client no longer searches for `OperatorConsole`, decorative ovens, signs, or nearby launcher-named models.
- The anchor and trail are invisible/faded while mounted, so the existing clear aiming frustum and relocated `NEIGHBORHOOD FAVORITE` sign remain protected. No launcher physics, camera coordinate, restaurant layout, customer, scoring, upgrade, Record Run, DataStore, or Rojo mapping behavior changed.
- Verified: `rojo build default.project.json` produced a 233,016-byte place with SHA-256 `DDC5168A81B8BE7B1EC535C58773106DAF8B10F3C2B3ABA08012FD70557FEE96`; recovery safety and all recovery/anchor contracts passed; `OperatorSpot`, the prior absolute trail route, and client `OperatorConsole` destination search are absent; protected gameplay/configuration files have no diff; and `git diff --check` passed.
- Roblox Studio was not interactively driven in this command-line run. Fresh spawn → follow trail → stand on final arrow → prompt appears → press `E`/tap → mounted sequence remains the explicit manual Studio validation and is not claimed as runtime-tested here.

## 2026-08-31 — onboarding visibility follow-up

- Clean starting state: pushed commit `3a221fe93745880c1cf1a6e032e4dd2487f411bf` on `feature/sightline-onboarding-20260831` with no local changes.
- Removed the small maroon/yellow cannon distance billboard and every player-facing grid-unit reference. Wider Plates now confirms its delivery-zone change as a percentage instead of an engine distance.
- Enlarged the seven client-only floor arrows to a wide neon cheese silhouette with three large round pepperoni pieces per arrow. The first two begin directly ahead of the authored spawn, the route curves across the open forecourt, and the final two sit on top of the launcher platform. Markers remain flat, shadowless, non-colliding, non-touching, and non-queryable.
- Simplified walking guidance to one compact bottom hint: `Follow the pizza arrows to the Pizza Cannon!`, changing at interaction range to `Press E or tap the Pizza Cannon to start!`. The trail remains visible through the approach, fades on mount, starts fresh every client play session, restores before completion after respawn, and reappears on explicit `? HELP` replay—even if Help is requested while mounted.
- Preserved the relocated full-size `NEIGHBORHOOD FAVORITE` sign and its camera-frustum contract. No world geometry, launcher/camera coordinate, customer system, Record Run logic, scoring, upgrade panel, Rojo mapping, or DataStore code changed.
- Verified: `rojo build default.project.json` produced a 232,392-byte place with SHA-256 `5A274E2D352842BEF6AC22534E8BE32F70E7091CF952AF14EF984AC423CEE7B4`; recovery safety and all recovery/onboarding visibility contracts passed; source search found no player-facing `stud`/`studs` copy or removed beacon path; the sign remains outside the launcher frustum; and `git diff --check` passed.
- Roblox Studio was not interactively driven in this command-line run. Fresh-Play arrow visibility/orientation, following the route, mount fade, in-game Help replay, and the free-play/Record Run/upgrades/aiming sequence remain an explicit manual Studio verification rather than a claimed runtime result.

## 2026-08-31 — launcher-sightline/onboarding restore checkpoint

- Clean baseline commit: `9f41fe56dc2a66998cebc0954dc42a220db7c0cc` on the pushed `feature/customer-events-progression-20260831` branch.
- Pushed annotated restore tag: `checkpoint/before-sightline-onboarding-20260831`.
- Focused working branch: `feature/sightline-onboarding-20260831`.
- Pre-edit source/contracts confirm the existing free-walk spawn, canonical launcher enter/exit and server-authoritative launch paths, customers and six tables, scoring/coins/upgrades, splats/reactive props, free play, and the one-minute Record Run remain present. This is source verification only; no new Studio runtime claim is made at the checkpoint.
- Scope boundary: relocate the obstructing progression sign without changing gameplay coordinates, and add a client-local, non-colliding first-time path tutorial. `Workspace`, restaurant/gameplay models, server services, and `default.project.json` remain protected.

### Focused sightline and first-pizza onboarding changes

- Relocated the full-size `NEIGHBORHOOD FAVORITE` progression sign from the launcher axis at `(0, 24, 70.8)` to the right exterior façade at `(42, 27.2, 73.4)`. Its nearest edge is approximately 72.9 degrees off the camera axis, outside the mounted camera's 28.5-degree horizontal half-frustum; the same clearance applies at low, medium, and high aim because those angles move the cosmetic aim rig/trajectory, not the fixed launcher camera. Added the permanent source rule that future décor must stay outside the camera-to-playfield corridor. No other world geometry moved.
- Added seven client-only cheese-arrow/pepperoni trail markers along the real exterior walk route from `WALK_SPAWN_CFRAME` to the regular launcher console. Every part is anchored, non-colliding, non-touching, non-queryable, shadowless, and locally pulsed; the last markers sit on top of the cannon platform. A distance-updating launcher beacon, compact bottom hint, and console highlight advance from follow-trail to `E`/tap interaction range.
- Reworked the existing tutorial card into a compact, non-active first-pizza corner hint with separate desktop and touch instructions. Onboarding completes only after the server accepts a launch, then fades into the non-modal `YOU'RE COOKING!` banner. Completion remains session-local, launcher exit/re-entry does not restart it, incomplete respawns restore it, and the `? HELP` button can explicitly replay it.
- Verified: `rojo build default.project.json` produced a 233,985-byte place with SHA-256 `CA26CB7F521D541FA4F99D132461A837E55634F4B5568F7B7273AAB6457ABB16`; recovery safety and all recovery/onboarding contracts passed; the old centered sign coordinate is absent; `default.project.json`, shared gameplay config, launcher/customer/Record Run/DataStore services, and protected Transfer-invariant services have no diff; `git diff --check` passed. Recovery/Transfer artifacts remain unchanged.
- Roblox Studio is installed but was not interactively driven by this command-line run. Manual Studio verification remains required for actual arrow orientation/pulse and UI composition on desktop/touch, walking the route, low/medium/high mounted views, accepted first launch, exit/re-enter launch, respawn restoration, and the complete free-play/Record Run regression sequence. No runtime or live DataStore claim is made.

## 2026-08-31 — customer/events progression checkpoint

- Clean starting commit: `2216dd19fc8dbe5e4b90c9f4bd977bc193542183` on `visual/protected-world-expansion-20260831`, matching its pushed remote.
- Pushed annotated restore tag: `checkpoint/before-customer-events-progression-20260831`.
- Working branch: `feature/customer-events-progression-20260831`.
- Baseline artifact hashes remain unchanged: recovery build `8C1C1B815626970FE6C228247338D52637B15B379022BD5A217AE936B976EE4B`; Transfer backup `73B3D5DF3B72F9B13350790759B715BC0E510BB7A41FED3C895F58BD17F11088`.
- Source/contract baseline confirms free walking and canonical launcher cleanup, enter/exit and server-authoritative aiming/launch, six tables and the complete customer lifecycle, scoring/coins/upgrades, splats/reactive props, free play, and the one-minute Record Run. Runtime behavior still requires Studio play verification; this checkpoint does not claim a new live playtest.

### Customer experience, shift events, and visible progression

- Replaced customer-triggered center feedback with a non-active side card: fixed-size typography, wrapped short copy, calculated card height, initial portrait icon, name/personality/patience labels, close button, and a 4.5-second fade. Entering the launcher immediately hides it; it never binds movement or launch input.
- Added complete dialogue pools for all 12 rotating identities across greeting, waiting, happy, wrong-pizza, and leaving states. Existing Entering → WalkingToSeat → SeatedWaiting → Served → HappyReaction → Eating → Leaving → Despawn behavior remains the lifecycle authority. Patience is now a non-punitive `:)` / `...` / `!` marker with matching border color; harmless customer hits still splat/react and recover.
- Added a server-wide replaying event cycle outside Record Run: Dinner Rush reveals and walks in an extra customer and pays +4 for service within ten seconds; Birthday Table targets a group-capacity booth with two party settings, +24 coins, confetti, and a room cheer; Food Critic marks one customer `STAR`, pays +32 Perfect / +20 Great, and saves the combo if the bonus is missed. Events use a shallow side banner and expire without penalties.
- Made upgrade effects measurable and visible. Wider Plates scales a real `DeliveryZone` touch part and matching ring; Speedy Oven reports the remaining authoritative reload; Hotter Oven displays its exact +4%-per-level range and strengthens oven glow; Bigger Tips reports the additional multiplied coins. Record Run continues using fixed power, reload, and zone scaling and never receives event/economy bonuses.
- Added session progression décor at total upgrade levels 1/3/6 (menu trim, golden oven badge, neighborhood-favorite sign), a low-volume replacement-customer door chime, slowly changing window ambience, and one isolated non-colliding distant street pedestrian. No table, launcher, camera, customer entrance, or shot-arc coordinate changed.
- Intentionally extended `CustomerService` while keeping `InteractionService`, `LayoutService`, `PropService`, bootstrap, `RecordRunService`, DataStore names, and `default.project.json` protected. Recovery contracts now preserve the lifecycle and new behavior explicitly rather than incorrectly requiring the enhanced customer module to remain byte-identical.
- Verified: `rojo build` produced an 86,411-byte place (`E5FF03278029216CA1362932DFF9D2A4BFBDAB5FACE870977F9E9DAAE57B8F76`), recovery safety/contracts passed, all 12 dialogue profiles and five categories passed, all event/upgrade fairness contracts passed, and `git diff --check` passed. Transfer and recovery artifact files were not edited.
- Not claimed as verified in this environment: live Studio UI composition, collision feel, audio balance, event timing, mobile frame rate, or the full walk → talk → launch → serve → event → Record Run → exit/re-enter → launch sequence. Those remain the final manual Studio playtest, including Output inspection.

## 2026-08-31 — protected visual-expansion checkpoint

- Clean baseline commit: `c1abb4ef6ec7f7ad3bb77417d82af78355ed6776` on `recovery/safe-transfer-merge-20260831`.
- Pushed annotated checkpoint tag: `checkpoint/current-working-before-visual-expansion-20260831`.
- Visual work branch: `visual/protected-world-expansion-20260831`.
- Baseline recovery artifact SHA-256: `8C1C1B815626970FE6C228247338D52637B15B379022BD5A217AE936B976EE4B`.
- Source audit confirmed the working launcher, customers/six tables, free play, Record Run, scoring, coins, upgrades/progression, pizza splats, reactive breakable props, player walking, and launcher reset paths before any visual edit.
- Council boundary: the environment pass owns removable perimeter/exterior art; launcher motion is client-only cosmetic feedback after a server-accepted shot; simple anchored parts, six low-cost ambient lights, one disabled-at-idle burst light, and zero-idle-rate particles protect mobile performance; the child-player read is a visible loaded pizza, obvious `Mount Launcher` prompt, lively storefronts, and feedback that never covers the shot.

### Protected visual expansion

- Replaced the 510x190 center-screen round overlay with a non-active 510x78 desktop / 340x58 touch top banner. It slides in, reports the reward and next round, and fades after 2.15 seconds without changing controls, movement, aiming, or launch readiness. The Record Run result surface is also a shallow, non-modal top card instead of a center blocker.
- Kept the authoritative launcher origin, projectile creation, power validation, hit resolution, and cooldown code unchanged. Added a cosmetic crank rig, live pressure readout, angle ticks, server-accepted muzzle flash, flour/cheese particles, oven pulse/steam, reload pizza visibility, and feed-roller motion. The world prompt now reads `Mount Launcher`; the default prompt still displays the `E` key.
- Added runtime models `RestaurantArtPass` and `NeighborhoodStreet`, each marked `VisualExpansion` and `RemovableWithoutGameplayImpact`. Restaurant additions stay on the ceiling, perimeter, corners, or behind the counter. The street adds a continuous walkable road/sidewalk/curb, crosswalk and lane markings, lamps, benches, bins, four fictional storefronts, a pizza van, a delivery scooter, and invisible outer safety boundaries.
- Did not modify `default.project.json`, any DataStore/leaderboard code or name, table/customer positions, shared gameplay configuration, or the Transfer-invariant services. The tracked recovery artifact and Transfer backup remain unchanged at SHA-256 `8C1C1B815626970FE6C228247338D52637B15B379022BD5A217AE936B976EE4B` and `73B3D5DF3B72F9B13350790759B715BC0E510BB7A41FED3C895F58BD17F11088`, respectively.
- Automated verification passed: `rojo build`, `Test-RecoverySafety.ps1`, `Test-RecoveryContracts.ps1`, unchanged core-game diff audit, visual ownership/banner contracts, and `git diff --check`.
- Roblox Studio was not play-tested during this pass. Manual Studio verification remains required for exterior collision/composition, mobile landscape readability/performance, free-play firing, a non-blocking round-clear banner, a complete Record Run, exit/re-entry firing, customer presentation, splats/breakables, and Output errors. No live DataStore claim is made.

## 2026-08-31 — safe Transfer recovery merge

- Created branch `recovery/safe-transfer-merge-20260831` from `620262d`; recorded the clean tracked baseline and the supplied backup hash before source changes.
- Read-only binary inventory of `recovery/PizzaLaunchTransfer.rbxl` found the complete ten-script game and a minimal saved Workspace. The restaurant, tables, launcher, customers, and UI are runtime-built; no Workspace replacement was performed.
- Confirmed `CustomerService`, `InteractionService`, `LayoutService`, `PropService`, and bootstrap are byte-identical to Transfer. Preserved the existing six target coordinates, launcher origin/camera, scoring, coins, upgrades, free play, Record Run, and DataStore name.
- Found and fixed the current-world construction regression: the detailed cannon used undefined `COLORS.orange`, which could stop `WorldBuilder` while creating the launcher.
- Added a selected storefront merge around the existing coordinates: exterior sidewalk, framed façade, central player entrance/exit, customer door openings, canopy, marquee, and planters. Customer spawn points now begin on the exterior forecourt and use the unchanged Transfer side-aisle/customer lifecycle.
- Made Workspace preservation explicit with `$ignoreUnknownInstances: true`, no Workspace `$path`, and a pre-sync safety check that also verifies the Transfer SHA-256.
- Created `recovery/PizzaLaunchMerged.recovery-20260831.rbxl` from the Transfer DataModel at a new path. All ten embedded scripts match reviewed branch source; the Transfer input hash remained `73B3D5DF3B72F9B13350790759B715BC0E510BB7A41FED3C895F58BD17F11088`.
- Automated verification passed: recovery safety/contracts, Transfer-invariant module hashes, customer lifecycle states, launcher/Record Run path presence, undefined color detection, artifact script equality, Rojo build, and `git diff --check`.
- Roblox Studio was not launched in this run. Launcher firing before/after Record Run, live NPC movement through doors, collisions, mobile UI, and final visual composition remain explicit Studio-only checks; no live DataStore claim is made.

## 2026-08-31 — active reliability pass

- Added one idempotent server launcher cleanup path for normal exit, Record Run completion, result exit, respawn, cancellation, and player removal. It clears the launcher lease, active projectile/touch connection, launch debounce/permission, Record Run handoff, and character movement; the client resets charging/input, camera, controls, guide, and launcher UI from the authoritative mode.
- Rebuilt upgrade cards with explicit current-level, owned/available/maxed, BUY/NEED MORE COINS states and server-authoritative effect descriptions. Upgrades are explicitly session-only; tips, delivery radius, reload, and power all apply in the server scoring/launch path.
- Record Run now retries and warns on DataStore failures, avoids duplicate completion submissions, caches board reads/name resolution, and keeps personal-best writes independent from global-board reads. Studio API failures render a labeled sample board rather than “unavailable.”
- Manual Studio requirement for real persistence: **File → Experience Settings → Security → Enable Studio Access to API Services**. This run does not claim published-server DataStore testing.
- Verified here: `rojo build default.project.json -o pizzalaunch.rbxlx`, `git diff --check`, and source-contract checks for all four server upgrade calculations, tracked projectile cleanup, six cleanup-path call sites, retried OrderedDataStore access, Studio sample-board text, and the removed unavailable-result message. Roblox Studio was not installed in this execution environment, so the exact two-run/respawn sequence and visual mobile pass remain the one manual Studio test.

## 2026-08-30 — Record Run council decision

- **Game / Creative Director:** Keep the restaurant and proven launch feel fully visible. Add a bright second console at the existing station so free play remains the default and the timed challenge feels like an in-world arcade event.
- **Roblox Engineer:** Reuse the authoritative projectile resolver and calculate every record point on the server. Isolate run timing, scoring, OrderedDataStore access, and board refreshes in one service with guarded failures.
- **Child Player Advocate:** Use a three-second countdown, one glowing order, a large timer, and a stepped combo multiplier. Near targets start at 100 points; farther targets visibly pay more without extra rules to read.
- **Product / Scope Guardian:** Ship one 60-second all-time record mode, personal best, and top-10 wall. Defer moving targets and additional modes until the fixed-table timing and scoring receive human playtesting.

### Built

- Added a second red `Start 1-Minute Record Run` proximity prompt beside the existing green free-play console. It claims the same validated launcher lease, positions the character correctly, and leaves the restaurant visible.
- Added a server-clock three-second countdown and 60-second run state. Launches are accepted only while the server says the run is active; exiting or respawning cancels cleanly and restores the prior free-play target.
- Added a deterministic all-table target sequence with fixed competitive power, reload, and accuracy values. Near tables award 100–110 base points, middle tables 140–150, and far tables 180–200; Perfect adds 40 and Great adds 20.
- Added a stepped 1x–2x record multiplier that increases every three consecutive deliveries. Wrong tables, customer hits, prop hits, floor shots, and other misses reset the record combo without subtracting points.
- Added a responsive Record Run HUD, large countdown, server-time timer, point/combo feedback, multiplier celebration, and end card with final score, personal best, and global top-10 status.
- Added `RecordRunService` for isolated timing, scoring, player-best loading, guarded OrderedDataStore writes, username resolution, top-10 ranking, and periodic wall refresh.
- Added the physical **Pizza Launch Legends** wall and a locally personalized best-score display above the launcher. Unpublished/API-disabled Studio sessions show friendly fallback copy and continue without errors.

### Tests and repairs

- `rojo build default.project.json -o pizzalaunch.rbxlx` and `git diff --check` passed during implementation.
- Initial unpublished-place playtest exposed that `GetOrderedDataStore()` itself can fail during module loading. Store acquisition is now guarded and lazy; a fresh Studio session produced empty Output.
- Actual prompt input showed the three-second countdown, anchored operator pose, Scriptable camera, record HUD, and enabled launcher controls. Q exit restored Custom camera, WalkSpeed 16, an unanchored character, the side exit, and both station prompts.
- Authoritative calibrated shots scored Table 1 Perfect at 140 and Table 2 Perfect at 150. Four consecutive Perfect deliveries reached 708 points and multiplier 1.25x; a deliberate wrong-table delivery left the score at 708 and reset the combo to 0.
- A complete API-disabled run ended with a 290-point session best, the labeled Studio fallback `Global leaderboard is available in the published game. Studio API access is currently off.`, and an updated local best display. No DataStore error appeared.
- iPhone 17 Pro landscape at a 750x361 runtime viewport fit the record header, timer, score, combo, personal best, target lane, aim pad, power controls, launch button, and exit button without clipping. The end summary remained centered and readable.
- Fresh free-play regression after Record Run work delivered a Perfect pizza for +20 coins and combo 1, confirming the original restaurant loop remains intact. Final Studio Output was empty.

## 2026-08-30 — Playable arcade vertical slice

### Council decisions

- **Finish one complete shot loop before persistence or content breadth.** Game Director: immediate arcade payoff; Engineer: small server-authoritative surface; New Player: one glowing target; Product: coins and combos create replay; Scope: fully testable today.
- **Use a fixed 42-degree arc and let charge select distance.** It makes the dotted trajectory predictable, keeps aiming to one horizontal axis, and lets children compare the landing-distance number directly with the target-distance number.
- **Generate the restaurant from Rojo-managed code.** This keeps Studio and Git synchronized while still producing a colorful, readable space with a cannon, six tables, customers, order signs, lighting, and spawn behavior.
- **Make mistakes funny and cheap.** Floor shots report `FLOOR PIZZA!`, wrong tables do not remove coins, projectiles bounce, and the next pizza is ready quickly. Only the combo resets.
- **Add three small session upgrades after validating scoring.** Bigger Tips, Wider Plates, and Speedy Oven turn coins into a replay reason without premature DataStore risk or simulator complexity.
- **Use a condensed landscape-only touch layout.** A wide restaurant view is fundamental to aiming. On phones, the large desktop tutorial is replaced by one concise control line and avatar movement controls are disabled.

### Built

- Server-generated restaurant with warm lighting, tiled floor, readable colored tables, simple hungry customers, order signs, target plates, cannon, and hidden player spawn.
- Mouse/keyboard/touch aiming and hold-to-charge firing with a fixed camera, live power bar, predicted landing distance, crosshair, and 14-dot ballistic trajectory.
- Server-owned spinning pizza physics, visible pepperoni toppings, collision validation, impact rings, bounce-friendly physical properties, timeout cleanup, and rapid reset.
- Remote launch validation rejects malformed types, non-finite numbers, backwards shots, excessive aim angles, overlapping shots, and cooldown violations.
- Per-player highlighted order target across six distances and lanes.
- Accuracy tiers (`PERFECT`, `GREAT`, `DELIVERED`), coins, combo bonuses, leaderboard values, positive miss copy, and animated HUD feedback.
- Session upgrade shop with validated server purchases: +25% coin levels, expanded accuracy radii, and reduced reload delay.
- Responsive desktop and mobile-landscape HUD plus short first-shot onboarding.
- Rojo project configuration and complete run/build documentation.

### Tests and fixes

- `rojo build default.project.json -o pizzalaunch.rbxlx` succeeds.
- `git diff --check` passes with no whitespace errors.
- Live Studio server/client play session starts with the generated world, remotes, HUD, and no errors in Output.
- Calibrated Table 4 shot returned `PERFECT`, awarded 20 coins, and selected the next target.
- Follow-up delivery advanced combo to 2 and awarded the expected +2 combo bonus.
- Three consecutive calibrated deliveries reached combo 3 and 60 coins.
- Deliberate overpowered shot returned `FLOOR PIZZA!`, awarded no coins, reset combo, and allowed an immediate retry.
- Purchased Bigger Tips level 1 for 35 coins; leaderboard decreased correctly and the next perfect delivery paid 25 rather than 20 coins.
- iPhone 16 Pro Max landscape playtest found desktop HUD overlap and visible character controls. Condensed the touch HUD, hid the desktop tutorial, constrained the launch panel, and disabled the default touch controls.
- Corrected table/customer sign faces and the cannon barrel's cylinder orientation after live visual inspection.

### Known limitations at this milestone

- Coins/upgrades are session-only; saving is deliberately not enabled yet.
- The restaurant has one fixed table arrangement; target order changes but tables do not move.
- Multiplayer shares the physical cannon model, while target highlights and orders remain per-player.

### Priorities identified at this milestone

1. Add a 60–90 second lunch rush with a clear results card and combo milestones.
2. Add original, licensed sound effects for charge, launch, bounce, perfect delivery, and crowd reactions.
3. After economy playtesting, add guarded DataStore saving for coins and upgrade levels.

## 2026-08-30 — Restaurant, aiming, feedback, and progression overhaul

The earlier build was treated as a prototype. This pass replaced weak systems instead of stacking content on top of them.

### Council decisions

- **Creative Director:** Rebuild the test room as a compact, warmly lit pizzeria. Chosen over adding more tables because atmosphere, silhouettes, and readable lanes were the largest quality gap.
- **Gameplay Director:** Replace fixed-angle shots with true yaw + pitch plus charge power. Keep a colored world-space arc/ring so misses remain understandable without numerical distance jargon.
- **Child Player Advocate:** Use one glowing customer, one physical order sign, three onboarding steps, big verbs, and funny zero-coin-penalty misses. Hide non-target signs to prevent reading overload.
- **Roblox Engineer:** Keep the environment/NPCs generated through Rojo, use anchored Humanoid customers with tween reactions, cap/fade mess, reset physics props, and validate all client launch inputs server-side.
- **Scope Guardian:** Build four reliable rounds with target pools and tighter accuracy rather than fragile moving tables or a larger map. Add saving only after this revised economy receives broader playtesting.

### Visual and layout overhaul

- Rebuilt the room with checkered restaurant flooring, warm plaster/brick/wainscot walls, ceiling beams, hanging lights, windows, framed pizza art, a stone pizza oven, service counter, readable menu, register, pizza boxes, cup stacks, condiment stations, balloons, and a dedicated launcher platform.
- Re-aligned six rectangular tables into deliberate left/right near, middle, and far lanes. Rugs, booth seating, colored target plates, and per-player outlines keep each landing zone distinct.
- Replaced colored customer stand-ins with six seated R6-style Humanoid NPCs. Each has a head/face, torso/shirt, arms, seated legs, varied skin tones, hair or hats, a booth, a name, and a target-only physical order sign.
- Tuned camera, color correction, bloom, warm point lights, and exposure after live screenshots. Surface text now scales to remain legible from the play camera.

### Aiming and HUD overhaul

- Added independent horizontal yaw and vertical pitch with server limits. Mouse position controls both axes; keyboard supports `A/D`, `W/S`, and both arrow pairs; touch has drag aiming plus a dedicated four-way pad.
- Charge now controls launch speed while pitch controls arc. Hotter Oven upgrades increase power and the client preview uses the same upgraded equation as the server.
- Replaced all player-facing `STUDS` language with `POWER` and `ARC LOW/MEDIUM/HIGH`.
- Expanded the guide to 18 trajectory dots plus a landing ring. Guide color changes from orange to yellow to green as the prediction approaches the active plate.
- Redesigned the HUD around coins/combo, round/order progress, a target card, concise onboarding, responsive feedback, a modal upgrade shop, and a large launch control.

### Feedback, sound, reactions, and mess

- Added free Creator Store launch, whoosh, bounce, splat, delivery, and perfect-shot audio. All five source IDs passed `ContentProvider:PreloadAsync`; no load warnings remained after replacement.
- Correct deliveries snap onto the plate, trigger cheering arms/faces, a coin burst, success/perfect audio, happy order copy, and a short `NOM NOM` eating beat.
- Wrong tables trigger surprise copy, face changes, and a sideways dodge. Direct customer hits make the NPC duck.
- Floor/wall/prop misses create temporary cheese and sauce splats, impact rings, screen shake, encouraging copy, and fast reloads. Mess is capped at 24 and fades automatically.
- Reachable cups, signs, pizza boxes, balloons, condiment bottles, and register/kitchen props can be knocked loose with impulses and restore themselves after 4.5 seconds.

### Progression and economy

- Added First Orders (3 easy/short), Dinner Rush (4 near/mid), Full House (5 mid/far), and Master Chef (6 all-table/tight) service rounds.
- Each round has a visible goal bar, target pool, accuracy scale, color identity, completion card, and coin bonus. Master Chef repeats as the endgame loop.
- Added the fourth upgrade, Hotter Oven, alongside Bigger Tips, Wider Plates, and Speedy Oven. All purchases remain server-validated.

### Studio tests and repairs

- Clean desktop start generated the entire pizzeria, six NPC tables, kitchen, props, remotes, HUD, and round state with no script errors.
- Calibrated 3D shots returned Perfect on near, middle, and far tables. Wrong-table shots reset combo and changed the struck NPC reaction text/pose.
- A center-lane cup shot returned `PIZZA CHAOS!`, created one temporary splat, unanchored/impulsed a cup, and restored it automatically.
- Keyboard regression found processed `W/S/A/D/Space` input being swallowed by the movement sink. Input priority was corrected; `W` reached High Arc and held `Space` charged/fired successfully.
- Played all 18 required deliveries through Round 4: goals advanced 3 → 4 → 5 → 6, bonuses paid 25 → 45 → 70 → 100, table pools widened, and Master Chef reset correctly.
- Purchased Hotter Oven level 1 for 50 coins; HUD cost advanced to 110 and upgraded ballistics remained synchronized.
- iPhone 16 Pro Max landscape test at an 830×418 viewport verified the compact target card, stats, restaurant view, four-way aim pad, power/arc bar, launch button, and four-item modal shop without layout overlap. Default Roblox touch controls were disabled.
- Touch-pad input changed the arc, touch launch charged to 63% and fired, and the resulting prop miss resolved/reloaded normally.
- Final clean-session regression scored `PERFECT +20`, then `PIZZA CHAOS!`; the splat count returned from 1 to 0 after cleanup and all loose cups reported anchored/reset.
- Runtime and built-place orientation both report `LandscapeSensor`; the generated restaurant contains 466 descendants, remaining modest for the scene detail level.
- Final replacement audio set produced no Output load warnings. Studio device simulation was returned to the default viewport.

### Current limitations and next priorities

- Persistence remains intentionally disabled until the new round rewards and upgrade prices receive human playtesting.
- The six-table room is deliberately fixed; future variation should reposition only one or two props/tables per round after verifying target clarity.
- The shared physical launcher model is locally aimed for each player. A future multiplayer pass should decide whether to instance launcher stations or present other players' aim direction.

## 2026-08-30 — Launcher framing polish

### Council decision

- **Creative / Gameplay Directors:** Keep the wide restaurant composition, but expose the physical cannon between the aiming pad and the launch console so the action visibly begins at the machine instead of appearing from behind the HUD.
- **Child Player Advocate:** Start new players on a lower, easier-to-read arc while retaining explicit up/down control for distant orders.
- **Roblox Engineer / Scope Guardian:** Reposition existing UI and shared ballistic constants rather than introduce a second camera mode or fragile first-person rig. The preview and server continue to use the same equations.

### Changes and validation

- Raised and moved the muzzle forward, lowered the initial arc, and rebalanced the charge range so the nearby opening tables remain reachable while the far tables still require intentional extra arc/power.
- Moved the power/launch console to the lower-right on desktop and touch layouts, uncovering the cannon in the center foreground without covering the active target lane.
- Desktop framing now clearly shows the red cannon barrel and glowing muzzle between the restaurant lanes and the lower-right launch console; the arc label was resized after the screenshot exposed an overlap.
- A recalibrated Table 2 opening shot landed `PERFECT!` at 2% charge. A 41° / 87% shot reached Table 6 accurately, confirming the full distance range remains playable.
- iPhone 17 Pro landscape at 750×361 kept stats, target card, upgrade button, four-way aim pad, power/arc console, and launch button in-bounds without overlap or truncated text. Runtime orientation reported `LandscapeSensor` and Output remained empty.
- Studio device simulation was returned to the default viewport after the phone test.

## 2026-08-30 — Combo crowd payoff

### Council decision

- **Creative / Gameplay Directors:** Make streaks change the room, not only the coin counter. At combo 3, 5, and every 10, all non-target customers now throw up their arms and cheer while the HUD flashes a crowd message.
- **Child Player Advocate:** Use visible celebration at memorable small numbers; no extra rules or meter are introduced.
- **Roblox Engineer / Scope Guardian:** Reuse the bounded NPC tween/reset and screen-feedback systems. This adds no persistent objects, new remotes, or animation asset dependency.

### Tests and repair

- Ten consecutive calibrated deliveries crossed combo 3, 5, and 10. Each milestone arrived in the authoritative shot payload; combo 10 displayed `THE WHOLE ROOM CHEERS!` with the capped +12 combo bonus.
- Live pose inspection during combo 10 measured every non-target customer's head raised about 1.37 units and the delivered customer's success jump at about 1.98 units. All six returned exactly to their authored reset poses after the celebration.
- The first screenshot showed the celebration tint compositing over the HUD. Its layer was moved behind the interface; the repeat test kept power, arc, and launch controls fully visible during the flash.
- Studio Output remained empty after the 10-shot progression and reaction-reset regression.

## 2026-08-30 — Walk-in restaurant and living-shift overhaul

### Council decisions

- **Gameplay designer:** Preserve the proven launch/scoring physics and add replayability through a walk-to-launch loop, changing occupied seats, and deterministic late-round comedy obstacles.
- **Environment designer:** Reframe the entrance so the visible avatar, side-mounted launcher sign, front register counter, dining aisle, kitchen/menu, and customers share the first view. Normalize table/NPC proportions rather than adding more decoration.
- **Gameplay engineer:** Give one server-authoritative player a launcher lease at a time. Split prompts, customer motion, layouts, and prop restoration into bounded modules; never reposition a live target during a shot.
- **Nine-year-old playtester:** Use one bottom objective, one active target marker, ordinary movement, an obvious `E` interaction, forgiving 16–23% opening shots, and almost no floating reading.

### Implemented

- Added normal third-person walk mode with a visible player avatar and deterministic entrance spawn. Launcher operation is now entered through a proximity prompt and exited with `Q` or an on-screen button.
- Added validated single-operator launcher occupancy, server-side distance checks, frozen operator pose, death/respawn recovery, and camera/movement restoration.
- Added front register/order counter dressing with order signage, parmesan, pepper flakes, napkin dispenser, splat surfaces, and concise register interaction feedback.
- Added short customer mood/personality interactions through contextual prompts and the existing HUD feedback toast.
- Removed all six legacy order signs/bubbles. Waiting customers use tiny pizza markers; reactions temporarily use `!`, `?`, `★`, or `YUM`; only the active table receives the prominent delivery marker/highlight/ring.
- Moved the opening tables to readable mid-range lanes and kept a broad center aisle. Varied small, booth, and family table proportions by distance.
- Rescaled customers to believable stylized Roblox proportions while preserving distinct clothing, skin tones, faces, hair, and accessories.
- Added staggered, bounded head/arm idle gestures and a served-seat step-away/return beat that cannot enter projectile lanes.
- First Orders shows two occupied seats, Dinner Rush four, Full House the middle/far group, and Master Chef all six. Full House activates a center reactive sign; Master Chef also activates the far pizza-box stack.
- Extracted prompt routing, customer motion, round dressing, and prop reset into `InteractionService`, `CustomerService`, `LayoutService`, and `PropService` modules.
- Walking and launcher interfaces now switch cleanly: normal touch/character controls versus aim pad, power/arc, trajectory, launch, and exit controls. Added a guard against Roblox re-enabling the touch movement GUI during launcher operation.

### Studio tests and repairs

- Fresh character spawned visibly at the authored entrance with `CameraType.Custom`, `WalkSpeed 16`, and an unanchored root. The initial spawn-order bug that placed characters in the dining room was fixed.
- Launcher prompt moved the character to the operator pose, anchored/froze movement, switched to the scriptable aiming camera, and showed launch controls. `Q` restored the side exit pose, normal camera, movement, and prompt availability.
- Customer interaction returned `MIA • SUPER HUNGRY` plus her short line; register interaction returned First Orders progress and coin status.
- Recalibrated opening tables landed Perfect at 16% and 23% charge instead of near-zero power.
- Twelve consecutive calibrated deliveries advanced First Orders → Dinner Rush → Full House → Master Chef. Every shot landed Perfect; active seating reached all six and both late-round obstacle sets enabled at the intended transitions.
- A center-cup shot returned `PIZZA CHAOS!`; the cup unanchored with `RecentlyHit=true`, then returned to its exact authored position, anchored/collidable state, and `RecentlyHit=false` after 4.5 seconds.
- iPhone 17 Pro landscape at 750×361 showed normal thumbstick/jump controls and the walk objective without overlap. Launcher mode removed those controls and fit the aim pad, target card, upgrades, exit, power/arc, and launch button without clipping.
- Studio device simulation was returned to default after testing.

### Remaining priorities

- Run a dedicated two-player contention/play-observation session before deciding whether one shared launcher is sufficient or each player needs a station.
- Add shift results/timing only after human playtesting confirms walking does not slow the desired arcade cadence.
- Add DataStore persistence only after the larger reward totals and upgrade prices are rebalanced with real players.

## 2026-08-30 — Living restaurant and Record Run choice pass

### Council decision

- **Gameplay designer:** Free Play should reward serving any waiting guest; Record Run should turn the same room into a clear risk/reward route where farther occupied tables pay more.
- **Systems engineer:** Claim each seat on the server before granting coins or points. Keep customer state, competitive scoring, prop limits, and cleanup authoritative; preserve the existing OrderedDataStore schema.
- **Environment/NPC designer:** Sell turnover with visible side doors, safe aisle travel, a short eating beat, refreshed names/colors, and alternating family-table seats rather than pathfinding through shot lanes.
- **Child playtester:** Keep Free Play calm with tiny pizza markers and one short instruction. Show glowing rings, values, timer, score, and combo only after explicitly starting Record Run.

### Pass 1 — customer flow and serving

- Replaced the fixed served side-step with explicit `SeatedWaiting → Served → HappyReaction → Eating → Leaving → Despawn → Entering → WalkingToSeat → SeatedWaiting` states.
- Added atomic delivery claims, per-table availability/occupancy attributes, one- or two-seat capacity metadata, safe anchored entrance/side-aisle routes, and a brief empty-seat replacement beat.
- Added twelve rotating customer identities with names, moods, short lines, skin/shirt/accent variation, idle looks/gestures, and refreshed walk-up prompts.
- Free Play now accepts any waiting customer in the active restaurant layout. Empty/leaving seats award nothing, while existing coins, combos, rounds, accuracy, upgrades, and quick reload remain intact.

### Pass 2 — distinct Record Run targets

- Removed the forced Record Run target sequence. Every occupied table is a valid server-scored choice; fixed values remain 100/110 near, 140/150 middle, and 180/200 far plus existing accuracy/combo bonuses.
- Free Play has no target rings, highlights, value labels, score, or timer. Record Run countdown/running alone reveals all eligible customers, glowing delivery rings, compact point plaques, and the competitive HUD.
- The trajectory guide evaluates the nearest currently deliverable table, and customer availability changes add/remove run markers without stale overlays.
- Fixed the opening timer display from `0:60` to `1:00`; exiting or completing a run removes all competition visuals and restores walking/free play.

### Pass 3 — controlled pizza chaos

- Direct customer hits now create a server-owned temporary hit state, splat/impact feedback, no delivery reward, combo loss, and a clean return to waiting.
- Added parmesan shakers, sauce bottles, and menus to table edges. Reactive props have a server cap, size-aware impulses/reset delays, exact pose/collision restoration, and reset-all cleanup at round/Record Run boundaries.
- Added visible customer arrival doors, welcome signs, and mats without changing the established counter, launcher, or restaurant floor plan.

### Studio and build validation

- Live Free Play delivery to Table 1 returned `PERFECT`, paid 20 coins, and began the customer turnover cycle with no timer or competition overlay.
- A full Table 2 lifecycle produced the complete expected state history, changed the replacement identity to Rex, and returned the seat to a deliverable state.
- Record Run started only from the red prompt, displayed `1:00`, six eligible rings/value objects, and no Free Play target card. Two repeated Perfect deliveries to far Table 6 paid 240 each and built score/combo to 480/2 after replacement.
- A direct customer-head hit returned `TOO HUNGRY!`, paid no coins, reset combo, and recorded `SeatedWaiting → HitReaction → SeatedWaiting`.
- A pizza hit on table sauce returned `PIZZA CHAOS!`; the prop unanchored/moved, then returned to its exact position with `PropState=Ready`, `RecentlyHit=false`, and zero active loose props.
- iPhone 17 Pro landscape (750×361 viewport) showed unclipped Free Play movement HUD and Record Run timer/aim pad/launch/exit controls. Six run rings/value objects were active; Output was empty. Studio was restored to the default viewport.
- Repeated `rojo build default.project.json -o pizzalaunch.rbxlx` and `git diff --check` completed successfully during development.

### Deliberately deferred

- Full Motor6D walk cycles, multiple simultaneous NPCs per table, random table relocation, and cross-lane pathfinding remain deferred until dedicated multiplayer observation proves they improve the game without obstructing shots.
- Record score persistence, personal-best behavior, and the global top-10 schema were intentionally left unchanged.
# 2026-09-13 — Milestone 0 verified checkpoint

Implemented immutable Record Run submissions and retry-safe personal bests; owner-only plate presentation; playable input with correlated launch replies; round-owned visibility; character/lease/shot/customer/prop cleanup; avatar collision isolation; dynamic guarded recovery generation; focused server/client extraction. No canonical source removed, no anchors/store/modes changed, no recovery input modified.

Validation: recovery safety and contracts PASS; 29 sources compile and 11 actual-Luau test files PASS; clean Rojo build PASS; optional recovery copy includes all 29 scripts with canonical/Workspace verification PASS; full integrated council diff review and `git diff --check` PASS. CRLF warnings inspected with `--ignore-cr-at-eol`; changes are substantive, no automatic reset performed.

Actual Studio: connected-place E mount, picker Space gate, Free Play launch/miss/reload, invalid request then valid launch, Q restoration, natural Record Run results/choose-mode, mounted death/respawn, and initialized rounds 1/3/4/1 module probe PASS. Separate fresh Rojo place: mount/picker, 3.002-second countdown, cancellation, collision-group matrix and walking restoration PASS. Output inspected: expected unavailable unpublished DataStore warnings; corrected QA-only probe errors documented in TEST_MATRIX. Both sessions stopped in Edit. No publishing or production data access.

NOT RUN: true two/four-client hitbox/physical deflection and handoff scenarios, native touch/tablet/controller, full natural four-round progression, live DataStore/rejoin/shutdown reliability. Pending submissions are memory-only until a successful write. Source build cannot demonstrate preservation of unknown Studio geometry. Next: Takeout Runner and FIFO reservations using a separate activity channel. Pushed hash is recorded in the next log entry after commit confirmation.
# 2026-09-13 — Milestone 0 remote confirmation / Milestone 1 in progress

Milestone 0 pushed commit: `10a454628daa63cc94f483444fd08280b213363d`. `git ls-remote` matched HEAD and worktree was clean before multiplayer implementation began. All available source/recovery/build checks passed; actual Studio coverage and remaining cases are listed below and in TEST_MATRIX.

Integrated multiplayer decision: independent Takeout Runner orders, 8 session coins plus optional 2 for quick service; two nearby shops via the existing crosswalk; FIFO 15-second approach reservations, no forced mount or Free Play timeout. A separate RestaurantActivity channel carries public station, queue and runner presentation without touching competitive target state. Small shared milestone rewards present service contributors only, after the runner loop passes. No paid products or durable coin economy.
# 2026-09-13 — Milestone 1 verified multiplayer checkpoint

Implemented independent Takeout Runner, two destinations with clear outbound/return corners, 8+optional2 session-coin rewards, FIFO queue/15-second reservations, occupied choices, queue position and honest public station status, operator pass-turn cue, and contributor-only shared restaurant milestone. Mode/activity requests now carry epochs. Activity UI/wallet messages are separate from competitive launcher state.

Real QA found and repaired two issues before checkpoint: direct street routes intersected bins/benches/van; a fresh Rojo place lost Baseplate.Position and opened the ground10 units higher than intended. Explicit same-height CFrame fixes serialization, with exact protected mapping comparison and actual binary regression test. No unknown Workspace or canonical recovery object changed.

PASS: recovery safety/contracts, 36-source compilation, 17 actual-Luau spec files, clean source build, full source/diff and independent release-safety review, whitespace check. Four-player behavior tests cover queue, activity/purchases during Record Run, stale requests and contributor rewards.

Actual Studio PASS: both runner destinations (~10/12 seconds), safe return/replay, late normal8 reward, fresh binary ground parity, two real clients with occupied choices/queue, NO TIME LIMIT, pass-turn/reservation/physical-prompt acceptance, restored walking camera/movement, and runner delivery during another player's Record Run with all six hitbox sizes/score/camera unchanged. Output inspected. Generated client windows needed restoration to render. Native four-client launch stalled before connection and was stopped; record it NOT RUN, not a game pass. Remaining: native mobile/controller (next visual milestone), true4-player capacity/abandonment study, real projectile crossing comparison and live persistence. No publishing or paid products. Pushed hash is recorded after confirmation in the next checkpoint.

# 2026-09-13 — Milestone 1 remote confirmation / Milestone 2 in progress

Milestone 1 pushed commit: `8b13e6ff4d7255dd1a087dbf5f436b894145ad33`. Remote branch matched HEAD and worktree was clean before the visual slice began.

Milestone 2 acceptance: reveal only the exact mapped Baseplate; quiet flooring and architectural surfaces; compact oven launcher, one polished booth/table/customer and shared pizza visual prefab; responsive HUD; unchanged six ballistic anchors, authoritative projectile/customer proxies and mode/input contracts. Inspect real spawn, walking, mounted, landscape phone and tablet views before spreading the hero treatment. Fresh-build and live-sync parity both required where Studio is available.

Initial mapping check PASS: exact Baseplate CFrame Y=-12 (top=-2), current LightingStyle=Realistic, PrioritizeLightingQuality=true and ShadowSoftness=.35 survive real binary serialization. Deprecated Technology/Outlines removed; structural comparison still protects every unrelated mapping. Runtime visual acceptance is pending, not implied by this build check.

M2 Studio mapping note: source modules live-synced, but existing session project-property changes were not applied automatically. After verifying exact mapped Baseplate class/size/old transform, QA set that object to the source CFrame Y=-12. The Assistant execution bridge rejected LightingStyle writes for lacking RobloxScript capability; no attempt to bypass it. Original session remains Soft lighting. Current lighting must be validated through the fresh build. This QA-only capability error is not a runtime game error.

M2 geometry QA: LauncherArt.spec executes the real prefab across 67 yaw settings and 32 pitch settings, inspecting every visual bounding corner, fixed origin, aperture/gauge direction and approach collider. PASS, lowest corner Y3.47. Lune0.10.5 CFrame.lookAt reverses native local-Z orientation in this harness; the test explicitly constructs right/up/back vectors and asserts LookVector alignment. Earlier exploratory sweep values were invalid and are not acceptance evidence. Native Roblox still uses its ordinary CFrame.lookAt.

Native M2 corrections: first1366x841 picker clipped RECORD RUN; title-height repair is being rechecked. First fresh build read back LightingStyle=Soft/PrioritizeLightingQuality=false despite modern serialized values. A second fresh build with explicit Technology=Future compatibility seed opened Realistic/true/.35 correctly. This is a tested serialization workaround, not a runtime deprecated-preset assignment; see https://github.com/rojo-rbx/rbx-dom/issues/637. The binary test now also protects the seed. The original Soft session cannot prove final lighting.

Native camera comparison rejected the original (0,29,82) view's ceiling/foreground facade obstruction. Selected (0,28,67), focus(0,1,-12), after two actual client camera candidates: foreground facade removed, less ceiling, all six rings project on screen (near X410/938,Y402/386; far X523/835,Y300/293 at1366x841). Gameplay origin/anchors are unchanged. Temporary QA render override was removed and Play stopped; mobile/fresh framing recheck pending.

M2 observed native UI: 667x375 and874x402 landscape phone (ActualResolution simulator),1024x768 tablet, and1920x1078 console simulation. Earlier physical-size simulation rounded to666x374; ActualResolution establishes exact targets. Picker title/description, FreePlayHUD, RecordHUD, natural60-second results and upgrade cards reported TextFits=true in tested states. Upgrade list actually scrolled. Phone hold-launch and releaseoutside produced serveracceptedreload. Controller simulation correctly shows EXIT[B]/HOLD RT and hides touchpad, but VirtualInput refused ButtonB because it is reserved byCoreGUI: actualcontrollerbuttonoperation remainsNOTRUN. Native twofingerhardware remainsNOTRUN; independentfingerlogic is behavior-tested.

Compact camera selected(0,26,67)focus(0,9,-22) after accounting for actual58pxCoreUI inset: six ring centers moved from HUD-coveredY130..179 to clearY174..217 in666x374 probe. ClientCamera now chooses compact framing by safe-height; larger viewports use reviewed desktopConfig. Results and scrolling panels intentionally cover gameplay. Generic offscreenlabelaudit does not count clipped-away scrollchildren as layout failures.

Actual native ProjectileService probe: collider0.65x6x6, Transparency1, PizzaLaunchProjectiles;27nonphysicalmassless visualparts; rootmass andassemblymass both11.9459056854. Probeobject destroyed immediately. Output inspected: expectedunpublishedDataStorewarnings; QA-only duplicate cameraoverride removal warning; no observedgameplayexception. Overrides removed, Playstopped, devicesimulatorreturneddefault. Fresh current-sourceRealisticlighting smoke is next.

# 2026-09-13 — Milestone 2a verified hero slice

Integrated decision: accept the first oven/table/customer/pizza slice after native review from spawn, mounted, detail and mobile views. The final central facade exposes the oven; lighter first-booth overlays preserve old furniture physics. Current desktop and compact cameras leave all six anchors unchanged and improve composition. Keep detailed character/furniture expansion as the next separate checkpoint.

PASS: recovery safety/contracts,41-source compilation,25 Luau spec files, clean Rojo build, actual final fresh-place ground/lighting and visual checks, complete council diff review, and git diff --check. Native hero delivery and complete customer lifecycle observed; pizza assembly mass unchanged. Phone/tablet/console-layout coverage and hardware limits are detailed in TEST_MATRIX. All QA overrides restored, simulations stopped and final test places returned to Edit. No canonical input, unknown owner geometry, live experience, paid product or historical record changed. Final screenshots remain ignored QA evidence. Pushed hash will be recorded after confirmation in the next checkpoint.

# 2026-09-13 — Milestone 2a remote confirmation / next slices

Milestone 2a pushed commit: `6bc7e8d29cbce3da5158fcdf86b0cdd701fa11de`. GitHub matched HEAD and worktree was clean before the next slice. Lead approved the tested hero treatment for propagation to six tables/customers, with exact collision proxies and lifecycle retained. The next checkpoint expands that visual treatment and checks local engine cost; physical low-end hardware remains unavailable.

The persistence council is preparing isolated draft modules under ignored .qa-artifacts/m3-draft. They are not mapped into this visual checkpoint. The agreed later integration uses a separate versioned mastery/cosmetic profile and low-cardinality server analytics; coins/upgrades stay session-only. Paid-product work remains architecture/documentation only.

# 2026-09-13 - Milestone 2b six-table visual checkpoint

Accepted the tested hero treatment across six booths and customers, preserving original physical proxies and authoritative lifecycle. Compact mobile takeout now leaves the walking character visible. PASS: 41-source compilation, 25 behavior specs, recovery safety/contracts, fresh build, full diff review and whitespace checks. Fresh native Studio verified six rigs, current lighting/ground and 667x375 mounted/runner presentation; Output had only expected unpublished DataStore warnings. Local frame diagnostic and exact NOT RUN hardware/multiplayer limits are recorded in TEST_MATRIX. Generated test place returned to Edit and simulator restored. No M3 drafts, artifacts or recovery inputs are staged. Pushed hash follows in the next checkpoint after remote confirmation.

# 2026-09-13 - Milestone 2b remote confirmation / M3 integration

Milestone 2b pushed as `7ed71434e1dcd4470b8a29a230d9bc0dc281254b`; remote hash matched and worktree was clean. M3 integrates separately reviewed versioned mastery, earned nameplates and bounded analytics. Coins/upgrades remain shift-only. Profile review found and required regression repairs for late acquisition after departure and lost renewal responses before acceptance. Production DataStore and analytics access stay disabled in Studio.

# 2026-09-13 - Milestone 3 verified profile/mastery foundation

Integrated Chef Book, four earned nameplates, server receipt hooks, versioned profile persistence and bounded journey analytics. Coins/upgrades remain shift-only and historical competitive records are unchanged. PASS: recovery safety/contracts, 48-source compilation, 30 behavioral spec files, final fresh Rojo build, full council review and whitespace checks. Canonical Transfer and historical merged recovery hashes still match.

Native evidence: 667x375 scrollable book and five real walking deliveries earned 50 coins, unlocked Tomato Chef and equipped its server-owned nameplate. Final 874x402 natural Record Run added exactly one completion and accepted launch completed onboarding. Actual open-book death cleared modal/focus; respawn retained same-server mastery. Tablet book and desktop restoration checks passed. Final source includes separate request/equip cadence and loading/character guards. Output contained only expected unpublished record-store warnings. Both generated test places are Edit; no production services were enabled. Real backend, physical hardware and four-client runtime limits remain explicitly NOT RUN in TEST_MATRIX. Pushed hash is recorded after confirmation in the next checkpoint.
