# USP Dart/Wasm boundary gate

This gate compares PrivacyGUI's Dart `external` bindings with the vendored
`usp_client.d.ts` contract. It checks class and method existence, method arity,
compatible parameter/return types, local JavaScript shim arity, and an explicit
policy for every intentionally unbound TypeScript method.

Run it from the repository root:

```bash
python3 tools/usp_boundary/verify_artifacts.py \
  --manifest web/usp-artifacts.json \
  --root .

python3 tools/usp_boundary/check_boundary.py \
  --dts web/usp_client.d.ts \
  --dart lib/core/usp/web/usp_client_wasm.dart \
  --dart lib/core/usp/web/usp_ws_client_wrapper.dart \
  --policy tools/usp_boundary/policy.json \
  --root .

python3 -m unittest discover -s tools/usp_boundary -p 'test_*.py'
```

The arity-mismatch fixture recreates the former one-argument Dart
`subscribe()` binding against the real three-argument TypeScript shape and
proves the checker fails. Hash verification proves the three vendored files
remain the reviewed artifact set recorded in `web/usp-artifacts.json`.

This is a producer/consumer API gate. It does not claim that a browser loaded
the application against a router, that firmware upload succeeded on a device,
or that TR-369 conformance passed.
