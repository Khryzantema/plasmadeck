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

    // Set while "Clear" fades every entry out; the notifications are removed when it is over.
    property bool clearing: false

    Timer {
        id: clearTimer
        interval: Kirigami.Units.shortDuration + 40
        onTriggered: {
            section.backend.clearAll();
            section.clearing = false;
        }
    }

    // Fixed height: the popup window must never be resized by the notifications (clearing one, a
    // new one arriving): on Wayland that makes the whole popup shake (KDE bug 481829). The list
    // scrolls when it has more entries than fit.
    readonly property real listHeight: Kirigami.Units.gridUnit * 14

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
            onClicked: {
                // Entries fade out first (opacity only, so nothing moves); then they are removed and
                // only the popup window shrinks, animated.
                section.clearing = true;
                clearTimer.restart();
            }
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

            delegate: Item {
                id: entry

                required property var model
                required property int index

                // A running job that was closed with the X stays hidden until it ends.
                readonly property bool hidden: section.backend.isJobActive(model)
                    && section.backend.dismissedJobs[model.notificationId] === true

                // Fades out before being closed, so the list only changes size afterwards.
                property bool closing: false
                property var afterFade: null

                width: ListView.view.width
                height: hidden ? 0 : card.implicitHeight + Kirigami.Units.smallSpacing
                visible: !hidden
                opacity: (closing || section.clearing) ? 0 : 1

                Behavior on opacity {
                    NumberAnimation {
                        duration: Kirigami.Units.shortDuration
                        easing.type: Easing.OutCubic
                    }
                }

                Timer {
                    id: fadeTimer
                    interval: Kirigami.Units.shortDuration + 40
                    onTriggered: if (entry.afterFade) entry.afterFade()
                }

                function closeAfterFade(action) {
                    afterFade = action;
                    closing = true;
                    fadeTimer.restart();
                }

                NotificationCard {
                    id: card
                    width: parent.width
                    notification: entry.model
                    unread: entry.model.read === false
                    onDefaultActionInvoked: section.backend.invokeDefault(section.backend.history, entry.index)
                    onActionInvoked: actionId => section.backend.invokeAction(section.backend.history, entry.index, actionId)
                    onCloseClicked: {
                        if (section.backend.isJobActive(entry.model)) {
                            const id = entry.model.notificationId;
                            entry.closeAfterFade(() => section.backend.dismissJob(id));
                        } else {
                            const row = entry.index;
                            entry.closeAfterFade(() => section.backend.close(section.backend.history, row));
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
