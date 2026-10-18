/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCMUtils
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.private.systemtray as SystemTray

// Lists the tray items (running ones and hidden ones that are not running)
// and lets the user show/hide and pin them.
KCMUtils.ScrollViewKCM {
    id: page

    property var cfg_pinnedItems: []
    property var cfg_hiddenItems: []
    property var cfg_pinnedItemsDefault: []
    property var cfg_hiddenItemsDefault: []

    function setIn(list, id, present) {
        const result = list.filter(x => x !== id);
        if (present) {
            result.push(id);
        }
        return result;
    }

    SystemTray.StatusNotifierModel {
        id: sniModel
    }

    Instantiator {
        id: running
        model: sniModel
        delegate: QtObject {
            readonly property string itemId: model.Id
            readonly property string title: model.Title || model.ToolTipTitle || model.Id
            readonly property var icon: model.Icon || model.IconName
            readonly property bool passive: model.Status === PlasmaCore.Types.PassiveStatus
            // Item data arrives asynchronously after the row is created.
            onItemIdChanged: Qt.callLater(page.refresh)
            onTitleChanged: Qt.callLater(page.refresh)
            onIconChanged: Qt.callLater(page.refresh)
            onPassiveChanged: Qt.callLater(page.refresh)
        }
        onObjectAdded: page.refresh()
        onObjectRemoved: page.refresh()
    }

    property var entries: []

    function refresh() {
        const list = [];
        for (let i = 0; i < running.count; i++) {
            const o = running.objectAt(i);
            if (o && !list.some(e => e.itemId === o.itemId)) {
                list.push({ itemId: o.itemId, title: o.title, icon: o.icon, passive: o.passive, running: true });
            }
        }
        // Hidden items whose app is not running right now.
        for (const id of cfg_hiddenItems) {
            if (!list.some(e => e.itemId === id)) {
                list.push({ itemId: id, title: id, icon: "application-x-executable", passive: false, running: false });
            }
        }
        entries = list.sort((a, b) => a.title.localeCompare(b.title));
    }

    Component.onCompleted: refresh()

    view: ListView {
        model: page.entries
        reuseItems: false

        Kirigami.PlaceholderMessage {
            anchors.centerIn: parent
            width: parent.width - Kirigami.Units.gridUnit * 4
            visible: parent.count === 0
            text: i18n("No applications are using the system tray")
        }

        delegate: QQC2.ItemDelegate {
            id: row

            required property var modelData

            width: ListView.view.width
            down: false
            hoverEnabled: false

            contentItem: RowLayout {
                spacing: Kirigami.Units.largeSpacing

                Kirigami.Icon {
                    source: row.modelData.icon
                    Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    QQC2.Label {
                        Layout.fillWidth: true
                        text: row.modelData.title
                        elide: Text.ElideRight
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        visible: text.length > 0
                        opacity: 0.7
                        font: Kirigami.Theme.smallFont
                        text: !row.modelData.running ? i18n("Not running")
                            : (row.modelData.passive ? i18n("Currently passive (hidden by the application)") : "")
                    }
                }

                QQC2.CheckBox {
                    text: i18n("Show")
                    checked: !page.cfg_hiddenItems.includes(row.modelData.itemId)
                    onToggled: page.cfg_hiddenItems = page.setIn(page.cfg_hiddenItems, row.modelData.itemId, !checked)
                }

                QQC2.CheckBox {
                    text: i18n("Pin to start")
                    checked: page.cfg_pinnedItems.includes(row.modelData.itemId)
                    onToggled: page.cfg_pinnedItems = page.setIn(page.cfg_pinnedItems, row.modelData.itemId, checked)
                }
            }
        }
    }
}
