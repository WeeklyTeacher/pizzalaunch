# Test matrix

Results below describe this run only. Historical BUILD_LOG results are not new evidence.

| Check | Baseline result | Evidence / limit |
| --- | --- | --- |
| Required branch / clean tracked state | PASS | `81e3f93`; one preserved untracked local place |
| Origin and pushed checkpoint | PASS | `git ls-remote` equals HEAD; push dry-run succeeded |
| Recovery safety | PASS | Explicit Workspace preservation and Transfer SHA-256 |
| Recovery contracts | PASS | Existing source/string/hash suite; limited behavioral coverage |
| Tracked merged recovery integrity | PASS | Historical SHA-256 matches |
| Rojo server | PASS | 7.7.0 responds at 127.0.0.1:34872 |
| Studio connection | PASS | `pizzalaunch`, Edit mode, PlaceId 0 |
| New source build | PASS | Rojo builds `.qa-artifacts/Milestone0-source.rbxl`; fresh Studio check follows |
| Immutable save / cancellation / retry faults | PASS (Luau) | 13 pure model cases and 3 actual RecordRunService scheduler/store regressions; real DataStore NOT RUN |
| Owner/walker purchase isolation | PASS Luau + partial two-client Studio | Four-player handler tests; real runner reward during another player's Record Run preserved rings/score/camera |
| Picker input / rejected launch / re-entry | PASS desktop Studio + Luau | E mount, Space in picker, click Free Play, Space shot/miss/reload, malformed direction rejection then accepted Space shot; touch/controller actual hardware NOT RUN |
| Round 3/4 props after reset | PASS Luau + Studio module probe | Explicitly initialized modules: rounds 1/3/4/1 have 0/1/4/0 active obstacles after reset; not natural four-round playthrough |
| Death/removal/replacement/disconnect cleanup | PASS partial Studio + Luau | Q restores speed16/unanchored/Custom/FOV70/upgrades; mounted death and respawn hide picker/results/exit and restore camera. Disconnect/multiple real clients NOT RUN |
| Projectile/bystander physical isolation | NOT RUN | Real physics and two/four-player scenarios |
| Takeout replay / queue / reservations | PASS Studio + Luau | Both destinations, replay, late reward, real two-client queue/handoff; four-player boundary suite |
| Hero art slice / fresh-build visual parity | PASS Studio slice review | Final facade/booth rechecked in fresh build; spawn, mounted, pizza delivery/customer reaction observed; fresh Realistic properties verified after migration fix |
| 667x375 / 874x402 / tablet / controller | PASS native composition; hardware limits below | Exact phone sizes,1024x768 tablet, console emulation; physical two-finger/controller input NOT RUN |
| Live persistence / reconnect / rapid servers | NOT RUN | No production DataStore access authorized |

Additional passing source-execution evidence: WorldBuilder preserves a mock owner model and all six ballistic centers; recovery overlay includes all current Rojo modules, rejects incomplete/ambiguous/unreviewed mappings, preserves a geometry fixture through binary round trip, and rejects unsafe/existing output paths. This does not establish live Studio/Rojo preservation.

Every milestone must also pass full diff review, `git diff --check`, exact staging review, and remote hash confirmation. Bulk evidence goes in ignored `.qa-artifacts`.

Milestone 0 aggregate: 29 real source files compile; 11 executable Luau spec files pass, including actual GameService prompt/remote owner-transfer integration and full client bootstrap. Recovery copy generation and binary round-trip preserve canonical input and Workspace fixture. Latest contract suite and safety pass.

Observed connected-place Studio Record Run ran to the natural 60-second end, showed results and CHOOSE MODE, and returned through the shared picker. Output contained expected unpublished-place DataStore warnings, plus two explicitly authored QA probe errors (wrong HUD capitalization and an uninitialized Assistant module registry); corrected probes passed. No production DataStore setting was enabled. Screenshot viewed for mounted Free Play; it confirms the existing framing needs Milestone 2 work, not final art approval.

Fresh generated place also opened and ran in a separate Studio instance: physical E mount, picker Space gate, Record Run countdown, run cancellation and movement restoration passed. Client-observed server events measured countdown at 3.002 seconds. Runtime collision matrix confirms projectiles/props do not collide with the avatar group; true multiplayer deflection remains NOT RUN. Fresh-place Output had only expected unpublished DataStore warnings. Both places returned to Edit without publishing. Latest optional recovery generation included all 29 scripts and verified canonical/Workspace round-trip preservation.

Milestone 1 source checks: 36 sources compile; 16 actual-Luau spec files pass, including four-player GameService boundary tests for independent rewards, Wider Plates during Record Run, contributor-only milestone payouts, FIFO reservations/approach validation and stale mode/activity requests. Actual WorldBuilder collider-envelope tests reproduce and prevent the original runner route obstruction.

Milestone 1 connected Studio: no launcher operator present; E pickup, normal-speed scripted Humanoid walking through exact route corners, E delivery and replay PASS. Tiny Sprouts completed in 11.716 seconds for 10 coins, Sunny Scoops in 9.967 seconds for 10, return walk 11.348 seconds. An earlier obstructed/late delivery still paid normal 8 coins; the obstruction was repaired. These were genuine engine walks with script-directed navigation, not a human usability study. Output after corrected routes contained only unpublished DataStore warnings. Native multiplayer session validation follows before checkpoint.

The first genuine two-client fresh-build session found Baseplate Y=0 despite intended/live-sync Y=-10, causing out-of-range occupied prompts. Earlier M0 fresh-place smoke passed at the central prompt but did not inspect this ground mismatch. Replaced only Baseplate.Position with an explicit equivalent CFrame; new RojoBuild.spec verifies all remaining mapping values against the protected baseline and tests actual binary ground transform. This is a regression fix, not a weakening of mapping safety. Corrected fresh multiplayer rerun follows.

Corrected genuine two-client fresh-place test PASS: both players see Baseplate Y=-10; occupied interaction, queue position 1 and FREE PLAY / NO TIME LIMIT, operator EXIT & PASS TURN, release restores Custom camera/unanchored movement, next player receives a 15-second reservation and must trigger the physical prompt before mounting. Tests used script-driven ProximityPrompt input and ordinary client requests, with a QA-only server helper staging nearby positions in the generated place; this helper is ignored and never mapped. A full runner delivery during the other player's active Record Run earned 10 coins while all six target-ring sizes, competitive score and mounted camera remained unchanged; walking activity HUD stayed hidden for the operator.

Studio multiplayer child windows initially did not render while hidden. Restoring only generated Place1 test windows resolved the input/capture wait; this was a test-window condition. A mounted picker screenshot was genuinely viewed. Four-client rerun follows. Current aggregate count is 17 spec files after adding the build parity regression.

Native four-client test: NOT RUN. ExecuteMultiplayerTestAsync(4) stalled while launching generated clients before MCP connections became available. Freed older generated-place processes and restored only test windows; no progress. Stopped only the known generated test processes. The owner's working Studio process was preserved. Actual two-client evidence and four-player executable boundary tests are separate from this missing runtime case. No human abandonment/capacity conclusion is claimed.

## Milestone 2a acceptance evidence

PASS: 41 source modules compile; 25 actual Luau spec files; recovery safety/contracts; real Rojo binary build; independent council code review; whitespace checks. Added real prefab/rig/pizza/fan/onboarding tests, safe-area and hybrid-input tests, and preserved mapping/authority/recovery coverage.

Observed Studio: original live source and separate fresh builds. Verified ground Y=-12, Realistic lighting/quality after the compatibility seed, final central facade exposing the oven, lighter first booth, desktop/compact camera composition, and all six target projections. Final source in exact667x375 selected camera(0,26,67), with target centers Y174..218 clear of the58px-inset HUD. Phone874x402 and tablet1024x768 layouts were also observed. Picker, Free Play, Record Run, natural results, scrollable upgrades and runner captions had no observed text overflow in tested states. An outside-button release produced an accepted launch/reload. Console simulation changed labels correctly; VirtualInput ButtonB was blocked by CoreGUI, so physical controller action remains NOT RUN.

Fresh normal server-validated scripted shots delivered to tables2 and1. Hero customer history observed SeatedWaiting → Served → HappyReaction → Eating → Leaving → Despawn → Entering → WalkingToSeat → SeatedWaiting. A temporary camera/HUD suppression captured the detailed pizza/customer reaction; it was restored afterward. This is an art-review view, not ordinary walking UI. Native pizza root/assembly mass matched with all27 visual parts. Final source fan was visible. Output inspected throughout; only expected unpublished DataStore warnings in final sessions.

NOT RUN: physical two-finger/controller hardware, full native four-client session, human capacity/abandonment study, sustained low-end mobile performance, live DataStore/rejoin/shutdown, exhaustive max-number text and every occupied/runner combination. M1 real two-client isolation remains evidence; M2 did not repeat that complete scenario. Bulk actual captures are ignored .qa-artifacts/M2-*.png; no screenshot set is committed. Studio tests do not establish preservation of unknown geometry in a source-only build.

## Milestone 2b actual acceptance

- PASS: all 25 behavior specs, 41-source compilation, recovery safety/contracts, fresh Milestone2b.rbxl build, full council diff review, git diff --check.
- PASS, native fresh Studio: six articulated customers, 152 render parts, 60 joints; every visual part noncolliding/nontouch/nonquery. Lighting Realistic and mapped ground Y=-12.
- PASS, native 667x375 simulator: physical launcher prompt, Free Play picker click, all-six mounted composition, ordinary Exit, takeout pickup prompt and compact 340x70 objective. Destination and reward TextFits=true. Pickup positioning used a QA-only server PivotTo; this was a UI check, not a new route timing test.
- Diagnostic only: 300 RenderStepped samples over five seconds, p50 16.87 ms, p95 18.09 ms, Studio total memory 2442.48 MB, viewport 666x374 before exact simulator reset. Host Studio measurement includes editor overhead; not a physical mobile budget claim.
- Output inspected: expected unpublished RecordRun DataStore warnings; no observed gameplay exception. Device simulation restored and generated test place returned to Edit.
- NOT RUN: physical low-end hardware, sustained four-player/effects performance, hardware two-finger/controller input and human queue-capacity/abandonment study. Previous genuine two-client evidence remains in the M1 section.
