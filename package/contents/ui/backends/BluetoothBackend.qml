/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.bluezqt as BluezQt
import org.kde.kitemmodels as KItemModels
import org.kde.plasma.workspace.dbus as DBus

import "../components"

// Public KF6 API: BluezQt.
Item {
    id: root
    visible: false

    readonly property var manager: BluezQt.Manager
    // Same rule as the native Bluetooth applet: an rfkill-blocked adapter disappears from BlueZ.
    readonly property bool available: manager.bluetoothBlocked || manager.adapters.length > 0
    readonly property bool powered: manager.bluetoothOperational
    readonly property var connectedDevices: manager.connectedDevices

    readonly property string statusText: {
        if (!powered) {
            return "";
        }
        if (connectedDevices.length === 1) {
            return connectedDevices[0].name;
        }
        if (connectedDevices.length > 1) {
            return i18np("%1 device", "%1 devices", connectedDevices.length);
        }
        return "";
    }

    // Paired devices only, connected ones first, like GNOME's Bluetooth menu.
    readonly property KItemModels.KSortFilterProxyModel pairedDevices: KItemModels.KSortFilterProxyModel {
        sourceModel: root.available ? devicesModel : null
        filterRowCallback: (sourceRow, sourceParent) => sourceModel.data(sourceModel.index(sourceRow, 0, sourceParent), KItemModels.KRoleNames.role("Paired")) === true
        sortRoleName: "Connected"
        sortOrder: Qt.DescendingOrder
    }

    readonly property Presence presence: Presence {
        available: root.available && bluezWatcher.registered
        serviceUp: bluezWatcher.registered
    }

    DBus.DBusServiceWatcher {
        id: bluezWatcher
        busType: DBus.BusType.System
        watchedService: "org.bluez"
    }

    // Returns the BluezQt.PendingCall so the caller can show progress.
    function toggleDevice(device) {
        return device.connected ? device.disconnectFromDevice() : device.connectToDevice();
    }

    BluezQt.DevicesModel {
        id: devicesModel
    }

    function setEnabled(enable) {
        manager.bluetoothBlocked = !enable;
        manager.adapters.forEach(adapter => {
            adapter.powered = enable;
        });
    }
}
