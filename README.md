# FocusApp

A minimal Pomodoro timer for macOS, built with SwiftUI.

## Features

- **Adjustable timers** — set focus, short break, and long break durations directly on the main screen
- **Auto-advance** — sessions chain automatically through the full cycle; stops after the long break
- **Sound effect** — plays on every session completion with adjustable volume
- **Streaks** — tracks consecutive days you've studied
- **Stats** — bar chart of your last 7 days and totals for sessions, focus time, and today's minutes
- **Notifications** — system alert when a session completes, even if the app is in the background

## Requirements

- macOS 14.0 or later
- Xcode 15 or later

## Getting Started

1. Clone the repo
2. Open `FocusApp.xcodeproj` in Xcode
3. Press **Cmd+R** to build and run

No dependencies to install.

## How It Works

The default Pomodoro cycle:

```
Focus (25 min) → Short Break (5 min) → Focus → Short Break → Focus → Short Break → Focus → Long Break (15 min)
```

After the long break the timer stops. Press play to start a new cycle.

All durations and the number of sessions before a long break are adjustable from the timer screen before you start.

## Project Structure

```
FocusApp/
├── App/            # Entry point and SwiftData container setup
├── Models/         # FocusSession (SwiftData), SessionType enum
├── ViewModels/     # TimerViewModel (state machine), StatsViewModel
├── Views/          # Timer, Stats, and Settings screens
├── Services/       # Notifications and sound playback
└── Utilities/      # Colors, formatters, UserDefaults keys
```

See [CLAUDE.md](CLAUDE.md) for full architecture notes.

## License

MIT
