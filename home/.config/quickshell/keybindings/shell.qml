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
    property string message: "Edit a shortcut and click Save. Generated shortcuts can be changed with Edit source."
    property bool failed: false
    function run(op, request) {
        if (worker.running) return;
        worker.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/keybindings/backend.py", op, JSON.stringify(request || {})];
        worker.operation = op;
        worker.running = true;
    }
    Process {
        id: worker
        property string operation: ""
        stdout: StdioCollector { onStreamFinished: {
            try {
                const result = JSON.parse(text);
                root.failed = !result.ok;
                if (result.rows) root.rows = result.rows;
                if (result.message) root.message = result.message;
                if (result.ok && (worker.operation === "save" || worker.operation === "reload")) refreshTimer.start();
            } catch (e) { root.failed = true; root.message = "Could not read shortcut data: " + e; }
        } }
    }
    Timer { id: refreshTimer; interval: 150; onTriggered: root.run("list") }
    Component.onCompleted: run("list")
    IpcHandler { target: "keybindings"; function toggle(): void { Qt.quit(); } }
    ApplicationWindow {
        id: window
        visible: true; width: 900; height: 600; minimumWidth: 760; minimumHeight: 400
        title: "Keyboard shortcuts"
        color: "transparent"
        background: Rectangle { color: root.surface; radius: root.theme.cornerRadius; border.color: root.edge; border.width: root.theme.edgeWidth }
        palette { window: root.surface; windowText: root.ink; base: root.rowColor; text: root.ink; button: root.rowColor; buttonText: root.ink; highlight: root.accent; highlightedText: root.panel; toolTipBase: root.panel; toolTipText: root.ink }
        onClosing: Qt.quit()
        HyprlandFocusGrab {
            active: window.visible
            windows: [window]
            onCleared: Qt.quit()
        }
        Shortcut { sequence: "Escape"; onActivated: Qt.quit() }
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 22; spacing: 12
            RowLayout {
                Label { text: "Keyboard shortcuts"; font.pixelSize: 26; font.bold: true }
                Item { Layout.fillWidth: true }
                Label { text: root.rows.length + " active bindings"; color: root.muted }
                ThemeButton { text: "Close"; onClicked: Qt.quit() }
            }
            RowLayout {
                ThemeField { Layout.fillWidth: true; placeholderText: "Search action, key, or mode…"; placeholderTextColor: root.muted; focus: true; onTextChanged: root.query = text.toLowerCase() }
                ThemeButton { text: "Refresh"; enabled: !worker.running; onClicked: root.run("list") }
                ThemeButton { text: "Reload config"; enabled: !worker.running; onClicked: root.run("reload") }
            }
            Label { text: root.message; color: root.failed ? "#ff9e9e" : root.muted; wrapMode: Text.Wrap; Layout.fillWidth: true }
            Label { text: "Key names: SUPER + SHIFT + slash · CTRL + Return · mouse:272. Escape closes this window."; color: root.muted; wrapMode: Text.Wrap; Layout.fillWidth: true }
            ListView {
                id: list
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 6
                model: root.rows.filter(r => (r.shortcut + " " + r.action + " " + r.mode).toLowerCase().includes(root.query))
                ScrollBar.vertical: ScrollBar {
                    contentItem: Rectangle { implicitWidth: 6; implicitHeight: 30; radius: 3; color: root.accent; opacity: parent.active ? 0.9 : 0.4 }
                }
                delegate: Rectangle {
                    required property var modelData
                    width: list.width - 16; height: 64; radius: root.radius; color: root.rowColor; border.color: Qt.rgba(root.edge.r, root.edge.g, root.edge.b, 0.35); border.width: 1
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 10; spacing: 10
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 5
                            Label { text: modelData.action; Layout.fillWidth: true; elide: Text.ElideRight; ToolTip.visible: actionHover.hovered; ToolTip.text: text; HoverHandler { id: actionHover } }
                            Label { text: modelData.mode + (modelData.flags ? " · " + modelData.flags : "") + (modelData.editable ? "" : " · edit in source"); color: root.muted; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                        }
                        ThemeField { id: key; text: modelData.shortcut; readOnly: !modelData.editable; Layout.preferredWidth: 240; selectByMouse: true }
                        ThemeButton { text: "Save"; enabled: modelData.editable && key.text !== modelData.shortcut && !worker.running; onClicked: root.run("save", Object.assign({}, modelData, {value:key.text})) }
                        ThemeButton { text: "Edit source"; enabled: !worker.running; onClicked: root.run("edit", modelData) }
                    }
                }
            }
        }
    }
}
