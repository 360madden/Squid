; ==================================================
; Version: 0.2.0-dev
; Total Characters: 34889
; Purpose: Bootstrap shell for Squid, a Windows local input broadcaster
;          written in AutoHotkey v2. This stage adds JSON config loading,
;          candidate-window discovery, leader/follower target persistence,
;          tray controls, safety hotkeys, and startup target refresh.
; ==================================================

#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn
SetWorkingDir A_ScriptDir

global SQUID_VERSION := "0.2.0-dev"
global SQUID_NAME := "Squid"
global SQUID_BASE_DIR := A_ScriptDir
global SQUID_CONFIG_DIR := SQUID_BASE_DIR "\config"
global SQUID_LOG_DIR := SQUID_BASE_DIR "\logs"
global SQUID_EXAMPLE_CONFIG_PATH := SQUID_CONFIG_DIR "\profiles.example.json"
global SQUID_CONFIG_PATH := SQUID_CONFIG_DIR "\profiles.json"
global SQUID_LOG_PATH := SQUID_LOG_DIR "\squid.log"
global SQUID_RUNTIME := Map(
    "IsEnabled", false,
    "IsEmergencyStopped", false,
    "Config", Map(),
    "ActiveProfileName", "",
    "ConfigLoaded", false,
    "ConfigExists", false,
    "RegisteredHotkeys", [],
    "SessionStartedAt", A_Now
)

OnExit(OnSquidExit)

InitializeSquid()

; ==================================================
; Initialization
; ==================================================

InitializeSquid() {
    EnsureDirectory(SQUID_CONFIG_DIR)
    EnsureDirectory(SQUID_LOG_DIR)
    EnsureConfigFile()

    SQUID_RUNTIME["ConfigExists"] := FileExist(SQUID_CONFIG_PATH) ? true : false
    SQUID_RUNTIME["Config"] := LoadConfig()
    SQUID_RUNTIME["ActiveProfileName"] := SQUID_RUNTIME["Config"]["activeProfile"]
    SQUID_RUNTIME["IsEnabled"] := SQUID_RUNTIME["Config"]["safety"]["globalEnabled"]
    SQUID_RUNTIME["ConfigLoaded"] := true

    RegisterConfiguredHotkeys()
    BuildTrayMenu()
    RefreshTargetsOnStartup()

    WriteLog("INFO", "Startup complete.")
}

EnsureConfigFile() {
    if FileExist(SQUID_CONFIG_PATH) {
        return
    }

    if FileExist(SQUID_EXAMPLE_CONFIG_PATH) {
        FileCopy(SQUID_EXAMPLE_CONFIG_PATH, SQUID_CONFIG_PATH, true)
        return
    }

    SaveConfig(BuildDefaultConfig())
}

RefreshTargetsOnStartup() {
    profile := GetActiveProfile()
    leaderResolved := ResolveAndUpdateWindowDescriptor(profile["leader"])
    followerResolvedCount := 0

    for _, follower in profile["followers"] {
        if ResolveAndUpdateWindowDescriptor(follower) {
            followerResolvedCount += 1
        }
    }

    SaveRuntimeConfig()
    WriteLog("INFO", "Startup target refresh complete. Leader=" leaderResolved " Followers=" followerResolvedCount)
}

; ==================================================
; Tray Menu
; ==================================================

BuildTrayMenu() {
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Enable / Disable Broadcasting", ToggleBroadcasting)
    A_TrayMenu.Add("Emergency Stop", TriggerEmergencyStop)
    A_TrayMenu.Add()
    A_TrayMenu.Add("Discover Candidate Windows", DiscoverCandidateWindows)
    A_TrayMenu.Add("Save Active Window as Leader", SaveActiveWindowAsLeader)
    A_TrayMenu.Add("Add Active Window as Follower", AddActiveWindowAsFollower)
    A_TrayMenu.Add("Remove Last Follower", RemoveLastFollower)
    A_TrayMenu.Add("Clear Leader", ClearLeader)
    A_TrayMenu.Add("Clear Followers", ClearFollowers)
    A_TrayMenu.Add("Refresh Persisted Targets", RefreshPersistedTargets)
    A_TrayMenu.Add()
    A_TrayMenu.Add("Reload Config", ReloadConfigFromDisk)
    A_TrayMenu.Add("Show Status", ShowStatus)
    A_TrayMenu.Add()
    A_TrayMenu.Add("Exit", ExitSquid)
    RefreshTrayTooltip()
}

BuildTrayTooltip() {
    enabledText := SQUID_RUNTIME["IsEnabled"] ? "Enabled" : "Disabled"
    stopText := SQUID_RUNTIME["IsEmergencyStopped"] ? "Emergency Stopped" : "Normal"
    profileText := SQUID_RUNTIME["ActiveProfileName"] != "" ? SQUID_RUNTIME["ActiveProfileName"] : "none"
    followers := GetFollowerCount()

    return SQUID_NAME " " SQUID_VERSION "`n"
        . "State: " enabledText "`n"
        . "Safety: " stopText "`n"
        . "Profile: " profileText "`n"
        . "Followers: " followers
}

RefreshTrayTooltip() {
    TraySetTip(BuildTrayTooltip())
}

; ==================================================
; Commands
; ==================================================

ToggleBroadcasting(*) {
    if SQUID_RUNTIME["IsEmergencyStopped"] {
        WriteLog("WARN", "Broadcast toggle ignored because emergency stop is active.")
        MsgBox("Broadcasting cannot be enabled until emergency stop is cleared.", SQUID_NAME)
        return
    }

    SQUID_RUNTIME["IsEnabled"] := !SQUID_RUNTIME["IsEnabled"]
    SQUID_RUNTIME["Config"]["safety"]["globalEnabled"] := SQUID_RUNTIME["IsEnabled"]
    SaveRuntimeConfig()

    stateText := SQUID_RUNTIME["IsEnabled"] ? "enabled" : "disabled"
    WriteLog("INFO", "Broadcasting " stateText ".")
    RefreshTrayTooltip()
}

TriggerEmergencyStop(*) {
    SQUID_RUNTIME["IsEnabled"] := false
    SQUID_RUNTIME["IsEmergencyStopped"] := true
    SQUID_RUNTIME["Config"]["safety"]["globalEnabled"] := false
    SaveRuntimeConfig()

    WriteLog("WARN", "Emergency stop triggered.")
    RefreshTrayTooltip()
    MsgBox("Emergency stop is active. Broadcasting has been forced off.", SQUID_NAME)
}

DiscoverCandidateWindows(*) {
    windows := EnumerateCandidateWindows()
    reportPath := SQUID_LOG_DIR "\window-candidates.txt"

    WriteWindowDiscoveryReport(windows, reportPath)
    WriteLog("INFO", "Discovered " windows.Length " candidate windows. Report=" reportPath)

    preview := BuildWindowPreview(windows, 8)
    message := "Candidate windows discovered: " windows.Length "`n`nReport:`n" reportPath

    if preview != "" {
        message .= "`n`nPreview:`n" preview
    }

    MsgBox(message, SQUID_NAME)
}

SaveActiveWindowAsLeader(*) {
    hwnd := WinExist("A")

    if !hwnd {
        MsgBox("No active window was found.", SQUID_NAME)
        return
    }

    descriptor := CaptureWindowDescriptorFromHwnd(hwnd, "Leader")

    if !DescriptorHasIdentity(descriptor) {
        MsgBox("The active window is not usable as a target.", SQUID_NAME)
        return
    }

    profile := GetActiveProfile()
    profile["leader"] := descriptor
    SaveRuntimeConfig()

    WriteLog("INFO", "Saved leader target. HWND=" descriptor["hwnd"] " EXE=" descriptor["exe"] " TITLE=" descriptor["titleContains"])
    RefreshTrayTooltip()
    MsgBox("Active window saved as leader.", SQUID_NAME)
}

AddActiveWindowAsFollower(*) {
    hwnd := WinExist("A")

    if !hwnd {
        MsgBox("No active window was found.", SQUID_NAME)
        return
    }

    descriptor := CaptureWindowDescriptorFromHwnd(hwnd, "Follower" (GetFollowerCount() + 1))

    if !DescriptorHasIdentity(descriptor) {
        MsgBox("The active window is not usable as a follower.", SQUID_NAME)
        return
    }

    profile := GetActiveProfile()

    if SameDescriptor(profile["leader"], descriptor) {
        MsgBox("The active window matches the current leader and was not added as a follower.", SQUID_NAME)
        return
    }

    duplicateIndex := FindFollowerIndex(profile["followers"], descriptor)

    if duplicateIndex {
        MsgBox("That follower already exists in the active profile.", SQUID_NAME)
        return
    }

    profile["followers"].Push(descriptor)
    SaveRuntimeConfig()

    WriteLog("INFO", "Added follower target. HWND=" descriptor["hwnd"] " EXE=" descriptor["exe"] " TITLE=" descriptor["titleContains"])
    RefreshTrayTooltip()
    MsgBox("Active window added as follower.", SQUID_NAME)
}

RemoveLastFollower(*) {
    profile := GetActiveProfile()

    if profile["followers"].Length = 0 {
        MsgBox("There are no followers to remove.", SQUID_NAME)
        return
    }

    removed := profile["followers"].Pop()
    SaveRuntimeConfig()

    WriteLog("INFO", "Removed last follower. HWND=" removed["hwnd"] " EXE=" removed["exe"] " TITLE=" removed["titleContains"])
    RefreshTrayTooltip()
    MsgBox("Last follower removed.", SQUID_NAME)
}

ClearLeader(*) {
    profile := GetActiveProfile()
    profile["leader"] := BuildEmptyWindowDescriptor("Leader")
    SaveRuntimeConfig()

    WriteLog("INFO", "Cleared leader target.")
    RefreshTrayTooltip()
    MsgBox("Leader target cleared.", SQUID_NAME)
}

ClearFollowers(*) {
    profile := GetActiveProfile()
    profile["followers"] := []
    SaveRuntimeConfig()

    WriteLog("INFO", "Cleared all follower targets.")
    RefreshTrayTooltip()
    MsgBox("All follower targets cleared.", SQUID_NAME)
}

RefreshPersistedTargets(*) {
    profile := GetActiveProfile()
    leaderResolved := ResolveAndUpdateWindowDescriptor(profile["leader"])
    followerResolvedCount := 0
    followerTotal := profile["followers"].Length

    for _, follower in profile["followers"] {
        if ResolveAndUpdateWindowDescriptor(follower) {
            followerResolvedCount += 1
        }
    }

    SaveRuntimeConfig()
    RefreshTrayTooltip()

    WriteLog("INFO", "Manual target refresh complete. Leader=" leaderResolved " Followers=" followerResolvedCount "/" followerTotal)
    MsgBox(
        "Target refresh complete.`n`nLeader resolved: " leaderResolved
        . "`nFollowers resolved: " followerResolvedCount "/" followerTotal,
        SQUID_NAME
    )
}

ReloadConfigFromDisk(*) {
    SQUID_RUNTIME["Config"] := LoadConfig()
    SQUID_RUNTIME["ActiveProfileName"] := SQUID_RUNTIME["Config"]["activeProfile"]
    SQUID_RUNTIME["IsEnabled"] := SQUID_RUNTIME["Config"]["safety"]["globalEnabled"]
    SQUID_RUNTIME["IsEmergencyStopped"] := false

    RegisterConfiguredHotkeys()
    RefreshTargetsOnStartup()
    RefreshTrayTooltip()

    WriteLog("INFO", "Config reloaded from disk.")
    MsgBox("Config reloaded from disk.", SQUID_NAME)
}

ShowStatus(*) {
    profile := GetActiveProfile()
    leader := profile["leader"]
    followers := profile["followers"]
    hotkeys := SQUID_RUNTIME["RegisteredHotkeys"]

    statusText := SQUID_NAME " " SQUID_VERSION "`n`n"
        . "Enabled: " BoolText(SQUID_RUNTIME["IsEnabled"]) "`n"
        . "Emergency Stopped: " BoolText(SQUID_RUNTIME["IsEmergencyStopped"]) "`n"
        . "Config Exists: " BoolText(SQUID_RUNTIME["ConfigExists"]) "`n"
        . "Config Loaded: " BoolText(SQUID_RUNTIME["ConfigLoaded"]) "`n"
        . "Active Profile: " SQUID_RUNTIME["ActiveProfileName"] "`n"
        . "Config Path: " SQUID_CONFIG_PATH "`n"
        . "Leader HWND: " leader["hwnd"] "`n"
        . "Leader EXE: " leader["exe"] "`n"
        . "Leader Title: " leader["titleContains"] "`n"
        . "Follower Count: " followers.Length "`n"
        . "Toggle Hotkey: " SQUID_RUNTIME["Config"]["safety"]["toggleHotkey"] "`n"
        . "Emergency Hotkey: " SQUID_RUNTIME["Config"]["safety"]["emergencyStopHotkey"] "`n"
        . "Registered Hotkeys: " hotkeys.Length

    MsgBox(statusText, SQUID_NAME " Status")
}

ExitSquid(*) {
    ExitApp()
}

; ==================================================
; Window Discovery and Targeting
; ==================================================

EnumerateCandidateWindows() {
    windows := []

    for _, hwnd in WinGetList() {
        if !IsViableTopLevelWindow(hwnd) {
            continue
        }

        descriptor := CaptureWindowDescriptorFromHwnd(hwnd, "")
        windows.Push(descriptor)
    }

    return windows
}

IsViableTopLevelWindow(hwnd) {
    if !DllCall("IsWindowVisible", "Ptr", hwnd, "Int") {
        return false
    }

    title := Trim(WinGetTitle("ahk_id " hwnd))

    if title = "" {
        return false
    }

    className := WinGetClass("ahk_id " hwnd)

    if className = "Progman" || className = "Shell_TrayWnd" || className = "WorkerW" {
        return false
    }

    return true
}

CaptureWindowDescriptorFromHwnd(hwnd, fallbackName := "") {
    title := Trim(WinGetTitle("ahk_id " hwnd))
    exe := ""
    className := ""

    try exe := WinGetProcessName("ahk_id " hwnd)
    try className := WinGetClass("ahk_id " hwnd)

    descriptor := Map()
    descriptor["name"] := fallbackName
    descriptor["hwnd"] := hwnd + 0
    descriptor["exe"] := exe
    descriptor["titleContains"] := title
    descriptor["class"] := className

    return descriptor
}

BuildEmptyWindowDescriptor(name := "") {
    descriptor := Map()
    descriptor["name"] := name
    descriptor["hwnd"] := 0
    descriptor["exe"] := ""
    descriptor["titleContains"] := ""
    descriptor["class"] := ""
    return descriptor
}

DescriptorHasIdentity(descriptor) {
    return descriptor["hwnd"] || descriptor["exe"] != "" || descriptor["titleContains"] != "" || descriptor["class"] != ""
}

ResolveAndUpdateWindowDescriptor(descriptor) {
    if !DescriptorHasIdentity(descriptor) {
        descriptor["hwnd"] := 0
        return 0
    }

    originalHwnd := descriptor["hwnd"]

    if originalHwnd && IsWindowHandleUsable(originalHwnd) && WindowMatchesDescriptor(originalHwnd, descriptor) {
        return originalHwnd
    }

    for _, hwnd in WinGetList() {
        if !IsViableTopLevelWindow(hwnd) {
            continue
        }

        if WindowMatchesDescriptor(hwnd, descriptor) {
            descriptor["hwnd"] := hwnd + 0
            return descriptor["hwnd"]
        }
    }

    descriptor["hwnd"] := 0
    return 0
}

IsWindowHandleUsable(hwnd) {
    return DllCall("IsWindow", "Ptr", hwnd, "Int") ? true : false
}

WindowMatchesDescriptor(hwnd, descriptor) {
    actualTitle := Trim(WinGetTitle("ahk_id " hwnd))
    actualExe := ""
    actualClass := ""

    try actualExe := WinGetProcessName("ahk_id " hwnd)
    try actualClass := WinGetClass("ahk_id " hwnd)

    if descriptor["exe"] != "" && actualExe != descriptor["exe"] {
        return false
    }

    if descriptor["class"] != "" && actualClass != descriptor["class"] {
        return false
    }

    if descriptor["titleContains"] != "" && !InStr(actualTitle, descriptor["titleContains"]) {
        return false
    }

    return true
}

SameDescriptor(leftDescriptor, rightDescriptor) {
    if !DescriptorHasIdentity(leftDescriptor) || !DescriptorHasIdentity(rightDescriptor) {
        return false
    }

    if leftDescriptor["exe"] != rightDescriptor["exe"] {
        return false
    }

    if leftDescriptor["class"] != rightDescriptor["class"] {
        return false
    }

    if leftDescriptor["titleContains"] != rightDescriptor["titleContains"] {
        return false
    }

    return true
}

FindFollowerIndex(followers, descriptor) {
    for index, follower in followers {
        if SameDescriptor(follower, descriptor) {
            return index
        }
    }

    return 0
}

BuildWindowPreview(windows, maxItems := 8) {
    if windows.Length = 0 {
        return ""
    }

    lines := []
    limit := windows.Length < maxItems ? windows.Length : maxItems

    loop limit {
        descriptor := windows[A_Index]
        lines.Push(
            A_Index ". HWND=" descriptor["hwnd"]
            . " | EXE=" descriptor["exe"]
            . " | TITLE=" descriptor["titleContains"]
        )
    }

    return JoinLines(lines)
}

WriteWindowDiscoveryReport(windows, reportPath) {
    lines := []
    lines.Push("Squid window discovery report")
    lines.Push("Generated: " FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss"))
    lines.Push("Count: " windows.Length)
    lines.Push("")

    for index, descriptor in windows {
        lines.Push("[" index "]")
        lines.Push("HWND=" descriptor["hwnd"])
        lines.Push("EXE=" descriptor["exe"])
        lines.Push("CLASS=" descriptor["class"])
        lines.Push("TITLE=" descriptor["titleContains"])
        lines.Push("")
    }

    try FileDelete(reportPath)
    FileAppend(JoinLines(lines) "`n", reportPath, "UTF-8")
}

GetFollowerCount() {
    return GetActiveProfile()["followers"].Length
}

; ==================================================
; Config
; ==================================================

BuildDefaultConfig() {
    config := Map()
    config["version"] := 1
    config["activeProfile"] := "default"

    logging := Map()
    logging["enabled"] := true
    logging["level"] := "info"
    logging["logDirectory"] := "logs"
    config["logging"] := logging

    safety := Map()
    safety["globalEnabled"] := false
    safety["toggleHotkey"] := "F9"
    safety["emergencyStopHotkey"] := "F10"
    safety["wheelDebounceMs"] := 120
    config["safety"] := safety

    profiles := []
    profiles.Push(BuildDefaultProfile("default"))
    config["profiles"] := profiles

    return config
}

BuildDefaultProfile(profileName) {
    profile := Map()
    profile["name"] := profileName
    profile["leader"] := BuildEmptyWindowDescriptor("Leader")
    profile["followers"] := []
    profile["mappings"] := BuildDefaultMappings()
    return profile
}

BuildDefaultMappings() {
    mappings := []

    mappings.Push(Map("input", "1", "type", "keyboard", "enabled", true, "targets", "followers"))
    mappings.Push(Map("input", "RButton", "type", "mouse_button", "enabled", true, "targets", "followers"))
    mappings.Push(Map("input", "WheelUp", "type", "mouse_wheel", "enabled", true, "targets", "followers"))
    mappings.Push(Map("input", "WheelDown", "type", "mouse_wheel", "enabled", true, "targets", "followers"))

    return mappings
}

LoadConfig() {
    configText := ""

    try {
        configText := FileRead(SQUID_CONFIG_PATH, "UTF-8")
    } catch Error as readError {
        WriteLog("ERROR", "Failed to read config file. " readError.Message)
        return BuildDefaultConfig()
    }

    if Trim(configText) = "" {
        WriteLog("WARN", "Config file was empty. Default config loaded.")
        return BuildDefaultConfig()
    }

    try {
        parsed := JsonParse(configText)
    } catch Error as parseError {
        WriteLog("ERROR", "Failed to parse config JSON. " parseError.Message)
        return BuildDefaultConfig()
    }

    return NormalizeConfig(parsed)
}

NormalizeConfig(rawConfig) {
    if !(rawConfig is Map) {
        return BuildDefaultConfig()
    }

    config := BuildDefaultConfig()

    if rawConfig.Has("version") {
        config["version"] := ToIntSafe(rawConfig["version"], 1)
    }

    if rawConfig.Has("activeProfile") {
        profileName := ToStringSafe(rawConfig["activeProfile"], "default")
        config["activeProfile"] := profileName != "" ? profileName : "default"
    }

    if rawConfig.Has("logging") && rawConfig["logging"] is Map {
        rawLogging := rawConfig["logging"]
        config["logging"]["enabled"] := ToBoolSafe(rawLogging.Has("enabled") ? rawLogging["enabled"] : true)
        config["logging"]["level"] := ToStringSafe(rawLogging.Has("level") ? rawLogging["level"] : "info", "info")
        config["logging"]["logDirectory"] := ToStringSafe(rawLogging.Has("logDirectory") ? rawLogging["logDirectory"] : "logs", "logs")
    }

    if rawConfig.Has("safety") && rawConfig["safety"] is Map {
        rawSafety := rawConfig["safety"]
        config["safety"]["globalEnabled"] := ToBoolSafe(rawSafety.Has("globalEnabled") ? rawSafety["globalEnabled"] : false)
        config["safety"]["toggleHotkey"] := ToStringSafe(rawSafety.Has("toggleHotkey") ? rawSafety["toggleHotkey"] : "F9", "F9")
        config["safety"]["emergencyStopHotkey"] := ToStringSafe(rawSafety.Has("emergencyStopHotkey") ? rawSafety["emergencyStopHotkey"] : "F10", "F10")
        config["safety"]["wheelDebounceMs"] := ToIntSafe(rawSafety.Has("wheelDebounceMs") ? rawSafety["wheelDebounceMs"] : 120, 120)
    }

    profiles := []

    if rawConfig.Has("profiles") && rawConfig["profiles"] is Array {
        for _, rawProfile in rawConfig["profiles"] {
            normalizedProfile := NormalizeProfile(rawProfile)
            profiles.Push(normalizedProfile)
        }
    }

    if profiles.Length = 0 {
        profiles.Push(BuildDefaultProfile(config["activeProfile"]))
    }

    config["profiles"] := profiles

    if !HasProfileNamed(config["profiles"], config["activeProfile"]) {
        config["profiles"].Push(BuildDefaultProfile(config["activeProfile"]))
    }

    return config
}

NormalizeProfile(rawProfile) {
    if !(rawProfile is Map) {
        return BuildDefaultProfile("default")
    }

    profileName := ToStringSafe(rawProfile.Has("name") ? rawProfile["name"] : "default", "default")
    profile := BuildDefaultProfile(profileName)

    if rawProfile.Has("leader") && rawProfile["leader"] is Map {
        profile["leader"] := NormalizeWindowDescriptor(rawProfile["leader"], "Leader")
    }

    followers := []

    if rawProfile.Has("followers") && rawProfile["followers"] is Array {
        for _, rawFollower in rawProfile["followers"] {
            followers.Push(NormalizeWindowDescriptor(rawFollower, "Follower"))
        }
    }

    profile["followers"] := followers

    mappings := []

    if rawProfile.Has("mappings") && rawProfile["mappings"] is Array {
        for _, rawMapping in rawProfile["mappings"] {
            mappings.Push(NormalizeMapping(rawMapping))
        }
    }

    if mappings.Length > 0 {
        profile["mappings"] := mappings
    }

    return profile
}

NormalizeWindowDescriptor(rawDescriptor, defaultName := "") {
    if !(rawDescriptor is Map) {
        return BuildEmptyWindowDescriptor(defaultName)
    }

    descriptor := BuildEmptyWindowDescriptor(defaultName)
    descriptor["name"] := ToStringSafe(rawDescriptor.Has("name") ? rawDescriptor["name"] : defaultName, defaultName)
    descriptor["hwnd"] := ToIntSafe(rawDescriptor.Has("hwnd") ? rawDescriptor["hwnd"] : 0, 0)
    descriptor["exe"] := ToStringSafe(rawDescriptor.Has("exe") ? rawDescriptor["exe"] : "", "")
    descriptor["titleContains"] := ToStringSafe(rawDescriptor.Has("titleContains") ? rawDescriptor["titleContains"] : "", "")
    descriptor["class"] := ToStringSafe(rawDescriptor.Has("class") ? rawDescriptor["class"] : "", "")
    return descriptor
}

NormalizeMapping(rawMapping) {
    mapping := Map()
    mapping["input"] := ""
    mapping["type"] := "keyboard"
    mapping["enabled"] := true
    mapping["targets"] := "followers"

    if rawMapping is Map {
        mapping["input"] := ToStringSafe(rawMapping.Has("input") ? rawMapping["input"] : "", "")
        mapping["type"] := ToStringSafe(rawMapping.Has("type") ? rawMapping["type"] : "keyboard", "keyboard")
        mapping["enabled"] := ToBoolSafe(rawMapping.Has("enabled") ? rawMapping["enabled"] : true)
        mapping["targets"] := ToStringSafe(rawMapping.Has("targets") ? rawMapping["targets"] : "followers", "followers")
    }

    return mapping
}

HasProfileNamed(profiles, profileName) {
    for _, profile in profiles {
        if profile["name"] = profileName {
            return true
        }
    }

    return false
}

GetActiveProfile() {
    config := SQUID_RUNTIME["Config"]
    profileName := config["activeProfile"]

    for _, profile in config["profiles"] {
        if profile["name"] = profileName {
            return profile
        }
    }

    newProfile := BuildDefaultProfile(profileName)
    config["profiles"].Push(newProfile)
    return newProfile
}

SaveRuntimeConfig() {
    SaveConfig(SQUID_RUNTIME["Config"])
}

SaveConfig(config) {
    jsonText := RenderConfigJson(config)
    try FileDelete(SQUID_CONFIG_PATH)
    FileAppend(jsonText "`n", SQUID_CONFIG_PATH, "UTF-8")
}

RenderConfigJson(config) {
    lines := []
    lines.Push("{")
    lines.Push('  "version": ' config["version"] ",")
    lines.Push('  "activeProfile": "' JsonEscape(config["activeProfile"]) '",')
    lines.Push('  "logging": {')
    lines.Push('    "enabled": ' BoolJson(config["logging"]["enabled"]) ",")
    lines.Push('    "level": "' JsonEscape(config["logging"]["level"]) '",')
    lines.Push('    "logDirectory": "' JsonEscape(config["logging"]["logDirectory"]) '"')
    lines.Push("  },")
    lines.Push('  "safety": {')
    lines.Push('    "globalEnabled": ' BoolJson(config["safety"]["globalEnabled"]) ",")
    lines.Push('    "toggleHotkey": "' JsonEscape(config["safety"]["toggleHotkey"]) '",')
    lines.Push('    "emergencyStopHotkey": "' JsonEscape(config["safety"]["emergencyStopHotkey"]) '",')
    lines.Push('    "wheelDebounceMs": ' config["safety"]["wheelDebounceMs"])
    lines.Push("  },")
    lines.Push('  "profiles": [')

    profiles := config["profiles"]

    for index, profile in profiles {
        isLastProfile := index = profiles.Length
        lines.Push(RenderProfileJson(profile, 2) . (isLastProfile ? "" : ","))
    }

    lines.Push("  ]")
    lines.Push("}")

    return JoinLines(lines)
}

RenderProfileJson(profile, indentLevel := 0) {
    indent := Indent(indentLevel)
    inner := Indent(indentLevel + 1)
    lines := []

    lines.Push(indent "{")
    lines.Push(inner '"name": "' JsonEscape(profile["name"]) '",')
    lines.Push(inner '"leader": ' RenderWindowDescriptorJson(profile["leader"], indentLevel + 1) ",")
    lines.Push(inner '"followers": [')

    followers := profile["followers"]

    if followers.Length > 0 {
        for index, follower in followers {
            isLastFollower := index = followers.Length
            lines.Push(RenderWindowDescriptorJson(follower, indentLevel + 2) . (isLastFollower ? "" : ","))
        }
    }

    lines.Push(inner "],")
    lines.Push(inner '"mappings": [')

    mappings := profile["mappings"]

    if mappings.Length > 0 {
        for index, mapping in mappings {
            isLastMapping := index = mappings.Length
            lines.Push(RenderMappingJson(mapping, indentLevel + 2) . (isLastMapping ? "" : ","))
        }
    }

    lines.Push(inner "]")
    lines.Push(indent "}")

    return JoinLines(lines)
}

RenderWindowDescriptorJson(descriptor, indentLevel := 0) {
    indent := Indent(indentLevel)
    inner := Indent(indentLevel + 1)
    lines := []

    lines.Push(indent "{")
    lines.Push(inner '"name": "' JsonEscape(descriptor["name"]) '",')
    lines.Push(inner '"hwnd": ' descriptor["hwnd"] ",")
    lines.Push(inner '"exe": "' JsonEscape(descriptor["exe"]) '",')
    lines.Push(inner '"titleContains": "' JsonEscape(descriptor["titleContains"]) '",')
    lines.Push(inner '"class": "' JsonEscape(descriptor["class"]) '"')
    lines.Push(indent "}")

    return JoinLines(lines)
}

RenderMappingJson(mapping, indentLevel := 0) {
    indent := Indent(indentLevel)
    inner := Indent(indentLevel + 1)
    lines := []

    lines.Push(indent "{")
    lines.Push(inner '"input": "' JsonEscape(mapping["input"]) '",')
    lines.Push(inner '"type": "' JsonEscape(mapping["type"]) '",')
    lines.Push(inner '"enabled": ' BoolJson(mapping["enabled"]) ",")
    lines.Push(inner '"targets": "' JsonEscape(mapping["targets"]) '"')
    lines.Push(indent "}")

    return JoinLines(lines)
}

Indent(level) {
    text := ""

    loop level {
        text .= "  "
    }

    return text
}

JsonEscape(text) {
    escaped := text
    escaped := StrReplace(escaped, "\", "\\")
    escaped := StrReplace(escaped, '"', '\"')
    escaped := StrReplace(escaped, "`r", "\r")
    escaped := StrReplace(escaped, "`n", "\n")
    escaped := StrReplace(escaped, "`t", "\t")
    return escaped
}

BoolJson(value) {
    return value ? "true" : "false"
}

BoolText(value) {
    return value ? "true" : "false"
}

ToStringSafe(value, fallback := "") {
    try {
        return value . ""
    } catch {
        return fallback
    }
}

ToIntSafe(value, fallback := 0) {
    try {
        return value + 0
    } catch {
        return fallback
    }
}

ToBoolSafe(value) {
    if value is String {
        lowerValue := StrLower(value)
        return lowerValue = "true" || lowerValue = "1" || lowerValue = "yes" || lowerValue = "on"
    }

    return value ? true : false
}

JoinLines(lines) {
    output := ""

    for index, line in lines {
        if index > 1 {
            output .= "`n"
        }

        output .= line
    }

    return output
}

; ==================================================
; Hotkeys
; ==================================================

RegisterConfiguredHotkeys() {
    for _, hotkeyName in SQUID_RUNTIME["RegisteredHotkeys"] {
        try Hotkey(hotkeyName, "Off")
    }

    SQUID_RUNTIME["RegisteredHotkeys"] := []

    toggleHotkey := SQUID_RUNTIME["Config"]["safety"]["toggleHotkey"]
    emergencyHotkey := SQUID_RUNTIME["Config"]["safety"]["emergencyStopHotkey"]

    RegisterHotkeyIfPresent(toggleHotkey, ToggleBroadcasting)
    RegisterHotkeyIfPresent(emergencyHotkey, TriggerEmergencyStop)
}

RegisterHotkeyIfPresent(hotkeyName, callback) {
    if hotkeyName = "" {
        return
    }

    try {
        Hotkey(hotkeyName, callback, "On")
        SQUID_RUNTIME["RegisteredHotkeys"].Push(hotkeyName)
        WriteLog("INFO", "Registered hotkey: " hotkeyName)
    } catch Error as hotkeyError {
        WriteLog("ERROR", "Failed to register hotkey: " hotkeyName ". " hotkeyError.Message)
    }
}

; ==================================================
; JSON Parser
; ==================================================

JsonParse(jsonText) {
    position := 1
    value := JsonParseValue(jsonText, &position)
    JsonSkipWhitespace(jsonText, &position)

    if position <= StrLen(jsonText) {
        throw Error("Unexpected trailing JSON content at position " position ".")
    }

    return value
}

JsonParseValue(jsonText, &position) {
    JsonSkipWhitespace(jsonText, &position)

    if position > StrLen(jsonText) {
        throw Error("Unexpected end of JSON input.")
    }

    character := SubStr(jsonText, position, 1)

    if character = "{" {
        return JsonParseObject(jsonText, &position)
    }

    if character = "[" {
        return JsonParseArray(jsonText, &position)
    }

    if character = '"' {
        return JsonParseString(jsonText, &position)
    }

    if character = "-" || IsDigit(character) {
        return JsonParseNumber(jsonText, &position)
    }

    if SubStr(jsonText, position, 4) = "true" {
        position += 4
        return true
    }

    if SubStr(jsonText, position, 5) = "false" {
        position += 5
        return false
    }

    if SubStr(jsonText, position, 4) = "null" {
        position += 4
        return ""
    }

    throw Error("Unexpected token at position " position ".")
}

JsonParseObject(jsonText, &position) {
    object := Map()
    position += 1
    JsonSkipWhitespace(jsonText, &position)

    if SubStr(jsonText, position, 1) = "}" {
        position += 1
        return object
    }

    loop {
        key := JsonParseString(jsonText, &position)
        JsonSkipWhitespace(jsonText, &position)

        if SubStr(jsonText, position, 1) != ":" {
            throw Error("Expected ':' at position " position ".")
        }

        position += 1
        value := JsonParseValue(jsonText, &position)
        object[key] := value

        JsonSkipWhitespace(jsonText, &position)
        character := SubStr(jsonText, position, 1)

        if character = "}" {
            position += 1
            return object
        }

        if character != "," {
            throw Error("Expected ',' or '}' at position " position ".")
        }

        position += 1
        JsonSkipWhitespace(jsonText, &position)
    }
}

JsonParseArray(jsonText, &position) {
    array := []
    position += 1
    JsonSkipWhitespace(jsonText, &position)

    if SubStr(jsonText, position, 1) = "]" {
        position += 1
        return array
    }

    loop {
        array.Push(JsonParseValue(jsonText, &position))
        JsonSkipWhitespace(jsonText, &position)

        character := SubStr(jsonText, position, 1)

        if character = "]" {
            position += 1
            return array
        }

        if character != "," {
            throw Error("Expected ',' or ']' at position " position ".")
        }

        position += 1
        JsonSkipWhitespace(jsonText, &position)
    }
}

JsonParseString(jsonText, &position) {
    if SubStr(jsonText, position, 1) != '"' {
        throw Error("Expected string at position " position ".")
    }

    position += 1
    result := ""

    while position <= StrLen(jsonText) {
        character := SubStr(jsonText, position, 1)

        if character = '"' {
            position += 1
            return result
        }

        if character = "\" {
            position += 1

            if position > StrLen(jsonText) {
                throw Error("Unexpected end of JSON escape sequence.")
            }

            escapeCharacter := SubStr(jsonText, position, 1)

            switch escapeCharacter {
                case '"':
                    result .= '"'
                case "\":
                    result .= "\"
                case "/":
                    result .= "/"
                case "b":
                    result .= Chr(8)
                case "f":
                    result .= Chr(12)
                case "n":
                    result .= "`n"
                case "r":
                    result .= "`r"
                case "t":
                    result .= "`t"
                case "u":
                    hexValue := SubStr(jsonText, position + 1, 4)

                    if StrLen(hexValue) != 4 {
                        throw Error("Invalid unicode escape at position " position ".")
                    }

                    result .= Chr(("0x" hexValue) + 0)
                    position += 4
                default:
                    throw Error("Unsupported escape sequence at position " position ".")
            }
        } else {
            result .= character
        }

        position += 1
    }

    throw Error("Unterminated JSON string.")
}

JsonParseNumber(jsonText, &position) {
    start := position

    while position <= StrLen(jsonText) {
        character := SubStr(jsonText, position, 1)

        if InStr("+-0123456789.eE", character) {
            position += 1
            continue
        }

        break
    }

    numberText := SubStr(jsonText, start, position - start)

    if numberText = "" {
        throw Error("Invalid number at position " start ".")
    }

    return numberText + 0
}

JsonSkipWhitespace(jsonText, &position) {
    while position <= StrLen(jsonText) {
        character := SubStr(jsonText, position, 1)

        if character = " " || character = "`t" || character = "`n" || character = "`r" {
            position += 1
            continue
        }

        break
    }
}

IsDigit(character) {
    return character ~= "^\d$"
}

; ==================================================
; Logging
; ==================================================

WriteLog(level, message) {
    timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
    logLine := "[" timestamp "] [" level "] " message "`n"

    try {
        FileAppend(logLine, SQUID_LOG_PATH, "UTF-8")
    }
}

; ==================================================
; Shutdown
; ==================================================

OnSquidExit(exitReason, exitCode) {
    WriteLog("INFO", "Shutdown. Reason=" exitReason " Code=" exitCode)
}

; End of script
