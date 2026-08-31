# Pizza Launch

Pizza Launch is a family-friendly Roblox restaurant arcade game. Walk through the pizzeria, greet customers, step behind the counter to operate the pizza cannon, and land dinner on the highlighted table. Accurate deliveries earn coins, combo bonuses, and session upgrades; misses create harmless, temporary restaurant chaos.

## Play the game

- Walk with normal Roblox movement (`WASD`, thumbstick, or touch controls).
- Use `E`, the gamepad interaction button, or the touch prompt at the glowing launcher to operate it.
- While operating, move the mouse to aim naturally left/right and raise/lower the launch arc.
- Keyboard: `A`/`D` or left/right arrows turn; `W`/`S` or up/down arrows change arc.
- Touch: drag to aim or use the large four-way aim pad.
- Hold the red **Launch** button, left mouse button, or `Space` to charge power, then release.
- Press `Q` or the visible **Exit Launcher** button to return to walking.
- Walk up to customers for a short mood/order line, or check the front register for shift progress.
- Follow the dotted arc and landing ring. Green is lined up, yellow is close, and orange needs adjustment.
- Deliver the round's orders, build combos, earn accuracy bonuses, and spend coins on earnings, precision, reload, and power upgrades.

Mobile play is landscape-only. Normal touch movement appears while walking; it is replaced by the dedicated aim pad and launch controls only while operating the cannon.

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
rojo serve default.project.json
```

In Studio, open a new baseplate/place, open the Rojo plugin, connect to the local server, and sync. Press **Play** to run both the server-generated restaurant and client HUD.

To build a standalone place file instead:

```powershell
rojo build default.project.json -o pizzalaunch.rbxlx
```

Open `pizzalaunch.rbxlx` in Studio and press **Play**. The generated place file and Rojo sourcemap are intentionally ignored by Git.

## Project structure

```text
src/
  shared/Config.luau          Tables, two-axis ballistics, rounds, and upgrades
  server/WorldBuilder.luau    Pizzeria, NPCs, kitchen, props, lighting, spawn
  server/GameService.luau     Physics, validation, reactions, mess, progression
  server/InteractionService.luau  Launcher/register/customer prompt routing
  server/CustomerService.luau     Bounded idle and served-seat choreography
  server/LayoutService.luau       Deterministic round seating/obstacle dressing
  server/PropService.luau         Knockable-prop impulse and reliable restoration
  server/init.server.luau     Server bootstrap
  client/init.client.luau     Camera, controls, trajectory, HUD, touch layout
```

The server owns launcher occupancy, projectile creation, hit resolution, rewards, combos, rounds, reactions, prop resets, and purchases. Clients only submit a validated 3D aim direction/charge while they hold the launcher lease. World and UI assets are generated from code so the repository remains the source of truth.

## Audio assets

Pizza Launch uses short, free Creator Store sound effects—no copyrighted music or paid assets:

- Pro Sound Effects: Balloon Pop 4 (`9113263647`), Fast Airy Whoosh (`9126229255`), Creature/Box Impact (`9113974103`), and Glass Splat 8 (`9114615986`).
- Free Creator Store pickup chime (`4612374036`) for delivery rewards.

All five IDs were preloaded successfully in Studio during the 2026-08-30 quality pass.

## Current scope

Coins and upgrades last for the current server session only. DataStore saving remains deferred until the revised economy has broader playtesting. Furniture positions are authored and stable for predictable physics; occupied seats and safe reactive obstacles change deterministically by round.
