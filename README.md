# Owner Panel (client-sided)

A single copy-paste **LocalScript** for a Roblox game. It shows a small status
HUD listing the active features. Each feature has a dot: **red = off**,
**green = on**. Features are toggled with hotkeys.

## Features

| Feature | Hotkey | What it does |
|---------|--------|--------------|
| Fly | `F` | Smooth physics-based flight (see controls below). |
| ESP | `E` | Shows each other player's **DisplayName** + **@username** above their head, visible through walls. |
| Hide/show panel | `RightCtrl` | Toggles the status HUD. |

### Fly controls

| Input | Action |
|-------|--------|
| `W` `A` `S` `D` | Move, relative to the camera |
| `Space` / `Left Ctrl` | Up / down |
| `Left Shift` (hold) | Boost |
| Scroll wheel | Change fly speed (shown live in the panel) |
| Gamepad | Left stick = move, triggers = up/down |

Fly is velocity-based with eased acceleration, so it feels smooth and slides
along walls instead of clipping through them. The avatar stays upright and faces
the camera, and camera zoom is locked while flying so the scroll wheel only
changes speed. All tuning (speed, boost, acceleration) lives in the `CONFIG`
table at the top of the script.

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
