/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

import "components"

// Applet root. Loads every backend on its own (see the Backend component below),
// sets the tooltip, and wires notifications and Do Not Disturb together.
// CompactRepresentation is the panel item, FullRepresentation the popup.
PlasmoidItem {
    id: root

    // Each backend is loaded on its own so that a missing or broken module
    // (private Plasma APIs can change between releases) only disables that part.
    component Backend: Loader {
        readonly property Item backend: status === Loader.Ready ? item : null
    }

    readonly property Item network: networkLoader.backend
    readonly property Item audio: audioLoader.backend
    readonly property Item battery: batteryLoader.backend
    readonly property Item brightness: brightnessLoader.backend
    readonly property Item bluetooth: bluetoothLoader.backend
    readonly property Item powerProfiles: powerProfilesLoader.backend
    readonly property Item dnd: dndLoader.backend
    readonly property Item nightLight: nightLightLoader.backend
    readonly property Item theme: themeLoader.backend
    readonly property Item tray: trayLoader.backend
    readonly property Item notifications: notificationsLoader.backend
    readonly property Item clipboard: clipboardLoader.backend

    Backend {
        id: networkLoader
        source: "backends/NetworkBackend.qml"
    }
    Backend {
        id: audioLoader
        source: "backends/AudioBackend.qml"
    }
    Backend {
        id: batteryLoader
        source: "backends/BatteryBackend.qml"
    }
    Backend {
        id: brightnessLoader
        source: "backends/BrightnessBackend.qml"
    }
    Backend {
        id: bluetoothLoader
        source: "backends/BluetoothBackend.qml"
    }
    Backend {
        id: powerProfilesLoader
        source: "backends/PowerProfilesBackend.qml"
    }
    Backend {
        id: dndLoader
        source: "backends/DndBackend.qml"
    }
    Backend {
        id: nightLightLoader
        source: "backends/NightLightBackend.qml"
    }
    Backend {
        id: themeLoader
        source: "backends/ThemeBackend.qml"
    }
    Backend {
        id: trayLoader
        source: "backends/TrayBackend.qml"
    }
    Backend {
        id: notificationsLoader
        source: "backends/NotificationsBackend.qml"
    }
    Backend {
        id: clipboardLoader
        source: "backends/ClipboardBackend.qml"
    }

    Binding {
        target: root.notifications
        property: "inhibited"
        value: root.dnd?.active ?? false
        when: root.notifications !== null
    }

    // On-screen notification bubbles.
    Loader {
        active: root.notifications !== null
        sourceComponent: NotificationPopups {
            backend: root.notifications
            visualParent: root.compactRepresentationItem
        }
    }

    // Like Plasma's Notifications widget: what was listed when the popup closes counts as seen.
    onExpandedChanged: expanded => {
        if (!expanded) {
            notifications?.markAllRead();
        }
    }

    Plasmoid.icon: "preferences-system-symbolic"
    Plasmoid.status: PlasmaCore.Types.ActiveStatus

    toolTipMainText: Plasmoid.title
    toolTipSubText: {
        const lines = [];
        if (network && network.statusText) {
            lines.push(network.statusText);
        }
        if (audio && audio.hasSink) {
            lines.push(audio.muted ? i18n("Volume: muted") : i18n("Volume: %1%", audio.volumePercent));
        }
        if (battery && battery.present) {
            lines.push(i18n("Battery: %1%", battery.percent));
        }
        if (notifications && notifications.statusText) {
            lines.push(notifications.statusText);
        }
        return lines.join("\n");
    }

    preferredRepresentation: compactRepresentation
    switchWidth: Kirigami.Units.gridUnit * 12
    switchHeight: Kirigami.Units.gridUnit * 12

    compactRepresentation: CompactRepresentation {
        plasmoidItem: root
    }

    fullRepresentation: FullRepresentation {
        plasmoidItem: root
    }
}
