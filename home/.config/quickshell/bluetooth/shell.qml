import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Bluetooth

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
    readonly property var adapter: Bluetooth.defaultAdapter
    property bool scanning: false
    Component.onDestruction: { if (scanning && adapter) adapter.discovering = false; }
    Timer { interval: 30000; running: root.scanning; onTriggered: { if (root.adapter) root.adapter.discovering=false; root.scanning=false; } }
    IpcHandler { target: "bluetooth"; function toggle(): void { Qt.quit(); } function scan(enabled: bool): void { if (root.adapter && root.adapter.enabled) { root.scanning=enabled; root.adapter.discovering=enabled; } } function state(): string { return JSON.stringify({visible:window.visible,discovering:root.adapter ? root.adapter.discovering : false,adapter:root.adapter ? root.adapter.name : "",devices:Bluetooth.devices.values.length,width:window.width,height:window.height}); } }
    PanelWindow {
        id: window
        visible: true
        screen: Quickshell.screens[0] || null
        anchors { top: true; right: true }
        margins { top: 48; right: 12 }
        implicitWidth: Math.min(460, screen ? screen.width - 24 : 460)
        implicitHeight: Math.min(400, screen ? screen.height - 72 : 400)
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell-bluetooth"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        color: "transparent"
        Rectangle { anchors.fill: parent; color: root.surface; radius: root.theme.cornerRadius; border.color: root.edge; border.width: root.theme.edgeWidth }
        HyprlandFocusGrab { active: window.visible; windows: [window]; onCleared: Qt.quit() }
        Shortcut { sequence: "Escape"; onActivated: Qt.quit() }
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 14; spacing: 10
            RowLayout {
                Label { text: "Bluetooth"; color: root.ink; font.pixelSize: 20; font.bold: true }
                Item { Layout.fillWidth: true }
                ThemeButton { text: "Close"; onClicked: Qt.quit() }
            }
            RowLayout {
                ThemeButton { text: root.adapter && root.adapter.enabled ? "Turn off" : "Turn on"; enabled: !!root.adapter; onClicked: root.adapter.enabled = !root.adapter.enabled }
                ThemeButton { text: root.scanning ? "Stop scan" : "Scan"; enabled: !!root.adapter && root.adapter.enabled; onClicked: { root.scanning=!root.scanning; root.adapter.discovering=root.scanning; } }
                Item { Layout.fillWidth: true }
            }
            Label { text: !root.adapter ? "No Bluetooth adapter found" : !root.adapter.enabled ? "Bluetooth is off or blocked" : root.scanning ? "Searching for nearby devices…" : "Choose a device to pair or connect."; color: root.muted; wrapMode: Text.Wrap; Layout.fillWidth: true }
            ListView {
                id: list
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 8
                model: Bluetooth.devices.values
                ScrollBar.vertical: ScrollBar { contentItem: Rectangle { implicitWidth: 6; implicitHeight: 30; radius: 3; color: root.accent } }
                delegate: Rectangle {
                    required property var modelData
                    width: list.width-12; height: 68; radius: root.radius; color: root.rowColor
                    border.color: modelData.connected ? root.accent : root.edge; border.width: root.theme.edgeWidth
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 10; spacing: 10
                        ColumnLayout {
                            Layout.fillWidth: true
                            Label { text: modelData.name || modelData.address; textFormat: Text.PlainText; color: root.ink; Layout.fillWidth: true; elide: Text.ElideRight; font.bold: true }
                            Label { text: modelData.pairing ? "Pairing…" : BluetoothDeviceState.toString(modelData.state) + (modelData.paired ? " · Paired" : " · Not paired"); color: root.muted; font.pixelSize: 12 }
                        }
                        ThemeButton {
                            text: modelData.pairing ? "Cancel" : modelData.connected ? "Disconnect" : modelData.paired ? "Connect" : "Pair"
                            enabled: !!root.adapter && root.adapter.enabled
                            onClicked: { if (modelData.pairing) modelData.cancelPair(); else if (modelData.connected) modelData.disconnect(); else if (modelData.paired) modelData.connect(); else modelData.pair(); }
                        }
                    }
                }
                Label { anchors.centerIn: parent; visible: list.count===0; text: "No devices yet. Turn on Bluetooth and scan."; color: root.muted; width: parent.width; wrapMode: Text.Wrap; horizontalAlignment: Text.AlignHCenter }
            }
            Label { text: "Pairing confirmations appear through Bluetooth authentication."; color: root.muted; Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: 12 }
        }
    }
}
