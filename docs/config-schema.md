# Squid Config Schema

## Purpose

This document defines the planned JSON configuration structure for Squid v0.1.

The format is meant to be:
- readable
- hand-editable
- strict enough to avoid ambiguity
- simple enough for a single-script AHK v2 project

## Guiding Rules

1. JSON is the source of truth for user-editable settings.
2. Missing fields must fail clearly or default safely.
3. Window handles are temporary and must not be the only matching mechanism.
4. Input mappings must be explicit.
5. Emergency stop and enable/disable controls must be easy to locate.

---

## Proposed Top-Level Shape

```json
{
  "version": 1,
  "activeProfile": "default",
  "logging": {
    "enabled": true,
    "level": "info",
    "logDirectory": "logs"
  },
  "safety": {
    "globalEnabled": false,
    "toggleHotkey": "F9",
    "emergencyStopHotkey": "F10",
    "wheelDebounceMs": 120
  },
  "profiles": [
    {
      "name": "default",
      "leader": {},
      "followers": [],
      "mappings": []
    }
  ]
}
```

---

## Top-Level Fields

### `version`
**Type:** integer  
Schema/config version.

### `activeProfile`
**Type:** string  
Name of the profile Squid should attempt to load on startup.

### `logging`
**Type:** object  
Controls session logging.

### `safety`
**Type:** object  
Controls high-level state, kill switch, and debounce settings.

### `profiles`
**Type:** array of objects  
List of named profiles.

---

## `logging` Object

```json
"logging": {
  "enabled": true,
  "level": "info",
  "logDirectory": "logs"
}
```

### Fields
- `enabled` — boolean
- `level` — string; suggested values: `error`, `warn`, `info`, `debug`
- `logDirectory` — string path relative to repo/script directory unless documented otherwise

### Rules
- logging should default to enabled
- invalid log level should fall back safely
- failures to write logs should not crash the script

---

## `safety` Object

```json
"safety": {
  "globalEnabled": false,
  "toggleHotkey": "F9",
  "emergencyStopHotkey": "F10",
  "wheelDebounceMs": 120
}
```

### Fields
- `globalEnabled` — boolean startup state
- `toggleHotkey` — string hotkey used to enable/disable broadcasting
- `emergencyStopHotkey` — string hotkey used to force stop broadcasting immediately
- `wheelDebounceMs` — integer debounce interval for mouse wheel handling

### Rules
- `emergencyStopHotkey` must always be defined or clearly defaulted
- debounce must be non-negative
- unsafe or invalid values must fail clearly or fall back safely

---

## Profile Object

```json
{
  "name": "default",
  "leader": {
    "hwnd": 0,
    "exe": "rift_x64.exe",
    "titleContains": "RIFT",
    "class": ""
  },
  "followers": [
    {
      "name": "Follower1",
      "hwnd": 0,
      "exe": "rift_x64.exe",
      "titleContains": "RIFT",
      "class": ""
    }
  ],
  "mappings": [
    {
      "input": "1",
      "type": "keyboard",
      "enabled": true,
      "targets": "followers"
    }
  ]
}
```

### Profile fields
- `name` — string, unique profile name
- `leader` — object describing the source/primary window context
- `followers` — array of target window descriptors
- `mappings` — array of explicit input mapping objects

---

## Window Descriptor Object

```json
{
  "name": "Follower1",
  "hwnd": 0,
  "exe": "rift_x64.exe",
  "titleContains": "RIFT",
  "class": ""
}
```

### Fields
- `name` — human-readable label
- `hwnd` — numeric handle if known at save time; treated as temporary
- `exe` — process executable name
- `titleContains` — substring for fallback title matching
- `class` — window class name if useful

### Rules
- `hwnd` alone is not reliable enough
- fallback metadata should be present for reacquire logic
- empty strings are allowed only where documented and handled intentionally

---

## Mapping Object

```json
{
  "input": "WheelUp",
  "type": "mouse_wheel",
  "enabled": true,
  "targets": "followers"
}
```

### Fields
- `input` — string identifier for the source input
- `type` — string; suggested values:
  - `keyboard`
  - `mouse_button`
  - `mouse_wheel`
- `enabled` — boolean
- `targets` — target selector; for v0.1 this should normally be `followers`

### Optional future fields
- `sendAs`
- `modifierPolicy`
- `debounceMs`
- `targetFilter`

These are not required for the first version.

---

## Example Full Config

```json
{
  "version": 1,
  "activeProfile": "rift-main",
  "logging": {
    "enabled": true,
    "level": "info",
    "logDirectory": "logs"
  },
  "safety": {
    "globalEnabled": false,
    "toggleHotkey": "F9",
    "emergencyStopHotkey": "F10",
    "wheelDebounceMs": 120
  },
  "profiles": [
    {
      "name": "rift-main",
      "leader": {
        "hwnd": 0,
        "exe": "rift_x64.exe",
        "titleContains": "RIFT",
        "class": ""
      },
      "followers": [
        {
          "name": "Follower1",
          "hwnd": 0,
          "exe": "rift_x64.exe",
          "titleContains": "RIFT",
          "class": ""
        },
        {
          "name": "Follower2",
          "hwnd": 0,
          "exe": "rift_x64.exe",
          "titleContains": "RIFT",
          "class": ""
        }
      ],
      "mappings": [
        {
          "input": "1",
          "type": "keyboard",
          "enabled": true,
          "targets": "followers"
        },
        {
          "input": "RButton",
          "type": "mouse_button",
          "enabled": true,
          "targets": "followers"
        },
        {
          "input": "WheelUp",
          "type": "mouse_wheel",
          "enabled": true,
          "targets": "followers"
        },
        {
          "input": "WheelDown",
          "type": "mouse_wheel",
          "enabled": true,
          "targets": "followers"
        }
      ]
    }
  ]
}
```

---

## Validation Expectations

At minimum, Squid should validate:
- config parses as JSON
- `version` exists
- `activeProfile` is defined
- referenced active profile exists
- safety hotkeys are present or defaulted
- mappings are explicit and typed
- follower list is allowed to be empty only if handled clearly

## Failure Handling Expectations

When config is bad, Squid should not continue silently.

It should either:
- refuse to enter active broadcasting state, or
- load safe defaults and log that it did so

## Future File Note

A future `config/profiles.example.json` file can be added once implementation starts.

For now, this schema document is the source of truth for config planning.
