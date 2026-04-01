# Squid

Squid is a **Windows local input broadcaster** written in **AutoHotkey v2**.

Its purpose is narrow: take specific **user-initiated** keyboard and mouse inputs and rebroadcast them to selected follower windows on the same PC.

## Status

This repository is in the **planning and bootstrap** stage.

What exists now:
- project documentation
- config schema planning
- test plan
- initial `Squid.ahk` skeleton

What does **not** exist yet:
- finished broadcast engine
- finished window targeting flow
- finished profile editor
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
│  └─ profiles.example.json
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

## Current Development Order

1. lock documentation
2. keep a minimal but valid `Squid.ahk` skeleton
3. add config example
4. implement window targeting
5. implement input capture
6. implement broadcast routing
7. harden behavior and logging

## Running the Current Skeleton

Requirements:
- Windows
- AutoHotkey v2

Current bootstrap behavior:
- initializes runtime state
- creates required folders
- builds tray menu commands
- writes a session log
- checks for config file presence
- exposes enable/disable and emergency stop controls

It is not a finished broadcaster yet.

## License

No license has been finalized yet.
