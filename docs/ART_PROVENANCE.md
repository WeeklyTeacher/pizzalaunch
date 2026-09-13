# Source art and reproduction

This checkpoint uses original procedural geometry authored for Pizza Launch in
the repository. No purchased assets, external meshes, bitmap textures, animation
IDs, product IDs, or additional audio IDs were introduced. There is no DCC source
or mesh export to recover: the Luau prefabs are the editable source. Existing
project licensing applies; this record does not assert a new third-party license.

| Source | Reproducible content | Runtime owner |
| --- | --- | --- |
| `src/server/LauncherArt.luau` | Compact oven body, feed tray, yoke, rounded barrel, pressure gauge, crank and bounded launch emitters | `PizzaLaunchWorld.LauncherStation` |
| `src/shared/PizzaVisual.luau` | Raised crust, cheese, pepperoni, basil and bake variation; loaded and flying variants | Cosmetic model welded to an explicit carrier |
| `src/server/WorldBuilder.luau` | Cream/plaster architecture, sand floor tiles, grounded support art, six muted booths, signage and runtime daylight/practical light values | `PizzaLaunchWorld` only |
| `src/server/WorldActivityService.luau` | Three-blade kitchen exhaust fan at eight updates per second | Explicit source-owned `KitchenVentFan` fixture |

Generate a fresh source place with `rojo build default.project.json -o
.qa-artifacts/<checkpoint>.rbxl`. Use the checked-in Rojo/Rokit configuration;
units are Roblox studs. The source world is constructed when the server starts.
No exported place or mesh is a canonical input. Fresh-build visual validation is
required as well as live synchronization; the mapped Baseplate uses explicit
CFrame because a Position-only mapping failed binary serialization in real QA.
Unknown Studio geometry is outside these prefab ownership boundaries.

## Preserved interfaces and geometry

`LauncherArt.build(station, Config, colors, PizzaVisual)` constructs one machine.
`AimPivot` remains exactly at `Config.LAUNCH_ORIGIN`. The approved desktop mounted
camera is at `(0, 28, 67)`, looking toward `(0, 1, -12)`. Compact safe heights below
540 use `(0, 26, 67)`, looking toward `(0, 9, -22)`, to clear the HUD. All six table, plate,
delivery-zone and authoritative customer anchors remain unchanged, as does the
gameplay launch origin. A cosmetic aim/recoil transform cannot define a projectile
origin or alter a collider.

The feedback bindings remain `AimRig`, `LoadedPizza`, `CosmeticMuzzleFlash`,
`FireLight`, `FlourPuff`, `CheeseSpark`, `PizzaFeedOven.WarmOvenSteam`, `OvenGlow`,
`FeedRoller`, `CosmeticCrankRig`, and `PressureGauge.PressureReadout.Label`.
Loaded pizza detail is marked `CosmeticLoadedPizza` so launch/reload cleanup hides
and restores every layer together. Pizza parts are noncolliding, nontouching,
nonqueryable and massless; their carrier retains authority over physics.

The old oversized launcher housing collision envelope was replaced deliberately
with one stable 12×8×11 housing collider at (0, 4.4, 66), behind the launch plane.
This follows the visible oven mass instead of retaining an invisible wall from
the wrongly dimensioned old cylindrical pedestal. The platform is unchanged.
All other prefab geometry is nonphysical. The full aim sweep, shot start/forward
lane and normal operator approach are checked geometrically; native Studio
rendering and interaction remain separate acceptance checks.

Tabletop, plate, zone, booth and existing table-support collision geometry remain
unchanged. Grounded table supports and booth legs/seams are cosmetic; rugs
now sit over the authored floor. This intentionally preserves the historical
collision response below tables pending a separately tested replacement.

Native spawn review found the central facade hid the compact oven while its tray
protruded through opaque plaster. Only that source-owned 55-stud facade segment
now presents a low terracotta base, open loading hatch aligned with the tray,
and clear shop window. Its original wall/wainscot collision proxies are retained;
the established player/customer doors, paths and anchors are unchanged. All nine
new window/hatch pieces are nonphysical. Geometry checks sample the spawn and pad
views, while actual visibility approval remains a Studio screenshot decision.

The Realistic-lighting screenshot rendered the first Fabric booth and rug nearly
black despite their configured pale/basil colors. The approved M2a correction uses
quiet SmoothPlastic appearance for those surfaces. Original Fabric seat/back
parts stay as transparent collision proxies, preserving their physical material
response; two exact-size nonphysical shapes carry the visible upholstery.
After native acceptance of the hero slice in `6bc7e8d29cbce3da5158fcdf86b0cdd701fa11de`,
M2b applies that construction to all six existing booths. Basil, subdued terracotta
and cream repeat once around the restaurant; each booth has only two grounded
legs and three small seams. Table dimensions, positions and competitive proxies
are unchanged. No furniture detail was added outside this approved treatment.

## Art scope and budgets

The hero machine contains 71 BaseParts including its loaded pizza and one housing
collider. The floor grid uses 42 broad low-contrast tiles instead of 154 saturated
checker tiles. The M2b booth propagation adds 35 cosmetic parts over M2a. Counts
below were measured by executing the actual source constructors in the fixture:

| Scope | Measured parts | Enforced budget / qualification |
| --- | ---: | --- |
| `WorldBuilder` fixed scene | 594 BaseParts | At most 620; includes the loaded pizza and hidden customer proxies |
| World collision geometry | 156 of the above | Unchanged from M2a; no new booth colliders |
| Fixed practical lights | 13 PointLights, 4 shadowed | At most 13 and 4 respectively |
| `TakeoutWorld` fixtures | 10 BaseParts | Separate from the WorldBuilder count |
| Initial six customer visuals | 152 BaseParts, 60 Motor6Ds | At most 32 parts and 10 joints per rig; six rigs maximum |
| Combined fixed restaurant at startup | 756 BaseParts | Excludes avatars, transient effects and client-local UI |

With the current 594-part world and the 192-part customer visual cap, the same
composition is at most 796 parts across customer identity changes. Customer-rig
tests cover all 12 current identities and the three accessory styles through
turnover. Each rig updates at most ten times per second; the six-rig cap also
bounds its Heartbeat connections. Their source and poses are documented in
`docs/HERO_PREFABS.md`.

A flying pizza adds 28 parts: its unchanged authoritative carrier and 27 visual
parts. Transient effects remain additional scoped budgets, including up to 24
four-part splats, nine-part coin bursts and 18-part confetti bursts. These numbers
are not an overall peak-memory or frame-time guarantee. Avatar populations,
overlapping effects and client rendering still require native performance
measurement; the lead records actual device evidence separately.

Launch emitters have zero continuous rate and short lifetimes; accepted shots
trigger bounded emission through client feedback. Ordinary flash/shake policy is
owned by the client feedback module. Warm practical lights keep their existing
scene roles; neutral fill, lower color-correction saturation and restrained bloom
avoid covering the pizza with orange haze. Current LightingStyle and quality
settings are mapped in the Rojo project, never assigned by a runtime script.

Ambient glass opacity pulses and the two-part sideways street glider were removed.
Their replacement is a six-part kitchen vent, with three rotating nonphysical
blades behind the service counter. One capped Heartbeat connection drives it;
restart/stop disconnects that connection and restores authored poses. Epoch checks
reject an already-queued old callback. There are no delayed tasks or ambient
tweens to survive teardown. Missing or unowned fixtures remain untouched.

## Validation boundary

`tests/LauncherArt.spec.luau` executes the actual prefab and checks local axes,
bounded geometry, nonphysical detail and the permitted aim sweep. The test uses
an explicit orthonormal camera basis because the pinned Lune runtime's lookAt
behavior differed from native Roblox in a direct probe. Actual Studio uses the
native CFrame APIs. `WorldContracts` protects anchors, historical furniture
proxies, grounded cosmetic supports, world/light budgets, ownership and prompt
count. `HeroFacade` checks sampled window views and all six booth overlays and
palette families. The binary Rojo test separately protects fresh-build ground
parity.

The lead records observed screenshots, fresh/live parity, mobile composition,
Output and limitations in `docs/TEST_MATRIX.md` and `BUILD_LOG.md`. Source tests
alone do not establish final visual quality, mobile frame time, sound permissions,
or preservation of geometry in an unknown owner place. Existing sound IDs were
retained; their external permission/provenance review remains unperformed.
