"""
build_urban_alleyway.py — Complete procedural generation of the high-detail
monochrome architectural clay diorama matching Image 1:
- Tight winding Mediterranean/brutalist hillside alleyways
- Split-level concrete staircase flights and stepped landings
- Multi-story cubic plaster buildings with recessed windows, doors, parapets,
  and exterior staircases wrapping up facade walls
- Highly detailed low/mid-poly abandoned sedans and hatchbacks parked askew
- Wooden/concrete utility poles with realistic catenary sagging power cables
- Gnarled bare winter/dead trees casting intricate branch shadows
- Clutter props: stacked crates, pallets, rubble bricks, rooftop AC units
- Pure architectural clay shader with bevel highlights and Cycles OptiX raytraced lighting
"""

import bpy
import bmesh
import math
import random
from mathutils import Vector, Euler, Matrix

def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    # Remove all collections and orphan data
    for col in bpy.data.collections:
        bpy.data.collections.remove(col)
    for mesh in bpy.data.meshes:
        bpy.data.meshes.remove(mesh)
    for mat in bpy.data.materials:
        bpy.data.materials.remove(mat)

def get_or_create_collection(name):
    if name in bpy.data.collections:
        return bpy.data.collections[name]
    col = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(col)
    return col

def get_clay_material():
    mat = bpy.data.materials.get("Clay_Plaster")
    if mat:
        return mat
    mat = bpy.data.materials.new(name="Clay_Plaster")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    nodes.clear()
    
    output = nodes.new(type="ShaderNodeOutputMaterial")
    output.location = (400, 0)
    
    bsdf = nodes.new(type="ShaderNodeBsdfPrincipled")
    bsdf.location = (0, 0)
    # Architectural matte plaster clay
    bsdf.inputs["Base Color"].default_value = (0.91, 0.91, 0.91, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.78
    bsdf.inputs["IOR"].default_value = 1.45
    
    mat.node_tree.links.new(bsdf.outputs["BSDF"], output.inputs["Surface"])
    return mat

def get_dark_recess_material():
    mat = bpy.data.materials.get("Clay_DarkRecess")
    if mat:
        return mat
    mat = bpy.data.materials.new(name="Clay_DarkRecess")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    nodes.clear()
    
    output = nodes.new(type="ShaderNodeOutputMaterial")
    output.location = (400, 0)
    
    bsdf = nodes.new(type="ShaderNodeBsdfPrincipled")
    bsdf.location = (0, 0)
    # Subtle darker tone for recessed window voids & interiors
    bsdf.inputs["Base Color"].default_value = (0.28, 0.28, 0.30, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.90
    
    mat.node_tree.links.new(bsdf.outputs["BSDF"], output.inputs["Surface"])
    return mat

def add_bevel(obj, width=0.025, segments=2):
    bev = obj.modifiers.new(name="Bevel", type="BEVEL")
    bev.width = width
    bev.segments = segments
    bev.limit_method = "ANGLE"
    bev.angle_limit = math.radians(35)
    bev.use_clamp_overlap = True

def assign_material(obj, mat):
    if len(obj.data.materials) == 0:
        obj.data.materials.append(mat)
    else:
        obj.data.materials[0] = mat

# ── PROCEDURAL ARCHITECTURE BUILDER ──

def create_box(name, size, pos, rot=(0,0,0), collection=None, mat=None, bevel=True, bevel_w=0.03):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    # Scale cube
    for v in bm.verts:
        v.co.x *= size[0]
        v.co.y *= size[1]
        v.co.z *= size[2]
    mesh = bpy.data.meshes.new(name + "_mesh")
    bm.to_mesh(mesh)
    bm.free()
    
    obj = bpy.data.objects.new(name, mesh)
    obj.location = pos
    obj.rotation_euler = rot
    if collection:
        collection.objects.link(obj)
    else:
        bpy.context.scene.collection.objects.link(obj)
    
    clay = mat if mat else get_clay_material()
    assign_material(obj, clay)
    if bevel:
        add_bevel(obj, width=bevel_w)
    return obj

def create_building_block(name, pos, size, stories=2, windows=None, doors=None, parapet=True, col=None):
    """
    Constructs a monolithic building with parapet roof, recessed windows, and doorways.
    size = (width, depth, height)
    windows = list of (wall_face, rel_x, rel_z, win_w, win_h) where wall_face in ['front', 'back', 'left', 'right']
    doors = list of (wall_face, rel_x, door_w, door_h)
    """
    bm = bmesh.new()
    w, d, h = size
    
    # Base building mass
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co.x *= w
        v.co.y *= d
        v.co.z *= h
        v.co.z += h * 0.5  # Base sits on Z=0
        
    mesh = bpy.data.meshes.new(name + "_mesh")
    bm.to_mesh(mesh)
    bm.free()
    
    bld_obj = bpy.data.objects.new(name, mesh)
    bld_obj.location = pos
    if col:
        col.objects.link(bld_obj)
    else:
        bpy.context.scene.collection.objects.link(bld_obj)
    assign_material(bld_obj, get_clay_material())
    add_bevel(bld_obj, width=0.03)
    
    # Parapet on roof
    if parapet:
        pt = 0.22 # parapet thickness
        ph = 0.65 # parapet height
        # North / South parapet walls
        create_box(f"{name}_parapet_N", (w, pt, ph), (pos[0], pos[1] + d*0.5 - pt*0.5, pos[2] + h + ph*0.5), collection=col, bevel_w=0.02)
        create_box(f"{name}_parapet_S", (w, pt, ph), (pos[0], pos[1] - d*0.5 + pt*0.5, pos[2] + h + ph*0.5), collection=col, bevel_w=0.02)
        create_box(f"{name}_parapet_E", (pt, d - pt*2, ph), (pos[0] + w*0.5 - pt*0.5, pos[1], pos[2] + h + ph*0.5), collection=col, bevel_w=0.02)
        create_box(f"{name}_parapet_W", (pt, d - pt*2, ph), (pos[0] - w*0.5 + pt*0.5, pos[1], pos[2] + h + ph*0.5), collection=col, bevel_w=0.02)
    
    # Recessed windows & doors as geometry insets
    recess_mat = get_dark_recess_material()
    if windows:
        for idx, (face, rx, rz, ww, wh) in enumerate(windows):
            inset_depth = 0.18
            if face == 'front': # -Y face
                win_pos = (pos[0] + rx, pos[1] - d*0.5 + inset_depth*0.5, pos[2] + rz)
                create_box(f"{name}_win_{idx}", (ww, inset_depth, wh), win_pos, collection=col, mat=recess_mat, bevel=False)
                # Sill
                create_box(f"{name}_sill_{idx}", (ww + 0.12, 0.08, 0.06), (win_pos[0], pos[1] - d*0.5 - 0.02, win_pos[2] - wh*0.5 - 0.03), collection=col, bevel_w=0.01)
            elif face == 'back': # +Y face
                win_pos = (pos[0] + rx, pos[1] + d*0.5 - inset_depth*0.5, pos[2] + rz)
                create_box(f"{name}_win_{idx}", (ww, inset_depth, wh), win_pos, collection=col, mat=recess_mat, bevel=False)
            elif face == 'left': # -X face
                win_pos = (pos[0] - w*0.5 + inset_depth*0.5, pos[1] + rx, pos[2] + rz)
                create_box(f"{name}_win_{idx}", (inset_depth, ww, wh), win_pos, collection=col, mat=recess_mat, bevel=False)
                create_box(f"{name}_sill_{idx}", (0.08, ww + 0.12, 0.06), (pos[0] - w*0.5 - 0.02, win_pos[1], win_pos[2] - wh*0.5 - 0.03), collection=col, bevel_w=0.01)
            elif face == 'right': # +X face
                win_pos = (pos[0] + w*0.5 - inset_depth*0.5, pos[1] + rx, pos[2] + rz)
                create_box(f"{name}_win_{idx}", (inset_depth, ww, wh), win_pos, collection=col, mat=recess_mat, bevel=False)
                create_box(f"{name}_sill_{idx}", (0.08, ww + 0.12, 0.06), (pos[0] + w*0.5 + 0.02, win_pos[1], win_pos[2] - wh*0.5 - 0.03), collection=col, bevel_w=0.01)
                
    if doors:
        for idx, (face, rx, dw, dh) in enumerate(doors):
            inset_depth = 0.22
            if face == 'front':
                door_pos = (pos[0] + rx, pos[1] - d*0.5 + inset_depth*0.5, pos[2] + dh*0.5)
                create_box(f"{name}_door_{idx}", (dw, inset_depth, dh), door_pos, collection=col, mat=recess_mat, bevel=False)
            elif face == 'left':
                door_pos = (pos[0] - w*0.5 + inset_depth*0.5, pos[1] + rx, pos[2] + dh*0.5)
                create_box(f"{name}_door_{idx}", (inset_depth, dw, dh), door_pos, collection=col, mat=recess_mat, bevel=False)
            elif face == 'right':
                door_pos = (pos[0] + w*0.5 - inset_depth*0.5, pos[1] + rx, pos[2] + dh*0.5)
                create_box(f"{name}_door_{idx}", (inset_depth, dw, dh), door_pos, collection=col, mat=recess_mat, bevel=False)
                
    return bld_obj

def create_exterior_wrap_stairs(name, start_pos, target_z, step_width=1.05, num_steps=18, along_axis='Y', direction=1, col=None):
    """Creates cantilevered concrete exterior stairs climbing along a building facade."""
    sx, sy, sz = start_pos
    tread = 0.32
    riser = (target_z - sz) / float(num_steps)
    clay = get_clay_material()
    
    for i in range(num_steps):
        if along_axis == 'Y':
            step_pos = (sx, sy + direction * (i * tread + tread*0.5), sz + i * riser + riser*0.5)
            create_box(f"{name}_step_{i}", (step_width, tread, riser), step_pos, collection=col, mat=clay, bevel_w=0.015)
        else:
            step_pos = (sx + direction * (i * tread + tread*0.5), sy, sz + i * riser + riser*0.5)
            create_box(f"{name}_step_{i}", (tread, step_width, riser), step_pos, collection=col, mat=clay, bevel_w=0.015)
            
    # Landing platform at the top
    if along_axis == 'Y':
        landing_pos = (sx, sy + direction * (num_steps * tread + 0.6), target_z - 0.1)
        create_box(f"{name}_landing", (step_width + 0.2, 1.2, 0.2), landing_pos, collection=col, mat=clay, bevel_w=0.02)
    else:
        landing_pos = (sx + direction * (num_steps * tread + 0.6), sy, target_z - 0.1)
        create_box(f"{name}_landing", (1.2, step_width + 0.2, 0.2), landing_pos, collection=col, mat=clay, bevel_w=0.02)

def create_street_staircase(name, start_pos, end_pos, width=3.2, num_steps=22, col=None):
    """Creates a grand flight of concrete stairs climbing between street levels."""
    p1 = Vector(start_pos)
    p2 = Vector(end_pos)
    delta = p2 - p1
    clay = get_clay_material()
    
    step_delta = delta / float(num_steps)
    step_length = Vector((step_delta.x, step_delta.y, 0)).length
    angle_z = math.atan2(delta.y, delta.x)
    
    # Steps
    for i in range(num_steps):
        sp = p1 + step_delta * (i + 0.5)
        step_obj = create_box(f"{name}_st_{i}", (step_length + 0.04, width, step_delta.z), 
                              (sp.x, sp.y, sp.z), rot=(0, 0, angle_z), collection=col, mat=clay, bevel_w=0.015)
        
    # Side concrete retaining curb / wall flanking the staircase
    curb_w = 0.32
    curb_h = 0.45
    side_offset = (width * 0.5 + curb_w * 0.5)
    # Right curb
    rc_start = p1 + Vector((-math.sin(angle_z), math.cos(angle_z), 0)) * side_offset
    rc_mid = p1 + delta * 0.5 + Vector((-math.sin(angle_z), math.cos(angle_z), 0)) * side_offset
    total_len = Vector((delta.x, delta.y, 0)).length
    create_box(f"{name}_curb_R", (total_len + 0.5, curb_w, curb_h), 
               (rc_mid.x, rc_mid.y, rc_mid.z + curb_h*0.5), rot=(0, 0, angle_z), collection=col, mat=clay, bevel_w=0.02)

# ── DETAILED VEHICLE GENERATOR ──

def create_car(name, pos, rot_z_deg=0, is_hatchback=False, col=None):
    """
    Constructs a stylized low/mid-poly abandoned car matching Image 1:
    - Sculpted chassis with wheel arches
    - Inset windshield, rear glass, side windows with A/B/C pillars
    - 4 detailed wheels & rims
    - Front/rear bumpers, side mirrors, hood line
    """
    clay = get_clay_material()
    recess_mat = get_dark_recess_material()
    car_col = bpy.data.collections.new(name)
    if col:
        col.children.link(car_col)
    else:
        bpy.context.scene.collection.children.link(car_col)
        
    rot = (0, 0, math.radians(rot_z_deg))
    cos_r = math.cos(math.radians(rot_z_deg))
    sin_r = math.sin(math.radians(rot_z_deg))
    
    def local_to_global(lx, ly, lz):
        gx = pos[0] + (lx * cos_r - ly * sin_r)
        gy = pos[1] + (lx * sin_r + ly * cos_r)
        gz = pos[2] + lz
        return (gx, gy, gz)
        
    # Chassis Lower Body (length 4.2m, width 1.76m, height 0.55m)
    create_box(f"{name}_chassis", (1.76, 4.2, 0.52), local_to_global(0, 0, 0.48), rot=rot, collection=car_col, mat=clay, bevel_w=0.03)
    
    # Cabin Upper (roof + pillars + windows)
    if not is_hatchback:
        # Sedan cabin
        create_box(f"{name}_cabin", (1.56, 2.2, 0.60), local_to_global(0, -0.15, 0.98), rot=rot, collection=car_col, mat=clay, bevel_w=0.03)
        # Angled windshield
        create_box(f"{name}_windshield", (1.46, 0.65, 0.52), local_to_global(0, 0.95, 0.88), 
                   rot=(math.radians(28), 0, math.radians(rot_z_deg)), collection=car_col, mat=recess_mat, bevel=False)
        # Rear window
        create_box(f"{name}_rear_win", (1.46, 0.65, 0.50), local_to_global(0, -1.25, 0.88), 
                   rot=(math.radians(-32), 0, math.radians(rot_z_deg)), collection=car_col, mat=recess_mat, bevel=False)
    else:
        # Hatchback cabin
        create_box(f"{name}_cabin", (1.56, 2.4, 0.62), local_to_global(0, -0.25, 0.98), rot=rot, collection=car_col, mat=clay, bevel_w=0.03)
        create_box(f"{name}_windshield", (1.46, 0.65, 0.52), local_to_global(0, 0.92, 0.88), 
                   rot=(math.radians(28), 0, math.radians(rot_z_deg)), collection=car_col, mat=recess_mat, bevel=False)
        create_box(f"{name}_rear_win", (1.46, 0.70, 0.54), local_to_global(0, -1.45, 0.88), 
                   rot=(math.radians(-42), 0, math.radians(rot_z_deg)), collection=car_col, mat=recess_mat, bevel=False)
                   
    # Side windows (inset)
    create_box(f"{name}_side_win_L", (0.04, 1.8, 0.42), local_to_global(-0.76, -0.15, 1.0), rot=rot, collection=car_col, mat=recess_mat, bevel=False)
    create_box(f"{name}_side_win_R", (0.04, 1.8, 0.42), local_to_global(0.76, -0.15, 1.0), rot=rot, collection=car_col, mat=recess_mat, bevel=False)
    
    # Bumpers
    create_box(f"{name}_bmpr_F", (1.82, 0.22, 0.22), local_to_global(0, 2.15, 0.38), rot=rot, collection=car_col, mat=clay, bevel_w=0.02)
    create_box(f"{name}_bmpr_R", (1.82, 0.22, 0.22), local_to_global(0, -2.15, 0.38), rot=rot, collection=car_col, mat=clay, bevel_w=0.02)
    
    # Headlights & Taillights
    create_box(f"{name}_hl_L", (0.34, 0.08, 0.16), local_to_global(-0.62, 2.12, 0.54), rot=rot, collection=car_col, mat=recess_mat, bevel=False)
    create_box(f"{name}_hl_R", (0.34, 0.08, 0.16), local_to_global(0.62, 2.12, 0.54), rot=rot, collection=car_col, mat=recess_mat, bevel=False)
    
    # Side Mirrors
    create_box(f"{name}_sm_L", (0.16, 0.12, 0.10), local_to_global(-0.84, 0.75, 0.92), rot=rot, collection=car_col, mat=clay, bevel_w=0.01)
    create_box(f"{name}_sm_R", (0.16, 0.12, 0.10), local_to_global(0.84, 0.75, 0.92), rot=rot, collection=car_col, mat=clay, bevel_w=0.01)
    
    # 4 Wheels (cylinders)
    wheel_offsets = [(-0.82, 1.25), (0.82, 1.25), (-0.82, -1.25), (0.82, -1.25)]
    for widx, (wx, wy) in enumerate(wheel_offsets):
        # Cylindrical tire
        bm = bmesh.new()
        bmesh.ops.create_cone(bm, cap_ends=True, radius1=0.33, radius2=0.33, depth=0.24, segments=16)
        # Rotate cylinder so axis is horizontal X
        bmesh.ops.rotate(bm, cent=(0,0,0), matrix=Matrix.Rotation(math.radians(90), 3, 'Y'), verts=bm.verts)
        mesh = bpy.data.meshes.new(f"{name}_wheel_{widx}_mesh")
        bm.to_mesh(mesh)
        bm.free()
        
        w_obj = bpy.data.objects.new(f"{name}_wheel_{widx}", mesh)
        w_obj.location = local_to_global(wx, wy, 0.33)
        w_obj.rotation_euler = rot
        car_col.objects.link(w_obj)
        assign_material(w_obj, clay)
        add_bevel(w_obj, width=0.015)
        
    return car_col

# ── TELEGRAPH / UTILITY POLE & CATENARY CABLES ──

def create_utility_pole(name, pos, height=8.2, col=None):
    """Creates a tall wooden/concrete utility pole with crossbars and insulator pegs."""
    clay = get_clay_material()
    pole_col = bpy.data.collections.new(name)
    if col:
        col.children.link(pole_col)
    else:
        bpy.context.scene.collection.children.link(pole_col)
        
    # Main vertical mast
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, radius1=0.14, radius2=0.14, depth=height, segments=12)
    mesh = bpy.data.meshes.new(f"{name}_mast_mesh")
    bm.to_mesh(mesh)
    bm.free()
    
    mast = bpy.data.objects.new(f"{name}_mast", mesh)
    mast.location = (pos[0], pos[1], pos[2] + height * 0.5)
    pole_col.objects.link(mast)
    assign_material(mast, clay)
    add_bevel(mast, width=0.015)
    
    # Crossarms (horizontal wooden crossbeams)
    # Upper crossarm
    create_box(f"{name}_crossarm_1", (1.65, 0.12, 0.12), (pos[0], pos[1], pos[2] + height - 0.4), collection=pole_col, mat=clay, bevel_w=0.01)
    # Lower crossarm
    create_box(f"{name}_crossarm_2", (1.45, 0.12, 0.12), (pos[0], pos[1], pos[2] + height - 1.2), collection=pole_col, mat=clay, bevel_w=0.01)
    
    # Insulator pegs (small vertical cylinders on crossarms)
    insulator_x = [-0.65, -0.25, 0.25, 0.65]
    for idx, ix in enumerate(insulator_x):
        bm_ins = bmesh.new()
        bmesh.ops.create_cone(bm_ins, cap_ends=True, radius1=0.045, radius2=0.045, depth=0.16, segments=8)
        m_ins = bpy.data.meshes.new(f"{name}_ins_{idx}_mesh")
        bm_ins.to_mesh(m_ins)
        bm_ins.free()
        iobj = bpy.data.objects.new(f"{name}_ins_{idx}", m_ins)
        iobj.location = (pos[0] + ix, pos[1], pos[2] + height - 0.3)
        pole_col.objects.link(iobj)
        assign_material(iobj, clay)
        
    # Attachment points for wires (returns list of 3D coordinates)
    attach_pts = [
        Vector((pos[0] - 0.65, pos[1], pos[2] + height - 0.25)),
        Vector((pos[0] - 0.25, pos[1], pos[2] + height - 0.25)),
        Vector((pos[0] + 0.25, pos[1], pos[2] + height - 0.25)),
        Vector((pos[0] + 0.65, pos[1], pos[2] + height - 0.25)),
    ]
    return pole_col, attach_pts

def create_catenary_cable(name, p1, p2, sag=0.45, segments=24, col=None):
    """Creates a realistic sagging catenary wire curve between two 3D points."""
    clay = get_clay_material()
    curve_data = bpy.data.curves.new(f"{name}_curve", type='CURVE')
    curve_data.dimensions = '3D'
    curve_data.bevel_depth = 0.014  # Realistic thick power cable
    curve_data.bevel_resolution = 3
    
    spline = curve_data.splines.new('POLY')
    spline.points.add(segments)
    
    for i in range(segments + 1):
        t = i / float(segments)
        pos = p1.lerp(p2, t)
        parabolic_drop = 4.0 * sag * t * (1.0 - t)
        pos.z -= parabolic_drop
        spline.points[i].co = (pos.x, pos.y, pos.z, 1.0)
        
    curve_obj = bpy.data.objects.new(name, curve_data)
    if col:
        col.objects.link(curve_obj)
    else:
        bpy.context.scene.collection.objects.link(curve_obj)
    assign_material(curve_obj, clay)
    return curve_obj

# ── DEAD BARE BRANCHING TREES ──

def create_dead_tree(name, pos, height=5.5, seed_val=101, col=None):
    """
    Constructs a gnarled organic dead tree with branching limbs
    that cast dramatic intricate branch shadows across walls and streets.
    """
    random.seed(seed_val)
    clay = get_clay_material()
    tree_col = bpy.data.collections.new(name)
    if col:
        col.children.link(tree_col)
    else:
        bpy.context.scene.collection.children.link(tree_col)
        
    # Main twisted trunk
    trunk_pts = [
        Vector((pos[0], pos[1], pos[2])),
        Vector((pos[0] + random.uniform(-0.15, 0.15), pos[1] + random.uniform(-0.15, 0.15), pos[2] + height * 0.35)),
        Vector((pos[0] + random.uniform(-0.3, 0.3), pos[1] + random.uniform(-0.3, 0.3), pos[2] + height * 0.65)),
        Vector((pos[0] + random.uniform(-0.2, 0.2), pos[1] + random.uniform(-0.2, 0.2), pos[2] + height * 0.85)),
    ]
    
    def create_limb(pts, start_r, end_r, l_name):
        curve_data = bpy.data.curves.new(l_name, type='CURVE')
        curve_data.dimensions = '3D'
        curve_data.bevel_depth = start_r
        curve_data.bevel_resolution = 3
        spline = curve_data.splines.new('BEZIER')
        spline.bezier_points.add(len(pts) - 1)
        for i, pt in enumerate(pts):
            bp = spline.bezier_points[i]
            bp.co = pt
            bp.handle_left_type = 'AUTO'
            bp.handle_right_type = 'AUTO'
            # Taper
            bp.radius = (start_r - (start_r - end_r) * (i / float(len(pts) - 1))) / start_r
        lobj = bpy.data.objects.new(l_name, curve_data)
        tree_col.objects.link(lobj)
        assign_material(lobj, clay)
        return lobj
        
    create_limb(trunk_pts, 0.22, 0.10, f"{name}_trunk")
    
    # 3 Primary main branches
    top_pt = trunk_pts[-1]
    num_branches = 4
    for b in range(num_branches):
        angle = (b / float(num_branches)) * math.pi * 2 + random.uniform(-0.4, 0.4)
        reach = random.uniform(1.4, 2.2)
        b_mid = top_pt + Vector((math.cos(angle)*reach*0.5, math.sin(angle)*reach*0.5, random.uniform(0.6, 1.2)))
        b_end = top_pt + Vector((math.cos(angle)*reach, math.sin(angle)*reach, random.uniform(1.2, 2.0)))
        create_limb([top_pt, b_mid, b_end], 0.11, 0.045, f"{name}_b_{b}")
        
        # 2 secondary twigs per primary branch
        for tw in range(2):
            tw_angle = angle + random.uniform(-0.6, 0.6)
            tw_reach = random.uniform(0.8, 1.3)
            tw_end = b_end + Vector((math.cos(tw_angle)*tw_reach, math.sin(tw_angle)*tw_reach, random.uniform(0.3, 0.8)))
            create_limb([b_end, tw_end], 0.045, 0.018, f"{name}_tw_{b}_{tw}")
            
    return tree_col

# ── PROPS: BOXES, CRATES, PALLETS & RUBBLE ──

def create_wooden_pallet(name, pos, rot_z_deg=0, col=None):
    clay = get_clay_material()
    p_col = bpy.data.collections.new(name)
    if col:
        col.children.link(p_col)
    else:
        bpy.context.scene.collection.children.link(p_col)
        
    rot = (0, 0, math.radians(rot_z_deg))
    cos_r = math.cos(math.radians(rot_z_deg))
    sin_r = math.sin(math.radians(rot_z_deg))
    def l2g(lx, ly, lz):
        return (pos[0] + (lx*cos_r - ly*sin_r), pos[1] + (lx*sin_r + ly*cos_r), pos[2] + lz)
        
    # 3 Bottom runners
    for rx in [-0.5, 0.0, 0.5]:
        create_box(f"{name}_run_{rx}", (0.08, 1.2, 0.09), l2g(rx, 0, 0.045), rot=rot, collection=p_col, mat=clay, bevel_w=0.01)
    # 5 Top deck boards
    for dy in [-0.5, -0.25, 0.0, 0.25, 0.5]:
        create_box(f"{name}_slat_{dy}", (1.1, 0.14, 0.025), l2g(0, dy, 0.10), rot=rot, collection=p_col, mat=clay, bevel_w=0.008)
    return p_col

def create_crate_cluster(name, pos, col=None):
    """Creates a cluster of stacked cardboard storage boxes and wooden crates."""
    clay = get_clay_material()
    crate_col = bpy.data.collections.new(name)
    if col:
        col.children.link(crate_col)
    else:
        bpy.context.scene.collection.children.link(crate_col)
        
    boxes = [
        # (size, offset, rot_z)
        ((0.9, 0.9, 0.8), (0.0, 0.0, 0.4), 8),
        ((0.85, 0.85, 0.75), (0.05, 0.05, 1.18), -6),
        ((0.7, 0.7, 0.6), (0.9, 0.1, 0.3), 15),
        ((0.6, 0.8, 0.5), (0.85, 0.15, 0.85), -12),
        ((0.8, 0.8, 0.7), (-0.85, -0.1, 0.35), 4),
        ((0.75, 0.75, 0.65), (-0.8, -0.05, 1.02), 18),
        ((0.55, 0.55, 0.45), (0.2, 0.9, 0.23), -22),
    ]
    for idx, (sz, off, rz) in enumerate(boxes):
        create_box(f"{name}_box_{idx}", sz, (pos[0] + off[0], pos[1] + off[1], pos[2] + off[2]), 
                   rot=(0, 0, math.radians(rz)), collection=crate_col, mat=clay, bevel_w=0.018)
    return crate_col

def create_rubble_scatter(name, center_pos, count=12, radius=1.8, col=None):
    """Scatters small concrete rubble chunks and bricks around crashed cars/curbs."""
    clay = get_clay_material()
    random.seed(int(center_pos[0] * 17 + center_pos[1] * 31))
    for i in range(count):
        dist = random.uniform(0.3, radius)
        ang = random.uniform(0, math.pi * 2)
        rx = center_pos[0] + math.cos(ang) * dist
        ry = center_pos[1] + math.sin(ang) * dist
        rz = center_pos[2] + random.uniform(0.04, 0.08)
        sz = (random.uniform(0.12, 0.28), random.uniform(0.14, 0.32), random.uniform(0.08, 0.16))
        create_box(f"{name}_rub_{i}", sz, (rx, ry, rz), 
                   rot=(random.uniform(-0.1, 0.1), random.uniform(-0.1, 0.1), random.uniform(0, math.pi*2)),
                   collection=col, mat=clay, bevel_w=0.01)

def create_ac_unit(name, pos, rot_z_deg=0, col=None):
    """Rooftop air conditioning compressor unit with fan grille."""
    clay = get_clay_material()
    rot = (0, 0, math.radians(rot_z_deg))
    ac_col = bpy.data.collections.new(name)
    if col:
        col.children.link(ac_col)
    else:
        bpy.context.scene.collection.children.link(ac_col)
        
    # Main condenser box
    create_box(f"{name}_body", (0.95, 0.80, 0.75), (pos[0], pos[1], pos[2] + 0.375), rot=rot, collection=ac_col, mat=clay, bevel_w=0.02)
    # Fan grille cylinder on top
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, radius1=0.28, radius2=0.28, depth=0.08, segments=16)
    m = bpy.data.meshes.new(f"{name}_fan_mesh")
    bm.to_mesh(m)
    bm.free()
    fan = bpy.data.objects.new(f"{name}_fan", m)
    fan.location = (pos[0], pos[1], pos[2] + 0.79)
    fan.rotation_euler = rot
    ac_col.objects.link(fan)
    assign_material(fan, clay)
    add_bevel(fan, width=0.01)
    return ac_col

# ── COMPLETE SCENE ASSEMBLY ──

def build_complete_urban_alleyway():
    print("[1/6] Clearing scene and initializing collections...")
    clear_scene()
    
    col_arch = get_or_create_collection("Architecture")
    col_streets = get_or_create_collection("Streets_Stairs")
    col_vehicles = get_or_create_collection("Vehicles")
    col_poles = get_or_create_collection("Poles_Cables")
    col_foliage = get_or_create_collection("Trees_Foliage")
    col_props = get_or_create_collection("Props_Debris")
    col_env = get_or_create_collection("Lighting_Camera")
    
    clay = get_clay_material()
    recess_mat = get_dark_recess_material()
    
    # ── 1. GROUND TILES & STREET SURFACES ──
    print("[2/6] Building street tiles, retaining walls, and staircases...")
    # Lower street base
    create_box("Street_Lower", (16.0, 18.0, 0.4), (0.0, -6.0, -0.2), collection=col_streets, mat=clay, bevel_w=0.03)
    # Upper terrace base
    create_box("Street_Upper_Terrace", (14.0, 16.0, 0.4), (0.0, 9.0, 3.4), collection=col_streets, mat=clay, bevel_w=0.03)
    # Background high street
    create_box("Street_Upper_Alley", (12.0, 16.0, 0.4), (1.0, 18.0, 4.2), collection=col_streets, mat=clay, bevel_w=0.03)
    
    # Retaining walls separating street levels
    create_box("Retaining_Wall_Mid", (14.0, 0.8, 3.8), (-1.5, 6.4, 1.9), collection=col_streets, mat=clay, bevel_w=0.03)
    
    # Curbs on lower street
    create_box("Curb_Lower_L", (0.35, 14.0, 0.22), (-3.2, -6.0, 0.11), collection=col_streets, mat=clay, bevel_w=0.015)
    create_box("Curb_Lower_R", (0.35, 12.0, 0.22), (2.8, -7.0, 0.11), collection=col_streets, mat=clay, bevel_w=0.015)
    
    # Long Street Staircase (22 steps climbing from Z=0 to Z=3.6)
    create_street_staircase("Staircase_Main", (0.2, -2.2, 0.0), (1.6, 6.2, 3.6), width=2.8, num_steps=22, col=col_streets)
    
    # Upper Terrace 4-Step Flight
    create_street_staircase("Staircase_Upper", (0.5, 7.2, 3.6), (0.8, 9.0, 4.3), width=2.6, num_steps=5, col=col_streets)
    
    # Angled retaining divider on mid-terrace matching Image 1
    create_box("Terrace_Angled_Parapet", (3.2, 0.35, 0.65), (-0.8, 6.8, 4.0), rot=(0, 0, math.radians(-35)), collection=col_streets, mat=clay, bevel_w=0.02)
    
    # ── 2. MONOLITHIC BUILDINGS & EXTERIOR STAIRS ──
    print("[3/6] Generating architectural blocks and facade recesses...")
    
    # Building 1 (Bottom-Left Foreground, 2-story)
    b1_wins = [
        ('right', -1.2, 4.8, 0.95, 1.25),
        ('right', 1.2, 4.8, 0.95, 1.25),
        ('right', -1.2, 2.2, 0.95, 1.25),
        ('front', -1.0, 4.8, 0.95, 1.25),
    ]
    b1_doors = [('right', 0.8, 1.1, 2.2)]
    # Building 1 (Bottom-Left Foreground, 2-story - shifted left and lower to frame street)
    b1_wins = [
        ('right', -1.2, 4.0, 0.95, 1.25),
        ('right', 1.2, 4.0, 0.95, 1.25),
        ('front', -1.0, 4.0, 0.95, 1.25),
    ]
    b1_doors = [('right', 0.8, 1.1, 2.2)]
    create_building_block("Building_1_SouthWest", (-8.8, -8.2, 0.0), (5.8, 6.2, 6.0), windows=b1_wins, doors=b1_doors, col=col_arch)
    
    # Building 2 (Mid-Left with Exterior Wrap Staircase & Rooftop AC)
    b2_wins = [
        ('right', -1.8, 7.5, 1.0, 1.3),
        ('right', 1.5, 7.5, 1.0, 1.3),
        ('right', -1.8, 4.2, 1.0, 1.3),
        ('right', 1.5, 10.2, 1.0, 1.3),
    ]
    b2_doors = [
        ('right', -0.2, 1.1, 2.2), # Ground door
        ('right', 2.8, 1.05, 2.1), # Second-floor door at top of exterior stairs!
    ]
    create_building_block("Building_2_MidWest", (-8.2, 2.5, 0.0), (6.8, 8.5, 11.5), windows=b2_wins, doors=b2_doors, col=col_arch)
    # Exterior wrap staircase climbing along Building 2's right facade wall to the 2nd floor door
    create_exterior_wrap_stairs("Bld2_Exterior_Stairs", (-4.3, -0.8, 0.0), target_z=3.8, step_width=1.05, num_steps=18, along_axis='Y', direction=1, col=col_arch)
    # Rooftop AC unit on Building 2
    create_ac_unit("AC_Building_2", (-7.2, 3.5, 11.5), rot_z_deg=25, col=col_props)
    # Rooftop stairwell access box
    create_box("Bld2_Roof_Access", (1.8, 2.2, 1.6), (-6.0, 0.8, 12.3), collection=col_arch, mat=clay, bevel_w=0.02)
    
    # Building 3 (Mid-Center Angled Facade matching Image 1)
    b3_pos = (-0.6, 10.5, 3.8)
    # Main block
    create_box("Building_3_Main", (6.5, 6.8, 11.8), (b3_pos[0] - 1.2, b3_pos[1] + 1.2, b3_pos[2] + 5.9), collection=col_arch, mat=clay, bevel_w=0.03)
    # Chamfered / Angled 45° facade wing
    create_box("Building_3_Chamfer", (4.8, 4.8, 11.8), (b3_pos[0] + 0.8, b3_pos[1] - 0.8, b3_pos[2] + 5.9), 
               rot=(0, 0, math.radians(45)), collection=col_arch, mat=clay, bevel_w=0.03)
    # Doorway on the angled facade
    create_box("Building_3_Door", (1.1, 0.25, 2.2), (b3_pos[0] - 0.2, b3_pos[1] - 1.8, b3_pos[2] + 1.1), 
               rot=(0, 0, math.radians(45)), collection=col_arch, mat=recess_mat, bevel=False)
    # Recessed lightwell / roof opening on Building 3
    create_box("Bld3_Roof_Recess", (1.8, 1.8, 1.2), (b3_pos[0] - 1.5, b3_pos[1] + 2.2, b3_pos[2] + 11.2), collection=col_arch, mat=clay, bevel_w=0.02)
    
    # Building 4 (Bottom-Right Foreground with 5-Step Entrance Flight)
    b4_wins = [
        ('front', -1.2, 4.8, 0.95, 1.25),
        ('front', 1.2, 4.8, 0.95, 1.25),
        ('left', -1.5, 4.8, 0.95, 1.25),
        ('left', 1.5, 4.8, 0.95, 1.25),
        ('left', 1.5, 2.2, 0.95, 1.25),
    ]
    b4_doors = [('left', -1.2, 1.15, 2.2)]
    create_building_block("Building_4_SouthEast", (6.2, -4.5, 0.0), (6.5, 7.8, 8.5), windows=b4_wins, doors=b4_doors, col=col_arch)
    # 5-step concrete fan/rectangular staircase leading up to Building 4's door
    for sidx in range(5):
        sw = 2.4 - sidx * 0.15
        sd = 1.6 - sidx * 0.18
        create_box(f"Bld4_Entry_Step_{sidx}", (sd, sw, 0.18), (2.5 + sidx * 0.14, -5.7, 0.09 + sidx * 0.18), collection=col_arch, mat=clay, bevel_w=0.012)
        
    # Building 5 (Middle-Right Monolithic Wall along Long Stairs)
    b5_wins = [
        ('left', -3.2, 8.5, 1.0, 1.3),
        ('left', 0.0, 8.5, 1.0, 1.3),
        ('left', 3.2, 8.5, 1.0, 1.3),
        ('left', -1.5, 5.0, 1.0, 1.3),
        ('left', 2.0, 5.0, 1.0, 1.3),
    ]
    create_building_block("Building_5_MidEast", (7.8, 6.0, 0.0), (6.8, 14.0, 13.5), windows=b5_wins, col=col_arch)
    
    # Building 6 (Top-Right Background)
    b6_wins = [('left', -1.2, 5.0, 1.0, 1.3), ('left', 1.2, 5.0, 1.0, 1.3)]
    create_building_block("Building_6_NorthEast", (7.2, 17.0, 3.8), (6.5, 8.0, 10.5), windows=b6_wins, col=col_arch)
    
    # Building 7 (Top-Left High Rooftop Terrace with parked car)
    create_building_block("Building_7_NorthWest", (-5.5, 16.5, 4.0), (7.0, 7.5, 9.5), col=col_arch)
    
    # ── 3. DETAILED ABANDONED VEHICLES (7 CARS AS IN IMAGE 1) ──
    print("[4/6] Constructing detailed low-poly abandoned vehicles...")
    # Car 1 (Bottom-left sedan parked askew beside pole & dead tree)
    create_car("Car_1_Sedan_SouthWest", (-3.8, -7.6, 0.05), rot_z_deg=24, is_hatchback=False, col=col_vehicles)
    
    # Car 2 (Bottom-right sedan angled diagonally in street)
    create_car("Car_2_Sedan_SouthEast", (3.2, -8.2, 0.05), rot_z_deg=-38, is_hatchback=False, col=col_vehicles)
    
    # Car 3 (Lower center hatchback parked at intersection)
    create_car("Car_3_Hatchback_LowerCenter", (0.5, -4.6, 0.05), rot_z_deg=14, is_hatchback=True, col=col_vehicles)
    
    # Car 4 (Mid-street sedan at the top landing of long stairs)
    create_car("Car_4_Sedan_MidLanding", (0.8, 6.2, 3.65), rot_z_deg=34, is_hatchback=False, col=col_vehicles)
    
    # Car 5 (Upper alley sedan 1 beside dead tree)
    create_car("Car_5_Sedan_UpperAlley_1", (2.4, 12.4, 4.25), rot_z_deg=22, is_hatchback=False, col=col_vehicles)
    
    # Car 6 (Upper alley car 2 parked in tandem behind Car 5)
    create_car("Car_6_Sedan_UpperAlley_2", (2.0, 15.6, 4.65), rot_z_deg=-16, is_hatchback=True, col=col_vehicles)
    
    # Car 7 (Parked on top-left rooftop terrace)
    create_car("Car_7_Sedan_RooftopTerrace", (-4.8, 15.2, 13.55), rot_z_deg=78, is_hatchback=False, col=col_vehicles)
    
    # ── 4. UTILITY POLES & SAGGY CATENARY POWER CABLES ──
    print("[5/6] Erecting utility poles and catenary power cables...")
    pole1_col, p1_pts = create_utility_pole("Utility_Pole_1", (-4.6, -7.5, 0.0), height=8.4, col=col_poles)
    pole2_col, p2_pts = create_utility_pole("Utility_Pole_2", (1.8, 1.4, 1.8), height=8.4, col=col_poles)
    pole3_col, p3_pts = create_utility_pole("Utility_Pole_3", (3.6, 11.2, 4.0), height=8.4, col=col_poles)
    
    # 4 Sagging cables from Pole 1 to Pole 2
    for i in range(4):
        create_catenary_cable(f"Cable_P1_P2_{i}", p1_pts[i], p2_pts[i], sag=0.48, col=col_poles)
        
    # 4 Sagging cables from Pole 2 to Pole 3
    for i in range(4):
        create_catenary_cable(f"Cable_P2_P3_{i}", p2_pts[i], p3_pts[i], sag=0.52, col=col_poles)
        
    # Service drop cables running into buildings
    create_catenary_cable("Cable_Drop_Bld2", p2_pts[0], Vector((-3.6, 2.5, 7.8)), sag=0.35, col=col_poles)
    create_catenary_cable("Cable_Drop_Bld5", p2_pts[3], Vector((4.4, 3.2, 8.5)), sag=0.38, col=col_poles)
    
    # ── 5. DEAD TREES, CLUTTER, CRATES, PALLETS & RUBBLE ──
    # Dead Bare Trees casting dramatic branching shadows
    create_dead_tree("Dead_Tree_1", (-5.4, -8.6, 0.0), height=6.2, seed_val=142, col=col_foliage)
    create_dead_tree("Dead_Tree_2", (2.8, 0.4, 0.6), height=5.4, seed_val=284, col=col_foliage)
    create_dead_tree("Dead_Tree_3", (1.6, 11.8, 4.0), height=6.0, seed_val=512, col=col_foliage)
    
    # Stacked crates and storage boxes in the alley nook left of long stairs
    create_crate_cluster("Crates_Alley_Nook", (-2.2, 0.6, 0.0), col=col_props)
    create_wooden_pallet("Pallet_Alley_1", (-2.0, -0.8, 0.0), rot_z_deg=18, col=col_props)
    create_wooden_pallet("Pallet_Alley_2", (-1.8, 1.8, 0.0), rot_z_deg=-25, col=col_props)
    
    # Scattered concrete rubble bricks around cars
    create_rubble_scatter("Rubble_Car2", (3.2, -8.2, 0.0), count=16, radius=2.2, col=col_props)
    create_rubble_scatter("Rubble_Car3", (0.5, -4.6, 0.0), count=12, radius=1.8, col=col_props)
    create_rubble_scatter("Rubble_Curb", (-2.8, -5.5, 0.0), count=8, radius=1.2, col=col_props)
    
    # ── 6. LIGHTING, CAMERA & CYCLES OPTIX SETUP ──
    print("[6/6] Calibrating camera perspective, directional sun, and Cycles OptiX...")
    scene = bpy.context.scene
    
    # Resolution: 1080 x 1920 (9:16 Portrait diorama matching Image 1)
    scene.render.resolution_x = 1080
    scene.render.resolution_y = 1920
    scene.render.resolution_percentage = 100
    
    # Camera: Calibrated Orthographic Isometric Camera
    cam_data = bpy.data.cameras.new("Diorama_Isometric_Camera")
    cam_data.type = 'ORTHO'
    cam_data.ortho_scale = 32.0
    cam_data.clip_start = 0.1
    cam_data.clip_end = 250.0
    
    cam_obj = bpy.data.objects.new("Diorama_Camera", cam_data)
    cam_obj.location = (-18.0, -26.0, 26.0)
    
    # Target tracking constraint
    look_target = create_box("Camera_Target", (0.2, 0.2, 0.2), (0.2, 3.5, 3.2), collection=col_env, bevel=False)
    look_target.hide_render = True
    
    track = cam_obj.constraints.new(type='TRACK_TO')
    track.target = look_target
    track.track_axis = 'TRACK_NEGATIVE_Z'
    track.up_axis = 'UP_Y'
    
    col_env.objects.link(cam_obj)
    scene.camera = cam_obj
    
    # Directional Sun Light (Matching the crisp, stark shadows in Image 1)
    sun_data = bpy.data.lights.new("Sun_KeyLight", type='SUN')
    sun_data.energy = 5.5
    sun_data.angle = math.radians(1.4) # Soft natural shadow penumbra
    sun_data.color = (1.0, 0.99, 0.97)
    
    sun_obj = bpy.data.objects.new("Sun_KeyLight", sun_data)
    # Precise sun direction from upper-right to lower-left
    sun_dir = Vector((-0.68, -0.42, -0.60)).normalized()
    rot_quat = Vector((0, 0, -1)).rotation_difference(sun_dir)
    sun_obj.rotation_euler = rot_quat.to_euler()
    col_env.objects.link(sun_obj)
    
    # Ambient World Fill (soft gray sky fill into crevices)
    if not scene.world:
        scene.world = bpy.data.worlds.new("Diorama_World")
    if scene.world.node_tree:
        bg_node = scene.world.node_tree.nodes.get("Background")
        if bg_node:
            bg_node.inputs["Color"].default_value = (0.86, 0.87, 0.90, 1.0)
            bg_node.inputs["Strength"].default_value = 0.42
        
    # Cycles Render Engine Setup with OptiX GPU Acceleration
    scene.render.engine = 'CYCLES'
    cycles = scene.cycles
    cycles.device = 'GPU'
    
    # Enable OptiX in preferences
    cycles_prefs = bpy.context.preferences.addons['cycles'].preferences
    cycles_prefs.compute_device_type = 'OPTIX'
    cycles_prefs.get_devices()
    for d in cycles_prefs.devices:
        if d.type in ['OPTIX', 'CUDA']:
            d.use = True
            print(f"  -> Cycles using GPU Device: {d.name} ({d.type})")
            
    cycles.samples = 128
    cycles.preview_samples = 32
    cycles.use_denoising = True
    cycles.denoiser = 'OPTIX'
    cycles.use_adaptive_sampling = True
    cycles.max_bounces = 8
    cycles.diffuse_bounces = 4
    cycles.glossy_bounces = 4
    cycles.transparent_max_bounces = 8
    
    # Color Management (High contrast architectural clay feel)
    scene.view_settings.view_transform = 'AgX' if 'AgX' in [vt.name for vt in bpy.types.ColorManagedViewSettings.bl_rna.properties['view_transform'].enum_items] else 'Filmic'
    scene.view_settings.look = 'High Contrast'
    scene.view_settings.exposure = 0.05
    
    # Save the complete .blend file!
    blend_path = "d:/Godot_Devs/Zombie_shooter/blender_scene/urban_alleyway_layout.blend"
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    print(f">> Successfully built and saved Blender scene to: {blend_path}")
    
    # Render High-Resolution Image!
    render_path = "d:/Godot_Devs/Zombie_shooter/blender_scene/urban_alleyway_render.png"
    scene.render.filepath = render_path
    print(f">> Rendering frame to: {render_path} ...")
    bpy.ops.render.render(write_still=True)
    print(">> Render complete!")

if __name__ == "__main__":
    build_complete_urban_alleyway()

