# Reusable Roblox Launcher System

This document captures the launcher interaction pattern proven in Pizza Launch. It is intentionally game-agnostic so a future Book Launch, Ice Cream Launch, or similar experience can reuse the architecture without importing Pizza Launch's restaurant, scoring, or art.

## Player flow

Use one legible path:

`spawn/entrance -> visible attraction sign -> floor-safe route -> exact use pad -> USE LAUNCHER -> mounted mode picker -> active play -> results or mode picker -> exit`

The attraction remains identifiable without tutorial UI. First-visit guidance adds only a short contextual hint, route markers, and a highlight. It fades after the first server-accepted launch. Do not ship an inactive or redundant tutorial button merely to make this guidance replayable.

## Mounting state machine

Keep one server-owned launcher lease and one outer player state. A recommended state model is:

- `walking / none`: normal movement; no launcher ownership.
- `launcher / select`: character is mounted and immobilized; mode picker is visible; firing is rejected.
- `launcher / freePlay`: normal launcher scoring with no timer.
- `launcher / recordRun`: countdown, timed play, saving, and results are phases of the same mounted lease.
- `cleanup`: invalidate delayed work, destroy the active shot, cancel run state when appropriate, restore movement/camera, release ownership, then return to `walking / none`.

Mount only after the server verifies the requesting character, living Humanoid, proximity to the authoritative interaction anchor, and launcher availability. Move and orient the HumanoidRootPart at a safe, visible use pad and anchor it while mounted. Reject repeat mount and launch requests. Cleanup must run for explicit exit, death, character replacement, player removal, and server-side invalid state.

Do not build separate physical prompts or independent mount state machines for each mode. The prompt claims the launcher; the mounted picker selects a submode.

## Mode selection

Present two equally weighted choices after mounting:

- `FREE PLAY` — practice launches with no time limit.
- `1-MINUTE RECORD RUN` — score as many points as possible in 60 seconds.

The client requests a mode, but the server validates the lease, mounted state, active projectile, and run phase before changing it. Free Play and timed play share aim, charge, projectile, hit, cleanup, and camera systems. Only the policy changes: timer, fixed competitive tuning, eligible targets, score, combo, and persistence.

Keep results compact and nonblocking. During saving, retain the lease and disable another start. When results are ready, offer Choose Mode and Exit. Returning to Free Play or another run must not require rediscovering the world prompt.

## First-time guidance and waypoint placement

- Begin at the actual spawn/entrance camera sightline, not a developer test position.
- Validate the sign, arrows, destination, and prompt through the real player camera after physically walking the spawn-to-interior route. Instance existence, coordinates, and an editor camera are not evidence that a player can see the guidance.
- Put a permanent, high-contrast attraction sign above or behind the launcher area using plain language.
- Derive the final waypoint, highlight, prompt-distance check, and mount validation from one authoritative interaction anchor.
- Lay intermediate waypoints in traversable open space. Keep them outside furniture, ovens, doors, queues, and collision bottlenecks.
- Raycast each marker to approved walkable surfaces and place it slightly above the hit surface. Never use one hard-coded world Y for a route across multiple floor levels.
- The final marker must end at the use pad, not the decorative launcher model or an invisible seat inside scenery.
- Make guidance client-local, anchored, noncolliding, non-touching, non-queryable, shadowless, and disposable. Destroy parts and disconnect update loops on teardown.
- Reduce guidance after success, but retain permanent environmental identification. Remove inactive, broken, or useless tutorial controls instead of shipping dead affordances.

Persist tutorial completion only when the game already has a suitable per-player profile schema and migration policy. Do not overload leaderboard or competitive score stores. Session-local completion is safer than unrelated persistence.

## Responsive launcher UI

- Initialize essential persistent menu buttons deterministically during PlayerGui construction. Their first-frame visibility must not wait for mounting, scoring, onboarding completion, a stat update, or any delayed server event.
- Keep persistent navigation ownership separate from launcher-mode presentation. A launcher transition may temporarily hide a button only for an overlapping modal and must restore it as soon as that modal closes; it must not rewrite the button's intended general visibility.
- Use readable Roblox-supported fonts, high contrast, short labels, and generous hit targets.
- Respect safe-area/top-bar insets and use scale constraints for desktop, phone landscape, tablet, and console.
- Keep the mounted picker centered and concise; hide it completely when play begins.
- Keep gameplay HUD at the edges. Do not cover the launcher muzzle, trajectory, landing point, or target lanes.
- Provide keyboard/mouse, touch, and gamepad bindings. Set explicit gamepad selection for the picker and restore it when the picker reopens.
- Always show a visible Exit Launcher action. During Free Play, also show Change Mode.
- Timed play must visibly show the 3-2-1 countdown, 60-second timer, current score, and best score where supported.
- Free Play must explicitly say `NO TIMER`.
- Avoid transient toasts that duplicate and overlap countdown numerals or results.

## Server validation boundaries

The server owns:

- launcher occupancy and lease release;
- mount distance, character health, and anchored mounted pose;
- permitted mode transitions and run phase;
- countdown and authoritative end time;
- launch cadence, charge bounds, aim cone, and projectile creation;
- hit resolution, score, combo, rewards, purchases, and persisted records;
- competitive fixed tuning and eligible targets.

The client owns presentation and input sampling only. Treat remote payloads as requests. Never accept client-supplied score, timer, hit identity, reward, ownership, or mode state.

## Multiplayer occupancy

If only one player can operate a launcher, keep its prompt discoverable while occupied and change the prompt text to a clear occupied state. When another player interacts, the server replies with a concise busy message; it must never move them, change their camera, or mutate the owner's state. If concurrency is desired later, create independent station instances with independent lease/state records rather than sharing mutable singleton client state.

## Cleanup and connection management

- Connect long-lived remotes once during initialization.
- Store and disconnect per-character, per-run, and per-guidance connections.
- Use a cleanup epoch/token so delayed reload, feedback, and countdown callbacks cannot alter a later mount.
- Clear active projectiles and temporary highlights/markers when switching policy or ending a run.
- Make cleanup idempotent; repeated death/exit/removal signals should be harmless.
- Restore camera type, selected gamepad object, movement values, root anchoring, HUD visibility, and prompt presentation.

## Test checklist

Run tests from a clean built place and from a Rojo-synced place where possible:

1. New player follows the entrance route, sees the exact use pad, mounts through the prompt, starts Free Play, launches repeatedly, and exits.
2. Reset session; start a Record Run; verify 3-2-1, initial 1:00, scoring, exact expiry, results, Choose Mode, and a second mode.
3. Returning/session-complete player is not nagged; permanent sign, use pad, and prompt remain available, with no broken or redundant tutorial control.
4. Keyboard/mouse, phone landscape touch, tablet, and gamepad interaction/aim/launch/exit.
5. Desktop and mobile safe-area/readability; no path marker below floors or inside geometry; unobstructed aim and targets.
6. Two players contend for the station; non-owner gets a clear occupied response and cannot affect owner score, timer, camera, projectile, or lease.
7. Exit, death, reset, disconnect, mode switch, countdown cancellation, results, and rapid repeated remote requests.
8. Existing scoring, upgrades, customers, splats, props, leaderboards, purchases, and persistence contracts.
9. Search source and runtime UI for debug coordinates, instance counts, internal phases, placeholder strings, and mixed public mode names.
10. Inspect Studio Output for errors and warnings after every path.

## Pizza Launch mistakes to avoid

- It originally exposed two nearby prompts that silently selected different modes. New players could not infer the relationship. Use one mount prompt and one explicit picker.
- The mount pose was inside decorative launcher/oven geometry, while the useful approach point was elsewhere. The pad, prompt, anchor, validation, and mounted pose must describe the same physical station.
- A route used a fixed Y coordinate and rendered below the floor. Raycast every waypoint to known walkable surfaces.
- `TRAIL READY 42` exposed an internal client part count: seven decorative arrows with six parts each. Never surface diagnostic instance counts; use a player-needed status such as `AIM GUIDE: READY` only when it adds value.
- A second coordinate diagnostic overwrote the walking hint each frame. Debug telemetry must be Studio/developer-only and isolated from player labels.
- Disabling the only prompt while occupied made the launcher appear broken to another player. Preserve discoverability and explain occupancy.
- Mixed names such as challenge, timed mode, speed run, and Record Run increased cognitive load. Pick one public name and enforce it in every sign, prompt, HUD, result, and document.
- Competitive results could become a stopping point. Keep results shallow and include direct Choose Mode and Exit actions.
- A redundant countdown toast obscured the primary numeral. Give each moment one dominant message.
- A persistent upgrades button was gated by launcher/onboarding state, so it appeared only after a first accepted launch and vanished during unrelated mode phases. Initialize essential navigation explicitly and let only its own modal visibility policy control it.
- Spawn-side guidance did not prove that a player inside the restaurant could see where to return. Walk the actual route at desktop and mobile camera sizes; add a restrained interior-facing direction cue and floor-safe return markers when the attraction sits behind the entering camera.
- A visible tutorial button with no useful behavior shipped as a dead promise. Contextual world guidance can stand on its own; remove nonfunctional controls and their replay-only state/connections.

## Future extraction

Pizza Launch currently remains self-contained so its Rojo paths and tested behavior do not change. A future shared module should be extracted only after a second game exists. At that point, separate a configuration-driven server lease/mode controller, client picker component, waypoint projector, and contract-test package; prove them in both games before declaring the shared package authoritative.
