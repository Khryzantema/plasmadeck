/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras

import "components"

// Network sub-page: Ethernet connections and Wi-Fi networks in sections
// (connect, disconnect, inline password for new protected Wi-Fi networks),
// the Wi-Fi switch when there is Wi-Fi, and a link to the settings.
SubPage {
    id: page

    required property Item network

    title: i18n("Network")
    iconName: network.wifiAvailable ? "network-wireless-symbolic" : "network-wired-symbolic"
    showSwitch: network.wifiAvailable
    switchLabel: i18n("Wi-Fi")
    checked: network.wifiEnabled
    // Wired connections stay listed while Wi-Fi is off.
    listVisible: true
    settingsModule: "kcm_networkmanagement"
    settingsLabel: i18n("All Networks Settings…")
    placeholderText: i18n("No networks found")
    model: network.networks

    sectionProperty: "Type"
    sectionDelegate: Kirigami.Heading {
        required property string section
        width: ListView.view ? ListView.view.width : implicitWidth
        topPadding: Kirigami.Units.smallSpacing
        level: 5
        opacity: 0.8
        text: Number(section) === page.network.typeWired ? i18n("Ethernet") : i18n("Wi-Fi")
    }

    onToggled: checked => network.setWifiEnabled(checked)

    // Keep the list fresh while the page is open, like the native applet.
    Timer {
        interval: 10000
        repeat: true
        triggeredOnStart: true
        running: page.visible && page.network.wifiAvailable && page.checked
        onTriggered: page.network.requestScan()
    }

    delegate: ColumnLayout {
        id: row

        required property var model
        required property int index

        readonly property bool active: page.network.isActive(model)
        readonly property bool connecting: page.network.isConnecting(model)
        readonly property bool wired: page.network.isWired(model)
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
                    source: row.wired ? (row.active ? "network-wired-activated-symbolic" : "network-wired-symbolic") : row.model.ConnectionIcon
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
                            return row.model.Uuid && !row.wired ? i18n("Saved") : "";
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
