#!/bin/bash

arg=$1

function initialize {
    meson setup build --prefix=/usr
    result=$?

    if [ $result -gt 0 ]; then
        echo "Unable to initialize, please review log"
        exit 1
    fi

    cd build

    ninja

    result=$?

    if [ $result -gt 0 ]; then
        echo "Unable to build project, please review log"
        exit 2
    fi
}

case $1 in
"clean")
    sudo rm -rf ./build
    ;;
"generate-i18n")
    grep -rc _\( * | grep ^src | grep -v :0 | cut -d : -f 1 | sort -o po/POTFILES
    echo "data/io.github.phase1geo.mosaic-note.shortcuts.ui" >> po/POTFILES
    initialize
    ninja io.github.phase1geo.mosaic-note-pot
    ninja io.github.phase1geo.mosaic-note-update-po
    ninja extra-pot
    ninja extra-update-po
    cp data/* ../data
    ;;
"install")
    initialize
    sudo ninja install
    ;;
"install-deps")
    output=$((dpkg-checkbuilddeps ) 2>&1)
    result=$?

    if [ $result -eq 0 ]; then
        echo "All dependencies are installed"
        exit 0
    fi

    replace="sudo apt install"
    pattern="(\([>=<0-9. ]+\))+"
    sudo_replace=${output/dpkg-checkbuilddeps: error: Unmet build dependencies:/$replace}
    command=$(sed -r -e "s/$pattern//g" <<< "$sudo_replace")
    
    $command
    ;;
"run")
    initialize
    ./io.github.phase1geo.mosaic-note "${@:2}"
    ;;
"debug")
    initialize
    # G_DEBUG=fatal-criticals gdb --args ./io.github.phase1geo.mosaic-note "${@:2}"
    G_DEBUG=fatal-warnings gdb --args ./io.github.phase1geo.mosaic-note "${@:2}"
    ;;
"valgrind")
    initialize
    valgrind ./io.github.phase1geo.mosaic-note "${@:2}"
    ;;
"uninstall")
    initialize
    sudo ninja uninstall
    ;;
"elementary")
    flatpak-builder --user --install --force-clean ../build-mosaic-note-elementary elementary/io.github.phase1geo.mosaic-note.yml
    # flatpak install --user --reinstall --assumeyes "$(pwd)/.flatpak-builder/cache" io.github.phase1geo.mosaicnote.Debug
    ;;
"flathub")
    flatpak-builder --user --install --force-clean ../build-mosaic-note-flathub flathub/io.github.phase1geo.mosaic-note.yml
    # flatpak install --user --reinstall --assumeyes "$(pwd)/.flatpak-builder/cache" io.github.phase1geo.mosaicnote.Debug
    ;;
"run-flatpak")
    flatpak run io.github.phase1geo.mosaic-note
    ;;
"debug-flatpak")
    flatpak run --command=sh --devel io.github.phase1geo.mosaic-note
    ;;
*)
    echo "Usage:"
    echo "  ./app [OPTION]"
    echo ""
    echo "Options:"
    echo "  clean             Removes build directories (can require sudo)"
    echo "  generate-i18n     Generates .pot and .po files for i18n (multi-language support)"
    echo "  install           Builds and installs application to the system (requires sudo)"
    echo "  install-deps      Installs missing build dependencies"
    echo "  run               Builds and runs the application (must run install once before successive calls to this command)"
    echo "  debug             Builds and runs the application in gdb debug mode"
    echo "  valgrind          Builds and runs the application using Valgrid"
    echo "  uninstall         Removes the application from the system (requires sudo)"
    echo "  elementary        Builds and installs the elementary OS Flatpak version of the application"
    echo "  flathub           Builds and installs the Flathub Flatpak version of the application"
    echo "  run-flatpak       Runs the installed Flatpak version of the application"
    echo "  debug-flatpak     Runs the installed Flatpak version of the application in gdb debug mode"
    ;;
esac
