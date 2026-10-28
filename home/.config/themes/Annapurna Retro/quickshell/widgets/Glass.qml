import "." as Config
import QtQuick

Rectangle {
    id: root

    property color glassColor: Config.Settings.value("Annapurna Retro", "Glass", "glassColor", "#10354d")
    property color glassBorder: Config.Settings.value("Annapurna Retro", "Glass", "glassBorder", "#ffffff")
    radius: Config.Settings.value("Annapurna Retro", "Glass", "radius", 0)
    color: glassColor
    opacity: Config.Settings.value("Annapurna Retro", "Glass", "opacity", 0.72)
    border.color: glassBorder
    border.width: Config.Settings.value("Annapurna Retro", "Glass", "border.width", 3)
    Rectangle {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        height: Config.Settings.value("Annapurna Retro", "Glass", "height", 1)
        radius: Config.Settings.value("Annapurna Retro", "Glass", "radius_2", 0)
        color: Config.Settings.value("Annapurna Retro", "Glass", "color", "#f1faff")
        opacity: Config.Settings.value("Annapurna Retro", "Glass", "opacity_2", 0.10)
    }
}
