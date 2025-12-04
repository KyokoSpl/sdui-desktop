# SDUI Desktop

A cross-platform desktop client for SDUI (school timetable system) built with Qt6/QML.

## Requirements

- **Qt 6.5+** with the following modules:
  - Qt Quick
  - Qt Quick Controls 2
  - Qt Network
- **CMake 3.16+**
- **C++17 compatible compiler** (GCC 9+, Clang 10+)

## Installing Dependencies

### Fedora (dnf)

```bash
# Install Qt6 development packages
sudo dnf install qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtquickcontrols2-devel

# Install build tools
sudo dnf install cmake gcc-c++ ninja-build

# Optional: Qt Creator IDE
sudo dnf install qt-creator
```

### Arch Linux (pacman)

```bash
# Install Qt6 packages
sudo pacman -S qt6-base qt6-declarative qt6-quickcontrols2

# Install build tools
sudo pacman -S cmake gcc ninja

# Optional: Qt Creator IDE
sudo pacman -S qtcreator
```

### Ubuntu/Debian (apt)

```bash
sudo apt install qt6-base-dev qt6-declarative-dev libqt6quick3d6 \
    qt6-quickcontrols2-dev cmake g++ ninja-build
```

### Qt Online Installer (Alternative)

If your distro has outdated Qt packages, download from https://www.qt.io/download-qt-installer

## Building

```bash
# Create build directory
mkdir build && cd build

# Configure with CMake
cmake ..

# Build
cmake --build . --parallel

# Run
./SduiDesktop
```

## Features

- **Modern Material Dark Theme** - Built-in dark mode with SDUI orange accent
- **Cross-Platform** - Works on Linux, Windows, and macOS
- **Smooth Animations** - QML provides 60fps UI transitions
- **Login System** - Authenticate with your SDUI account
- **Timetable Views**:
  - Day view
  - Work week (5 days)
  - Full week (7 days)
- **Lesson Details** - Click any lesson for full info
- **Status Indicators** - Cancelled, substitution, room changes
- **Settings** - Persistent preferences

## Architecture

```
src/
├── main.cpp              # Application entry point
├── sduiapiclient.h/cpp   # SDUI API communication
├── timetablemodel.h/cpp  # Data model for lessons
└── settingsmanager.h/cpp # Persistent settings

qml/
├── Main.qml              # Main window with navigation
├── LoginPage.qml         # Login screen
├── TimetablePage.qml     # Timetable display
├── SettingsPage.qml      # Settings screen
└── components/
    ├── GlassCard.qml     # Glass-morphism card
    ├── LessonCard.qml    # Individual lesson display
    ├── FloatingControls.qml
    ├── DayHeader.qml     # Week day headers
    └── TimeColumn.qml    # Hour slot column
```

## Why Qt/QML?

| Feature | Qt/QML | wxWidgets | GTK |
|---------|--------|-----------|-----|
| Modern UI | ✅ Declarative, animations | ❌ Native widgets | ⚠️ Theme dependent |
| Cross-platform | ✅ Same look everywhere | ⚠️ Native = inconsistent | ❌ Linux focused |
| Dark mode | ✅ Built-in Material style | ❌ Manual styling | ⚠️ Theme dependent |
| Performance | ✅ GPU accelerated | ⚠️ CPU rendering | ⚠️ Varies |

Qt/QML was chosen because:
1. **Not GTK** - Qt has its own rendering engine
2. **Truly cross-platform** - Same code runs identically on Linux/Windows/Mac
3. **Modern UI** - Material Design style out of the box
4. **Dark mode** - Native support
5. **Similar to Jetpack Compose** - Easy to port Android UI patterns
