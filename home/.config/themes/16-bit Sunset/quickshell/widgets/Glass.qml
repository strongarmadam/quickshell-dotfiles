import "." as Config
import QtQuick

Rectangle {
    id: root

    property color glassColor: Config.Settings.value("16-bit Sunset", "Glass", "glassColor", "#241b16")
    property color glassBorder: Config.Settings.value("16-bit Sunset", "Glass", "glassBorder", "#a89270")
    radius: Config.Settings.value("16-bit Sunset", "Glass", "radius", 18)
    color: glassColor
    opacity: Config.Settings.value("16-bit Sunset", "Glass", "opacity", 0.72)
    border.color: glassBorder
    border.width: Config.Settings.value("16-bit Sunset", "Glass", "border.width", 1)
    Rectangle {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        height: Config.Settings.value("16-bit Sunset", "Glass", "height", 1)
        radius: Config.Settings.value("16-bit Sunset", "Glass", "radius_2", 1)
        color: Config.Settings.value("16-bit Sunset", "Glass", "color", "#e5d8bd")
        opacity: Config.Settings.value("16-bit Sunset", "Glass", "opacity_2", 0.10)
    }
}
