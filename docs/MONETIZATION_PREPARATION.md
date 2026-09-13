# Future cosmetic entitlements - design only

No sale feature is enabled. There are no paid IDs, products, passes, purchase prompts, price labels, MarketplaceService handlers or live sale settings in this implementation. The four Chef Book nameplates are earned through play. This document is the Milestone 4 architecture decision, not approval to sell anything.

## Boundaries

Future candidates are permanent chef styles, launcher skins, pizza/trail/splatter appearance, optional nameplates and guaranteed celebrations. Each needs explicit owner approval and provenance. A skin may replace only cosmetic geometry/effect configuration. It must retain the same authoritative projectile collider, launch origin, mass, muzzle/pivot, target projections, reload, trajectory and collision groups. Spectators' cosmetics must not obscure the operator's view or alter customer availability.

Never sell entry, retries, seconds, score multipliers, combo protection, hitbox size, guidance, power, reload, queue priority, sole-launcher access, basic controls, accessibility, current session coins, random rewards, mystery crates, paid wheels, luck boosts or spend rankings. No missed-day punishment or paid timed pressure. Keep guaranteed ownership and contents clear before any future purchase.

## Proposed future service boundary

The existing ProfileModel/ProfileService owns earned mastery and versioned data; ProfileCosmetics owns only server-created appearance. Future paid ownership must be a separate EntitlementService, with a reviewed server catalog mapping real owner-approved platform identifiers to internal cosmetic keys. It may expose read-only `owns`/`list` and a validated `requestEquip`; no entitlement may enter ShotPolicy, DeliveryScoring, RecordRunService, LauncherQueue or PlayerProgression arithmetic. UI receives display metadata and verified ownership, never authority to grant.

That service must not become a competing writer to the profile key. Grants must use the profile's serialized lease/revision transaction path, or a separately designed ledger with explicit reconciliation. Never assume transactions across different DataStore keys are atomic. Existing profile status/durable/dirty flags and gameplay receipt sequences cannot acknowledge paid fulfillment; verified purchase identifiers and a durable grant/deduplication record are separate requirements.

Version 1 reserves and preserves `pendingFulfillment`, but contains no receipt processor. Do not insert paid receipt state into that field without a versioned schema review. A future migration must distinguish processed receipts, pending durable grants, ownership source and schema version; protect unknown/future data; and define bounded archival without forgetting deduplication. Large unbounded purchase histories must not grow inside the current 512-entry profile validation budget.

The 512-entry limit counts recursively visited key/value pairs across the whole document, not 512 receipts. Paid-ledger capacity and archival are not implemented.

For any future repeat-purchasable product, use a single server receipt owner. Persist grant and deduplication in one atomic per-player transaction, acknowledge only confirmed durable fulfillment, and safely retry delayed or repeated receipts. A purchase UI completion event is not evidence of durable grant. For permanent passes, verify platform ownership on the server and restore appearance after rejoin. Select the product mechanism only after the intended entitlement and restoration behavior are approved. These requirements follow the official [developer product guidance](https://create.roblox.com/docs/production/monetization/developer-products) and [MarketplaceService API](https://create.roblox.com/docs/reference/engine/classes/MarketplaceService).

No live implementation should acknowledge from a session-only default or bypass a locked/failed profile. A stale server must not grant twice or erase a later server's ownership. Backend outages leave fulfillment pending and ordinary gameplay available. Never hard-code displayed Robux prices; future presentation must use approved live platform metadata with an unavailable state.

An ownership lookup failure remains unknown and must not erase confirmed ownership. Prevent repurchasing an already-owned permanent cosmetic; restoring ownership is not another sale.

## Required approval evidence before implementation or sale

1. Owner approves exact cosmetic, guaranteed contents, platform mechanism and real identifier. No fabricated placeholders or product creation during this run.
2. Profile backend validation passes in a separately approved test experience: new/existing/failed load, rapid rejoin, two-server handoff, throttling, shutdown and ownership restoration. Current fake-backend tests are not this evidence.
3. Receipt fault tests cover duplicate, concurrent and out-of-order delivery, uncertain write responses, durable grant followed by lost acknowledgement, leave during fulfillment, new server takeover and repeated restoration. Grant and acknowledgment must remain durable and idempotent.
4. Compare baseline and equipped authoritative configuration/physics for every style; test ordinary and Perfect effects, two/four players, mobile, controller and accessibility. No obstruction, advantage or queue preference is allowed.
5. Review provenance, part/effect budgets, fresh Rojo build/live-sync parity, understandable ownership UI and recovery procedures. Then obtain explicit permission for publishing and sale configuration.

The smallest next step is persistence and multiplayer validation by the owner, not a store screen. Data and appearance boundaries are prepared; paid fulfillment and sales remain intentionally unimplemented.
