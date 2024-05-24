#!/bin/sh

set -u
ARCH=x86_64
APP=pavucontrol
APPDIR="$APP".AppDir
REPO="https://github.com/lxqt/pavucontrol-qt/releases/download/2.0.0/pavucontrol-qt-2.0.0.tar.xz"
ICON="https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-icon-theme/master/Papirus/64x64/apps/yast-sound.svg"
EXEC="$APP-qt"

LINUXDEPLOY="https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-static-x86_64.AppImage"
APPIMAGETOOL=$(wget -q https://api.github.com/repos/probonopd/go-appimage/releases -O - | sed 's/"/ /g; s/ /\n/g' | grep -o 'https.*continuous.*tool.*86_64.*mage$')

# CREATE DIRECTORIES
[ -n "$APP" ] && mkdir -p ./"$APP/$APPDIR" && cd ./"$APP/$APPDIR" || exit 1

# DOWNLOAD AND BUILD PAVUCONTROL
CURRENTDIR="$(readlink -f "$(dirname "$0")")" # DO NOT MOVE THIS
wget "$REPO" -O download.tar.xz && tar fx *tar* && cd pavucontrol* \
&& mkdir ./build && cd ./build && cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr .. \
&& make -j$(nproc) \
&& DESTDIR="$CURRENTDIR" make install \
&& cd ../.. && rm -rf ./pavucontrol* ./download.tar.xz || exit 1

# AppRun
cat >> ./AppRun << 'EOF'
#!/bin/sh
CURRENTDIR="$(dirname "$(readlink -f "$0")")"
"$CURRENTDIR/usr/bin/pavucontrol-qt" "$@"
EOF
chmod a+x ./AppRun

APPVERSION=$(./AppRun --version | awk 'FNR == 1 {print $2}')

# Desktop
mv ./usr/share/applications/*.desktop ./

# Icon
wget "$ICON" -O multimedia-volume-control.svg || touch ./multimedia-volume-control.svg
ln -s ./multimedia-volume-control.png ./.DirIcon

# MAKE APPIMAGE USING FUSE3 COMPATIBLE APPIMAGETOOL
cd .. && wget "$LINUXDEPLOY" -O linuxdeploy && wget -q "$APPIMAGETOOL" -O ./appimagetool && chmod a+x ./linuxdeploy ./appimagetool \
&& ./linuxdeploy --appdir "$APPDIR" --plugin qt --executable "$APPDIR"/usr/bin/"$EXEC" && VERSION="$APPVERSION" ./appimagetool -s ./"$APPDIR" || exit 1

[ -n "$APP" ] && mv ./*.AppImage .. && cd .. && rm -rf ./"$APP" && echo "All Done!" || exit 1
