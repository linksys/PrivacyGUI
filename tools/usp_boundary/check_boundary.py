#!/usr/bin/env python3
"""Fail closed when PrivacyGUI Dart JS interop drifts from usp_client.d.ts."""

import argparse
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Parameter:
    type_name: str
    optional: bool = False


@dataclass(frozen=True)
class Signature:
    name: str
    parameters: tuple[Parameter, ...]
    return_type: str


def strip_comments(text):
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.DOTALL)
    return re.sub(r"//[^\n]*", "", text)


def matching_brace(text, opening):
    depth = 0
    for index in range(opening, len(text)):
        if text[index] == "{":
            depth += 1
        elif text[index] == "}":
            depth -= 1
            if depth == 0:
                return index
    raise ValueError("unclosed block")


def split_parameters(raw):
    if not raw.strip():
        return []
    result = []
    start = 0
    depths = {"<": 0, "(": 0, "{": 0, "[": 0}
    pairs = {">": "<", ")": "(", "}": "{", "]": "["}
    for index, char in enumerate(raw):
        if char in depths:
            depths[char] += 1
        elif char in pairs:
            depths[pairs[char]] -= 1
        elif char == "," and all(value == 0 for value in depths.values()):
            result.append(raw[start:index].strip())
            start = index + 1
    result.append(raw[start:].strip())
    return [item for item in result if item]


def ts_parameters(raw):
    result = []
    for item in split_parameters(raw):
        match = re.match(r"[\w$]+\s*(\?)?\s*:\s*(.+)$", item, re.DOTALL)
        if not match:
            raise ValueError("cannot parse TypeScript parameter: %s" % item)
        result.append(Parameter(match.group(2).strip(), bool(match.group(1))))
    return tuple(result)


def dart_parameters(raw):
    result = []
    for item in split_parameters(raw):
        item = re.sub(r"\b(required|covariant)\s+", "", item.strip())
        match = re.match(r"(.+?)\s+\w+$", item, re.DOTALL)
        if not match:
            raise ValueError("cannot parse Dart parameter: %s" % item)
        result.append(Parameter(match.group(1).strip(), False))
    return tuple(result)


def parse_typescript(path):
    text = strip_comments(Path(path).read_text(encoding="utf-8"))
    classes = {}
    class_spans = []
    for match in re.finditer(r"export\s+class\s+(\w+)\s*\{", text):
        class_name = match.group(1)
        opening = text.index("{", match.start())
        closing = matching_brace(text, opening)
        class_spans.append((match.start(), closing + 1))
        body = text[opening + 1:closing]
        methods = {}
        constructor = re.search(
            r"(?ms)^\s*(private\s+)?constructor\s*\(([^;]*?)\)\s*;",
            body,
        )
        if constructor and not constructor.group(1):
            methods["constructor"] = Signature(
                "constructor", ts_parameters(constructor.group(2)), class_name
            )
        method_pattern = re.compile(
            r"(?m)^\s*(?:static\s+)?(\[Symbol\.dispose\]|\w+)"
            r"\s*\(([^;]*?)\)\s*:\s*([^;\n]+);",
            re.DOTALL,
        )
        for method in method_pattern.finditer(body):
            name = (
                "Symbol.dispose"
                if method.group(1) == "[Symbol.dispose]"
                else method.group(1)
            )
            methods[name] = Signature(
                name,
                ts_parameters(method.group(2)),
                method.group(3).strip(),
            )
        classes[class_name] = methods

    functions = {}
    function_pattern = re.compile(
        r"export\s+(?:default\s+)?function\s+(\w+)\s*"
        r"\((.*?)\)\s*:\s*([^;]+);",
        re.DOTALL,
    )
    for match in function_pattern.finditer(text):
        if any(start <= match.start() < end for start, end in class_spans):
            continue
        functions[match.group(1)] = Signature(
            match.group(1),
            ts_parameters(match.group(2)),
            match.group(3).strip(),
        )
    return classes, functions


def parse_dart_extensions(path):
    text = strip_comments(Path(path).read_text(encoding="utf-8"))
    classes = {}
    spans = []
    extension_pattern = re.compile(
        r"@JS\('([^']+)'\)"
        r"(?:\s*@[A-Za-z_]\w*(?:\([^)]*\))?)*"
        r"\s*extension\s+type\s+\w+.*?\{",
        re.DOTALL,
    )
    for match in extension_pattern.finditer(text):
        js_class = match.group(1)
        opening = text.index("{", match.start())
        closing = matching_brace(text, opening)
        spans.append((match.start(), closing + 1))
        body = text[opening + 1:closing]
        methods = {}

        factory_pattern = re.compile(
            r"(?ms)^\s*(?:@JS\('([^']+)'\)\s*)?"
            r"external\s+factory\s+\w+(?:\._)?\s*\(([^;]*?)\)\s*;",
        )
        for factory in factory_pattern.finditer(body):
            name = factory.group(1) or "constructor"
            methods[name] = Signature(
                name, dart_parameters(factory.group(2)), js_class
            )

        method_pattern = re.compile(
            r"(?ms)^\s*(?:@JS\('([^']+)'\)\s*)?"
            r"external\s+(?!factory\b)(?:static\s+)?(\S+)\s+(\w+)\s*"
            r"\(([^;]*?)\)\s*;",
        )
        for method in method_pattern.finditer(body):
            dart_name = method.group(3)
            name = method.group(1) or dart_name.rstrip("_")
            methods[name] = Signature(
                name,
                dart_parameters(method.group(4)),
                method.group(2).strip(),
            )
        classes[js_class] = methods
    return classes, spans, text


def parse_dart_globals(path, spans, text):
    globals_ = {}
    pattern = re.compile(
        r"(?ms)^\s*@JS\('([^']+)'\)\s*"
        r"external\s+(\S+)\s+\w+\s*\(([^;]*?)\)\s*;",
    )
    for match in pattern.finditer(text):
        if any(start <= match.start() < end for start, end in spans):
            continue
        globals_[match.group(1)] = Signature(
            match.group(1),
            dart_parameters(match.group(3)),
            match.group(2).strip(),
        )
    return globals_


def normalized_type(type_name):
    compact = re.sub(r"\s+", "", type_name)
    compact = compact.replace("|undefined", "").replace("|null", "")
    compact = compact.rstrip("?")
    if compact.startswith("Promise<") or compact.startswith("JSPromise<"):
        return "promise"
    if "Function(" in compact or "=>" in compact:
        return "function"
    mapping = {
        "any": "any",
        "JSAny": "any",
        "string": "string",
        "String": "string",
        "JSString": "string",
        "boolean": "bool",
        "bool": "bool",
        "number": "number",
        "int": "number",
        "num": "number",
        "Uint8Array": "bytes",
        "JSUint8Array": "bytes",
        "Function": "function",
        "JSFunction": "function",
        "void": "void",
        "UspClient": "usp-client",
        "UspClientJS": "usp-client",
        "UspClientBuilder": "usp-client-builder",
        "UspClientBuilderJS": "usp-client-builder",
    }
    return mapping.get(compact, compact)


def compare_signature(label, dart, typescript):
    errors = []
    if len(dart.parameters) != len(typescript.parameters):
        errors.append(
            "%s arity mismatch: Dart=%d TypeScript=%d"
            % (label, len(dart.parameters), len(typescript.parameters))
        )
        return errors
    for index, (dart_param, ts_param) in enumerate(
        zip(dart.parameters, typescript.parameters), start=1
    ):
        if normalized_type(dart_param.type_name) != normalized_type(ts_param.type_name):
            errors.append(
                "%s parameter %d type mismatch: Dart=%s TypeScript=%s"
                % (label, index, dart_param.type_name, ts_param.type_name)
            )
    if normalized_type(dart.return_type) != normalized_type(typescript.return_type):
        errors.append(
            "%s return type mismatch: Dart=%s TypeScript=%s"
            % (label, dart.return_type, typescript.return_type)
        )
    return errors


def local_js_arity(path, name):
    text = Path(path).read_text(encoding="utf-8")
    match = re.search(
        r"window\." + re.escape(name)
        + r"\s*=\s*(?:async\s+)?function\s*\((.*?)\)",
        text,
        re.DOTALL,
    )
    if not match:
        return None
    return len(split_parameters(match.group(1)))


def discover_dart_paths(roots):
    """Discover every Dart file below roots that declares callable JS externals."""
    discovered = []
    for root in roots:
        root = Path(root)
        if not root.is_dir():
            raise ValueError("Dart discovery root is not a directory: %s" % root)
        for path in sorted(root.rglob("*.dart")):
            text = strip_comments(path.read_text(encoding="utf-8"))
            if re.search(r"\bexternal\b[^;]*\(", text, flags=re.DOTALL):
                discovered.append(path)
    return discovered


def run_check(dts_path, dart_paths, policy_path, root):
    policy = json.loads(Path(policy_path).read_text(encoding="utf-8"))
    if policy.get("schema_version") != 1:
        return [], ["policy schema_version must be 1"]

    ts_classes, ts_functions = parse_typescript(dts_path)
    dart_classes = {}
    dart_globals = {}
    errors = []
    for dart_path in dart_paths:
        classes, spans, text = parse_dart_extensions(dart_path)
        globals_ = parse_dart_globals(dart_path, spans, text)
        declared = len(re.findall(r"\bexternal\b", text))
        recognized = sum(len(methods) for methods in classes.values()) + len(globals_)
        if recognized != declared:
            errors.append(
                "%s contains %d external declarations but only %d were recognized"
                % (dart_path, declared, recognized)
            )
        for class_name, methods in classes.items():
            dart_classes.setdefault(class_name, {}).update(methods)
        dart_globals.update(globals_)

    reports = []
    unbound = policy.get("intentionally_unbound", {})
    for class_name, methods in dart_classes.items():
        if class_name not in ts_classes:
            errors.append("Dart binds missing TypeScript class %s" % class_name)
            continue
        for method_name, dart_signature in methods.items():
            ts_signature = ts_classes[class_name].get(method_name)
            label = "%s.%s" % (class_name, method_name)
            if not ts_signature:
                errors.append("Dart binds missing TypeScript method %s" % label)
                continue
            errors.extend(compare_signature(label, dart_signature, ts_signature))
            reports.append("BOUND %s" % label)

    for class_name in dart_classes:
        if class_name not in ts_classes:
            continue
        bound = set(dart_classes[class_name])
        for method_name in sorted(set(ts_classes[class_name]) - bound):
            reason = unbound.get(class_name, {}).get(method_name)
            label = "%s.%s" % (class_name, method_name)
            if not reason:
                errors.append(
                    "TypeScript method %s is unbound and has no policy reason" % label
                )
            else:
                reports.append("INTENTIONALLY UNBOUND %s — %s" % (label, reason))

    for class_name, methods in unbound.items():
        for method_name in methods:
            if class_name not in ts_classes or method_name not in ts_classes[class_name]:
                errors.append(
                    "stale unbound policy entry %s.%s" % (class_name, method_name)
                )
            elif method_name in dart_classes.get(class_name, {}):
                errors.append(
                    "stale unbound policy entry for bound method %s.%s"
                    % (class_name, method_name)
                )

    local_globals = policy.get("local_js_globals", {})
    for name, dart_signature in dart_globals.items():
        if name in ts_functions:
            errors.extend(
                compare_signature(
                    "top-level %s" % name, dart_signature, ts_functions[name]
                )
            )
            reports.append("BOUND top-level %s" % name)
            continue
        local = local_globals.get(name)
        if not local:
            errors.append(
                "Dart binds top-level %s, absent from .d.ts and local shim policy" % name
            )
            continue
        js_path = Path(root) / local["defined_in"]
        arity = local_js_arity(js_path, name)
        if arity is None:
            errors.append("local JS shim %s is not defined in %s" % (name, js_path))
        elif arity != len(dart_signature.parameters):
            errors.append(
                "local JS shim %s arity mismatch: Dart=%d JavaScript=%d"
                % (name, len(dart_signature.parameters), arity)
            )
        else:
            reports.append("LOCAL JS SHIM %s — %s" % (name, local["reason"]))

    for name in local_globals:
        if name not in dart_globals:
            errors.append("stale local JS shim policy entry %s" % name)

    required_classes = policy.get("required_dart_classes", [])
    for class_name in required_classes:
        if class_name not in dart_classes:
            errors.append("required Dart JS class was not discovered: %s" % class_name)

    minimum = policy.get("minimum_decisions")
    if not isinstance(minimum, int) or isinstance(minimum, bool) or minimum < 1:
        errors.append("policy minimum_decisions must be a positive integer")
    elif len(reports) < minimum:
        errors.append(
            "boundary decision floor not met: verified=%d required=%d"
            % (len(reports), minimum)
        )
    return reports, errors


def main(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument("--dts", required=True)
    parser.add_argument("--dart", action="append", default=[])
    parser.add_argument("--dart-root", action="append", default=[])
    parser.add_argument("--policy", required=True)
    parser.add_argument("--root", default=".")
    args = parser.parse_args(argv)
    try:
        dart_paths = [Path(path) for path in args.dart]
        dart_paths.extend(discover_dart_paths(args.dart_root))
        dart_paths = sorted(set(path.resolve() for path in dart_paths))
        if not dart_paths:
            raise ValueError("no Dart external-binding files were discovered")
        reports, errors = run_check(
            args.dts, dart_paths, args.policy, Path(args.root).resolve()
        )
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print("FAIL: %s" % error, file=sys.stderr)
        return 1
    for report in sorted(reports):
        print(report)
    if errors:
        for error in errors:
            print("FAIL: %s" % error, file=sys.stderr)
        return 1
    print("PASS: %d boundary decisions verified" % len(reports))
    return 0


if __name__ == "__main__":
    sys.exit(main())
