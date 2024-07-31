package levelstate

import "../../../engine/input"
import "../../../engine/camera"
import "../../../engine/math/mathf"
import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"

import "../../../engine/physics"

import "core:fmt"

Player :: struct {
    bindMap: ^input.BindingMap,

    position: mathf.vec3,
    controller: physics.CharacterController,

    FORWARD: mathf.vec3,
    RIGHT: mathf.vec3,

    cam: camera.Camera,

    settings: PlayerSettings
}

PlayerSettings :: struct {
    view_locked: bool,
    movement_locked: bool,
    walkSpeed, lookSpeed: f32
}

construct_player :: proc(bindMap: ^input.BindingMap) -> Player {
    player : Player = {
        bindMap,
        { 0, 0, 0 },
        {},

        { 0, 0, 0 },
        { 0, 0, 0 },

        camera.DEFAULT_CAMERA,

        {
            false, false,
            10, 0.5
        }
    }

    player.controller = {
        height = 2,
        width = 0.5,
        maxSlopeAngle = 35,
        maxCollisionDist = 10,
        groundTagMask = { 2 },
        collisionTagMask = { 1 }
    }

    return player
}

update_player :: proc(player: ^Player, level: ^LevelState) {
    input.set_context(player.bindMap)

    do_player_mouse_look(player, level)
    camera.apply_rotation(&player.cam)

    do_player_movement(player, level)
    player.cam.transform.position = player.position + player.cam.viewCamera.up * (player.controller.height - 0.25)
    camera.apply_position(&player.cam)
}

debug_render_player :: proc(player: ^Player, level: ^LevelState) {
    physics.draw_char_controller(&player.controller)
    camera.draw_camera(&player.cam)
}

do_player_movement :: proc(player: ^Player, level: ^LevelState) {
    axisH := -input.get_axis_value("MOVEX")
    axisV := input.get_axis_value("MOVEY")

    moveDir: mathf.vec2 = linalg.vector_normalize0(
        mathf.vec2 {
            axisH,
            axisV
        }
    )

    player.FORWARD = linalg.vector_normalize0(linalg.matrix_mul_vector(player.cam.viewRotMatrix, mathf.vec3{ 0, 0, 1 }) * { 1, 0, 1 })
    player.RIGHT = linalg.vector_normalize0(linalg.matrix_mul_vector(player.cam.viewRotMatrix, mathf.vec3{ 1, 0, 0 }) * { 1, 0, 1 })

    wishdir := player.FORWARD * moveDir[1] + player.RIGHT * moveDir[0]
    translation := wishdir * player.settings.walkSpeed * rl.GetFrameTime()

    if player.settings.movement_locked {
        physics.do_movement_collision(translation, &player.controller, level.levelData)
        //physics.do_gravity_collision(10 * rl.GetFrameTime(), &player.controller, level.levelData)
    }
    else{
        //translation += {0, -10 * rl.GetFrameTime(), 0}
        physics.apply_velocity(translation, &player.controller, level.levelData)
    }

    physics.apply_gravity(10 * rl.GetFrameTime(), &player.controller, level.levelData)
}

do_player_mouse_look :: proc(player: ^Player, level: ^LevelState) {
    //Block all the rotation logic when player is in freeCam mode
    if player.settings.view_locked do return

    //Rotation logic stolen from https://github.com/jakubtomsu/dungeon-of-quake/blob/main/game/player.odin

    //Apply mouse Input on ViewState
    player.cam.transform.rotation[1] += -input.get_axis_value("LOOKX") * player.settings.lookSpeed * rl.GetFrameTime() * level.timeScale
    player.cam.transform.rotation[0] += input.get_axis_value("LOOKY") * player.settings.lookSpeed * rl.GetFrameTime() * level.timeScale

    player.cam.transform.rotation[0] = clamp(
        player.cam.transform.rotation[0],
        -math.PI * 0.5 * 0.95,
        math.PI * 0.5 * 0.95
    )
}