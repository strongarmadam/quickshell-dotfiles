import "." as Config
import QtQuick

Rectangle {
    id: root

    property color glassColor: Config.Settings.value("Bakery Hearth", "Glass", "glassColor", "#2b1b14")
    property color glassBorder: Config.Settings.value("Bakery Hearth", "Glass", "glassBorder", "#b58c6b")
    radius: Config.Settings.value("Bakery Hearth", "Glass", "radius", 4)
    color: glassColor
    opacity: Config.Settings.value("Bakery Hearth", "Glass", "opacity", 0.72)
    border.color: glassBorder
    border.width: Config.Settings.value("Bakery Hearth", "Glass", "border.width", 1)
    Rectangle {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        height: Config.Settings.value("Bakery Hearth", "Glass", "height", 1)
        radius: Config.Settings.value("Bakery Hearth", "Glass", "radius_2", 1)
        color: Config.Settings.value("Bakery Hearth", "Glass", "color", "#fce3c1")
        opacity: Config.Settings.value("Bakery Hearth", "Glass", "opacity_2", 0.10)
    }
}
