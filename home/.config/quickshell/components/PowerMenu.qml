import "." as Config
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: root
    property color panelColor
    property color edgeColor
    property color textColor
    property color accentColor
    property real panelOpacity: Config.Settings.value("shared", "PowerMenu", "panelOpacity", 1)
    property real cornerRadius: Config.Settings.value("shared", "PowerMenu", "cornerRadius", 18)
    property int edgeWidth: Config.Settings.value("shared", "PowerMenu", "edgeWidth", 1)
    readonly property color surfaceColor: Qt.rgba(panelColor.r, panelColor.g, panelColor.b, panelColor.a * panelOpacity)
    property int selectedIndex: 0
    readonly property var actions: [
        { label: "Lock", icon: "lock", command: [Quickshell.env("HOME") + "/.local/bin/lock-session"] },
        { label: "Power off", icon: "power", command: ["systemctl", "poweroff"] },
        { label: "Reboot", icon: "reboot", command: ["systemctl", "reboot"] },
        { label: "Log out", icon: "logout", command: ["hyprctl", "dispatch", "hl.dsp.exit()"] }
    ]
    function moveSelection(direction) {
        selectedIndex = (selectedIndex + direction + actions.length) % actions.length;
    }
    function activate(index) {
        visible = false;
        Quickshell.execDetached(actions[index].command);
    }
    onVisibleChanged: {
        if (visible) {
            selectedIndex = 0;
            keyboard.forceActiveFocus();
        }
    }
    visible: false
    screen: Quickshell.screens[0] || null
    anchors.right: true
    margins.right: 28
    implicitWidth: Config.Settings.value("shared", "PowerMenu", "implicitWidth", 300)
    readonly property real buttonSpacing: Config.Settings.value("shared", "PowerMenu", "spacing", 16)
    readonly property real buttonHeight: Math.min(Config.Settings.value("shared", "PowerMenu", "height", 136), ((screen ? screen.height : 720) - 48 - buttonSpacing * (actions.length - 1)) / actions.length)
    implicitHeight: actions.length * buttonHeight + (actions.length - 1) * buttonSpacing
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "power-menu"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    HyprlandFocusGrab {
        active: root.visible
        windows: [root]
        onCleared: root.visible = false
    }

    IpcHandler {
        target: "powerMenu"
        function toggle(): void { root.visible = !root.visible; }
        function close(): void { root.visible = false; }
        function isOpen(): bool { return root.visible; }
        function selectedButton(): string { return root.actions[root.selectedIndex].label; }
        function moveSelection(direction: int): void { root.moveSelection(direction); }
    }

    Item {
        id: keyboard
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Up || event.key === Qt.Key_Left || event.key === Qt.Key_K || event.key === Qt.Key_H)
                root.moveSelection(-1);
            else if (event.key === Qt.Key_Down || event.key === Qt.Key_Right || event.key === Qt.Key_J || event.key === Qt.Key_L)
                root.moveSelection(1);
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                if (!event.isAutoRepeat) root.activate(root.selectedIndex);
            } else if (event.key === Qt.Key_Escape) root.visible = false;
            else return;
            event.accepted = true;
        }
        Column {
            anchors.fill: parent
            spacing: root.buttonSpacing
            Repeater {
                model: root.actions
                delegate: Rectangle {
                    id: button
                    required property int index
                    required property var modelData
                    readonly property bool selected: root.selectedIndex === index
                    width: Config.Settings.value("shared", "PowerMenu", "width", 300)
                    height: root.buttonHeight
                    radius: root.cornerRadius
                    color: button.selected || mouse.containsMouse ? Qt.tint(root.surfaceColor, Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.22)) : root.surfaceColor
                    border.color: button.selected || mouse.containsMouse ? root.accentColor : root.edgeColor
                    border.width: button.selected ? Math.max(3, root.edgeWidth) : root.edgeWidth
                    // Vector icons stay sharp and do not depend on an icon font.
                    Canvas {
                        id: icon
                        width: 44; height: 44
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 22
                        property color ink: root.accentColor
                        onInkChanged: requestPaint()
                        onPaint: {
                            var c = getContext("2d"); c.reset();
                            c.strokeStyle = ink; c.lineWidth = 3;
                            c.lineCap = "round"; c.lineJoin = "round";
                            c.beginPath();
                            if (button.modelData.icon === "power") {
                                c.arc(22, 24, 16, -Math.PI / 2 + 0.6, Math.PI * 1.5 - 0.6);
                                c.moveTo(22, 3); c.lineTo(22, 22);
                            } else if (button.modelData.icon === "reboot") {
                                // Clockwise arc ending at the top, with a tangent-aligned arrowhead.
                                c.arc(22, 22, 16, -0.35, Math.PI * 1.5);
                                c.moveTo(16, 0); c.lineTo(22, 6); c.lineTo(16, 12);
                            } else if (button.modelData.icon === "lock") {
                                c.moveTo(12, 19); c.lineTo(12, 12);
                                c.arc(22, 12, 10, Math.PI, 2 * Math.PI);
                                c.lineTo(32, 19);
                                c.rect(7, 19, 30, 23);
                                c.moveTo(22, 28); c.lineTo(22, 34);
                            } else {
                                c.moveTo(20, 5); c.lineTo(6, 5); c.lineTo(6, 39); c.lineTo(20, 39);
                                c.moveTo(18, 22); c.lineTo(39, 22);
                                c.moveTo(31, 14); c.lineTo(39, 22); c.lineTo(31, 30);
                            }
                            c.stroke();
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 82
                        text: button.modelData.label
                        color: root.textColor
                        font.family: Config.Settings.value("shared", "PowerMenu", "font.family", "sans-serif")
                        font.pixelSize: Config.Settings.value("shared", "PowerMenu", "font.pixelSize", 24)
                        font.weight: Font.DemiBold
                    }
                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activate(button.index)
                    }
                }
            }
        }
    }
}
