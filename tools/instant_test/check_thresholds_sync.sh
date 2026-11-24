#!/usr/bin/env bash
# Compare Instant Test's pinned threshold table with the canonical one in
# linksys-ai-msdm (docs/contracts/thresholds.v0.json; home decided on
# linksys/linksys-ai-msdm#745).
#
# Usage: tools/instant_test/check_thresholds_sync.sh <ai-msdm checkout> [ref] [--update]
#   ref       commit or branch in that checkout to compare against (default: origin/dev)
#   --update  re-vendor: copy the canonical file at <ref> and record its commit + sha256
#
# Exit 0 = in sync; 1 = drift (or the pin record is wrong); 2 = usage error.
set -euo pipefail
cd "$(dirname "$0")/../.."
CHECKOUT="${1:-}"; REF="${2:-origin/dev}"; MODE="${3:-}"
if [[ "$REF" == "--update" ]]; then MODE="--update"; REF="origin/dev"; fi
[[ -n "$CHECKOUT" && -d "$CHECKOUT/.git" || -f "$CHECKOUT/.git" ]] || { echo "usage: $0 <ai-msdm checkout> [ref] [--update]" >&2; exit 2; }
DIR=test/page/instant_verify/contracts
VENDORED="$DIR/thresholds.v0.json"; SOURCE="$DIR/thresholds.v0.source.json"
COMMIT="$(git -C "$CHECKOUT" rev-parse "$REF^{commit}")"
TMP="$(mktemp)"; trap 'rm -f "$TMP"' EXIT
git -C "$CHECKOUT" show "$COMMIT:docs/contracts/thresholds.v0.json" > "$TMP"
sha() { shasum -a 256 "$1" | cut -d' ' -f1; }
CANON_SHA="$(sha "$TMP")"; VEND_SHA="$(sha "$VENDORED")"
RECORDED_SHA="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["sha256"])' "$SOURCE")"
if [[ "$MODE" == "--update" ]]; then
  cp "$TMP" "$VENDORED"
  python3 - "$SOURCE" "$COMMIT" "$CANON_SHA" <<'PY'
import json, sys
p, commit, digest = sys.argv[1:]
d = json.load(open(p)); d["canonical"]["ref"] = commit; d["sha256"] = digest
open(p, "w").write(json.dumps(d, indent=2) + "\n")
PY
  echo "re-vendored thresholds.v0.json from ai-msdm $COMMIT ($CANON_SHA)."
  echo "Now update diagnostic_thresholds.dart if a cutoff changed, and run the conformance test."
  exit 0
fi
status=0
[[ "$VEND_SHA" == "$RECORDED_SHA" ]] || { echo "DRIFT: vendored copy ($VEND_SHA) does not match its pin record ($RECORDED_SHA)"; status=1; }
[[ "$VEND_SHA" == "$CANON_SHA" ]] || { echo "DRIFT: ai-msdm $REF ($COMMIT) has $CANON_SHA; vendored copy is $VEND_SHA. Re-vendor with --update."; status=1; }
[[ $status -eq 0 ]] && echo "in sync with ai-msdm $REF ($COMMIT)."
exit $status
