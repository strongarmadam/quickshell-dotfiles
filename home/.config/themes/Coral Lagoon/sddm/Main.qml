import QtQuick
import QtQuick.Controls.Basic as Controls

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: backgroundColor

    readonly property string themeName: config.ThemeName || "Sign in"
    readonly property color backgroundColor: config.BackgroundColor || "#042235"
    readonly property color panelColor: config.PanelColor || "#062b40"
    readonly property color outlineColor: config.OutlineColor || "#6bbacb"
    readonly property color textColor: config.TextColor || "#e5f6ff"
    readonly property color accentColor: config.AccentColor || "#cfb5ef"
    readonly property color buttonColor: config.ButtonColor || "#efb957"
    readonly property color errorColor: config.ErrorColor || "#efb957"
    readonly property int panelRadius: Number(config.PanelRadius || 0)
    readonly property int controlRadius: Number(config.ControlRadius || 0)
    readonly property int edgeWidth: Number(config.EdgeWidth || 1)
    property bool authenticating: false
    property string errorText: ""

    function tint(color, opacity) { return Qt.rgba(color.r, color.g, color.b, opacity); }
    function submit() {
        if (authenticating || !userField.text.trim() || sessions.currentIndex < 0) return;
        errorText = "";
        authenticating = true;
        sddm.login(userField.text.trim(), passwordField.text, sessions.currentIndex);
    }

    Image {
        id: wallpaperImage
        anchors.fill: parent
        source: Qt.resolvedUrl(config.Wallpaper || "wallpaper.jpg")
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
    }
    Rectangle {
        anchors.fill: parent
        color: root.tint(root.backgroundColor, 0.16)
    }

    component GlassButton: Controls.Button {
        id: button
        property bool primary: false
        property bool small: false
        implicitWidth: small ? 72 : 80
        implicitHeight: small ? 24 : 28
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: small ? 9 : 10
        font.bold: true
        padding: 4
        hoverEnabled: true
        background: GlassSurface {
            wallpaper: wallpaperImage
            tint: button.primary ? root.buttonColor : root.panelColor
            tintOpacity: button.down ? 0.88 : button.hovered || button.activeFocus ? 0.78 : button.primary ? 0.65 : 0.52
            outline: button.hovered || button.activeFocus ? root.accentColor : root.outlineColor
            cornerRadius: root.controlRadius
            edgeWidth: root.edgeWidth
        }
        contentItem: Text {
            text: button.text
            font: button.font
            color: root.textColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            opacity: button.enabled ? 1 : 0.45
        }
    }

    GlassSurface {
        id: loginPanel
        width: Math.min(260, root.width - 32)
        height: 178
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: root.height > 480 ? -28 : 0
        wallpaper: wallpaperImage
        tint: root.panelColor
        outline: root.outlineColor
        tintOpacity: 0.70
        cornerRadius: root.panelRadius
        edgeWidth: root.edgeWidth

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 8
            Text {
                width: parent.width
                text: root.themeName
                color: root.accentColor
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                font.bold: true
                elide: Text.ElideRight
            }
            Controls.TextField {
                id: userField
                width: parent.width
                height: 28
                text: userModel.lastUser
                placeholderText: "Username"
                color: root.textColor
                placeholderTextColor: root.tint(root.textColor, 0.55)
                selectionColor: root.tint(root.accentColor, 0.40)
                selectedTextColor: root.textColor
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                leftPadding: 9
                rightPadding: 9
                enabled: !root.authenticating
                background: GlassSurface {
                    wallpaper: wallpaperImage
                    tint: root.backgroundColor
                    tintOpacity: 0.48
                    outline: userField.activeFocus ? root.accentColor : root.outlineColor
                    cornerRadius: root.controlRadius
                    edgeWidth: root.edgeWidth
                }
                onAccepted: passwordField.forceActiveFocus()
                KeyNavigation.tab: passwordField
                Accessible.name: "Username"
            }
            Controls.TextField {
                id: passwordField
                width: parent.width
                height: 28
                placeholderText: "Password"
                echoMode: TextInput.Password
                passwordCharacter: "●"
                color: root.textColor
                placeholderTextColor: root.tint(root.textColor, 0.55)
                selectionColor: root.tint(root.accentColor, 0.40)
                selectedTextColor: root.textColor
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                leftPadding: 9
                rightPadding: 9
                enabled: !root.authenticating
                background: GlassSurface {
                    wallpaper: wallpaperImage
                    tint: root.backgroundColor
                    tintOpacity: 0.48
                    outline: passwordField.activeFocus ? root.accentColor : root.outlineColor
                    cornerRadius: root.controlRadius
                    edgeWidth: root.edgeWidth
                }
                onAccepted: root.submit()
                KeyNavigation.tab: sessions
                Accessible.name: "Password"
            }
            Row {
                width: parent.width
                spacing: 8
                Controls.ComboBox {
                    id: sessions
                    width: parent.width - loginButton.width - parent.spacing
                    height: 28
                    model: sessionModel
                    textRole: "name"
                    currentIndex: Math.max(0, sessionModel.lastIndex)
                    enabled: !root.authenticating && count > 1
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 9
                    leftPadding: 8
                    rightPadding: 17
                    background: GlassSurface {
                        wallpaper: wallpaperImage
                        tint: root.backgroundColor
                        tintOpacity: 0.40
                        outline: sessions.activeFocus ? root.accentColor : root.outlineColor
                        cornerRadius: root.controlRadius
                        edgeWidth: root.edgeWidth
                    }
                    contentItem: Text {
                        text: sessions.displayText
                        font: sessions.font
                        color: root.textColor
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                    indicator: Text {
                        x: sessions.width - 15
                        anchors.verticalCenter: parent.verticalCenter
                        text: "⌄"
                        color: root.accentColor
                        font.pixelSize: 12
                        visible: sessions.count > 1
                    }
                    delegate: Controls.ItemDelegate {
                        width: sessions.width
                        text: model.name
                        font: sessions.font
                        contentItem: Text {
                            text: parent.text
                            font: parent.font
                            color: root.textColor
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: parent.highlighted || parent.hovered ? root.tint(root.accentColor, 0.22) : "transparent"
                            radius: root.controlRadius
                        }
                        highlighted: sessions.highlightedIndex === index
                    }
                    popup: Controls.Popup {
                        y: sessions.height + 4
                        width: sessions.width
                        padding: 4
                        implicitHeight: Math.min(160, contentItem.implicitHeight + 8)
                        background: GlassSurface {
                            wallpaper: wallpaperImage
                            tint: root.panelColor
                            tintOpacity: 0.86
                            outline: root.outlineColor
                            cornerRadius: root.controlRadius
                            edgeWidth: root.edgeWidth
                        }
                        contentItem: ListView {
                            clip: true
                            implicitHeight: contentHeight
                            model: sessions.popup.visible ? sessions.delegateModel : null
                            currentIndex: sessions.highlightedIndex
                            Controls.ScrollIndicator.vertical: Controls.ScrollIndicator {}
                        }
                    }
                    KeyNavigation.tab: loginButton
                    Accessible.name: "Desktop session"
                }
                GlassButton {
                    id: loginButton
                    width: 80
                    height: 28
                    text: root.authenticating ? "WAIT…" : "SIGN IN"
                    primary: true
                    enabled: !root.authenticating && userField.text.trim().length > 0 && sessions.currentIndex >= 0
                    onClicked: root.submit()
                    KeyNavigation.tab: userField
                }
            }
            Text {
                width: parent.width
                height: 12
                text: root.errorText || (root.authenticating ? "Signing in…" : keyboard.capsLock ? "Caps Lock is on" : "")
                color: root.errorText ? root.errorColor : root.accentColor
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 9
                elide: Text.ElideRight
            }
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 18
        spacing: 8
        GlassButton {
            small: true
            text: "REBOOT"
            visible: sddm.canReboot
            onClicked: sddm.reboot()
            Accessible.name: "Reboot"
        }
        GlassButton {
            small: true
            text: "SHUTDOWN"
            visible: sddm.canPowerOff
            onClicked: sddm.powerOff()
            Accessible.name: "Shutdown"
        }
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.authenticating = false;
            root.errorText = "Sign-in failed. Try again.";
            passwordField.clear();
            passwordField.forceActiveFocus();
        }
        function onLoginSucceeded() { root.errorText = ""; }
    }
    Component.onCompleted: passwordField.forceActiveFocus()
}
