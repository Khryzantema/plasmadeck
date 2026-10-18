/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

// Inline radio-style submenu: a header and a list of choices.
Rectangle {
    id: menu

    property string title
    property string iconName
    // [{ text, icon, checked }]
    property var choices: []

    signal chosen(int index)

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
                source: menu.iconName
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
            }
            Kirigami.Heading {
                level: 5
                text: menu.title
                Layout.fillWidth: true
            }
        }

        Repeater {
            model: menu.choices
            delegate: PlasmaComponents3.ItemDelegate {
                id: choiceItem

                required property var modelData
                required property int index

                Layout.fillWidth: true
                text: modelData.text
                icon.name: modelData.icon ?? ""
                highlighted: activeFocus

                Accessible.role: Accessible.RadioButton
                Accessible.checkable: true
                Accessible.checked: modelData.checked

                contentItem: RowLayout {
                    spacing: Kirigami.Units.smallSpacing
                    Kirigami.Icon {
                        visible: choiceItem.icon.name.length > 0
                        source: choiceItem.icon.name
                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    }
                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        text: choiceItem.text
                        elide: Text.ElideRight
                    }
                    Kirigami.Icon {
                        source: "object-select-symbolic"
                        visible: choiceItem.modelData.checked
                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    }
                }

                onClicked: menu.chosen(index)
            }
        }
    }
}
