import json
import tempfile
import unittest
from pathlib import Path

from check_boundary import run_check


HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent


class BoundaryTests(unittest.TestCase):
    def test_deliberate_subscribe_arity_mismatch_fails(self):
        fixture = HERE / "fixtures" / "arity_mismatch"
        _, errors = run_check(
            fixture / "usp_client.d.ts",
            [fixture / "usp_client_wasm.dart"],
            fixture / "policy.json",
            fixture,
        )
        self.assertTrue(any("arity mismatch" in error for error in errors), errors)

    def test_missing_local_shim_fails(self):
        fixture = HERE / "fixtures" / "arity_mismatch"
        with tempfile.TemporaryDirectory() as temp:
            temp = Path(temp)
            (temp / "binding.dart").write_text(
                "@JS('missingShim')\n"
                "external JSPromise<JSAny?> missingShim(JSAny value);\n",
                encoding="utf-8",
            )
            (temp / "shim.js").write_text("", encoding="utf-8")
            policy = {
                "schema_version": 1,
                "intentionally_unbound": {},
                "local_js_globals": {
                    "missingShim": {
                        "defined_in": "shim.js",
                        "reason": "negative fixture"
                    }
                }
            }
            (temp / "policy.json").write_text(
                json.dumps(policy), encoding="utf-8"
            )
            _, errors = run_check(
                fixture / "usp_client.d.ts",
                [temp / "binding.dart"],
                temp / "policy.json",
                temp,
            )
            self.assertTrue(any("not defined" in error for error in errors), errors)


if __name__ == "__main__":
    unittest.main()
