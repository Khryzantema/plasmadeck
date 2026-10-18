/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras

import "components"

// Wi-Fi sub-page: on/off switch, the list of networks (connect, disconnect,
// inline password for new protected networks) and a link to the settings.
SubPage {
    id: page

    required property Item network

    title: i18n("Wi-Fi")
    iconName: "network-wireless-symbolic"
    checked: network.wifiEnabled
    settingsModule: "kcm_networkmanagement"
    settingsLabel: i18n("All Networks Settings…")
    placeholderText: i18n("No networks found")
    model: network.wifiNetworks

    onToggled: checked => network.setWifiEnabled(checked)

    // Keep the list fresh while the page is open, like the native applet.
    Timer {
        interval: 10000
        repeat: true
        triggeredOnStart: true
        running: page.visible && page.checked
        onTriggered: page.network.requestScan()
    }

    delegate: ColumnLayout {
        id: row

        required property var model
        required property int index

        readonly property bool active: page.network.isActive(model)
        readonly property bool connecting: page.network.isConnecting(model)
        property bool askingPassword: false

        width: ListView.view.width
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents3.ItemDelegate {
            id: item
            Layout.fillWidth: true
            highlighted: activeFocus || row.ListView.isCurrentItem && row.ListView.view.activeFocus

            Accessible.name: row.model.ItemUniqueName
            Accessible.description: status.text

            onClicked: {
                if (page.network.needsPassword(row.model)) {
                    row.askingPassword = !row.askingPassword;
                } else {
                    page.network.toggleNetwork(row.model);
                }
            }
            Keys.onReturnPressed: clicked()
            Keys.onEnterPressed: clicked()

            contentItem: RowLayout {
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source: row.model.ConnectionIcon
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        text: row.model.ItemUniqueName
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                        font.weight: row.active ? Font.DemiBold : Font.Normal
                    }
                    PlasmaComponents3.Label {
                        id: status
                        Layout.fillWidth: true
                        visible: text.length > 0
                        font: Kirigami.Theme.smallFont
                        opacity: 0.7
                        elide: Text.ElideRight
                        text: {
                            if (row.connecting) {
                                return i18n("Connecting…");
                            }
                            if (row.active) {
                                return i18n("Connected");
                            }
                            return row.model.Uuid ? i18n("Saved") : "";
                        }
                    }
                }

                PlasmaComponents3.BusyIndicator {
                    visible: row.connecting
                    running: visible
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                }

                Kirigami.Icon {
                    visible: row.active && !row.connecting
                    source: "object-select-symbolic"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing
            visible: row.askingPassword

            PlasmaExtras.PasswordField {
                id: passwordField
                Layout.fillWidth: true
                placeholderText: i18n("Password")
                Accessible.name: i18n("Password for %1", row.model.ItemUniqueName)
                onVisibleChanged: if (visible) forceActiveFocus()
                onAccepted: connectButton.clicked()
                Keys.onEscapePressed: event => {
                    row.askingPassword = false;
                    item.forceActiveFocus();
                    event.accepted = true;
                }
            }

            PlasmaComponents3.Button {
                id: connectButton
                text: i18n("Connect")
                enabled: passwordField.text.length > 0
                onClicked: {
                    page.network.toggleNetwork(row.model, passwordField.text);
                    passwordField.clear();
                    row.askingPassword = false;
                }
            }
        }
    }
}
