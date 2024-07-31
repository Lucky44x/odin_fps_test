package levelstate

import "../../../engine/camera"
import "../../../engine/external/imgui"
import "../../../engine/input"

import "../../../engine/math/mathf"

import "core:math/linalg"
import "core:math"
import rl "vendor:raylib"

@(private)
devCam: camera.Camera

@(private)
freecamMoveLocked: bool
@(private)
freecamViewLocked: bool

@(private)
rightMouseLook: bool = true

toggle_freecam :: proc(player: ^Player) {
    if isFreeCam {
        isFreeCam = false
        player.settings.movement_locked = false
        player.settings.view_locked = false
    }
    else{
        isFreeCam = true
        player.settings.movement_locked = true
        player.settings.view_locked = true
        devCam = player.cam
    }
}

do_freecam_update :: proc(state: ^LevelState) {
    if !isFreeCam do return

    if rightMouseLook {
        if rl.IsMouseButtonPressed(rl.MouseButton.RIGHT) {
            freecamMoveLocked = false
            freecamViewLocked = false
            isCurserDisabled = false
            rl.DisableCursor()
        }

        if rl.IsMouseButtonReleased(rl.MouseButton.RIGHT) {
            freecamMoveLocked = true
            freecamViewLocked = true
            isCurserDisabled = false
            rl.EnableCursor()
        }
    }

    freecam_rotation(state)
    freecam_movement(state)
}

freecam_movement :: proc(state: ^LevelState) {
    if !state.player.settings.movement_locked || isCurserDisabled || freecamMoveLocked do return

    axisH := -input.get_axis_value("MOVEX")
    axisV := input.get_axis_value("MOVEY")

    moveDir: mathf.vec2 = linalg.vector_normalize0(
        mathf.vec2 {
            axisH,
            axisV
        }
    )

    wishdir := devCam.transform.FORWARD * moveDir[1] + devCam.transform.RIGHT * moveDir[0]
    translation := wishdir * state.player.settings.walkSpeed * rl.GetFrameTime()

    devCam.transform.position += translation
    camera.apply_position(&devCam)
}

freecam_rotation :: proc(state: ^LevelState) {
    if !state.player.settings.view_locked || isCurserDisabled || freecamViewLocked do return
    //Rotation logic stolen from https://github.com/jakubtomsu/dungeon-of-quake/blob/main/game/state.player.odin

    //Apply mouse Input on ViewState
    devCam.transform.rotation[1] += -input.get_axis_value("LOOKX") * state.player.settings.lookSpeed * rl.GetFrameTime()
    devCam.transform.rotation[0] += input.get_axis_value("LOOKY") * state.player.settings.lookSpeed * rl.GetFrameTime()

    state.player.cam.transform.rotation[0] = clamp(
        state.player.cam.transform.rotation[0],
        -math.PI * 0.5 * 0.95,
        math.PI * 0.5 * 0.95
    )

    camera.apply_rotation(&devCam)
}