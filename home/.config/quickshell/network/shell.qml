import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
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
    property var network: ({devices: [], profiles: [], networks: [], wifiAvailable: false, wifiEnabled: false, wifiHardware: false})
    property string message: "Choose a connection. Passwords are requested locally by NetworkManager."
    property bool failed: false
    property string query: ""
    property int section: 0
    readonly property var entries: (section === 0 ? network.networks : section === 1 ? network.devices : network.profiles).filter(r => (r.ssid || r.name || r.device || "").toLowerCase().includes(query))
    function run(request) {
        if (worker.running) return;
        worker.requestedOp = request.op;
        worker.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/network/backend.py", JSON.stringify(request)];
        worker.running = true;
    }
    function activate(row) {
        if (section === 0) run(row.active ? {op:"disconnect",device:row.device} : {op:"wifi-connect",device:row.device,bssid:row.bssid});
        else if (section === 1) run({op: row.state.startsWith("connected") ? "disconnect" : "device-connect",device:row.device});
        else run({op:row.active ? "profile-disconnect" : "profile-connect",uuid:row.uuid});
    }
    function rowActive(row) { return section === 1 ? row.state.startsWith("connected") : row.active; }
    function subtitle(row) {
        if (section === 0) return row.signal + "% signal · " + row.security + " · " + row.device + (row.active ? " · Connected" : "");
        if (section === 1) return row.type + " · " + row.state + (row.connection && row.connection !== "--" ? " · " + row.connection : "");
        return row.type + (row.active ? " · Active on " + row.device : " · Saved");
    }
    Process {
        id: worker
        property string requestedOp: ""
        stdout: StdioCollector { onStreamFinished: {
            try {
                const result = JSON.parse(text);
                if (result.external) { Qt.quit(); return; }
                if (result.status) { root.network = result.status; if (!root.network.wifiAvailable && root.section === 0) root.section = 1; }
                if (!result.ok || result.message) { root.failed = !result.ok; root.message = result.message; }
            } catch(e) { root.failed = true; root.message = "Could not read NetworkManager status."; }
        } }
    }
    Component.onCompleted: run({op:"status"})
    Timer { interval: 5000; running: true; repeat: true; onTriggered: root.run({op:"status"}) }
    IpcHandler { target: "network"; function toggle(): void { Qt.quit(); } function state(): string { return JSON.stringify({visible:window.visible,grab:networkGrab.active,devices:root.network.devices.length,wifi:root.network.wifiAvailable,width:window.width,height:window.height,screen:window.screen ? window.screen.name : ""}); } }
    PanelWindow {
        id: window
        visible: true
        screen: Quickshell.screens[0] || null
        anchors { top: true; right: true }
        margins { top: 48; right: 12 }
        implicitWidth: Math.min(520, screen ? screen.width - 24 : 520)
        implicitHeight: Math.min(460, screen ? screen.height - 72 : 460)
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell-network"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        color: "transparent"
        Rectangle { anchors.fill: parent; color: root.surface; radius: root.theme.cornerRadius; border.color: root.edge; border.width: root.theme.edgeWidth }
        HyprlandFocusGrab { id: networkGrab; active: window.visible; windows: [window]; onCleared: Qt.quit() }
        Shortcut { sequence: "Escape"; onActivated: Qt.quit() }
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 14; spacing: 10
            RowLayout {
                Label { text: "Network connections"; color: root.ink; font.pixelSize: 20; font.bold: true }
                Item { Layout.fillWidth: true }
                ThemeButton { text: "Advanced…"; enabled: !worker.running; onClicked: root.run({op:"advanced"}) }
                ThemeButton { text: "Close"; onClicked: Qt.quit() }
            }
            RowLayout {
                ThemeButton { text: "Wi-Fi"; enabled: root.network.wifiAvailable; onClicked: root.section=0 }
                ThemeButton { text: "Adapters"; onClicked: root.section=1 }
                ThemeButton { text: "Saved / VPN"; onClicked: root.section=2 }
                Item { Layout.fillWidth: true }
                ThemeButton { visible: root.network.wifiAvailable; text: root.network.wifiEnabled ? "Turn Wi-Fi off" : "Turn Wi-Fi on"; enabled: !worker.running && root.network.wifiHardware; onClicked: root.run({op:"radio",enabled:!root.network.wifiEnabled}) }
            }
            RowLayout {
                ThemeField { Layout.fillWidth: true; focus: true; Component.onCompleted: Qt.callLater(() => forceActiveFocus()); placeholderText: "Search connections…"; onTextChanged: root.query=text.toLowerCase() }
                ThemeButton { text: root.section===0 ? "Scan" : "Refresh"; enabled: !worker.running && (root.section !== 0 || root.network.wifiEnabled); onClicked: root.run({op:root.section===0 ? "scan" : "status"}) }
            }
            Label { text: worker.running && worker.requestedOp !== "status" ? "Updating connection…" : root.message; color: root.failed ? "#ff9e9e" : root.muted; wrapMode: Text.Wrap; Layout.fillWidth: true }
            Label { visible: root.network.wifiAvailable && !root.network.wifiHardware; text: "Wi-Fi is blocked by a hardware switch or airplane mode."; color: root.accent; Layout.fillWidth: true; wrapMode: Text.Wrap }
            ListView {
                id: list
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 8
                model: root.entries
                ScrollBar.vertical: ScrollBar { contentItem: Rectangle { implicitWidth: 6; implicitHeight: 30; radius: 3; color: root.accent } }
                delegate: Rectangle {
                    required property var modelData
                    width: list.width-12; height: 62; radius: root.radius; color: root.rowColor
                    border.color: root.rowActive(modelData) ? root.accent : root.edge; border.width: 1
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 10; spacing: 10
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 6
                            Label { text: modelData.ssid || modelData.name || modelData.device; textFormat: Text.PlainText; color: root.ink; Layout.fillWidth: true; elide: Text.ElideRight; font.bold: true }
                            Label { text: root.subtitle(modelData); textFormat: Text.PlainText; color: root.muted; Layout.fillWidth: true; elide: Text.ElideRight; font.pixelSize: 12 }
                        }
                        ThemeButton { text: root.rowActive(modelData) ? "Disconnect" : "Connect"; enabled: !worker.running && !(root.section===1 && (modelData.state==="unavailable" || modelData.state==="unmanaged")); onClicked: root.activate(modelData) }
                    }
                }
                Label { anchors.centerIn: parent; visible: root.entries.length===0; text: root.query ? "No matching connections" : root.section===0 ? (root.network.wifiEnabled ? "No networks found. Try Scan." : "Wi-Fi is off.") : "No connections available"; color: root.muted }
            }
            Label { text: (root.section===0 ? "Wi-Fi networks" : root.section===1 ? "Network adapters" : "Saved profiles and VPNs") + " · Advanced: hidden Wi-Fi, IP/DNS and profile editing"; color: root.muted; Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: 12 }
        }
    }
}
