# Squid Roadmap

## Planning Rule

Do not overbuild.

Squid starts as one master script: `Squid.ahk`.
The roadmap is organized to produce a working broadcaster first, then improve usability.

## Phase 0 — Documentation Lock

### Goal
Lock project direction before writing implementation code.

### Deliverables
- `docs/product-spec.md`
- `docs/roadmap.md`
- `docs/test-plan.md`
- `docs/config-schema.md`

### Exit criteria
- v0.1 scope is defined
- single-file direction is explicit
- first implementation milestones are ordered

---

## Phase 1 — Core Skeleton

### Goal
Create the smallest viable `Squid.ahk` shell.

### Deliverables
- AHK v2 directives
- version/purpose header
- runtime state object
- logger init
- config load flow
- tray menu shell
- clean exit path

### Exit criteria
- script launches
- script exits cleanly
- log file is created
- config can be loaded or defaulted safely

---

## Phase 2 — Window Discovery and Persistence

### Goal
Allow Squid to know which windows matter.

### Deliverables
- enumerate candidate windows
- manual leader/follower assignment flow
- persist window matching data
- refresh/reacquire target logic
- stale handle detection

### Exit criteria
- Squid can reacquire previously selected targets after restart
- stale windows do not break startup
- target acquisition results are logged clearly

---

## Phase 3 — Input Capture

### Goal
Capture only the inputs Squid is supposed to rebroadcast.

### Deliverables
- hotkey registration system
- mapped keyboard input handling
- mapped mouse button handling
- wheel up/down handling
- debounce protection for noisy inputs

### Exit criteria
- configured hotkeys register reliably
- unconfigured inputs are ignored
- wheel handling does not explode into uncontrolled repeat spam

---

## Phase 4 — Broadcast Engine

### Goal
Send mapped inputs to follower windows reliably.

### Deliverables
- follower routing
- global enable/disable state
- emergency stop handling
- logging for send success/failure
- safe handling when targets disappear

### Exit criteria
- mapped inputs reach follower windows consistently in controlled tests
- global disable blocks all broadcasts
- emergency stop is immediate

---

## Phase 5 — Usability Pass

### Goal
Make normal use practical without source edits.

### Deliverables
- cleaner tray menu commands
- visible status indicator
- profile switch support
- target refresh command
- diagnostics command(s)

### Exit criteria
- common operations do not require opening the source file
- active state is obvious
- target and profile troubleshooting is easier

---

## Phase 6 — Hardening

### Goal
Reduce fragility and improve reliability.

### Deliverables
- better failure handling
- more precise logging
- validation of config/profile fields
- stronger startup fallback behavior
- more edge-case tests

### Exit criteria
- common failure modes are understandable from logs
- bad config does not cause confusing startup behavior
- missing windows degrade gracefully

---

## Later / Deferred Work

These are intentionally postponed until a working local broadcaster exists:

- small GUI editor for profiles
- alternate send methods if needed
- richer per-input routing rules
- multiple profile presets for different game layouts
- optional split of `Squid.ahk` into modules

---

## What Not To Do Early

- do not build a large GUI first
- do not invent a plugin architecture first
- do not add screen-reading logic first
- do not split into many `.ahk` files before there is real maintenance pressure
- do not bury core behavior behind too much abstraction

---

## v0.1 Release Definition

A v0.1 release is justified when Squid can:

- load a profile
- identify intended target windows
- register mapped keyboard and mouse inputs
- rebroadcast them to follower windows
- toggle broadcasting on/off
- stop instantly with an emergency hotkey
- produce useful logs

That is enough for a first real version.
