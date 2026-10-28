import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

ShellRoot {
    id: root
    property var theme: ({name: "", panelColor: "#b8030609", textColor: "#d7f3ff", accentColor: "#3aa9d2", edgeColor: "#155779", panelOpacity: 1, cornerRadius: 4, edgeWidth: 1})
    readonly property color panel: theme.panelColor
    readonly property color ink: theme.textColor
    readonly property color accent: theme.accentColor
    readonly property color edge: theme.edgeColor
    readonly property color surface: Qt.rgba(panel.r, panel.g, panel.b, panel.a * theme.panelOpacity)
    readonly property color muted: Qt.rgba(ink.r, ink.g, ink.b, 0.72)
    readonly property color rowColor: Qt.rgba(panel.r, panel.g, panel.b, 0.25)
    readonly property real radius: Math.min(theme.cornerRadius, 12)
    Process {
        id: themeReader
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/keybindings/backend.py", "theme"]
        running: true
        stdout: StdioCollector { onStreamFinished: {
            try { const result = JSON.parse(text); if (result.ok) root.theme = result.theme; } catch (e) { console.warn("Shortcut theme:", e); }
        } }
    }
    Timer { interval: 2000; repeat: true; running: true; onTriggered: { if (!themeReader.running) themeReader.running = true; } }
    component ThemeButton: Button {
        id: control
        hoverEnabled: true
        contentItem: Text { text: control.text; font: control.font; color: root.ink; opacity: control.enabled ? 1 : 0.4; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        background: Rectangle {
            implicitWidth: 80; implicitHeight: 34; radius: root.radius
            color: control.down ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.35) : control.hovered ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.20) : root.rowColor
            border.color: control.activeFocus || control.hovered ? root.accent : root.edge
            border.width: root.theme.edgeWidth; opacity: control.enabled ? 1 : 0.4
        }
    }
    component ThemeField: TextField {
        id: control
        color: root.ink; placeholderTextColor: root.muted
        selectionColor: root.accent; selectedTextColor: root.panel
        background: Rectangle {
            implicitHeight: 34; implicitWidth: 160; radius: root.radius
            color: root.rowColor
            border.color: control.activeFocus ? root.accent : root.edge
            border.width: root.theme.edgeWidth
        }
    }
    property var rows: []
    property string query: ""
    property bool paused: false
    property bool confirmClear: false
    property string message: "Select an entry to copy, then paste normally."
    readonly property var filtered: rows.filter(r => r.preview.toLowerCase().includes(query))
    function run(op, id) {
        if (worker.running) return;
        worker.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/clipboard/backend.py", op, id || ""];
        worker.running = true;
    }
    function choose(index) { if (filtered[index]) run("copy", filtered[index].id); }
    Process {
        id: worker
        stdout: StdioCollector { onStreamFinished: {
            try {
                const result = JSON.parse(text);
                if (!result.ok) { root.message = result.message; return; }
                if (result.copied) { Qt.quit(); return; }
                if (result.rows) root.rows = result.rows;
                root.paused = !!result.paused;
                if (list.currentIndex < 0 && root.filtered.length) list.currentIndex = 0;
            } catch(e) { root.message = "Could not read clipboard history."; }
        } }
    }
    Component.onCompleted: run("list")
    Timer { interval: 1500; running: true; repeat: true; onTriggered: root.run("list") }
    IpcHandler { target: "clipboard"; function toggle(): void { Qt.quit(); } function state(): string { return JSON.stringify({visible: window.visible, grab: clipboardGrab.active}); } }
    FloatingWindow {
        id: window
        visible: true; implicitWidth: 700; implicitHeight: 540; minimumSize: Qt.size(500, 350)
        title: "Clipboard history"
        color: "transparent"
        Rectangle { anchors.fill: parent; color: root.surface; radius: root.theme.cornerRadius; border.color: root.edge; border.width: root.theme.edgeWidth }
        onClosed: Qt.quit()
        HyprlandFocusGrab { id: clipboardGrab; active: window.visible; windows: [window]; onCleared: Qt.quit() }
        Shortcut { sequence: "Escape"; onActivated: Qt.quit() }
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 20; spacing: 12
            RowLayout {
                Label { text: "Clipboard history"; color: root.ink; font.pixelSize: 25; font.bold: true }
                Item { Layout.fillWidth: true }
                ThemeButton { text: root.paused ? "Resume" : "Pause"; onClicked: root.run("pause") }
                ThemeButton { text: root.confirmClear ? "Confirm clear" : "Clear all"; enabled: root.rows.length > 0; onClicked: { if (root.confirmClear) { root.run("clear"); root.confirmClear = false; } else root.confirmClear = true; } }
            }
            ThemeField {
                Layout.fillWidth: true; focus: true; placeholderText: "Search clipboard history…"
                onTextChanged: { root.query = text.toLowerCase(); list.currentIndex = 0; root.confirmClear = false; }
                Keys.onDownPressed: list.currentIndex = Math.min(root.filtered.length-1, list.currentIndex+1)
                Keys.onUpPressed: list.currentIndex = Math.max(0,list.currentIndex-1)
                Keys.onReturnPressed: root.choose(list.currentIndex)
                Keys.onEnterPressed: root.choose(list.currentIndex)
            }
            Label { text: root.paused ? "Recording paused · existing history is still available" : root.message; color: root.muted; wrapMode: Text.Wrap; Layout.fillWidth: true }
            ListView {
                id: list
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 6
                model: root.filtered; currentIndex: 0
                ScrollBar.vertical: ScrollBar { contentItem: Rectangle { implicitWidth: 6; implicitHeight: 30; radius: 3; color: root.accent } }
                delegate: Rectangle {
                    id: entry
                    required property var modelData
                    required property int index
                    width: list.width-12; height: 64; radius: root.radius
                    color: ListView.isCurrentItem ? Qt.tint(root.rowColor,Qt.rgba(root.accent.r,root.accent.g,root.accent.b,0.18)) : root.rowColor
                    border.color: ListView.isCurrentItem ? root.accent : root.edge
                    border.width: 1
                    MouseArea { anchors.fill: parent; onClicked: root.choose(entry.index) }
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 10; spacing: 12
                        Label { text: entry.modelData.image ? "IMAGE" : "TEXT"; color: root.accent; font.pixelSize: 10 }
                        Label { text: entry.modelData.preview; textFormat: Text.PlainText; color: root.ink; Layout.fillWidth: true; elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.Wrap }
                        ThemeButton { text: "Delete"; onClicked: root.run("delete",entry.modelData.id) }
                    }
                }
                Label { anchors.centerIn: parent; visible: root.filtered.length === 0; text: root.rows.length ? "No matches" : "Copy something to start your history."; color: root.muted }
            }
            Label { text: root.rows.length + "/200 entries · ↑ ↓ select · Enter copies · Esc closes"; color: root.muted; font.pixelSize: 12 }
        }
    }
}
