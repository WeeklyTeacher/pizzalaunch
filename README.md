# Pizza Launch

Pizza Launch is a family-friendly Roblox arcade game: aim the restaurant's pizza cannon, charge the shot, and land dinner on the glowing customer's table. Accurate deliveries earn coins, combo bonuses, and session upgrades; misses bounce harmlessly and reset quickly.

## Play the game

- Move the mouse to aim naturally left/right and raise/lower the launch arc.
- Keyboard: `A`/`D` or left/right arrows turn; `W`/`S` or up/down arrows change arc.
- Touch: drag to aim or use the large four-way aim pad.
- Hold the red **Launch** button, left mouse button, or `Space` to charge power, then release.
- Follow the dotted arc and landing ring. Green is lined up, yellow is close, and orange needs adjustment.
- Deliver the round's orders, build combos, earn accuracy bonuses, and spend coins on earnings, precision, reload, and power upgrades.

Mobile play is landscape-only. The launch button is touch-sized and character movement is disabled because all play happens through the cannon.

## Progression

The restaurant runs four escalating service rounds:

1. **First Orders** — three short shots with generous accuracy.
2. **Dinner Rush** — four orders across the near and middle lanes.
3. **Full House** — five longer shots with standard accuracy.
4. **Master Chef** — six orders across the full restaurant with tighter plates.

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
  server/init.server.luau     Server bootstrap
  client/init.client.luau     Camera, controls, trajectory, HUD, touch layout
```

The server owns projectile creation, hit resolution, rewards, combos, rounds, reactions, prop resets, and purchases. Clients only submit a validated 3D aim direction and charge value. World and UI assets are generated from code so the repository remains the source of truth.

## Audio assets

Pizza Launch uses short, free Creator Store sound effects—no copyrighted music or paid assets:

- Pro Sound Effects: Balloon Pop 4 (`9113263647`), Fast Airy Whoosh (`9126229255`), Creature/Box Impact (`9113974103`), and Glass Splat 8 (`9114615986`).
- Free Creator Store pickup chime (`4612374036`) for delivery rewards.

All five IDs were preloaded successfully in Studio during the 2026-08-30 quality pass.

## Current scope

Coins and upgrades last for the current server session only. DataStore saving is intentionally deferred until the revised economy has broader playtesting. The table layout is fixed, while target pools, shot distance, accuracy, goals, and bonuses escalate across rounds.
