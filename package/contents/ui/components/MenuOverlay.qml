/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

// A menu card that floats over the popup content, next to the control that
// opened it. The popup is a real window: changing its size makes Plasma
// resize and reposition it, which flickers on Wayland, so menus never
// change the popup size and can animate freely.
Item {
    id: overlay

    // Item the card is attached to; the card opens below it, or above when there is no room.
    property Item anchorItem
    property bool open: false
    property Component sourceComponent
    readonly property Item item: loader.item

    signal dismissed()

    anchors.fill: parent
    visible: open || hideAnimation.running
    z: 100

    readonly property real gap: Kirigami.Units.smallSpacing
    readonly property real maxCardHeight: height - gap * 2

    function place() {
        if (!anchorItem) {
            return;
        }
        const anchorPos = anchorItem.mapToItem(overlay, 0, 0);
        const cardHeight = Math.min(loader.implicitHeight, maxCardHeight);
        const below = anchorPos.y + anchorItem.height + gap;
        card.targetY = below + cardHeight <= height - gap
            ? below
            : Math.max(gap, anchorPos.y - gap - cardHeight);
        card.opensUpward = card.targetY < anchorPos.y;
    }

    onOpenChanged: {
        if (open) {
            hideAnimation.stop();
            place();
            showAnimation.restart();
            Qt.callLater(() => card.nextItemInFocusChain(true)?.forceActiveFocus(Qt.TabFocusReason));
        } else {
            showAnimation.stop();
            hideAnimation.restart();
        }
    }

    // Dims the content behind the menu; clicking it closes the menu.
    Rectangle {
        id: scrim
        anchors.fill: parent
        radius: Kirigami.Units.cornerRadius
        color: Kirigami.Theme.backgroundColor
        opacity: 0

        MouseArea {
            anchors.fill: parent
            onClicked: overlay.dismissed()
            onWheel: wheel => wheel.accepted = true
        }
    }

    Kirigami.ShadowedRectangle {
        id: card

        property real targetY: 0
        property bool opensUpward: false

        x: 0
        y: targetY
        width: parent.width
        height: Math.min(loader.implicitHeight, overlay.maxCardHeight)
        radius: Kirigami.Units.cornerRadius * 2
        color: Kirigami.Theme.backgroundColor
        shadow.size: Kirigami.Units.gridUnit
        shadow.color: Qt.rgba(0, 0, 0, 0.35)
        shadow.yOffset: 2
        transformOrigin: opensUpward ? Item.Bottom : Item.Top

        PlasmaComponents3.ScrollView {
            anchors.fill: parent

            Loader {
                id: loader
                width: card.width
                active: overlay.visible
                sourceComponent: overlay.sourceComponent
                onLoaded: overlay.place()
                onImplicitHeightChanged: if (overlay.open) overlay.place()
            }
        }
    }

    // Kirigami durations follow the system animation speed (0 when animations are off).
    ParallelAnimation {
        id: showAnimation
        NumberAnimation { target: scrim; property: "opacity"; from: 0; to: 0.5; duration: Kirigami.Units.longDuration }
        NumberAnimation { target: card; property: "opacity"; from: 0; to: 1; duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
        NumberAnimation { target: card; property: "scale"; from: 0.94; to: 1; duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
        NumberAnimation {
            target: card
            property: "y"
            from: card.targetY + (card.opensUpward ? Kirigami.Units.gridUnit : -Kirigami.Units.gridUnit)
            to: card.targetY
            duration: Kirigami.Units.longDuration
            easing.type: Easing.OutCubic
        }
    }

    ParallelAnimation {
        id: hideAnimation
        NumberAnimation { target: scrim; property: "opacity"; to: 0; duration: Kirigami.Units.shortDuration }
        NumberAnimation { target: card; property: "opacity"; to: 0; duration: Kirigami.Units.shortDuration; easing.type: Easing.InCubic }
        NumberAnimation { target: card; property: "scale"; to: 0.96; duration: Kirigami.Units.shortDuration; easing.type: Easing.InCubic }
    }
}
