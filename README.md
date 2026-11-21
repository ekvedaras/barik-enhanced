# Barik Enhanced

[![Version](https://img.shields.io/badge/version-1.9.1-blue.svg)](https://github.com/MateoCerquetella/barik-enhanced/releases/tag/v1.9.1)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-14.0%2B-black.svg)](https://github.com/MateoCerquetella/barik-enhanced)

A custom, fully configurable menu bar for macOS. Built on top of [Barik](https://github.com/mocki-toki/barik) with new widgets, drag-and-drop configuration, performance optimizations, and more.

![Menu Bar](resources/screenshots/menubar-full.png)

## Features

### Drag & Drop Widget Configurator
Right-click the menu bar or click the gear icon to open the visual configurator. Drag widgets from the available panel to the active list, reorder them, or remove them. Changes apply instantly.

![Widget Configurator](resources/screenshots/configurator.png)

### 20+ Widgets

| Widget | Description |
|--------|-------------|
| **Spaces** | Window manager integration (yabai/AeroSpace/OmniWM) |
| **Now Playing** | Current song with album art (Spotify/Apple Music) |
| **Weather** | Live temperature and forecast via Open-Meteo (no API key) |
| **CPU & RAM** | System resource usage with color-coded alerts |
| **Network Activity** | Upload/download speed |
| **Volume** | Audio control with interactive slider popup |
| **Microphone** | Mic mute/unmute toggle |
| **Brightness** | Screen brightness control |
| **Battery** | Battery level with charging status |
| **Network** | WiFi/Ethernet connection status |
| **WireGuard** | macOS tunnel state with gateway and peer ICMP probes |
| **Syncthing** | Folder sync state, transfer progress, and process RAM |
| **Time** | Date, time, and calendar popup |
| **Meetings** | Current/next Meet, Zoom, or Teams call with one-click join |
| **Claude Usage** | Claude API rate limit tracking with configurable alert thresholds |
| **Codex Usage** | OpenAI Codex usage monitoring with configurable alert thresholds |
| **Pomodoro** | Focus timer with work/break cycles |
| **Disk Usage** | Storage monitor with capacity bar |
| **Uptime** | System uptime display |
| **Do Not Disturb** | macOS Focus mode toggle |
| **Countdown** | Days until a target date |
| **Keyboard Layout** | Current input source indicator |
| **Performance Mode** | System performance profile selector |

### Widget Popups

<p float="left">
  <img src="resources/screenshots/weather.png" width="280" />
  <img src="resources/screenshots/volume.png" width="280" />
  <img src="resources/screenshots/claude-usage.png" width="280" />
</p>

### Settings Menu
Click the gear icon at the end of the bar to access:
- **Configure Widgets** — open the drag & drop configurator
- **Launch at Login** — start Barik Enhanced on boot
- **About** — credits and version info
- **Quit** — close the app

## This fork

This fork adds shell-script widgets and a CLI to Barik Enhanced, and builds without Xcode (`scripts/build-app.sh`, SwiftPM only). Releases attach a ready-built `Barik.zip` (bundle id `com.ekvedaras.Barik`). Do not use the in-app update button: it installs upstream over the fork.

### Script widgets

Any `script.<name>` id in `displayed` runs a command and draws the JSON it prints.

```toml
[widgets]
displayed = ["default.spaces", "spacer", "script.uptime", "default.time"]

[widgets.script.uptime]
command = "~/.config/barik/scripts/uptime.sh"
mode = "poll"          # poll: run every `interval` seconds; stream: one JSON document per output line
interval = 60          # 0 = only at start and on events
events = ["uptime_change", "system_woke"]   # `barik trigger <event>` re-runs it

[script]
path = "/opt/homebrew/bin:/usr/bin:/bin"    # PATH for every script
```

```sh
#!/bin/sh
# ~/.config/barik/scripts/uptime.sh
up=$(uptime | sed -E 's/.*up ([^,]*),.*/\1/')
printf '{"items":[{"id":"up","icon":"sf:clock","label":"%s","color":"green","click":"open -b com.apple.ActivityMonitor"}]}\n' "$up"
```

Item fields: `id`, `icon` (`sf:<symbol>`, `app:<bundle id>`, `file:<path>`, `text:<chars>`), `label`, `color` (`accent`, `red`, ..., `#rrggbb`), `style` (`pill`/`plain`), `outline`, `joined`, `animation` (`none`/`pulse`/`shake`/`spin`), `tooltip`, `click`, `right_click`, `popup` (rows of `icon`, `label`, `color`, `click`). `{"items":[]}` shows nothing. A widget table with `space = "<workspace>"` draws its items inside that workspace's pill in the Spaces widget.

### CLI

```sh
scripts/barik trigger <event>   # re-run scripts listening to <event>
scripts/barik reload            # reload the config
scripts/barik zen [on|off]      # toggle zen mode (no argument toggles)
```

The wrapper runs `Barik.app/Contents/MacOS/Barik`; `BARIK_APP` points it at another app path.

### Zen mode

```toml
[zen]
hide = ["default.cpuram", "script.uptime"]

[zen.widgets.default.time]   # merged over [widgets.default.time] while zen is on
format = "HH:mm"
```

Toggle with `barik zen`, a right click on the clock, or "Zen Mode" in the bar's context menu. The state survives restarts.

### Overflow

When the left section runs into the right one, script items that do not fit hide behind a `+N` pill; clicking it lists them in a popup.

### Smaller changes

- `default.spaces`: `space.order = ["A", "B"]` (listed first, rest alphabetical) and `space.show-empty = true` (AeroSpace).
- `default.time`: `calendar.events-inline = true` puts the next event left of the clock; it turns accent 5 min before start.
- `notch`: a spacer as wide as the screen's notch.
- Spaces, volume and keyboard layout update on system notifications instead of polling.
- Config writes follow a symlinked config file (stow, home-manager); the watcher survives the file being replaced.
- Logs go to `~/Library/Logs/Barik/barik.log`.

## Installation

### Homebrew (Recommended)
```bash
brew tap MateoCerquetella/barik-enhanced
brew install --cask barik-enhanced
```

### From Source
```bash
git clone https://github.com/MateoCerquetella/barik-enhanced.git
cd barik-enhanced
open BarikEnhanced.xcodeproj
```
Build and run with Xcode (Cmd+R).

### Requirements
- macOS 14.0+
- Xcode 15+
- A window manager like [AeroSpace](https://github.com/nikitabobko/AeroSpace), [yabai](https://github.com/koekeishiya/yabai) or OmniWM (optional, for Spaces widget)

## Configuration

Barik Enhanced uses a TOML config file at `~/.barik-config.toml`. Edit it manually or use the built-in widget configurator.

### Example Configuration
```toml
theme = "system" # system, light, dark

[widgets]
displayed = [
    "default.spaces",
    "spacer",
    "default.nowplaying",
    "default.weather",
    "default.cpuram",
    "default.networkactivity",
    "divider",
    "default.volume",
    "default.microphone",
    "default.network",
    "default.wireguard",
    "default.syncthing",
    "default.battery",
    "default.meetings",
    "default.time"
]

[widgets.default.spaces]
space.show-key = true
window.show-title = true
window.title.max-length = 50

[widgets.default.battery]
show-percentage = true
warning-level = 30
critical-level = 10

[widgets.default.time]
format = "E d, J:mm"
calendar.format = "J:mm"
calendar.show-events = false

[widgets.default.meetings]
title-max-length = 32 # compact title characters (8-80)

[widgets.default.clipboard]
max-items = 10              # in-memory entries (1-20)
preview-max-length = 40     # compact preview characters (8-120)

[widgets.default.wireguard]
# Legacy single-profile form. Replace these TEST-NET values with your VPN details.
tunnel-name = "Example WireGuard"
gateway = "192.0.2.1"
refresh-interval = 30 # seconds (clamped to 10-600)
peers = ["Example Router=198.51.100.10", "Example Node=203.0.113.20"]
# Optional multi-profile form. When present, the connected profile is selected automatically.
profiles = [
  { name = "Primary", tunnel-name = "Example Primary", gateway = "192.0.2.1", peers = ["Router=198.51.100.10"] },
  { name = "Backup", tunnel-name = "Example Backup", gateway = "203.0.113.1", peers = ["Phone=203.0.113.20"] },
]

[widgets.default.syncthing]
api-url = "http://127.0.0.1:8384"
api-key = "" # Syncthing Settings > GUI > API Key
folder-id = "developer"
local-name = "Saturn"
peer-name = "Jupiter"
# peer-device-id = "" # optional; use when peer-name is ambiguous
refresh-interval = 15

[widgets.default.cpuram]
show-icon = false
cpu-warning-level = 70
cpu-critical-level = 90
ram-warning-level = 70
ram-critical-level = 90

[widgets.default.claude-usage]
warning-threshold = 60
critical-threshold = 80

[widgets.default.codex-usage]
warning-threshold = 60
critical-threshold = 80

[widgets.default.pomodoro]
work-duration = 25       # minutes
short-break = 5
long-break = 15
pomodoros-before-long-break = 4
```

### Available Widget IDs
```
default.spaces          default.nowplaying      default.weather
default.cpuram          default.networkactivity  default.volume
default.microphone      default.brightness      default.network
default.wireguard       default.syncthing       default.battery
default.time
default.meetings        default.clipboard       default.dnd
default.disk            default.uptime          default.pomodoro
default.performance     default.keyboardlayout  default.claude-usage
default.codex-usage     default.countdown       spacer
divider
```

The WireGuard widget reads every configured macOS tunnel state, follows the first
connected profile, and can connect, disconnect, or switch profiles from its popup.
Switching stops other configured tunnels and waits for disconnection before
starting the selected profile. The compact label shows only UP, OFF, PROBE, or
CHECK; profile names remain in the popup and tooltip. It runs
lightweight ICMP reachability probes only for the connected profile's gateway and
peers. Probe results are diagnostic only; they are
not authoritative WireGuard or RouterOS handshake data. Existing configurations
without `profiles` continue to operate as one legacy profile. Each `tunnel-name`
must match the macOS service name shown by `scutil --nc list`, so a tunnel
renamed in the WireGuard app needs the matching name here before its state can
be reported.

The Syncthing widget reads the configured node's REST API. It shows the selected
folder's completion against the named peer and the queried Syncthing process's
reported RAM. Keep the API bound to localhost and use a secure tunnel when Barik
runs on another machine. Protect the config file because it contains the API
key. A peer's RAM requires querying that peer's own API.

## Performance

Barik Enhanced is optimized for minimal resource usage:
- All widget managers use the singleton pattern (one timer per manager)
- Change detection prevents unnecessary SwiftUI redraws
- Background thread polling for system metrics
- Debounced config file watching
- Runs as a daemon (no Dock icon)

## Credits

Built by [Mateo Cerquetella](https://github.com/MateoCerquetella)

Based on [Barik](https://github.com/mocki-toki/barik) by [mocki-toki](https://github.com/mocki-toki)

## License

[MIT](LICENSE)
