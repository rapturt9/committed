# Committed - Architecture

## Overview
macOS menu bar app for commitment tracking with deadline enforcement, forecasting, and reflection.

## Core Loop
1. Set deadline with probability forecast (synced to Fatebook)
2. As deadline approaches (T-24h): full-screen pre-mortem overlay forces you to identify 3 risks
3. After deadline passes: full-screen post-mortem overlay forces reflection
4. All data synced to Obsidian daily notes

## Project Structure
```
Committed/Sources/
  App/
    CommittedApp.swift      - @main entry, MenuBarExtra scene
    AppDelegate.swift       - Lifecycle, deadline timer (60s interval)
  Models/
    Commitment.swift        - Core model with status, source, forecasts
    PreMortem.swift         - 3 risks + mitigations
    PostMortem.swift        - Outcome, what worked/failed, lessons
    Forecast.swift          - Probability snapshots
  Views/
    MenuBarIcon.swift       - Badge with overdue/today counts
    MenuBarPopover.swift    - Main UI: grouped commitment list
    AddCommitmentView.swift - New commitment form with forecast slider
    SettingsView.swift      - Launch at login, integration toggles
  Overlay/
    OverlayManager.swift    - NSWindow at .screenSaver level, modal
    OverlayContentView.swift - Pre-mortem and post-mortem forms
  Services/
    Store.swift             - JSON persistence to ~/Library/Application Support/Committed/
    Config.swift            - .env file reader for API keys
    FatebookService.swift   - createQuestion, getQuestion endpoints
    RemindersService.swift  - EventKit integration for Apple Reminders
    StreaksService.swift     - SQLite reader for Streaks app data
    ObsidianService.swift   - Read commitments.md, write to daily notes
    IntegrationManager.swift - Orchestrates all service syncs
```

## Data Flow
- **Persistence**: JSON file at `~/Library/Application Support/Committed/commitments.json`
- **Config**: `.env` bundled in app or at `~/.committed.env`
- **Overlay trigger**: 60-second timer checks deadlines, shows overlay if needed
- **Overlay is modal**: NSWindow at `.screenSaver` level, borderless, covers full screen

## Integrations
| Service | Method | Direction |
|---------|--------|-----------|
| Fatebook | REST API (v0) | Write (create forecasts) |
| Apple Reminders | EventKit | Read (pull due items) |
| Streaks | SQLite direct read | Read (habit data) |
| Obsidian | File I/O | Read/Write (commitments.md, daily notes) |

## Build
Requires: macOS 14+, Swift 5.9+ (Command Line Tools sufficient, no Xcode needed)
```
./build.sh           # Builds and creates .app bundle
open .build/arm64-apple-macosx/debug/Committed.app
```
