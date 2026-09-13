# Council decisions

## 2026-09-13: correctness before expansion

The requested six council specialties use Astra Ultra, scheduled in waves within available concurrency. All inspect actual source. The lead makes the integrated decision and owns release checks.

Authority, UX, art, persistence, and QA audits independently reproduced the reported Milestone 0 flaws in source. Selected approach: extract focused state/policy modules and repair each authority boundary while retaining tuning, scoring, table centers, and the two launcher modes.

Rejected alternatives: rewriting the entire game at once; hiding failed persistence behind session-best copy; allowing walker inventory to drive shared station geometry; resetting prop presentation from a hidden snapshot; accepting silence as a launch rejection; treating a source build as Studio preservation evidence.

Acceptance criteria: immutable completed submissions survive cancel/replay; failed saves retain retryable bests without zero-overwrites; only the lease owner controls station policy; picker inputs cannot consume readiness; explicit launch acknowledgement recovers rejected requests; round 3/4 props retain current layout visibility after resets; stale character/shot callbacks cannot affect a new lease; bystanders cannot physically deflect competitive projectiles; generated recovery copies contain every current mapped module; all checks pass before pushing.

## Multiplayer design boundary

Takeout Runner is an independent walking activity, not a launcher mode. Orders use server-owned per-player state, two short destinations, proximity validation, and session-coin rewards. It must function without an operator and have no competitive dependencies. Queue uses FIFO plus a short approach reservation; no teleport, auto-mount, fabricated Free Play ETA, or queue priority purchase. Shared milestones reward actual contributors only after runner behavior is tested.

## Art direction

Cozy toy-like neighborhood pizzeria. Priorities: launcher, flying pizza, hungry tables. Fix only the mapped ground object, then simplify floor/sign hierarchy, review camera and launcher visual basis, and validate one hero slice before expansion. Source-native procedural assets keep provenance and reproducibility in Git without purchased assets or invented IDs.

## Economy and persistence

Coins/upgrades remain explicitly shift/session-only. Historical competitive store and values remain unchanged. Any future durable mastery/cosmetic profile is separate, versioned, and must distinguish a new profile from failed load. No paid products, prompts, IDs, prices, or live-sale configuration during this run.
# Milestone 0 acceptance evidence

All six council specialties inspected their actual source. Final cross-review found and repaired customer reaction callbacks surviving a lease and knocked props surviving operator release. Owner-only cleanup now invalidates both. Client review fixed processed Space/aim keys under Roblox's movement sink while retaining picker, shop and text-entry gates.

The layout/prop frozen hashes were replaced by executing the real modules across rounds and resets. Mapping, canonical recovery hashes and unchanged bootstrap safeguards remain. Source wiring assertions were updated to the extracted ownership boundaries, with executable client bootstrap and GameService handler tests beneath them. No failing assertion was bypassed.

Acceptance requires recovery safety/contracts, all Luau specs, compilation, fresh Rojo build, full diff review and observed single-player Studio checks. Real two/four-player physics, native touch/controller and live persistence remain separately recorded requirements; doubles cannot establish those claims.

## Milestone 1 route and isolation decisions

Use an activity-only snapshot channel instead of extending launcher GameState: a runner reward must not invoke mounted target, camera or input presentation. Shared rewards use the same quiet channel, including when a past contributor is now in Record Run. Only actor-specific reward receipts claim earned coins; public milestone notifications never imply an AFK reward.

Real walking QA rejected the initial direct far-side route: it crossed the trash bin at X43/Z149 and the bench. The corrected guide stays at Z145, then turns around each obstacle; Sunny uses two clearance corners. Return trips reverse the approach/crosswalk route instead of pointing diagonally through the van. Existing props remain untouched. Client guidance uses close corner arrival, not nearest-point skipping. Actual authored-collider tests reproduce the old obstruction and pass the revised outbound/return envelopes.

Queue transparency does not add launcher capacity. No independent practice lane is added without evidence that the runner plus honest waiting remains inadequate; observing real player abandonment is still an owner playtest requirement.

Fresh multiplayer QA exposed a pre-existing build-only ground defect: a project `Position` value live-synced to Y=-10 but the binary place opened at Y=0. This put the baseplate top at Y10 and lifted walking avatars above prompt range. Repair the exact mapped Baseplate with an explicit CFrame at the same intended Y=-10 before the multiplayer checkpoint. RojoBuild.spec now compares every other mapping property to the protected baseline and inspects the actual binary transform. The M2 floor reveal remains a separate Y=-12 decision. Unknown Workspace objects are untouched. Reference: [Rojo CFrame property format](https://rojo.space/docs/v7/properties/).
