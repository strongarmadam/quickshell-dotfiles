import QtQuick
import QtQuick.Controls
import QtQml.Models
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: popup
    required property var palette
    property var trayItem: null
    property var levels: []
    property var parentBar: null
    property var currentMenu: null
    property bool grabReady: false
    Timer { id: grabDelay; interval: 150; onTriggered: popup.grabReady = popup.visible }
    property real iconX: 0
    property real barBottom: 36
    function open(item, source, parentBar) {
        if (visible && trayItem === item) { visible = false; return; }
        visible = false;
        trayItem = item;
        popup.parentBar = parentBar;
        screen = parentBar.screen;
        const point = source.mapToItem(parentBar.contentItem, 0, source.height);
        iconX = point.x + source.width / 2;
        barBottom = point.y;
        levels = [item.menu];
        visible = true;
    }
    onTrayItemChanged: if (!trayItem && visible) visible = false
    visible: false
    anchors { top: true; left: true }
    margins { top: popup.barBottom + 6; left: Math.max(6, Math.min(popup.iconX - popup.implicitWidth / 2, (popup.screen ? popup.screen.width : 1920) - popup.implicitWidth - 6)) }
    implicitWidth: 280
    implicitHeight: Math.max(16, Math.min(content.implicitHeight + 16, (screen ? screen.height : 1080) - barBottom - 24))
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell-tray-menu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    onVisibleChanged: {
        if (visible) { surface.forceActiveFocus(); grabDelay.restart(); }
        else { grabDelay.stop(); grabReady = false; levels = []; trayItem = null; }
    }
    Connections {
        target: popup.trayItem
        function onHasMenuChanged() { if (!popup.trayItem.hasMenu) popup.visible = false; }
    }
    HyprlandFocusGrab {
        active: popup.visible && popup.grabReady
        windows: popup.parentBar ? [popup, popup.parentBar] : [popup]
        onCleared: popup.visible = false
    }
    Instantiator {
        id: menus
        model: popup.levels
        delegate: QsMenuOpener { required property var modelData; menu: modelData }
        onObjectAdded: (index, object) => { popup.currentMenu = object; }
        onObjectRemoved: (index, object) => { popup.currentMenu = count > 0 ? objectAt(count - 1) : null; }
    }
    Rectangle {
        id: surface
        anchors.fill: parent
        color: popup.palette.panelColor
        radius: popup.palette.cornerRadius
        border { color: popup.palette.edgeColor; width: Math.max(1, popup.palette.edgeWidth) }
        focus: true
        Keys.onEscapePressed: popup.visible = false
        ScrollView {
            anchors.fill: parent
            anchors.margins: 8
            clip: true
            contentWidth: availableWidth
            Column {
                id: content
                width: parent.width
                spacing: 2
                Button {
                    visible: popup.levels.length > 1
                    width: parent.width
                    height: visible ? 34 : 0
                    text: "‹ Back"
                    onClicked: popup.levels = popup.levels.slice(0, -1)
                    contentItem: Text { text: parent.text; color: popup.palette.textColor; font.family: popup.palette.themeFontFamily; verticalAlignment: Text.AlignVCenter; leftPadding: 10 }
                    background: Rectangle { color: parent.hovered ? popup.palette.buttonHoverColor : "transparent"; radius: popup.palette.barButtonRadius }
                }
                Repeater {
                    model: popup.currentMenu ? popup.currentMenu.children : null
                    delegate: Button {
                        id: row
                        required property var modelData
                        width: content.width
                        height: modelData.isSeparator ? 9 : 36
                        enabled: modelData.enabled && !modelData.isSeparator
                        hoverEnabled: true
                        onClicked: {
                            if (modelData.hasChildren) popup.levels = popup.levels.concat([modelData]);
                            else { modelData.triggered(); popup.visible = false; }
                        }
                        background: Rectangle {
                            color: row.hovered || row.visualFocus ? popup.palette.buttonHoverColor : "transparent"
                            radius: popup.palette.barButtonRadius
                            Rectangle { visible: row.modelData.isSeparator; anchors.centerIn: parent; width: parent.width - 16; height: 1; color: popup.palette.edgeColor }
                        }
                        contentItem: Row {
                            visible: !row.modelData.isSeparator
                            spacing: 8
                            opacity: row.enabled ? 1 : 0.45
                            Text { width: 18; anchors.verticalCenter: parent.verticalCenter; text: row.modelData.checkState === Qt.Checked ? "✓" : ""; color: popup.palette.accentColor }
                            Text {
                                width: row.width - 72
                                anchors.verticalCenter: parent.verticalCenter
                                text: row.modelData.text.replace(/\&(.)/g, "$1")
                                elide: Text.ElideRight
                                color: popup.palette.textColor
                                font { family: popup.palette.themeFontFamily; pixelSize: popup.palette.themeFontSize }
                            }
                            Text { anchors.verticalCenter: parent.verticalCenter; text: row.modelData.hasChildren ? "›" : ""; color: popup.palette.accentColor }
                        }
                    }
                }
            }
        }
    }
}
