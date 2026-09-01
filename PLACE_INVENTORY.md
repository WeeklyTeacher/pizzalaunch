# Pizza Launch Place Inventory and Ownership

## A. Transfer gameplay systems to preserve

- `Config`: launcher physics, six table coordinates, accuracy bands, rounds, upgrades, Record Run constants, and unchanged OrderedDataStore name.
- `GameService`: authoritative pizza creation, launch validation, collision resolution, scoring, coins, combos, purchases, launcher lease, walk/launcher mode, and Record Run integration.
- `CustomerService`: twelve rotating identities and complete enter/sit/serve/react/eat/leave/replace lifecycle with table availability ownership.
- `RecordRunService`: countdown, timer, score/combo, personal best, and global top-ten access.
- `InteractionService`, `LayoutService`, and `PropService`: prompts, round seating/dressing, reactive props, and restoration.
- Client HUD: walking prompt, aiming, trajectory preview, power/reload, upgrades, Record Run, result feedback, camera, desktop/touch input, and cleanup.
- Gameplay geometry: launcher origin/camera, six authored tables and plates, customer seats, target arcs, side aisles, and operator/exit positions.

## B. Current shell assets worth importing

- Detailed pizza press: loaded pizza, readable muzzle, oven feed, pressure gauge, crank, red/steel/wood materials, and contained heat/steam.
- Existing large restaurant shell, kitchen/service counter, front order counter/register, side customer door points, window treatment, signs, menu, lights, and décor. These are already shared with Transfer and should be preserved, not duplicated.
- Selected new façade treatment only: exterior forecourt, front wall framing around existing openings, canopy, and readable restaurant identity.

## C. Assets and logic that must not be imported

- Any second or simplified launcher, customer controller, target/table set, scoring loop, UI, remote folder, or Record Run implementation.
- Any architecture placed between launcher muzzle and tables, across side customer aisles, over target plates, or at the operator/exit positions.
- Any Workspace replacement, generated duplicate restaurant, or shell whose collision blocks the existing walk route.
- Any DataStore rename, leaderboard schema change, or global-board behavior change.

## D. Rojo deletion risk

`default.project.json` currently describes Workspace properties and a Baseplate but has no Workspace `$path`. Rojo v7 defaults `$ignoreUnknownInstances` to true when no `$path` is present, so unknown Studio restaurant models are not presently mapped for deletion. The safety state is still implicit and therefore fragile. Recovery work will make `$ignoreUnknownInstances: true` explicit and add a checker that rejects a Workspace `$path` or a missing/false ignore flag.

## E. Ownership boundary

### Studio-owned

- Hand-built restaurant shell, storefront, doors, exterior, counters, tables, props, signs, lighting, and manually placed models.
- Future finalized physical restaurant should live in a Studio container named `StudioRestaurant` and must never be deleted by runtime setup or Rojo sync.

### Rojo-owned

- Scripts/modules under ReplicatedStorage, ServerScriptService, and StarterPlayerScripts.
- Client UI constructed by the client script, remotes created by server startup, services, configuration, and bounded runtime gameplay effects.
- The current generated `PizzaLaunchWorld` remains a temporary source-defined compatibility world until the physical restaurant is baked and reviewed in Studio.

### Explicit boundary rules

- Rojo may own script containers; it may not own or replace arbitrary Workspace children.
- `Workspace.$path` is forbidden.
- `Workspace.$ignoreUnknownInstances` must be true.
- Runtime generation may replace only `PizzaLaunchWorld`; it must not modify `StudioRestaurant`.
- The Transfer backup is read-only and excluded from version-control staging.
