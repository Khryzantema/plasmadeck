# PlasmaDeck

A GNOME-style Quick Settings menu for KDE Plasma 6, with its own system tray
and notification center. One compact panel item shows your tray icons and the
network, brightness, volume, battery and notification status; clicking the
status icons opens a single popup with the quick controls.

Written in plain QML (no compiled plugin), using the same Plasma modules and
DBus services the built-in widgets use.

## Features

**Panel**
- System tray icons (StatusNotifierItem: Steam, Discord, Telegram…) right in
  the panel: left click activates (or opens the menu when the app does not
  support activation), middle click runs the secondary action, right click
  opens the app's menu, scrolling is forwarded to the app.
- Items that need attention get a red badge and a subtle pulse; passive items
  are hidden. Items can be pinned to the start or hidden from their menu, and
  shown again from the widget settings.
- Status icons: notifications (plain bell, bell with "!" for unread, crossed-out
  bell for Do Not Disturb), network, brightness, volume and battery.
- Scroll over the volume or brightness icon to change it (Shift for small steps).

**Popup**
- Volume slider with mute and output device picker, including Plasma's
  "Raise maximum volume" (150%) option.
- Microphone slider with mute and input device picker (shown when an input
  device exists).
- Brightness slider per display (internal backlight or DDC/CI monitors).
- Network toggle: Wi-Fi on machines that have it, Ethernet otherwise
  (connect/disconnect the wired connection); its page lists the Ethernet
  connections and the Wi-Fi networks.
- Toggles: Bluetooth (with the device list), Power Mode
  (power-saver / balanced / performance), Airplane Mode, Do Not Disturb,
  Night Light, Dark Style, Battery, Clipboard and Screenshot.
- Clipboard history (full-width pill above the notifications): the last 15 entries (text, links and image thumbnails);
  picking one puts it back on the clipboard. It keeps Plasma's clipboard
  engine running, so history is recorded even without Plasma's system tray.
- Notification history with app icon, actions, close and "Clear".

**Notifications**
- When no other notification server is running (e.g. after removing Plasma's
  system tray), the widget becomes the desktop notification server and shows
  its own popups in the screen corner next to it. Popups follow Plasma's
  notification settings: timeout, Do Not Disturb, critical notifications,
  per-application rules.

**General**
- Follows the Plasma theme (colors, accent color, fonts, icons, dark mode).
- Works on horizontal and vertical panels, on Wayland and X11.
- Hardware that is missing (no battery, backlight, Wi-Fi or Bluetooth) is
  simply not shown. If a DBus service goes away (NetworkManager, BlueZ…), its
  toggle shows "Unavailable" without stale state and recovers by itself.
- Keyboard navigation: Tab, arrow keys, Enter/Space, Esc.
- Animations follow the system animation speed. The popup never resizes while
  in use, so it does not flicker on Wayland.
- Translations: Brazilian Portuguese, German, French, Spanish, Russian,
  Simplified Chinese, Italian, Polish, Japanese, European Portuguese, Dutch,
  Turkish, Ukrainian, Czech, Korean and Traditional Chinese.

## Requirements

- KDE Plasma 6.7 (developed and tested on Plasma 6.7.5, KDE Frameworks 6.31,
  Qt 6.11, Fedora 44 Kinoite, Wayland).
- Optional, for the matching features: NetworkManager, BlueZ,
  power-profiles-daemon or tuned-ppd, UPower, Spectacle.

## Installation

From the release file:

```sh
kpackagetool6 --type Plasma/Applet --install io.github.khryzantema.plasmadeck-1.0.0.plasmoid
```

From a clone of this repository:

```sh
./dev.sh install     # installs or upgrades the package
```

Then right-click the panel → **Add or Manage Widgets…** → search for
**PlasmaDeck**. After upgrading, restart Plasma to load the new version:

```sh
systemctl --user restart plasma-plasmashell
```

### Avoiding duplicate icons

The widget shows the tray icons itself, so remove Plasma's **System Tray**
from the panel (right-click it → **Remove**), or right-click it →
**Configure System Tray…** → **Entries** and set the applications to
"Always hidden".

Plasma's system tray also hosts other widgets. If you remove it, notifications
keep working through PlasmaDeck, but you may want to add standalone
widgets such as **Clipboard** or **KDE Connect** back to the panel.

## Private APIs used

Plasma has no stable QML API for most system controls, so the widget reuses
the modules of Plasma's own widgets where that saves a lot of work, and talks
to the stable DBus services directly everywhere else. Each backend lives in its
own file under `contents/ui/backends/` and is loaded with a `Loader`, so a
module that changes or disappears only disables that part of the widget.

| Feature | Module | Status |
|---|---|---|
| Volume, devices, microphone | `org.kde.plasma.private.volume` (plasma-pa) | private |
| Wi-Fi, airplane mode, network icon | `org.kde.plasma.networkmanagement` (plasma-nm) | internal |
| Brightness, Dark Style | `org.kde.plasma.private.brightnesscontrolplugin` (powerdevil) | private |
| Tray item list and icons | `StatusNotifierModel` from `org.kde.plasma.private.systemtray` | private |
| Clipboard history | `org.kde.plasma.private.clipboard` (Klipper, plasma-workspace) | private |
| Notifications, Do Not Disturb | `org.kde.notificationmanager` (plasma-workspace) | semi-public |
| DBus calls from QML | `org.kde.plasma.workspace.dbus` (plasma-workspace) | semi-public |
| Bluetooth | `org.kde.bluezqt` (KDE Frameworks) | public |
| Battery | UPower over DBus | stable |
| Power Mode | `org.freedesktop.UPower.PowerProfiles` over DBus | stable |
| Night Light | `org.kde.KWin.NightLight` over DBus + `kwinrc` | stable |
| Tray actions and menus | StatusNotifierItem and `com.canonical.dbusmenu` over DBus | stable |

When Plasma updates, the private modules are the first place to look if
something stops working.

## Known limitations

- **XEmbed tray icons** (very old applications) are not supported directly.
  They still show up through Plasma's `xembedsniproxy`, which also runs on
  Wayland (for XWayland apps) and turns them into regular StatusNotifierItems,
  but proxied icons can look blurry and clicks on them are simulated.
- **Activating tray items on Wayland**: Plasma's own tray passes an XDG
  activation token when it activates an app, which a QML-only widget cannot
  obtain. Native Wayland apps may just flash in the task manager instead of
  coming to the front. Apps that bring themselves forward (Steam, most
  XWayland apps) are not affected. Notifications are not affected either: the
  server hands an activation token to the app.
- Tray menus show the `icon-name` of entries but not embedded icon images.
- Notifications: file transfer progress ("jobs"), inline replies and file
  thumbnails are not supported yet.
- Notifications from applications without a `.desktop` file are not kept in
  the history. This is Plasma's default (`/etc/xdg/plasmanotifyrc`), and it can
  be changed in System Settings → Notifications → Configure → Other
  applications → Show in history.
- Night Light is switched on and off through the KWin setting, like GNOME does,
  rather than temporarily inhibited like Plasma's Brightness widget.
- Wi-Fi and Bluetooth lists were developed on a machine without Wi-Fi or a
  working Bluetooth adapter and were only tested with simulated data.

## Development

- `dev.sh install | run | package | remove`: install, run in a window with
  `plasmawindowed`, build the `.plasmoid`, uninstall.
- `probe.sh <snippet.qml> <workdir>`: runs a throwaway copy of the widget
  offscreen with extra QML injected (used to test backends and grab images
  without opening windows).
- `tools/i18n.py extract | update | compile`: translation workflow without
  gettext. User-visible strings are English in the code (`i18n()`);
  translations live in `po/<language>.po` and are compiled into
  `package/contents/locale/`.

## License

GPL-2.0-or-later.
