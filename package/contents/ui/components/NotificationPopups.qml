/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

// On-screen notification bubbles, stacked in the screen corner next to the
// applet (below a top panel, above a bottom one).
Item {
    id: popups

    required property Item backend
    // The panel item, used to pick the left or right corner.
    property Item visualParent

    // True while the PlasmaDeck popup is open.
    property bool hidden: false

    // Opening the popup dismisses the bubbles for good: they stay in the notification list.
    onHiddenChanged: {
        if (hidden) {
            for (let i = backend.popups.rowCount() - 1; i >= 0; i--) {
                backend.expire(backend.popups, i);
            }
        }
    }

    // Every bubble stays on screen for this long (ms), whatever the notification asks for.
    readonly property int bubbleTimeout: 5000

    readonly property int popupWidth: Kirigami.Units.gridUnit * 20
    readonly property int spacing: Kirigami.Units.largeSpacing
    readonly property int edgeDistance: Kirigami.Units.largeSpacing

    readonly property rect screenRect: {
        const containment = Plasmoid.containment;
        if (!containment) {
            return Qt.rect(0, 0, -1, -1);
        }
        // availableScreenRect is relative to the screen and excludes panels.
        return Qt.rect(containment.screenGeometry.x + containment.availableScreenRect.x,
                       containment.screenGeometry.y + containment.availableScreenRect.y,
                       containment.availableScreenRect.width,
                       containment.availableScreenRect.height);
    }
    readonly property bool atTop: Plasmoid.location !== PlasmaCore.Types.BottomEdge
    readonly property bool atRight: {
        if (Plasmoid.location === PlasmaCore.Types.LeftEdge) {
            return false;
        }
        if (Plasmoid.location === PlasmaCore.Types.RightEdge || !visualParent) {
            return true;
        }
        return visualParent.mapToGlobal(visualParent.width / 2, 0).x > screenRect.x + screenRect.width / 2;
    }

    onScreenRectChanged: relayout()
    onAtRightChanged: relayout()

    function bubbleAt(i) {
        return bubbles.objectAt(i);
    }

    function relayout() {
        if (screenRect.width <= 0) {
            return;
        }
        let y = atTop ? screenRect.y + edgeDistance : screenRect.y + screenRect.height - edgeDistance;
        for (let i = 0; i < bubbles.count; i++) {
            const dialog = bubbleAt(i);
            if (!dialog) {
                continue;
            }
            dialog.x = atRight ? screenRect.x + screenRect.width - edgeDistance - dialog.width : screenRect.x + edgeDistance;
            if (atTop) {
                dialog.y = y;
                y += dialog.height + spacing;
            } else {
                y -= dialog.height;
                dialog.y = y;
                y -= spacing;
            }
        }
    }

    Instantiator {
        id: bubbles
        model: popups.backend.popups

        onObjectAdded: Qt.callLater(popups.relayout)
        onObjectRemoved: Qt.callLater(popups.relayout)

        delegate: PlasmaCore.Dialog {
            id: dialog

            required property var model
            required property int index

            readonly property int timeout: popups.bubbleTimeout

            type: PlasmaCore.Dialog.Tooltip
            flags: Qt.WindowDoesNotAcceptFocus
            location: PlasmaCore.Types.Floating
            hideOnWindowDeactivate: false
            visible: false

            onWidthChanged: popups.relayout()
            onHeightChanged: popups.relayout()

            Component.onCompleted: {
                popups.relayout();
                // Shown by assignment (not a binding): a bound visible makes the window appear
                // without ever being drawn. Nothing new pops up while the PlasmaDeck popup is open.
                visible = !popups.hidden;
                popups.backend.popups.playSoundHint(popups.backend.index(popups.backend.popups, index));
            }

            // Follows the PlasmaDeck popup: a bubble open at that moment is taken off the screen.
            readonly property bool suppressed: popups.hidden
            onSuppressedChanged: if (suppressed) visible = false

            mainItem: NotificationCard {
                id: card
                width: popups.popupWidth
                notification: dialog.model
                color: "transparent"
                onDefaultActionInvoked: popups.backend.invokeDefault(popups.backend.popups, dialog.index)
                onActionInvoked: actionId => popups.backend.invokeAction(popups.backend.popups, dialog.index, actionId)
                onCloseClicked: {
                    // A running job cannot be closed: just take its bubble off the screen.
                    if (popups.backend.isJobActive(dialog.model)) {
                        popups.backend.expire(popups.backend.popups, dialog.index);
                    } else {
                        popups.backend.close(popups.backend.popups, dialog.index);
                    }
                }
                onSuspendClicked: popups.backend.suspendJob(popups.backend.popups, dialog.index)
                onResumeClicked: popups.backend.resumeJob(popups.backend.popups, dialog.index)
                onKillClicked: popups.backend.killJob(popups.backend.popups, dialog.index)

                // Paused while the pointer is over the bubble.
                Timer {
                    interval: dialog.timeout
                    running: dialog.timeout > 0 && !card.hovered
                    onTriggered: popups.backend.expire(popups.backend.popups, dialog.index)
                }
            }
        }
    }
}
