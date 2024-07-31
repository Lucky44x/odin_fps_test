package levelstate

import ui "../../../engine/ui"
import "../../../engine/input"
import levelLoading "../../../engine/level"
import "../../../engine/physics"
import "../../../engine/rendering"
import "../../../editor"
import "../../../engine/window"
import rl "vendor:raylib"

import "core:strings"
import "core:fmt"
import "core:os"
import "core:io"

@(private)
switchLevelCallback: proc(LevelState)
@(private)
allLevels: [dynamic]levelLoading.LevelData = make([dynamic]levelLoading.LevelData)
@(private)
keyBindsRef: ^input.BindingMap = nil

LevelState :: struct {
    player: Player,
    timeScale: f32,
    levelData: ^levelLoading.LevelData
}

init_state_machine :: proc(
    levelSwitch: proc(LevelState)
) {
    switchLevelCallback = levelSwitch
}

set_keymap :: proc(keymap: ^input.BindingMap) {
    keyBindsRef = keymap
}

isCurserDisabled := false
isFreeCam := false
freeCamPlayer: ^Player
currentData: ^levelLoading.LevelData

do_level_update :: proc(state: ^LevelState) {
    physics.update_level_objects(state.levelData)

    if input.is_bind_pressed("ESCAPE") {
        if isCurserDisabled {
            rl.DisableCursor()
            state.timeScale = 1.0
            isCurserDisabled = false
        }
        else {
            rl.EnableCursor()
            state.timeScale = 0.0
            isCurserDisabled = true
        }
    }

    when ODIN_DEBUG {
        if input.is_bind_pressed("DEBUG") do editor.toggle_editor()
        editor.update_editors(state.levelData, isFreeCam ? &devCam : &state.player.cam)
    
        do_freecam_update(state)
    }
}

do_level_render :: proc(state: ^LevelState) {
    when ODIN_DEBUG do editor.draw_editor(state.levelData)

    if isFreeCam {
        rl.BeginMode3D(devCam.viewCamera) 
    }
    else do rl.BeginMode3D(state.player.cam.viewCamera) 

    material := rl.LoadMaterialDefault()

    levelLoading.DrawSkybox(&state.levelData.skybox)

    
    for obj in state.levelData.levelObjects {
        if obj.objectMesh == -1 do continue

        rl.DrawMesh(state.levelData.levelMeshes[obj.objectMesh].mesh, state.levelData.levelMaterials[obj.objectMaterial].material, obj.objectTransform.transformMatrix)
    }
    
    //levelLoading.render_instanced_objects(state.levelData)

    update_player(&state.player, state)

    if isFreeCam do debug_render_player(&state.player, state)

    rendering.render_3D_futures()
    editor.draw_gizmos(state.levelData)
    rl.EndMode3D()

    rendering.render_2D_futures()
}

init_level :: proc(level: ^LevelState) {
    spawnTags := levelLoading.get_objects_by_tag({ 0 }, level.levelData)
    if len(spawnTags) > 0 do level.player.position = spawnTags[0].objectTransform.position

    physics.link_controller(&level.player.position, &level.player.FORWARD, &level.player.RIGHT, &level.player.controller)

    //skybox clear color
    #partial switch type in level.levelData.skybox { case rl.Color: window.set_clearColor(type) }

    //Custom Editor
    when ODIN_DEBUG {
        freeCamPlayer = &level.player
        currentData = level.levelData
        
        editor.add_custom_editor(editor.CustomEditor{
            name = "Freecam",
            constructor = proc(data: ^levelLoading.LevelData) { do_freecam_imgui(freeCamPlayer) }
        })
        editor.add_custom_editor(editor.CustomEditor{
            name = "Player",
            constructor = proc(data: ^levelLoading.LevelData) { do_player_imgui(freeCamPlayer, currentData) }
        })
    }
}

load_level :: proc(levelIndex: int, keyBinds: ^input.BindingMap) -> LevelState {
    rl.DisableCursor()

    return {
        construct_player(keyBinds),
        1.0,
        &allLevels[levelIndex]
    }
}

generate_levels :: proc(levelDir: string) -> []ui.Field {
    buttons: [dynamic]ui.Field = make([dynamic]ui.Field)

    isValid := true
    index := 0
    for isValid {
        mapDir := fmt.aprintf("%s/%v", levelDir, index)
        levelDat, err := levelLoading.load_level_from_disk(mapDir)

        if err != nil do break
        append(&allLevels, levelDat)
        buttonData := make([]int, 1)
        buttonData[0] = index

        newButton := ui.Button{
            text = strings.clone_to_cstring(levelDat.levelName),
            extras = buttonData,
        }

        newButton.func = proc(levelUI: ^ui.LevelUI, button: ^ui.Button) {
            switchLevelCallback(load_level(button.extras[0], keyBindsRef))
        }

        append(&buttons, newButton)
        
        newHint := ui.Hint{
            text = strings.clone_to_cstring(mapDir)
        }
        append(&buttons, newHint)

        index += 1
    }

    backButton := ui.Button{
        text = "< Back",
        leftPress = true,
        func = proc(lui: ^ui.LevelUI, butt: ^ui.Button) {
            lui.selectedui = 0
        }
    }

    append(&buttons, backButton)

    return buttons[:]
}