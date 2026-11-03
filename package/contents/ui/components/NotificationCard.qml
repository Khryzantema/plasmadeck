/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.coreaddons as KCoreAddons
import org.kde.kirigami as Kirigami
import org.kde.notificationmanager as NotificationManager
import org.kde.plasma.components as PlasmaComponents3

// One notification: app header, summary, body, optional image and actions.
// Used in the popup's notification list and in the on-screen bubbles.
Rectangle {
    id: card

    // Model roles of NotificationManager.Notifications (summary, body, applicationName…).
    required property var notification
    property int maximumBodyLines: 4
    property bool unread: false

    signal defaultActionInvoked()
    signal actionInvoked(string actionId)
    signal closeClicked()
    signal suspendClicked()
    signal resumeClicked()
    signal killClicked()

    readonly property bool hovered: hover.hovered
    // File operations (Dolphin copy/move, downloads…) arrive as jobs with progress.
    readonly property bool isJob: notification.type === NotificationManager.Notifications.JobType
    readonly property bool jobRunning: isJob && notification.jobState === NotificationManager.Notifications.JobStateRunning
    readonly property bool jobSuspended: isJob && notification.jobState === NotificationManager.Notifications.JobStateSuspended
    readonly property bool jobActive: jobRunning || jobSuspended
    readonly property bool critical: notification.urgency === NotificationManager.Notifications.CriticalUrgency

    implicitHeight: layout.implicitHeight + Kirigami.Units.largeSpacing * 2
    radius: Kirigami.Units.cornerRadius * 2
    color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, hover.hovered ? 0.1 : 0.06)
    border.width: critical ? 2 : 0
    border.color: Kirigami.Theme.negativeTextColor

    Accessible.role: Accessible.Notification
    Accessible.name: notification.summary
    Accessible.description: notification.body

    HoverHandler {
        id: hover
    }

    TapHandler {
        enabled: card.notification.hasDefaultAction === true
        onTapped: card.defaultActionInvoked()
    }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        // Header: app icon and name, time, close button.
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                source: card.notification.applicationIconName || "preferences-desktop-notification-symbolic"
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
            }

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                text: card.notification.applicationName || ""
                font: Kirigami.Theme.smallFont
                opacity: 0.8
                elide: Text.ElideRight
                textFormat: Text.PlainText
            }

            Rectangle {
                visible: card.unread
                width: Kirigami.Units.smallSpacing * 1.5
                height: width
                radius: width / 2
                color: Kirigami.Theme.highlightColor
                Accessible.name: i18n("Unread")
            }

            PlasmaComponents3.Label {
                visible: !card.jobActive
                text: card.notification.created
                    ? KCoreAddons.Format.formatRelativeDateTime(card.notification.updated || card.notification.created, Locale.ShortFormat)
                    : ""
                font: Kirigami.Theme.smallFont
                opacity: 0.7
            }

            PlasmaComponents3.ToolButton {
                visible: card.jobActive && card.notification.suspendable === true
                icon.name: card.jobSuspended ? "media-playback-start-symbolic" : "media-playback-pause-symbolic"
                text: card.jobSuspended ? i18n("Resume") : i18n("Pause")
                display: PlasmaComponents3.AbstractButton.IconOnly
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium + Kirigami.Units.smallSpacing
                Layout.preferredHeight: Layout.preferredWidth
                onClicked: card.jobSuspended ? card.resumeClicked() : card.suspendClicked()
                PlasmaComponents3.ToolTip.text: text
                PlasmaComponents3.ToolTip.visible: hovered
                PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
            }

            PlasmaComponents3.ToolButton {
                visible: card.jobActive && card.notification.killable === true
                icon.name: "media-playback-stop-symbolic"
                text: i18n("Cancel")
                display: PlasmaComponents3.AbstractButton.IconOnly
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium + Kirigami.Units.smallSpacing
                Layout.preferredHeight: Layout.preferredWidth
                onClicked: card.killClicked()
                PlasmaComponents3.ToolTip.text: text
                PlasmaComponents3.ToolTip.visible: hovered
                PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
            }

            PlasmaComponents3.ToolButton {
                visible: !card.jobActive && card.notification.closable !== false
                icon.name: "window-close-symbolic"
                text: i18n("Close")
                display: PlasmaComponents3.AbstractButton.IconOnly
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium + Kirigami.Units.smallSpacing
                Layout.preferredHeight: Layout.preferredWidth
                Accessible.name: i18n("Close notification")
                onClicked: card.closeClicked()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.largeSpacing

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: Kirigami.Units.smallSpacing / 2

                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    text: card.notification.summary || ""
                    font.weight: Font.DemiBold
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }

                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: card.notification.body || ""
                    wrapMode: Text.Wrap
                    maximumLineCount: card.maximumBodyLines
                    elide: Text.ElideRight
                    // The server already sanitizes the markup to a safe subset.
                    textFormat: Text.StyledText
                    opacity: 0.9
                    onLinkActivated: link => Qt.openUrlExternally(link)
                }
            }

            Kirigami.Icon {
                readonly property var picture: card.notification.image || card.notification.iconName
                visible: !!picture && card.notification.iconName !== card.notification.applicationIconName
                source: picture
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: Kirigami.Units.iconSizes.large
                Layout.preferredHeight: Kirigami.Units.iconSizes.large
            }
        }

        // Job progress: bar, percentage and "x of y · speed".
        RowLayout {
            Layout.fillWidth: true
            visible: card.jobActive
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.ProgressBar {
                Layout.fillWidth: true
                from: 0
                to: 100
                value: Math.max(0, card.notification.percentage ?? 0)
                indeterminate: card.jobRunning && (card.notification.percentage ?? -1) < 0
            }

            PlasmaComponents3.Label {
                visible: (card.notification.percentage ?? -1) >= 0
                text: i18nc("Job progress", "%1%", card.notification.percentage)
                font: Kirigami.Theme.smallFont
            }
        }

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            readonly property var details: card.notification.jobDetails
            visible: card.jobActive && text.length > 0
            font: Kirigami.Theme.smallFont
            opacity: 0.7
            elide: Text.ElideRight
            textFormat: Text.PlainText
            text: {
                if (card.jobSuspended) {
                    return i18n("Paused");
                }
                if (!details) {
                    return "";
                }
                const parts = [];
                if (details.totalBytes > 0) {
                    parts.push(i18nc("Bytes processed of total", "%1 of %2",
                        KCoreAddons.Format.formatByteSize(details.processedBytes),
                        KCoreAddons.Format.formatByteSize(details.totalBytes)));
                }
                if (details.speed > 0) {
                    parts.push(i18nc("Transfer speed", "%1/s", KCoreAddons.Format.formatByteSize(details.speed)));
                }
                return parts.join(" · ");
            }
        }

        // Action buttons sent by the application.
        Flow {
            Layout.fillWidth: true
            visible: actionRepeater.count > 0
            spacing: Kirigami.Units.smallSpacing

            Repeater {
                id: actionRepeater
                model: {
                    const names = card.notification.actionNames || [];
                    const labels = card.notification.actionLabels || [];
                    const list = [];
                    for (let i = 0; i < names.length; i++) {
                        // "default" is triggered by clicking the notification itself.
                        if (names[i] !== "default" && labels[i]) {
                            list.push({ id: names[i], label: labels[i] });
                        }
                    }
                    return list;
                }
                delegate: PlasmaComponents3.Button {
                    required property var modelData
                    text: modelData.label
                    onClicked: card.actionInvoked(modelData.id)
                }
            }
        }
    }
}
