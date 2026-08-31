# Pizza Launch Upgrade Roadmap

Updated: 2026-08-30

## Council review

The current build has a satisfying, server-authoritative launch and reward loop, a colorful generated room, responsive trajectory guidance, and reliable temporary mess. Its largest weakness is framing: players spawn as an invisible camera attached to a permanently active cannon, so the decorated room still reads as a target gallery rather than a restaurant they inhabit.

### Current problems observed

- The character is hidden, normal movement is sunk, and the scriptable launch camera is forced every frame.
- The launcher has no interaction boundary; play begins in an aiming view before the player understands the restaurant.
- The nearest tables sit close to the muzzle and demand unusually low charge, which is less intuitive than later shots.
- All six large customer bubbles exist in the world. Client hiding reduces some clutter, but reactions and signs still compete with the restaurant staging.
- Every table/customer is always occupied and stays in one arrangement, making rounds visually repetitive.
- Customers have good visual variety and reactions but no idle motion, arrival/served transition, or lightweight walk-up interaction.
- The service counter is visually far behind the dining room and is not part of the player's movement loop.
- Reactive props work, but their placement is concentrated in firing lanes instead of at believable restaurant interaction points.
- World, gameplay, and client scripts are growing large; new behavior needs clean ownership boundaries.

## Player experience goals

- A new player can walk into a recognizable restaurant, see the highlighted order, approach the launcher, and understand the interaction within ten seconds.
- Walking feels like normal Roblox; operating the launcher feels like a focused arcade station; switching either way is immediate and reliable.
- First-round shots use comfortable distance, broad delivery zones, and unobstructed sight lines.
- Only the active order receives a prominent marker. Waiting customers communicate through small icons, pose, and color.
- Each shift changes who is seated and which lanes are active without moving a target during a live shot.
- NPCs appear to wait, look around, greet, celebrate, and cycle after service while never blocking the launch lane.
- Misses create readable, temporary comedy and always restore the room.

## Priority 1 — implement during this run

- [x] Add a server-owned walk/launcher mode state with validated enter and exit remotes.
- [x] Add a launcher `ProximityPrompt` (`E` / touch) behind the front counter and a clear floor queue/interaction marker.
- [x] Restore visible player characters and ordinary third-person movement while walking.
- [x] Switch to the scriptable aiming camera, trajectory, launch controls, and movement lock only while operating the launcher.
- [x] Add a visible Exit Launcher button plus keyboard escape path; restore the character/camera safely on death or respawn.
- [x] Rework the front of house so the service counter, register, prep shelf, launcher station, and customer area form a believable loop.
- [x] Move the two opening targets farther from the muzzle and keep a wide central aisle with fair left/right sight lines.
- [x] Replace persistent customer speech bubbles with subtle waiting icons; show one compact active-order marker only.
- [x] Add launcher, register, and customer contextual prompts with short status lines in one reusable HUD toast.
- [x] Add deterministic round layouts that enable different customer/table groups and light, authored obstacle sets only between shots/rounds.

## Priority 2 — implement after the mode switch is stable

- [x] Add bounded customer idle gestures and look-around motions with staggered timers.
- [x] Add served/customer-cycle choreography: celebrate, step safely away from the table, and settle back into the authored seat pose.
- [x] Give each customer a concise personality/status line and mood icon without dialogue trees.
- [x] Distribute napkin dispensers, parmesan, pepper flakes, cups, menus, and sauce bottles across side tables and counter edges.
- [x] Centralize reactive-prop reset and temporary-effect cleanup rules with caps and collision restoration.
- [x] Add round-specific visual dressing: open seats in First Orders, busier Dinner Rush, a safe center sign obstacle in Full House, and full seating/pizza boxes in Master Chef.
- [x] Add a compact walk-mode objective card and hide cannon-only controls/trajectory when not in launcher mode.
- [x] Verify desktop and phone-landscape UI in both walk and launcher modes.

## Priority 3 — continued upgrades

- [x] Add an optional one-minute Record Run with countdown, authoritative score/combo, results card, personal best, and all-time top-10 wall.
- [ ] Add optional bonus orders that reward bank shots or prop ricochets without blocking normal progress.
- [ ] Add authored customer entrance paths using waypoint tweens or pathfinding only outside active shot lanes.
- [ ] Add multiple launcher stations or per-player visual rigs after a dedicated multiplayer test.
- [ ] Split remaining large client UI and server scoring code into focused modules after behavior stabilizes.
- [ ] Add accessibility settings for guide opacity, camera shake, sound volume, and high-contrast target colors.
- [ ] Add guarded session recovery and eventually DataStore persistence after economy playtesting.
- [ ] Add more restaurant themes only after the core dining room retains clarity across devices.

## What will be implemented during this run

Completed in this run: Priority 1 plus the listed safe Priority 2 work—the walk/launcher loop, contextual prompts, fairer floor plan, compact target communication, deterministic round seating/obstacles, idle/customer-cycle behavior, expanded prop comedy, responsive mode-specific HUD, and live Studio regression testing.

## Ideas intentionally deferred

Focused follow-up completed: the existing station now offers a separate 60-second Record Run. It preserves free roam and free play, uses fixed competitive physics, calculates points on the server, persists one best score per player in an OrderedDataStore, and presents the global top 10 on an in-world Legends wall.

- DataStore persistence and monetization: economy values still need human balance testing.
- Free-roaming pathfinding customers across firing lanes: high glitch and obstruction risk for little immediate gain.
- Random table placement: unpredictability can invalidate the trajectory guide and create unfair blocked shots.
- Long dialogue, quests, toppings, delivery inventory, or additional restaurants: these dilute the one-more-shot arcade loop.
- Large multiplayer architecture: first make one player's walk/launcher transition completely reliable, then test contention explicitly.

## Council decision notes

- **Gameplay designer:** Preserve the proven physics/scoring system. Improve replayability through changing active seats and readable authored hazards, not more currencies or menus.
- **Environment designer:** Move restaurant identity into the player's route—entrance, host/register counter, prep cues, launcher, aisle, booths—instead of adding decoration to distant walls.
- **Gameplay engineer:** Use a small authoritative interaction service and deterministic layout state. Avoid moving tables during a projectile and avoid NPC pathfinding through targets.
- **Nine-year-old playtester:** Start in walk mode with one short objective, a bright launcher prompt, and forgiving mid-distance tables. Keep only one big marker and minimize reading.
- **Tradeoff:** Showing the avatar reduces immediate fire speed by one interaction, but makes the place understandable and creates a meaningful restaurant fantasy. The launcher prompt and nearby spawn keep that cost under a few seconds.
