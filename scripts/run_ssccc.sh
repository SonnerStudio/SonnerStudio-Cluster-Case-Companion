#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUT_BIN="/tmp/SSCCCApp"

echo "Baue SonnerStudio Cluster-Case-Companion (SS-CCC)..."
swiftc -parse-as-library \
  -target arm64-apple-macosx14.0 \
  -sdk "$(xcrun --show-sdk-path)" \
  -o "${OUT_BIN}" \
  "${ROOT_DIR}/app/Sources/Models/ClusterModels.swift" \
  "${ROOT_DIR}/app/Sources/Models/Localization.swift" \
  "${ROOT_DIR}/app/Sources/ViewModels/ClusterViewModel.swift" \
  "${ROOT_DIR}/app/Sources/Views/Theme.swift" \
  "${ROOT_DIR}/app/Sources/Views/ClusterOverviewView.swift" \
  "${ROOT_DIR}/app/Sources/Views/DevicesCompareView.swift" \
  "${ROOT_DIR}/app/Sources/Views/ModelStudioView.swift" \
  "${ROOT_DIR}/app/Sources/Views/NetworkRdmaView.swift" \
  "${ROOT_DIR}/app/Sources/Views/InternetClusterView.swift" \
  "${ROOT_DIR}/app/Sources/Views/MultiModelModeView.swift" \
  "${ROOT_DIR}/app/Sources/Views/AgentIntegrationsView.swift" \
  "${ROOT_DIR}/app/Sources/Views/ScienceBenchmarksView.swift" \
  "${ROOT_DIR}/app/Sources/Views/ApiConsoleView.swift" \
  "${ROOT_DIR}/app/Sources/Views/HelpDocDeepDiveContent.swift" \
  "${ROOT_DIR}/app/Sources/Views/HelpDocsView.swift" \
  "${ROOT_DIR}/app/Sources/SSCCCApp.swift"

echo "Starte SS-CCC..."
pkill -f "^${OUT_BIN}$" 2>/dev/null || true
sleep 0.2
export SSCCC_BG_PATH="${ROOT_DIR}/app/Resources/solaris_bg.png"
export SSCCC_SIDEBAR_BG_PATH="${ROOT_DIR}/app/Resources/solaris_sidebar_bg.png"
exec "${OUT_BIN}"
