import "." as Config
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Hyprland
import Quickshell.Wayland
Scope {
    id: root
    required property var palette
    property bool centerOpen: false
    readonly property int count: server.trackedNotifications.values.length
    function toggle() { centerOpen = !centerOpen; }
    function clear() { server.trackedNotifications.values.slice().forEach(n => n.dismiss()); }
    NotificationServer {
        id: server
        actionsSupported: true; bodySupported: true; persistenceSupported: true
        onNotification: notification => { notification.tracked = true; if (server.trackedNotifications.values.length > 50) server.trackedNotifications.values[0].dismiss(); }
    }
    PanelWindow {
        id: panel
        screen: Quickshell.screens[0]
        anchors { top: true; right: true }
margins { top: 48; right: 12 }
        implicitWidth: Config.Settings.value("shared", "DesktopNotifications", "implicitWidth", 360)
        implicitHeight: Math.min(screen ? screen.height - 80 : 700, column.implicitHeight + 24)
        visible: root.centerOpen || cards.visibleCount > 0
        color: "transparent"; exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay; WlrLayershell.namespace: "quickshell-notifications"
        WlrLayershell.keyboardFocus: root.centerOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        HyprlandFocusGrab {
            active: root.centerOpen
            windows: [panel]
            onCleared: root.centerOpen = false
        }
        Connections {
            target: root
            function onCenterOpenChanged() { if (root.centerOpen) history.forceActiveFocus(); }
        }
        Flickable {
            id: history
            focus: root.centerOpen
            Keys.onEscapePressed: event => { root.centerOpen = false; event.accepted = true; }
            anchors.fill: parent; contentHeight: column.implicitHeight + 24; clip: true
            Column {
                id: column; x: 12; y: 12; width: parent.width - 24; spacing: 8
                Rectangle {
                    visible: root.centerOpen; width: parent.width; height: 44
                    color: root.palette.surfaceColor; radius: root.palette.cornerRadius; border.color: root.palette.edgeColor
                    Row {
                        anchors.centerIn: parent; spacing: 8
                        UiButton { palette: root.palette; label: "NOTIFICATIONS" }
                        UiButton { palette: root.palette; label: "Clear"; onClicked: root.clear() }
                        UiButton { palette: root.palette; label: "×"; onClicked: root.centerOpen = false }
                    }
                }
                Text { visible: root.centerOpen && root.count === 0; text: "No notifications"; color: root.palette.textColor; font.pixelSize: 14 }
                Repeater {
                    id: cards; model: server.trackedNotifications
                    property int visibleCount: { let n = 0; for (let i = 0; i < count; i++) { const item = itemAt(i); if (item && item.toastVisible) n++; } return n; }
                    delegate: Rectangle {
                        id: card
                        required property var modelData
                        property bool toastVisible: !modelData.lastGeneration
                        visible: root.centerOpen || toastVisible
                        width: column.width; height: visible ? content.implicitHeight + 24 : 0
                        radius: root.palette.cornerRadius; color: root.palette.surfaceColor
                        border { color: modelData.urgency === NotificationUrgency.Critical ? root.palette.accentColor : root.palette.edgeColor; width: root.palette.edgeWidth }
                        Timer { interval: card.modelData.expireTimeout > 0 ? card.modelData.expireTimeout : 6000; running: card.toastVisible && card.modelData.expireTimeout !== 0 && card.modelData.urgency !== NotificationUrgency.Critical; onTriggered: { card.toastVisible = false; if (card.modelData.transient) card.modelData.expire(); } }
                        Connections { target: card.modelData; function onSummaryChanged() { card.toastVisible = true; } }
                        Column {
                            id: content; x: 12; y: 12; width: parent.width - 24; spacing: 8
                            Row {
                                width: parent.width; spacing: 6
                                Text { width: parent.width - 32; text: card.modelData.appName; color: root.palette.accentColor; font.pixelSize: 11; elide: Text.ElideRight; textFormat: Text.PlainText }
                                UiButton { palette: root.palette; label: "×"; implicitHeight: 18; onClicked: card.modelData.dismiss() }
                            }
                            Text { width: parent.width; text: card.modelData.summary; color: root.palette.textColor; font { pixelSize: 14; bold: true }
wrapMode: Text.Wrap; maximumLineCount: 3; elide: Text.ElideRight; textFormat: Text.PlainText }
                            Text { width: parent.width; visible: text.length > 0; text: card.modelData.body; color: root.palette.textColor; font.pixelSize: 12; wrapMode: Text.Wrap; maximumLineCount: 6; elide: Text.ElideRight; textFormat: Text.PlainText }
                            Flow {
                                width: parent.width; spacing: 4
                                Repeater {
                                    model: card.modelData.actions
                                    UiButton { required property var modelData; palette: root.palette; label: modelData.text; onClicked: modelData.invoke() }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
