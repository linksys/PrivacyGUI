import json
import tempfile
import unittest
from pathlib import Path

from check_boundary import discover_dart_paths, run_check


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

    def test_static_instance_mismatch_fails(self):
        fixture = HERE / "fixtures" / "static_mismatch"
        _, errors = run_check(
            fixture / "usp_client.d.ts",
            [fixture / "usp_client_wasm.dart"],
            fixture / "policy.json",
            fixture,
        )
        self.assertTrue(
            any("static-ness mismatch" in error for error in errors), errors
        )

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
                "minimum_decisions": 1,
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

    def test_zero_decisions_fails_the_floor(self):
        fixture = HERE / "fixtures" / "arity_mismatch"
        with tempfile.TemporaryDirectory() as temp:
            temp = Path(temp)
            dart = temp / "empty.dart"
            dart.write_text("", encoding="utf-8")
            policy = temp / "policy.json"
            policy.write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "minimum_decisions": 1,
                        "intentionally_unbound": {},
                        "local_js_globals": {},
                    }
                ),
                encoding="utf-8",
            )
            _, errors = run_check(
                fixture / "usp_client.d.ts", [dart], policy, temp
            )
            self.assertTrue(any("decision floor" in error for error in errors), errors)

    def test_static_interop_annotation_does_not_hide_extension(self):
        with tempfile.TemporaryDirectory() as temp:
            temp = Path(temp)
            dts = temp / "usp_client.d.ts"
            dts.write_text(
                "export class UspClient { constructor(base_url: string); }\n",
                encoding="utf-8",
            )
            dart = temp / "binding.dart"
            dart.write_text(
                "@JS('UspClient')\n"
                "@staticInterop\n"
                "extension type UspClientJS._(JSObject _) implements JSObject {\n"
                "  external factory UspClientJS(String baseUrl);\n"
                "}\n",
                encoding="utf-8",
            )
            policy = temp / "policy.json"
            policy.write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "minimum_decisions": 1,
                        "required_dart_classes": ["UspClient"],
                        "intentionally_unbound": {},
                        "local_js_globals": {},
                    }
                ),
                encoding="utf-8",
            )
            reports, errors = run_check(dts, [dart], policy, temp)
            self.assertEqual(errors, [])
            self.assertIn("BOUND UspClient.constructor", reports)

    def test_unannotated_top_level_external_is_not_silently_ignored(self):
        with tempfile.TemporaryDirectory() as temp:
            temp = Path(temp)
            dts = temp / "usp_client.d.ts"
            dts.write_text(
                "export function subscribe(value: string): void;\n",
                encoding="utf-8",
            )
            dart = temp / "binding.dart"
            dart.write_text(
                "external void subscribe(String value);\n", encoding="utf-8"
            )
            policy = temp / "policy.json"
            policy.write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "minimum_decisions": 1,
                        "intentionally_unbound": {},
                        "local_js_globals": {},
                    }
                ),
                encoding="utf-8",
            )
            _, errors = run_check(dts, [dart], policy, temp)
            self.assertTrue(any("only 0 were recognized" in e for e in errors), errors)

    def test_function_typed_parameter_is_parsed(self):
        with tempfile.TemporaryDirectory() as temp:
            temp = Path(temp)
            dts = temp / "usp_client.d.ts"
            dts.write_text(
                "export class UspClient { onRecord(callback: Function): void; }\n",
                encoding="utf-8",
            )
            dart = temp / "binding.dart"
            dart.write_text(
                "@JS('UspClient')\n"
                "extension type UspClientJS._(JSObject _) implements JSObject {\n"
                "  external void onRecord(void Function(JSAny) callback);\n"
                "}\n",
                encoding="utf-8",
            )
            policy = temp / "policy.json"
            policy.write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "minimum_decisions": 1,
                        "intentionally_unbound": {},
                        "local_js_globals": {},
                    }
                ),
                encoding="utf-8",
            )
            reports, errors = run_check(dts, [dart], policy, temp)
            self.assertEqual(errors, [])
            self.assertIn("BOUND UspClient.onRecord", reports)

    def test_discovery_includes_new_external_binding_files(self):
        with tempfile.TemporaryDirectory() as temp:
            temp = Path(temp)
            binding = temp / "new_binding.dart"
            binding.write_text(
                "@JS('newBinding')\nexternal void newBinding(String value);\n",
                encoding="utf-8",
            )
            (temp / "ordinary.dart").write_text(
                "void ordinary() {}\n", encoding="utf-8"
            )
            self.assertEqual(discover_dart_paths([temp]), [binding])

    def test_local_js_getter_is_discovered_and_verified(self):
        with tempfile.TemporaryDirectory() as temp:
            temp = Path(temp)
            dts = temp / "usp_client.d.ts"
            dts.write_text("", encoding="utf-8")
            binding = temp / "wasm_init.dart"
            binding.write_text(
                "@JS('__uspClientReady')\n"
                "external JSPromise<JSBoolean>? get ready;\n",
                encoding="utf-8",
            )
            (temp / "usp_init.js").write_text(
                "window.__uspClientReady = Promise.resolve(true);\n",
                encoding="utf-8",
            )
            policy = temp / "policy.json"
            policy.write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "minimum_decisions": 1,
                        "required_dart_globals": ["__uspClientReady"],
                        "intentionally_unbound": {},
                        "local_js_globals": {
                            "__uspClientReady": {
                                "kind": "getter",
                                "defined_in": "usp_init.js",
                                "reason": "negative fixture",
                            }
                        },
                    }
                ),
                encoding="utf-8",
            )

            self.assertEqual(discover_dart_paths([temp]), [binding])
            reports, errors = run_check(dts, [binding], policy, temp)
            self.assertEqual(errors, [])
            self.assertTrue(
                any("LOCAL JS VALUE __uspClientReady" in item for item in reports)
            )

    def test_missing_required_class_fails(self):
        with tempfile.TemporaryDirectory() as temp:
            temp = Path(temp)
            dts = temp / "usp_client.d.ts"
            dts.write_text(
                "export class UspClient { constructor(base_url: string); }\n",
                encoding="utf-8",
            )
            dart = temp / "empty.dart"
            dart.write_text("", encoding="utf-8")
            policy = temp / "policy.json"
            policy.write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "minimum_decisions": 1,
                        "required_dart_classes": ["UspClient"],
                        "intentionally_unbound": {},
                        "local_js_globals": {},
                    }
                ),
                encoding="utf-8",
            )

            _, errors = run_check(dts, [dart], policy, temp)
            self.assertTrue(
                any("required Dart JS class" in error for error in errors),
                errors,
            )

    def test_invalid_unbound_policy_fails_without_a_traceback(self):
        fixture = HERE / "fixtures" / "arity_mismatch"
        with tempfile.TemporaryDirectory() as temp:
            temp = Path(temp)
            policy = temp / "policy.json"
            policy.write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "minimum_decisions": 1,
                        "intentionally_unbound": [],
                        "local_js_globals": {},
                    }
                ),
                encoding="utf-8",
            )
            _, errors = run_check(
                fixture / "usp_client.d.ts",
                [fixture / "usp_client_wasm.dart"],
                policy,
                temp,
            )
            self.assertIn(
                "policy intentionally_unbound must be an object",
                errors,
            )


if __name__ == "__main__":
    unittest.main()
