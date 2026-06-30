# UNSDF — Level 1 Design Canon

*"Wrong Side of the Airlock."* Locked spec for the vertical slice. The code in
`scripts/` implements this document; if the two disagree, this wins.

## Premise

You've just been rejected by the United Nations Space Defense Force. You're
stranded on **Tier-9 Concourse** of a massive station — cramped, industrial,
lived-in sci-fi (*Alien* / *Cowboy Bebop*). No clearance, no creds, no ride.
The only way out is to get yourself smuggled off. Level 1 is one self-contained
dungeon; the **Smuggler's Hangar (C3)** is the locked final room.

## The station grid (4x4)

|   | 1 (Core)            | 2 (Service)        | 3 (Edge)              | 4 (Dead End)        |
|---|---------------------|--------------------|-----------------------|---------------------|
| A | A1 Recruitment ★    | A2 Security Hub ⚠  | A3 Maintenance Corr.  | A4 Locked Storage   |
| B | B1 Main Concourse   | B2 Lower Docks     | B3 Ventilation Shaft  | B4 Restricted Gate🔒 |
| C | C1 Trash Compactor  | C2 Engine Room     | **C3 Smuggler ★GOAL** | C4 Fuel Depot       |
| D | D1 Life Support     | D2 Cargo Bay       | D3 Comm. Array        | D4 Air-Lock         |

★ start / goal · ⚠ camera hazard · 🔒 gated by the Technician

## Door graph (what connects to what)

- **A1** ↔ A2 (east), ↔ B1 (south)
- **A2** ↔ A1, ↔ A3 (east), ↔ B2 (south) — *hazard, no checkpoint*
- **A3** ↔ A2, ↔ A4 (east), ↔ B3 (south)
- **A4** ↔ A3 (dead end)
- **B1** ↔ A1, ↔ B2 (east), ↔ C1 (south)
- **B2** ↔ A2, ↔ B1, ↔ B3 (east), ↔ C2 (south)
- **B3** ↔ A3, ↔ B2, **↔ B4 (east) 🔒 flag `gate_unlocked`**
- **B4** ↔ B3, ↔ C4 (south)
- **C1** ↔ B1, ↔ C2 (east), ↔ D1 (south)
- **C2** ↔ B2, ↔ C1, **↔ D2 (south) 🔒 item `access_keycard`**
- **C3** ↔ C4 (east) — *single door; the goal is sealed off otherwise*
- **C4** ↔ B4, ↔ C3
- **D1** ↔ C1, ↔ D2 (east)
- **D2** ↔ C2, ↔ D1, ↔ D3 (east)
- **D3** ↔ D2, ↔ D4 (east)
- **D4** ↔ D3 (dead end)

**The seal that matters:** the {B4, C4, C3} cluster's *only* connection to the
rest of the station is the locked **B3→B4** gate. There is deliberately no
C2→C3 door and no D-row path into C4, so C3 cannot be reached early.

## Critical path & dependencies

| # | Where | Action | Key in / out |
|---|-------|--------|--------------|
| 1 | A1 | Talk to the Recruiter | starts the quest |
| 2 | B1 | Janitor → keycard+vent hint; Traveler → camera-timing hint | info |
| 3 | B3→A3 | Crawl the vents (skips the A2 cameras) | **Access Keycard** |
| 4 | C2→D2 | Keycard unlocks the Cargo Bay keypad | enter D2 |
| 5 | D2 | Solve the crate / pressure-plate puzzle | **Power Core** |
| 6 | C2 | Give the Power Core to the Technician | sets `gate_unlocked` |
| 7 | B3→B4→C4 | Pass the now-open Restricted Gate, through the Fuel Depot | reach C3 |
| 8 | C3 | "I'm desperate." → the Smuggler takes you | **DEMO CLEAR** |

Two items, two locks, fully linear. The **A2 Security Hub** is the brute-force
alternate to step 3: cross it directly and the cameras escort you back. The vent
route is the safe path.

## NPC dialogue

Concise, cryptic, world-building. Full trees in `scripts/data/dialogue_db.gd`.

- **UNSDF Recruiter (A1):** rejects you; on "anyone else hiring?" points at the
  freelancers on the lower docks.
- **Station Janitor (B1):** a keycard was dropped near the Maintenance Corridor;
  crawl the B3 vents to dodge the A2 cameras.
- **Business Traveler (B1):** the A2 cameras run a patrol loop — wait for the red
  light to blink twice (the reset interval).
- **Cynical Dock Worker (B2):** go see the Technician in the Engine Room.
- **Station Technician (C2):** bring a Power Core, she slices the gate. Gated
  give-branch (requires the Core); re-greets once the gate is open.
- **The Smuggler (C3):** spy or desperate? "Desperate" launches you out.

## Mechanics (locked calls)

- **Movement:** grid-stepped, **8-directional** (cardinals + diagonals); the
  character sprite faces the way you move. **Push** by walking into a crate
  (cardinal only); **Pull** by holding Grab and backing straight out of a faced
  crate. **No dash.**
- **Soft-lock guard:** room-exit reset. Rooms are rebuilt from `RoomDB` on every
  entry, so crates snap back to start — you can never trap yourself.
- **Threat model:** binary stealth/caught. Cameras have an armed/idle duty cycle
  (the "blink twice" tell). Getting spotted = hard reset to the last checkpoint.
  **No combat, no HP / Suit Integrity bar.** Hazard rooms don't set checkpoints.
- **Transitions:** one screen per room, Zelda-style slide. Caught-respawn uses a
  fade instead.

## The D2 "Cargo Shift" puzzle

A 20x15 room, open floor. Three pressure plates in a vertical line at the center
(col 10, rows 6–8). Four crates; the fourth is a spare/red herring. Hold all
three plates down at once and the **Maintenance Cache** (north, row 2) hisses
open and yields the **Power Core**. Push/pull only; reset-on-exit means any
mistake is undone by leaving and re-entering.

## Visual direction

**Modern 2D JRPG** (think Pokémon / a clean anime RPG) — *not* 16-bit pixel art.
Dark steel blues, industrial orange hazard lighting, lived-in *Alien* / *Cowboy
Bebop* sci-fi. Each room is a **painted background** (`assets/backgrounds/<id>.png`,
one per RoomDB room) shown full-screen; the player and NPCs are **cel-shaded
character sprites** composited on top. The 20x15 grid stays as invisible collision
mapped onto the painted floor — the gameplay logic is unchanged, only the look.

**Art is generated locally** with FLUX.2-klein-4B via mflux on makemake (see
`~/LOCAL-FLUX.md`), then keyed/assembled into game assets:
- `assets/backgrounds/` — 16 painted room scenes.
- `assets/sprites/recruit_<dir>.png` — the player in 8 facing directions (5 unique
  poses generated, 3 horizontally mirrored), white backgrounds keyed to transparent.
- `assets/sprites/npc_<dialogue>.png` — NPC overworld sprites (rooms fall back to a
  procedural marker for any NPC without art yet).
- `assets/portraits/` — dialogue-box character portraits.

Dialogue is a near-fullscreen comms panel; the body sizes to its content so long
monologues never clip. UI renders crisp at native resolution (`canvas_items`
stretch). Per CJ's colorblindness, gameplay cues use blue/orange, not red/green.

The procedural 16-bit renderer (`scripts/render/`, `PixelArt`/`Decor`) and the
`shaders/` graders are kept from the earlier pass as an unused fallback.

**Display:** base coordinate space 320x240 (4:3), window **1280x960**; painted
backgrounds and sprites use linear filtering and render at full window resolution.
