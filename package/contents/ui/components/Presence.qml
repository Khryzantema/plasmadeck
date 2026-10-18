/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick

// Decides whether a feature is shown, hidden or shown as unavailable:
//  - never seen (no hardware or support): hidden;
//  - its service went away after being seen: shown as unavailable, without stale state;
//  - otherwise: shown normally.
QtObject {
    // The feature is currently usable (hardware present and service answering).
    property bool available: false
    // The DBus service behind the feature is registered.
    property bool serviceUp: true

    property bool seen: false

    readonly property bool shown: available || unavailable
    readonly property bool unavailable: seen && !serviceUp

    onAvailableChanged: {
        if (available) {
            seen = true;
        }
    }
    Component.onCompleted: {
        if (available) {
            seen = true;
        }
    }
}
