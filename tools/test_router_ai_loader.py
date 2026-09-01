#!/usr/bin/env python3
"""Contract test for the package-owned Router AI web loader."""

from html.parser import HTMLParser
from pathlib import Path
import unittest
from urllib.parse import urlsplit


class ScriptCollector(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.scripts: list[dict[str, str | None]] = []

    def handle_starttag(
        self, tag: str, attrs: list[tuple[str, str | None]]
    ) -> None:
        if tag == "script":
            self.scripts.append(dict(attrs))


EXPECTED_LOADER = {"src": "/ai/linksys-ai.js", "defer": None}


def router_ai_scripts(html: str) -> list[dict[str, str | None]]:
    parser = ScriptCollector()
    parser.feed(html)
    return [
        script
        for script in parser.scripts
        if urlsplit(script.get("src") or "").path.rsplit("/", 1)[-1]
        == "linksys-ai.js"
    ]


def assert_loader_contract(html: str) -> None:
    if router_ai_scripts(html) != [EXPECTED_LOADER]:
        raise AssertionError("expected exactly one fixed, deferred Router AI loader")


class RouterAiLoaderContractTest(unittest.TestCase):
    def test_package_owned_bundle_is_loaded_once_with_defer(self) -> None:
        assert_loader_contract(Path("web/index.html").read_text(encoding="utf-8"))

    def test_query_or_fragment_variant_is_still_detected_as_a_duplicate(self) -> None:
        html = """
        <script src="/ai/linksys-ai.js" defer></script>
        <script src="/ai/linksys-ai.js?v=2#retry" defer></script>
        """

        with self.assertRaisesRegex(AssertionError, "exactly one fixed"):
            assert_loader_contract(html)


if __name__ == "__main__":
    unittest.main()
