/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.plasma.workspace.dbus as DBus

// DBus.Properties keeps stale values when the remote service goes away and
// does not reload when it comes back. This wraps it with a service watcher so
// consumers can rely on `available` and always see fresh values.
DBus.Properties {
    id: root

    readonly property bool available: watcher.registered
    readonly property var props: available ? properties : ({})

    property DBus.DBusServiceWatcher watcher: DBus.DBusServiceWatcher {
        busType: root.busType
        watchedService: root.service
        onRegisteredChanged: {
            if (registered) {
                root.updateAll();
            }
        }
    }

    // DBus values may arrive as typed wrappers ({value: ...}); unwrap them.
    function value(key) {
        const v = props[key];
        return v !== null && typeof v === "object" && "value" in v ? v.value : v;
    }
    function str(key) {
        const v = value(key);
        return v === undefined || v === null ? "" : String(v);
    }
    function num(key) {
        const v = Number(value(key));
        return isNaN(v) ? 0 : v;
    }
    function bool(key) {
        return value(key) === true;
    }
}
