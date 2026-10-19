/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCMUtils
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras

// Sub-view shown in place of the main page: back button, title, on/off switch,
// a scrollable list and a link to the matching System Settings page.
FocusScope {
    id: page

    property string title
    property string iconName
    property bool checked
    // The on/off switch in the header (hidden e.g. on a machine without Wi-Fi).
    property bool showSwitch: true
    property string switchLabel: title
    // Whether the list is shown; by default only while switched on.
    property bool listVisible: checked
    property string settingsModule
    property string settingsLabel
    property string placeholderText
    property alias model: list.model
    property alias delegate: list.delegate
    // Optional section headers (ListView.section).
    property string sectionProperty
    property Component sectionDelegate

    signal back()
    signal toggled(bool checked)

    implicitHeight: layout.implicitHeight

    Keys.onEscapePressed: back()

    ColumnLayout {
        id: layout
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.ToolButton {
                id: backButton
                focus: true
                icon.name: page.LayoutMirroring.enabled ? "go-next-symbolic" : "go-previous-symbolic"
                text: i18n("Back")
                display: PlasmaComponents3.AbstractButton.IconOnly
                Accessible.name: text
                onClicked: page.back()
                PlasmaComponents3.ToolTip.text: text
                PlasmaComponents3.ToolTip.visible: hovered
                PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
            }

            Kirigami.Icon {
                source: page.iconName
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
            }

            Kirigami.Heading {
                Layout.fillWidth: true
                level: 3
                text: page.title
                elide: Text.ElideRight
            }

            PlasmaComponents3.Switch {
                visible: page.showSwitch
                checked: page.checked
                Accessible.name: page.switchLabel
                onToggled: page.toggled(checked)
            }
        }

        PlasmaComponents3.ScrollView {
            Layout.fillWidth: true
            // Uses the popup's fixed height; the list scrolls inside it.
            Layout.fillHeight: true
            visible: page.listVisible

            ListView {
                id: list
                clip: true
                section.property: page.sectionProperty
                section.delegate: page.sectionDelegate
                spacing: Kirigami.Units.smallSpacing
                keyNavigationEnabled: true
                activeFocusOnTab: true
                highlightMoveDuration: 0
                KeyNavigation.backtab: backButton

                PlasmaExtras.PlaceholderMessage {
                    anchors.centerIn: parent
                    width: parent.width - Kirigami.Units.gridUnit * 2
                    visible: list.count === 0
                    text: page.placeholderText
                }
            }
        }

        // Keeps the settings button at the bottom while the list is hidden.
        Item {
            Layout.fillHeight: true
            visible: !page.listVisible
        }

        PlasmaComponents3.ToolButton {
            Layout.fillWidth: true
            visible: page.settingsModule.length > 0
            icon.name: "configure-symbolic"
            text: page.settingsLabel
            onClicked: KCMUtils.KCMLauncher.openSystemSettings(page.settingsModule)
        }
    }
}
