package editor

import "../engine/level"
import im "../engine/external/imgui"
import "../engine/rendering"

import rl "vendor:raylib"
import "core:fmt"

@(private)
mesh_MeshSelectedIndex := -1
@(private="file")
mesh_SelectedModel: rl.Model

@(private="file")
mesh_ViewportRenderWireframe := false
@(private="file")
mesh_ViewportRotationEnabled := false
@(private="file")
mesh_ViewportTint: [3]f32 = { 1, 1, 1 }
@(private="file")
mesh_ViewportRenderTexture: rl.RenderTexture2D
@(private="file")
mesh_ViewportCamera: rl.Camera3D = {
    { 5, 5, 5 },
    { 0, 0, 0 },
    { 0, 1, 0 },
    60,
    rl.CameraProjection.PERSPECTIVE
}

init_mesh_editor_gui :: proc() {
    mesh_ViewportRenderTexture = rl.LoadRenderTexture(256, 256)
}

select_mesh :: proc(selectedMesh: int, levelData: ^level.LevelData) {
    if selectedMesh == -1 do return
    meshWindowOpen = true

    mesh_MeshSelectedIndex = selectedMesh
    mesh_SelectedModel = rl.LoadModelFromMesh(levelData.levelMeshes[selectedMesh].mesh)
}

draw_mesh_editor_gui :: proc(levelData: ^level.LevelData) {
    im.Begin("Level-Meshes", &meshWindowOpen)
    levelCName := fmt.caprintf("%s", levelData.levelName)
    im.SeparatorText(levelCName)

    im.BeginChild("Meshes", { im.GetContentRegionAvail()[0] / 3, im.GetContentRegionAvail()[1] }, {}, { im.WindowFlag.HorizontalScrollbar })
    for meshInd := 0; meshInd < len(levelData.levelMeshes); meshInd += 1 {
        mesh := &levelData.levelMeshes[meshInd]
        
        meshCname := fmt.caprintf("%v", mesh.name)
        if im.Selectable(meshCname, mesh_MeshSelectedIndex == meshInd) do select_mesh(meshInd, levelData)

        delete(meshCname)
    }
    im.EndChild()
    im.SameLine()
    im.BeginChild("Selected Mesh", { im.GetContentRegionAvail()[0], im.GetContentRegionAvail()[1] }, {}, {})

    name := mesh_MeshSelectedIndex == -1 ? "NAN" : levelData.levelMeshes[mesh_MeshSelectedIndex].source
    im.Text("Source: %s", name)
    //Viewport stuf
    im.ColorEdit3("MeshColor", &mesh_ViewportTint, { im.ColorEditFlag.NoInputs, im.ColorEditFlag.NoLabel })
    im.SameLine()
    im.Checkbox("Wireframe", &mesh_ViewportRenderWireframe)
    im.SameLine()
    im.Checkbox("Rotation", &mesh_ViewportRotationEnabled)

    draw_mesh_viewport()

    size := im.GetContentRegionAvail()
    minSize := min(size[0], size[1])
    im.Image(&mesh_ViewportRenderTexture.texture.id, { minSize, minSize }, { 0, 1 }, { 1, 0 })

    im.EndChild()

    check_cursor_inside_imgui_window()
    im.End()
    delete(levelCName)
}

@(private="file")
draw_mesh_viewport :: proc() {
    rl.BeginTextureMode(mesh_ViewportRenderTexture)
    rl.ClearBackground(rl.DARKGRAY)

    if mesh_MeshSelectedIndex != -1 {

        rl.BeginMode3D(mesh_ViewportCamera)

        col: rl.Color = {
            u8(255 * mesh_ViewportTint[0]),
            u8(255 * mesh_ViewportTint[1]),
            u8(255 * mesh_ViewportTint[2]),
            255
        }

        if mesh_ViewportRenderWireframe do rl.DrawModelWires(mesh_SelectedModel, { 0, 0, 0 }, 1, col)
        else do rl.DrawModel(mesh_SelectedModel, { 0, 0, 0 }, 1, col)
        
        rl.EndMode3D()
    }
    else{
        rl.DrawText("EMTPY", 25, 25, 50, rl.GRAY)
    }

    rl.EndTextureMode()
}

update_mesh_viewport :: proc() {
    if mesh_ViewportRotationEnabled do rl.UpdateCamera(&mesh_ViewportCamera, rl.CameraMode.ORBITAL)
}