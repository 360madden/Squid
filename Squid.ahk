; ==================================================
; Version: 0.1.0-dev
; Total Characters: 5350
; Purpose: Bootstrap shell for Squid, a Windows local input broadcaster
;          written in AutoHotkey v2. This skeleton initializes runtime
;          state, logging, tray controls, and config presence checks.
; ==================================================

#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn
SetWorkingDir A_ScriptDir

global SQUID_VERSION := "0.1.0-dev"
global SQUID_NAME := "Squid"
global SQUID_BASE_DIR := A_ScriptDir
global SQUID_CONFIG_DIR := SQUID_BASE_DIR "\config"
global SQUID_LOG_DIR := SQUID_BASE_DIR "\logs"
global SQUID_CONFIG_PATH := SQUID_CONFIG_DIR "\profiles.example.json"
global SQUID_RUNTIME := Map(
    "IsEnabled", false,
    "IsEmergencyStopped", false,
    "ActiveProfileName", "",
    "ConfigLoaded", false,
    "ConfigExists", false,
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

    BuildTrayMenu()
    LoadBootstrapConfig()
    WriteLog("INFO", "Startup complete.")
}

LoadBootstrapConfig() {
    exists := FileExist(SQUID_CONFIG_PATH) ? true : false

    SQUID_RUNTIME["ConfigExists"] := exists
    SQUID_RUNTIME["ConfigLoaded"] := exists
    SQUID_RUNTIME["ActiveProfileName"] := exists ? "default" : ""

    if exists {
        WriteLog("INFO", "Config file detected at: " SQUID_CONFIG_PATH)
    } else {
        WriteLog("WARN", "Config file not found at: " SQUID_CONFIG_PATH)
    }
}

EnsureDirectory(directoryPath) {
    if !DirExist(directoryPath) {
        DirCreate(directoryPath)
    }
}

; ==================================================
; Tray Menu
; ==================================================

BuildTrayMenu() {
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Enable / Disable Broadcasting", ToggleBroadcasting)
    A_TrayMenu.Add("Emergency Stop", TriggerEmergencyStop)
    A_TrayMenu.Add()
    A_TrayMenu.Add("Reload Bootstrap Config", ReloadBootstrapConfig)
    A_TrayMenu.Add("Refresh Targets (Placeholder)", RefreshTargetsPlaceholder)
    A_TrayMenu.Add("Show Status", ShowStatus)
    A_TrayMenu.Add()
    A_TrayMenu.Add("Exit", ExitSquid)
    TraySetTip(BuildTrayTooltip())
}

BuildTrayTooltip() {
    enabledText := SQUID_RUNTIME["IsEnabled"] ? "Enabled" : "Disabled"
    stopText := SQUID_RUNTIME["IsEmergencyStopped"] ? "Emergency Stopped" : "Normal"
    profileText := SQUID_RUNTIME["ActiveProfileName"] != "" ? SQUID_RUNTIME["ActiveProfileName"] : "none"

    return SQUID_NAME " " SQUID_VERSION "`n"
        . "State: " enabledText "`n"
        . "Safety: " stopText "`n"
        . "Profile: " profileText
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
    stateText := SQUID_RUNTIME["IsEnabled"] ? "enabled" : "disabled"

    WriteLog("INFO", "Broadcasting " stateText ".")
    RefreshTrayTooltip()
}

TriggerEmergencyStop(*) {
    SQUID_RUNTIME["IsEnabled"] := false
    SQUID_RUNTIME["IsEmergencyStopped"] := true

    WriteLog("WARN", "Emergency stop triggered.")
    RefreshTrayTooltip()
    MsgBox("Emergency stop is active. Broadcasting has been forced off.", SQUID_NAME)
}

ReloadBootstrapConfig(*) {
    LoadBootstrapConfig()
    WriteLog("INFO", "Bootstrap config reload requested.")
    RefreshTrayTooltip()
}

RefreshTargetsPlaceholder(*) {
    WriteLog("INFO", "Target refresh placeholder invoked.")
    MsgBox("Target refresh is not implemented yet.", SQUID_NAME)
}

ShowStatus(*) {
    statusText := SQUID_NAME " " SQUID_VERSION "`n`n"
        . "Enabled: " (SQUID_RUNTIME["IsEnabled"] ? "true" : "false") "`n"
        . "Emergency Stopped: " (SQUID_RUNTIME["IsEmergencyStopped"] ? "true" : "false") "`n"
        . "Config Exists: " (SQUID_RUNTIME["ConfigExists"] ? "true" : "false") "`n"
        . "Config Loaded: " (SQUID_RUNTIME["ConfigLoaded"] ? "true" : "false") "`n"
        . "Active Profile: " (SQUID_RUNTIME["ActiveProfileName"] != "" ? SQUID_RUNTIME["ActiveProfileName"] : "none") "`n"
        . "Config Path: " SQUID_CONFIG_PATH

    MsgBox(statusText, SQUID_NAME " Status")
}

ExitSquid(*) {
    ExitApp()
}

; ==================================================
; Logging
; ==================================================

WriteLog(level, message) {
    timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
    logLine := "[" timestamp "] [" level "] " message "`n"
    logPath := SQUID_LOG_DIR "\squid.log"

    try {
        FileAppend(logLine, logPath, "UTF-8")
    }
}

; ==================================================
; Shutdown
; ==================================================

OnSquidExit(exitReason, exitCode) {
    WriteLog("INFO", "Shutdown. Reason=" exitReason " Code=" exitCode)
}

; End of script
