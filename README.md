# Mafia Game

A Roblox mafia game: join a **family**, climb the **rank** ladder
(Associate → Soldier → Capo → Consigliere → Underboss → Boss), and fight other
families for **territory**. Built **server-authoritative** so progression and
combat can't be cheated by the client.

## Project layout (Rojo)

```
default.project.json   Rojo project mapping
src/shared/            ReplicatedStorage.Shared  (config + helpers shared by both sides)
  Families.luau          family definitions (id / name / color)
  Ranks.luau             the rank ladder + forReputation() helper
  Territories.luau       capturable zone definitions (id / name / position / radius)
  Remotes.luau           creates/fetches the shared RemoteEvents
src/server/            ServerScriptService.Server (authoritative game logic)
  Main.server.luau       wires systems together + validates family-join requests
  PlayerData.luau        authoritative profiles (family/rep/money) + leaderstats
  DataStore.luau         crash-proof save/load wrapper (persists progress)
  Territory.luau         spawns zones, runs capture ticks, awards rep + money
  Combat.luau            server-validated melee + kill rewards
src/client/            StarterPlayerScripts.Client (UI + input only)
  Main.client.luau       family picker, HUD, live territory board, toasts, attack input
```

## Running it

1. Install **Rojo** (CLI + the Roblox Studio plugin). Easiest via [Rokit](https://github.com/rojo-rbx/rokit) or `aftman`, or grab Rojo from its releases.
2. In this folder run `rojo serve`.
3. In Studio, open the Rojo plugin and click **Connect**. The `src/` code syncs in.
4. Press **Play**. You'll get a family picker; choosing one is validated on the
   server and your HUD updates with your family + rank.
5. Walk into one of the glowing zone discs. With only your family present it
   captures (earning reputation); holding it pays money + a little rep each
   second. Two families in the same zone = contested (capture freezes).
6. **Click** to swing at a nearby rival (different family). Kills earn
   reputation + money. Watch the top-right board for live ownership/capture,
   the player list for your stats, and toasts for captures + promotions.

To test combat and capturing properly, use Studio's **Test → Players** (2+) or
**Start (local server)** so you have rivals. Progress saves via DataStore once
the game is published (or with "Enable Studio Access to API Services" on).

### Tuning
- Families: `src/shared/Families.luau`
- Rank ladder + thresholds: `src/shared/Ranks.luau`
- Zone positions/sizes: `src/shared/Territories.luau`
- Capture speed, rewards, hold income: constants at the top of `src/server/Territory.luau`

### Current status
Implemented: families, ranks/reputation, server-authoritative family join, HUD,
capturable territory (capture + hold income + contest), live territory board,
leaderstats, DataStore saving, promotions, and server-validated melee combat.
Next ideas: family bases/spawns, proper weapons (tools), a map, and a
boss-only promotion/demotion system.

---

# Owner Panel (client-sided)

`OwnerPanel.lua` is a separate, standalone client tool (not part of the game
above). It shows a small status HUD (black & gold theme) listing active
features, each with a dot: **gold = on**, **dark = off**, toggled with hotkeys.

## Features

| Feature | Hotkey | What it does |
|---------|--------|--------------|
| Fly | `F` | Smooth physics-based flight (see controls below). |
| Target | `Q` | Locks onto the player nearest your mouse: highlights them through walls and locks the camera onto them. |
| Random TP | `H` | Chaos toggle: teleports your character to a random point every frame (X/Z ±500, Y up to +500 so you don't fall into the void), anchored to where you toggled it on. Returns you to that spot when turned off. |
| ESP | *always on* | Shows each other player's **DisplayName** + **@username** above their head, visible through walls. No keybind or panel row. |
| Hide/show panel | `RightCtrl` | Toggles the status HUD. |
| Kill script | **KILL SCRIPT** button | Fully unloads the script (see below). |

### Kill switch

The red **KILL SCRIPT** button at the bottom of the panel completely unloads the
script: it turns every feature off, releases the camera, removes the panel, ESP
tags and target highlight, disconnects all of its events, and deletes the script
instance. To use it again afterwards you just re-run/re-add the LocalScript.

### Target controls

- Aim near a player and press `Q` to lock on. The target is highlighted
  (visible through walls), the camera locks onto them, and the panel shows
  their name.
- Press `Q` again to unlock — it always deselects, no matter where you're
  aiming. To switch targets, press `Q` to unlock, then aim at someone else and
  press `Q` again.
- The lock clears automatically if the target dies or leaves.

Highlight colors are set in the `CONFIG` table.

### Camera lock-on

Camera lock-on is built into the target: whenever you have a target (set with
`Q`), the camera snaps behind you and keeps the target framed, tracking it
**instantly with no smoothing** as either of you moves. It restores your normal
camera as soon as the target is cleared (press `Q` again, or the target
dies/leaves).

Tune `CamLockDistance` and `CamLockHeight` in `CONFIG`. The camera aims straight
at the target's head.

### Fly controls

| Input | Action |
|-------|--------|
| `W` `A` `S` `D` | Move, relative to the camera |
| `Space` / `Left Ctrl` | Up / down |
| `Left Shift` (hold) | Boost |
| Gamepad | Left stick = move, triggers = up/down |

Fly is velocity-based and tuned to be responsive (input maps to motion almost
instantly), while still sliding along walls instead of clipping through them,
and the avatar stays upright facing the camera. Speed is fixed at `200`
(`FlySpeed` in `CONFIG`). Responsiveness is `FlyAcceleration` (higher = snappier,
lower = floatier); boost and the rest live in the same table.

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
