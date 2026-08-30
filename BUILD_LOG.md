# Pizza Launch Build Log

## 2026-08-30 — Playable arcade vertical slice

### Council decisions

- **Finish one complete shot loop before persistence or content breadth.** Game Director: immediate arcade payoff; Engineer: small server-authoritative surface; New Player: one glowing target; Product: coins and combos create replay; Scope: fully testable today.
- **Use a fixed 42-degree arc and let charge select distance.** It makes the dotted trajectory predictable, keeps aiming to one horizontal axis, and lets children compare the landing-distance number directly with the target-distance number.
- **Generate the restaurant from Rojo-managed code.** This keeps Studio and Git synchronized while still producing a colorful, readable space with a cannon, six tables, customers, order signs, lighting, and spawn behavior.
- **Make mistakes funny and cheap.** Floor shots report `FLOOR PIZZA!`, wrong tables do not remove coins, projectiles bounce, and the next pizza is ready quickly. Only the combo resets.
- **Add three small session upgrades after validating scoring.** Bigger Tips, Wider Plates, and Speedy Oven turn coins into a replay reason without premature DataStore risk or simulator complexity.
- **Use a condensed landscape-only touch layout.** A wide restaurant view is fundamental to aiming. On phones, the large desktop tutorial is replaced by one concise control line and avatar movement controls are disabled.

### Built

- Server-generated restaurant with warm lighting, tiled floor, readable colored tables, simple hungry customers, order signs, target plates, cannon, and hidden player spawn.
- Mouse/keyboard/touch aiming and hold-to-charge firing with a fixed camera, live power bar, predicted landing distance, crosshair, and 14-dot ballistic trajectory.
- Server-owned spinning pizza physics, visible pepperoni toppings, collision validation, impact rings, bounce-friendly physical properties, timeout cleanup, and rapid reset.
- Remote launch validation rejects malformed types, non-finite numbers, backwards shots, excessive aim angles, overlapping shots, and cooldown violations.
- Per-player highlighted order target across six distances and lanes.
- Accuracy tiers (`PERFECT`, `GREAT`, `DELIVERED`), coins, combo bonuses, leaderboard values, positive miss copy, and animated HUD feedback.
- Session upgrade shop with validated server purchases: +25% coin levels, expanded accuracy radii, and reduced reload delay.
- Responsive desktop and mobile-landscape HUD plus short first-shot onboarding.
- Rojo project configuration and complete run/build documentation.

### Tests and fixes

- `rojo build default.project.json -o pizzalaunch.rbxlx` succeeds.
- `git diff --check` passes with no whitespace errors.
- Live Studio server/client play session starts with the generated world, remotes, HUD, and no errors in Output.
- Calibrated Table 4 shot returned `PERFECT`, awarded 20 coins, and selected the next target.
- Follow-up delivery advanced combo to 2 and awarded the expected +2 combo bonus.
- Three consecutive calibrated deliveries reached combo 3 and 60 coins.
- Deliberate overpowered shot returned `FLOOR PIZZA!`, awarded no coins, reset combo, and allowed an immediate retry.
- Purchased Bigger Tips level 1 for 35 coins; leaderboard decreased correctly and the next perfect delivery paid 25 rather than 20 coins.
- iPhone 16 Pro Max landscape playtest found desktop HUD overlap and visible character controls. Condensed the touch HUD, hid the desktop tutorial, constrained the launch panel, and disabled the default touch controls.
- Corrected table/customer sign faces and the cannon barrel's cylinder orientation after live visual inspection.

### Known limitations

- Coins/upgrades are session-only; saving is deliberately not enabled yet.
- Audio is not included. Current feedback uses animation, text, neon trajectory/impact effects, and physics so the game has no external asset dependency.
- The restaurant has one fixed table arrangement; target order changes but tables do not move.
- Multiplayer shares the physical cannon model, while target highlights and orders remain per-player.

### Best next priorities

1. Add a 60–90 second lunch rush with a clear results card and combo milestones.
2. Add original, licensed sound effects for charge, launch, bounce, perfect delivery, and crowd reactions.
3. After economy playtesting, add guarded DataStore saving for coins and upgrade levels.
