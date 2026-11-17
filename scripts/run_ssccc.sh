#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUT_BIN="/tmp/SSCCCApp"
SPM_BIN="${ROOT_DIR}/app/.build/out/Products/Debug/SSCCCApp"
if [[ ! -x "${SPM_BIN}" ]]; then
  SPM_BIN="${ROOT_DIR}/app/.build/debug/SSCCCApp"
fi

BUILD_ONLY=0
if [[ "${1:-}" == "--build-only" ]]; then
  BUILD_ONLY=1
fi
SKIP_BUILD="${SSCCC_SKIP_BUILD:-0}"
unset SSCCC_SKIP_BUILD || true

SWIFT_REL_FILES=(
  "Models/ClusterModels.swift"
  "Models/Localization.swift"
  "Models/GatewayStrings.swift"
  "ViewModels/ClusterViewModel.swift"
  "ViewModels/LiveCluster.swift"
  "ViewModels/SetupTool.swift"
  "ViewModels/GatewayClient.swift"
  "Views/Theme.swift"
  "Views/ClusterOverviewView.swift"
  "Views/DevicesCompareView.swift"
  "Views/ModelStudioView.swift"
  "Views/NetworkRdmaView.swift"
  "Views/InternetClusterView.swift"
  "Views/MultiModelModeView.swift"
  "Views/AgentIntegrationsView.swift"
  "Views/ScienceBenchmarksView.swift"
  "Views/ApiConsoleView.swift"
  "Views/ClusterSetupView.swift"
  "Views/HelpDocDeepDiveContent.swift"
  "Views/HelpDocsView.swift"
  "Views/ImageStudioView.swift"
  "Views/GatewayPanels.swift"
  "SSCCCApp.swift"
)

if [[ "${BUILD_ONLY}" != "1" && "${SKIP_BUILD}" == "1" && -x "${OUT_BIN}" ]]; then
  echo "Überspringe Build (SSCCC_SKIP_BUILD=1), starte bestehendes Binary ${OUT_BIN}..."
else
  echo "Baue SonnerStudio Cluster-Case-Companion (SS-CCC)..."
  STAGE_DIR="/tmp/ssccc_src_stage"
  MOD_CACHE="/tmp/ssccc_modcache"
  rm -rf "${STAGE_DIR}"
  mkdir -p "${STAGE_DIR}/Models" "${STAGE_DIR}/ViewModels" "${STAGE_DIR}/Views" "${MOD_CACHE}"

  STAGE_ARGS=()
  for rel in "${SWIFT_REL_FILES[@]}"; do
    cp -f "${ROOT_DIR}/app/Sources/${rel}" "${STAGE_DIR}/${rel}"
    STAGE_ARGS+=("${STAGE_DIR}/${rel}")
  done

  if swiftc \
    -module-cache-path "${MOD_CACHE}" \
    -parse-as-library \
    -target arm64-apple-macosx14.0 \
    -sdk "$(xcrun --show-sdk-path)" \
    -o "${OUT_BIN}.new" \
    "${STAGE_ARGS[@]}"; then
    chmod 755 "${OUT_BIN}.new"
    mv -f "${OUT_BIN}.new" "${OUT_BIN}"
  elif [[ -x "${SPM_BIN}" ]]; then
    echo "Warnung: swiftc fehlgeschlagen — nutze Fallback-Binary ${SPM_BIN}..."
    cp -f "${SPM_BIN}" "${OUT_BIN}.new"
    chmod 755 "${OUT_BIN}.new"
    mv -f "${OUT_BIN}.new" "${OUT_BIN}"
  else
    echo "Fehler: Kompilierung fehlgeschlagen und kein Fallback-Binary vorhanden." >&2
    exit 1
  fi
fi

if [[ "${BUILD_ONLY}" == "1" ]]; then
  exit 0
fi

echo "Starte SS-CCC..."
pkill -f "^${OUT_BIN}$" 2>/dev/null || true
sleep 0.2
export SSCCC_BG_PATH="${ROOT_DIR}/app/Resources/solaris_bg.png"
export SSCCC_SIDEBAR_BG_PATH="${ROOT_DIR}/app/Resources/solaris_sidebar_bg.png"
export SSCCC_ICON_PATH="${ROOT_DIR}/app/Resources/ssccc_app_icon.png"
exec "${OUT_BIN}"
