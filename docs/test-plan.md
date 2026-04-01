# Squid Test Plan

## Purpose

This document defines the manual validation plan for Squid v0.1.

The goal is not elegance. The goal is to prove that the broadcaster behaves predictably, stops immediately, and fails clearly.

## Test Environment Baseline

### Required environment
- Windows 11
- AutoHotkey v2 installed
- one leader window
- at least one follower window
- logging enabled
- a known profile file

### Recommended environment
- two or more follower windows
- a repeat-prone mouse wheel
- windows with slightly changing titles to test reacquire logic

---

## Test Categories

1. startup and shutdown
2. config loading
3. window targeting
4. keyboard broadcast
5. mouse button broadcast
6. mouse wheel broadcast
7. enable/disable state control
8. emergency stop
9. stale target handling
10. logging quality

---

## 1. Startup and Shutdown Tests

### T-01: clean startup
**Steps**
1. Launch `Squid.ahk`.
2. Observe tray/status behavior.
3. Check log output.

**Expected result**
- script starts without runtime error
- status is visible or inferable
- log file/session entry is created

### T-02: clean shutdown
**Steps**
1. Start Squid.
2. Exit using the intended tray/menu command.

**Expected result**
- script exits without hanging
- shutdown is logged

---

## 2. Config Loading Tests

### T-10: valid config load
**Steps**
1. Place a valid JSON profile/config.
2. Start Squid.

**Expected result**
- config loads successfully
- active profile is identified in logs/status

### T-11: missing config
**Steps**
1. Remove or rename the expected config file.
2. Start Squid.

**Expected result**
- script does not crash
- fallback/default behavior is clear
- missing config is logged clearly

### T-12: malformed config
**Steps**
1. Corrupt the JSON intentionally.
2. Start Squid.

**Expected result**
- script does not continue silently with undefined behavior
- failure is logged clearly
- user can tell what went wrong

---

## 3. Window Targeting Tests

### T-20: enumerate candidate windows
**Steps**
1. Open leader and follower windows.
2. Run target discovery.

**Expected result**
- intended windows appear in candidate results
- obviously irrelevant windows can be excluded

### T-21: save and reload targets
**Steps**
1. Assign leader/follower targets.
2. Save profile.
3. Restart Squid.

**Expected result**
- targets are restored from config/profile
- restore attempt is logged

### T-22: stale window handle
**Steps**
1. Save targets.
2. Close and reopen one target window so the HWND changes.
3. Restart or refresh targeting.

**Expected result**
- Squid attempts fallback matching
- stale handle is not treated as success
- reacquire result is logged clearly

---

## 4. Keyboard Broadcast Tests

### T-30: single mapped key
**Steps**
1. Map one simple key.
2. Enable broadcasting.
3. Press the key once in leader context.

**Expected result**
- follower windows receive exactly one corresponding broadcast event each
- action is logged

### T-31: unmapped key
**Steps**
1. Press a key that is not mapped.

**Expected result**
- no broadcast occurs
- optional debug log may note ignore behavior

### T-32: repeated keypresses
**Steps**
1. Press a mapped key repeatedly at normal manual speed.

**Expected result**
- broadcasts remain stable
- no stuck state develops
- no obvious extra duplicates appear beyond real input count

---

## 5. Mouse Button Tests

### T-40: left or right mouse button mapping
**Steps**
1. Map one mouse button.
2. Enable broadcasting.
3. Click once.

**Expected result**
- follower windows receive the expected mapped input
- no uncontrolled repeats occur

### T-41: rapid clicks
**Steps**
1. Rapid-click a mapped mouse button.

**Expected result**
- Squid remains responsive
- no lockup or runaway send loop occurs

---

## 6. Mouse Wheel Tests

### T-50: single wheel up
**Steps**
1. Map wheel up.
2. Trigger one deliberate wheel notch.

**Expected result**
- a practical single broadcast event occurs per intended wheel action

### T-51: single wheel down
**Steps**
1. Map wheel down.
2. Trigger one deliberate wheel notch.

**Expected result**
- a practical single broadcast event occurs per intended wheel action

### T-52: noisy wheel behavior
**Steps**
1. Use hardware likely to generate bursty wheel events.
2. Trigger several manual wheel actions.

**Expected result**
- debounce logic reduces obvious over-trigger behavior
- wheel use remains practical
- debounce behavior is observable in logs if debug is enabled

---

## 7. Enable/Disable State Tests

### T-60: global disable
**Steps**
1. Disable broadcasting.
2. Press mapped keys and buttons.

**Expected result**
- no rebroadcast occurs
- disabled state is obvious

### T-61: re-enable
**Steps**
1. Re-enable broadcasting.
2. Press mapped inputs again.

**Expected result**
- broadcasting resumes normally

---

## 8. Emergency Stop Tests

### T-70: emergency stop while idle
**Steps**
1. Trigger emergency stop while no current broadcast is occurring.

**Expected result**
- broadcasting becomes blocked immediately
- stopped state is clear in status/logs

### T-71: emergency stop during active use
**Steps**
1. Repeatedly use mapped inputs.
2. Trigger emergency stop mid-session.

**Expected result**
- further broadcasting stops immediately
- no lingering active state remains

---

## 9. Missing / Broken Target Tests

### T-80: one follower missing
**Steps**
1. Configure multiple followers.
2. Close one follower window.
3. Broadcast a mapped input.

**Expected result**
- existing valid targets still work
- invalid target is logged clearly
- script does not crash

### T-81: all followers missing
**Steps**
1. Close all configured follower windows.
2. Trigger mapped input.

**Expected result**
- no crash
- failed routing is logged clearly
- behavior is understandable

---

## 10. Logging Quality Tests

### T-90: startup logging
**Expected log content**
- session start
- config result
- active profile
- target reacquire result

### T-91: input/broadcast logging
**Expected log content**
- mapped input observed
- broadcast attempted
- per-target success/failure when useful

### T-92: shutdown logging
**Expected log content**
- explicit shutdown entry

---

## Pass Criteria for v0.1

Squid v0.1 passes basic validation when:

- startup/shutdown works repeatedly
- bad config does not cause silent nonsense
- targets can be reacquired practically
- keyboard/mouse broadcasts behave predictably
- wheel broadcast is usable with debounce
- emergency stop is immediate
- logs make failures understandable

## Notes

This is a manual-first test plan.

Automated testing is not the priority at this stage. The first priority is proving that the broadcaster works and fails in understandable ways.
