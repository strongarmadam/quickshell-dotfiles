import "." as Config
import QtQuick

Rectangle {
    id: root

    property color glassColor: Config.Settings.value("Rivendell", "Glass", "glassColor", "#1e241c")
    property color glassBorder: Config.Settings.value("Rivendell", "Glass", "glassBorder", "#76674b")
    radius: Config.Settings.value("Rivendell", "Glass", "radius", 18)
    color: glassColor
    opacity: Config.Settings.value("Rivendell", "Glass", "opacity", 0.72)
    border.color: glassBorder
    border.width: Config.Settings.value("Rivendell", "Glass", "border.width", 1)
    Rectangle {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        height: Config.Settings.value("Rivendell", "Glass", "height", 1)
        radius: Config.Settings.value("Rivendell", "Glass", "radius_2", 1)
        color: Config.Settings.value("Rivendell", "Glass", "color", "#e2dcc5")
        opacity: Config.Settings.value("Rivendell", "Glass", "opacity_2", 0.10)
    }
}
