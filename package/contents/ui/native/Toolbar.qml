/*
    SPDX-FileCopyrightText: 2013-2017 Jan Grulich <jgrulich@redhat.com>

    SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
*/

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.networkmanagement as PlasmaNM
import org.kde.kcmutils as KCMUtils

RowLayout {
    id: toolbar

    // The Wi-Fi, mobile data and airplane mode switches are not shown in PlasmaDeck (they have their
    // own toggles), so these messages only follow the state of the radios.
    readonly property var displayWifiOffMessage: availableDevices.wirelessDeviceAvailable && !enabledConnections.wirelessEnabled
    readonly property var displayWifiConnectingMessage: availableDevices.wirelessDeviceAvailable && enabledConnections.wirelessEnabled && searchTextField.text.length === 0
    readonly property var displayWwanMessage: availableDevices.modemDeviceAvailable && !enabledConnections.wwanEnabled
    readonly property var displayplaneModeMessage: PlasmaNM.Configuration.airplaneModeEnabled && (availableDevices.modemDeviceAvailable || availableDevices.wirelessDeviceAvailable)

    property bool hasConnections
    property alias searchTextField: searchTextField

    PlasmaNM.EnabledConnections {
        id: enabledConnections

    }

    PlasmaNM.QrcaHandler {
        id: qrca
    }

    spacing: Kirigami.Units.smallSpacing

    PlasmaComponents3.ToolButton {
        id: hotspotButton

        visible: availableDevices.wirelessDeviceAvailable
        enabled: handler.hotspotSupported
        checkable: true
        checked: handler.hotspotActive

        text: i18n("Hotspot")
        display: PlasmaComponents3.AbstractButton.IconOnly
        icon.name: "network-wireless-hotspot"

        KeyNavigation.right: searchTextField

        onClicked: {
            if (PlasmaNM.Configuration.hotspotConnectionPath) {
                handler.stopHotspot()
            } else {
                handler.createHotspot()
            }
        }

        PlasmaComponents3.ToolTip {
            text: {
                if (!enabledConnections.wirelessEnabled) {
                    return i18nc("@info:tooltip", "Cannot create a hotspot because Wi-Fi is disabled.")
                } else if (!handler.hotspotSupported) {
                    return i18nc("@info:tooltip", "Cannot create a hotspot because all wireless radios are in use. Disconnect from the current Wi-Fi network or connect another wireless radio.")
                } else if (handler.hotspotActive) {
                    return i18nc("@info:tooltip", "Disable Hotspot");
                } else {
                    return i18nc("@info:tooltip", "Create Hotspot");
                }
            }
        }
    }

    PlasmaExtras.SearchField {
        id: searchTextField

        Layout.fillWidth: true

        enabled: toolbar.hasConnections || text.length > 0

        // This uses expanded to ensure the binding gets reevaluated
        // when the plasmoid is shown again and that way ensure we are
        // always in the correct state on show.
        focus: mainWindow.expanded && !Kirigami.InputMethod.willShowOnActive

        KeyNavigation.left: hotspotButton.visible ? hotspotButton : hotspotButton.KeyNavigation.left
        KeyNavigation.right: openEditorButton

        onTextChanged: {
            appletProxyModel.setFilterFixedString(text)
        }
    }

    PlasmaComponents3.ToolButton {
        icon.name: "view-barcode-qr"
        text: i18nc("@action:button", "Scan Wi-Fi QR Code")
        enabled: qrca.available
        display: PlasmaComponents3.ToolButton.IconOnly
        Accessible.description: {
            if (qrca.available) {
                return i18nc("@info:tooltip", "Scan QR Code to connect to a Wi-Fi network");
            } else {
                return i18nc("@info:tooltip", "Install QRCA Barcode Scanner to scan for a QR Code that connects to a Wi-Fi network")
            }
        }

        PlasmaComponents3.ToolTip {
            text: parent.Accessible.description
        }

        onClicked: qrca.launch()
    }

    PlasmaComponents3.ToolButton {
        id: openEditorButton

        visible: mainWindow.kcmAuthorized

        icon.name: "configure"

        PlasmaComponents3.ToolTip {
            text: i18n("Configure network connections…")
        }

        onClicked: {
            KCMUtils.KCMLauncher.openSystemSettings(mainWindow.kcm)
        }
    }
}
