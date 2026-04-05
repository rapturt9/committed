# committed

A macOS menu bar app that forces accountability through commitment tracking, forecasting, and forced reflections.

**Core idea**: You can't use your computer without active commitments. Failed tasks force post-mortems. Everything is tracked with Brier scores.

## What it does

- **Menu bar countdown** to your next task (seconds when under 15 min)
- **Full-screen overlay** blocks your screen if you have no commitments in the next 24 hours
- **Pre-mortems forced on creation**: identify 3 risks before you can commit
- **Post-mortems forced on failure**: reflect on what went wrong before you can continue
- **Brier scoring** tracks your calibration across all commitments and habits
- **Integrations**: Fatebook (forecasting), Apple Reminders, Streaks (habits), Obsidian (daily notes)
- **Auto-restart**: launchd keeps the app alive, you can't escape it

## Screenshot

The menu bar shows your next task with a live countdown. The popover shows everything in a unified timeline sorted by time: TODAY (active + failed), UPCOMING, PAST 24H, and LONG TERM GOALS.

## Requirements

- macOS 14+
- Swift 5.9+ (Command Line Tools, no Xcode required)

## Install

```bash
git clone <repo-url>
cd committed

# Create your .env file (not tracked by git)
cp .env.example .env
# Edit .env with your values

# Build and install
chmod +x build.sh
./build.sh
```

## Configuration

Create a `.env` file in the project root:

```
FATEBOOK_API_KEY=your_api_key_here
OBSIDIAN_VAULT_PATH=/path/to/your/obsidian/vault
```

### Fatebook (optional)
1. Go to [fatebook.io/api-setup](https://fatebook.io/api-setup)
2. Sign in and copy your API key
3. Set `FATEBOOK_API_KEY` in `.env`
4. Commitments will auto-create Fatebook predictions

### Obsidian (optional)
1. Set `OBSIDIAN_VAULT_PATH` to your vault directory
2. Pre-mortems and post-mortems get written to daily notes in `Daily Notes/YYYY-MM-DD.md`
3. You can also create a `commitments.md` file with the format:
   ```
   - [ ] Task name | 2026-04-15
   - [x] Done task | 2026-04-01
   ```

### Apple Reminders
- Automatically enabled
- The app will request Reminders access on first launch
- Creating a commitment also creates an Apple Reminder with the deadline

### Streaks (optional)
- The app reads from `~/Library/Application Support/Committed/streaks-cache.json`
- Create this file with your habits and target times:
  ```json
  [
    {"title": "Morning Meditation", "currentStreak": 0, "bestStreak": 0, "status": "N", "targetTime": "08:00"},
    {"title": "Workout", "currentStreak": 0, "bestStreak": 0, "status": "N", "targetTime": "17:00"}
  ]
  ```
- Habits past their target time without completion are auto-failed and force a post-mortem

### Long Term Goals
- Edit `IntegrationManager.swift` to add your Fatebook question IDs for long-term goals
- They appear at the bottom of the popover with current probabilities

## Keep alive

To make the app auto-restart and launch at login:

```bash
cat > ~/Library/LaunchAgents/com.committed.app.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.committed.app</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Applications/Committed.app/Contents/MacOS/Committed</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>ThrottleInterval</key>
    <integer>5</integer>
</dict>
</plist>
EOF

launchctl load ~/Library/LaunchAgents/com.committed.app.plist
```

To stop: `launchctl unload ~/Library/LaunchAgents/com.committed.app.plist`

## Data storage

- Commitments, pre/post mortems: `~/Library/Application Support/Committed/commitments.json`
- Streaks cache: `~/Library/Application Support/Committed/streaks-cache.json`
- Post-mortem tracking: `UserDefaults` (prevents duplicate overlays on restart)

## Architecture

See `docs/architecture.md` for full details.
