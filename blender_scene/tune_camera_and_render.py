import bpy
import math
from mathutils import Vector, Euler

def tune():
    scene = bpy.context.scene
    cam_obj = bpy.data.objects.get("Diorama_Camera")
    cam = cam_obj.data
    
    # Switch to Orthographic Isometric Camera
    cam.type = 'ORTHO'
    cam.ortho_scale = 22.0
    cam.clip_start = 0.1
    cam.clip_end = 250.0
    
    # Position camera diagonally looking down at ~45-50 degrees
    # Looking from South-West to North-East
    cam_obj.location = (-28.0, -30.0, 30.0)
    
    look_target = bpy.data.objects.get("Camera_Target")
    if not look_target:
        look_target = bpy.data.objects.new("Camera_Target", None)
        scene.collection.objects.link(look_target)
    look_target.location = (0.2, 3.2, 3.8)
    
    # Sun Light Direction
    sun_obj = bpy.data.objects.get("Sun_KeyLight")
    if sun_obj:
        # Shine from upper-right toward lower-left
        sun_dir = Vector((-0.65, -0.45, -0.72)).normalized()
        rot_quat = Vector((0, 0, -1)).rotation_difference(sun_dir)
        sun_obj.rotation_euler = rot_quat.to_euler()
        sun_obj.data.energy = 5.2
        sun_obj.data.angle = math.radians(1.5)
        
    # Quick preview render with 64 samples
    scene.cycles.samples = 64
    scene.cycles.preview_samples = 32
    scene.cycles.use_denoising = True
    scene.cycles.denoiser = 'OPTIX'
    
    render_path = "d:/Godot_Devs/Zombie_shooter/blender_scene/preview_render.png"
    scene.render.filepath = render_path
    print(f"Rendering preview to: {render_path} ...")
    bpy.ops.render.render(write_still=True)
    print("Preview render saved successfully.")
    
    # Save the updated blend file
    bpy.ops.wm.save_as_mainfile(filepath="d:/Godot_Devs/Zombie_shooter/blender_scene/urban_alleyway_layout.blend")
    print("Blend file updated.")

if __name__ == "__main__":
    tune()
