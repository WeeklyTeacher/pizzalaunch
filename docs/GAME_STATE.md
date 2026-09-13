# Game state

## Current implementation

The pushed M0/M1/M2 checkpoints provide authoritative launcher cleanup/retries, independent Takeout Runner orders, FIFO reservations, a six-table toy pizzeria, articulated customers, detailed pizza visuals and responsive component UI. M3 adds Chef Book mastery, earned nameplates and bounded analytics; acceptance evidence follows below. Coins and upgrades remain session-only. Historical competitive records and ballistic anchors are unchanged. Earlier baseline sections are historical, not current defect reports.

## Baseline audited 2026-09-13

Branch: `feat/astra-overhaul-20260913-101719`. Starting pushed commit: `81e3f930b6210359e6ee4c64a90f0b83e9c7dac8` (launcher contract/documentation checkpoint), following release tag `v1.0.0` at `79fceab`.

The lead read all 13 tracked source files, three testing/recovery scripts, project/tool configuration, ignore rules, launcher contract, README, build log, roadmap, ownership/recovery documents, recent history/tags, and available historical screenshot evidence before editing.

The game builds its pizzeria from `WorldBuilder`; server bootstrap builds the world and starts `GameService`. There are six fixed delivery tables, twelve rotating customer identities, a server-owned customer lifecycle, four escalating Free Play rounds, three repeating shift events, capped reactive props and splats, and a shared launcher. Players walk to one prompt and choose Free Play or a 60-second Record Run after a countdown. Coins and four upgrades are session-only. Record personal bests use the existing numeric OrderedDataStore and `u_<userId>` keys.

`GameService` currently combines lease/mount state, shot physics, hit resolution, scoring, progression, and effects. `RecordRunService` combines timing and persistence. The client combines HUD construction, input, camera, onboarding, target presentation, and feedback. These are extraction targets for Milestone 0.

Known confirmed defects at baseline: mutable asynchronous score submission; no persistent retry of failed session best; walker purchase mutates active shared delivery zones; picker launch can stick readiness; hidden round-one props overwrite later activation; incomplete character/stale-callback cleanup; avatars can deflect projectiles; recovery generator lists only ten of thirteen current source containers.

Rojo 7.7.0 responds at `127.0.0.1:34872`. Workspace mapping ignores unknown objects and has no `$path`. The mapped Baseplate has top Y=0 and obscures authored floor/sidewalk/road surfaces around Y=-0.5. This will be addressed only in the visual milestone.

Connected Studio `pizzalaunch` is an unpublished local place (PlaceId 0), initially Edit mode; server source and mapped Baseplate exist, `StudioRestaurant` was not present in the read-only initial inspection. This is not a runtime or preservation test.

## Recovery evidence

- Transfer input SHA-256: `73B3D5DF3B72F9B13350790759B715BC0E510BB7A41FED3C895F58BD17F11088`.
- Historical tracked merged artifact SHA-256: `8C1C1B815626970FE6C228247338D52637B15B379022BD5A217AE936B976EE4B`.
- Both hashes verified before edits. Existing local `PizzaLaunch-Astra-Working_1_0.rbxl` is preserved, never staged.

## Milestone 0 implementation

The server now separates LauncherLease, ShotPolicy, ProjectileService, DeliveryScoring, PlayerProgression, RecordPersistence, ServerEffects, and CustomerFeedback. GameService remains the integration owner for remote handlers, delivery routing and round progression. CustomerService remains the lifecycle authority. No canonical source file was deleted.

The client separates LauncherInputState, ClientInput, ClientCamera, UITheme, UIConstruction, UIPresentation, Onboarding and Feedback. The bootstrap retains target/aim visuals and integration. Launch requests include a monotonically increasing request ID and cleanup epoch; accepted/rejected replies reconcile readiness against authoritative active-shot/reload state. Picker/countdown/input-modal gating is explicit. Mode requests also carry cleanup epochs, added in Milestone 1.

Completed records freeze user ID, score, GUID and timestamps before any yield. Session best, confirmed saved best and pending submissions are distinct. Writes serialize per player, retry with bounded backoff, survive local departure, and use max-preserving UpdateAsync transforms. Corrupt/failed loads cannot cause default writes. Shutdown retries are bounded; pending memory cannot survive a full server failure without a successful DataStore write.

Walker inventory purchases cannot update an operator's world policy. All avatar descendants use a collision group isolated from projectiles and reactive props. Resolved pizzas lose collision/touch/query; owner cleanup clears active and lingering shot visuals, cancels customer feedback and restores knocked props before releasing the lease. Layout owns current-round visibility while PropService restores only authored poses and layout-owned presentation.

Recovery generation now discovers every required script through Rojo and checks the complete source inventory. It overlays only owned script roots into a new ignored copy, verifies canonical hash and Workspace serialization before/after, and refuses existing/unsafe output paths. Normal builds still use Rojo. The pinned local Lune harness executes actual production modules with explicit engine boundaries.

## Next checkpoint

Milestone 0 is pushed as `10a454628daa63cc94f483444fd08280b213363d`; Milestone 1 as `8b13e6ff4d7255dd1a087dbf5f436b894145ad33`. Source and actual runtime evidence are recorded in TEST_MATRIX. Milestone 2 is building the first launcher/table/customer/pizza visual slice, revealing authored flooring and making HUD layouts respond to real viewports. Preserve competitive anchors and proxies; inspect spawn, walking, mounted and mobile views before wider propagation.

## Milestone 1 implementation

TakeoutRunner owns per-player walking orders, immutable completion receipts, request cadence, character identity and travel plausibility. TakeoutConfig supplies two destinations and explicit clearance corners around street props. TakeoutWorld owns nonphysical pickup/drop-off fixtures and a compact NOW PLAYING display; it never modifies unknown models. Pickups remain independently available even without a launcher operator. Rewards are 8 session coins plus an optional 2 within 16 seconds; no deadline removes the ordinary reward.

LauncherQueue owns FIFO entries and 15-second reservations. Reservation never mounts or moves a character; GameService still acquires a healthy nearby character lease. Activity request IDs/epochs reject duplicates and stale joins/leaves; mode requests now also carry the launcher cleanup epoch. Occupied prompts remain enabled, with JOIN LINE / DO TAKEOUT ORDERS choices, positions and real mode/time. Unlimited Free Play says NO TIME LIMIT. EXIT & PASS TURN uses ordinary cleanup.

RestaurantActivity carries queue, runner, station, wallet and shared milestone snapshots independently from launcher GameState. ActivityHUD/ActivityPresentation own walking objectives, nonphysical local carry/route visuals, reservation cues and quiet wallet updates. No walking reward refreshes an operator's competitive target presentation. SharedMilestone counts 12 successful Free Play/takeout completions and gives 10 session coins only to present actual contributors; Record Run never contributes. No paid or persistent coin economy added.

## Milestone 2 first visual slice

LauncherArt builds a compact oven/tray/barrel/gauge/crank around the unchanged launch pivot. PizzaVisual supplies 27 welded massless render parts while ProjectileService retains the authoritative collider and physics. CustomerRig adds ten Motor6D joints and eight bounded procedural poses to table 1; original contact proxies and CustomerService lifecycle remain authoritative. Detailed booth treatment is limited to table 1 until slice acceptance. Hidden physical furniture proxies retain their material/response where visual overlays replace dark Fabric.

The mapped ground is now at Y=-12 (top=-2), exposing 42 broad quiet floor tiles, sidewalk and street. The central source-owned facade reveals the oven while keeping doors and collision boundaries. Instructions are reduced to a destination cue, contextual prompt and mounted picker; personal best is on the side wall. Ambient motion is a bounded kitchen fan with explicit teardown. Original owner geometry is untouched.

ResponsiveLayout/UIPresentation use safe content and PreferredInput; essential controls keep readable sizes, upgrades scroll on phones, existing notices hide behind modal panels, and focus restores for controller navigation. Loaded-pizza detail participates in feedback cleanup; recoil is local and cannot move the gameplay origin. Desktop camera is (0,28,67) toward (0,1,-12); short safe viewports use (0,26,67) toward (0,9,-22) to clear the top HUD. Tests include observed native target projections plus actual CoreUI inset.

Modern lighting requires a Technology=Future compatibility seed for current Rojo/Studio serialization. Fresh Studio verification, not only Lune decoding, established Realistic/true/.35. Runtime fill/bloom remains restrained. See ART_PROVENANCE and HERO_PREFABS for source reproduction and budgets. Paid products and persistent session coins remain absent.

## Milestone 2b accepted propagation

All six booths now share the accepted quiet basil/terracotta/cream construction. All six customers use the articulated rig: 152 initial render parts, 60 joints, six 10 Hz loops, bounded to 192 render parts. Original furniture and customer contact proxies, lifecycle, table centers and ballistic anchors remain unchanged. Fixed restaurant startup geometry totals 756 parts excluding avatars and transient effects.

Standalone takeout on short viewports uses a 340x70 card in the safe top center; queue combinations retain their full controls. Native 667x375 inspection confirmed readable destination/reward text and normal walking controls. The fresh Realistic build passed all-six visual inspection. Next: integrate versioned mastery profiles and bounded analytics; coins/upgrades remain session-only.

## Milestone 3 profile, mastery and analytics

ProfileModel owns validated versioned documents, monotonic mastery/stamps, earned styles and immutable save transforms. ProfileService owns serialized per-user IO, session fencing, autosave/retry and departure/shutdown drains. Studio and unpublished places always use memory. Loading/failure/locked states are distinct from confirmed new profiles; old data cannot be replaced with zero defaults. No historical Record Run migration or persistent session currency was introduced.

GameService emits server-only monotonic receipts after accepted delivery, takeout and frozen Record Run completion. ProfileState/ProfileAction are separate from competitive GameState. Client ChefBook/ChefBookPresentation show five goals, six table stamps, twelve customer stamps, personal record tiers and four earned styles. Server ProfileCosmetics owns quiet nonphysical nameplates, hides them while mounted and preserves unknown namesakes. The first accepted launch completes tutorial memory/profile state; false or stale snapshots cannot revive completed onboarding.

JourneyAnalytics records bounded join/route/mount/service/upgrade/queue/runner/record/profile events and distinguishes blocked first approaches from direct mounts. Only two UI route events are accepted, after character/health/epoch/proximity validation. Published server SDK sends are deferred and bounded; Studio performs no analytics calls. See PROFILE_SYSTEM and ANALYTICS for schemas, failure behavior and backend limits. Paid fulfillment remains unimplemented.
