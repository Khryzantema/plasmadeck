/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.plasma.workspace.dbus as DBus

import "../components"

// Stable API: UPower DisplayDevice over DBus.
Item {
    id: root
    visible: false

    // UPower device Type 2 = battery; State 1 = charging, 4 = fully charged, 5 = pending charge.
    readonly property bool present: upower.available && upower.bool("IsPresent") && upower.num("Type") === 2
    readonly property int percent: Math.round(upower.num("Percentage"))
    readonly property int state: upower.num("State")
    readonly property bool charging: state === 1 || state === 4 || state === 5
    readonly property string panelIcon: present ? iconForLevel(percent, charging) + "-symbolic" : ""

    // Same thresholds as Plasma's own BatteryIcon component.
    function iconForLevel(p, plugged) {
        let level;
        if (p >= 95) {
            level = "100";
        } else if (p > 5) {
            level = String(Math.min(9, Math.floor((p + 5) / 10)) * 10).padStart(3, "0");
        } else {
            level = "000";
        }
        return "battery-" + level + (plugged ? "-charging" : "");
    }

    ServiceProperties {
        id: upower
        busType: DBus.BusType.System
        service: "org.freedesktop.UPower"
        path: "/org/freedesktop/UPower/devices/DisplayDevice"
        iface: "org.freedesktop.UPower.Device"
    }
}
