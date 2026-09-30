# Development Guide & Implementation Plan — STAHP IT!
**A Native macOS Task-Based Stopwatch, Menu Bar Utility, and Floating HUD**

---

## 1. Project Overview & Vision

**STAHP IT!** is a high-precision, distraction-free macOS task timer and stopwatch designed for developers, designers, and power users. It allows users to track billable or focused task time with zero friction through two primary lightweight interfaces:
1. **Menu Bar Status Item & Popover**: Compact, live-ticking status bar with quick actions.
2. **Floating Overlay HUD (PiP)**: A draggable, frosted-glass (Liquid Material) always-on-top pill that floats across all macOS spaces and full-screen apps without stealing keyboard focus.
3. **Session & History Manager**: Complete timeline of recorded task sessions with tagging, notes, and CSV/Markdown export capabilities.

---

## 2. User Journey & App Workflow

```
                   ┌──────────────────────────────────────────────┐
                   │             Launch STAHP IT!                 │
                   │ (Appears in Menu Bar & Optional Floating HUD)│
                   └──────────────────────┬───────────────────────┘
                                          │
                                          ▼
     ┌────────────────────────────────────────────────────────────────────────┐
     │                             Active Mode                                │
     │                                                                        │
     │  ┌───────────────────────────┐          ┌───────────────────────────┐  │
     │  │      Menu Bar Popover     │          │    Floating HUD Pill      │  │
     │  │  - Select or create task  │ ◄──────► │  - Glance live timer      │  │
     │  │  - Quick Play / Pause     │ (Synced) │  - Hover: Play/Pause/Done │  │
     │  │  - View today's summary   │          │  - Drag to reposition     │  │
     │  │  - Toggle Overlay         │          │  - Minimize or Lock       │  │
     │  └───────────────────────────┘          └───────────────────────────┘  │
     └────────────────────────────────────┬───────────────────────────────────┘
                                          │
                        Stop / Finish Session Triggered
                                          │
                                          ▼
     ┌────────────────────────────────────────────────────────────────────────┐
     │                       Session Completion Modal                         │
     │  - Review elapsed duration & task tag                                  │
     │  - Add optional session notes / tags                                   │
     │  - Save session to persistent storage or discard                       │
     └────────────────────────────────────┬───────────────────────────────────┘
                                          │
                                          ▼
     ┌────────────────────────────────────────────────────────────────────────┐
     │                      History & Export Dashboard                        │
     │  - Daily / Weekly time breakdowns by task                              │
     │  - Edit / Delete historical session logs                               │
     │  - Export logs to CSV / JSON / Markdown worklog (Linear/Jira/Slack)    │
     └────────────────────────────────────────────────────────────────────────┘
```

### Detailed Workflow States:
1. **Quick Start**:
   - User clicks Menu Bar icon or uses global hotkey (`⌥ ⇧ Space`).
   - If no task is selected, timer starts with default task (e.g. *"General Work"*) or prompts for quick task name entry.
2. **Focus / Floating Overlay**:
   - Floating HUD pill docks to screen corner with ultra-thin frosted glass effect.
   - When active, displays task color indicator, task title, and monospaced ticking timer.
   - Controls reveal on hover: `Pause/Resume`, `Finish Task`, `Cycle Task`, `Snap/Dock`.
   - Supports "Click-Through / Lock" mode for unobtrusive ambient time awareness.
3. **Task Switching**:
   - One-click task switching: stops and saves current task segment, immediately begins tracking the new task.
4. **Completion & Archival**:
   - On completion, session is committed to local storage with start/end timestamps and duration.

---

## 3. Architecture & Technical Specifications

### Tech Stack
- **Language**: Swift 6
- **UI Frameworks**: SwiftUI + AppKit (`NSPanel`, `NSStatusItem`, `NSApplicationPresentationOptions`)
- **Persistence**: Lightweight JSON File Store / SwiftData with Codable models
- **Target OS**: macOS 14.0+ (Sonoma, Sequoia and newer)

### Core Modules

```
STAHP IT!/
├── Package.swift / Project Settings
├── Sources/
│   ├── App/
│   │   ├── StahpItApp.swift          // App lifecycle, menu bar & window coordinators
│   │   ├── AppState.swift            // Central observable view-model / coordinator
│   │   └── HotkeyManager.swift       // Global keyboard shortcuts (Carbon / NSEvent)
│   ├── Engine/
│   │   ├── StopwatchEngine.swift     // Drift-proof reference timestamp timer engine
│   │   └── TimeFormatter.swift       // Monospaced and human-readable time formatters
│   ├── Models/
│   │   ├── TaskItem.swift            // Task model (id, name, color, icon, target)
│   │   └── TimeSession.swift         // Session model (id, taskId, start, end, duration, notes)
│   ├── Storage/
│   │   ├── StorageManager.swift      // Persistence manager with auto-save
│   │   └── Exporters.swift           // CSV & Markdown export generators
│   └── Views/
│       ├── MenuBar/
│       │   ├── MenuBarView.swift     // Popover content (active controls, quick task list)
│       │   └── MenuBarStatusView.swift// Dynamic status bar title & icon
│       ├── Overlay/
│       │   ├── OverlayPanel.swift    // Specialized NSPanel (floating, non-activating)
│       │   └── OverlayHUDView.swift  // Frosted glass interactive pill UI
│       └── Dashboard/
│           ├── HistoryView.swift     // Historical sessions & time breakdown
│           ├── TaskManagerView.swift // Task creator, color picker, targets
│           └── SettingsView.swift    // Display preferences, hotkeys, startup settings
```

---

## 4. Key Implementation Nuances

### 1. Drift-Proof Timing Engine
To prevent timer freeze/drift during background throttling, sleep, or intensive CPU spikes:
- Use reference timestamp calculation:
  $$\text{Elapsed} = \text{Date.now.timeIntervalSince}(\text{startTime}) + \text{accumulatedDuration}$$
- UI ticker scheduled via `Timer.publish(every: 0.05, on: .main, in: .common)` so menu bar and overlay update smoothly without lag when interacting with menus.

### 2. Floating Overlay (`NSPanel`) Configuration
- `styleMask: [.borderless, .nonactivatingPanel]` (prevents taking focus away from user's active editor/terminal).
- `level: .floating` or `.statusBar` (stays above standard application windows).
- `collectionBehavior: [.canJoinAllSpaces, .fullScreenAuxiliary]` (remains visible across virtual desktops and full-screen apps).
- `isMovableByWindowBackground = true` (draggable anywhere on the pill).
- `backgroundColor = .clear` with SwiftUI `.background(.ultraThinMaterial)`.

### 3. Agent Mode Configuration
- `LSUIElement = true` configured in `Info.plist` so the app runs natively as a lightweight Menu Bar status utility with no clutter in the macOS Dock or `⌘ Tab` switcher (with toggleable option in settings).

---

## 5. Step-by-Step Implementation Plan

### Phase 1: Foundation & Data Layer
- [ ] Initialize Swift Package / macOS App structure.
- [ ] Implement `TaskItem` and `TimeSession` models with Codable support.
- [ ] Implement `StorageManager` with robust local JSON persistence and default starter tasks.
- [ ] Implement `StopwatchEngine` with drift-proof reference timing, state transitions (`idle`, `running`, `paused`), and lap/session recording.

### Phase 2: Menu Bar Integration
- [ ] Implement `NSStatusItem` / `MenuBarExtra` with dynamic live ticking digits.
- [ ] Create `MenuBarView` popover with active task display, start/pause/stop buttons, task switcher, and quick-add task field.
- [ ] Add compact mode (icon-only or time-only) for notch/crowded menu bars.

### Phase 3: Floating HUD Overlay
- [ ] Implement `OverlayPanel` (`NSPanel` subclass configured for floating HUD behavior).
- [ ] Build `OverlayHUDView` with Liquid Material (ultra-thin glass), drag handle, monospaced timer, and hover action controls.
- [ ] Implement HUD modes: Standard Pill, Expanded Controls, and Locked / Click-Through mode.
- [ ] Add smooth show/hide transitions and position persistence.

### Phase 4: Session History & Task Management
- [ ] Build `HistoryView` displaying logged sessions grouped by day/task.
- [ ] Add Session Note editing and session deletion.
- [ ] Implement export feature: Export to CSV and formatted Markdown worklog.
- [ ] Build `TaskManagerView` to create, edit, color-code, and archive tasks.

### Phase 5: Global Shortcuts & Polish
- [ ] Implement global hotkeys (`⌥ ⇧ Space` to toggle timer, `⌥ ⇧ O` to toggle overlay).
- [ ] Add haptic/audio cues on start, pause, and milestone completion.
- [ ] Polish animations, color palette, dark/light mode responsiveness, and verify builds.

---

## 6. Verification & Acceptance Criteria
1. **Timing Accuracy**: Timer matches wall-clock time across system sleep and wake cycles.
2. **Menu Bar Responsiveness**: Popover opens immediately with smooth live seconds update.
3. **Overlay Behavior**: Draggable across monitors and spaces; remains on top without stealing keyboard focus.
4. **Data Integrity**: All task sessions persist across app restarts and export cleanly to CSV/Markdown.
