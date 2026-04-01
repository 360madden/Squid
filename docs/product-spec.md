# Squid Product Specification

## 1. Purpose

Squid is a Windows local input broadcaster written in AutoHotkey v2.

Its job is simple: take specific user-initiated inputs and rebroadcast them to selected follower windows on the same PC.

This project is being developed around **one master script**: `Squid.ahk`.

## 2. Product Positioning

### What Squid is
- a local Windows desktop utility
- an input broadcaster
- focused on keyboard, mouse button, and mouse wheel rebroadcasting
- profile-driven
- meant for manual multibox-style use on one PC

### What Squid is not
- not a bot
- not an automation engine
- not a screen reader
- not a memory reader
- not a scripting framework for autonomous play
- not a multi-PC sync system in v0.1

## 3. Technical Baseline

- **Language:** AutoHotkey v2 only
- **Primary OS:** Windows 11
- **Primary source file:** `Squid.ahk`
- **Config format:** JSON
- **Initial control surface:** tray menu first, minimal GUI later

## 4. Core Problem

Repeated manual input across several local windows is tedious and error-prone.

The product must reduce repetition while keeping control immediate, predictable, and easy to stop.

## 5. Core Goals

1. Broadcast selected keyboard inputs from a leader context to follower windows.
2. Broadcast selected mouse buttons.
3. Support mouse wheel input with debounce protection.
4. Allow fast global enable/disable.
5. Allow emergency stop.
6. Persist configuration in readable profile files.
7. Keep implementation understandable inside one master `.ahk` file.

## 6. Primary Use Case

A user has one active leader game window and multiple follower windows on the same local PC.

The user presses a mapped key once.

Squid forwards that same mapped input to the chosen follower windows according to the active profile.

## 7. Initial Feature Scope (v0.1)

### In scope
- leader/follower window registration
- active profile selection
- keyboard input rebroadcasting
- mouse button rebroadcasting
- mouse wheel rebroadcasting
- global broadcaster toggle
- emergency stop hotkey
- logging
- target window refresh / reacquire flow
- dry-run or diagnostics mode

### Out of scope
- automation based on screen state
- OCR
- memory reading
- network sync between PCs
- addon/game integration
- complex GUI builder
- macro sequencing engine
- plugin system

## 8. Functional Requirements

### 8.1 Startup
- Squid starts cleanly.
- Squid loads config or falls back safely.
- Squid initializes runtime state.
- Squid creates tray menu controls.
- Squid writes a session log.

### 8.2 Profiles
- Squid supports named profiles.
- A profile defines target windows and broadcast mappings.
- A profile stores emergency stop and global toggle controls.
- A profile can be loaded without editing source code.

### 8.3 Window Targeting
- Squid can enumerate candidate windows.
- The user can mark one or more follower windows.
- The user can refresh targets when windows change.
- Squid must handle stale window handles safely.
- Squid should use fallback matching when a prior window handle is gone.

### 8.4 Input Handling
- Squid only reacts to explicitly configured inputs.
- Squid supports keyboard keys.
- Squid supports mouse buttons.
- Squid supports mouse wheel up/down.
- Squid must support debounce handling where input hardware can generate repeated bursts.

### 8.5 Broadcasting
- Broadcasting occurs only when enabled.
- Inputs are routed only to the selected follower set.
- Squid logs broadcast attempts and failures.
- Squid must be able to stop broadcasting instantly.

### 8.6 Diagnostics
- Squid logs state changes.
- Squid logs profile load results.
- Squid logs window acquisition results.
- Squid logs hotkey registration results.
- Squid exposes a visible enabled/paused/stopped status.

## 9. Non-Functional Requirements

- predictable behavior over abstraction
- strong safety controls
- minimal hidden behavior
- easy manual testing
- code clarity inside a single script
- no deprecated AHK v1 syntax

## 10. Internal Code Organization

`Squid.ahk` remains one file, but must be split into clear internal sections:

1. Header / metadata
2. Directives and startup
3. Constants
4. Runtime state
5. Configuration load/save
6. Window discovery and matching
7. Hotkey registration
8. Input routing
9. Broadcast engine
10. UI / tray / status
11. Logging and diagnostics
12. Shutdown

## 11. Safety Requirements

- emergency stop must always be available
- disabled state must block broadcasting
- missing target windows must not crash the script
- stale or invalid targets must be logged clearly
- wheel and repeat-heavy inputs must avoid uncontrolled bursts

## 12. Acceptance Criteria for v0.1

Squid v0.1 is acceptable when all of the following are true:

- launches on Windows 11 without source edits for normal use
- loads a JSON profile successfully
- identifies selected leader/follower windows
- toggles broadcasting on and off cleanly
- rebroadcasts mapped keyboard inputs to follower windows
- rebroadcasts mapped mouse buttons to follower windows
- handles wheel input with practical debounce protection
- exposes an emergency stop hotkey
- writes useful logs for startup, targeting, and broadcast activity

## 13. Deferred Decisions

The following can wait until after the first working broadcaster:

- whether a small config GUI is worth it
- whether profile editing should stay manual JSON only
- whether later file splitting is justified
- whether send strategy needs alternate fallback methods
