#!/bin/sh

set -u
export ARCH="$(uname -m)"
export APPIMAGE_EXTRACT_AND_RUN=1
APP=pavucontrol-qt
ICON="https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-icon-theme/master/Papirus/64x64/apps/yast-sound.svg"
APPIMAGETOOL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-$ARCH.AppImage"
LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"
SHARUN="https://github.com/VHSgunzo/sharun/releases/download/v0.0.2/sharun-$ARCH"

# Prepare AppDir
mkdir -p ./"$APP"/AppDir
cd ./"$APP"/AppDir

mv /usr/share/applications/pavucontrol-qt.desktop ./
wget "$ICON" -O multimedia-volume-control.svg
ln -s ./multimedia-volume-control.png ./.DirIcon

cat >> ./AppRun << 'EOF'
#!/bin/sh
CURRENTDIR="$(dirname "$(readlink -f "$0")")"
"$CURRENTDIR/bin/pavucontrol-qt" "$@"
EOF
chmod +x ./AppRun

# ADD LIBRARIES
wget "$LIB4BN" -O ./lib4bin
wget "$SHARUN" -O ./sharun
chmod +x ./lib4bin ./sharun
HARD_LINKS=1 ./lib4bin "$(command -v pavucontrol-qt)"
rm -f ./lib4bin

rm -f ./shared/lib/lib.path || true # forces sharun to regenerate the file
VERSION=$(./AppRun --version | awk 'FNR==1 {print $2; exit}')

# MAKE APPIAMGE WITH FUSE3 COMPATIBLE APPIMAGETOOL
wget -q "$APPIMAGETOOL" -O ./appimagetool 
chmod +x ./appimagetool

./appimagetool --comp zstd --mksquashfs-opt -Xcompression-level --mksquashfs-opt 22 \
	-n -u "gh-releases-zsync|$GITHUB_REPOSITORY_OWNER|rofi-AppImage|continuous|*$ARCH.AppImage.zsync" \
	./"$APP".AppDir "$APP"-"$VERSION"-"$ARCH".AppImage

mv ./*.AppImage ../
cd .. 
rm -rf ./"$APP"
echo "All Done!"
