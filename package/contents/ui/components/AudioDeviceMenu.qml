/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

// Device picker for the volume (outputs) or microphone (inputs) slider, like GNOME's sound menus.
Rectangle {
    id: menu

    required property Item audio
    // Which devices to list: output (sinks) or input (sources).
    property bool input: false

    implicitHeight: column.implicitHeight + Kirigami.Units.largeSpacing * 2
    radius: Kirigami.Units.cornerRadius * 2
    color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.06)

    component DeviceSection: ColumnLayout {
        id: section

        property string title
        property string iconName
        property var model

        spacing: 0
        visible: repeater.count > 0

        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                source: section.iconName
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
            }
            Kirigami.Heading {
                level: 5
                text: section.title
                Layout.fillWidth: true
            }
        }

        Repeater {
            id: repeater
            model: section.model
            delegate: PlasmaComponents3.ItemDelegate {
                id: deviceItem

                required property var model
                readonly property var device: model.PulseObject
                readonly property bool isDefault: device ? device.default : false

                Layout.fillWidth: true
                text: menu.audio.deviceName(device)
                highlighted: activeFocus

                Accessible.role: Accessible.RadioButton
                Accessible.checkable: true
                Accessible.checked: isDefault

                contentItem: RowLayout {
                    spacing: Kirigami.Units.smallSpacing
                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        text: deviceItem.text
                        elide: Text.ElideRight
                    }
                    Kirigami.Icon {
                        source: "object-select-symbolic"
                        visible: deviceItem.isDefault
                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    }
                }

                onClicked: menu.audio.setDefault(device)
            }
        }
    }

    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.largeSpacing

        DeviceSection {
            Layout.fillWidth: true
            title: menu.input ? i18n("Sound Input") : i18n("Sound Output")
            iconName: menu.input ? "audio-input-microphone-symbolic" : "audio-speakers-symbolic"
            model: menu.input ? menu.audio.sources : menu.audio.sinks
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: !menu.input
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Separator {
                Layout.fillWidth: true
            }

            PlasmaComponents3.Switch {
                Layout.fillWidth: true
                text: i18n("Raise maximum volume")
                checked: menu.audio.raiseMaximumVolume
                onToggled: menu.audio.setRaiseMaximumVolume(checked)
            }

            // Same warning as Plasma's Audio Volume applet.
            PlasmaComponents3.Label {
                Layout.fillWidth: true
                visible: menu.audio.raiseMaximumVolume
                text: i18n("Prolonged use of this feature will damage the device's speakers. Only use it temporarily to make quiet media audible.")
                wrapMode: Text.Wrap
                font: Kirigami.Theme.smallFont
                color: Kirigami.Theme.neutralTextColor
            }
        }
    }
}
