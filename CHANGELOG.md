# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
