#!/usr/bin/env bash
# Development helper: ./dev.sh install | run | package | remove
set -euo pipefail

cd "$(dirname "$0")"
ID=$(sed -n 's/.*"Id": "\(.*\)".*/\1/p' package/metadata.json)
VERSION=$(sed -n 's/.*"Version": "\(.*\)".*/\1/p' package/metadata.json)

case "${1:-}" in
    install)
        if kpackagetool6 --type Plasma/Applet --show "$ID" >/dev/null 2>&1; then
            kpackagetool6 --type Plasma/Applet --upgrade package
        else
            kpackagetool6 --type Plasma/Applet --install package
        fi
        ;;
    run)
        "$0" install
        QT_FORCE_STDERR_LOGGING=1 QT_LOGGING_RULES="js.debug=true;qml.debug=true" plasmawindowed "$ID"
        ;;
    package)
        mkdir -p dist
        rm -f "dist/$ID-$VERSION.plasmoid"
        (cd package && zip -qr "../dist/$ID-$VERSION.plasmoid" .)
        echo "dist/$ID-$VERSION.plasmoid"
        ;;
    remove)
        kpackagetool6 --type Plasma/Applet --remove "$ID"
        ;;
    *)
        echo "usage: $0 install | run | package | remove" >&2
        exit 1
        ;;
esac
