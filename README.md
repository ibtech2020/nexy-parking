# Park Master 🚗
### A Cross-Platform 3D Car Parking Simulation — Flutter + Flame Engine

---

## 📋 Project Overview

Park Master is a full-featured realistic car parking simulator built with Flutter and Flame Engine. It features gesture-based controls, a realistic physics engine, 10 hand-crafted levels, multiple vehicles, and a polished dark neon UI.

---

## 🏗️ Architecture

```
lib/
├── main.dart                     # App entry, Hive init, orientation lock
├── core/
│   ├── app_theme.dart            # Dark neon theme, colors, typography
│   ├── app_router.dart           # GoRouter navigation
│   └── tilt_controller.dart      # Gyroscope steering input
├── game/
│   ├── park_master_game.dart     # Main Flame game (world, camera, loop)
│   ├── car_physics.dart          # Physics engine (Ackermann steering, drag, RPM)
│   ├── level_data.dart           # All 10 level configs (walls, cones, spots)
│   └── components/
│       ├── car_component.dart        # Car rendering + collision hitbox
│       ├── wall_component.dart       # Wall, cone, parking zone, environment
│       ├── particle_system.dart      # Exhaust, skid, impact, celebration particles
│       └── minimap_component.dart    # In-world minimap (screen-space viewport)
├── screens/
│   ├── splash_screen.dart        # Animated boot screen
│   ├── main_menu_screen.dart     # Animated main menu with grid background
│   ├── level_select_screen.dart  # Level grid with stars + difficulty
│   ├── game_screen.dart          # Full game: Flame + Flutter HUD overlay
│   ├── garage_screen.dart        # Car/color/upgrade selection
│   ├── settings_screen.dart      # Audio, graphics, controls config
│   └── leaderboard_screen.dart   # Global + personal scores
├── widgets/
│   ├── steering_wheel_widget.dart # Circular drag-gesture steering wheel
│   ├── pedal_widget.dart          # Gas / brake press-and-hold pedals
│   ├── gear_selector_widget.dart  # P/R/N/D gear tabs
│   ├── hud_overlay.dart           # Speedometer, RPM, timer bar, camera toggle
│   └── result_overlay.dart        # Animated win/lose screen with stars
├── audio/
│   └── audio_service.dart        # Engine RPM audio, SFX, looping music
└── models/
    ├── player_progress.dart       # Hive model: scores, stars, unlocks, coins
    └── car_config.dart            # Hive model: car ownership, upgrades, color
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| UI Framework | Flutter 3.x |
| Game Engine | Flame 1.18 (2D rendering, world, camera, collision) |
| Physics | Custom Ackermann steering model in `car_physics.dart` |
| State Management | Riverpod 2.x |
| Navigation | GoRouter |
| Persistence | Hive (local) |
| Audio | audioplayers + flame_audio |
| Haptics | vibration |
| Sensors | sensors_plus (gyroscope tilt) |
| Animations | flutter_animate |
| Fonts | Google Fonts (Rajdhani) |

---

## 🚀 Setup & Run

### Prerequisites
- Flutter SDK ≥ 3.0.0
- Dart SDK ≥ 3.0.0
- Android Studio or Xcode
- A physical device recommended for gyroscope testing

### Install dependencies
```bash
cd park_master
flutter pub get
```

### Generate Hive adapters
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Run on device
```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# With release optimizations (recommended for gameplay)
flutter run --release
```

### Build APK
```bash
flutter build apk --release --split-per-abi
```

### Build iOS IPA
```bash
flutter build ipa --release
```

---

## 🎮 Controls

| Control | Gesture |
|---------|---------|
| Steering | Drag the circular wheel left/right |
| Gas | Hold the GAS pedal button |
| Brake / Reverse | Hold BRAKE; in R gear = reverse |
| Gear shift | Tap P / R / N / D buttons |
| Tilt steering | Enable in Settings → tilt device |
| Camera | Tap CAM button to cycle Follow/Top/Driver |
| Pause | Tap PAUSE button |

---

## 🎯 Game Modes

| Mode | Description |
|------|-------------|
| Career | 10 levels, increasing difficulty, locked progression |
| Garage | Choose & customize your car |
| Leaderboard | Compare scores globally |
| Free Drive | (Future) Open world exploration |
| Multiplayer | (Future) Real-time competitive parking |

---

## 🚗 Vehicles

| Car | Speed | Handling | Unlock |
|-----|-------|----------|--------|
| City Sedan | ★★★☆☆ | ★★★★☆ | Default |
| Urban SUV | ★★☆☆☆ | ★★★☆☆ | Level 3 |
| Turbo GT | ★★★★★ | ★★☆☆☆ | Level 6 |
| Pickup XL | ★★☆☆☆ | ★★★★★ | Level 9 |

---

## 🌍 Level Guide

| # | Name | Environment | Difficulty |
|---|------|-------------|------------|
| 1 | Intro Run | Open Lot | ⭐ |
| 2 | Parking Lot A | Bay Parking | ⭐ |
| 3 | Underground | Garage Columns | ⭐⭐ |
| 4 | Tight Alley | Narrow Corridor | ⭐⭐⭐ |
| 5 | Urban Chaos | City Maze | ⭐⭐⭐ |
| 6 | Obstacle Run | Cone Slalom | ⭐⭐⭐⭐ |
| 7 | SUV Challenge | Garage (SUV) | ⭐⭐⭐⭐ |
| 8 | Night Shift | Dark Garage | ⭐⭐⭐⭐ |
| 9 | Turbo Sprint | Sports Car Urban | ⭐⭐⭐⭐⭐ |
| 10 | Master Class | Expert Night | ⭐⭐⭐⭐⭐ |

---

## ⚡ Physics System

The `CarPhysics` class implements a simplified Ackermann steering model:

- **Ackermann steering**: Turn radius computed from wheelbase and steer angle
- **Engine force**: Proportional to throttle × max power, reduced by damage
- **Air drag**: Quadratic with speed (F = 0.5·Cd·v²)
- **Rolling resistance**: Linear friction constant per car spec
- **Drift**: At high speed + high steer, lateral grip reduces (drift factor)
- **Damage levels**: None → Light → Moderate → Severe (reduces max speed + power)
- **RPM simulation**: Linear model for audio feedback

---

## 🔊 Audio Assets Required

Place these in `assets/audio/`:
```
engine_idle.mp3       # Looping engine at idle RPM
skid.mp3              # Tire screech
collision_hard.mp3    # Hard impact
collision_soft.mp3    # Soft bump
cone_hit.mp3          # Cone knock
park_success.mp3      # Victory chime
gear_shift.mp3        # Gear click
countdown.mp3         # 3-2-1 beep
music_menu.mp3        # Menu background
music_game.mp3        # In-game background
```

---

## 🎨 Design System

Colors:
- **Neon Cyan** `#00FFC8` — primary, acceleration, success
- **Neon Orange** `#FF8C00` — secondary, gear, score
- **Neon Red** `#FF3C3C` — danger, brake, damage
- **Dark BG** `#0A0A0F` — base background
- **Dark Card** `#1A1A28` — panels and cards

---

## 🔮 Future Roadmap

- [ ] AI traffic (pathfinding with A*)
- [ ] Weather effects (rain particles, wet road friction)
- [ ] Real-time multiplayer (WebSocket + Firebase)
- [ ] Replay system (record inputs, play back)
- [ ] More vehicles (bus, motorbike, truck)
- [ ] Daily challenges with global leaderboard
- [ ] Unity bridge integration for full 3D rendering

---

## 📄 License

This project is original work. All code, level designs, game mechanics, and UI are custom-built. No third-party game content has been reproduced.
