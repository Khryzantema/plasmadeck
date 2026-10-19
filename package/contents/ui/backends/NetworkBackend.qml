/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.kitemmodels as KItemModels
import org.kde.plasma.networkmanagement as PlasmaNM
import org.kde.plasma.workspace.dbus as DBus

import "../components"

// Private API: org.kde.plasma.networkmanagement (plasma-nm).
// Wi-Fi, Ethernet (wired connections) and airplane mode.
Item {
    id: root
    visible: false

    // --- Overall state (panel icon, tooltip) ---
    readonly property string panelIcon: connectionIcon.connectionIcon ? connectionIcon.connectionIcon + "-symbolic" : ""
    readonly property string statusText: networkStatus.activeConnections
    readonly property bool connecting: connectionIcon.connecting

    // --- Wi-Fi ---
    readonly property bool wifiAvailable: availableDevices.wirelessDeviceAvailable
    readonly property bool wifiEnabled: enabledConnections.wirelessEnabled
    readonly property string wifiNetworkName: activeName(PlasmaNM.Enums.Wireless)

    // --- Ethernet ---
    readonly property bool wiredAvailable: availableDevices.wiredDeviceAvailable
    readonly property string wiredConnectionName: activeName(PlasmaNM.Enums.Wired)
    readonly property bool wiredConnected: wiredConnectionName !== ""

    // Same rule as the native Networks applet.
    readonly property bool airplaneModeAvailable: availableDevices.modemDeviceAvailable || availableDevices.wirelessDeviceAvailable
    readonly property bool airplaneMode: PlasmaNM.Configuration.airplaneModeEnabled

    readonly property Presence wifiPresence: Presence {
        available: root.wifiAvailable && nmWatcher.registered
        serviceUp: nmWatcher.registered
    }
    readonly property Presence wiredPresence: Presence {
        available: root.wiredAvailable && nmWatcher.registered
        serviceUp: nmWatcher.registered
    }
    readonly property Presence airplanePresence: Presence {
        available: root.airplaneModeAvailable && nmWatcher.registered
        serviceUp: nmWatcher.registered
    }

    // Connection types, for the sections of the network page.
    readonly property int typeWired: PlasmaNM.Enums.Wired
    readonly property int typeWireless: PlasmaNM.Enums.Wireless

    // Everything the network page lists: wired connections first, then Wi-Fi
    // networks (when Wi-Fi is on). Inside each group the order stays the one of
    // the native applet (active first, then known, then by signal), because the
    // sort by type is stable.
    readonly property KItemModels.KSortFilterProxyModel networks: KItemModels.KSortFilterProxyModel {
        sourceModel: appletProxyModel
        sortRoleName: "Type"
        sortOrder: Qt.AscendingOrder
        filterRowCallback: (sourceRow, sourceParent) => {
            const type = sourceModel.data(sourceModel.index(sourceRow, 0, sourceParent), KItemModels.KRoleNames.role("Type"));
            return type === PlasmaNM.Enums.Wired
                || (type === PlasmaNM.Enums.Wireless && root.wifiAvailable && root.wifiEnabled);
        }
    }

    onWifiEnabledChanged: networks.invalidateFilter()
    onWifiAvailableChanged: networks.invalidateFilter()

    // --- Actions ---

    function setWifiEnabled(enable) {
        handler.enableWireless(enable);
    }

    // Turning Ethernet on brings up the wired connection used most recently;
    // turning it off disconnects the active one.
    function setWiredConnected(enable) {
        const all = [];
        for (let i = 0; i < wiredConnections.count; i++) {
            all.push(wiredConnections.objectAt(i));
        }
        if (!enable) {
            all.filter(c => isActive(c.data)).forEach(c => toggleNetwork(c.data));
            return;
        }
        const known = all.filter(c => c.data.Uuid).sort((a, b) => b.lastUsed - a.lastUsed);
        if (known.length > 0) {
            toggleNetwork(known[0].data);
        }
    }

    function setAirplaneMode(enable) {
        handler.enableAirplaneMode(enable);
        PlasmaNM.Configuration.airplaneModeEnabled = enable;
    }

    function requestScan() {
        handler.requestScan();
    }

    // --- Helpers for list entries (model roles of plasma-nm's NetworkModel) ---

    function isWired(network) {
        return network.Type === PlasmaNM.Enums.Wired;
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

    // Name of the active connection of a given type, or "".
    function activeName(type) {
        const list = type === PlasmaNM.Enums.Wired ? wiredConnections : wifiConnections;
        for (let i = 0; i < list.count; i++) {
            const c = list.objectAt(i);
            if (c && c.data.ConnectionState === PlasmaNM.Enums.Activated) {
                return c.data.ItemUniqueName;
            }
        }
        return "";
    }

    // --- plasma-nm objects ---

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

    PlasmaNM.NetworkModel {
        id: networkModel
    }

    PlasmaNM.AppletProxyModel {
        id: appletProxyModel
        sourceModel: networkModel
    }

    DBus.DBusServiceWatcher {
        id: nmWatcher
        busType: DBus.BusType.System
        watchedService: "org.freedesktop.NetworkManager"
    }

    // Connections of one type, kept as objects so their roles can be read from JS.
    // (Inline components cannot see the ids of this file, so the model is passed in.)
    component ConnectionsOfType: Instantiator {
        id: connections
        property int type
        property var source
        model: KItemModels.KSortFilterProxyModel {
            sourceModel: connections.source
            filterRowCallback: (sourceRow, sourceParent) => sourceModel.data(sourceModel.index(sourceRow, 0, sourceParent), KItemModels.KRoleNames.role("Type")) === connections.type
        }
        delegate: QtObject {
            required property var model
            readonly property var data: model
            // Time of the last use (ms since the epoch), for picking a connection to bring up.
            readonly property real lastUsed: model.TimeStamp ? new Date(model.TimeStamp).getTime() : 0
        }
    }

    ConnectionsOfType {
        id: wiredConnections
        type: PlasmaNM.Enums.Wired
        source: networkModel
    }

    ConnectionsOfType {
        id: wifiConnections
        type: PlasmaNM.Enums.Wireless
        source: networkModel
    }
}
