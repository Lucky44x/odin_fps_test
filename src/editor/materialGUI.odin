package editor

import "../engine/level"
import im "../engine/external/imgui"
import "../engine/rendering"

import rl "vendor:raylib"
import "core:fmt"

@(private)
material_MaterialSelectedIndex := -1
@(private="file")
material_SelectedMesh := -1

@(private="file")
material_ViewportRotationEnabled := false
@(private="file")
material_ViewportRenderTexture: rl.RenderTexture2D
@(private="file")
material_ViewportCamera: rl.Camera3D = {
    { 5, 5, 5 },
    { 0, 0, 0 },
    { 0, 1, 0 },
    60,
    rl.CameraProjection.PERSPECTIVE
}

@(private="file")
zeroMatrix: rl.Matrix

init_material_editor_gui :: proc() {
    material_ViewportRenderTexture = rl.LoadRenderTexture(1024, 1024)

    zeroMatrix = rl.MatrixTranslate(0, 0, 0)
    zeroMatrix *= rl.MatrixRotateXYZ({ 0, 0 ,0 })
    zeroMatrix *= rl.MatrixScale(1, 1, 1)
}

select_material_and_mesh :: proc(material, mesh: int, levelData: ^level.LevelData) {
    material_SelectedMesh = mesh

    select_material(material, levelData)
}

select_material :: proc(selectedMaterial: int, levelData: ^level.LevelData) {
    if selectedMaterial == -1 do return
    materialsWindowOpen = true

    material_MaterialSelectedIndex = selectedMaterial
}

draw_material_editor_gui :: proc(levelData: ^level.LevelData) {
    im.Begin("Level-Materials", &materialsWindowOpen)
    levelCName := fmt.caprintf("%s", levelData.levelName)
    im.SeparatorText(levelCName)

    im.BeginChild("Materials", { im.GetContentRegionAvail()[0] / 3, im.GetContentRegionAvail()[1] }, {}, { im.WindowFlag.HorizontalScrollbar })
    for materialInd := 0; materialInd < len(levelData.levelMaterials); materialInd += 1 {
        mat := &levelData.levelMaterials[materialInd]
        
        materialCname := fmt.caprintf("%v", mat.name)
        if im.Selectable(materialCname, material_MaterialSelectedIndex == materialInd) do select_material(materialInd, levelData)

        delete(materialCname)
    }
    im.EndChild()

    im.SameLine()
    im.BeginChild("Selected Mesh", { im.GetContentRegionAvail()[0], im.GetContentRegionAvail()[1] }, {}, {})

    vertSource := material_MaterialSelectedIndex == -1 ? "NAN" : levelData.levelMaterials[material_MaterialSelectedIndex].vertSource
    fragSource := material_MaterialSelectedIndex == -1 ? "NAN" : levelData.levelMaterials[material_MaterialSelectedIndex].fragSource
    im.Text("Fragment: %s", fragSource)
    im.Text("Vertex: %s", vertSource)
    im.Spacing()

    //Viewport stuff
    comboPrev := material_SelectedMesh == -1 ? "NAN" : fmt.caprintf("%s", levelData.levelMeshes[material_SelectedMesh].name)
    if im.BeginCombo("##MESH", comboPrev) {
        
        for &mesh, ind in levelData.levelMeshes {
            meshCName := fmt.caprintf("%s", mesh.name)
            if im.Selectable(meshCName, material_SelectedMesh == ind) do material_SelectedMesh = ind
            delete(meshCName)
        }
        
        im.EndCombo()
    }
    if material_SelectedMesh != -1 do delete(comboPrev)

    im.SameLine()
    im.Checkbox("Rotation", &material_ViewportRotationEnabled)

    draw_material_viewport(levelData)

    size := im.GetContentRegionAvail()
    minSize := min(size[0], size[1])
    im.Image(&material_ViewportRenderTexture.texture.id, { minSize, minSize }, { 0, 1 }, { 1, 0 })

    im.EndChild()

    check_cursor_inside_imgui_window()
    im.End()
    delete(levelCName)
}

@(private="file")
draw_material_viewport :: proc(levelData: ^level.LevelData) {
    rl.BeginTextureMode(material_ViewportRenderTexture)
    rl.ClearBackground(rl.DARKGRAY)

    if material_MaterialSelectedIndex != -1 && material_SelectedMesh != -1 {

        rl.BeginMode3D(material_ViewportCamera)

        rl.DrawMesh(levelData.levelMeshes[material_SelectedMesh].mesh, levelData.levelMaterials[material_MaterialSelectedIndex].material, zeroMatrix)

        rl.EndMode3D()
    }
    else{
        if material_SelectedMesh == -1 do rl.DrawText("SELECT\n\n\n\n\nMESH", 25, 25, 50, rl.GRAY)
        else do rl.DrawText("EMTPY", 25, 25, 50, rl.GRAY)
    }

    rl.EndTextureMode()
}

update_material_viewport :: proc() {
    if material_ViewportRotationEnabled do rl.UpdateCamera(&material_ViewportCamera, rl.CameraMode.ORBITAL)
}