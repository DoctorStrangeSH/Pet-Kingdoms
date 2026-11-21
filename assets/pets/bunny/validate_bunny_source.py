#!/usr/bin/env python3
"""Validate the committed Bunny OBJ/MTL source without requiring Blender."""
from pathlib import Path
import math
import re
import sys

ROOT = Path(__file__).resolve().parent
OBJ = ROOT / "bunny.obj"
MTL = ROOT / "bunny.mtl"

def fail(message: str) -> None:
    print(f"FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)

if not OBJ.is_file() or not MTL.is_file():
    fail("bunny.obj and bunny.mtl must both exist")

vertices = 0
faces = 0
objects = []
used_materials = set()
defined_materials = set()
min_bounds = [math.inf, math.inf, math.inf]
max_bounds = [-math.inf, -math.inf, -math.inf]

for line_no, raw in enumerate(OBJ.read_text(encoding="utf-8").splitlines(), 1):
    line = raw.strip()
    if not line or line.startswith("#"):
        continue
    fields = line.split()
    kind = fields[0]
    if kind == "v":
        if len(fields) < 4:
            fail(f"OBJ line {line_no}: malformed vertex")
        try:
            xyz = [float(value) for value in fields[1:4]]
        except ValueError:
            fail(f"OBJ line {line_no}: non-numeric vertex")
        if not all(math.isfinite(value) for value in xyz):
            fail(f"OBJ line {line_no}: non-finite vertex")
        vertices += 1
        for axis, value in enumerate(xyz):
            min_bounds[axis] = min(min_bounds[axis], value)
            max_bounds[axis] = max(max_bounds[axis], value)
    elif kind == "o":
        if len(fields) < 2:
            fail(f"OBJ line {line_no}: unnamed object")
        objects.append(" ".join(fields[1:]))
    elif kind == "usemtl":
        if len(fields) != 2:
            fail(f"OBJ line {line_no}: malformed usemtl")
        used_materials.add(fields[1])
    elif kind == "f":
        if len(fields) != 4:
            fail(f"OBJ line {line_no}: expected triangulated face, got {len(fields)-1} vertices")
        for token in fields[1:]:
            raw_index = token.split("/")[0]
            try:
                index = int(raw_index)
            except ValueError:
                fail(f"OBJ line {line_no}: invalid vertex index {token}")
            if index == 0 or abs(index) > vertices:
                fail(f"OBJ line {line_no}: vertex index out of range: {index}")
        faces += 1

for line_no, raw in enumerate(MTL.read_text(encoding="utf-8").splitlines(), 1):
    fields = raw.strip().split()
    if fields and fields[0] == "newmtl":
        if len(fields) != 2:
            fail(f"MTL line {line_no}: malformed newmtl")
        defined_materials.add(fields[1])

if vertices != 15332:
    fail(f"expected 15,332 vertices, found {vertices}")
if faces != 30194:
    fail(f"expected 30,194 triangles, found {faces}")
if len(objects) != 13:
    fail(f"expected 13 named mesh objects, found {len(objects)}")
if len(set(objects)) != len(objects):
    fail("duplicate OBJ object names")
if len(defined_materials) != 9:
    fail(f"expected 9 material definitions, found {len(defined_materials)}")
if used_materials != defined_materials:
    fail(f"OBJ/MTL material mismatch: used={sorted(used_materials)}, defined={sorted(defined_materials)}")
if any(not math.isfinite(value) for value in min_bounds + max_bounds):
    fail("mesh has no valid bounds")
if min_bounds[1] < -0.19 or max_bounds[1] > 2.13:
    fail(f"unexpected vertical bounds: {min_bounds[1]}..{max_bounds[1]}")

print("PASS: Bunny OBJ/MTL source integrity")
print(f"  vertices={vertices} triangles={faces} objects={len(objects)} materials={len(defined_materials)}")
print(f"  bounds_min={tuple(round(v, 4) for v in min_bounds)}")
print(f"  bounds_max={tuple(round(v, 4) for v in max_bounds)}")
