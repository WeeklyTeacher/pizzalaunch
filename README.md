# Pizza Launch

Pizza Launch is a family-friendly Roblox arcade game: aim the restaurant's pizza cannon, charge the shot, and land dinner on the glowing customer's table. Accurate deliveries earn coins, combo bonuses, and session upgrades; misses bounce harmlessly and reset quickly.

## Play the game

- Aim left or right with the mouse, a touch drag, `A`/`D`, or the arrow keys.
- Hold the red **Launch** button, the left mouse button, or `Space` to charge distance.
- Match the `LANDING` distance to the highlighted table, then release.
- Spend coins in **Upgrades** on better tips, wider accuracy zones, or a faster reload.

Mobile play is landscape-only. The launch button is touch-sized and character movement is disabled because all play happens through the cannon.

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
  shared/Config.luau          Shared balance, tables, accuracy, and upgrades
  server/WorldBuilder.luau    Restaurant, cannon, customers, lighting, spawn
  server/GameService.luau     Physics, validation, scoring, combos, purchases
  server/init.server.luau     Server bootstrap
  client/init.client.luau     Camera, controls, trajectory, HUD, touch layout
```

The server owns projectile creation, hit resolution, rewards, combos, and purchases. Clients only submit a clamped aim direction and charge value. World and UI assets are generated from code so the repository remains the source of truth.

## Current scope

Coins and upgrades last for the current server session only. DataStore saving is intentionally deferred until the arcade loop and economy have had broader playtesting. No paid assets, external audio, or unavailable services are required.
