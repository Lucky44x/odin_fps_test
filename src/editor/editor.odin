package editor

import "../engine/camera"
import im "../engine/external/imgui"
import "../engine/input"
import "../engine/level"
import "../engine/math/mathf"
import "../engine/rendering"
import cam "../engine/camera"

import "core:math/linalg"
import "core:math"
import rl "vendor:raylib"
import "core:fmt"
import "core:strings"

CustomEditor :: struct {
    name: cstring,
    updater: proc(^level.LevelData),
    constructor: proc(^level.LevelData),
    open: bool
}

@(private="file")
IsEditorOpen := false

@(private)
CustomEditors: [dynamic]CustomEditor

@(private)
IsAnyWindowHovered: bool = false

@(private)
meshWindowOpen := false
@(private)
sceneWindowOpen := false
@(private)
texturesWindowOpen := false
@(private)
materialsWindowOpen := false

@(private)
arrowModels: [3]rl.Model
@(private)
arrowMesh: rl.Mesh
@(private)
axisColors : [3]rl.Color = { rl.RED, rl.GREEN, rl.BLUE }

toggle_editor :: proc() { IsEditorOpen = !IsEditorOpen }

draw_editor :: proc(levelData: ^level.LevelData) {
    when !ODIN_DEBUG do return
    if !IsEditorOpen do return

    for &editor in CustomEditors {
        if !editor.open do continue

        im.Begin(editor.name, &editor.open)
        editor.constructor(levelData)

        check_cursor_inside_imgui_window()
        im.End()
    }

    draw_main_menu_bar(levelData)

    if meshWindowOpen do draw_mesh_editor_gui(levelData)
    if sceneWindowOpen do draw_scenery_editor_gui(levelData)
    if texturesWindowOpen do draw_texture_editor_gui(levelData)
    if materialsWindowOpen do draw_material_editor_gui(levelData)
}

draw_gizmos :: proc(levelData: ^level.LevelData) {
    when !ODIN_DEBUG do return
    if !IsEditorOpen do return

    draw_scenery_gizmos(levelData)
}

update_editors :: proc(levelData: ^level.LevelData, camera: ^cam.Camera) {
    when !ODIN_DEBUG do return

    update_scenery_editor(levelData, camera)
    update_mesh_viewport()
    update_material_viewport()

    for editor in CustomEditors {
        if editor.updater == nil do continue
        editor.updater(levelData)
    }

    IsAnyWindowHovered = false
}

add_custom_editor :: proc(editor: CustomEditor) {
    append(&CustomEditors, editor)
}

init_editor :: proc() {
    when !ODIN_DEBUG do return
    
    arrowMesh = rl.GenMeshCylinder(0.05, 2, 8)
    CustomEditors = make([dynamic]CustomEditor)

    init_mesh_editor_gui()
    init_material_editor_gui()
}

destroy_editor :: proc() {
    when !ODIN_DEBUG do return

    delete(CustomEditors)
}

check_cursor_inside_imgui_window :: proc() {
    windowPos := im.GetWindowPos()
    windowSize := im.GetWindowSize()
    mousePos := rl.GetMousePosition()

    if mousePos[0] < windowPos[0] || mousePos[0] > windowPos[0] + windowSize[0] do return
    if mousePos[1] < windowPos[1] || mousePos[1] > windowPos[1] + windowSize[1] do return

    IsAnyWindowHovered = true
}

tag_mask_gui :: proc(mask: ^level.TagMask, scenery: ^level.LevelData, name : cstring = "tags") {
    popupID := fmt.caprintf("%s-tag-popup", name)

    if im.Button(name) do im.OpenPopup(popupID)
    if im.BeginPopup(popupID) {
        for i := 0; i < scenery.usedTags; i += 1 {
            enabled := i32(i) in mask
            tagCName := fmt.caprintf("%s", scenery.levelTags[i])

            im.MenuItemBoolPtr(tagCName, "", &enabled)
            delete(tagCName)

            if enabled != i32(i) in mask {
                if i32(i) in mask && !enabled do mask ^= mask^ - level.TagMask{ i32(i) }
                else if i32(i) not_in mask && enabled do mask ^= mask^ + level.TagMask{ i32(i) }
            }
        }
        im.EndPopup()
    }
    delete(popupID)
}