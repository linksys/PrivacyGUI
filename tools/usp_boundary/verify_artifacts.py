#!/usr/bin/env python3
"""Verify vendored USP artifacts, hashes, source revision, and production surface."""

import argparse
import hashlib
import json
import re
import sys
import urllib.request
from pathlib import Path


REQUIRED_PATHS = {
    "web/usp_client.js",
    "web/usp_client_bg.wasm",
    "web/usp_client.d.ts",
}
REQUIRED_EXPORTS = (
    "export class UspClient",
    "export class UspWsClient",
    "export function buildGetRecord",
    "export function buildOperateRecord",
    "export function buildWebSocketConnect",
    "export function decodeRecord",
)


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def fetch_url(url):
    with urllib.request.urlopen(url, timeout=30) as response:
        return response.read()


def raw_base(repository, commit):
    match = re.fullmatch(r"https://github\.com/([^/]+)/([^/]+?)(?:\.git)?", repository)
    if not match:
        raise ValueError("unsupported upstream repository URL: %s" % repository)
    return "https://raw.githubusercontent.com/%s/%s/%s" % (
        match.group(1),
        match.group(2),
        commit,
    )


def verify_manifest(manifest_path, root, verify_upstream=False, fetcher=fetch_url):
    manifest = json.loads(Path(manifest_path).read_text(encoding="utf-8"))
    errors = []
    reports = []
    if manifest.get("schema_version") != 1:
        errors.append("manifest schema_version must be 1")
    upstream = manifest.get("upstream", {})
    commit = upstream.get("commit", "")
    if not re.fullmatch(r"[0-9a-f]{40}", commit):
        errors.append("upstream commit must be a full 40-character SHA")
    features = set(manifest.get("build", {}).get("features", []))
    if not {"wasm", "websocket"} <= features:
        errors.append("build features must include wasm and websocket")

    artifacts = manifest.get("artifacts", [])
    paths = {artifact.get("path") for artifact in artifacts}
    if paths != REQUIRED_PATHS:
        errors.append(
            "artifact paths must be exactly: %s"
            % ", ".join(sorted(REQUIRED_PATHS))
        )

    base = None
    if verify_upstream and not errors:
        try:
            base = raw_base(upstream.get("repository", ""), commit)
        except ValueError as error:
            errors.append(str(error))

    contents = {}
    for artifact in artifacts:
        relative = artifact.get("path", "")
        path = Path(root) / relative
        try:
            data = path.read_bytes()
        except OSError as error:
            errors.append("%s: %s" % (relative, error))
            continue
        contents[relative] = data
        actual_hash = sha256(data)
        if artifact.get("sha256") != actual_hash:
            errors.append(
                "%s hash mismatch: manifest=%s actual=%s"
                % (relative, artifact.get("sha256"), actual_hash)
            )
        else:
            reports.append("HASH %s %s" % (relative, actual_hash))

        if base:
            upstream_path = artifact.get("upstream_path", "")
            if not upstream_path:
                errors.append("%s has no upstream_path" % relative)
                continue
            try:
                source = fetcher("%s/%s" % (base, upstream_path))
            except Exception as error:  # URL failures must become gate failures.
                errors.append("%s upstream fetch failed: %s" % (relative, error))
                continue
            if source != data:
                errors.append(
                    "%s differs from %s@%s:%s"
                    % (
                        relative,
                        upstream.get("repository"),
                        commit,
                        upstream_path,
                    )
                )
            else:
                reports.append("UPSTREAM MATCH %s" % relative)

    wasm = contents.get("web/usp_client_bg.wasm", b"")
    if wasm and not wasm.startswith(b"\x00asm"):
        errors.append("web/usp_client_bg.wasm has invalid WebAssembly magic")
    for relative in ("web/usp_client.js", "web/usp_client.d.ts"):
        if relative not in contents:
            continue
        surface = contents[relative].decode("utf-8", errors="replace")
        missing = [export for export in REQUIRED_EXPORTS if export not in surface]
        if missing:
            errors.append(
                "%s is missing production exports: %s"
                % (relative, ", ".join(missing))
            )
    return reports, errors


def main(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", required=True)
    parser.add_argument("--root", default=".")
    parser.add_argument("--verify-upstream", action="store_true")
    args = parser.parse_args(argv)
    try:
        reports, errors = verify_manifest(
            args.manifest,
            Path(args.root).resolve(),
            verify_upstream=args.verify_upstream,
        )
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print("FAIL: %s" % error, file=sys.stderr)
        return 1
    for report in reports:
        print(report)
    if errors:
        for error in errors:
            print("FAIL: %s" % error, file=sys.stderr)
        return 1
    if args.verify_upstream:
        print("PASS: vendored USP artifacts match hashes and upstream source")
    else:
        print("PASS: vendored USP artifacts match the provenance manifest")
    return 0


if __name__ == "__main__":
    sys.exit(main())
