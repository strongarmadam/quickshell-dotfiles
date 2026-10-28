pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var data: ({})
    property var creatorTheme: ({})
    FileView {
        id: creatorStorage
        path: Quickshell.env("HOME") + "/.config/themes/current/creator-settings.json"
        blockLoading: true; watchChanges: true; printErrors: false
        onFileChanged: reload()
        onLoaded: { try { root.creatorTheme = JSON.parse(text()); } catch (e) { root.creatorTheme = {}; } }
    }
    function value(theme, component, key, fallback) {
        const group = theme === root.creatorTheme.name ? root.creatorTheme.values : theme === "shared" ? data.shared : (data.themes || {})[theme];
        const values = group && group[component];
        return values && values[key] !== undefined ? values[key] : fallback;
    }
    function load() {
        try {
            const parsed = JSON.parse(storage.text());
            if (parsed.version !== 1 || !parsed.shared || !parsed.themes || !parsed.layout)
                throw new Error("Expected version 1 with shared, themes, and layout objects");
            data = parsed;
        } catch (error) { console.warn("Quickshell settings: keeping previous settings:", error); }
    }
    function saveLayout(positions) {
        if (data.version !== 1) {
            console.warn("Cannot save layout until valid settings are loaded");
            return;
        }
        const updated = Object.assign({}, data, {layout: positions});
        data = updated;
        storage.setText(JSON.stringify(updated, null, 2) + "\n");
    }
    FileView {
        id: storage
        path: Quickshell.env("HOME") + "/.config/quickshell/settings.json"
        blockLoading: true
        atomicWrites: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.load()
        onSaveFailed: error => console.warn("Quickshell settings could not be saved:", error)
    }
    Component.onCompleted: load()
}
