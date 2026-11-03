/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

// Notification history shown at the bottom of the popup.
// Fixed height: the popup must not resize while in use (see MenuOverlay).
ColumnLayout {
    id: section

    required property Item backend
    // Off when something else above already draws the separator.
    property bool showSeparator: true

    spacing: Kirigami.Units.smallSpacing

    // The list is as small as it can be when empty (just the bell), grows with the notifications
    // up to five of them, and scrolls past that, with a scroll bar on the side.
    readonly property real minListHeight: placeholder.implicitHeight + Kirigami.Units.smallSpacing
    readonly property int maxVisibleItems: 5
    // Height of the first five entries (measured, with a guess for those not created yet).
    property real fiveItemsHeight: Kirigami.Units.gridUnit * 5.5 * maxVisibleItems
    readonly property real contentWanted: list.contentHeight
    property real listHeight: list.count === 0
        ? minListHeight
        : Math.max(minListHeight, Math.min(list.count <= maxVisibleItems ? list.contentHeight : fiveItemsHeight, fiveItemsHeight))

    function measureFiveItems() {
        let total = 0;
        let measured = 0;
        for (let i = 0; i < Math.min(list.count, maxVisibleItems); i++) {
            const item = list.itemAtIndex(i);
            if (item) {
                total += item.height;
                measured++;
            }
        }
        if (measured > 0) {
            fiveItemsHeight = total / measured * maxVisibleItems;
        }
    }

    Behavior on listHeight {
        NumberAnimation {
            duration: Kirigami.Units.shortDuration
            easing.type: Easing.OutCubic
        }
    }

    Kirigami.Separator {
        Layout.fillWidth: true
        Layout.topMargin: Kirigami.Units.smallSpacing
        visible: section.showSeparator
    }

    RowLayout {
        Layout.fillWidth: true

        Kirigami.Heading {
            Layout.fillWidth: true
            level: 4
            text: i18n("Notifications")
        }

        PlasmaComponents3.ToolButton {
            visible: list.count > 0
            icon.name: "edit-clear-history-symbolic"
            text: i18n("Clear")
            onClicked: section.backend.clearAll()
        }
    }

    PlasmaComponents3.ScrollView {
        Layout.fillWidth: true
        Layout.preferredHeight: section.listHeight
        // A classic side bar, only when the list does not fit.
        PlasmaComponents3.ScrollBar.vertical.policy: list.contentHeight > list.height + 1 ? PlasmaComponents3.ScrollBar.AlwaysOn : PlasmaComponents3.ScrollBar.AlwaysOff

        ListView {
            id: list
            model: section.backend.history
            clip: true
            reuseItems: false
            cacheBuffer: Kirigami.Units.gridUnit * 40
            onContentHeightChanged: Qt.callLater(section.measureFiveItems)
            onCountChanged: Qt.callLater(section.measureFiveItems)

            delegate: Item {
                id: entry

                required property var model
                required property int index

                // A running job that was closed with the X stays hidden until it ends.
                readonly property bool hidden: section.backend.isJobActive(model)
                    && section.backend.dismissedJobs[model.notificationId] === true

                width: ListView.view.width
                height: hidden ? 0 : card.implicitHeight + Kirigami.Units.smallSpacing
                visible: !hidden

                NotificationCard {
                    id: card
                    width: parent.width
                    notification: entry.model
                    unread: entry.model.read === false
                    onDefaultActionInvoked: section.backend.invokeDefault(section.backend.history, entry.index)
                    onActionInvoked: actionId => section.backend.invokeAction(section.backend.history, entry.index, actionId)
                    onCloseClicked: {
                        if (section.backend.isJobActive(entry.model)) {
                            section.backend.dismissJob(entry.model.notificationId);
                        } else {
                            section.backend.close(section.backend.history, entry.index);
                        }
                    }
                    onSuspendClicked: section.backend.suspendJob(section.backend.history, entry.index)
                    onResumeClicked: section.backend.resumeJob(section.backend.history, entry.index)
                    onKillClicked: section.backend.killJob(section.backend.history, entry.index)
                }
            }

            // Compact empty state: a small bell and a line of text.
            RowLayout {
                id: placeholder
                anchors.centerIn: parent
                spacing: Kirigami.Units.smallSpacing
                visible: list.count === 0
                opacity: 0.7

                Kirigami.Icon {
                    source: section.backend.serverRunning ? "notification-inactive-symbolic" : "notification-disabled-symbolic"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                }

                PlasmaComponents3.Label {
                    text: section.backend.serverRunning ? i18n("No notifications") : i18n("Notification service not available")
                }
            }
        }
    }
}
