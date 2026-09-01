# Pizza Launch Build Log

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
