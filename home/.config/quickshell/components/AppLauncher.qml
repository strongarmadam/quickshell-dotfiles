import "." as Config
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
Item {
    id: root
    required property var palette
    property bool opened: false
    property bool presented: false
    property string mode: "apps"
    property var results: []
    property int selected: 0
    property var usageCounts: ({})
    FileView {
        id: usageStorage
        path: Quickshell.env("HOME") + "/.local/state/quickshell-launcher-usage.json"
        blockLoading: true
        atomicWrites: true
        printErrors: false
        onSaveFailed: error => console.warn("Launcher usage could not be saved:", error)
    }
    Component.onCompleted: {
        try {
            const saved = JSON.parse(usageStorage.text());
            if (saved.version === 1 && saved.counts && typeof saved.counts === "object") usageCounts = saved.counts;
        } catch (error) { /* Usage starts at zero when there is no history. */ }
        filter();
    }
    function recordLaunch(id) {
        const updated = Object.assign({}, usageCounts);
        updated[id] = (Number(updated[id]) || 0) + 1;
        usageCounts = updated;
        usageStorage.setText(JSON.stringify({version: 1, counts: updated}, null, 2) + "\n");
    }
    function filter() {
        let query = search.text.toLowerCase().trim();
        results = DesktopEntries.applications.values.filter(e => (e.name + " " + e.genericName + " " + e.keywords.join(" ")).toLowerCase().includes(query)).sort((a,b) => ((Number(usageCounts[b.id]) || 0) - (Number(usageCounts[a.id]) || 0)) || a.name.localeCompare(b.name));
        selected = 0;
    }
    function stateInfo() { return JSON.stringify({open: opened, matches: results.length, first: results.length ? results[0].name : ""}); }
    function setQuery(query) { search.text = query; }
    function open() { opened = true; }
    function close() { opened = false; }
    function toggle(nextMode) { mode = nextMode || "apps"; opened = !opened; }
    function launch(index) {
        const entry = results[index];
        if (!entry) return;
        recordLaunch(entry.id);
        close();
        const appCommand = entry.runInTerminal ? [Quickshell.env("HOME") + "/.local/bin/desktop-app", "terminal-exec"].concat(entry.command) : entry.command;
        // A separate scope keeps launched apps alive when the desktop service restarts.
        Quickshell.execDetached({command: ["systemd-run", "--user", "--scope", "--collect", "--quiet", "--expand-environment=no", "--"].concat(appCommand), workingDirectory: entry.workingDirectory});
    }
    visible: presented
    enabled: opened
    property var screen: Hyprland.focusedMonitor ? Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor.name) || Quickshell.screens[0] : Quickshell.screens[0]
    x: parent ? (parent.width - width) / 2 : 0
    y: 38
    width: implicitWidth
    height: implicitHeight
    readonly property real revealProgress: sheet.reveal
    implicitWidth: Math.min(340 + 2 * palette.cornerRadius, screen ? screen.width - 32 : 340)
    implicitHeight: Math.min(screen ? screen.height - 70 : 400,
                            mode === "web" ? 54 : 58 + Math.max(1, Math.min(results.length, 10)) * 42)
    function animateTo(target) {
        revealAnimation.stop();
        revealAnimation.from = sheet.reveal;
        revealAnimation.to = target;
        revealAnimation.start();
    }
    onOpenedChanged: {
        if (opened) {
            search.text = "";
            filter();
            if (!presented) {
                presented = true;
                // Map the surface and paint the collapsed frame before motion.
                openingTimer.restart();
            } else animateTo(1);
            Qt.callLater(() => { if (root.opened) search.forceActiveFocus(); });
        } else {
            openingTimer.stop();
            animateTo(0);
        }
    }
    Timer {
        id: openingTimer
        interval: 32
        onTriggered: if (root.opened) root.animateTo(1)
    }
    NumberAnimation {
        id: revealAnimation
        target: sheet; property: "reveal"
        duration: 160
        easing.type: Easing.OutCubic
        onFinished: if (!root.opened) root.presented = false
    }
    Connections { target: DesktopEntries; function onApplicationsChanged() { root.filter(); } }
    Item {
        anchors.fill: parent
        clip: true
        Rectangle {
            id: sheet
            property real reveal: 0
            width: parent.width
            height: parent.height
            y: (reveal - 1) * height
            color: "transparent"
            Column {
                anchors { fill: parent; margins: 10; leftMargin: 10 + root.palette.cornerRadius; rightMargin: 10 + root.palette.cornerRadius }
                spacing: Config.Settings.value("shared", "AppLauncher", "spacing", 8)
                Rectangle {
                    width: parent.width
                    height: Config.Settings.value("shared", "AppLauncher", "height", 34)
                    color: root.palette.launcherBubbles ? root.palette.surfaceColor : "#20ffffff"
                    radius: root.palette.cornerRadius > 0 ? 6 : 0
                    TextInput {
                        id: search
                        anchors { fill: parent; leftMargin: 10; rightMargin: 10; topMargin: 8; bottomMargin: 8 }
                        color: root.palette.textColor
                        font { family: "JetBrainsMono Nerd Font"; pixelSize: 12; bold: true }
                        clip: true
                        selectByMouse: true
                        onTextChanged: root.filter()
                        Keys.onEscapePressed: root.close()
                        Keys.onDownPressed: root.selected = Math.min(root.results.length - 1, root.selected + 1)
                        Keys.onUpPressed: root.selected = Math.max(0, root.selected - 1)
                        Keys.onReturnPressed: {
                            if (root.mode === "web") {
                                root.close();
                                Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/desktop-app", "browser", "https://www.google.com/search?q=" + encodeURIComponent(text)]);
                            } else root.launch(root.selected);
                        }
                        Text {
                            anchors.fill: parent
                            visible: !search.text && !search.preeditText
                            text: root.mode === "web" ? "Search the web…" : "Search apps…"
                            color: root.palette.textColor
                            opacity: Config.Settings.value("shared", "AppLauncher", "opacity", 0.45)
                            font: search.font
                        }
                    }
                }
                ListView {
                    id: list
                    width: parent.width
                    height: root.height - 62
                    clip: true
                    spacing: Config.Settings.value("shared", "AppLauncher", "spacing_2", 6)
                    visible: root.mode === "apps"
                    model: root.results
                    currentIndex: root.selected
                    highlightMoveDuration: 0
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: list.width
                        height: Config.Settings.value("shared", "AppLauncher", "height_2", 36)
                        radius: root.palette.cornerRadius > 0 ? 18 : 0
                        border.width: Math.max(1, root.palette.edgeWidth)
                        border.color: root.selected === index ? root.palette.accentColor : root.palette.edgeColor
                        color: root.selected === index ? root.palette.accentColor : root.palette.surfaceColor
                        ThemeAppIcon {
                            x: 10; anchors.verticalCenter: parent.verticalCenter
                            width: 16; height: 16
                            symbol: root.palette.launcherSymbol
                            ink: root.selected === index ? root.palette.panelColor : root.palette.accentColor
                        }
                        Text {
                            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 34; rightMargin: 10 }
                            text: modelData.name
                            color: root.selected === index ? root.palette.panelColor : root.palette.textColor
                            font { family: search.font.family; pixelSize: 14; bold: true }
                            elide: Text.ElideRight
                            textFormat: Text.PlainText
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: root.selected = index
                            onClicked: root.launch(index)
                        }
                    }
                    Text {
                        visible: root.results.length === 0
                        text: "No applications found"
                        color: root.palette.textColor
                        font: search.font
                        anchors.centerIn: parent
                    }
                }
            }
        }
    }
}
