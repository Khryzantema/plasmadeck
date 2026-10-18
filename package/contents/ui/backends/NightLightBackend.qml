/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.plasma.workspace.dbus as DBus

import "../components"

// Stable API: org.kde.KWin.NightLight over DBus. Turning it on or off changes the
// persistent setting (like GNOME), not a temporary inhibition.
Item {
    id: root
    visible: false

    readonly property bool available: nightLight.available && nightLight.bool("available")
    readonly property bool settingEnabled: nightLight.bool("enabled")
    readonly property bool inhibited: nightLight.bool("inhibited")
    readonly property bool active: settingEnabled && !inhibited
    property bool busy: false

    readonly property Presence presence: Presence {
        available: root.available
        serviceUp: nightLight.available
    }

    readonly property string statusText: {
        if (!settingEnabled) {
            return "";
        }
        if (inhibited) {
            return i18n("Suspended");
        }
        if (nightLight.num("currentTemperature") !== nightLight.num("targetTemperature")) {
            return i18n("Transitioning");
        }
        return nightLight.bool("daylight") ? i18n("Day") : i18n("Night");
    }

    function setEnabled(enable) {
        busy = true;
        // KWin only picks the change up with --notify followed by a reconfigure.
        runner.exec("kwriteconfig6 --file kwinrc --group NightColor --key Active --notify " + (enable ? "true" : "false"), exitCode => {
            busy = false;
            if (exitCode !== 0) {
                console.warn("PlasmaDeck: could not change Night Light setting");
                return;
            }
            DBus.SessionBus.asyncCall({
                service: "org.kde.KWin",
                path: "/KWin",
                iface: "org.kde.KWin",
                member: "reconfigure",
            }, () => {}, () => {});
        });
    }

    CommandRunner {
        id: runner
    }

    ServiceProperties {
        id: nightLight
        busType: DBus.BusType.Session
        service: "org.kde.KWin.NightLight"
        path: "/org/kde/KWin/NightLight"
        iface: "org.kde.KWin.NightLight"
    }
}
