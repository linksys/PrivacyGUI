#!/usr/bin/env python3
"""Pre-tool hook: block `gh pr create` unless review-pr-readiness was run recently."""
import json, os, sys, time

STAMP = "/tmp/.pr-review-passed"
MAX_AGE = 600  # 10 minutes

data = json.load(sys.stdin)
cmd = data.get("tool_input", {}).get("command", "")

if "gh pr create" not in cmd:
    print(json.dumps({"continue": True}))
    sys.exit(0)

if os.path.exists(STAMP) and (time.time() - os.path.getmtime(STAMP)) < MAX_AGE:
    os.remove(STAMP)
    print(json.dumps({"continue": True}))
else:
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": (
                "STOP: Before creating a PR, you MUST first execute the "
                "review-pr-readiness skill. Run the full skill workflow, "
                "present the report, and only proceed after user confirms."
            ),
        }
    }))
