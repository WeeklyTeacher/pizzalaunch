# Game state

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

The client separates LauncherInputState, ClientInput, ClientCamera, UITheme, UIConstruction, UIPresentation, Onboarding and Feedback. The bootstrap retains target/aim visuals and integration. Launch requests include a monotonically increasing request ID and cleanup epoch; accepted/rejected replies reconcile readiness against authoritative active-shot/reload state. Picker/countdown/input-modal gating is explicit. Mode requests still use the original protocol; adding mode epochs is planned with multiplayer integration.

Completed records freeze user ID, score, GUID and timestamps before any yield. Session best, confirmed saved best and pending submissions are distinct. Writes serialize per player, retry with bounded backoff, survive local departure, and use max-preserving UpdateAsync transforms. Corrupt/failed loads cannot cause default writes. Shutdown retries are bounded; pending memory cannot survive a full server failure without a successful DataStore write.

Walker inventory purchases cannot update an operator's world policy. All avatar descendants use a collision group isolated from projectiles and reactive props. Resolved pizzas lose collision/touch/query; owner cleanup clears active and lingering shot visuals, cancels customer feedback and restores knocked props before releasing the lease. Layout owns current-round visibility while PropService restores only authored poses and layout-owned presentation.

Recovery generation now discovers every required script through Rojo and checks the complete source inventory. It overlays only owned script roots into a new ignored copy, verifies canonical hash and Workspace serialization before/after, and refuses existing/unsafe output paths. Normal builds still use Rojo. The pinned local Lune harness executes actual production modules with explicit engine boundaries.

## Next checkpoint

Complete Milestone 0 fresh-build runtime check and checkpoint, then independent Takeout Runner and honest FIFO launcher reservations. Use a separate RestaurantActivity snapshot channel so walking activity never updates an operator's target presentation. Visual work follows the runner loop.
