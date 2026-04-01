# Squid

Squid is a **Windows local input broadcaster** written in **AutoHotkey v2**.

Its purpose is narrow: take specific **user-initiated** keyboard and mouse inputs and rebroadcast them to selected follower windows on the same PC.

## Status

This repository is in the **bootstrap** stage.

What exists now:
- project documentation
- JSON profile bootstrap
- tray controls
- safety hotkeys
- candidate-window discovery
- leader/follower target capture
- persisted target refresh / reacquire logic
- startup logging and status reporting

What does **not** exist yet:
- mapped input capture
- rebroadcast send engine
- production-ready release

## Project Direction

Squid is being built around **one master script** first:

- `Squid.ahk`

That is deliberate.

Early over-segmentation in AHK usually creates drift, confusion, and fake architecture. The correct first milestone is a working single-script broadcaster with clear internals, not a pile of half-useful modules.

## Goals

- broadcast selected keyboard inputs
- broadcast selected mouse buttons
- support mouse wheel input with debounce protection
- support leader/follower window targeting
- allow global enable/disable
- provide an emergency stop hotkey
- persist profiles in JSON
- log startup, targeting, and broadcast behavior

## Non-Goals

Squid is **not** intended to be:

- a bot
- an automation engine
- a screen reader
- a memory reader
- a pathfinding system
- a multi-PC sync system in v0.1

## Planned Repository Shape

```text
Squid/
├─ README.md
├─ Squid.ahk
├─ config/
│  ├─ profiles.example.json
│  └─ profiles.json        # generated at runtime
└─ docs/
   ├─ product-spec.md
   ├─ roadmap.md
   ├─ test-plan.md
   └─ config-schema.md
```

## Documentation

- `docs/product-spec.md` — product requirements and acceptance criteria
- `docs/roadmap.md` — milestone order
- `docs/test-plan.md` — manual validation plan
- `docs/config-schema.md` — planned JSON config structure

## Planned v0.1 Scope

In scope:
- leader/follower targeting
- mapped keyboard rebroadcasting
- mapped mouse button rebroadcasting
- mouse wheel rebroadcasting
- global toggle
- emergency stop
- logging
- profile loading

Out of scope:
- OCR
- memory reading
- autonomous behavior
- plugin architecture
- large GUI work
- network sync

## Running the Current Build

Requirements:
- Windows
- AutoHotkey v2

Current bootstrap behavior:
- ensures `config/profiles.json` exists by copying `profiles.example.json` on first run
- loads and normalizes JSON config
- registers toggle and emergency-stop hotkeys from config
- builds tray menu commands
- discovers candidate windows on demand
- saves the active window as leader or follower
- refreshes persisted targets against live windows using stored metadata
- writes a session log
- shows current state and target summary

It is still **not** a finished broadcaster yet.

## Current Development Order

1. lock documentation
2. bootstrap shell
3. window discovery and target persistence
4. input capture
5. broadcast routing
6. hardening and logging refinement

## License

No license has been finalized yet.
