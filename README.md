# UNSDF — "Wrong Side of the Airlock"

A 16-bit sci-fi action-adventure in the spirit of the original *Legend of Zelda*
engine: top-down, grid movement, one-screen-per-room transitions. You've just
been rejected by the **United Nations Space Defense Force**. Level 1 is a single
"dungeon" — the cramped, lived-in Tier-9 space port — and your job is to smuggle
yourself off the station.

**Engine:** Godot 4.6.x (GL Compatibility renderer)
**License:** Apache-2.0 · © 2026 Aaron K. Clark (CryptoJones)
**Status:** v0.1.0 — runnable vertical-slice scaffold

---

## Run it

```bash
godot --headless --path . --import   # FIRST run only: builds the class cache
godot --path .                       # run the game
godot -e --path .                    # open in the editor instead
```

> First launch must be the `--import` pass (or just open the editor once). A
> fresh clone has no `.godot/` cache, so `class_name` globals aren't registered
> yet and a cold `godot --path .` dies with "Identifier ... not declared".

Main scene: `scenes/main.tscn`.

## Controls

| Action   | Keys                  |
|----------|-----------------------|
| Move     | Arrows / WASD         |
| Interact | Z / Enter / Space     |
| Push     | walk into a crate     |
| Pull     | hold X / Shift, back straight out of a crate |
| Choose   | Up/Down + Interact (in dialogue) |

## The critical path

```
A1 Recruitment  --talk-->  B1 Concourse (Janitor + Traveler)
   -> B2 -> B3 Vents --north--> A3  (grab the ACCESS KEYCARD; vents skip the A2 cameras)
   -> ... -> C2 Engine Room --south(keycard)--> D2 Cargo Bay
        (push/pull 3 crates onto the plates -> POWER CORE)
   -> back to C2: give the Core to the Technician  ->  Restricted Gate (B4) unlocks
   -> B3 --east--> B4 --south--> C4 Fuel Depot --west--> C3 Smuggler's Hangar
   -> "I'm desperate."  ->  DEMO CLEAR
```

The brute-force route to the keycard (A1 -> A2 -> A3) runs the **Security Hub**
cameras: get spotted and you're escorted back to the checkpoint. The vent route
through B3 avoids them. C3 is reachable **only** through the unlocked B4->C4
buffer — never directly from the B- or D-rows.

## Project layout

```
project.godot              # display: 320x240, integer scale, nearest filter
scenes/main.tscn           # boot scene -> scripts/main.gd
scripts/
  main.gd                  # builds World + Player + HUD, loads room A1
  autoload/
    game_state.gd          # flags, checkpoint, runtime input map  (GameState)
    inventory.gd           # key items                              (Inventory)
    dialogue_manager.gd    # walks DialogueDB trees, drives the HUD (DialogueManager)
    room_manager.gd        # room build, slide transitions, locks   (RoomManager)
  data/
    grid.gd                # tile/screen constants + helpers
    item_db.gd             # key-item catalogue
    dialogue_db.gd         # all six NPC dialogue trees
    room_db.gd             # the 16-room station as data
  world/
    room.gd                # builds + draws one screen; puzzle + camera logic
    player.gd              # grid push/pull controller
    pushable.gd            # crate
  ui/
    hud.gd                 # dialogue box, status, fade, DEMO CLEAR
shaders/
  snes_quantize.gdshader   # global posterize to a 16-bit color space
  palette_swap.gdshader    # indexed palette state-swaps (e.g. alarm red)
docs/DESIGN.md             # the locked level-1 design canon
```

See `docs/DESIGN.md` for the full grid, dialogue, mechanics, and puzzle spec.

## Locked design calls (v0.1.0)

- **Controller:** push/pull, no dash.
- **Soft-lock guard:** room-exit reset (rooms rebuild from data on entry).
- **Threat model:** binary stealth/caught, hard reset, **no HP bar**.
- **Transition topology:** the Restricted Gate (B4) empties into the Fuel Depot
  (C4), which buffers into the Smuggler's Hangar (C3).

## Scaffolded vs. next

**In place & runnable:** all systems above + the full critical path, end to end.

**Placeholder / next up:**
- Art is code-drawn rectangles. Swap `room.gd` placeholder draws for a `TileSet`
  + `TileMapLayer`, or promote rooms to hand-authored `.tscn` scenes with sprites.
- Wire `snes_quantize` as a screen post-process and use `palette_swap` for the
  alarm-state mood shift when a camera trips.
- Flesh out the optional rooms (Trash Compactor, Comm. Array, Life Support,
  Air-Lock) with flavor and secrets.
- Audio (pneumatic hiss on the cache, camera sweep hum, the undock sting).
