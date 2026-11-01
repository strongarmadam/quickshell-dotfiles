import Quickshell
import Quickshell.Services.SystemTray

// Own the tray registry independently of the themed desktop's lifetime.
Scope {
    readonly property var registeredItems: SystemTray.items
}
