#!/bin/sh

set -eu
export ARCH="$(uname -m)"
export APPIMAGE_EXTRACT_AND_RUN=1
APP=pavucontrol-qt
ICON="https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-icon-theme/master/Papirus/64x64/apps/yast-sound.svg"
APPIMAGETOOL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-$ARCH.AppImage"
UPINFO="gh-releases-zsync|$(echo $GITHUB_REPOSITORY | tr '/' '|')|latest|*$ARCH.AppImage.zsync"
LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"

# Prepare AppDir
mkdir -p ./"$APP"/AppDir/usr/share/applications
cd ./"$APP"/AppDir

cp /usr/share/applications/pavucontrol-qt.desktop ./usr/share/applications
cp /usr/share/applications/pavucontrol-qt.desktop ./
wget "$ICON" -O multimedia-volume-control.svg
ln -s ./multimedia-volume-control.svg ./.DirIcon

cat >> ./AppRun << 'EOF'
#!/bin/sh
CURRENTDIR="$(dirname "$(readlink -f "$0")")"
[ -f "$APPIMAGE".stylesheet ] && APPIMAGE_QT_THEME="$APPIMAGE.stylesheet"
[ -f "$APPIMAGE_QT_THEME" ] && set -- "$@" "-stylesheet" "$APPIMAGE_QT_THEME"
"$CURRENTDIR/bin/pavucontrol-qt" "$@"
EOF
chmod +x ./AppRun

# ADD LIBRARIES
wget "$LIB4BN" -O ./lib4bin
chmod +x ./lib4bin
./lib4bin -p -w "$(command -v pavucontrol-qt)"
rm -f ./lib4bin

# DELOY QT
mkdir -p ./shared/lib/qt6/plugins
cp -r /usr/lib/qt6/plugins/iconengines       ./shared/lib/qt6/plugins
cp -r /usr/lib/qt6/plugins/imageformats      ./shared/lib/qt6/plugins
cp -r /usr/lib/qt6/plugins/platforms         ./shared/lib/qt6/plugins
cp -r /usr/lib/qt6/plugins/platformthemes    ./shared/lib/qt6/plugins
cp -r /usr/lib/qt6/plugins/styles            ./shared/lib/qt6/plugins
cp -r /usr/lib/qt6/plugins/xcbglintegrations ./shared/lib/qt6/plugins
cp -r /usr/lib/qt6/plugins/wayland-*         ./shared/lib/qt6/plugins

ldd ./shared/lib/qt6/plugins/*/* 2>/dev/null \
  | awk -F"[> ]" '{print $4}' | xargs -I {} cp -nv {} ./shared/lib || true

find ./shared/lib -type f -exec strip -s -R .comment --strip-unneeded {} ';'

./sharun -g # makes sharun generate the lib.path file
VERSION=$(./AppRun --version 2>/dev/null | awk 'NR==1 {print $2; exit}')
if [ -z "$VERSION" ]; then
	VERSION=$(pacman -Q pavucontrol-qt | awk 'NR==1 {print $2; exit}')
fi
export VERSION

# MAKE APPIAMGE WITH FUSE3 COMPATIBLE APPIMAGETOOL
cd ..
wget -q "$APPIMAGETOOL" -O ./appimagetool
chmod +x ./appimagetool

./appimagetool --comp zstd \
	--mksquashfs-opt -Xcompression-level --mksquashfs-opt 22 \
	-n -u "$UPINFO" "$PWD"/AppDir "$PWD"/"$APP"-"$VERSION"-anylinux-"$ARCH".AppImage

mv ./*.AppImage* ../
cd ..
rm -rf ./"$APP"
echo "All Done!"
