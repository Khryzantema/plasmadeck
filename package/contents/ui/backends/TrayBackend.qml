/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.kitemmodels as KItemModels
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.private.systemtray as SystemTray
import org.kde.plasma.workspace.dbus as DBus

// Hybrid tray backend:
//  - listing, status and decoded icons (theme name, IconPixmap, IconThemePath) come from
//    StatusNotifierModel, a private type of org.kde.plasma.private.systemtray;
//  - every interaction talks to the StatusNotifierItem directly over DBus.
Item {
    id: root
    visible: false

    readonly property var pinnedIds: Plasmoid.configuration.pinnedItems
    readonly property var hiddenIds: Plasmoid.configuration.hiddenItems

    readonly property alias pinnedModel: pinnedProxy
    readonly property alias otherModel: otherProxy
    readonly property int count: pinnedModel.count + otherModel.count
    readonly property bool needsAttention: attentionModel.count > 0

    readonly property string sniInterface: "org.kde.StatusNotifierItem"

    function isPinned(id) {
        return pinnedIds.includes(id);
    }

    function setPinned(id, pinned) {
        const list = pinnedIds.filter(x => x !== id);
        if (pinned) {
            list.push(id);
        }
        Plasmoid.configuration.pinnedItems = list;
    }

    function setHidden(id, hidden) {
        const list = hiddenIds.filter(x => x !== id);
        if (hidden) {
            list.push(id);
        }
        Plasmoid.configuration.hiddenItems = list;
    }

    // DataEngineSource is "<bus name><object path>", e.g. ":1.231/org/ayatana/NotificationItem/steam".
    function splitSource(source) {
        const slash = source.indexOf("/");
        return slash < 0 ? { service: source, path: "/StatusNotifierItem" } : { service: source.slice(0, slash), path: source.slice(slash) };
    }

    function call(source, iface, member, args, signature, onReply, onError) {
        const target = splitSource(source);
        DBus.SessionBus.asyncCall({
            service: target.service,
            path: target.path,
            iface: iface,
            member: member,
            arguments: args,
            signature: signature,
        }, reply => onReply?.(reply), reply => onError ? onError(reply) : console.warn("PlasmaDeck:", member, "failed:", reply.error.message));
    }

    function activate(source, x, y, onError) {
        call(source, sniInterface, "Activate", [Math.round(x), Math.round(y)], "(ii)", null, onError);
    }

    function secondaryActivate(source, x, y) {
        call(source, sniInterface, "SecondaryActivate", [Math.round(x), Math.round(y)], "(ii)");
    }

    function scroll(source, delta, orientation) {
        call(source, sniInterface, "Scroll", [delta, orientation], "(is)");
    }

    // Asks the item to show its own context menu (used when it has no dbusmenu).
    function legacyContextMenu(source, x, y) {
        call(source, sniInterface, "ContextMenu", [Math.round(x), Math.round(y)], "(ii)");
    }

    // Resolves the item's dbusmenu object path; calls back with "" when it has none.
    function menuPath(source, callback) {
        call(source, "org.freedesktop.DBus.Properties", "Get", [sniInterface, "Menu"], "(ss)",
            reply => {
                const path = String(reply.value?.value ?? reply.value ?? "");
                callback(path === "/" ? "" : path);
            },
            () => callback(""));
    }

    component ItemProxy: KItemModels.KSortFilterProxyModel {
        property bool pinned
        sourceModel: sniModel
        sortRoleName: "Title"
        sortCaseSensitivity: Qt.CaseInsensitive
        filterRowCallback: (sourceRow, sourceParent) => {
            const index = sourceModel.index(sourceRow, 0, sourceParent);
            const id = sourceModel.data(index, KItemModels.KRoleNames.role("Id"));
            const status = sourceModel.data(index, KItemModels.KRoleNames.role("Status"));
            return status !== PlasmaCore.Types.PassiveStatus
                && !root.hiddenIds.includes(id)
                && root.pinnedIds.includes(id) === pinned;
        }
    }

    ItemProxy {
        id: pinnedProxy
        pinned: true
    }

    ItemProxy {
        id: otherProxy
        pinned: false
    }

    ItemProxy {
        id: attentionModel
        filterRowCallback: (sourceRow, sourceParent) => {
            const index = sourceModel.index(sourceRow, 0, sourceParent);
            return sourceModel.data(index, KItemModels.KRoleNames.role("Status")) === PlasmaCore.Types.NeedsAttentionStatus
                && !root.hiddenIds.includes(sourceModel.data(index, KItemModels.KRoleNames.role("Id")));
        }
    }

    onPinnedIdsChanged: refilter()
    onHiddenIdsChanged: refilter()

    function refilter() {
        pinnedModel.invalidateFilter();
        otherModel.invalidateFilter();
        attentionModel.invalidateFilter();
    }

    SystemTray.StatusNotifierModel {
        id: sniModel
    }
}
