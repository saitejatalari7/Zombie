import bpy
import math
import os

OUTPUT_DIR = r"D:\Godot_Devs\Zombie_shooter\assets\models"
PROPS_DIR = os.path.join(OUTPUT_DIR, "props")
SECTORS_DIR = os.path.join(OUTPUT_DIR, "sectors")
os.makedirs(PROPS_DIR, exist_ok=True)
os.makedirs(SECTORS_DIR, exist_ok=True)

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
        "pitch_black": get_or_create_material("Mat_PitchBlack", "#0A0A0C", roughness=0.9, metallic=0.0),
        "road_grey": get_or_create_material("Mat_RoadGrey", "#6B6B70", roughness=0.9, metallic=0.0),
        "glass": get_or_create_material("Mat_Glass", "#B8B8BF", roughness=0.05, metallic=0.1),
        "rust_grey": get_or_create_material("Mat_RustGrey", "#7A7A7E", roughness=0.8, metallic=0.15),
    }


# ==============================================================================
# 1. WRECKED CIVILIAN CAR — VARIANT A (Sedan, dented hood)
# ==============================================================================
def build_wrecked_car_a():
    clear_objects()
    m = get_mats()

    # Chassis body
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.45))
    body = bpy.context.active_object
    body.name = "Car_Body"
    body.scale = (1.0, 2.2, 0.55)
    body.data.materials.append(m["slate"])

    # Cabin
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, -0.2, 1.05))
    cabin = bpy.context.active_object
    cabin.name = "Car_Cabin"
    cabin.scale = (0.85, 1.2, 0.45)
    cabin.data.materials.append(m["light_grey"])

    # Hood (tilted/dented upward)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 1.2, 0.75))
    hood = bpy.context.active_object
    hood.name = "Car_Hood"
    hood.scale = (0.9, 0.7, 0.06)
    hood.rotation_euler = (math.radians(8), 0, math.radians(3))
    hood.data.materials.append(m["slate"])

    # Windshield (dark glass, cracked angle)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0.55, 1.1))
    windshield = bpy.context.active_object
    windshield.name = "Car_Windshield"
    windshield.scale = (0.82, 0.05, 0.42)
    windshield.rotation_euler = (math.radians(25), 0, 0)
    windshield.data.materials.append(m["dark"])

    # 4 Wheels
    for i, (wx, wy) in enumerate([(-0.55, 0.9), (0.55, 0.9), (-0.55, -0.85), (0.55, -0.85)]):
        bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.25, depth=0.18, location=(wx, wy, 0.25))
        wh = bpy.context.active_object
        wh.name = f"Car_Wheel_{i}"
        wh.rotation_euler = (0, math.radians(90), 0)
        wh.data.materials.append(m["charcoal"])

    # Bumper ripped off (leaning against car)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0.6, 1.65, 0.2))
    bumper = bpy.context.active_object
    bumper.name = "Car_Bumper_Detached"
    bumper.scale = (0.8, 0.08, 0.15)
    bumper.rotation_euler = (0, 0, math.radians(65))
    bumper.data.materials.append(m["slate"])

    path = os.path.join(PROPS_DIR, "wrecked_car_a.glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB')
    print(f"[Blender] Exported Wrecked Car A -> {path}")


# ==============================================================================
# 2. WRECKED CIVILIAN CAR — VARIANT B (SUV, flipped on side)
# ==============================================================================
def build_wrecked_car_b():
    clear_objects()
    m = get_mats()

    # SUV Body (on its side)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.55))
    body = bpy.context.active_object
    body.name = "SUV_Body"
    body.scale = (1.15, 2.6, 0.65)
    body.rotation_euler = (0, 0, math.radians(85))
    body.data.materials.append(m["light_grey"])

    # Cabin (visible because rolled)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(-0.1, -0.15, 1.15))
    cabin = bpy.context.active_object
    cabin.name = "SUV_Cabin"
    cabin.scale = (0.95, 1.5, 0.5)
    cabin.rotation_euler = (0, 0, math.radians(85))
    cabin.data.materials.append(m["slate"])

    # Exposed wheels (2 facing up)
    for i, wy in enumerate([0.85, -0.85]):
        bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.3, depth=0.2, location=(0.5, wy, 1.2))
        wh = bpy.context.active_object
        wh.name = f"SUV_Wheel_{i}"
        wh.rotation_euler = (0, math.radians(5), 0)
        wh.data.materials.append(m["charcoal"])

    path = os.path.join(PROPS_DIR, "wrecked_car_b.glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB')
    print(f"[Blender] Exported Wrecked Car B (SUV) -> {path}")


# ==============================================================================
# 3. WRECKED CIVILIAN CAR — VARIANT C (Compact, burned-out shell)
# ==============================================================================
def build_wrecked_car_c():
    clear_objects()
    m = get_mats()

    # Burned compact chassis (charcoal = burned out)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.4))
    body = bpy.context.active_object
    body.name = "Compact_Body"
    body.scale = (0.85, 1.8, 0.5)
    body.data.materials.append(m["charcoal"])

    # Hollow cabin (no roof — burned off)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, -0.1, 0.82))
    cabin_rim = bpy.context.active_object
    cabin_rim.name = "Compact_CabinRim"
    cabin_rim.scale = (0.7, 0.9, 0.08)
    cabin_rim.data.materials.append(m["dark"])

    # Missing wheel replaced by axle stub
    for i, (wx, wy) in enumerate([(-0.5, 0.65), (0.5, 0.65), (-0.5, -0.65)]):
        bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=0.22, depth=0.15, location=(wx, wy, 0.22))
        wh = bpy.context.active_object
        wh.name = f"Compact_Wheel_{i}"
        wh.rotation_euler = (0, math.radians(90), 0)
        wh.data.materials.append(m["dark"])

    # Missing wheel position — just axle rod
    bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.04, depth=0.3, location=(0.5, -0.65, 0.22))
    axle = bpy.context.active_object
    axle.name = "Compact_AxleStub"
    axle.rotation_euler = (0, math.radians(90), 0)
    axle.data.materials.append(m["metal"])

    path = os.path.join(PROPS_DIR, "wrecked_car_c.glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB')
    print(f"[Blender] Exported Wrecked Car C (Compact) -> {path}")


# ==============================================================================
# 4. DEAD TREE — VARIANT A (Tall gnarled)
# ==============================================================================
def build_dead_tree_a():
    clear_objects()
    m = get_mats()

    # Trunk
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.18, depth=3.0, location=(0, 0, 1.5))
    trunk = bpy.context.active_object
    trunk.name = "Tree_Trunk"
    trunk.rotation_euler = (math.radians(3), math.radians(2), 0)
    trunk.data.materials.append(m["charcoal"])

    # Main branches (forking arms)
    branch_data = [
        ((0.15, 0.1, 2.8), (0.08, 0.08, 1.2), (math.radians(25), 0, math.radians(20))),
        ((-0.2, -0.05, 2.6), (0.07, 0.07, 1.0), (math.radians(-30), math.radians(15), math.radians(-25))),
        ((0.05, 0.2, 3.3), (0.06, 0.06, 0.8), (math.radians(40), math.radians(-10), math.radians(10))),
        ((-0.1, -0.15, 3.0), (0.05, 0.05, 0.65), (math.radians(-20), math.radians(30), math.radians(-35))),
        ((0.22, -0.1, 2.2), (0.06, 0.06, 0.9), (math.radians(15), math.radians(-25), math.radians(40))),
    ]
    for idx, (loc, sc, rot) in enumerate(branch_data):
        bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=1, depth=1, location=loc)
        br = bpy.context.active_object
        br.name = f"Tree_Branch_{idx}"
        br.scale = sc
        br.rotation_euler = rot
        br.data.materials.append(m["charcoal"])

    # Sub-branches / twigs
    twig_data = [
        ((0.45, 0.3, 3.8), (0.03, 0.03, 0.5), (math.radians(35), 0, math.radians(30))),
        ((-0.55, 0.15, 3.4), (0.025, 0.025, 0.45), (math.radians(-40), math.radians(20), math.radians(-20))),
        ((0.1, -0.4, 3.7), (0.025, 0.025, 0.4), (math.radians(50), math.radians(-30), 0)),
        ((-0.3, 0.35, 3.1), (0.025, 0.025, 0.35), (math.radians(-25), math.radians(45), math.radians(15))),
    ]
    for idx, (loc, sc, rot) in enumerate(twig_data):
        bpy.ops.mesh.primitive_cylinder_add(vertices=5, radius=1, depth=1, location=loc)
        tw = bpy.context.active_object
        tw.name = f"Tree_Twig_{idx}"
        tw.scale = sc
        tw.rotation_euler = rot
        tw.data.materials.append(m["charcoal"])

    path = os.path.join(PROPS_DIR, "dead_tree_a.glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB')
    print(f"[Blender] Exported Dead Tree A -> {path}")


# ==============================================================================
# 5. DEAD TREE — VARIANT B (Short stumpy with broken limbs)
# ==============================================================================
def build_dead_tree_b():
    clear_objects()
    m = get_mats()

    # Short thick trunk
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.25, depth=2.0, location=(0, 0, 1.0))
    trunk = bpy.context.active_object
    trunk.name = "TreeB_Trunk"
    trunk.rotation_euler = (math.radians(5), 0, math.radians(-3))
    trunk.data.materials.append(m["charcoal"])

    # Two thick stubs (broken branches)
    bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.1, depth=0.6, location=(0.2, 0, 1.8))
    stub1 = bpy.context.active_object
    stub1.name = "TreeB_Stub_0"
    stub1.rotation_euler = (math.radians(20), 0, math.radians(45))
    stub1.data.materials.append(m["charcoal"])

    bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.09, depth=0.5, location=(-0.15, 0.1, 1.6))
    stub2 = bpy.context.active_object
    stub2.name = "TreeB_Stub_1"
    stub2.rotation_euler = (math.radians(-15), math.radians(25), math.radians(-40))
    stub2.data.materials.append(m["charcoal"])

    # One dangling long branch
    bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.06, depth=1.4, location=(0.1, -0.15, 1.9))
    branch = bpy.context.active_object
    branch.name = "TreeB_Hanging"
    branch.rotation_euler = (math.radians(55), 0, math.radians(15))
    branch.data.materials.append(m["charcoal"])

    path = os.path.join(PROPS_DIR, "dead_tree_b.glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB')
    print(f"[Blender] Exported Dead Tree B -> {path}")


# ==============================================================================
# 6. POWER POLE WITH CATENARY WIRES
# ==============================================================================
def build_power_pole():
    clear_objects()
    m = get_mats()

    # Concrete pole
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.15, depth=6.0, location=(0, 0, 3.0))
    pole = bpy.context.active_object
    pole.name = "PowerPole"
    pole.data.materials.append(m["light_grey"])

    # Cross arm
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 5.5))
    arm = bpy.context.active_object
    arm.name = "CrossArm"
    arm.scale = (2.0, 0.12, 0.12)
    arm.data.materials.append(m["slate"])

    # Insulators (6 caps on cross arm)
    for i, ox in enumerate([-0.85, -0.5, -0.15, 0.15, 0.5, 0.85]):
        bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.05, depth=0.25, location=(ox, 0, 5.7))
        ins = bpy.context.active_object
        ins.name = f"Insulator_{i}"
        ins.data.materials.append(m["white"])

    # Wire segments drooping (simplified catenary curves via thin cubes)
    for i, ox in enumerate([-0.5, 0.0, 0.5]):
        bpy.ops.mesh.primitive_cube_add(size=1, location=(ox, 3.0, 4.6))
        wire = bpy.context.active_object
        wire.name = f"Wire_{i}"
        wire.scale = (0.015, 6.0, 0.015)
        wire.rotation_euler = (math.radians(-5), 0, 0)
        wire.data.materials.append(m["pitch_black"])

    path = os.path.join(PROPS_DIR, "power_pole.glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB')
    print(f"[Blender] Exported Power Pole -> {path}")


# ==============================================================================
# 7. STREETLAMP (with OmniLight3D mount socket at top)
# ==============================================================================
def build_streetlamp():
    clear_objects()
    m = get_mats()

    # Post
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.08, depth=4.5, location=(0, 0, 2.25))
    post = bpy.context.active_object
    post.name = "Lamp_Post"
    post.data.materials.append(m["slate"])

    # Curved gooseneck arm
    bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.06, depth=1.2, location=(0.4, 0, 4.3))
    arm = bpy.context.active_object
    arm.name = "Lamp_Arm"
    arm.rotation_euler = (0, math.radians(55), 0)
    arm.data.materials.append(m["slate"])

    # Lamp head housing
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0.8, 0, 4.4))
    head = bpy.context.active_object
    head.name = "Lamp_Head"
    head.scale = (0.3, 0.2, 0.1)
    head.data.materials.append(m["metal"])

    # Light socket marker (small white sphere for Godot OmniLight placement)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=8, ring_count=6, radius=0.06, location=(0.8, 0, 4.32))
    socket = bpy.context.active_object
    socket.name = "LightSocket"
    socket.data.materials.append(m["white"])

    # Base plate
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.2, depth=0.1, location=(0, 0, 0.05))
    base = bpy.context.active_object
    base.name = "Lamp_Base"
    base.data.materials.append(m["slate"])

    path = os.path.join(PROPS_DIR, "streetlamp.glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB')
    print(f"[Blender] Exported Streetlamp -> {path}")


# ==============================================================================
# 8. TRANSIT BUS (Sector 2 large blocker)
# ==============================================================================
def build_transit_bus():
    clear_objects()
    m = get_mats()

    # Bus main body
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 1.1))
    body = bpy.context.active_object
    body.name = "Bus_Body"
    body.scale = (1.3, 4.8, 1.1)
    body.data.materials.append(m["light_grey"])

    # Roof
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 2.25))
    roof = bpy.context.active_object
    roof.name = "Bus_Roof"
    roof.scale = (1.35, 4.9, 0.08)
    roof.data.materials.append(m["slate"])

    # Window strip (dark glass band)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0.66, 0, 1.55))
    win_r = bpy.context.active_object
    win_r.name = "Bus_WindowR"
    win_r.scale = (0.03, 4.2, 0.45)
    win_r.data.materials.append(m["dark"])

    bpy.ops.mesh.primitive_cube_add(size=1, location=(-0.66, 0, 1.55))
    win_l = bpy.context.active_object
    win_l.name = "Bus_WindowL"
    win_l.scale = (0.03, 4.2, 0.45)
    win_l.data.materials.append(m["dark"])

    # Windshield (front)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 2.42, 1.55))
    ws = bpy.context.active_object
    ws.name = "Bus_Windshield"
    ws.scale = (1.15, 0.04, 0.55)
    ws.data.materials.append(m["dark"])

    # Crimson route stripe
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.85))
    stripe = bpy.context.active_object
    stripe.name = "Bus_Stripe"
    stripe.scale = (1.32, 4.85, 0.06)
    stripe.data.materials.append(m["crimson"])

    # 6 Wheels
    for i, wy in enumerate([-2.8, -1.0, 1.0, 2.8]):
        for side in [-0.75, 0.75]:
            bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.3, depth=0.2, location=(side, wy, 0.3))
            wh = bpy.context.active_object
            wh.name = f"Bus_Wheel_{i}_{int(side > 0)}"
            wh.rotation_euler = (0, math.radians(90), 0)
            wh.data.materials.append(m["charcoal"])

    path = os.path.join(PROPS_DIR, "transit_bus.glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB')
    print(f"[Blender] Exported Transit Bus -> {path}")


# ==============================================================================
# 9. CHEMICAL SILO (Sector 3 Industrial)
# ==============================================================================
def build_chemical_silo():
    clear_objects()
    m = get_mats()

    # Main tank cylinder
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=1.2, depth=4.5, location=(0, 0, 2.7))
    tank = bpy.context.active_object
    tank.name = "Silo_Tank"
    tank.data.materials.append(m["light_grey"])

    # Domed cap
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=1.2, location=(0, 0, 4.95))
    cap = bpy.context.active_object
    cap.name = "Silo_Cap"
    cap.scale = (1, 1, 0.35)
    cap.data.materials.append(m["slate"])

    # Hazard stripe
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=1.22, depth=0.2, location=(0, 0, 3.0))
    stripe = bpy.context.active_object
    stripe.name = "Silo_HazardStripe"
    stripe.data.materials.append(m["crimson"])

    # Support legs (4)
    for i, (lx, ly) in enumerate([(-0.7, -0.7), (0.7, -0.7), (-0.7, 0.7), (0.7, 0.7)]):
        bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.08, depth=0.9, location=(lx, ly, 0.45))
        leg = bpy.context.active_object
        leg.name = f"Silo_Leg_{i}"
        leg.data.materials.append(m["metal"])

    # Access ladder
    bpy.ops.mesh.primitive_cube_add(size=1, location=(1.25, 0, 2.5))
    ladder = bpy.context.active_object
    ladder.name = "Silo_Ladder"
    ladder.scale = (0.06, 0.3, 2.0)
    ladder.data.materials.append(m["metal"])

    path = os.path.join(PROPS_DIR, "chemical_silo.glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB')
    print(f"[Blender] Exported Chemical Silo -> {path}")


# ==============================================================================
# 10. SHIPPING CONTAINER (Sector 3 Industrial)
# ==============================================================================
def build_shipping_container():
    clear_objects()
    m = get_mats()

    # Main box
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 1.3))
    box = bpy.context.active_object
    box.name = "Container_Body"
    box.scale = (1.2, 3.0, 1.3)
    box.data.materials.append(m["rust_grey"])

    # Corrugated ridges (side detail)
    for i in range(6):
        oy = -2.2 + i * 0.85
        bpy.ops.mesh.primitive_cube_add(size=1, location=(0.62, oy, 1.3))
        ridge = bpy.context.active_object
        ridge.name = f"Container_Ridge_R_{i}"
        ridge.scale = (0.03, 0.3, 1.2)
        ridge.data.materials.append(m["slate"])

    # Double doors (front face)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 1.52, 1.3))
    door = bpy.context.active_object
    door.name = "Container_Door"
    door.scale = (1.15, 0.04, 1.25)
    door.data.materials.append(m["slate"])

    # Lock bar
    bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.03, depth=1.6, location=(0.15, 1.55, 1.3))
    lock = bpy.context.active_object
    lock.name = "Container_Lock"
    lock.data.materials.append(m["metal"])

    path = os.path.join(PROPS_DIR, "shipping_container.glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB')
    print(f"[Blender] Exported Shipping Container -> {path}")


# ==============================================================================
# 11. MODULAR BUILDING WALL SLAB (stackable brutalist segment)
# ==============================================================================
def build_modular_wall():
    clear_objects()
    m = get_mats()

    # Main wall slab
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 1.5))
    wall = bpy.context.active_object
    wall.name = "Wall_Slab"
    wall.scale = (4.0, 0.3, 3.0)
    wall.data.materials.append(m["white"])

    # Window cutout visual (dark recess)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(1.2, 0.16, 2.0))
    win = bpy.context.active_object
    win.name = "Wall_Window_0"
    win.scale = (0.6, 0.05, 0.8)
    win.data.materials.append(m["pitch_black"])

    bpy.ops.mesh.primitive_cube_add(size=1, location=(-1.2, 0.16, 2.0))
    win2 = bpy.context.active_object
    win2.name = "Wall_Window_1"
    win2.scale = (0.6, 0.05, 0.8)
    win2.data.materials.append(m["pitch_black"])

    # Concrete trim/ledge at bottom
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0.2, 0.1))
    trim = bpy.context.active_object
    trim.name = "Wall_Trim"
    trim.scale = (4.1, 0.08, 0.2)
    trim.data.materials.append(m["light_grey"])

    path = os.path.join(SECTORS_DIR, "modular_wall.glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB')
    print(f"[Blender] Exported Modular Wall -> {path}")


# ==============================================================================
# 12. MODULAR FLOOR SLAB (ground tile)
# ==============================================================================
def build_modular_floor():
    clear_objects()
    m = get_mats()

    # Floor tile
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, -0.05))
    floor = bpy.context.active_object
    floor.name = "Floor_Slab"
    floor.scale = (4.0, 4.0, 0.1)
    floor.data.materials.append(m["white"])

    # Sidewalk curb edge
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 2.05, 0.08))
    curb = bpy.context.active_object
    curb.name = "Floor_Curb"
    curb.scale = (4.0, 0.1, 0.18)
    curb.data.materials.append(m["light_grey"])

    path = os.path.join(SECTORS_DIR, "modular_floor.glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB')
    print(f"[Blender] Exported Modular Floor -> {path}")


# ==============================================================================
# 13. MODULAR STAIRWELL BLOCK
# ==============================================================================
def build_modular_stairwell():
    clear_objects()
    m = get_mats()

    # Stairwell housing
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 1.5))
    housing = bpy.context.active_object
    housing.name = "Stairwell_Housing"
    housing.scale = (2.0, 1.5, 3.0)
    housing.data.materials.append(m["light_grey"])

    # Steps (8 steps visible)
    for i in range(8):
        step_z = 0.2 + i * 0.35
        step_y = -0.5 + i * 0.16
        bpy.ops.mesh.primitive_cube_add(size=1, location=(0, step_y, step_z))
        step = bpy.context.active_object
        step.name = f"Step_{i}"
        step.scale = (1.4, 0.2, 0.12)
        step.data.materials.append(m["white"])

    # Handrail
    bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.04, depth=3.5, location=(0.75, 0.2, 1.7))
    rail = bpy.context.active_object
    rail.name = "Handrail"
    rail.rotation_euler = (math.radians(25), 0, 0)
    rail.data.materials.append(m["metal"])

    # Dark doorway (entrance)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, -0.76, 1.0))
    door = bpy.context.active_object
    door.name = "Stairwell_Door"
    door.scale = (0.8, 0.04, 1.5)
    door.data.materials.append(m["pitch_black"])

    path = os.path.join(SECTORS_DIR, "modular_stairwell.glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB')
    print(f"[Blender] Exported Modular Stairwell -> {path}")


# ==============================================================================
# RUN ALL BUILDS
# ==============================================================================
build_wrecked_car_a()
build_wrecked_car_b()
build_wrecked_car_c()
build_dead_tree_a()
build_dead_tree_b()
build_power_pole()
build_streetlamp()
build_transit_bus()
build_chemical_silo()
build_shipping_container()
build_modular_wall()
build_modular_floor()
build_modular_stairwell()
print(">>> ALL 13 PHASE 3 ASSETS EXPORTED TO GLB!")
