#!/usr/bin/env python3
"""
Automatic Version Control Helper for SonnerStudio Cluster-Case-Companion (SS-CCC).
Keeps version.json and app/Sources/Models/ClusterModels.swift (AppReleaseMetadata)
in sync, derives Git commit SHA & build count, and validates version consistency.
"""

from __future__ import annotations

import argparse
import datetime
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VERSION_JSON = ROOT / "version.json"
CLUSTER_MODELS = ROOT / "app" / "Sources" / "Models" / "ClusterModels.swift"


def run_git(args: list[str]) -> str:
    try:
        out = subprocess.check_output(["git", *args], cwd=ROOT, stderr=subprocess.DEVNULL)
        return out.decode("utf-8").strip()
    except Exception:
        return ""


def parse_semver(ver: str) -> tuple[int, int, int]:
    clean = ver.strip().lstrip("vV")
    parts = [int(p) for p in clean.split(".")[:3] if p.isdigit()]
    while len(parts) < 3:
        parts.append(0)
    return parts[0], parts[1], parts[2]


def bump_semver(ver: str, part: str) -> str:
    maj, min_, pat = parse_semver(ver)
    if part == "major":
        return f"{maj + 1}.0.0"
    if part == "minor":
        return f"{maj}.{min_ + 1}.0"
    if part == "patch":
        return f"{maj}.{min_}.{pat + 1}"
    return f"{maj}.{min_}.{pat}"


def update_cluster_models(version: str, build: int, commit_sha: str) -> None:
    text = CLUSTER_MODELS.read_text(encoding="utf-8")
    text = re.sub(
        r'(static let fallbackVersion\s*=\s*")[^"]*(")',
        rf'\g<1>{version}\g<2>',
        text,
    )
    text = re.sub(
        r'(static let fallbackBuild\s*=\s*)\d+',
        rf'\g<1>{build}',
        text,
    )
    text = re.sub(
        r'(static let embeddedCommitSHA\s*=\s*")[^"]*(")',
        rf'\g<1>{commit_sha}\g<2>',
        text,
    )
    CLUSTER_MODELS.write_text(text, encoding="utf-8")


def check_sync() -> int:
    data = json.loads(VERSION_JSON.read_text(encoding="utf-8"))
    swift_text = CLUSTER_MODELS.read_text(encoding="utf-8")

    v_match = re.search(r'static let fallbackVersion\s*=\s*"([^"]+)"', swift_text)
    b_match = re.search(r'static let fallbackBuild\s*=\s*(\d+)', swift_text)
    if not v_match or not b_match:
        print("FAIL: fallbackVersion or fallbackBuild missing in ClusterModels.swift", file=sys.stderr)
        return 1

    swift_ver = v_match.group(1)
    swift_build = int(b_match.group(1))
    json_ver = data.get("version")
    json_build = int(data.get("build", 0))

    if swift_ver != json_ver or swift_build != json_build:
        print(
            f"FAIL: Version mismatch: version.json=({json_ver}, build {json_build}) "
            f"!= ClusterModels.swift=({swift_ver}, build {swift_build})",
            file=sys.stderr,
        )
        return 1

    print(f"OK: version.json and ClusterModels.swift synchronized at v{json_ver} (build {json_build})")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="SS-CCC automatic version controller")
    parser.add_argument("--part", choices=["none", "patch", "minor", "major"], default="none")
    parser.add_argument("--sync-git", action="store_true", help="Sync build count, commit SHA & recent notes from git")
    parser.add_argument("--mandatory", action="store_true", help="Mark this release as mandatory update")
    parser.add_argument("--title", default="", help="Optional release title to store in version.json")
    parser.add_argument("--check", action="store_true", help="Only verify version.json and ClusterModels.swift match")
    args = parser.parse_args()

    if args.check:
        return check_sync()

    data = json.loads(VERSION_JSON.read_text(encoding="utf-8"))
    new_version = bump_semver(data.get("version", "1.6.0"), args.part)
    new_build = int(data.get("build", 160))

    commit_sha = data.get("commit_sha", "")
    if args.sync_git:
        git_count = run_git(["rev-list", "--count", "HEAD"])
        git_sha = run_git(["rev-parse", "--short", "HEAD"])
        recent_log = run_git(["log", "-n", "5", "--pretty=format:• %s (%h)"])
        if git_count.isdigit():
            new_build = max(new_build, int(git_count))
        if git_sha:
            commit_sha = git_sha
        if recent_log:
            data["notes"] = recent_log
    if args.part != "none":
        new_build += 1

    data["version"] = new_version
    data["build"] = new_build
    data["tag"] = f"v{new_version}"
    if args.title.strip():
        data["title"] = args.title.strip()
    elif args.part != "none":
        data["title"] = f"SS-CCC v{new_version} — Full 8-Language Localization, Local GPU/ANE Core Readout & 25/25 Tests"
    data["commit_sha"] = commit_sha
    data["updated_at"] = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    if args.mandatory:
        data["mandatory"] = True

    VERSION_JSON.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    update_cluster_models(new_version, new_build, commit_sha)
    print(f"Updated version to v{new_version} (build {new_build}, commit {commit_sha})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
