/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.kitemmodels as KItemModels
import org.kde.plasma.private.clipboard as Clipboard

// Private API: org.kde.plasma.private.clipboard (Klipper, plasma-workspace).
//
// KlipperInterface starts Plasma's clipboard engine (Klipper) inside plasmashell
// if no Clipboard widget did it already, so history keeps being recorded even
// without Plasma's system tray. History is persistent (~/.local/share/klipper).
Item {
    id: root
    visible: false

    // How many entries the menu shows.
    readonly property int limit: 15

    readonly property alias recent: recentModel
    readonly property int count: history.count
    readonly property string currentText: history.currentText

    // Same item type flags as Klipper's HistoryItemType.
    readonly property int typeImage: 1 << 2
    readonly property int typeUrl: 1 << 3

    // Puts an older entry back on the clipboard.
    function select(uuid) {
        history.moveToTop(uuid);
    }

    // Klipper asks for confirmation in a modal dialog, which runs a nested event
    // loop. Calling it straight from a button in the popup lets the popup (and
    // that button) be destroyed while its click handler is still running, which
    // makes Qt abort plasmashell. So the call runs later, from this backend.
    function clear() {
        Qt.callLater(() => history.clearHistory());
    }

    // One line preview of a text entry: whitespace collapsed, trimmed.
    function preview(text) {
        return String(text ?? "").replace(/\s+/g, " ").trim();
    }

    Clipboard.KlipperInterface {
        id: klipper
    }

    Clipboard.HistoryModel {
        id: history
    }

    KItemModels.KSortFilterProxyModel {
        id: recentModel
        sourceModel: history
        filterRowCallback: sourceRow => sourceRow < root.limit
    }

    // New entries are inserted at the top and push others down: rows that were
    // already accepted are not filtered again on their own, so refilter.
    Connections {
        target: history
        function onCountChanged() {
            recentModel.invalidateFilter();
        }
    }
}
