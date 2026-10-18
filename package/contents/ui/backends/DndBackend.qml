/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.notificationmanager as NotificationManager
import org.kde.plasma.workspace.dbus as DBus

import "../components"

// Semi-public API: org.kde.notificationmanager (plasma-workspace). Uses the same
// settings as the native Notifications applet, so both stay in sync.
Item {
    id: root
    visible: false

    // Server.valid is only true inside the process hosting the server, so watch the bus instead.
    readonly property bool available: notificationService.registered
    property date now: new Date()

    readonly property Presence presence: Presence {
        available: root.available
        serviceUp: notificationService.registered
    }

    DBus.DBusServiceWatcher {
        id: notificationService
        busType: DBus.BusType.Session
        watchedService: "org.freedesktop.Notifications"
    }

    readonly property bool active: {
        const until = settings.notificationsInhibitedUntil;
        const byTime = !isNaN(until.getTime()) && now.getTime() < until.getTime();
        return byTime || settings.notificationsInhibitedByApplication;
    }

    readonly property string statusText: {
        if (!active) {
            return "";
        }
        if (settings.notificationsInhibitedByApplication) {
            return settings.notificationInhibitionApplications.join(", ");
        }
        const until = settings.notificationsInhibitedUntil;
        // The native applet uses "one year from now" to mean "until turned off".
        if (until.getTime() - now.getTime() < 24 * 3600 * 1000) {
            return i18n("Until %1", until.toLocaleTimeString(Qt.locale(), Locale.ShortFormat));
        }
        return "";
    }

    function setActive(enable) {
        if (enable) {
            const until = new Date();
            until.setFullYear(until.getFullYear() + 1);
            settings.notificationsInhibitedUntil = until;
        } else {
            settings.notificationsInhibitedUntil = undefined;
            settings.revokeApplicationInhibitions();
        }
        settings.save();
        now = new Date();
    }

    NotificationManager.Settings {
        id: settings
        live: true
    }

    // Time-based inhibitions expire on their own.
    Timer {
        interval: 30 * 1000
        repeat: true
        running: root.active
        onTriggered: root.now = new Date()
    }
}
