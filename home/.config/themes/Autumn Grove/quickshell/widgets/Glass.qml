import "." as Config
import QtQuick

Rectangle {
    id: root

    property color glassColor: Config.Settings.value("Autumn Grove", "Glass", "glassColor", "#241b16")
    property color glassBorder: Config.Settings.value("Autumn Grove", "Glass", "glassBorder", "#a89270")
    radius: Config.Settings.value("Autumn Grove", "Glass", "radius", 18)
    color: glassColor
    opacity: Config.Settings.value("Autumn Grove", "Glass", "opacity", 0.72)
    border.color: glassBorder
    border.width: Config.Settings.value("Autumn Grove", "Glass", "border.width", 1)
    Rectangle {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        height: Config.Settings.value("Autumn Grove", "Glass", "height", 1)
        radius: Config.Settings.value("Autumn Grove", "Glass", "radius_2", 1)
        color: Config.Settings.value("Autumn Grove", "Glass", "color", "#e5d8bd")
        opacity: Config.Settings.value("Autumn Grove", "Glass", "opacity_2", 0.10)
    }
}
