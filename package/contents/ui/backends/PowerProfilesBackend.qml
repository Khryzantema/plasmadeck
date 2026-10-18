/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.plasma.workspace.dbus as DBus

import "../components"

// Stable API: org.freedesktop.UPower.PowerProfiles (power-profiles-daemon or tuned-ppd).
Item {
    id: root
    visible: false

    readonly property bool available: ppd.available && profiles.length > 0
    readonly property string activeProfile: ppd.str("ActiveProfile")
    readonly property var profiles: {
        // Arrives as a QML sequence, not a JS Array.
        const list = ppd.value("Profiles");
        if (!list || !list.length) {
            return [];
        }
        const order = ["power-saver", "balanced", "performance"];
        return Array.from(list).map(entry => String(entry.Profile?.value ?? entry.Profile ?? ""))
            .filter(name => order.includes(name))
            .sort((a, b) => order.indexOf(a) - order.indexOf(b));
    }

    readonly property Presence presence: Presence {
        available: root.available
        serviceUp: ppd.available
    }

    function displayName(profile) {
        switch (profile) {
        case "power-saver":
            return i18n("Power Saver");
        case "balanced":
            return i18n("Balanced");
        case "performance":
            return i18n("Performance");
        }
        return profile;
    }

    function iconName(profile) {
        switch (profile) {
        case "power-saver":
            return "battery-profile-powersave-symbolic";
        case "performance":
            return "battery-profile-performance-symbolic";
        }
        return "speedometer-symbolic";
    }

    function setProfile(profile) {
        DBus.SystemBus.asyncCall({
            service: ppd.service,
            path: ppd.path,
            iface: "org.freedesktop.DBus.Properties",
            member: "Set",
            // DBus.variant holds a real QDBusVariant; plain or typed values would be sent as "s".
            arguments: [ppd.iface, "ActiveProfile", new DBus.variant(profile)],
            signature: "(ssv)",
        }, () => {}, reply => console.warn("PlasmaDeck: could not set power profile:", reply.error.message));
    }

    function cycle() {
        const i = profiles.indexOf(activeProfile);
        setProfile(profiles[(i + 1) % profiles.length]);
    }

    ServiceProperties {
        id: ppd
        busType: DBus.BusType.System
        service: "org.freedesktop.UPower.PowerProfiles"
        path: "/org/freedesktop/UPower/PowerProfiles"
        iface: "org.freedesktop.UPower.PowerProfiles"
    }
}
