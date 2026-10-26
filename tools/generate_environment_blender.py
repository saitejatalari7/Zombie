import bpy
import bmesh
import math
import os
from mathutils import Vector, Matrix

out_env = r"d:\Godot_Devs\Zombie_shooter\assets\models\environment"
out_bld = r"d:\Godot_Devs\Zombie_shooter\assets\models\buildings"
os.makedirs(out_env, exist_ok=True)
os.makedirs(out_bld, exist_ok=True)

def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def create_material(name, albedo_color, roughness=0.5, metallic=0.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs['Base Color'].default_value = albedo_color
        bsdf.inputs['Roughness'].default_value = roughness
        bsdf.inputs['Metallic'].default_value = metallic
    return mat

def apply_material(obj, mat):
    if obj.data.materials:
        obj.data.materials[0] = mat
    else:
        obj.data.materials.append(mat)

def join_objects(obj_list, final_name):
    if not obj_list:
        return None
    if len(obj_list) > 1:
        bpy.ops.object.select_all(action='DESELECT')
        for o in obj_list:
            o.select_set(True)
        bpy.context.view_layer.objects.active = obj_list[0]
        bpy.ops.object.join()
        joined = bpy.context.active_object
    else:
        joined = obj_list[0]
    joined.name = final_name
    return joined

# ==============================================================================
# 1. ROAD TILES
# ==============================================================================

# A. Straight Road (10m x 10m, 6m asphalt road, 2m sidewalks on left & right)
def build_road_straight():
    clear_scene()
    mat_asphalt = create_material("Mat_Asphalt", (0.16, 0.16, 0.18, 1.0), roughness=0.85, metallic=0.0)
    mat_sidewalk = create_material("Mat_Sidewalk", (0.84, 0.84, 0.86, 1.0), roughness=0.75, metallic=0.0)
    mat_curb = create_material("Mat_Curb", (0.72, 0.72, 0.75, 1.0), roughness=0.7, metallic=0.0)

    parts = []
    # Asphalt Center Road (6m wide, 10m long, height 0.2m)
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    rd = bpy.context.active_object
    rd.scale = (6.0, 10.0, 0.2)
    rd.location = (0, 0, 0.1)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(rd, mat_asphalt)
    parts.append(rd)

    # Left Sidewalk (2m wide, 10m long, 0.35m high -> 0.15m curb height)
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    sw_l = bpy.context.active_object
    sw_l.scale = (2.0, 10.0, 0.35)
    sw_l.location = (-4.0, 0, 0.175)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(sw_l, mat_sidewalk)
    parts.append(sw_l)

    # Right Sidewalk
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    sw_r = bpy.context.active_object
    sw_r.scale = (2.0, 10.0, 0.35)
    sw_r.location = (4.0, 0, 0.175)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(sw_r, mat_sidewalk)
    parts.append(sw_r)

    # Curbs (Beveled edges along sidewalks)
    for x_c in [-3.05, 3.05]:
        bpy.ops.mesh.primitive_cube_add(size=1.0)
        cb = bpy.context.active_object
        cb.scale = (0.1, 10.0, 0.38)
        cb.location = (x_c, 0, 0.19)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        apply_material(cb, mat_curb)
        parts.append(cb)

    joined = join_objects(parts, "RoadStraight")
    target_path = os.path.join(out_env, "road_straight.glb")
    bpy.ops.export_scene.gltf(filepath=target_path, export_format='GLB', use_selection=False, export_apply=True)
    print(f"Exported Road Straight to {target_path}")

# B. Road T-Junction (10m x 10m)
def build_road_t_junction():
    clear_scene()
    mat_asphalt = create_material("Mat_Asphalt", (0.16, 0.16, 0.18, 1.0), roughness=0.85, metallic=0.0)
    mat_sidewalk = create_material("Mat_Sidewalk", (0.84, 0.84, 0.86, 1.0), roughness=0.75, metallic=0.0)

    parts = []
    # Base asphalt plane for whole intersection
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    base = bpy.context.active_object
    base.scale = (10.0, 10.0, 0.2)
    base.location = (0, 0, 0.1)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(base, mat_asphalt)
    parts.append(base)

    # Left Corner Sidewalk Block (2m x 2m)
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    sw1 = bpy.context.active_object
    sw1.scale = (2.0, 2.0, 0.35)
    sw1.location = (-4.0, 4.0, 0.175)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(sw1, mat_sidewalk)
    parts.append(sw1)

    # Right Corner Sidewalk Block (2m x 2m)
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    sw2 = bpy.context.active_object
    sw2.scale = (2.0, 2.0, 0.35)
    sw2.location = (4.0, 4.0, 0.175)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(sw2, mat_sidewalk)
    parts.append(sw2)

    # Bottom Full Sidewalk (10m x 2m)
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    sw3 = bpy.context.active_object
    sw3.scale = (10.0, 2.0, 0.35)
    sw3.location = (0, -4.0, 0.175)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(sw3, mat_sidewalk)
    parts.append(sw3)

    joined = join_objects(parts, "RoadTJunction")
    target_path = os.path.join(out_env, "road_t_junction.glb")
    bpy.ops.export_scene.gltf(filepath=target_path, export_format='GLB', use_selection=False, export_apply=True)
    print(f"Exported Road T-Junction to {target_path}")

# C. Road Split-Level Stairs (10m x 10m, links low street at 0m to high street at +1.6m)
def build_road_stairs():
    clear_scene()
    mat_asphalt = create_material("Mat_Asphalt", (0.16, 0.16, 0.18, 1.0), roughness=0.85, metallic=0.0)
    mat_sidewalk = create_material("Mat_Sidewalk", (0.84, 0.84, 0.86, 1.0), roughness=0.75, metallic=0.0)
    mat_concrete = create_material("Mat_Concrete", (0.78, 0.78, 0.80, 1.0), roughness=0.7, metallic=0.0)

    parts = []
    # Lower road segment (Y = -5 to -2)
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    low_rd = bpy.context.active_object
    low_rd.scale = (6.0, 3.0, 0.2)
    low_rd.location = (0, -3.5, 0.1)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(low_rd, mat_asphalt)
    parts.append(low_rd)

    # Upper road segment (Y = 2 to 5, at height Z = 1.6m)
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    high_rd = bpy.context.active_object
    high_rd.scale = (6.0, 3.0, 0.2)
    high_rd.location = (0, 3.5, 1.7)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(high_rd, mat_asphalt)
    parts.append(high_rd)

    # 8 Wide Concrete Steps connecting Y = -2 to Y = +2
    num_steps = 8
    step_depth = 4.0 / num_steps
    step_height = 1.6 / num_steps
    for s in range(num_steps):
        bpy.ops.mesh.primitive_cube_add(size=1.0)
        st = bpy.context.active_object
        h = (s + 1) * step_height
        st.scale = (6.0, step_depth, h)
        st.location = (0, -2.0 + (s + 0.5) * step_depth, h * 0.5)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        apply_material(st, mat_concrete)
        parts.append(st)

    # Flanking retaining walls
    for x_w in [-3.5, 3.5]:
        bpy.ops.mesh.primitive_cube_add(size=1.0)
        w = bpy.context.active_object
        w.scale = (1.0, 10.0, 2.4)
        w.location = (x_w, 0, 1.2)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        apply_material(w, mat_concrete)
        parts.append(w)

    joined = join_objects(parts, "RoadStairs")
    target_path = os.path.join(out_env, "road_stairs.glb")
    bpy.ops.export_scene.gltf(filepath=target_path, export_format='GLB', use_selection=False, export_apply=True)
    print(f"Exported Road Stairs to {target_path}")

# ==============================================================================
# 2. MODULAR BUILDINGS MATCHING REFERENCE IMAGES
# ==============================================================================

# A. Building Residential Block (8m x 8m, 9m tall, 3 floors, recessed door, windows, rooftop AC)
def build_residential_block():
    clear_scene()
    mat_clay = create_material("Mat_WhiteClay", (0.91, 0.91, 0.93, 1.0), roughness=0.88, metallic=0.0)
    mat_dark = create_material("Mat_DarkRecess", (0.12, 0.12, 0.14, 1.0), roughness=0.9, metallic=0.0)
    mat_metal = create_material("Mat_MetalVent", (0.24, 0.25, 0.28, 1.0), roughness=0.4, metallic=0.7)

    parts = []
    # Main building body (8m x 8m x 9m)
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    bld = bpy.context.active_object
    bld.scale = (8.0, 8.0, 9.0)
    bld.location = (0, 0, 4.5)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(bld, mat_clay)
    parts.append(bld)

    # Inset Entrance Door (Front facade at -Y)
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    dr = bpy.context.active_object
    dr.scale = (1.4, 0.2, 2.3)
    dr.location = (1.8, -4.05, 1.15)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(dr, mat_dark)
    parts.append(dr)

    # Concrete door threshold steps
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    step = bpy.context.active_object
    step.scale = (1.8, 0.6, 0.25)
    step.location = (1.8, -4.3, 0.125)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(step, mat_clay)
    parts.append(step)

    # Recessed windows (Floor 1, 2, 3)
    window_coords = [
        (-2.0, -4.05, 1.8), (-2.0, -4.05, 4.8), (1.8, -4.05, 4.8),
        (-2.0, -4.05, 7.4), (1.8, -4.05, 7.4),
        (-4.05, -1.8, 4.8), (-4.05, 1.8, 4.8), (-4.05, -1.8, 7.4), (-4.05, 1.8, 7.4)
    ]
    for (wx, wy, wz) in window_coords:
        bpy.ops.mesh.primitive_cube_add(size=1.0)
        w = bpy.context.active_object
        w.scale = (1.0, 0.15, 1.2) if abs(wy) > abs(wx) else (0.15, 1.0, 1.2)
        w.location = (wx, wy, wz)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        apply_material(w, mat_dark)
        parts.append(w)

    # Rooftop Parapet Lip (0.4m tall border)
    for px, py, sx, sy in [
        (0, 3.9, 8.0, 0.3), (0, -3.9, 8.0, 0.3),
        (3.9, 0, 0.3, 7.6), (-3.9, 0, 0.3, 7.6)
    ]:
        bpy.ops.mesh.primitive_cube_add(size=1.0)
        p = bpy.context.active_object
        p.scale = (sx, sy, 0.5)
        p.location = (px, py, 9.25)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        apply_material(p, mat_clay)
        parts.append(p)

    # Rooftop AC Compressor Unit
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    ac = bpy.context.active_object
    ac.scale = (1.2, 0.9, 0.8)
    ac.location = (-1.8, 1.8, 9.4)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(ac, mat_metal)
    parts.append(ac)

    # Rooftop Access Stairwell Hatch
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    rh = bpy.context.active_object
    rh.scale = (2.2, 2.0, 1.8)
    rh.location = (1.6, -1.6, 9.9)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(rh, mat_clay)
    parts.append(rh)

    joined = join_objects(parts, "BuildingResidentialBlock")
    target_path = os.path.join(out_bld, "building_residential_block.glb")
    bpy.ops.export_scene.gltf(filepath=target_path, export_format='GLB', use_selection=False, export_apply=True)
    print(f"Exported Residential Block to {target_path}")

# B. Building with Exterior Staircase (Exact match to Image 1!)
def build_building_external_stairs():
    clear_scene()
    mat_clay = create_material("Mat_WhiteClay", (0.91, 0.91, 0.93, 1.0), roughness=0.88, metallic=0.0)
    mat_dark = create_material("Mat_DarkRecess", (0.12, 0.12, 0.14, 1.0), roughness=0.9, metallic=0.0)
    mat_rail = create_material("Mat_Handrail", (0.2, 0.22, 0.25, 1.0), roughness=0.5, metallic=0.7)

    parts = []
    # Main building mass (9m x 8m x 9m)
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    bld = bpy.context.active_object
    bld.scale = (9.0, 8.0, 9.0)
    bld.location = (0, 0, 4.5)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(bld, mat_clay)
    parts.append(bld)

    # Second Floor Doorway Landing
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    ld = bpy.context.active_object
    ld.scale = (1.6, 1.8, 0.3)
    ld.location = (-4.8, 2.0, 3.5)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(ld, mat_clay)
    parts.append(ld)

    # 2nd Floor Doorway
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    dr2 = bpy.context.active_object
    dr2.scale = (0.2, 1.2, 2.2)
    dr2.location = (-4.55, 2.0, 4.6)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(dr2, mat_dark)
    parts.append(dr2)

    # Concrete steps climbing from Y = -2.5 to Y = 1.0, reaching height 3.5m
    num_stairs = 10
    step_y = 3.5 / num_stairs
    step_z = 3.5 / num_stairs
    for s in range(num_stairs):
        bpy.ops.mesh.primitive_cube_add(size=1.0)
        st = bpy.context.active_object
        h = (s + 1) * step_z
        st.scale = (1.2, step_y, h)
        st.location = (-4.8, -2.5 + (s + 0.5) * step_y, h * 0.5)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        apply_material(st, mat_clay)
        parts.append(st)

    # Handrail along outer edge of stairs
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    rail = bpy.context.active_object
    rail.scale = (0.06, 4.2, 0.06)
    rail.location = (-5.45, -0.6, 2.6)
    rail.rotation_euler = (math.radians(-42), 0, 0)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(rail, mat_rail)
    parts.append(rail)

    # Ground floor door
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    dr1 = bpy.context.active_object
    dr1.scale = (1.4, 0.2, 2.3)
    dr1.location = (2.2, -4.05, 1.15)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(dr1, mat_dark)
    parts.append(dr1)

    # Recessed windows
    for wx, wy, wz in [(-2.0, -4.05, 5.5), (2.0, -4.05, 5.5), (0.0, -4.05, 2.0)]:
        bpy.ops.mesh.primitive_cube_add(size=1.0)
        w = bpy.context.active_object
        w.scale = (1.0, 0.15, 1.2)
        w.location = (wx, wy, wz)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        apply_material(w, mat_dark)
        parts.append(w)

    joined = join_objects(parts, "BuildingExternalStairs")
    target_path = os.path.join(out_bld, "building_with_external_stairs.glb")
    bpy.ops.export_scene.gltf(filepath=target_path, export_format='GLB', use_selection=False, export_apply=True)
    print(f"Exported Building External Stairs to {target_path}")

# C. Asymmetric Chamfered Building (Direct match to Image 1 center building!)
def build_building_chamfered():
    clear_scene()
    mat_clay = create_material("Mat_WhiteClay", (0.91, 0.91, 0.93, 1.0), roughness=0.88, metallic=0.0)
    mat_dark = create_material("Mat_DarkRecess", (0.12, 0.12, 0.14, 1.0), roughness=0.9, metallic=0.0)

    parts = []
    # Main block
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    b1 = bpy.context.active_object
    b1.scale = (7.0, 7.0, 9.5)
    b1.location = (0, 0, 4.75)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(b1, mat_clay)
    parts.append(b1)

    # 45-degree Angled Facade Wing
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    b2 = bpy.context.active_object
    b2.scale = (4.5, 4.5, 8.5)
    b2.location = (-2.8, -2.8, 4.25)
    b2.rotation_euler = (0, 0, math.radians(45))
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(b2, mat_clay)
    parts.append(b2)

    # Inset Entrance
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    dr = bpy.context.active_object
    dr.scale = (1.4, 0.2, 2.3)
    dr.location = (1.5, -3.55, 1.15)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(dr, mat_dark)
    parts.append(dr)

    # Recessed windows
    for wx, wy, wz in [(1.5, -3.55, 5.0), (1.5, -3.55, 7.5), (3.55, 0.0, 5.0)]:
        bpy.ops.mesh.primitive_cube_add(size=1.0)
        w = bpy.context.active_object
        w.scale = (1.0, 0.15, 1.2) if wy != 0.0 else (0.15, 1.0, 1.2)
        w.location = (wx, wy, wz)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        apply_material(w, mat_dark)
        parts.append(w)

    joined = join_objects(parts, "BuildingChamfered")
    target_path = os.path.join(out_bld, "building_angled_facade.glb")
    bpy.ops.export_scene.gltf(filepath=target_path, export_format='GLB', use_selection=False, export_apply=True)
    print(f"Exported Angled Facade Building to {target_path}")

# D. Industrial Warehouse with Corrugated Bay Doors (Direct match to Image 2!)
def build_warehouse():
    clear_scene()
    mat_concrete = create_material("Mat_WarehouseWall", (0.86, 0.86, 0.88, 1.0), roughness=0.8, metallic=0.0)
    mat_roof = create_material("Mat_CorrugatedRoof", (0.76, 0.77, 0.80, 1.0), roughness=0.6, metallic=0.3)
    mat_door = create_material("Mat_RollUpDoor", (0.28, 0.30, 0.34, 1.0), roughness=0.5, metallic=0.7)
    mat_duct = create_material("Mat_DuctMetal", (0.42, 0.44, 0.48, 1.0), roughness=0.35, metallic=0.85)

    parts = []
    # Main warehouse hall (14m wide, 10m deep, 6m tall)
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    wh = bpy.context.active_object
    wh.scale = (14.0, 10.0, 6.0)
    wh.location = (0, 0, 3.0)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(wh, mat_concrete)
    parts.append(wh)

    # Pitched roof gable
    bpy.ops.mesh.primitive_cylinder_add(radius=5.2, depth=14.2, vertices=3)
    rf = bpy.context.active_object
    rf.rotation_euler = (0, math.radians(90), 0)
    rf.location = (0, 0, 6.8)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(rf, mat_roof)
    parts.append(rf)

    # Large Cargo Roll-Up Bay Door (4.5m wide x 4.2m tall)
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    dr1 = bpy.context.active_object
    dr1.scale = (4.5, 0.25, 4.2)
    dr1.location = (-2.5, -5.05, 2.1)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(dr1, mat_door)
    parts.append(dr1)

    # Second Roll-Up Bay Door
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    dr2 = bpy.context.active_object
    dr2.scale = (3.5, 0.25, 3.6)
    dr2.location = (4.0, -5.05, 1.8)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(dr2, mat_door)
    parts.append(dr2)

    # Industrial Rooftop HVAC Duct (from Image 2)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.45, depth=8.0, vertices=12)
    dt = bpy.context.active_object
    dt.rotation_euler = (math.radians(90), 0, 0)
    dt.location = (-4.0, 0, 6.5)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(dt, mat_duct)
    parts.append(dt)

    # Exhaust Blower Box
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    bl = bpy.context.active_object
    bl.scale = (1.8, 1.8, 1.4)
    bl.location = (-4.0, 3.5, 6.8)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(bl, mat_duct)
    parts.append(bl)

    joined = join_objects(parts, "WarehouseIndustrial")
    target_path = os.path.join(out_bld, "building_warehouse.glb")
    bpy.ops.export_scene.gltf(filepath=target_path, export_format='GLB', use_selection=False, export_apply=True)
    print(f"Exported Industrial Warehouse to {target_path}")

# ==============================================================================
# 3. LOGISTICS & DEPOT ASSETS (Direct match to Image 2!)
# ==============================================================================

# A. Single Shipping Container (6.0m x 2.4m x 2.6m)
def build_shipping_container():
    clear_scene()
    mat_container = create_material("Mat_ContainerCharcoal", (0.18, 0.20, 0.24, 1.0), roughness=0.6, metallic=0.45)
    mat_frame = create_material("Mat_ContainerFrame", (0.12, 0.13, 0.15, 1.0), roughness=0.7, metallic=0.6)

    parts = []
    # Main container box
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    cb = bpy.context.active_object
    cb.scale = (6.0, 2.4, 2.6)
    cb.location = (0, 0, 1.3)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(cb, mat_container)
    parts.append(cb)

    # 4 Corner Castings / Posts
    for cx in [-2.95, 2.95]:
        for cy in [-1.15, 1.15]:
            bpy.ops.mesh.primitive_cube_add(size=1.0)
            col = bpy.context.active_object
            col.scale = (0.18, 0.18, 2.65)
            col.location = (cx, cy, 1.3)
            bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
            apply_material(col, mat_frame)
            parts.append(col)

    # Corrugated side ribs (simulated with 12 vertical rib battens)
    for i in range(-5, 6):
        rx = float(i) * 0.52
        for side_y in [-1.22, 1.22]:
            bpy.ops.mesh.primitive_cube_add(size=1.0)
            rib = bpy.context.active_object
            rib.scale = (0.08, 0.04, 2.4)
            rib.location = (rx, side_y, 1.3)
            bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
            apply_material(rib, mat_frame)
            parts.append(rib)

    # End Door Latch Rods
    for lx in [-0.4, 0.4]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.03, depth=2.3, vertices=8)
        rod = bpy.context.active_object
        rod.location = (3.04, lx, 1.3)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        apply_material(rod, mat_frame)
        parts.append(rod)

    joined = join_objects(parts, "ShippingContainer")
    target_path = os.path.join(out_env, "shipping_container.glb")
    bpy.ops.export_scene.gltf(filepath=target_path, export_format='GLB', use_selection=False, export_apply=True)
    print(f"Exported Shipping Container to {target_path}")

# B. Shipping Container Stack (3 containers high/offset forming a 6m high wall!)
def build_container_stack():
    clear_scene()
    mat_dark = create_material("Mat_ContainerDark", (0.16, 0.17, 0.20, 1.0), roughness=0.6, metallic=0.45)
    mat_crimson = create_material("Mat_ContainerCrimson", (0.55, 0.08, 0.10, 1.0), roughness=0.65, metallic=0.3)
    mat_olive = create_material("Mat_ContainerOlive", (0.28, 0.32, 0.26, 1.0), roughness=0.7, metallic=0.35)

    parts = []
    # Bottom container 1 (Dark)
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    c1 = bpy.context.active_object
    c1.scale = (6.0, 2.4, 2.6)
    c1.location = (0, 0, 1.3)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(c1, mat_dark)
    parts.append(c1)

    # Top container 2 (Crimson, stacked directly on top)
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    c2 = bpy.context.active_object
    c2.scale = (6.0, 2.4, 2.6)
    c2.location = (0, 0, 3.9)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(c2, mat_crimson)
    parts.append(c2)

    # Adjacent offset container 3 (Olive)
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    c3 = bpy.context.active_object
    c3.scale = (6.0, 2.4, 2.6)
    c3.location = (0, 2.5, 1.3)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(c3, mat_olive)
    parts.append(c3)

    joined = join_objects(parts, "ContainerStack")
    target_path = os.path.join(out_env, "shipping_container_stack.glb")
    bpy.ops.export_scene.gltf(filepath=target_path, export_format='GLB', use_selection=False, export_apply=True)
    print(f"Exported Container Stack to {target_path}")

# C. Concrete Jersey Barrier (2.5m x 0.6m x 0.9m)
def build_jersey_barrier():
    clear_scene()
    mat_barrier = create_material("Mat_JerseyBarrier", (0.75, 0.75, 0.77, 1.0), roughness=0.85, metallic=0.0)

    parts = []
    # Wide base
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    b_base = bpy.context.active_object
    b_base.scale = (2.5, 0.6, 0.3)
    b_base.location = (0, 0, 0.15)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(b_base, mat_barrier)
    parts.append(b_base)

    # Tapered upper spine
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    b_top = bpy.context.active_object
    b_top.scale = (2.5, 0.25, 0.65)
    b_top.location = (0, 0, 0.6)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(b_top, mat_barrier)
    parts.append(b_top)

    joined = join_objects(parts, "JerseyBarrier")
    target_path = os.path.join(out_env, "jersey_barrier.glb")
    bpy.ops.export_scene.gltf(filepath=target_path, export_format='GLB', use_selection=False, export_apply=True)
    print(f"Exported Jersey Barrier to {target_path}")

if __name__ == "__main__":
    print("=== STARTING MODULAR ENVIRONMENT & BUILDING GENERATION ===")
    build_road_straight()
    build_road_t_junction()
    build_road_stairs()
    build_residential_block()
    build_building_external_stairs()
    build_building_chamfered()
    build_warehouse()
    build_shipping_container()
    build_container_stack()
    build_jersey_barrier()
    print("=== ALL ENVIRONMENT & BUILDING ASSETS GENERATED SUCCESSFULLY ===")
