# Development Guide & Technical Specifications — STAHP IT!
**A Native macOS Task-Based Stopwatch, Menu Bar Utility, and OLED Dynamic Island HUD**

---

## 1. Project Overview & Vision

**STAHP IT!** is a high-precision, distraction-free macOS task stopwatch and Dynamic Island utility designed for developers, designers, and power users. It delivers real-time time awareness with zero friction through modular interfaces:

1. **MacBook Pro Dynamic Island Notch HUD**: Symmetrical, hardware-calibrated wings flanking the camera notch with pure `#000000` zero-nit OLED/Liquid Retina XDR true black and hover-only aurora light bloom.
2. **Magnetic Edge Snapping & Docking**: Multi-anchor docking supporting vertical edge pills (left/right display edges), horizontal docks (top/bottom), and free-floating mode with fluid `NSAnimationContext` easing.
3. **Menu Bar Status Item & Popover**: Compact status item with customizable display modes (Notch Only, Menu Bar Only, or Both).
4. **Active Frontmost Application Tracking**: Real-time awareness of active macOS applications (Xcode, Figma, Safari, etc.) paired directly with task sessions.
5. **Session Persistence & Auto-Resume**: Crash-resilient state snapshots auto-saved every 4 seconds and upon app exit/sleep, enabling automatic session resumption on launch.
6. **Session & History Manager**: Filterable history timeline with formula-injection-safe CSV and Markdown table export.

---

## 2. Architecture & Technical Specifications

### Tech Stack
- **Language**: Swift 6.0
- **UI Frameworks**: SwiftUI + AppKit (`NSPanel`, `NSStatusItem`, `NSAnimationContext`, `CAMediaTimingFunction`)
- **Graphics Engine**: CoreGraphics (`generate_icon.swift`)
- **Display Pipeline**: Apple ProMotion 60–120Hz refresh cadence
- **Persistence**: Lightweight JSON File Store with `Codable` models
- **Target OS**: macOS 14.0+ (Sonoma, Sequoia) — Apple Silicon (M1/M2/M3/M4) & Intel

---

## 3. Codebase Structure & Module Map

```
STAHP IT!/
├── Package.swift                             # Swift Package Manager manifest
├── generate_icon.swift                       # CoreGraphics programmatic macOS AppIcon generator
├── run.sh                                    # Release build, icon compilation & launch script
├── README.md                                 # User & developer documentation
├── LICENSE                                   # MIT License
└── Sources/
    ├── App/
    │   ├── StahpItApp.swift                  # Main App lifecycle & MenuBarExtra dynamic insertion
    │   ├── AppState.swift                    # Central @MainActor state coordinator & persistence
    │   └── HotkeyManager.swift               # Carbon global keyboard shortcut listener
    ├── Engine/
    │   ├── StopwatchEngine.swift             # High-precision 60-120Hz ProMotion timer engine
    │   ├── TimeFormatter.swift               # Stopwatch, vertical pill & duration string formatters
    │   └── AppleTheme.swift                  # Apple HIG design tokens, fluid springs & notch geometry
    ├── Models/
    │   ├── TaskItem.swift                    # Task category schema & color hex extensions
    │   └── TimeSession.swift                 # Historical session & active snapshot schema
    ├── Storage/
    │   └── StorageManager.swift              # JSON store, preferences schema & CSV/MD export
    └── Views/
        ├── MenuBar/
        │   └── MenuBarView.swift             # Native macOS Menu Bar status item view
        ├── Overlay/
        │   ├── OverlayPanel.swift            # AppKit NSPanel magnetic edge snapping & drag controller
        │   └── OverlayHUDView.swift          # OLED Notch Dynamic Island & Edge Dock Pills
        └── Dashboard/
            ├── SettingsView.swift            # Tabbed Settings dialog (General, Notch, Categories, Hotkeys, Data)
            ├── SettingsWindowController.swift # NSWindowController for standalone Settings window
            ├── DashboardWindowView.swift      # NavigationSplitView Dashboard container
            ├── HistoryView.swift              # Session history log & export
            ├── TaskManagerView.swift          # Category list & editor
            └── SessionCompletionSheet.swift   # Finish session notes sheet
```

---

## 4. Key Architectural Implementations

### 1. Drift-Proof 60–120Hz Timing Engine (`StopwatchEngine.swift`)
- **Reference Timestamp Calculations**: Prevents timer drift during background throttling or thread sleeps:
  $$\text{Elapsed} = \text{Date.now.timeIntervalSince}(\text{startTime}) + \text{accumulatedDuration}$$
- **ProMotion Synchronized Cadence**: UI tick publisher scheduled on the `.common` run loop mode (`Timer.publish(every: 1.0/60.0)`), maintaining fluid 60–120Hz display refresh.

### 2. OLED & Liquid Retina XDR Notch Calibration (`OverlayHUDView.swift`, `AppleTheme.swift`)
- **Zero-Nit True Black (`#000000`)**: Mini-LED local dimming zones and OLED pixels remain completely extinguished ($0$ nits) behind the notch wings, preventing gray backlight blooming against the MacBook bezel.
- **Symmetrical Responsive Geometry ($W_{\text{left}} = W_{\text{right}}$)**: Left wing terminates flush at the hardware camera housing, and the right stopwatch wing begins flush from the right boundary. Symmetrical padding expands dynamically based on content length.
- **Hover-Only Light Contour (`NotchLightContourView`)**: Ambient Apple Intelligence aurora glow contour stays completely off during tracking and only blooms with smooth rotation on mouse hover.

### 3. Magnetic Multi-Anchor Docking (`OverlayPanel.swift`)
- **`NSPanel` Configuration**: `styleMask: [.borderless, .nonactivatingPanel]`, `level: .statusBar`, and `collectionBehavior: [.canJoinAllSpaces, .fullScreenAuxiliary]`.
- **Fluid `NSAnimationContext` Easing**: Snapping between screen anchors animates with `.easeInEaseOut` timing over $0.32\text{s}$ for smooth gliding across displays.

### 4. App Presentation Location Modes (`appDisplayLocation`)
- **Notch HUD Only**: Displays the app exclusively on the MacBook Notch Dynamic Island (or magnetic screen edge dock). The top menu bar icon is removed via `MenuBarExtra(isInserted:)`.
- **Menu Bar Only**: Displays the app exclusively as a macOS top status bar item. The Notch overlay is hidden.
- **Both**: Displays the app simultaneously on both interfaces.

### 5. Automatic Session State Persistence (`ActiveSessionSnapshot`)
- **Crash & Restart Resilience**: Saves live active session snapshots every 4 seconds and upon app termination (`willTerminateNotification` / `willSleepNotification`).
- **Seamless Resume**: Relaunching the app remembers your exact elapsed time, active task category, and recorded lap splits.
- **Auto-Resume Running Timers**: If the stopwatch was actively tracking before quitting, it immediately resumes ticking on app launch.

### 6. Security & Export Defense
- **CSV Formula Injection Mitigation**: Sanitizes cell prefixes (`=`, `+`, `-`, `@`) with prepended `'` escape markers before generating CSV files.
- **Markdown Pipe Escaping**: Escapes `|` characters in task titles and notes to prevent broken Markdown tables.

---

## 5. Completed Milestones (v0.5)

- [x] High-precision 60–120Hz ProMotion stopwatch timing engine with lap recording.
- [x] Liquid Retina XDR / OLED True Black `#000000` MacBook Notch Dynamic Island with symmetrical responsive wings.
- [x] Hover-only Apple Intelligence aurora light bloom contour.
- [x] Multi-anchor magnetic edge snapping (Top Notch, Left/Right Vertical Pills, Bottom Docks, Free Float).
- [x] Exclusive App Display Location settings (Notch Only vs Menu Bar Only vs Both).
- [x] Crash-resilient session persistence and auto-resume on relaunch.
- [x] Custom task category manager with custom colors, SF Symbols, and target goals.
- [x] Frontmost active application tracking & customizable HUD display modes.
- [x] Formula-safe CSV and Markdown table session history export.
- [x] Programmatic CoreGraphics designer macOS app icon (`generate_icon.swift`).
- [x] GitHub repository setup and **v0.5** release published with binary bundle assets.

---

## 6. Build & Packaging Instructions

```bash
# Compile and launch the release bundle
chmod +x run.sh
./run.sh

# Programmatically generate AppIcon.icns
swift generate_icon.swift
iconutil -c icns AppIcon.iconset -o AppIcon.icns
```
