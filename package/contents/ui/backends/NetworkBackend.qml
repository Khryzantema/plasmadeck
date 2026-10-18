/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.kitemmodels as KItemModels
import org.kde.plasma.networkmanagement as PlasmaNM
import org.kde.plasma.workspace.dbus as DBus

import "../components"

// Private API: org.kde.plasma.networkmanagement (plasma-nm).
Item {
    id: root
    visible: false

    readonly property string panelIcon: connectionIcon.connectionIcon ? connectionIcon.connectionIcon + "-symbolic" : ""
    readonly property string statusText: networkStatus.activeConnections
    readonly property bool connecting: connectionIcon.connecting

    readonly property bool wifiAvailable: availableDevices.wirelessDeviceAvailable
    readonly property bool wifiEnabled: enabledConnections.wirelessEnabled
    readonly property string wifiNetworkName: activeWifi.count > 0 ? (activeWifi.objectAt(0)?.name ?? "") : ""

    // Same rule as the native Networks applet.
    readonly property bool airplaneModeAvailable: availableDevices.modemDeviceAvailable || availableDevices.wirelessDeviceAvailable
    readonly property bool airplaneMode: PlasmaNM.Configuration.airplaneModeEnabled

    // Wireless networks, sorted like the native applet (active first, then known, then by signal).
    readonly property KItemModels.KSortFilterProxyModel wifiNetworks: KItemModels.KSortFilterProxyModel {
        sourceModel: root.wifiAvailable ? appletProxyModel : null
        filterRowCallback: (sourceRow, sourceParent) => {
            const index = sourceModel.index(sourceRow, 0, sourceParent);
            return sourceModel.data(index, KItemModels.KRoleNames.role("Type")) === PlasmaNM.Enums.Wireless;
        }
    }

    readonly property Presence wifiPresence: Presence {
        available: root.wifiAvailable && nmWatcher.registered
        serviceUp: nmWatcher.registered
    }
    readonly property Presence airplanePresence: Presence {
        available: root.airplaneModeAvailable && nmWatcher.registered
        serviceUp: nmWatcher.registered
    }

    DBus.DBusServiceWatcher {
        id: nmWatcher
        busType: DBus.BusType.System
        watchedService: "org.freedesktop.NetworkManager"
    }

    function setWifiEnabled(enable) {
        handler.enableWireless(enable);
    }

    function requestScan() {
        handler.requestScan();
    }

    function isSecured(securityType) {
        // OWE ("Enhanced Open") is encrypted but needs no password.
        return securityType !== PlasmaNM.Enums.NoneSecurity && securityType !== PlasmaNM.Enums.UnknownSecurity
            && securityType !== PlasmaNM.Enums.OWE;
    }

    // Same decision tree as the native ConnectionItem. Returns true when a password is needed first.
    function needsPassword(network) {
        return !network.Uuid && isSecured(network.SecurityType) && network.ConnectionState === PlasmaNM.Enums.Deactivated;
    }

    function isConnecting(network) {
        return network.ConnectionState === PlasmaNM.Enums.Activating;
    }

    function isActive(network) {
        return network.ConnectionState === PlasmaNM.Enums.Activated || network.ConnectionState === PlasmaNM.Enums.Activating;
    }

    function toggleNetwork(network, password) {
        if (isActive(network)) {
            handler.deactivateConnection(network.ConnectionPath, network.DevicePath);
        } else if (network.Uuid) {
            handler.activateConnection(network.ConnectionPath, network.DevicePath, network.SpecificPath);
        } else if (password !== undefined) {
            handler.addAndActivateConnection(network.DevicePath, network.SpecificPath, password);
        } else {
            handler.addAndActivateConnection(network.DevicePath, network.SpecificPath);
        }
    }

    PlasmaNM.AppletProxyModel {
        id: appletProxyModel
        sourceModel: networkModel
    }

    function setAirplaneMode(enable) {
        handler.enableAirplaneMode(enable);
        PlasmaNM.Configuration.airplaneModeEnabled = enable;
    }

    PlasmaNM.NetworkStatus {
        id: networkStatus
    }

    PlasmaNM.ConnectionIcon {
        id: connectionIcon
        connectivity: networkStatus.connectivity
    }

    PlasmaNM.AvailableDevices {
        id: availableDevices
    }

    PlasmaNM.EnabledConnections {
        id: enabledConnections
    }

    PlasmaNM.Handler {
        id: handler
    }

    // The model is only needed to name the active Wi-Fi network.
    PlasmaNM.NetworkModel {
        id: networkModel
    }

    KItemModels.KSortFilterProxyModel {
        id: activeWifiModel
        sourceModel: root.wifiAvailable ? networkModel : null
        filterRowCallback: (sourceRow, sourceParent) => {
            const index = sourceModel.index(sourceRow, 0, sourceParent);
            return sourceModel.data(index, KItemModels.KRoleNames.role("Type")) === PlasmaNM.Enums.Wireless
                && sourceModel.data(index, KItemModels.KRoleNames.role("ConnectionState")) === PlasmaNM.Enums.Activated;
        }
    }

    Instantiator {
        id: activeWifi
        model: activeWifiModel
        delegate: QtObject {
            readonly property string name: model.ItemUniqueName
        }
    }
}
