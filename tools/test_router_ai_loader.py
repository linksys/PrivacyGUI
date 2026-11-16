#!/usr/bin/env python3
"""Contract test for the build-flagged, package-owned Router AI web loader.

A default PrivacyGUI build must not reference the Router AI bundle at all. The
loader is added at runtime by lib/core/ai_session/router_ai_loader.dart, and
only in a build made with ENABLE_ROUTER_AI=true (--dart-define=enable_router_ai).
"""

# Keeps the `str | None` annotations below importable on Python 3.9.
from __future__ import annotations

from html.parser import HTMLParser
from pathlib import Path
import os
import re
import subprocess
import unittest
from urllib.parse import urlsplit

ROOT = Path(__file__).resolve().parents[1]


class ScriptCollector(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.scripts: list[dict[str, str | None]] = []

    def handle_starttag(
        self, tag: str, attrs: list[tuple[str, str | None]]
    ) -> None:
        if tag == "script":
            self.scripts.append(dict(attrs))


def router_ai_scripts(html: str) -> list[dict[str, str | None]]:
    parser = ScriptCollector()
    parser.feed(html)
    return [
        script
        for script in parser.scripts
        if urlsplit(script.get("src") or "").path.rsplit("/", 1)[-1]
        == "linksys-ai.js"
    ]


def assert_no_static_loader(html: str) -> None:
    if router_ai_scripts(html):
        raise AssertionError("web shell must not reference the Router AI bundle")


def build_script_flag(env_value: str | None) -> subprocess.CompletedProcess:
    """Run only build_web.sh's flag validation, with flutter stubbed out."""
    env = {k: v for k, v in os.environ.items() if k != "ENABLE_ROUTER_AI"}
    if env_value is not None:
        env["ENABLE_ROUTER_AI"] = env_value
    script = (ROOT / "build_web.sh").read_text(encoding="utf-8")
    # Replace the real build with an echo of the dart-defines it would pass.
    stubbed = "flutter() { printf '%s\\n' \"$@\"; }\n" + script
    return subprocess.run(
        ["bash", "-c", stubbed, "build_web.sh", "1", "none", "", "qa", "false", "false"],
        cwd=ROOT,
        env=env,
        capture_output=True,
        text=True,
        timeout=60,
    )


class RouterAiLoaderContractTest(unittest.TestCase):
    def test_default_web_shell_has_no_router_ai_loader(self) -> None:
        assert_no_static_loader((ROOT / "web/index.html").read_text(encoding="utf-8"))

    def test_query_or_fragment_variant_is_still_detected(self) -> None:
        with self.assertRaisesRegex(AssertionError, "must not reference"):
            assert_no_static_loader('<script src="/ai/linksys-ai.js?v=2#x" defer></script>')

    def test_runtime_loader_targets_the_package_owned_path(self) -> None:
        loader = (ROOT / "lib/core/ai_session/router_ai_loader.dart").read_text(encoding="utf-8")
        self.assertIn("const routerAiBundlePath = '/ai/linksys-ai.js';", loader)
        self.assertIn("if (!BuildConfig.enableRouterAi) return false;", loader)

    def test_widget_is_not_loaded_before_login(self) -> None:
        # The widget must never be on the login screen, so nothing loads it at
        # startup. AuthNotifier shows it only after the AI session bootstrap
        # succeeds.
        main = (ROOT / "lib/main.dart").read_text(encoding="utf-8")
        self.assertEqual(re.findall(r"^\s*loadRouterAiBundle\(\)", main, re.M), [])
        self.assertEqual(re.findall(r"^import .*router_ai_loader\.dart", main, re.M), [])
        auth = (ROOT / "lib/providers/auth/auth_provider.dart").read_text(encoding="utf-8")
        self.assertEqual(len(re.findall(r"ref\.read\(routerAiLoaderProvider\)\(\);", auth)), 1)
        callers = subprocess.run(
            ["git", "grep", "-l", r"loadRouterAiBundle\|routerAiLoaderProvider", "--", "lib"],
            cwd=ROOT, capture_output=True, text=True, check=True,
        ).stdout.split()
        self.assertEqual(
            sorted(callers),
            ["lib/core/ai_session/router_ai_loader.dart", "lib/providers/auth/auth_provider.dart"],
        )

    def test_flag_defaults_off_in_dart(self) -> None:
        config = (ROOT / "lib/constants/build_config.dart").read_text(encoding="utf-8")
        self.assertIn(
            "bool.fromEnvironment('enable_router_ai', defaultValue: false)", config
        )

    def test_build_script_defaults_off_and_passes_the_flag(self) -> None:
        for value, expected in [(None, "false"), ("false", "false"), ("true", "true")]:
            result = build_script_flag(value)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn(f"--dart-define=enable_router_ai={expected}", result.stdout)

    def test_build_script_rejects_ambiguous_values(self) -> None:
        for value in ["TRUE", "1", "yes", ""]:
            result = build_script_flag(value)
            if value == "":
                # Empty means unset under ${VAR:-false}: defaults off.
                self.assertIn("--dart-define=enable_router_ai=false", result.stdout)
                continue
            self.assertNotEqual(result.returncode, 0, value)
            self.assertIn("ENABLE_ROUTER_AI must be exactly", result.stderr)


if __name__ == "__main__":
    unittest.main()
