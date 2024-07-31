package mapstate

import "../../engine/math/mathf"
import alg "core:math/linalg"
import rl "vendor:raylib"

import "core:fmt"

PlayerNoclipState :: struct {
    speed: f32
}

do_player_noclip_physics :: proc(player: ^Player, state: ^PlayerNoclipState) {
    //Do state Switches
    if !player.noclip {
        player.state = PlayerFallingState{ GRAVITY = 0.751 }
        player.isnoclip = false
        return
    }

    walkDir: mathf.vec3 = { 0, 0, 0 }

    if rl.IsKeyDown(.W) do walkDir[0] = 1.0
    else if rl.IsKeyDown(.S) do walkDir[0] = -1.0

    if rl.IsKeyDown(.A) do walkDir[1] = -1.0
    else if rl.IsKeyDown(.D) do walkDir[1] = 1.0

    if rl.IsKeyDown(.E) do walkDir[2] = 1.0
    else if rl.IsKeyDown(.Q) do walkDir[2] = -1.0

    walkDir = alg.normalize0(walkDir)

    mouseWheelDelt := rl.GetMouseWheelMove()
    state.speed += mouseWheelDelt

    player.translation = walkDir * player.movementSpeed * rl.GetFrameTime() * state.speed
}