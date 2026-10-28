import "." as Config
import QtQuick
import QtQuick.Controls
Rectangle {
    id: root
    required property var palette
    property string tooltip: ""
    property string label: ""
    property bool selected: false
    property bool boxed: false
    property bool occupied: false
    property color labelColor: root.palette.textColor
    signal clicked()
    signal middleClicked()
    signal rightClicked()
    signal scrolled(int direction)
    implicitWidth: Math.max(30, caption.implicitWidth + 20)
    implicitHeight: Config.Settings.value("shared", "UiButton", "implicitHeight", 28)
    radius: Math.min(width, height) / 2
    border.width: boxed ? Math.max(1, root.palette.edgeWidth) : 0
    border.color: selected ? root.palette.accentColor : root.palette.edgeColor
    color: root.palette.ringAccents ? (mouse.containsMouse || selected ? Qt.tint(root.palette.surfaceColor, "#18efb957") : root.palette.surfaceColor) : selected ? root.palette.accentColor : mouse.containsMouse ? Qt.tint(root.palette.panelColor, "#30ffffff") : boxed ? root.palette.surfaceColor : "transparent"
    Text { id: caption; anchors.centerIn: parent; text: root.label; color: root.palette.ringAccents && root.selected ? root.palette.accentColor : root.selected ? root.palette.panelColor : root.labelColor; font { family: "JetBrainsMono Nerd Font"; pixelSize: 12; bold: true } }
    Rectangle { visible: root.occupied; width: 4; height: 4; radius: 2; anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 3 }
        color: root.selected && !root.palette.ringAccents ? root.palette.panelColor : root.palette.accentColor }
    ToolTip.visible: mouse.containsMouse && tooltip.length > 0
    ToolTip.text: tooltip
    ToolTip.delay: 500
    MouseArea {
        id: mouse; anchors.fill: parent; hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: event => { if (event.button === Qt.RightButton) root.rightClicked(); else if (event.button === Qt.MiddleButton) root.middleClicked(); else root.clicked(); }
        onWheel: event => root.scrolled(event.angleDelta.y > 0 ? 1 : -1)
    }
}
