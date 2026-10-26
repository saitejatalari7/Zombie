import bpy
import bmesh
import math
import os
from mathutils import Vector, Matrix

out_dir = r"d:\Godot_Devs\Zombie_shooter\assets\models\characters"
weapons_dir = r"d:\Godot_Devs\Zombie_shooter\assets\models\weapons"
os.makedirs(out_dir, exist_ok=True)
os.makedirs(weapons_dir, exist_ok=True)

def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def create_material(name, albedo_color, roughness=0.5, metallic=0.0, emission=None, emission_energy=1.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs['Base Color'].default_value = albedo_color
        bsdf.inputs['Roughness'].default_value = roughness
        bsdf.inputs['Metallic'].default_value = metallic
        if emission and 'Emission Color' in bsdf.inputs:
            bsdf.inputs['Emission Color'].default_value = emission
            if 'Emission Strength' in bsdf.inputs:
                bsdf.inputs['Emission Strength'].default_value = emission_energy
    return mat

def apply_material(obj, mat):
    if obj.data.materials:
        obj.data.materials[0] = mat
    else:
        obj.data.materials.append(mat)

def join_and_pivot(obj_list, final_name, pivot_pos, parent=None):
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
    
    # Set pivot/origin to pivot_pos
    orig_cursor = bpy.context.scene.cursor.location.copy()
    bpy.context.scene.cursor.location = Vector(pivot_pos)
    bpy.context.view_layer.objects.active = joined
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR', center='MEDIAN')
    bpy.context.scene.cursor.location = orig_cursor
    
    if parent:
        joined.parent = parent
        joined.matrix_parent_inverse = parent.matrix_world.inverted()
        
    return joined

# ==============================================================================
# 1. PLAYER OPERATIVE MODEL
# ==============================================================================
def build_player_model():
    clear_scene()

    mat_white = create_material("Mat_ArmorWhite", (0.92, 0.93, 0.96, 1.0), roughness=0.25, metallic=0.05)
    mat_black = create_material("Mat_TacticalBlack", (0.08, 0.08, 0.10, 1.0), roughness=0.75, metallic=0.0)
    mat_scarf = create_material("Mat_CrimsonScarf", (0.85, 0.02, 0.06, 1.0), roughness=0.8, metallic=0.0)
    mat_visor = create_material("Mat_Visor", (0.02, 0.02, 0.03, 1.0), roughness=0.08, metallic=0.95, emission=(0.0, 0.45, 0.7, 1.0), emission_energy=0.8)
    mat_metal = create_material("Mat_GunMetal", (0.18, 0.20, 0.22, 1.0), roughness=0.35, metallic=0.85)

    root = bpy.data.objects.new("PlayerCharacter", None)
    bpy.context.collection.objects.link(root)
    root.location = (0, 0, 0)

    # ── Torso Assembly ──
    torso_parts = []
    # Chest base
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    t = bpy.context.active_object
    t.scale = (0.24, 0.16, 0.32)
    t.location = (0, 0, 1.05)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(t, mat_white)
    torso_parts.append(t)
    
    # Front ballistic chest plate
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    cp = bpy.context.active_object
    cp.scale = (0.21, 0.04, 0.20)
    cp.location = (0, -0.17, 1.12)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(cp, mat_white)
    torso_parts.append(cp)

    # 3 Mag Pouches
    for x_off in [-0.11, 0.0, 0.11]:
        bpy.ops.mesh.primitive_cube_add(size=1.0)
        p = bpy.context.active_object
        p.scale = (0.045, 0.04, 0.09)
        p.location = (x_off, -0.19, 0.97)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        apply_material(p, mat_black)
        torso_parts.append(p)

    # Tactical duty belt
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    ub = bpy.context.active_object
    ub.scale = (0.26, 0.18, 0.06)
    ub.location = (0, 0, 0.81)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(ub, mat_black)
    torso_parts.append(ub)

    # Side radio holster
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    sh = bpy.context.active_object
    sh.scale = (0.04, 0.08, 0.08)
    sh.location = (0.14, 0.04, 0.82)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(sh, mat_black)
    torso_parts.append(sh)

    join_and_pivot(torso_parts, "Torso", (0, 0, 0.81), root)

    # ── Scarf Assembly (Crimson Shemagh) ──
    scarf_parts = []
    bpy.ops.mesh.primitive_cylinder_add(radius=0.18, depth=0.12, vertices=16)
    sc = bpy.context.active_object
    sc.location = (0, -0.02, 1.30)
    sc.scale = (1.08, 0.98, 1.0)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(sc, mat_scarf)
    scarf_parts.append(sc)

    # Hanging scarf tails
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    st1 = bpy.context.active_object
    st1.scale = (0.07, 0.03, 0.18)
    st1.location = (-0.08, -0.17, 1.18)
    st1.rotation_euler = (0, 0, math.radians(-12))
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(st1, mat_scarf)
    scarf_parts.append(st1)

    bpy.ops.mesh.primitive_cube_add(size=1.0)
    st2 = bpy.context.active_object
    st2.scale = (0.06, 0.03, 0.14)
    st2.location = (-0.02, -0.17, 1.20)
    st2.rotation_euler = (0, 0, math.radians(8))
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(st2, mat_scarf)
    scarf_parts.append(st2)

    join_and_pivot(scarf_parts, "Scarf", (0, 0, 1.25), root)

    # ── Head & Helmet Assembly ──
    head_parts = []
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    hb = bpy.context.active_object
    hb.scale = (0.16, 0.18, 0.17)
    hb.location = (0, -0.01, 1.48)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(hb, mat_black)
    head_parts.append(hb)

    # Helmet dome
    bpy.ops.mesh.primitive_cylinder_add(radius=0.18, depth=0.15, vertices=16)
    hl = bpy.context.active_object
    hl.location = (0, -0.01, 1.54)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(hl, mat_black)
    head_parts.append(hl)

    # Glossy Visor with HUD glow
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    vs = bpy.context.active_object
    vs.scale = (0.16, 0.04, 0.065)
    vs.location = (0, -0.17, 1.47)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(vs, mat_visor)
    head_parts.append(vs)

    # Tactical side headset / ear-pro
    for x_ear in [-0.17, 0.17]:
        bpy.ops.mesh.primitive_cube_add(size=1.0)
        ep = bpy.context.active_object
        ep.scale = (0.025, 0.05, 0.07)
        ep.location = (x_ear, -0.01, 1.48)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        apply_material(ep, mat_black)
        head_parts.append(ep)

    join_and_pivot(head_parts, "Head", (0, 0, 1.36), root)

    # ── Backpack Assembly ──
    pack_parts = []
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    bp = bpy.context.active_object
    bp.scale = (0.20, 0.12, 0.26)
    bp.location = (0, 0.19, 1.10)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(bp, mat_black)
    pack_parts.append(bp)

    # Long whip tactical antenna
    bpy.ops.mesh.primitive_cylinder_add(radius=0.01, depth=0.40, vertices=8)
    at = bpy.context.active_object
    at.location = (0.13, 0.23, 1.38)
    at.rotation_euler = (math.radians(-8), math.radians(5), 0)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(at, mat_metal)
    pack_parts.append(at)

    join_and_pivot(pack_parts, "Backpack", (0, 0.14, 1.10), root)

    # ── Left Arm Assembly (Pivot at Shoulder: -0.28, 0, 1.20) ──
    arm_l_parts = []
    # Pauldron / shoulder guard
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    sp_l = bpy.context.active_object
    sp_l.scale = (0.09, 0.10, 0.09)
    sp_l.location = (-0.28, 0, 1.20)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(sp_l, mat_white)
    arm_l_parts.append(sp_l)

    # Bicep & Forearm
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    lb_l = bpy.context.active_object
    lb_l.scale = (0.065, 0.065, 0.28)
    lb_l.location = (-0.26, -0.12, 1.05)
    lb_l.rotation_euler = (math.radians(35), math.radians(-15), 0)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(lb_l, mat_white)
    arm_l_parts.append(lb_l)

    # Tactical Glove
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    gl_l = bpy.context.active_object
    gl_l.scale = (0.06, 0.07, 0.07)
    gl_l.location = (-0.20, -0.26, 0.92)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(gl_l, mat_black)
    arm_l_parts.append(gl_l)

    join_and_pivot(arm_l_parts, "ArmLeft", (-0.28, 0.0, 1.20), root)

    # ── Right Arm Assembly (Pivot at Shoulder: 0.28, 0, 1.20) ──
    arm_r_parts = []
    # Shoulder guard
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    sp_r = bpy.context.active_object
    sp_r.scale = (0.09, 0.10, 0.09)
    sp_r.location = (0.28, 0, 1.20)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(sp_r, mat_white)
    arm_r_parts.append(sp_r)

    # Arm angled forward holding rifle
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    lb_r = bpy.context.active_object
    lb_r.scale = (0.065, 0.065, 0.28)
    lb_r.location = (0.26, -0.12, 1.05)
    lb_r.rotation_euler = (math.radians(35), math.radians(15), 0)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(lb_r, mat_white)
    arm_r_parts.append(lb_r)

    # Tactical Glove
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    gl_r = bpy.context.active_object
    gl_r.scale = (0.06, 0.07, 0.07)
    gl_r.location = (0.20, -0.26, 0.92)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(gl_r, mat_black)
    arm_r_parts.append(gl_r)

    join_and_pivot(arm_r_parts, "ArmRight", (0.28, 0.0, 1.20), root)

    # ── Left Leg Assembly (Pivot at Hip: -0.14, 0, 0.78) ──
    leg_l_parts = []
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    th_l = bpy.context.active_object
    th_l.scale = (0.085, 0.095, 0.36)
    th_l.location = (-0.14, 0, 0.60)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(th_l, mat_white)
    leg_l_parts.append(th_l)

    # Knee armor plate
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    kp_l = bpy.context.active_object
    kp_l.scale = (0.09, 0.04, 0.08)
    kp_l.location = (-0.14, -0.06, 0.42)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(kp_l, mat_black)
    leg_l_parts.append(kp_l)

    # Shin
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    sh_l = bpy.context.active_object
    sh_l.scale = (0.08, 0.09, 0.34)
    sh_l.location = (-0.14, 0, 0.25)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(sh_l, mat_white)
    leg_l_parts.append(sh_l)

    # Combat boot
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    bt_l = bpy.context.active_object
    bt_l.scale = (0.09, 0.16, 0.10)
    bt_l.location = (-0.14, -0.03, 0.05)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(bt_l, mat_black)
    leg_l_parts.append(bt_l)

    join_and_pivot(leg_l_parts, "LegLeft", (-0.14, 0.0, 0.78), root)

    # ── Right Leg Assembly (Pivot at Hip: 0.14, 0, 0.78) ──
    leg_r_parts = []
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    th_r = bpy.context.active_object
    th_r.scale = (0.085, 0.095, 0.36)
    th_r.location = (0.14, 0, 0.60)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(th_r, mat_white)
    leg_r_parts.append(th_r)

    # Knee plate
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    kp_r = bpy.context.active_object
    kp_r.scale = (0.09, 0.04, 0.08)
    kp_r.location = (0.14, -0.06, 0.42)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(kp_r, mat_black)
    leg_r_parts.append(kp_r)

    # Shin
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    sh_r = bpy.context.active_object
    sh_r.scale = (0.08, 0.09, 0.34)
    sh_r.location = (0.14, 0, 0.25)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(sh_r, mat_white)
    leg_r_parts.append(sh_r)

    # Boot
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    bt_r = bpy.context.active_object
    bt_r.scale = (0.09, 0.16, 0.10)
    bt_r.location = (0.14, -0.03, 0.05)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(bt_r, mat_black)
    leg_r_parts.append(bt_r)

    join_and_pivot(leg_r_parts, "LegRight", (0.14, 0.0, 0.78), root)

    target_path = os.path.join(out_dir, "player_operative.glb")
    bpy.ops.export_scene.gltf(
        filepath=target_path,
        export_format='GLB',
        use_selection=False,
        export_apply=True
    )
    print(f"Exported Operative Player to {target_path}")

# ==============================================================================
# 2. ZOMBIE SHAMBLER MODEL (Iconic Faceted Bone Cubic Skull)
# ==============================================================================
def build_zombie_shambler():
    clear_scene()

    mat_skull = create_material("Mat_ZombieSkull", (0.94, 0.94, 0.95, 1.0), roughness=0.85, metallic=0.0)
    mat_eyes = create_material("Mat_ZombieHollow", (0.04, 0.04, 0.05, 1.0), roughness=1.0, metallic=0.0)
    mat_charcoal = create_material("Mat_ZombieBody", (0.12, 0.12, 0.14, 1.0), roughness=0.95, metallic=0.0)

    root = bpy.data.objects.new("ZombieShambler", None)
    bpy.context.collection.objects.link(root)
    root.location = (0, 0, 0)

    # ── Torso ──
    torso_parts = []
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    t = bpy.context.active_object
    t.scale = (0.22, 0.16, 0.40)
    t.location = (0, 0.04, 0.96)
    t.rotation_euler = (math.radians(14), 0, math.radians(-3))
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(t, mat_charcoal)
    torso_parts.append(t)

    # Slender hunch spine
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    sp = bpy.context.active_object
    sp.scale = (0.05, 0.06, 0.32)
    sp.location = (0, 0.16, 1.00)
    sp.rotation_euler = (math.radians(16), 0, 0)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(sp, mat_charcoal)
    torso_parts.append(sp)

    join_and_pivot(torso_parts, "Torso", (0, 0.04, 0.72), root)

    # ── Head & Skull (Bone White Faceted Skull matching Zombie 2.jpeg) ──
    head_parts = []
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    sk = bpy.context.active_object
    sk.scale = (0.22, 0.23, 0.22)
    sk.location = (0, -0.10, 1.35)
    sk.rotation_euler = (math.radians(8), 0, 0)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(sk, mat_skull)
    head_parts.append(sk)

    # Deep Hollow Eye Sockets
    for x_eye in [-0.06, 0.06]:
        bpy.ops.mesh.primitive_cube_add(size=1.0)
        eye = bpy.context.active_object
        eye.scale = (0.04, 0.04, 0.045)
        eye.location = (x_eye, -0.22, 1.37)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        apply_material(eye, mat_eyes)
        head_parts.append(eye)

    # Open Agonized Mouth Groove
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    mo = bpy.context.active_object
    mo.scale = (0.11, 0.04, 0.04)
    mo.location = (0, -0.21, 1.27)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(mo, mat_eyes)
    head_parts.append(mo)

    join_and_pivot(head_parts, "Head", (0, -0.06, 1.20), root)

    # ── Left Clawing Arm (Reaching forward) ──
    arm_l_parts = []
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    al = bpy.context.active_object
    al.scale = (0.065, 0.40, 0.065)
    al.location = (-0.26, -0.19, 1.08)
    al.rotation_euler = (math.radians(-15), math.radians(10), 0)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(al, mat_charcoal)
    arm_l_parts.append(al)

    # Sharp claw hand
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    cl_l = bpy.context.active_object
    cl_l.scale = (0.08, 0.11, 0.04)
    cl_l.location = (-0.24, -0.40, 1.02)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(cl_l, mat_charcoal)
    arm_l_parts.append(cl_l)

    join_and_pivot(arm_l_parts, "ArmLeft", (-0.26, 0.0, 1.14), root)

    # ── Right Clawing Arm (Reaching forward) ──
    arm_r_parts = []
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    ar = bpy.context.active_object
    ar.scale = (0.065, 0.40, 0.065)
    ar.location = (0.26, -0.19, 1.08)
    ar.rotation_euler = (math.radians(-22), math.radians(-10), 0)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(ar, mat_charcoal)
    arm_r_parts.append(ar)

    bpy.ops.mesh.primitive_cube_add(size=1.0)
    cl_r = bpy.context.active_object
    cl_r.scale = (0.08, 0.11, 0.04)
    cl_r.location = (0.24, -0.40, 1.02)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(cl_r, mat_charcoal)
    arm_r_parts.append(cl_r)

    join_and_pivot(arm_r_parts, "ArmRight", (0.26, 0.0, 1.14), root)

    # ── Left Leg ──
    leg_l_parts = []
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    ll = bpy.context.active_object
    ll.scale = (0.075, 0.085, 0.68)
    ll.location = (-0.13, 0.06, 0.36)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(ll, mat_charcoal)
    leg_l_parts.append(ll)

    join_and_pivot(leg_l_parts, "LegLeft", (-0.13, 0.06, 0.72), root)

    # ── Right Leg ──
    leg_r_parts = []
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    lr = bpy.context.active_object
    lr.scale = (0.075, 0.085, 0.68)
    lr.location = (0.13, 0.06, 0.36)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(lr, mat_charcoal)
    leg_r_parts.append(lr)

    join_and_pivot(leg_r_parts, "LegRight", (0.13, 0.06, 0.72), root)

    target_path = os.path.join(out_dir, "zombie_shambler.glb")
    bpy.ops.export_scene.gltf(
        filepath=target_path,
        export_format='GLB',
        use_selection=False,
        export_apply=True
    )
    print(f"Exported Zombie Shambler to {target_path}")

# ==============================================================================
# 3. ZOMBIE RUNNER MODEL (Predatory Stance + Glowing Crimson Eyes)
# ==============================================================================
def build_zombie_runner():
    clear_scene()

    mat_skull = create_material("Mat_RunnerSkull", (0.90, 0.90, 0.92, 1.0), roughness=0.8, metallic=0.0)
    mat_charcoal = create_material("Mat_RunnerBody", (0.10, 0.10, 0.12, 1.0), roughness=0.95, metallic=0.0)
    mat_crimson_eyes = create_material("Mat_CrimsonEyes", (1.0, 0.04, 0.08, 1.0), roughness=0.1, emission=(1.0, 0.04, 0.08, 1.0), emission_energy=5.0)

    root = bpy.data.objects.new("ZombieRunner", None)
    bpy.context.collection.objects.link(root)
    root.location = (0, 0, 0)

    # Hunched Predatory Spine (32° forward lean)
    torso_parts = []
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    t = bpy.context.active_object
    t.scale = (0.19, 0.15, 0.36)
    t.location = (0, 0.10, 0.86)
    t.rotation_euler = (math.radians(30), 0, 0)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(t, mat_charcoal)
    torso_parts.append(t)
    join_and_pivot(torso_parts, "Torso", (0, 0.10, 0.65), root)

    # Head Tilted Up with Striking Red Eyes
    head_parts = []
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    sk = bpy.context.active_object
    sk.scale = (0.18, 0.20, 0.18)
    sk.location = (0, -0.14, 1.15)
    sk.rotation_euler = (math.radians(-5), 0, 0) # Head tilted up to stare straight forward!
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(sk, mat_skull)
    head_parts.append(sk)

    # Glowing Red Predatory Eyes
    for x_eye in [-0.05, 0.05]:
        bpy.ops.mesh.primitive_cube_add(size=1.0)
        eye = bpy.context.active_object
        eye.scale = (0.035, 0.03, 0.03)
        eye.location = (x_eye, -0.25, 1.17)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        apply_material(eye, mat_crimson_eyes)
        head_parts.append(eye)

    join_and_pivot(head_parts, "Head", (0, -0.08, 1.08), root)

    # Thin, Wiry Sprinting Arms
    arm_l_parts = []
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    al = bpy.context.active_object
    al.scale = (0.055, 0.44, 0.055)
    al.location = (-0.24, -0.24, 0.96)
    al.rotation_euler = (math.radians(-30), math.radians(15), 0)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(al, mat_charcoal)
    arm_l_parts.append(al)
    join_and_pivot(arm_l_parts, "ArmLeft", (-0.24, 0.0, 1.05), root)

    arm_r_parts = []
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    ar = bpy.context.active_object
    ar.scale = (0.055, 0.44, 0.055)
    ar.location = (0.24, -0.24, 0.96)
    ar.rotation_euler = (math.radians(-35), math.radians(-15), 0)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(ar, mat_charcoal)
    arm_r_parts.append(ar)
    join_and_pivot(arm_r_parts, "ArmRight", (0.24, 0.0, 1.05), root)

    # Sprinter Legs
    leg_l_parts = []
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    ll = bpy.context.active_object
    ll.scale = (0.065, 0.075, 0.64)
    ll.location = (-0.12, 0.12, 0.32)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(ll, mat_charcoal)
    leg_l_parts.append(ll)
    join_and_pivot(leg_l_parts, "LegLeft", (-0.12, 0.12, 0.65), root)

    leg_r_parts = []
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    lr = bpy.context.active_object
    lr.scale = (0.065, 0.075, 0.64)
    lr.location = (0.12, 0.12, 0.32)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(lr, mat_charcoal)
    leg_r_parts.append(lr)
    join_and_pivot(leg_r_parts, "LegRight", (0.12, 0.12, 0.65), root)

    target_path = os.path.join(out_dir, "zombie_runner.glb")
    bpy.ops.export_scene.gltf(
        filepath=target_path,
        export_format='GLB',
        use_selection=False,
        export_apply=True
    )
    print(f"Exported Zombie Runner to {target_path}")

# ==============================================================================
# 4. ZOMBIE TANK MODEL (2.5m Brutal Heavyweight with Armored Carapace)
# ==============================================================================
def build_zombie_tank():
    clear_scene()

    mat_skull = create_material("Mat_TankSkull", (0.88, 0.88, 0.90, 1.0), roughness=0.8, metallic=0.0)
    mat_eyes = create_material("Mat_TankEyes", (1.0, 0.08, 0.08, 1.0), roughness=0.2, emission=(1.0, 0.08, 0.08, 1.0), emission_energy=4.0)
    mat_charcoal = create_material("Mat_TankBody", (0.10, 0.10, 0.12, 1.0), roughness=0.95, metallic=0.0)
    mat_armor = create_material("Mat_TankArmor", (0.22, 0.22, 0.26, 1.0), roughness=0.45, metallic=0.65)

    root = bpy.data.objects.new("ZombieTank", None)
    bpy.context.collection.objects.link(root)
    root.location = (0, 0, 0)

    # Massive Hulk Torso + Shoulder Armor Plates
    torso_parts = []
    # Main muscular core
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    t = bpy.context.active_object
    t.scale = (0.58, 0.40, 0.64)
    t.location = (0, 0.02, 1.45)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(t, mat_charcoal)
    torso_parts.append(t)

    # Heavy Carapace Armor Backplate
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    bp = bpy.context.active_object
    bp.scale = (0.50, 0.14, 0.52)
    bp.location = (0, 0.22, 1.52)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(bp, mat_armor)
    torso_parts.append(bp)

    # Broad Shoulder Plates
    for x_sh in [-0.36, 0.36]:
        bpy.ops.mesh.primitive_cube_add(size=1.0)
        sp = bpy.context.active_object
        sp.scale = (0.24, 0.28, 0.18)
        sp.location = (x_sh, 0.02, 1.76)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        apply_material(sp, mat_armor)
        torso_parts.append(sp)

    join_and_pivot(torso_parts, "Torso", (0, 0.02, 1.10), root)

    # Heavy Massive Bone Skull with Jutting Brow & Glowing Slit Eyes
    head_parts = []
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    sk = bpy.context.active_object
    sk.scale = (0.30, 0.32, 0.30)
    sk.location = (0, -0.16, 1.82)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(sk, mat_skull)
    head_parts.append(sk)

    # Jutting Heavy Brow
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    br = bpy.context.active_object
    br.scale = (0.28, 0.08, 0.08)
    br.location = (0, -0.32, 1.90)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(br, mat_skull)
    head_parts.append(br)

    # Red Glowing Slit Eyes
    for x_eye in [-0.08, 0.08]:
        bpy.ops.mesh.primitive_cube_add(size=1.0)
        eye = bpy.context.active_object
        eye.scale = (0.05, 0.04, 0.025)
        eye.location = (x_eye, -0.33, 1.84)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        apply_material(eye, mat_eyes)
        head_parts.append(eye)

    join_and_pivot(head_parts, "Head", (0, -0.05, 1.65), root)

    # Heavy Club Arms & Sledgehammer Fists
    arm_l_parts = []
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    al = bpy.context.active_object
    al.scale = (0.22, 0.24, 0.85)
    al.location = (-0.68, -0.12, 1.25)
    al.rotation_euler = (math.radians(-15), math.radians(6), 0)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(al, mat_charcoal)
    arm_l_parts.append(al)

    # Massive Club Fist
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    fst_l = bpy.context.active_object
    fst_l.scale = (0.26, 0.28, 0.28)
    fst_l.location = (-0.68, -0.22, 0.82)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(fst_l, mat_charcoal)
    arm_l_parts.append(fst_l)

    join_and_pivot(arm_l_parts, "ArmLeft", (-0.68, 0.0, 1.65), root)

    arm_r_parts = []
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    ar = bpy.context.active_object
    ar.scale = (0.22, 0.24, 0.85)
    ar.location = (0.68, -0.12, 1.25)
    ar.rotation_euler = (math.radians(-15), math.radians(-6), 0)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(ar, mat_charcoal)
    arm_r_parts.append(ar)

    bpy.ops.mesh.primitive_cube_add(size=1.0)
    fst_r = bpy.context.active_object
    fst_r.scale = (0.26, 0.28, 0.28)
    fst_r.location = (0.68, -0.22, 0.82)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(fst_r, mat_charcoal)
    arm_r_parts.append(fst_r)

    join_and_pivot(arm_r_parts, "ArmRight", (0.68, 0.0, 1.65), root)

    # Massive Pillar Legs
    leg_l_parts = []
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    ll = bpy.context.active_object
    ll.scale = (0.20, 0.24, 1.05)
    ll.location = (-0.30, 0.06, 0.55)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(ll, mat_charcoal)
    leg_l_parts.append(ll)
    join_and_pivot(leg_l_parts, "LegLeft", (-0.30, 0.06, 1.08), root)

    leg_r_parts = []
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    lr = bpy.context.active_object
    lr.scale = (0.20, 0.24, 1.05)
    lr.location = (0.30, 0.06, 0.55)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(lr, mat_charcoal)
    leg_r_parts.append(lr)
    join_and_pivot(leg_r_parts, "LegRight", (0.30, 0.06, 1.08), root)

    target_path = os.path.join(out_dir, "zombie_tank.glb")
    bpy.ops.export_scene.gltf(
        filepath=target_path,
        export_format='GLB',
        use_selection=False,
        export_apply=True
    )
    print(f"Exported Zombie Tank to {target_path}")

# ==============================================================================
# 5. ASSAULT CARBINE RIFLE MODEL
# ==============================================================================
def build_assault_carbine():
    clear_scene()

    mat_receiver = create_material("Mat_GunReceiver", (0.10, 0.10, 0.12, 1.0), roughness=0.45, metallic=0.75)
    mat_barrel = create_material("Mat_GunBarrel", (0.22, 0.24, 0.26, 1.0), roughness=0.3, metallic=0.9)
    mat_accent = create_material("Mat_GunAccent", (0.85, 0.05, 0.1, 1.0), roughness=0.4, metallic=0.1)
    mat_reticle = create_material("Mat_ReflexReticle", (1.0, 0.05, 0.1, 1.0), roughness=0.1, emission=(1.0, 0.05, 0.1, 1.0), emission_energy=5.0)

    parts = []
    # Main receiver
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    rec = bpy.context.active_object
    rec.scale = (0.07, 0.45, 0.10)
    rec.location = (0, 0, 0)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(rec, mat_receiver)
    parts.append(rec)

    # Barrel extending forward (-Y in Blender)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.022, depth=0.40, vertices=12)
    bar = bpy.context.active_object
    bar.rotation_euler = (math.radians(90), 0, 0)
    bar.location = (0, -0.38, 0.01)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(bar, mat_barrel)
    parts.append(bar)

    # Flash hider muzzle
    bpy.ops.mesh.primitive_cylinder_add(radius=0.03, depth=0.07, vertices=8)
    mz = bpy.context.active_object
    mz.rotation_euler = (math.radians(90), 0, 0)
    mz.location = (0, -0.58, 0.01)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(mz, mat_barrel)
    parts.append(mz)

    # Curved 30-round magazine
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    mag = bpy.context.active_object
    mag.scale = (0.05, 0.10, 0.22)
    mag.location = (0, -0.06, -0.14)
    mag.rotation_euler = (math.radians(-14), 0, 0)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(mag, mat_receiver)
    parts.append(mag)

    # Optical reflex sight
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    opt = bpy.context.active_object
    opt.scale = (0.05, 0.12, 0.06)
    opt.location = (0, 0.04, 0.09)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(opt, mat_receiver)
    parts.append(opt)

    # Red dot reflex reticle glass
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    ret = bpy.context.active_object
    ret.scale = (0.035, 0.02, 0.04)
    ret.location = (0, 0.04, 0.095)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(ret, mat_reticle)
    parts.append(ret)

    # Tactical buttstock (+Y in Blender)
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    stk = bpy.context.active_object
    stk.scale = (0.06, 0.26, 0.11)
    stk.location = (0, 0.32, -0.02)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(stk, mat_receiver)
    parts.append(stk)

    # Pistol grip
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    grp = bpy.context.active_object
    grp.scale = (0.05, 0.08, 0.16)
    grp.location = (0, 0.12, -0.10)
    grp.rotation_euler = (math.radians(22), 0, 0)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(grp, mat_receiver)
    parts.append(grp)

    # Crimson accent strip
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    acc = bpy.context.active_object
    acc.scale = (0.072, 0.16, 0.015)
    acc.location = (0, -0.08, 0.05)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    apply_material(acc, mat_accent)
    parts.append(acc)

    rifle_obj = join_and_pivot(parts, "AssaultCarbine", (0, 0, 0))

    target_path = os.path.join(weapons_dir, "assault_carbine.glb")
    bpy.ops.export_scene.gltf(
        filepath=target_path,
        export_format='GLB',
        use_selection=False,
        export_apply=True
    )
    print(f"Exported Assault Carbine to {target_path}")

if __name__ == "__main__":
    print("=== STARTING SOLID MESH BLENDER CHARACTER & WEAPON GENERATION ===")
    build_player_model()
    build_zombie_shambler()
    build_zombie_runner()
    build_zombie_tank()
    build_assault_carbine()
    print("=== ALL 3D BLENDER ASSETS GENERATED SUCCESSFULLY ===")
