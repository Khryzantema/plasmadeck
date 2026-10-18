/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.workspace.dbus as DBus

// Renders a StatusNotifierItem's com.canonical.dbusmenu as a native popup menu.
Item {
    id: builder

    required property Item tray

    readonly property string menuInterface: "com.canonical.dbusmenu"
    property PlasmaComponents3.Menu menu: null

    // Opens the context menu of `source` next to `anchor`. `globalPos` is used for
    // apps without a dbusmenu, which draw their own menu.
    function open(source, itemId, anchor, globalPos) {
        tray.menuPath(source, path => {
            if (path === "") {
                tray.legacyContextMenu(source, globalPos.x, globalPos.y);
                return;
            }
            const service = tray.splitSource(source).service;
            // Some apps (e.g. Steam) regenerate item ids when the menu is opened or refreshed,
            // so announce the menu first and only then fetch the ids we will click.
            sendEvent(service, path, 0, "opened");
            call(service, path, "AboutToShow", [0], "(i)", () => fetchLayout(service, path, itemId, anchor), () => fetchLayout(service, path, itemId, anchor));
        });
    }

    function call(service, path, member, args, signature, onReply, onError) {
        DBus.SessionBus.asyncCall({
            service: service,
            path: path,
            iface: menuInterface,
            member: member,
            arguments: args,
            signature: signature,
        }, reply => onReply?.(reply), reply => {
            if (onError) {
                onError(reply);
            } else {
                console.warn("PlasmaDeck: dbusmenu", member, "failed:", reply.error.message);
            }
        });
    }

    // Same payload as Plasma's own importer: an empty string variant and no timestamp.
    function sendEvent(service, path, id, eventId) {
        call(service, path, "Event", [id, eventId, new DBus.variant(""), 0], "(isvu)", null,
            eventId === "clicked" ? null : () => {});
    }

    function fetchLayout(service, path, itemId, anchor) {
        call(service, path, "GetLayout", [0, -1, []], "(iias)", reply => {
            // Reply: (u revision, (i id, a{sv} properties, av children))
            const layout = unwrap(reply.values[1]);
            show(service, path, itemId, anchor, unwrap(layout[2]));
        });
    }

    // DBus values may arrive wrapped as {value: ...}.
    function unwrap(v) {
        return v !== null && typeof v === "object" && !Array.isArray(v) && "value" in v ? unwrap(v.value) : v;
    }

    function prop(props, key) {
        return props && key in props ? unwrap(props[key]) : undefined;
    }

    // dbusmenu uses "_" for mnemonics ("__" is a literal underscore); Qt uses "&".
    function label(text) {
        return String(text ?? "").replace(/&/g, "&&").replace(/__/g, "\u0000").replace(/_/g, "").replace(/\u0000/g, "_");
    }

    function populate(target, children, service, path) {
        for (const child of Array.from(children ?? [])) {
            const node = unwrap(child);
            const id = Number(unwrap(node[0]));
            const props = unwrap(node[1]) ?? {};
            const subChildren = unwrap(node[2]) ?? [];

            if (prop(props, "visible") === false) {
                continue;
            }
            if (prop(props, "type") === "separator") {
                target.addItem(separatorComponent.createObject(null));
                continue;
            }

            const text = label(prop(props, "label"));
            if (prop(props, "children-display") === "submenu" || subChildren.length > 0) {
                const submenu = menuComponent.createObject(null, { title: text });
                populate(submenu, subChildren, service, path);
                target.addMenu(submenu);
                continue;
            }

            const toggleType = prop(props, "toggle-type");
            const item = itemComponent.createObject(null, {
                text: text,
                enabled: prop(props, "enabled") !== false,
                checkable: toggleType === "checkmark" || toggleType === "radio",
                checked: Number(prop(props, "toggle-state")) === 1,
                "icon.name": prop(props, "icon-name") ?? "",
            });
            item.triggered.connect(() => sendEvent(service, path, id, "clicked"));
            target.addItem(item);
        }
    }

    function show(service, path, itemId, anchor, children) {
        if (menu) {
            menu.dismiss();
            menu.destroy();
        }
        menu = menuComponent.createObject(builder);
        populate(menu, children, service, path);

        // Our own entries: pin this item to the start, or hide it from PlasmaDeck.
        if (menu.count > 0) {
            menu.addItem(separatorComponent.createObject(null));
        }
        const pinned = tray.isPinned(itemId);
        const pinItem = itemComponent.createObject(null, {
            text: pinned ? i18n("Unpin from Start") : i18n("Pin to Start"),
            "icon.name": pinned ? "window-unpin-symbolic" : "window-pin-symbolic",
        });
        pinItem.triggered.connect(() => tray.setPinned(itemId, !pinned));
        menu.addItem(pinItem);
        const hideItem = itemComponent.createObject(null, {
            text: i18n("Hide from PlasmaDeck"),
            "icon.name": "view-hidden-symbolic",
        });
        hideItem.triggered.connect(() => tray.setHidden(itemId, true));
        menu.addItem(hideItem);

        menu.closed.connect(() => sendEvent(service, path, 0, "closed"));

        // Open away from the panel edge the applet sits on.
        switch (Plasmoid.location) {
        case PlasmaCore.Types.BottomEdge:
            menu.popup(anchor, 0, -menu.implicitHeight);
            break;
        case PlasmaCore.Types.LeftEdge:
            menu.popup(anchor, anchor.width, 0);
            break;
        case PlasmaCore.Types.RightEdge:
            menu.popup(anchor, -menu.implicitWidth, 0);
            break;
        default:
            menu.popup(anchor, 0, anchor.height);
        }
    }

    Component {
        id: menuComponent
        PlasmaComponents3.Menu {
            // A real window, so long menus are not clipped by the popup.
            popupType: QQC2.Popup.Window
        }
    }

    Component {
        id: itemComponent
        PlasmaComponents3.MenuItem {}
    }

    Component {
        id: separatorComponent
        PlasmaComponents3.MenuSeparator {}
    }
}
