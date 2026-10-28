import "." as Config
import QtQuick

Rectangle {
    id: root

    property color glassColor: Config.Settings.value("Coral Lagoon", "Glass", "glassColor", "#062b40")
    property color glassBorder: Config.Settings.value("Coral Lagoon", "Glass", "glassBorder", "#6bbacb")
    radius: Math.min(width, height) / 2
    color: glassColor
    opacity: Config.Settings.value("Coral Lagoon", "Glass", "opacity", 0.72)
    border.color: glassBorder
    border.width: Config.Settings.value("Coral Lagoon", "Glass", "border.width", 1)
    Rectangle {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        height: Config.Settings.value("Coral Lagoon", "Glass", "height", 1)
        radius: Config.Settings.value("Coral Lagoon", "Glass", "radius_2", 1)
        color: Config.Settings.value("Coral Lagoon", "Glass", "color", "#e5f6ff")
        opacity: Config.Settings.value("Coral Lagoon", "Glass", "opacity_2", 0.10)
    }
}
