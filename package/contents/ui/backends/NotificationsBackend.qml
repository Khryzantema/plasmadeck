/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.notificationmanager as NotificationManager
import org.kde.plasma.workspace.dbus as DBus

// Semi-public API: org.kde.notificationmanager (plasma-workspace).
//
// Creating a Notifications model registers this process as the desktop
// notification server (org.freedesktop.Notifications) when nobody else owns
// it. In plasmashell the server is shared, so this also works side by side
// with Plasma's own Notifications widget.
Item {
    id: root
    visible: false

    // Do Not Disturb state, owned by DndBackend.
    property bool inhibited: false

    readonly property bool serverRunning: NotificationManager.Server.valid || serviceWatcher.registered
    readonly property alias history: historyModel
    readonly property alias popups: popupModel
    readonly property alias settings: notificationSettings

    // Same rule as the native applet: notifications currently shown as popups are not "unread".
    readonly property int unreadCount: Math.max(0, historyModel.unreadNotificationsCount - popupModel.activeNotificationsCount)

    readonly property string panelIcon: {
        if (!serverRunning || inhibited) {
            return "notification-disabled-symbolic";
        }
        // No icon theme ships a bell with an exclamation mark, so the applet carries its own.
        return unreadCount > 0 ? String(Qt.resolvedUrl("../../icons/notification-unread-symbolic.svg")) : "notification-inactive-symbolic";
    }

    readonly property string statusText: {
        if (!serverRunning) {
            return i18n("Notification service not available");
        }
        return unreadCount > 0 ? i18np("%1 unread notification", "%1 unread notifications", unreadCount) : "";
    }

    // Everything up to now counts as seen.
    function markAllRead() {
        historyModel.lastRead = undefined;
    }

    function clearAll() {
        // Notifications still on screen stay until they expire, like in the native applet.
        historyModel.clear(NotificationManager.Notifications.ClearExpired);
    }

    function index(model, row) {
        return model.index(row, 0);
    }

    function invokeDefault(model, row) {
        model.invokeDefaultAction(index(model, row), NotificationManager.Notifications.Close);
    }

    function invokeAction(model, row, actionId) {
        model.invokeAction(index(model, row), actionId, NotificationManager.Notifications.Close);
    }

    function close(model, row) {
        model.close(index(model, row));
    }

    function expire(model, row) {
        model.expire(index(model, row));
    }

    // Lets the server know Do Not Disturb is on, so notifications added meanwhile are marked as such.
    onInhibitedChanged: NotificationManager.Server.inhibited = inhibited
    Component.onCompleted: NotificationManager.Server.inhibited = inhibited

    DBus.DBusServiceWatcher {
        id: serviceWatcher
        busType: DBus.BusType.Session
        watchedService: "org.freedesktop.Notifications"
    }

    NotificationManager.Settings {
        id: notificationSettings
        live: true
    }

    NotificationManager.Notifications {
        id: historyModel
        showExpired: true
        showDismissed: true
        showJobs: false
        sortMode: NotificationManager.Notifications.SortByDate
        groupMode: NotificationManager.Notifications.GroupDisabled
        ignoreBlacklistDuringInhibition: true
        blacklistedDesktopEntries: notificationSettings.historyBlacklistedApplications
        blacklistedNotifyRcNames: notificationSettings.historyBlacklistedServices
        urgencies: NotificationManager.Notifications.CriticalUrgency | NotificationManager.Notifications.NormalUrgency
            | (notificationSettings.lowPriorityHistory ? NotificationManager.Notifications.LowUrgency : 0)
    }

    // Same filtering as the native popups.
    NotificationManager.Notifications {
        id: popupModel
        limit: 5
        showExpired: false
        showDismissed: false
        showAddedDuringInhibition: false
        showJobs: false
        blacklistedDesktopEntries: notificationSettings.popupBlacklistedApplications
        blacklistedNotifyRcNames: notificationSettings.popupBlacklistedServices
        whitelistedDesktopEntries: root.inhibited ? notificationSettings.doNotDisturbPopupWhitelistedApplications : []
        whitelistedNotifyRcNames: root.inhibited ? notificationSettings.doNotDisturbPopupWhitelistedServices : []
        sortMode: NotificationManager.Notifications.SortByTypeAndUrgency
        sortOrder: Qt.AscendingOrder
        groupMode: NotificationManager.Notifications.GroupDisabled
        urgencies: {
            let urgencies = 0;
            // Critical always, except in Do Not Disturb when disabled in the settings.
            if (!root.inhibited || notificationSettings.criticalPopupsInDoNotDisturbMode) {
                urgencies |= NotificationManager.Notifications.CriticalUrgency;
            }
            if (!root.inhibited) {
                urgencies |= NotificationManager.Notifications.NormalUrgency;
                if (notificationSettings.lowPriorityPopups) {
                    urgencies |= NotificationManager.Notifications.LowUrgency;
                }
            }
            return urgencies;
        }
    }
}
