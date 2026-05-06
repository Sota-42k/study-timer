# FocusApp

macOS Pomodoro timer app built with SwiftUI + SwiftData + Swift Charts.

## Requirements

- Xcode 15+ (Swift 5, macOS 14.0 deployment target)
- No third-party dependencies

## Build

Open `FocusApp.xcodeproj` in Xcode and press **Cmd+R**, or from the command line:

```bash
xcodebuild -project FocusApp.xcodeproj -scheme FocusApp -destination "platform=macOS" -configuration Debug build
```

## Project Structure

```
FocusApp/
├── App/
│   └── FocusAppApp.swift          # @main entry, ModelContainer, window config
├── Models/
│   ├── FocusSession.swift         # SwiftData @Model — persisted only on completion
│   └── SessionType.swift          # enum: focus | shortBreak | longBreak
├── ViewModels/
│   ├── TimerViewModel.swift        # Timer state machine (idle/running/paused/completed)
│   └── StatsViewModel.swift        # Computed stats over session data
├── Views/
│   ├── ContentView.swift           # NavigationSplitView root (Timer / Stats / Settings)
│   ├── Timer/
│   │   ├── TimerView.swift         # Main screen: ring, controls, idle settings panel
│   │   ├── CircularProgressRing.swift
│   │   └── LapListView.swift
│   ├── Stats/
│   │   ├── StatsView.swift
│   │   ├── DailyBarChart.swift     # Swift Charts — last 7 days bar chart
│   │   └── StatSummaryRow.swift
│   └── Settings/
│       └── SettingsView.swift
├── Services/
│   ├── NotificationService.swift   # UNUserNotificationCenter + AVAudioPlayer
│   └── StreakService.swift         # Pure streak calculation functions
├── Utilities/
│   ├── ColorTheme.swift            # All app colors (light mode)
│   ├── Formatters.swift            # formatSeconds(), formatDuration()
│   └── UserDefaultsKeys.swift      # Centralized @AppStorage key constants
└── timer.wav                       # Completion sound (played via AVAudioPlayer)
```

## Architecture

### Timer State Machine (`TimerViewModel`)

```
idle → start() → running(.focus)
running → pause() → paused
running → tick reaches 0 → completed  [saves FocusSession, plays sound, auto-advances after 1.5s]
running → reset() → idle              [no save]
paused  → resume() → running
paused  → reset() → idle
completed → next() → running(nextType)
completed → reset() → idle
```

Auto-advance stops after `.longBreak` — that is the end of one full cycle.

### Data Persistence

- **SwiftData** stores `FocusSession` records (focus sessions only; breaks are not persisted).
- **UserDefaults** (via `@AppStorage`) stores timer durations, cycle length, sound volume, and notification toggle.
- The SwiftData store lives at `~/Library/Application Support/com.sotafujii.focusapp/`.

### Key Behaviours

- Sessions are only saved on **natural completion** — reset and skip do not write to the store.
- Timer durations are read from UserDefaults at session **start time**, so changing them mid-session takes effect next session.
- Sound volume is read from UserDefaults at **play time**, so the slider takes effect immediately.
- `StreakService` is pure functions with no side effects — easy to unit test.

## UserDefaults Keys

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `focusDuration` | Double | 1500 | Focus session length in seconds |
| `shortBreakDuration` | Double | 300 | Short break length in seconds |
| `longBreakDuration` | Double | 900 | Long break length in seconds |
| `sessionsBeforeLong` | Int | 4 | Focus sessions per cycle |
| `soundVolume` | Double | 1.0 | Sound effect volume (0.0–1.0) |
| `notificationsEnabled` | Bool | true | System notification toggle |

## iOS Scaling Notes

The architecture is cross-platform-ready:
- `TimerViewModel`, `StatsViewModel`, `StreakService`, and all models are platform-agnostic.
- `ContentView` uses `#if os(macOS)` to switch between `NavigationSplitView` (macOS) and `TabView` (iOS) — currently only the macOS branch is implemented.
- `NotificationService` uses `UNUserNotificationCenter` which is identical on iOS.
- To add iOS: create a new Xcode target pointing at the same source files; exclude `AppDelegate.swift`.
