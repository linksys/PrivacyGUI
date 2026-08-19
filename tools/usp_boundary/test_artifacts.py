import hashlib
import json
import tempfile
import unittest
from pathlib import Path

from verify_artifacts import verify_manifest


EXPORTS = b"\n".join(
    (
        b"export class UspClient",
        b"export class UspWsClient",
        b"export function buildGetRecord",
        b"export function buildOperateRecord",
        b"export function buildWebSocketConnect",
        b"export function decodeRecord",
    )
)


class ArtifactTests(unittest.TestCase):
    def make_tree(self, root):
        files = {
            "web/usp_client.js": EXPORTS,
            "web/usp_client_bg.wasm": b"\x00asmfixture",
            "web/usp_client.d.ts": EXPORTS,
        }
        artifacts = []
        for relative, data in files.items():
            path = root / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
            artifacts.append(
                {
                    "path": relative,
                    "upstream_path": relative.replace("web/", "usp-client/pkg/"),
                    "sha256": hashlib.sha256(data).hexdigest(),
                }
            )
        manifest = {
            "schema_version": 1,
            "upstream": {
                "repository": "https://github.com/linksys/usp_framework",
                "commit": "0123456789abcdef0123456789abcdef01234567",
            },
            "build": {"features": ["wasm", "websocket"]},
            "artifacts": artifacts,
        }
        manifest_path = root / "manifest.json"
        manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
        return manifest_path, files

    def test_valid_manifest_and_upstream_match(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            manifest, files = self.make_tree(root)

            def fetcher(url):
                for relative, data in files.items():
                    upstream = relative.replace("web/", "usp-client/pkg/")
                    if url.endswith(upstream):
                        return data
                raise AssertionError(url)

            _, errors = verify_manifest(
                manifest, root, verify_upstream=True, fetcher=fetcher
            )
            self.assertEqual(errors, [])

    def test_changed_artifact_fails_hash(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            manifest, _ = self.make_tree(root)
            (root / "web/usp_client.d.ts").write_text(
                "changed", encoding="utf-8"
            )
            _, errors = verify_manifest(manifest, root)
            self.assertTrue(any("hash mismatch" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
