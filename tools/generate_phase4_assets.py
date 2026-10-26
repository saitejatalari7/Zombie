import bpy
import math
import os

OUTPUT_DIR = r"D:\Godot_Devs\Zombie_shooter\assets\models"
PROPS_DIR = os.path.join(OUTPUT_DIR, "props")
WEAPONS_DIR = os.path.join(OUTPUT_DIR, "weapons")
os.makedirs(PROPS_DIR, exist_ok=True)
os.makedirs(WEAPONS_DIR, exist_ok=True)

def clear_objects():
    if bpy.context.active_object and bpy.context.active_object.mode != 'OBJECT':
        bpy.ops.object.mode_set(mode='OBJECT')
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)

def get_or_create_material(name, hex_color, roughness=0.6, metallic=0.1):
    if name in bpy.data.materials:
        return bpy.data.materials[name]
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    hex_clean = hex_color.lstrip('#')
    r = int(hex_clean[0:2], 16) / 255.0
    g = int(hex_clean[2:4], 16) / 255.0
    b = int(hex_clean[4:6], 16) / 255.0
    bsdf.inputs['Base Color'].default_value = (r**2.2, g**2.2, b**2.2, 1.0)
    bsdf.inputs['Roughness'].default_value = roughness
    bsdf.inputs['Metallic'].default_value = metallic
    return mat

def get_mats():
    return {
        "white": get_or_create_material("Mat_White", "#F5F5F7", roughness=0.85, metallic=0.0),
        "light_grey": get_or_create_material("Mat_LightGrey", "#D1D1D6", roughness=0.7, metallic=0.0),
        "slate": get_or_create_material("Mat_Slate", "#8E8E93", roughness=0.6, metallic=0.1),
        "charcoal": get_or_create_material("Mat_Charcoal", "#3A3A3C", roughness=0.5, metallic=0.15),
        "dark": get_or_create_material("Mat_Dark", "#242426", roughness=0.4, metallic=0.2),
        "metal": get_or_create_material("Mat_Gunmetal", "#48484A", roughness=0.35, metallic=0.6),
        "crimson": get_or_create_material("Mat_Crimson", "#E50914", roughness=0.15, metallic=0.2),
        "gold": get_or_create_material("Mat_Gold", "#FFB800", roughness=0.3, metallic=0.7)
    }

# ==============================================================================
# 1. HEAVY SHOULDER-MOUNTED ROCKET LAUNCHER
# ==============================================================================
def build_rocket_launcher():
    clear_objects()
    m = get_mats()

    # Main launch tube (heavy octagonal / cylinder tube)
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.18, depth=1.75, location=(0, 0, 0))
    tube = bpy.context.active_object
    tube.name = "Launcher_Tube"
    tube.rotation_euler = (math.radians(90), 0, 0)
    tube.data.materials.append(m["metal"])

    # Rear exhaust bell / venturi nozzle
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.24, depth=0.28, location=(0, -0.92, 0))
    nozzle = bpy.context.active_object
    nozzle.name = "Launcher_Exhaust"
    nozzle.rotation_euler = (math.radians(90), 0, 0)
    nozzle.data.materials.append(m["charcoal"])

    # Front muzzle shroud collar
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.22, depth=0.22, location=(0, 0.88, 0))
    shroud = bpy.context.active_object
    shroud.name = "Launcher_MuzzleShroud"
    shroud.rotation_euler = (math.radians(90), 0, 0)
    shroud.data.materials.append(m["charcoal"])

    # Crimson Danger Warning Band around muzzle
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.225, depth=0.08, location=(0, 0.76, 0))
    stripe = bpy.context.active_object
    stripe.name = "Launcher_CrimsonStripe"
    stripe.rotation_euler = (math.radians(90), 0, 0)
    stripe.data.materials.append(m["crimson"])

    # Shoulder rest cushion
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, -0.35, -0.22))
    pad = bpy.context.active_object
    pad.name = "Launcher_ShoulderPad"
    pad.scale = (0.22, 0.42, 0.14)
    pad.data.materials.append(m["dark"])

    # Tactical Foregrip & Trigger
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0.22, -0.32))
    grip = bpy.context.active_object
    grip.name = "Launcher_Grip"
    grip.scale = (0.12, 0.16, 0.35)
    grip.rotation_euler = (math.radians(-12), 0, 0)
    grip.data.materials.append(m["charcoal"])

    # Optical Target Acquisition Scope Box
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0.18, 0.1, 0.22))
    scope = bpy.context.active_object
    scope.name = "Launcher_OpticScope"
    scope.scale = (0.16, 0.52, 0.18)
    scope.data.materials.append(m["charcoal"])

    # Crimson Scope Lens
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.07, depth=0.04, location=(0.18, 0.38, 0.22))
    lens = bpy.context.active_object
    lens.name = "Launcher_ScopeLens"
    lens.rotation_euler = (math.radians(90), 0, 0)
    lens.data.materials.append(m["crimson"])

    out_path = os.path.join(WEAPONS_DIR, "rocket_launcher.glb")
    bpy.ops.export_scene.gltf(filepath=out_path, export_format='GLB')
    print(f"[Blender] Exported Rocket Launcher -> {out_path}")

# ==============================================================================
# 2. RED MILITARY SUPPLY CRATE
# ==============================================================================
def build_military_crate():
    clear_objects()
    m = get_mats()

    # Main heavy crate body
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.5))
    crate = bpy.context.active_object
    crate.name = "Crate_Body"
    crate.scale = (1.4, 0.9, 0.85)
    crate.data.materials.append(m["charcoal"])

    # Heavy Reinforced Lid
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.96))
    lid = bpy.context.active_object
    lid.name = "Crate_Lid"
    lid.scale = (1.46, 0.96, 0.14)
    lid.data.materials.append(m["slate"])

    # 4 Crimson Corner Braces / Shock Bumpers
    for i, (cx, cy) in enumerate([(-0.68, -0.42), (0.68, -0.42), (-0.68, 0.42), (0.68, 0.42)]):
        bpy.ops.mesh.primitive_cube_add(size=1, location=(cx, cy, 0.5))
        brace = bpy.context.active_object
        brace.name = f"Crate_CornerBrace_{i}"
        brace.scale = (0.16, 0.16, 0.92)
        brace.data.materials.append(m["crimson"])

    # Central Military Latch / Locking Clamps
    for j, lx in enumerate([-0.35, 0.35]):
        bpy.ops.mesh.primitive_cube_add(size=1, location=(lx, 0.49, 0.65))
        latch = bpy.context.active_object
        latch.name = f"Crate_Latch_{j}"
        latch.scale = (0.12, 0.06, 0.22)
        latch.data.materials.append(m["metal"])

    # Top Carry Handles
    for k, hx in enumerate([-0.72, 0.72]):
        bpy.ops.mesh.primitive_cube_add(size=1, location=(hx, 0, 0.65))
        handle = bpy.context.active_object
        handle.name = f"Crate_Handle_{k}"
        handle.scale = (0.06, 0.24, 0.12)
        handle.data.materials.append(m["metal"])

    out_path = os.path.join(PROPS_DIR, "military_crate.glb")
    bpy.ops.export_scene.gltf(filepath=out_path, export_format='GLB')
    print(f"[Blender] Exported Military Crate -> {out_path}")

# ==============================================================================
# 3. HIGH-VALUE FLIGHT RECORDER / WEAPON PROTOTYPE CASE
# ==============================================================================
def build_flight_recorder_case():
    clear_objects()
    m = get_mats()

    # Rugged Hardcase Body (Tactical brief/case)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.22))
    case = bpy.context.active_object
    case.name = "FlightRecorder_Body"
    case.scale = (0.85, 0.62, 0.38)
    case.data.materials.append(m["dark"])

    # High-Visibility Crimson Lid Stripe
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.42))
    stripe = bpy.context.active_object
    stripe.name = "FlightRecorder_CrimsonBand"
    stripe.scale = (0.86, 0.22, 0.04)
    stripe.data.materials.append(m["crimson"])

    # Carrying Handle on Top
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0.34, 0.22))
    handle = bpy.context.active_object
    handle.name = "FlightRecorder_Handle"
    handle.scale = (0.32, 0.08, 0.08)
    handle.data.materials.append(m["metal"])

    # Twin Latches
    for i, lx in enumerate([-0.25, 0.25]):
        bpy.ops.mesh.primitive_cube_add(size=1, location=(lx, 0.32, 0.22))
        lt = bpy.context.active_object
        lt.name = f"FlightRecorder_Latch_{i}"
        lt.scale = (0.08, 0.04, 0.12)
        lt.data.materials.append(m["slate"])

    # Glowing Antenna Beacon Stud (Status Light)
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.04, depth=0.12, location=(0.32, -0.2, 0.44))
    beacon = bpy.context.active_object
    beacon.name = "FlightRecorder_Beacon"
    beacon.data.materials.append(m["gold"])

    out_path = os.path.join(PROPS_DIR, "flight_recorder_case.glb")
    bpy.ops.export_scene.gltf(filepath=out_path, export_format='GLB')
    print(f"[Blender] Exported Flight Recorder Case -> {out_path}")

# Run builds
build_rocket_launcher()
build_military_crate()
build_flight_recorder_case()
print(">>> ALL 3 PHASE 4 ASSETS EXPORTED SUCCESSFULLY!")
