#!/usr/bin/env python3
"""Contract test for the package-owned Router AI web loader."""

from html.parser import HTMLParser
from pathlib import Path
import unittest


class ScriptCollector(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.scripts: list[dict[str, str | None]] = []

    def handle_starttag(
        self, tag: str, attrs: list[tuple[str, str | None]]
    ) -> None:
        if tag == "script":
            self.scripts.append(dict(attrs))


class RouterAiLoaderContractTest(unittest.TestCase):
    def test_package_owned_bundle_is_loaded_once_with_defer(self) -> None:
        parser = ScriptCollector()
        parser.feed(Path("web/index.html").read_text(encoding="utf-8"))

        ai_scripts = [
            script
            for script in parser.scripts
            if (script.get("src") or "").endswith("linksys-ai.js")
        ]

        self.assertEqual(ai_scripts, [{"src": "/ai/linksys-ai.js", "defer": None}])


if __name__ == "__main__":
    unittest.main()
