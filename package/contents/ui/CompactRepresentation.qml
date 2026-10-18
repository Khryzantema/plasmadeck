/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

import "components"

// Panel content: the system tray icons, followed by the GNOME-style status
// cluster (network, brightness, volume, battery) that opens the popup.
Item {
    id: compact

    required property PlasmoidItem plasmoidItem

    // Follows the panel; overridable for previews and tests.
    property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property int thickness: vertical ? width : height
    readonly property int iconSize: Kirigami.Units.iconSizes.roundedIconSize(Math.min(thickness, Kirigami.Units.iconSizes.smallMedium))
    readonly property Item tray: plasmoidItem.tray

    readonly property var icons: [
        { kind: "notifications", name: plasmoidItem.notifications?.panelIcon ?? "" },
        { kind: "network", name: plasmoidItem.network?.panelIcon ?? "" },
        { kind: "brightness", name: plasmoidItem.brightness?.panelIcon ?? "" },
        { kind: "audio", name: plasmoidItem.audio?.panelIcon ?? "" },
        { kind: "battery", name: plasmoidItem.battery?.panelIcon ?? "" },
    ].filter(icon => icon.name.length > 0)

    Layout.minimumWidth: vertical ? Kirigami.Units.iconSizes.small : layout.implicitWidth
    Layout.minimumHeight: vertical ? layout.implicitHeight : Kirigami.Units.iconSizes.small
    Layout.preferredWidth: Layout.minimumWidth
    Layout.preferredHeight: Layout.minimumHeight

    GridLayout {
        id: layout
        anchors.centerIn: parent
        flow: compact.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
        rows: compact.vertical ? -1 : 1
        columns: compact.vertical ? 1 : -1
        rowSpacing: 0
        columnSpacing: 0

        Repeater {
            model: compact.tray?.pinnedModel ?? null
            delegate: PanelTrayItem {
                tray: compact.tray
                trayMenu: panelTrayMenu
                iconSize: compact.iconSize
            }
        }

        Repeater {
            model: compact.tray?.otherModel ?? null
            delegate: PanelTrayItem {
                tray: compact.tray
                trayMenu: panelTrayMenu
                iconSize: compact.iconSize
            }
        }

        // Status cluster: clicking it opens the popup.
        MouseArea {
            id: cluster

            Layout.preferredWidth: icons.implicitWidth + Kirigami.Units.smallSpacing * 2
            Layout.preferredHeight: icons.implicitHeight + Kirigami.Units.smallSpacing * 2
            Layout.fillWidth: compact.vertical
            Layout.fillHeight: !compact.vertical

            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            activeFocusOnTab: true

            property bool wasExpanded: false
            onPressed: wasExpanded = compact.plasmoidItem.expanded
            onClicked: compact.plasmoidItem.expanded = !wasExpanded

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Select) {
                    compact.plasmoidItem.expanded = !compact.plasmoidItem.expanded;
                    event.accepted = true;
                }
            }

            Accessible.role: Accessible.Button
            Accessible.name: Plasmoid.title
            Accessible.description: compact.plasmoidItem.toolTipSubText
            Accessible.onPressAction: compact.plasmoidItem.expanded = !compact.plasmoidItem.expanded

            GridLayout {
                id: icons
                anchors.centerIn: parent
                flow: compact.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
                rows: compact.vertical ? -1 : 1
                columns: compact.vertical ? 1 : -1
                rowSpacing: Kirigami.Units.smallSpacing
                columnSpacing: Kirigami.Units.smallSpacing

                Repeater {
                    model: compact.icons
                    delegate: Kirigami.Icon {
                        required property var modelData
                        Layout.preferredWidth: compact.iconSize
                        Layout.preferredHeight: compact.iconSize
                        source: modelData.name
                        active: cluster.containsMouse || cluster.activeFocus
                        // Icons shipped with the applet are plain files: tint them like theme symbolic icons.
                        isMask: modelData.name.startsWith("file:")
                        color: Kirigami.Theme.textColor

                        // Scrolling over the volume or brightness icon adjusts it; clicks pass through.
                        MouseArea {
                            anchors.fill: parent
                            // Cover the spacing around the icon so scrolling does not miss it.
                            anchors.margins: -Kirigami.Units.smallSpacing
                            enabled: parent.modelData.kind === "audio" || parent.modelData.kind === "brightness"
                            acceptedButtons: Qt.NoButton

                            property int wheelDelta: 0

                            function step(up, small) {
                                if (parent.modelData.kind === "audio") {
                                    up ? compact.plasmoidItem.audio?.volumeUp(small) : compact.plasmoidItem.audio?.volumeDown(small);
                                } else {
                                    up ? compact.plasmoidItem.brightness?.stepUp(small) : compact.plasmoidItem.brightness?.stepDown(small);
                                }
                            }

                            onWheel: wheel => {
                                const delta = (wheel.inverted ? -1 : 1) * (wheel.angleDelta.y ? wheel.angleDelta.y : -wheel.angleDelta.x);
                                // Drop any remainder when the scroll direction changes.
                                if ((wheelDelta > 0 && delta < 0) || (wheelDelta < 0 && delta > 0)) {
                                    wheelDelta = 0;
                                }
                                wheelDelta += delta;
                                // 120 is one notch of a regular mouse wheel; touchpads send smaller deltas.
                                const small = (wheel.modifiers & Qt.ShiftModifier) !== 0;
                                while (wheelDelta >= 120) {
                                    wheelDelta -= 120;
                                    step(true, small);
                                }
                                while (wheelDelta <= -120) {
                                    wheelDelta += 120;
                                    step(false, small);
                                }
                            }
                        }
                    }
                }

                // Shown when nothing reports an icon yet (e.g. all services down).
                Kirigami.Icon {
                    visible: compact.icons.length === 0
                    Layout.preferredWidth: compact.iconSize
                    Layout.preferredHeight: compact.iconSize
                    source: Plasmoid.icon
                }
            }

            // Keyboard focus ring.
            Rectangle {
                anchors.fill: parent
                visible: cluster.activeFocus
                color: "transparent"
                radius: Kirigami.Units.cornerRadius
                border.width: 1
                border.color: Kirigami.Theme.focusColor
            }
        }
    }

    TrayMenu {
        id: panelTrayMenu
        tray: compact.tray
    }
}
