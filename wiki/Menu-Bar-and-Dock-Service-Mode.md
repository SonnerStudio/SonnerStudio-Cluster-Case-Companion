# Menu Bar Service Mode (`⌘⇧M`) & Modern Solaris Dock Icon

[← Back to Wiki Home](Home.md)

## 🛰️ Running SS-CCC Silently Alongside Ollama for Agents & IDEs

Once your Apple Silicon cluster is verified **Ready**, you no longer need to keep a large control window open on your desktop. SS-CCC acts as a silent local & distributed inference service in the background:

1. **Move into the Top macOS Menu Bar (`MenuBarExtra`):**
   - Click the yellow window **Minimize** button (when auto-minimize is active), click the top header **To Menu Bar** pill (`mb_btn_minimize`), or press **`⌘⇧M`**.
   - The main Studio window hides cleanly and switches the app activation policy to `.accessory`, placing SS-CCC right next to **Ollama** and system utilities in the top macOS menu bar.

2. **Live Status Popover (`SSCCCMenuBarExtraView`):**
   Clicking the SS-CCC Menu Bar item displays:
   - **Live Cluster Readiness badge** (`Ready`, `Partially Configured`, `Not Ready`, `Unconfigured`)
   - **Pooled & Usable RAM (GB)** (`iogpu.wired_limit_mb`-protected)
   - **Active Node Count** (Local + WAN peers)
   - **Active Loaded Model & Layer Split** + **Active Runtime & MMM Slots**
   - **1-Click Copy API Endpoints:** `http://127.0.0.1:8000/v1` (OpenAI / MMM) and `http://127.0.0.1:11434` (Ollama)
   - **Connected IDEs & Agents** indicator (`Cursor`, `OpenCode`, `Hermes Agent`, `Antigravity`, `VS Code`, `Xcode`)
   - **Quick Controls:** Toggle auto-minimize, verify cluster readiness, **Show / Restore Studio Window** (`⌘⇧M`), or quit.

---

## ☀️ Modern macOS Solaris Dock Application Icon

SS-CCC features a custom `1024×1024` squircle icon (`app/Resources/ssccc_app_icon.png` & `AppIcon.icns`) depicting four interconnected Apple Silicon node dies around a glowing **Solaris Sun** unified-memory core with the industrial hazard bar and `SS-CCC` badge.

`SSCCCAppIconProvider.applyDockIcon()` applies the icon automatically on startup, Dock reopen (`applicationShouldHandleReopen`), and when restoring the window from the Menu Bar (`restoreWindowFromMenuBar()`).
