/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras

// Notification history shown at the bottom of the popup.
// Fixed height: the popup must not resize while in use (see MenuOverlay).
ColumnLayout {
    id: section

    required property Item backend
    // Off when something else above already draws the separator.
    property bool showSeparator: true

    spacing: Kirigami.Units.smallSpacing

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
        Layout.preferredHeight: Kirigami.Units.gridUnit * 14

        ListView {
            id: list
            model: section.backend.history
            spacing: Kirigami.Units.smallSpacing
            clip: true
            reuseItems: false

            delegate: NotificationCard {
                required property var model
                required property int index

                width: ListView.view.width
                notification: model
                unread: model.read === false
                onDefaultActionInvoked: section.backend.invokeDefault(section.backend.history, index)
                onActionInvoked: actionId => section.backend.invokeAction(section.backend.history, index, actionId)
                onCloseClicked: section.backend.close(section.backend.history, index)
            }

            PlasmaExtras.PlaceholderMessage {
                anchors.centerIn: parent
                width: parent.width - Kirigami.Units.gridUnit * 2
                visible: list.count === 0
                iconName: section.backend.serverRunning ? "notification-inactive-symbolic" : "notification-disabled-symbolic"
                text: section.backend.serverRunning ? i18n("No notifications") : i18n("Notification service not available")
            }
        }
    }
}
