import bpy
import math
import os

OUTPUT_DIR = r"D:\Godot_Devs\Zombie_shooter\assets\models"
WEAPONS_DIR = os.path.join(OUTPUT_DIR, "weapons")
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
        "white": get_or_create_material("Mat_OutpostWhite", "#F5F5F7", roughness=0.8, metallic=0.0),
        "light_grey": get_or_create_material("Mat_OutpostLightGrey", "#D1D1D6", roughness=0.7, metallic=0.0),
        "slate": get_or_create_material("Mat_OutpostSlate", "#8E8E93", roughness=0.6, metallic=0.1),
        "charcoal": get_or_create_material("Mat_WeaponCharcoal", "#242426", roughness=0.4, metallic=0.3),
        "metal": get_or_create_material("Mat_WeaponGunmetal", "#48484A", roughness=0.35, metallic=0.6),
        "crimson": get_or_create_material("Mat_CrimsonAccent", "#E50914", roughness=0.15, metallic=0.2),
    }

# ==============================================================================
# 1. GENERATE OUTPOST DIORAMA
# ==============================================================================
def build_outpost():
    clear_objects()
    m = get_mats()
    
    # Base ground slab
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, -0.4))
    base = bpy.context.active_object
    base.name = "Outpost_Base"
    base.scale = (14, 14, 0.8)
    base.data.materials.append(m["white"])
    
    # Helipad Platform
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=2.6, depth=0.1, location=(3.5, 3.5, 0.05))
    helipad = bpy.context.active_object
    helipad.name = "Helipad_Platform"
    helipad.data.materials.append(m["light_grey"])
    
    # Helipad 'H' letter
    bpy.ops.mesh.primitive_cube_add(size=1, location=(3.5 - 0.7, 3.5, 0.12))
    h1 = bpy.context.active_object
    h1.scale = (0.2, 1.4, 0.05)
    h1.data.materials.append(m["crimson"])
    
    bpy.ops.mesh.primitive_cube_add(size=1, location=(3.5 + 0.7, 3.5, 0.12))
    h2 = bpy.context.active_object
    h2.scale = (0.2, 1.4, 0.05)
    h2.data.materials.append(m["crimson"])
    
    bpy.ops.mesh.primitive_cube_add(size=1, location=(3.5, 3.5, 0.12))
    h3 = bpy.context.active_object
    h3.scale = (1.2, 0.2, 0.05)
    h3.data.materials.append(m["crimson"])

    # Main Bunker Command Structure
    bpy.ops.mesh.primitive_cube_add(size=1, location=(-2.5, -2.0, 1.4))
    bunker = bpy.context.active_object
    bunker.name = "Bunker_Command"
    bunker.scale = (5.5, 4.5, 2.8)
    bunker.data.materials.append(m["white"])

    # Bunker Overhang Roof
    bpy.ops.mesh.primitive_cube_add(size=1, location=(-2.3, -1.8, 2.9))
    roof = bpy.context.active_object
    roof.name = "Bunker_Roof"
    roof.scale = (6.0, 5.0, 0.4)
    roof.data.materials.append(m["light_grey"])

    # Bunker Slit Window
    bpy.ops.mesh.primitive_cube_add(size=1, location=(-2.5, 0.26, 2.0))
    visor = bpy.context.active_object
    visor.name = "Bunker_SlitWindow"
    visor.scale = (4.0, 0.1, 0.4)
    visor.data.materials.append(m["charcoal"])

    # Comms Array Mast
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.15, depth=4.0, location=(-4.5, -3.5, 3.5))
    mast = bpy.context.active_object
    mast.name = "Comms_Mast"
    mast.data.materials.append(m["metal"])

    # Satellite Dish
    bpy.ops.mesh.primitive_cone_add(vertices=12, radius1=0.8, depth=0.4, location=(-4.5, -3.5, 5.6))
    dish = bpy.context.active_object
    dish.rotation_euler = (math.radians(35), math.radians(20), 0)
    dish.data.materials.append(m["white"])

    # Perimeter Blast Walls
    wall_coords = [
        ((-6.5, 0, 0.6), (0.4, 13.0, 1.2)),
        ((0, -6.5, 0.6), (13.0, 0.4, 1.2)),
        ((6.5, -2.5, 0.6), (0.4, 8.0, 1.2)),
        ((-2.5, 6.5, 0.6), (8.0, 0.4, 1.2)),
    ]
    for idx, (loc, sc) in enumerate(wall_coords):
        bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
        w = bpy.context.active_object
        w.name = f"BlastWall_{idx}"
        w.scale = sc
        w.data.materials.append(m["light_grey"])

    # Tactical Buggy
    bpy.ops.mesh.primitive_cube_add(size=1, location=(2.5, -3.0, 0.5))
    rover = bpy.context.active_object
    rover.name = "Armored_Rover_Chassis"
    rover.scale = (1.8, 3.2, 0.8)
    rover.data.materials.append(m["slate"])

    bpy.ops.mesh.primitive_cube_add(size=1, location=(2.5, -3.2, 1.0))
    rover_cab = bpy.context.active_object
    rover_cab.name = "Armored_Rover_Cab"
    rover_cab.scale = (1.4, 1.8, 0.6)
    rover_cab.data.materials.append(m["charcoal"])

    # Wheels
    wheel_offsets = [(-1.0, -2.0), (-1.0, -4.0), (1.0, -2.0), (1.0, -4.0)]
    for idx, (ox, oy) in enumerate(wheel_offsets):
        bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.4, depth=0.3, location=(2.5 + ox, oy, 0.4))
        wh = bpy.context.active_object
        wh.name = f"Rover_Wheel_{idx}"
        wh.rotation_euler = (0, math.radians(90), 0)
        wh.data.materials.append(m["charcoal"])

    # Floodlights
    for idx, (fx, fy) in enumerate([(-6.0, 6.0), (6.0, -6.0)]):
        bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.1, depth=3.2, location=(fx, fy, 1.6))
        pole = bpy.context.active_object
        pole.name = f"Floodlight_Pole_{idx}"
        pole.data.materials.append(m["slate"])

        bpy.ops.mesh.primitive_cube_add(size=1, location=(fx, fy, 3.3))
        head = bpy.context.active_object
        head.name = f"Floodlight_Head_{idx}"
        head.scale = (0.5, 0.35, 0.3)
        head.data.materials.append(m["crimson"])

    # Sandbags
    for idx in range(3):
        bpy.ops.mesh.primitive_cube_add(size=1, location=(1.0 + idx * 0.9, 0.5, 0.3))
        sb = bpy.context.active_object
        sb.scale = (0.8, 0.4, 0.35)
        sb.data.materials.append(m["light_grey"])

    outpost_path = os.path.join(OUTPUT_DIR, "outpost_diorama.glb")
    bpy.ops.export_scene.gltf(filepath=outpost_path, export_format='GLB')
    print(f"[Blender] Exported Outpost Diorama -> {outpost_path}")

# ==============================================================================
# 2. GENERATE WEAPON 1: ASSAULT CARBINE
# ==============================================================================
def build_assault_carbine():
    clear_objects()
    m = get_mats()
    
    # Upper Receiver
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0))
    rec = bpy.context.active_object
    rec.scale = (0.16, 0.9, 0.28)
    rec.data.materials.append(m["charcoal"])

    # Lower Receiver & Handgrip
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, -0.22, -0.26))
    grip = bpy.context.active_object
    grip.scale = (0.13, 0.22, 0.38)
    grip.rotation_euler = (math.radians(-18), 0, 0)
    grip.data.materials.append(m["charcoal"])

    # Curved Banana Mag
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0.12, -0.32))
    mag = bpy.context.active_object
    mag.scale = (0.12, 0.28, 0.48)
    mag.rotation_euler = (math.radians(12), 0, 0)
    mag.data.materials.append(m["metal"])

    # Barrel & Shroud
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.06, depth=1.1, location=(0, 0.95, 0.04))
    barrel = bpy.context.active_object
    barrel.rotation_euler = (math.radians(90), 0, 0)
    barrel.data.materials.append(m["metal"])

    # Muzzle Flash Hider
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.08, depth=0.18, location=(0, 1.55, 0.04))
    muzzle = bpy.context.active_object
    muzzle.rotation_euler = (math.radians(90), 0, 0)
    muzzle.data.materials.append(m["charcoal"])

    # Tactical Stock
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, -0.85, -0.06))
    stock = bpy.context.active_object
    stock.scale = (0.14, 0.7, 0.28)
    stock.data.materials.append(m["charcoal"])

    # Top Picatinny Rail
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0.15, 0.17))
    rail = bpy.context.active_object
    rail.scale = (0.12, 0.85, 0.06)
    rail.data.materials.append(m["metal"])

    # Red Dot Holographic Sight
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0.05, 0.26))
    optic = bpy.context.active_object
    optic.scale = (0.13, 0.3, 0.16)
    optic.data.materials.append(m["charcoal"])

    # Crimson Ejection Port / Accent
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0.085, -0.05, 0.05))
    accent = bpy.context.active_object
    accent.scale = (0.02, 0.22, 0.08)
    accent.data.materials.append(m["crimson"])

    weapon_path = os.path.join(WEAPONS_DIR, "assault_carbine.glb")
    bpy.ops.export_scene.gltf(filepath=weapon_path, export_format='GLB')
    print(f"[Blender] Exported Assault Carbine -> {weapon_path}")

# ==============================================================================
# 3. GENERATE WEAPON 2: TACTICAL SHOTGUN
# ==============================================================================
def build_tactical_shotgun():
    clear_objects()
    m = get_mats()

    # Heavy Receiver
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0))
    rec = bpy.context.active_object
    rec.scale = (0.18, 0.85, 0.32)
    rec.data.materials.append(m["charcoal"])

    # Full Solid Stock
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, -0.75, -0.12))
    stock = bpy.context.active_object
    stock.scale = (0.15, 0.8, 0.34)
    stock.data.materials.append(m["slate"])

    # Pistol Grip
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, -0.25, -0.26))
    grip = bpy.context.active_object
    grip.scale = (0.14, 0.2, 0.36)
    grip.rotation_euler = (math.radians(-25), 0, 0)
    grip.data.materials.append(m["charcoal"])

    # Main Heavy Shotgun Barrel
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.085, depth=1.3, location=(0, 0.98, 0.08))
    barrel = bpy.context.active_object
    barrel.rotation_euler = (math.radians(90), 0, 0)
    barrel.data.materials.append(m["metal"])

    # Under-barrel Tubular Mag
    bpy.ops.mesh.primitive_cylinder_add(vertices=14, radius=0.075, depth=1.1, location=(0, 0.88, -0.07))
    tube = bpy.context.active_object
    tube.rotation_euler = (math.radians(90), 0, 0)
    tube.data.materials.append(m["metal"])

    # Ribbed Pump Forend (Slide)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0.65, -0.06))
    pump = bpy.context.active_object
    pump.scale = (0.22, 0.45, 0.22)
    pump.data.materials.append(m["charcoal"])

    # Heat Shield with Crimson Accent vents
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0.85, 0.18))
    shield = bpy.context.active_object
    shield.scale = (0.19, 0.7, 0.06)
    shield.data.materials.append(m["crimson"])

    shotgun_path = os.path.join(WEAPONS_DIR, "tactical_shotgun.glb")
    bpy.ops.export_scene.gltf(filepath=shotgun_path, export_format='GLB')
    print(f"[Blender] Exported Tactical Shotgun -> {shotgun_path}")

# ==============================================================================
# 4. GENERATE WEAPON 3: HIGH-CALIBER SMG
# ==============================================================================
def build_high_caliber_smg():
    clear_objects()
    m = get_mats()

    # Compact Box Receiver
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0))
    rec = bpy.context.active_object
    rec.scale = (0.16, 0.65, 0.26)
    rec.data.materials.append(m["charcoal"])

    # Straight Vertical Stick Mag
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0.08, -0.36))
    mag = bpy.context.active_object
    mag.scale = (0.11, 0.16, 0.58)
    mag.data.materials.append(m["metal"])

    # Integrated Grip around magwell
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, -0.16, -0.22))
    grip = bpy.context.active_object
    grip.scale = (0.14, 0.18, 0.32)
    grip.rotation_euler = (math.radians(-15), 0, 0)
    grip.data.materials.append(m["charcoal"])

    # Short Heavy Barrel with Suppressor Shroud
    bpy.ops.mesh.primitive_cylinder_add(vertices=14, radius=0.09, depth=0.75, location=(0, 0.65, 0.02))
    suppressor = bpy.context.active_object
    suppressor.rotation_euler = (math.radians(90), 0, 0)
    suppressor.data.materials.append(m["metal"])

    # Wireframe Folding Stock
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, -0.55, 0.02))
    wire_stock = bpy.context.active_object
    wire_stock.scale = (0.12, 0.45, 0.16)
    wire_stock.data.materials.append(m["metal"])

    # Crimson Safety Switch & Strip
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0.085, -0.1, 0.05))
    switch = bpy.context.active_object
    switch.scale = (0.02, 0.12, 0.05)
    switch.data.materials.append(m["crimson"])

    smg_path = os.path.join(WEAPONS_DIR, "high_caliber_smg.glb")
    bpy.ops.export_scene.gltf(filepath=smg_path, export_format='GLB')
    print(f"[Blender] Exported High-Caliber SMG -> {smg_path}")

# Run builds
build_outpost()
build_assault_carbine()
build_tactical_shotgun()
build_high_caliber_smg()
print(">>> ALL 4 ASSETS EXPORTED TO GLB!")
