#!/usr/bin/env python3
"""Validate a SpeakEasy deployment profile against profile.schema.json (stdlib only).

usage: validate_profile.py PROFILE.json [SCHEMA.json]
Prints OK or the list of violations (paths and reasons only, never values). Exit 0/1/2.
Implements the JSON Schema subset the schema uses: type, enum, pattern, minLength, maxLength,
required, properties, additionalProperties (false or schema), items, $ref to #/$defs.
"""
import json
import re
import sys
from pathlib import Path


def resolve(schema, root):
    ref = schema.get("$ref")
    if not ref:
        return schema
    node = root
    for part in ref.lstrip("#/").split("/"):
        node = node[part]
    return node


def check(value, schema, root, path, errs):
    schema = resolve(schema, root)
    types = {"object": dict, "array": list, "string": str, "integer": int, "boolean": bool}
    t = schema.get("type")
    if t in types:
        if not isinstance(value, types[t]) or (t == "integer" and isinstance(value, bool)):
            errs.append(f"{path or '$'}: expected {t}")
            return
    if "enum" in schema and value not in schema["enum"]:
        errs.append(f"{path or '$'}: must be one of {schema['enum']}")
    if isinstance(value, str):
        if len(value) < schema.get("minLength", 0):
            errs.append(f"{path}: too short")
        if len(value) > schema.get("maxLength", 10**9):
            errs.append(f"{path}: too long")
        if schema.get("pattern") and not re.search(schema["pattern"], value):
            errs.append(f"{path}: does not match the required format")
    if isinstance(value, list) and "items" in schema:
        for i, item in enumerate(value):
            check(item, schema["items"], root, f"{path}[{i}]", errs)
    if isinstance(value, dict):
        props = schema.get("properties", {})
        for req in schema.get("required", []):
            if req not in value:
                errs.append(f"{path or '$'}: missing required key {req!r}")
        addl = schema.get("additionalProperties", True)
        for k, v in value.items():
            sub = f"{path}.{k}" if path else k
            if k in props:
                check(v, props[k], root, sub, errs)
            elif addl is False:
                errs.append(f"{sub}: unknown key")
            elif isinstance(addl, dict):
                check(v, addl, root, sub, errs)


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    prof_path = Path(argv[1])
    schema_path = Path(argv[2]) if len(argv) > 2 else Path(__file__).resolve().parent.parent / "profile.schema.json"
    try:
        data = json.loads(prof_path.read_text())
        schema = json.loads(schema_path.read_text())
    except (OSError, ValueError) as e:
        print(f"ERROR: {e.__class__.__name__}")
        return 2
    errs = []
    check(data, schema, schema, "", errs)
    print("OK" if not errs else "INVALID: " + "; ".join(errs))
    return 1 if errs else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
