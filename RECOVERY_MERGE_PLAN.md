# Pizza Launch Safe Recovery Merge Plan

## Recovery baseline

- Recovery branch: `recovery/safe-transfer-merge-20260831`
- Starting commit: `620262d174bea75cbfcbc015d77cc1cf1fd42850`
- Starting status: clean tracked tree; untracked `recovery/` containing the supplied backup.
- Supplied backup found at `E:\projects\roblox\pizzalaunch\recovery\PizzaLaunchTransfer.rbxl`.
- Backup SHA-256: `73B3D5DF3B72F9B13350790759B715BC0E510BB7A41FED3C895F58BD17F11088`.
- No file named `PizzaLaunchTransfer.original.rbxl` was present. The available file will not be renamed, moved, edited, opened in Studio, or used as a Rojo target.

## Audit result

The Transfer place is the gameplay base. A read-only binary inventory found 92 descendants and all ten gameplay scripts, but no saved restaurant: Workspace contains only Camera, Baseplate, Terrain, and SpawnLocation. The complete restaurant and game are created at runtime by `WorldBuilder`.

The current source is not an empty replacement. It is a direct descendant of Transfer:

- Byte-identical: `CustomerService`, `InteractionService`, `LayoutService`, `PropService`, and server bootstrap.
- Additive deltas: launcher cleanup in `GameService`, upgrade readability in client/Config, DataStore diagnostics in `RecordRunService`, and physical cannon detail in `WorldBuilder`.
- Transfer already contains the full customer lifecycle: `SeatedWaiting → Served → HappyReaction → Eating → Leaving → Despawn → Entering → WalkingToSeat → SeatedWaiting`.
- Transfer already contains six tables, fair authored target positions, walk/launcher mode, free play, Record Run, coins, upgrades, customer entrance points, side-aisle routing, front counter, kitchen, doors, signage, and décor.

## Merge strategy

1. Never modify the Transfer backup. Verify its SHA-256 before and after every artifact-generation step.
2. Keep all Transfer gameplay systems and authored target geometry intact. Do not replace Workspace wholesale and do not import a second launcher, table set, customer controller, UI, or scoring loop.
3. Retain the audited additive launcher cleanup and UI improvements because they wrap, rather than replace, Transfer gameplay.
4. Make the environment merge only in `WorldBuilder`:
   - preserve all table positions, launcher origin, camera, and customer side aisles;
   - retain the current detailed pizza press/cannon;
   - add a coherent front façade, sidewalk/forecourt, entrance framing, canopy, and signage around the existing Transfer door and spawn geometry;
   - keep all new architecture behind or outside the launcher firing plane.
5. Keep `CustomerService` unchanged. Its byte-identical Transfer flow already enters through the authored front-door points, seats, serves, reacts, leaves, frees the table, and replaces the customer.
6. Do not change `RecordRunService`, DataStore names, or leaderboard behavior during this merge.
7. Make Workspace ownership explicit in Rojo: unknown Studio instances must be ignored, no Workspace `$path` is allowed, and the safety checker must pass before any sync.
8. Build a new merged artifact from the Transfer DataModel copy with reviewed source scripts. Never serialize back to the Transfer path.

## Commit sequence

1. Audit documents and Rojo pre-sync guard.
2. Selected storefront/environment merge, with gameplay modules unchanged.
3. New recovery artifact, build verification, inventory update, and truthful validation log.

## Validation boundary

Automated checks will verify source ancestry, customer lifecycle states, target coordinates, launcher/Record Run code paths, Rojo safety, build output, diff cleanliness, and unchanged backup hash. Roblox Studio runtime behavior and visual quality will be listed as manual until actually tested in Studio.
