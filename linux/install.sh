#!/usr/bin/env bash
set -euo pipefail

APP_NAME="yt-dlp-gui"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Allow overriding destinations when running the script.
INSTALL_PREFIX="${INSTALL_PREFIX:-$HOME/.local/share/${APP_NAME}}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
DESKTOP_DIR="${DESKTOP_DIR:-$HOME/.local/share/applications}"
BUILD_MODE="${BUILD_MODE:-release}"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter SDK is not available in PATH. Install Flutter 3.9+ and retry." >&2
  exit 1
fi

case "${BUILD_MODE}" in
  release|profile|debug) ;;
  *)
    echo "Unsupported BUILD_MODE '${BUILD_MODE}'. Use release, profile, or debug." >&2
    exit 1
    ;;
esac

case "$(uname -m)" in
  x86_64|amd64) FLUTTER_ARCH="x64" ;;
  arm64|aarch64) FLUTTER_ARCH="arm64" ;;
  *)
    echo "Unsupported architecture '$(uname -m)'." >&2
    exit 1
    ;;
esac

echo "Building ${APP_NAME} (${BUILD_MODE}) for ${FLUTTER_ARCH}..."
pushd "${REPO_ROOT}" >/dev/null
flutter build linux "--${BUILD_MODE}"
popd >/dev/null

BUNDLE_DIR="${REPO_ROOT}/build/linux/${FLUTTER_ARCH}/${BUILD_MODE}/bundle"
if [[ ! -d "${BUNDLE_DIR}" ]]; then
  echo "Bundle directory ${BUNDLE_DIR} not found. Build may have failed." >&2
  exit 1
fi

echo "Installing bundle into ${INSTALL_PREFIX}..."
rm -rf "${INSTALL_PREFIX}"
mkdir -p "${INSTALL_PREFIX}"
cp -R "${BUNDLE_DIR}/." "${INSTALL_PREFIX}/"

mkdir -p "${BIN_DIR}"
ln -sf "${INSTALL_PREFIX}/${APP_NAME}" "${BIN_DIR}/${APP_NAME}"

DESKTOP_FILE="${DESKTOP_DIR}/${APP_NAME}.desktop"
mkdir -p "${DESKTOP_DIR}"
cat >"${DESKTOP_FILE}" <<EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=${APP_NAME}
Comment=Graphical interface for yt-dlp
Exec=${INSTALL_PREFIX}/${APP_NAME}
Icon=${INSTALL_PREFIX}/data/flutter_assets/assets/yt-dlp/icons/app_icon.ico
Terminal=false
Categories=AudioVideo;Network;
EOF

update_desktop_database() {
  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "${DESKTOP_DIR}" >/dev/null 2>&1 || true
  fi
}

update_desktop_database

echo
echo "Installation complete."
echo "- Binary: ${INSTALL_PREFIX}/${APP_NAME}"
echo "- Symlink: ${BIN_DIR}/${APP_NAME}"
echo "- Desktop file: ${DESKTOP_FILE}"
echo
echo "Add ${BIN_DIR} to your PATH if needed, then run '${APP_NAME}'."
