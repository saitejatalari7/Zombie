"""Generate Godot character scenes from characters.json.

Usage:  python3 tools/level_design/build_character_scenes.py
Writes assets/models/characters/<id>_model.tscn for each character.

Each scene has a Node3D pivot per animated part (Torso, Head, ArmLeft, ArmRight,
LegLeft, LegRight), so player.gd / zombie.gd keep finding them with find_child().
Parts are boxes (or a scaled sphere) with flat clay materials. Models face -Z.
"""
import json
import math
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SPEC = os.path.join(os.path.dirname(os.path.abspath(__file__)), "characters.json")
OUT_DIR = os.path.join(ROOT, "assets", "models", "characters")
SKIP_PIVOTS = {"player": {"Rifle"}}  # player.tscn already has its own rifle node


def euler_yxz_rows(deg):
    """Basis rows for Godot's default YXZ euler order (R = Ry * Rx * Rz)."""
    x, y, z = (math.radians(a) for a in deg)
    cx, sx, cy, sy, cz, sz = math.cos(x), math.sin(x), math.cos(y), math.sin(y), math.cos(z), math.sin(z)
    ry = [[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]]
    rx = [[1, 0, 0], [0, cx, -sx], [0, sx, cx]]
    rz = [[cz, -sz, 0], [sz, cz, 0], [0, 0, 1]]
    def mul(a, b):
        return [[sum(a[i][k] * b[k][j] for k in range(3)) for j in range(3)] for i in range(3)]
    return mul(mul(ry, rx), rz)


def xform(pos, rot=None, scale=None):
    rows = euler_yxz_rows(rot or [0, 0, 0])
    if scale:
        rows = [[rows[i][j] * scale[j] for j in range(3)] for i in range(3)]
    vals = [v for row in rows for v in row] + list(pos)
    return "Transform3D(" + ", ".join(f"{v:.5g}" for v in vals) + ")"


def color(hex_str):
    h = hex_str.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))
    # Godot stores albedo in sRGB space in the inspector, same as the hex value
    return f"Color({r:.4f}, {g:.4f}, {b:.4f}, 1)"


def build(spec):
    skip = SKIP_PIVOTS.get(spec["id"], set())
    emissive = set(spec.get("emissive", []))
    subs, nodes = [], []
    mat_ids, mesh_ids = {}, {}

    for key, hex_str in spec["colors"].items():
        mid = f"mat_{key}"
        mat_ids[key] = mid
        lines = [f'[sub_resource type="StandardMaterial3D" id="{mid}"]', f'resource_name = "{spec["id"]}_{key}"',
                 f"albedo_color = {color(hex_str)}", "roughness = 0.85"]
        if key in emissive:
            lines += ["emission_enabled = true", f"emission = {color(hex_str)}", "emission_energy_multiplier = 2.0"]
        subs.append("\n".join(lines))

    def mesh_id(shape, size):
        key = (shape, tuple(size)) if shape == "box" else (shape,)
        if key not in mesh_ids:
            mid = f"{shape}_{len(mesh_ids)}"
            mesh_ids[key] = mid
            if shape == "box":
                subs.append(f'[sub_resource type="BoxMesh" id="{mid}"]\nsize = Vector3({size[0]}, {size[1]}, {size[2]})')
            else:
                subs.append(f'[sub_resource type="SphereMesh" id="{mid}"]\nradius = 1.0\nheight = 2.0\nradial_segments = 12\nrings = 6')
        return mesh_ids[key]

    root_name = spec["name"].replace(" ", "") + "Model"
    nodes.append(f'[node name="{root_name}" type="Node3D"]')
    for p in spec["pivots"]:
        if p["name"] in skip:
            continue
        nodes.append(f'[node name="{p["name"]}" type="Node3D" parent="."]\ntransform = {xform(p["pos"], p.get("rot"))}')

    counts = {}
    for node, shape, size, pos, color_key, *rest in spec["parts"]:
        if node in skip:
            continue
        rot = rest[0] if rest else None
        counts[node] = counts.get(node, 0) + 1
        name = f"{node}Part{counts[node]}"
        if shape == "sphere":
            t = xform(pos, rot, size)
            m = mesh_id("sphere", None)
        else:
            t = xform(pos, rot)
            m = mesh_id("box", size)
        nodes.append(f'[node name="{name}" type="MeshInstance3D" parent="{node}"]\ntransform = {t}\n'
                     f'mesh = SubResource("{m}")\nsurface_material_override/0 = SubResource("{mat_ids[color_key]}")')

    header = f"[gd_scene load_steps={len(subs) + 1} format=3]"
    return "\n\n".join([header] + subs + nodes) + "\n"


def main():
    data = json.load(open(SPEC))
    for spec in data["characters"]:
        path = os.path.join(OUT_DIR, f"{spec['id']}_model.tscn")
        with open(path, "w") as f:
            f.write(build(spec))
        print("wrote", os.path.relpath(path, ROOT))


if __name__ == "__main__":
    main()
