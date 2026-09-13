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

## Milestone 2 integrated slice decision

Choose quiet warm plaster/cream, subdued terracotta, tomato machinery/actions, basil success and cheese-gold pizza highlights. Reveal the authored floor by moving only mapped Baseplate to Y=-12; simplify the revealed checker before judging visual hierarchy. Replace duplicated physical explanations with one destination cue plus contextual prompt and mounted mode explanations. Move personal-best presentation off the entrance sightline.

Build a source-native LauncherArt prefab and shared PizzaVisual prefab; no purchased assets or invented IDs. First articulated customer and detailed booth remain a table-one slice until actual views pass. Cosmetic parts are nonphysical; exact gameplay origin, target centers and delivery/customer/projectile proxies remain protected. An oversized ghost machine collider is not a preserved contract: a compact source-owned pedestal is acceptable after documented clearance checks.

Use current supported LightingStyle/PrioritizeLightingQuality in authored mapping, not runtime script writes. Native fresh-place QA exposed a migration problem that binary inspection alone missed: without an explicit Technology seed, Studio overwrote the modern settings. Retain `Technology=Future` solely as a tested serialization compatibility seed; a second fresh place opened Realistic/true correctly. References: [current Lighting API](https://create.roblox.com/docs/reference/engine/classes/Lighting), [upstream migration issue](https://github.com/rojo-rbx/rbx-dom/issues/637).

The HUD follows available viewport/safe area and active input. Keep essential controls readable rather than scaling every desktop panel down. Native device simulator coverage supplements behavioral tests; real two-finger hardware and human capacity/abandonment still require owner testing.

## Milestone 2b decision and acceptance

Accepted propagation of the M2a slice to six existing booths/customers. Reusing the tested silhouettes was selected over new furniture, additional decoration or altered competitive geometry. Cap six rigs, ten joints each, 10 Hz animation; preserve all proxy geometry and lifecycle. Compact standalone runner objective removes the unused queue row while retaining full queued/reserved presentation.

Acceptance passed: all 25 behavior specs, recovery contracts/safety, source compilation, fresh Rojo build, full diff review and whitespace check. Native fresh Studio verified six rigs/152 parts/60 joints, Realistic lighting, ground Y=-12, mounted phone composition and readable 340x70 runner card. Local five-second frame sample is diagnostic only; physical phone performance and human queue abandonment remain untested. M3 drafts stayed ignored and unmapped during this checkpoint.

## Milestone 3 integrated decision

Keep coins and upgrades shift-only; add durable mastery and earned cosmetic nameplates through a separate versioned profile. This avoids silently changing the finite session economy or historical competitive data. Session-token fencing and immutable revision retries were selected over load-default-save behavior. Failed profile loads keep normal play available without pretending to be new players. Uncertain backend ownership is decided by atomic transforms, not stale local timestamps.

Chef Book is a walking modal with readable scrolling goals/stamps, quiet navigation and explicit local/loading/save status. It cannot repaint mounted competitive state. Server receipt sequences are independently scoped to deliveries, takeout and completed runs; client requests can only read the profile or equip an earned catalog style. Cosmetics never alter physics or launcher tuning.

Analytics uses a fixed event vocabulary and three bounded fields, with separate initial blocked/direct cohorts. Two UI route messages require current server proximity and character context; all rewards and achievements originate from existing authoritative outcomes. Deferred SDK failures may lose telemetry but cannot block gameplay. Paid products remain prohibited in this run.

Acceptance requires the full recovery/behavior/build suite, four-player source-boundary isolation, failure/reconnect fault injection, native book/earned-style/progression and lifecycle checks, and explicit NOT RUN live backend/hardware cases. Review caught and fixed late-acquisition orphan leases, uncertain-renewal local expiry, stale book focus on death, and shared read/equip cadence suppressing immediate selection. No failing checkpoint is pushed.

## Milestone 3b extraction decision

Complete the delivery ownership boundary after the integrated mastery checkpoint. Extract the existing transaction into DeliveryService, retaining exact synchronous ordering and delayed callback guards. Keep profile/analytics/shared hooks in GameService and inject existing service instances. Rejected alternatives: changing rewards/rounds during extraction or constructing duplicate authority state. Acceptance requires the full suite, concrete numeric outgoing reward tests, unchanged four-player integration behavior and a fresh native delivery smoke test.

## Milestone 4 final council decision

Prepare documentation and service boundaries only. Future EntitlementService must use the profile's serialized writer or an explicitly reconciled ledger; no assumed atomicity across keys, no session flags as purchase confirmation, and no unbounded receipt list in the current document budget. Ownership lookup failure remains unknown and cannot erase confirmed ownership. Permanent cosmetics must not be sold twice to an existing owner. Candidate content is guaranteed appearance only; every competitive/accessibility/queue advantage and randomized sale is excluded.

The persistence council reviewed these requirements against the current source. Paid receipt processing, platform catalog/IDs, product creation, prompts, prices, publishing and live configuration remain intentionally unimplemented. Required next evidence is owner-approved backend and device/multiplayer validation, not a store screen.
