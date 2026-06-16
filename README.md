# Owner Panel (client-sided)

A single copy-paste **LocalScript** for a Roblox game. It shows a small status
HUD listing the active features. Each feature has a dot: **red = off**,
**green = on**. Features are toggled with hotkeys.

## Features

| Feature | Hotkey | What it does |
|---------|--------|--------------|
| Fly | `F` | Smooth physics-based flight (see controls below). |
| ESP | `E` | Shows each other player's **DisplayName** + **@username** above their head, visible through walls. |
| Target | `Q` | Locks onto the player nearest your mouse: highlights them through walls, draws a tracer from your cursor to them, and locks the camera onto them. |
| Hide/show panel | `RightCtrl` | Toggles the status HUD. |
| Kill script | **KILL SCRIPT** button | Fully unloads the script (see below). |

### Kill switch

The red **KILL SCRIPT** button at the bottom of the panel completely unloads the
script: it turns every feature off, restores your camera, removes the panel,
tracer, ESP tags and target highlight, disconnects all of its events, and
deletes the script instance. To use it again afterwards you just re-run/re-add
the LocalScript.

### Target controls

- Aim near a player and press `Q` to lock on. The target is highlighted
  (visible through walls), a tracer is drawn from your mouse to them, the camera
  locks onto them, and the panel shows their name.
- Press `Q` again to unlock — it always deselects, no matter where you're
  aiming. To switch targets, press `Q` to unlock, then aim at someone else and
  press `Q` again.
- The lock clears automatically if the target dies or leaves.

Colors and tracer thickness are set in the `CONFIG` table.

### Camera lock-on

Camera lock-on is built into the target: whenever you have a target (set with
`Q`), the camera moves behind you and keeps the target framed, tracking smoothly
as either of you moves. It restores your normal camera as soon as the target is
cleared (press `Q` again, or the target dies/leaves).

Tune `CamLockDistance`, `CamLockHeight`, and `CamLockSmooth` in `CONFIG`.

### Fly controls

| Input | Action |
|-------|--------|
| `W` `A` `S` `D` | Move, relative to the camera |
| `Space` / `Left Ctrl` | Up / down |
| `Left Shift` (hold) | Boost |
| Gamepad | Left stick = move, triggers = up/down |

Fly is velocity-based with eased acceleration, so it feels smooth and slides
along walls instead of clipping through them, and the avatar stays upright facing
the camera. Speed is fixed at `200` (`FlySpeed` in `CONFIG`); the rest of the
tuning (boost, acceleration) lives in the same table.

All keys and values are configurable in the `CONFIG` table at the top of the script.

## Install

1. In Roblox Studio, add a **LocalScript** to
   `StarterPlayer > StarterPlayerScripts`.
2. Paste the contents of [`OwnerPanel.lua`](./OwnerPanel.lua) into it.
3. (Optional) Edit the `isOwner()` function near the top to control who the
   panel loads for. It currently returns `true` for everyone.

## Note on security

Everything here is **client-only** and affects only your own client (your
camera, your movement, name tags only you can see). That is what
"client-sided" means and it is safe to use.

If you later want owner powers that change the game for **everyone** (kick
players, give items, etc.), those must be done with `RemoteEvent`s that are
**validated on the server** — the client can be tampered with, so a
client-side check alone is not enough.
