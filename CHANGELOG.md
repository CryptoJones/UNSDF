# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- GitHub Actions CI now runs the Godot 4.6.3 headless smoke test on pushes to
  `main` and on pull requests.

### Fixed
- Caught respawns now refresh the room label/checkpoint HUD state after the
  checkpoint room is rebuilt.
- Dialogue body text now wraps inside the comms panel instead of clipping long
  lines.
- The D2 crate-puzzle smoke test now follows legal player push/pull movement
  instead of teleporting crates directly.

### Changed — art direction pivot to a modern 2D JRPG (painted backgrounds)
- Replaced the procedural 16-bit look with **painted, FLUX-generated art** (think
  Pokémon / clean anime RPG), generated locally on makemake (FLUX.2-klein-4B via
  mflux; pipeline documented in `~/LOCAL-FLUX.md`).
- **16 painted room backgrounds** (`assets/backgrounds/<id>.png`), one per RoomDB
  room, shown full-screen; `Room` composites the interactive layer on top and
  keeps the 20x15 grid as invisible collision.
- **8-direction player sprite** (`assets/sprites/recruit_<dir>.png`) — 5 unique
  cel-shaded poses generated, 3 mirrored, white backgrounds keyed to transparent.
- **8-way movement** — the controller now reads diagonals; the sprite faces the
  move vector. Crate push stays cardinal-only. (`DESIGN.md` canon updated.)
- **NPC sprites** wired with a procedural fallback (auto-upgrade per NPC as art
  lands); dialogue-portrait art under `assets/portraits/`.
- The procedural 16-bit renderer (`scripts/render/`) is kept as an unused fallback.

### Added (earlier procedural pass, now superseded)
- `PixelArt` render kit (`scripts/render/pixel_art.gd`): procedural, asset-free
  16-bit art — ordered-dither metal floors, beveled riveted wall plates, shaded
  humanoid actors (player + NPCs), glowing pickups, and a baked vignette.
- `Decor` set-dressing layer (`scripts/render/decor.gd`): per-room "space stuff"
  — themed wall furniture (screens, consoles, lockers, tanks, pipes, vents,
  dishes), a macro floor-plate grid, painted walkways, a themed centrepiece
  (reactor / holo-table / load pad / trench / pit) and dense flat floor clutter
  (hatches, vents, cable trays, cargo pallets, deck stencils, hazard chevrons).
  All wall-mounted or flat/walkable, so nothing collides with the critical path.
- Drawn character-face portraits in the dialogue box (replaces the flat swatch).

### Changed
- Replaced the flat solid-colour placeholder art in `Room`, `Player` and
  `Pushable` with textured, shaded rendering.
- Rooms now breathe atmosphere: ceiling fluorescent wash, an orange/red hazard
  alarm tint that pulses when a camera arms, and edge vignette.
- Stretch mode switched to **`canvas_items`** so UI fonts render at native
  resolution — text is now crisp and readable instead of upscaled/blurry.
- Dialogue is now a **near-fullscreen comms panel** with a large portrait header
  and a body that sizes to its content, so long NPC monologues never clip.
- Window ships at **1280x960** (4x integer scale, retargeted for 1080p screens);
  the window is now resizable.

## [0.1.0] - 2026-06-29

Initial vertical-slice scaffold of Level 1, "Wrong Side of the Airlock".

### Added
- Godot 4.6 project (GL Compatibility, 320x240 integer-scaled, pixel-snapped).
- Data-driven 16-room station grid (A1–D4) defined in `RoomDB`.
- Grid-locked **push/pull** player controller (no dash, no combat).
- **Room-exit reset**: rooms rebuild from data on entry, so crates snap back
  (the soft-lock guard).
- Screen-to-screen slide transitions + door-lock checks.
- Hard-reset stealth model: security cameras in A2 trip a "caught" respawn to
  the last checkpoint. No HP / Suit Integrity bar.
- Dialogue system + full trees for all six NPCs (Recruiter, Janitor, Business
  Traveler, Dock Worker, Technician, Smuggler).
- Cargo Bay (D2) pressure-plate crate puzzle wired to the Power Core reward.
- Critical path: Keycard (A3, via the B3 vents) -> Cargo Bay (D2) -> Power Core
  -> Technician (C2) -> gate unlock -> B4 -> C4 -> Smuggler (C3) -> DEMO CLEAR.
- Minimalist HUD: floating dialogue box with portrait swatch, status line,
  room label, fade, and win overlay.
- Optional 16-bit shaders: `snes_quantize` (global posterize) and
  `palette_swap` (indexed state palettes).
