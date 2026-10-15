"""
generate_models.py
Generates pickup_datacube_crystal.glb and weapon_shuriken_razor.glb
using Blender's procedural geometry and GLTF exporter.
"""

import bpy
import bmesh
import math
from mathutils import Vector, Matrix, Euler

def clean_scene():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    for block in bpy.data.meshes:
        if block.users == 0:
            bpy.data.meshes.remove(block)
    for block in bpy.data.materials:
        if block.users == 0:
            bpy.data.materials.remove(block)

def create_emissive_material(name, base_color, emissive_color, emissive_strength=10.0, metallic=0.8, roughness=0.2):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = base_color
        bsdf.inputs["Metallic"].default_value = metallic
        bsdf.inputs["Roughness"].default_value = roughness
        bsdf.inputs["Emission Color"].default_value = emissive_color
        bsdf.inputs["Emission Strength"].default_value = emissive_strength
    return mat

def create_metal_material(name, base_color, metallic=0.9, roughness=0.25):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = base_color
        bsdf.inputs["Metallic"].default_value = metallic
        bsdf.inputs["Roughness"].default_value = roughness
    return mat

def build_datacube_crystal(export_path):
    clean_scene()
    
    # Materials
    mat_emerald_glow = create_emissive_material("EmeraldNeon", (0.05, 0.4, 0.15, 1.0), (0.0, 1.0, 0.45, 1.0), emissive_strength=12.0)
    mat_dark_crystal = create_metal_material("DarkCrystalCore", (0.02, 0.08, 0.04, 1.0), metallic=0.95, roughness=0.1)
    mat_ring_gold = create_emissive_material("RingHolo", (0.1, 0.5, 0.25, 1.0), (0.1, 1.0, 0.5, 1.0), emissive_strength=8.0)
    
    # 1. Outer Faceted Octahedron Crystal
    mesh = bpy.data.meshes.new("CrystalOuterMesh")
    bm = bmesh.new()
    
    # Octahedron vertices (scaled taller vertically for an elegant gem silhouette)
    # top, bottom, 4 equatorial points
    r = 0.28
    h = 0.44
    v_top = bm.verts.new((0, 0, h))
    v_bottom = bm.verts.new((0, 0, -h))
    v_px = bm.verts.new((r, 0, 0))
    v_py = bm.verts.new((0, r, 0))
    v_nx = bm.verts.new((-r, 0, 0))
    v_ny = bm.verts.new((0, -r, 0))
    
    # 8 faces
    bm.faces.new((v_top, v_px, v_py))
    bm.faces.new((v_top, v_py, v_nx))
    bm.faces.new((v_top, v_nx, v_ny))
    bm.faces.new((v_top, v_ny, v_px))
    bm.faces.new((v_bottom, v_py, v_px))
    bm.faces.new((v_bottom, v_nx, v_py))
    bm.faces.new((v_bottom, v_ny, v_nx))
    bm.faces.new((v_bottom, v_px, v_ny))
    
    bm.to_mesh(mesh)
    bm.free()
    
    obj_crystal = bpy.data.objects.new("CrystalOuter", mesh)
    bpy.context.collection.objects.link(obj_crystal)
    obj_crystal.data.materials.append(mat_emerald_glow)
    
    # 2. Inner dense refraction core
    mesh_inner = bpy.data.meshes.new("CrystalInnerMesh")
    bm_in = bmesh.new()
    ri = 0.18
    hi = 0.28
    vi_top = bm_in.verts.new((0, 0, hi))
    vi_bottom = bm_in.verts.new((0, 0, -hi))
    vi_px = bm_in.verts.new((ri, 0, 0))
    vi_py = bm_in.verts.new((0, ri, 0))
    vi_nx = bm_in.verts.new((-ri, 0, 0))
    vi_ny = bm_in.verts.new((0, -ri, 0))
    bm_in.faces.new((vi_top, vi_px, vi_py))
    bm_in.faces.new((vi_top, vi_py, vi_nx))
    bm_in.faces.new((vi_top, vi_nx, vi_ny))
    bm_in.faces.new((vi_top, vi_ny, vi_px))
    bm_in.faces.new((vi_bottom, vi_py, vi_px))
    bm_in.faces.new((vi_bottom, vi_nx, vi_py))
    bm_in.faces.new((vi_bottom, vi_ny, vi_nx))
    bm_in.faces.new((vi_bottom, vi_px, vi_ny))
    bm_in.to_mesh(mesh_inner)
    bm_in.free()
    
    obj_inner = bpy.data.objects.new("CrystalInner", mesh_inner)
    bpy.context.collection.objects.link(obj_inner)
    obj_inner.data.materials.append(mat_dark_crystal)
    obj_inner.parent = obj_crystal
    
    # 3. Holographic Orbital Gyro Ring (tilted around crystal)
    bpy.ops.mesh.primitive_torus_add(
        align='WORLD',
        location=(0, 0, 0),
        rotation=(math.radians(25), math.radians(15), 0),
        major_radius=0.38,
        minor_radius=0.018,
        major_segments=32,
        minor_segments=8
    )
    obj_ring = bpy.context.active_object
    obj_ring.name = "OrbitRing"
    obj_ring.data.materials.append(mat_ring_gold)
    
    # Export GLB
    bpy.ops.export_scene.gltf(
        filepath=export_path,
        export_format='GLB',
        use_selection=False,
        export_apply=True
    )
    print(f"Exported Datacube Crystal to {export_path}")

def build_shuriken_razor(export_path):
    clean_scene()
    
    mat_cyan_glow = create_emissive_material("CyanNeon", (0.0, 0.3, 0.4, 1.0), (0.0, 1.0, 1.0, 1.0), emissive_strength=14.0)
    mat_dark_steel = create_metal_material("CyberSteel", (0.05, 0.06, 0.08, 1.0), metallic=0.95, roughness=0.15)
    
    # Center Hub (Cylinder with beveled rim)
    bpy.ops.mesh.primitive_cylinder_add(
        radius=0.14,
        depth=0.08,
        vertices=16,
        location=(0, 0, 0)
    )
    obj_hub = bpy.context.active_object
    obj_hub.name = "CenterHub"
    obj_hub.data.materials.append(mat_dark_steel)
    
    # Central glowing power core
    bpy.ops.mesh.primitive_cylinder_add(
        radius=0.06,
        depth=0.09,
        vertices=16,
        location=(0, 0, 0)
    )
    obj_core = bpy.context.active_object
    obj_core.name = "CoreLight"
    obj_core.data.materials.append(mat_cyan_glow)
    
    # 4 Curved Razor Blades
    blades = []
    for i in range(4):
        angle = i * (math.pi / 2.0)
        
        bm = bmesh.new()
        # Create blade points
        # Base attaches to hub, tip curves outward
        p0 = Vector((0.08, -0.05, 0.0))    # Root trailing
        p1 = Vector((0.13, 0.05, 0.0))     # Root leading
        p2 = Vector((0.35, 0.12, 0.0))     # Mid leading curve
        p3 = Vector((0.55, 0.02, 0.0))     # Sharp Tip
        p4 = Vector((0.28, -0.03, 0.0))    # Inner trailing edge
        
        # 3D thickness (t = 0.025 at spine, 0.002 at razor edges)
        # We create upper and lower faces
        verts_top = []
        verts_bot = []
        for p, z in [(p0, 0.02), (p1, 0.005), (p2, 0.003), (p3, 0.001), (p4, 0.015)]:
            # Rotate by angle
            rot_mat = Matrix.Rotation(angle, 4, 'Z')
            pos_t = rot_mat @ Vector((p.x, p.y, z))
            pos_b = rot_mat @ Vector((p.x, p.y, -z))
            verts_top.append(bm.verts.new(pos_t))
            verts_bot.append(bm.verts.new(pos_b))
        
        # Top faces
        bm.faces.new((verts_top[0], verts_top[1], verts_top[2], verts_top[4]))
        bm.faces.new((verts_top[4], verts_top[2], verts_top[3]))
        # Bottom faces
        bm.faces.new((verts_bot[4], verts_bot[2], verts_bot[1], verts_bot[0]))
        bm.faces.new((verts_bot[3], verts_bot[2], verts_bot[4]))
        # Side/cutting edge faces
        for j in range(5):
            nxt = (j + 1) % 5
            bm.faces.new((verts_top[j], verts_top[nxt], verts_bot[nxt], verts_bot[j]))
        
        mesh_blade = bpy.data.meshes.new(f"BladeMesh_{i}")
        bm.to_mesh(mesh_blade)
        bm.free()
        
        obj_blade = bpy.data.objects.new(f"Blade_{i}", mesh_blade)
        bpy.context.collection.objects.link(obj_blade)
        obj_blade.data.materials.append(mat_cyan_glow)
        blades.append(obj_blade)
        
    # Join into single unified shuriken object
    bpy.ops.object.select_all(action='DESELECT')
    obj_hub.select_set(True)
    obj_core.select_set(True)
    for b in blades:
        b.select_set(True)
    bpy.context.view_layer.objects.active = obj_hub
    bpy.ops.object.join()
    obj_hub.name = "WeaponShurikenRazor"
    
    # Export GLB
    bpy.ops.export_scene.gltf(
        filepath=export_path,
        export_format='GLB',
        use_selection=False,
        export_apply=True
    )
    print(f"Exported Razor Shuriken to {export_path}")

if __name__ == "__main__":
    import sys
    models_dir = "/Users/leonid/src/ninja-survivor/assets/models"
    build_datacube_crystal(f"{models_dir}/pickup_datacube_crystal.glb")
    build_shuriken_razor(f"{models_dir}/weapon_shuriken_razor.glb")
