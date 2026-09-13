# Pizza Launch

Pizza Launch is a family-friendly Roblox restaurant arcade game. Walk through the pizzeria, greet a changing cast of customers, use the Pizza Launcher, and land dinner on any hungry table. Accurate deliveries earn coins, combo bonuses, and session upgrades; misses create harmless, temporary restaurant chaos.

## Play the game

- Walk with normal Roblox movement (`WASD`, thumbstick, or touch controls).
- Follow the pizza arrows to the pizza-shaped launcher pad, then use `E`, gamepad `X`, or the large touch prompt labeled **USE LAUNCHER**.
- Choose **FREE PLAY** or **1-MINUTE RECORD RUN** after mounting. Both choices use the same launcher and server-owned mount state.
- While operating, move the mouse to aim naturally left/right and raise/lower the launch arc.
- Keyboard: `A`/`D` or left/right arrows turn; `W`/`S` or up/down arrows change arc.
- Touch: drag to aim or use the large four-way aim pad.
- Hold the red **Launch** button, left mouse button, or `Space` to charge power, then release.
- Press `Q` or the visible **Exit Launcher** button to return to walking.
- Walk up to customers for a short mood/order line, or check the front register for shift progress.
- Follow the dotted arc and landing ring. Green is lined up, yellow is close, and orange needs adjustment.
- In Free Play, serve any visible hungry customer. Customers celebrate, eat, leave through the side entrances, and return as new guests.
- Deliver the round's orders, build combos, earn accuracy bonuses, and spend coins on earnings, precision, reload, and power upgrades.
- While walking, pick up a takeout pizza and follow its marker to one of two neighborhood destinations. Earn 8 session coins, plus an optional 2 for a quick delivery.
- If the launcher is occupied, join the line or do takeout orders. Free Play has no time limit; a released turn offers the next player a 15-second reservation to approach normally.

Mobile play is landscape-only. Normal touch movement appears while walking; it is replaced by the dedicated aim pad and launch controls only while operating the cannon.

## 1-Minute Record Run

Choose **1-MINUTE RECORD RUN** from the launcher mode picker to start a three-second countdown followed by 60 seconds of launches. Every currently occupied table becomes a glowing choice only during the run. Near, middle, and far tables pay progressively more points, so players can repeat a difficult far table after its next customer arrives or take safer nearby deliveries. Perfect and Great accuracy add bonuses. Consecutive correct deliveries raise a stepped multiplier from 1x to 2x, while misses and wrong hits reset the run combo.

Record scoring is calculated entirely by the server. Record runs use fixed launch power, reload timing, and accuracy assistance so session upgrades cannot affect the all-time competition. The end card shows final score, personal best, and top-10 status. The wall-mounted **Pizza Launch Legends** board reads the ten highest saved personal records from an `OrderedDataStore`.

## Progression

The restaurant runs four escalating service rounds:

1. **First Orders** — two open, comfortable lanes and three forgiving deliveries.
2. **Dinner Rush** — four occupied tables across the near and middle lanes.
3. **Full House** — middle/far seating plus a safe reactive sign obstacle.
4. **Master Chef** — all six customers, tighter accuracy, and a distant knockable box stack.

Round completions pay coin bonuses. Master Chef repeats as an endgame score/combo challenge.

## Studio and Rojo setup

Requirements: Roblox Studio, the Rojo Studio plugin, and Rojo 7.7.0. This repository includes a Rokit tool manifest.

```powershell
rokit install
rojo serve default.project.json --address 127.0.0.1 --port 34872
```

In Studio, open a new baseplate/place, open the Rojo plugin, connect to the local server, and sync. Press **Play** to run both the server-generated restaurant and client HUD.

### Persistence testing

Do not publish or enable production DataStore access during local development. The mastery profile service always uses memory in Studio or unpublished places. Record persistence uses its existing store when available; use the isolated fault tests to verify retry and ownership behavior without touching player data.

When record storage is unavailable, gameplay still works with session bests and honest save status. Expected unpublished-place warnings may appear in Output. Real backend rejoin and server-handoff tests require a separately approved test experience; they are not established by the local tests.

To build a standalone place file instead:

```powershell
rojo build default.project.json -o .qa-artifacts/PizzaLaunch-local.rbxl
```

Open the generated local place in Studio and press **Play**. A source-only build does not include or prove preservation of unknown Studio-owned geometry. Recovery inputs and `StudioRestaurant` must remain untouched. See [current architecture and scope](docs/GAME_STATE.md), [test evidence](docs/TEST_MATRIX.md), and [profile design](docs/PROFILE_SYSTEM.md).

## Project structure

```text
src/
  shared/Config.luau          Tables, two-axis ballistics, rounds, and upgrades
  server/WorldBuilder.luau    Pizzeria, NPCs, kitchen, props, lighting, spawn
  server/GameService.luau     Remote/lifecycle integration and delivery routing
  server/LauncherLease.luau   Validated station ownership and character restoration
  server/ShotPolicy.luau     Request validation and fixed competitive tuning
  server/ProjectileService.luau  Server physics, avatar isolation and cleanup
  server/TakeoutRunner.luau   Independent walking orders and rewards
  server/LauncherQueue.luau   FIFO approach reservations
  server/ProfileService.luau  Versioned mastery, safe saves and session fencing
  server/JourneyAnalytics.luau  Bounded server events and validated route cues
  server/InteractionService.luau  Launcher/register/customer prompt routing
  server/CustomerService.luau     Server-owned seating, service, departure, arrival, and hit states
  server/LayoutService.luau       Deterministic round seating/obstacle dressing
  server/PropService.luau         Capped knockable props, exact restoration, and mode cleanup
  server/RecordRunService.luau    Timed scoring, personal bests, OrderedDataStore top 10
  server/init.server.luau     Server bootstrap
  client/init.client.luau     Integration for camera/input/UI components and trajectory
```

The server owns launcher occupancy, projectile creation, hit resolution, rewards, combos, rounds, record timing/scoring, reactions, prop resets, and purchases. Clients only submit a validated 3D aim direction/charge while they hold the launcher lease. World and UI assets are generated from code so the repository remains the source of truth.

## Audio assets

Pizza Launch uses short, free Creator Store sound effects—no copyrighted music or paid assets:

- Pro Sound Effects: Balloon Pop 4 (`9113263647`), Fast Airy Whoosh (`9126229255`), Creature/Box Impact (`9113974103`), and Glass Splat 8 (`9114615986`).
- Free Creator Store pickup chime (`4612374036`) for delivery rewards.

All five IDs were preloaded successfully in Studio during the 2026-08-30 quality pass.

## Current scope

Record Run personal bests and the all-time top 10 persist through an OrderedDataStore when Roblox services are available. Coins and upgrades still last for the current server session only; economy persistence remains deferred until broader balance testing. Furniture positions are authored and stable for predictable physics. Customer occupancy changes through deterministic, server-owned entrance and seating routes that stay outside the launcher and target lanes.

Chef Book adds a separate versioned profile for mastery, table/customer stamps, completed-run milestones, earned nameplates and tutorial completion. It never changes competitive tuning or converts session coins into durable currency. Local Studio profiles use memory only. See the current test matrix for backend and hardware cases that still require owner validation.
