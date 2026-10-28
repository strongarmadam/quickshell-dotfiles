import "." as Config
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    property var layoutManager
    property string widgetId
    readonly property bool drawerMember: ["cpu", "temperature", "memory", "network"].includes(widgetId)
    property real drawerProgress: !drawerMember || (layoutManager && layoutManager.drawerReady && layoutManager.monitorWidgetsShown) ? 1 : 0
    Behavior on drawerProgress { NumberAnimation { duration: 260; easing.type: Easing.InOutCubic } }
    property real defaultX: Config.Settings.value("Space Green", "MovableWidget", "defaultX", 20)
    property real defaultY: 50
    property real widgetX: defaultX
    property real widgetY: defaultY
    readonly property bool beingDragged: layoutManager !== null && layoutManager !== undefined
                                              && layoutManager.draggedWidget === root

    visible: Config.Settings.value("shared", "Visibility", widgetId, true) && layoutManager !== null && layoutManager !== undefined && layoutManager.ready
        && (!drawerMember || (layoutManager.drawerReady && (layoutManager.monitorWidgetsShown || drawerProgress > 0)))
    screen: Quickshell.screens[0] || null
    anchors { top: true; left: true }
    margins { left: Math.round(root.widgetX - (root.drawerMember ? (root.widgetX + root.width + 4) * (1 - root.drawerProgress) : 0)); top: Math.round(root.widgetY) }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "desktop-widget-" + widgetId
    color: "transparent"

    Component.onCompleted: {
        if (layoutManager) layoutManager.registerWidget(root);
    }
    Component.onDestruction: {
        if (layoutManager) layoutManager.unregisterWidget(root);
    }
    onVisibleChanged: {
        if (!visible && layoutManager) layoutManager.widgetHidden(root);
    }

    HoverHandler {
        id: hover
        onHoveredChanged: {
            if (root.layoutManager) root.layoutManager.hoverWidget(root.widgetId, hovered);
        }
        cursorShape: root.beingDragged ? Qt.ClosedHandCursor : Qt.ArrowCursor
    }

    Rectangle {
        anchors.fill: parent
        z: 100
        color: "transparent"
        border.color: Config.Settings.value("Space Green", "MovableWidget", "border.color", "#e5d8bd")
        border.width: root.beingDragged ? 2 : 0
        radius: Config.Settings.value("Space Green", "MovableWidget", "radius", 4)
        visible: root.beingDragged
    }
}
