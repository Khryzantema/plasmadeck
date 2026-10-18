/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

import "components"

// Bluetooth sub-page: on/off switch, paired devices (connect/disconnect with
// progress and battery level) and a link to the settings.
SubPage {
    id: page

    required property Item bluetooth

    title: i18n("Bluetooth")
    iconName: "network-bluetooth-symbolic"
    checked: bluetooth.powered
    settingsModule: "kcm_bluetooth"
    settingsLabel: i18n("Bluetooth Settings…")
    placeholderText: i18n("No paired devices")
    model: bluetooth.pairedDevices

    onToggled: checked => bluetooth.setEnabled(checked)

    delegate: PlasmaComponents3.ItemDelegate {
        id: item

        required property var model
        required property int index

        property bool busy: false

        width: ListView.view.width
        highlighted: activeFocus || ListView.isCurrentItem && ListView.view.activeFocus

        Accessible.name: model.Name
        Accessible.description: status.text

        onClicked: {
            if (busy) {
                return;
            }
            busy = true;
            const call = page.bluetooth.toggleDevice(model.Device);
            call.finished.connect(() => {
                busy = false;
                if (call.error) {
                    console.warn("PlasmaDeck: Bluetooth", model.Name, call.errorText);
                }
            });
        }
        Keys.onReturnPressed: clicked()
        Keys.onEnterPressed: clicked()

        contentItem: RowLayout {
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                source: item.model.Icon
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    text: item.model.Name
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    font.weight: item.model.Connected ? Font.DemiBold : Font.Normal
                }
                PlasmaComponents3.Label {
                    id: status
                    Layout.fillWidth: true
                    font: Kirigami.Theme.smallFont
                    opacity: 0.7
                    elide: Text.ElideRight
                    text: {
                        if (item.busy) {
                            return item.model.Connected ? i18n("Disconnecting…") : i18n("Connecting…");
                        }
                        const battery = item.model.Device?.battery;
                        if (item.model.Connected) {
                            return battery ? i18n("Connected · %1% battery", battery.percentage) : i18n("Connected");
                        }
                        return i18n("Not connected");
                    }
                }
            }

            PlasmaComponents3.BusyIndicator {
                visible: item.busy
                running: visible
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
            }

            Kirigami.Icon {
                visible: item.model.Connected && !item.busy
                source: "object-select-symbolic"
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
            }
        }
    }
}
