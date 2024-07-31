package levelstate

import rl "vendor:raylib"
import im "../../../engine/external/imgui"
import "core:fmt"
import "../../../engine/transform"
import "../../../engine/camera"
import "../../../editor"
import "../../../engine/level"

do_player_imgui :: proc(player: ^Player, scenery: ^level.LevelData) {
    im.InputFloat3("Player-Position", &player.position)
    editor.imgui_camera_inspector(&player.cam)
    if im.CollapsingHeader("Character Controller") do editor.character_controller_editor(&player.controller, scenery)
    if im.CollapsingHeader("Player-Settings") do do_player_settings_imgui(&player.settings)
}

do_player_settings_imgui :: proc(playerSettings: ^PlayerSettings) {
    im.InputFloat("Walk Speed", &playerSettings.walkSpeed)
    im.InputFloat("Look Speed", &playerSettings.lookSpeed)
    im.Checkbox("movelock", &playerSettings.movement_locked)
    im.SameLine()
    im.Checkbox("looklock", &playerSettings.view_locked)
}