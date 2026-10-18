/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Controls as QQC2
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCMUtils

import "components"

// The PlasmaDeck popup: sliders, the toggle grid and the notification list
// on the main page, the Wi-Fi and Bluetooth lists as sub-pages, and the device,
// power mode and clipboard pickers as floating menus (MenuOverlay).
PlasmaExtras.Representation {
    id: full

    required property PlasmoidItem plasmoidItem

    readonly property Item audio: plasmoidItem.audio
    readonly property Item brightness: plasmoidItem.brightness
    readonly property Item network: plasmoidItem.network
    readonly property Item bluetooth: plasmoidItem.bluetooth
    readonly property Item powerProfiles: plasmoidItem.powerProfiles
    readonly property Item dnd: plasmoidItem.dnd
    readonly property Item nightLight: plasmoidItem.nightLight
    readonly property Item theme: plasmoidItem.theme
    readonly property Item battery: plasmoidItem.battery
    readonly property Item notifications: plasmoidItem.notifications
    readonly property Item clipboard: plasmoidItem.clipboard

    // Only one inline menu is open at a time, as in GNOME.
    property string openMenu: ""

    function toggleMenu(name) {
        openMenu = openMenu === name ? "" : name;
    }

    // Sub-views (Wi-Fi, Bluetooth) replace the main page, as in GNOME.
    property Item pageOpener: null

    function openPage(page) {
        openMenu = "";
        pageOpener = Window.activeFocusItem;
        stack.push(page === "wifi" ? wifiPage : bluetoothPage);
        stack.currentItem.forceActiveFocus(Qt.TabFocusReason);
    }

    function closePage() {
        if (stack.depth > 1) {
            stack.pop();
            // Give focus back to the arrow that opened the page.
            (pageOpener ?? mainPage.nextItemInFocusChain()).forceActiveFocus(Qt.TabFocusReason);
            pageOpener = null;
        }
    }

    function focusFirst() {
        mainPage.nextItemInFocusChain(true).forceActiveFocus(Qt.TabFocusReason);
    }

    // The popup keeps the main page's height on every page and while menus are open:
    // resizing the popup window makes Plasma move it, which flickers on Wayland.
    readonly property real pageHeight: content.implicitHeight

    Layout.minimumWidth: Kirigami.Units.gridUnit * 20
    Layout.preferredWidth: Kirigami.Units.gridUnit * 22
    Layout.minimumHeight: pageHeight + Kirigami.Units.largeSpacing * 2
    Layout.preferredHeight: Layout.minimumHeight
    Layout.maximumHeight: Layout.minimumHeight
    collapseMarginsHint: true

    Keys.onEscapePressed: {
        if (stack.depth > 1) {
            closePage();
        } else if (openMenu !== "") {
            openMenu = "";
        } else {
            plasmoidItem.expanded = false;
        }
    }

    Connections {
        target: full.plasmoidItem
        function onExpandedChanged() {
            if (!full.plasmoidItem.expanded) {
                full.openMenu = "";
                stack.pop(null, QQC2.StackView.Immediate);
            } else {
                Qt.callLater(full.focusFirst);
            }
        }
    }

    component SlideTransition: Transition {
        property real fromX
        property real toX
        NumberAnimation {
            property: "x"
            from: fromX
            to: toX
            duration: Kirigami.Units.longDuration
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            property: "opacity"
            from: fromX === 0 ? 1 : 0
            to: toX === 0 ? 1 : 0
            duration: Kirigami.Units.longDuration
        }
    }

    QQC2.StackView {
        id: stack
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        clip: true
        initialItem: mainPage

        pushEnter: SlideTransition { fromX: stack.width; toX: 0 }
        pushExit: SlideTransition { fromX: 0; toX: -stack.width }
        popEnter: SlideTransition { fromX: -stack.width; toX: 0 }
        popExit: SlideTransition { fromX: 0; toX: stack.width }
    }

    // Menus float over the content instead of resizing the popup.
    Item {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        visible: stack.depth === 1

        MenuOverlay {
            anchorItem: volumeRow
            open: full.openMenu === "audio" && volumeRow.visible
            onDismissed: full.openMenu = ""
            sourceComponent: AudioDeviceMenu {
                audio: full.audio
            }
        }

        MenuOverlay {
            anchorItem: microphoneRow
            open: full.openMenu === "microphone" && microphoneRow.visible
            onDismissed: full.openMenu = ""
            sourceComponent: AudioDeviceMenu {
                audio: full.audio
                input: true
            }
        }

        MenuOverlay {
            anchorItem: clipboardToggle
            open: full.openMenu === "clipboard" && full.clipboard !== null
            onDismissed: full.openMenu = ""
            sourceComponent: ClipboardMenu {
                clipboard: full.clipboard
                onChosen: full.openMenu = ""
            }
        }

        MenuOverlay {
            anchorItem: powerProfileToggle
            open: full.openMenu === "power" && (full.powerProfiles?.available ?? false)
            onDismissed: full.openMenu = ""
            sourceComponent: ChoiceMenu {
                title: i18n("Power Mode")
                iconName: "speedometer-symbolic"
                choices: full.powerProfiles.profiles.map(profile => ({
                    text: full.powerProfiles.displayName(profile),
                    icon: full.powerProfiles.iconName(profile),
                    checked: profile === full.powerProfiles.activeProfile,
                }))
                onChosen: index => full.powerProfiles.setProfile(full.powerProfiles.profiles[index])
            }
        }
    }

    CommandRunner {
        id: commandRunner
    }

    Component {
        id: wifiPage
        WifiPage {
            network: full.network
            onBack: full.closePage()
        }
    }

    Component {
        id: bluetoothPage
        BluetoothPage {
            bluetooth: full.bluetooth
            onBack: full.closePage()
        }
    }

    Item {
        id: mainPage
        implicitHeight: content.implicitHeight

        ColumnLayout {
            id: content
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Kirigami.Units.smallSpacing

            // Volume
            SliderRow {
                id: volumeRow
                Layout.fillWidth: true
                visible: full.audio !== null && full.audio.hasSink

                readonly property var sink: full.audio?.sink ?? null

                iconName: full.audio?.panelIcon ?? ""
                iconButtonLabel: full.audio?.muted ? i18n("Unmute") : i18n("Mute")
                accessibleName: i18n("Volume of %1", full.audio?.deviceName(sink) ?? "")
                from: 0
                to: full.audio ? full.audio.maximumFor(sink) : 100
                stepSize: (full.audio?.normalVolume ?? 100) / 100
                value: sink ? sink.volume : 0
                dimmed: full.audio?.muted ?? false

                expandable: true
                expanded: full.openMenu === "audio"
                expandLabel: i18n("Select audio device")

                onIconClicked: full.audio.toggleMute(sink)
                onMoved: value => full.audio.setVolume(sink, value)
                onReleased: full.audio.playFeedback()
                onExpandToggled: full.toggleMenu("audio")
            }

            // Microphone: shown whenever an input device is connected.
            SliderRow {
                id: microphoneRow
                Layout.fillWidth: true
                visible: full.audio !== null && full.audio.hasSource

                readonly property var source: full.audio?.source ?? null

                iconName: full.audio?.sourceIcon ?? ""
                iconButtonLabel: full.audio?.sourceMuted ? i18n("Unmute microphone") : i18n("Mute microphone")
                accessibleName: i18n("Microphone volume of %1", full.audio?.deviceName(source) ?? "")
                from: 0
                to: full.audio ? full.audio.maximumFor(source) : 100
                stepSize: (full.audio?.normalVolume ?? 100) / 100
                value: source ? source.volume : 0
                dimmed: full.audio?.sourceMuted ?? false

                expandable: true
                expanded: full.openMenu === "microphone"
                expandLabel: i18n("Select microphone")

                onIconClicked: full.audio.toggleMute(source)
                onMoved: value => full.audio.setVolume(source, value)
                onExpandToggled: full.toggleMenu("microphone")
            }

            // Brightness: one slider per controllable display.
            Repeater {
                model: full.brightness && full.brightness.available ? full.brightness.displays : null
                delegate: SliderRow {
                    required property string displayName
                    required property string label
                    required property int brightness
                    required property int maxBrightness

                    Layout.fillWidth: true
                    iconName: "display-brightness-symbolic"
                    iconInteractive: false
                    accessibleName: i18n("Brightness of %1", label)
                    from: 0
                    to: maxBrightness
                    stepSize: Math.max(1, maxBrightness / 100)
                    value: brightness
                    onMoved: value => full.brightness.setBrightness(displayName, value)
                }
            }

            // Toggles
            GridLayout {
                id: toggleGrid
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                columns: 2
                uniformCellWidths: true
                rowSpacing: Kirigami.Units.smallSpacing * 2
                columnSpacing: Kirigami.Units.smallSpacing * 2

                QuickToggle {
                    Layout.fillWidth: true
                    visible: full.network?.wifiPresence.shown ?? false
                    unavailable: full.network?.wifiPresence.unavailable ?? false
                    checked: full.network?.wifiEnabled ?? false
                    iconName: !checked ? "network-wireless-disconnected-symbolic" : "network-wireless-symbolic"
                    title: i18n("Wi-Fi")
                    subtitle: !checked ? "" : (full.network.wifiNetworkName || i18n("Not connected"))
                    hasMenu: true
                    menuLabel: i18n("Show Wi-Fi networks")
                    onToggled: full.network.setWifiEnabled(!checked)
                    onMenuRequested: full.openPage("wifi")
                }

                QuickToggle {
                    Layout.fillWidth: true
                    visible: full.bluetooth?.presence.shown ?? false
                    unavailable: full.bluetooth?.presence.unavailable ?? false
                    checked: full.bluetooth?.powered ?? false
                    iconName: !checked ? "network-bluetooth-inactive-symbolic" : (full.bluetooth.connectedDevices.length > 0 ? "network-bluetooth-activated-symbolic" : "network-bluetooth-symbolic")
                    title: i18n("Bluetooth")
                    subtitle: full.bluetooth?.statusText ?? ""
                    hasMenu: true
                    menuLabel: i18n("Show Bluetooth devices")
                    onToggled: full.bluetooth.setEnabled(!checked)
                    onMenuRequested: full.openPage("bluetooth")
                }

                QuickToggle {
                    id: powerProfileToggle
                    Layout.fillWidth: true
                    visible: full.powerProfiles?.presence.shown ?? false
                    unavailable: full.powerProfiles?.presence.unavailable ?? false
                    readonly property string profile: full.powerProfiles?.activeProfile ?? ""
                    checked: profile !== "" && profile !== "balanced"
                    iconName: full.powerProfiles?.iconName(profile) ?? ""
                    title: i18n("Power Mode")
                    subtitle: full.powerProfiles?.displayName(profile) ?? ""
                    hasMenu: true
                    menuOpen: full.openMenu === "power"
                    menuLabel: i18n("Choose power mode")
                    onToggled: full.powerProfiles.cycle()
                    onMenuRequested: full.toggleMenu("power")
                }

                QuickToggle {
                    Layout.fillWidth: true
                    visible: full.network?.airplanePresence.shown ?? false
                    unavailable: full.network?.airplanePresence.unavailable ?? false
                    checked: full.network?.airplaneMode ?? false
                    iconName: "network-flightmode-on-symbolic"
                    title: i18n("Airplane Mode")
                    onToggled: full.network.setAirplaneMode(!checked)
                }

                QuickToggle {
                    Layout.fillWidth: true
                    visible: full.dnd?.presence.shown ?? false
                    unavailable: full.dnd?.presence.unavailable ?? false
                    checked: full.dnd?.active ?? false
                    iconName: "notifications-disabled-symbolic"
                    title: i18n("Do Not Disturb")
                    subtitle: full.dnd?.statusText ?? ""
                    onToggled: full.dnd.setActive(!checked)
                }

                QuickToggle {
                    Layout.fillWidth: true
                    visible: full.nightLight?.presence.shown ?? false
                    unavailable: full.nightLight?.presence.unavailable ?? false
                    checked: full.nightLight?.active ?? false
                    busy: full.nightLight?.busy ?? false
                    iconName: "redshift-status-on-symbolic"
                    title: i18n("Night Light")
                    subtitle: full.nightLight?.statusText ?? ""
                    // An inhibited Night Light stays enabled; toggling turns the setting off.
                    onToggled: full.nightLight.setEnabled(!full.nightLight.settingEnabled)
                }

                QuickToggle {
                    Layout.fillWidth: true
                    visible: full.theme !== null
                    checked: full.theme?.darkMode ?? false
                    iconName: "weather-clear-night-symbolic"
                    title: i18n("Dark Style")
                    onToggled: full.theme.setDarkMode(!checked)
                }

                QuickToggle {
                    Layout.fillWidth: true
                    visible: full.battery !== null && full.battery.present
                    checkable: false
                    iconName: full.battery?.panelIcon ?? ""
                    title: i18n("Battery")
                    subtitle: full.battery?.charging
                        ? i18n("%1% · charging", full.battery.percent)
                        : i18nc("Battery percentage", "%1%", full.battery?.percent ?? 0)
                    onToggled: {
                        full.plasmoidItem.expanded = false;
                        KCMUtils.KCMLauncher.openSystemSettings("kcm_powerdevilprofilesconfig");
                    }
                }

                QuickToggle {
                    id: clipboardToggle
                    Layout.fillWidth: true
                    visible: full.clipboard !== null
                    checkable: false
                    iconName: "klipper-symbolic"
                    title: i18n("Clipboard")
                    subtitle: full.clipboard?.currentText ? full.clipboard.preview(full.clipboard.currentText) : i18n("Empty")
                    hasMenu: true
                    menuOpen: full.openMenu === "clipboard"
                    menuLabel: i18n("Show clipboard history")
                    // Nothing to switch on or off: the pill opens the history too.
                    onToggled: full.toggleMenu("clipboard")
                    onMenuRequested: full.toggleMenu("clipboard")
                }

                QuickToggle {
                    Layout.fillWidth: true
                    checkable: false
                    iconName: "camera-photo-symbolic"
                    title: i18n("Screenshot")
                    onToggled: {
                        // Close first so the popup is not in the shot.
                        full.plasmoidItem.expanded = false;
                        commandRunner.exec("spectacle");
                    }
                }
            }

            NotificationList {
                Layout.fillWidth: true
                visible: full.notifications !== null
                backend: full.notifications
            }
        }
    }
}
