/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras

// Clipboard history picker, styled like the audio device menu.
Rectangle {
    id: menu

    required property Item clipboard

    signal chosen()

    implicitHeight: column.implicitHeight + Kirigami.Units.largeSpacing * 2
    radius: Kirigami.Units.cornerRadius * 2
    color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.06)

    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                source: "klipper-symbolic"
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
            }
            Kirigami.Heading {
                level: 5
                text: i18n("Clipboard History")
                Layout.fillWidth: true
            }
            PlasmaComponents3.ToolButton {
                visible: menu.clipboard.count > 0
                icon.name: "edit-clear-history-symbolic"
                text: i18n("Clear")
                display: PlasmaComponents3.AbstractButton.IconOnly
                Accessible.name: i18n("Clear clipboard history")
                onClicked: {
                    menu.chosen();
                    menu.clipboard.clear();
                }
                PlasmaComponents3.ToolTip.text: Accessible.name
                PlasmaComponents3.ToolTip.visible: hovered
                PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
            }
        }

        PlasmaExtras.PlaceholderMessage {
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.largeSpacing
            visible: menu.clipboard.count === 0
            iconName: "klipper-symbolic"
            text: i18n("Clipboard is empty")
        }

        Repeater {
            model: menu.clipboard.recent
            delegate: PlasmaComponents3.ItemDelegate {
                id: entry

                required property var model
                required property int index

                readonly property bool isImage: (model.type & menu.clipboard.typeImage) !== 0
                readonly property bool isUrl: (model.type & menu.clipboard.typeUrl) !== 0
                // The first entry is what is on the clipboard right now.
                readonly property bool current: index === 0

                Layout.fillWidth: true
                text: isImage ? i18n("Image") : menu.clipboard.preview(model.display)
                highlighted: activeFocus

                Accessible.role: Accessible.RadioButton
                Accessible.checkable: true
                Accessible.checked: current

                contentItem: RowLayout {
                    spacing: Kirigami.Units.smallSpacing

                    Kirigami.Icon {
                        visible: !entry.isImage
                        source: entry.isUrl ? "link-symbolic" : "edit-paste-symbolic"
                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    }

                    // Images get a small thumbnail instead of text.
                    Image {
                        visible: entry.isImage
                        source: entry.isImage ? (entry.model.decoration ?? "") : ""
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        sourceSize.height: Kirigami.Units.gridUnit * 2
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                    }

                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        text: entry.text
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        textFormat: Text.PlainText
                    }

                    Kirigami.Icon {
                        visible: entry.current
                        source: "object-select-symbolic"
                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    }
                }

                onClicked: {
                    menu.clipboard.select(model.uuid);
                    menu.chosen();
                }
            }
        }
    }
}
