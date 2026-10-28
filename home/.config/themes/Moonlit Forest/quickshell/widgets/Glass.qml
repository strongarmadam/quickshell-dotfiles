import "." as Config
import QtQuick

Rectangle {
    id: root

    property color glassColor: Config.Settings.value("Moonlit Forest", "Glass", "glassColor", "#030609")
    property color glassBorder: Config.Settings.value("Moonlit Forest", "Glass", "glassBorder", "#155779")
    radius: Config.Settings.value("Moonlit Forest", "Glass", "radius", 18)
    color: glassColor
    opacity: Config.Settings.value("Moonlit Forest", "Glass", "opacity", 0.72)
    border.color: glassBorder
    border.width: Config.Settings.value("Moonlit Forest", "Glass", "border.width", 1)
    Rectangle {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        height: Config.Settings.value("Moonlit Forest", "Glass", "height", 1)
        radius: Config.Settings.value("Moonlit Forest", "Glass", "radius_2", 1)
        color: Config.Settings.value("Moonlit Forest", "Glass", "color", "#d7f3ff")
        opacity: Config.Settings.value("Moonlit Forest", "Glass", "opacity_2", 0.10)
    }
}
