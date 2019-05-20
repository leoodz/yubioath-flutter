import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

ColumnLayout {

    readonly property int dynamicWidth: 420
    readonly property int dynamicMargin: 64

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter

    ColumnLayout {
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        Layout.topMargin: -125

        StyledImage {
            source: "../images/people.svg"
            color: app.isDark() ? defaultLightForeground : defaultLightOverlay
            iconWidth: 80
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        }

        Label {
            text: "No credentials"
            Layout.rowSpan: 1
            wrapMode: Text.WordWrap
            font.pixelSize: 13
            font.bold: true
            lineHeight: 1.5
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        }

        Label {
            text: "This YubiKey contains no credentials."
            horizontalAlignment: Qt.AlignHCenter
            Layout.minimumWidth: 320
            Layout.maximumWidth: app.width - dynamicMargin
                                 < dynamicWidth ? app.width - dynamicMargin : dynamicWidth
            Layout.rowSpan: 1
            lineHeight: 1.2
            wrapMode: Text.WordWrap
            font.pixelSize: 13
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        }

        StyledButton {
            id: addBtn
            text: "Add"
            enabled: true
            focus: true
            Layout.alignment: Qt.AlignCenter | Qt.AlignVCenter
            onClicked: yubiKey.scanQr()
            Keys.onReturnPressed: yubiKey.scanQr()
            Keys.onEnterPressed: yubiKey.scanQr()
        }
    }
}
