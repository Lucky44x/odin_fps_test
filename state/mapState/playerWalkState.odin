package mapstate

import "../../engine/math/mathf"
import alg "core:math/linalg"
import rl "vendor:raylib"

import "core:fmt"

PlayerWalkState :: struct {
    runModifier: f32,
    isRunning: bool
}

do_player_walk_physics :: proc(player: ^Player, state: ^PlayerWalkState) {
    //Do state Switches
    if player.cam.position[1] > player.cam_offset[1] {
        player.state = PlayerFallingState{ GRAVITY = 0.5 }
        return
    }

    if rl.IsKeyPressed(.SPACE) {
        player.state = PlayerJumpState{ jumpImpulse = 0.1, jumpDropoff = 0.98, fallThreshold = 0.05, velocity = player.translation }
        return
    }

    walkDir: mathf.vec3 = { 0, 0, 0 }

    if rl.IsKeyDown(.W) do walkDir[0] = 1.0
    else if rl.IsKeyDown(.S) do walkDir[0] = -1.0

    if rl.IsKeyDown(.A) do walkDir[1] = -1.0
    else if rl.IsKeyDown(.D) do walkDir[1] = 1.0

    if rl.IsKeyDown(.LEFT_SHIFT) do state.isRunning = true
    else do state.isRunning = false

    walkDir = alg.normalize0(walkDir)
    if state.isRunning do walkDir *= state.runModifier

    player.translation = walkDir * player.movementSpeed * rl.GetFrameTime() * player.time_scale

    if rl.IsKeyDown(.C) {
        player.state = PlayerSlideState{ velocity = player.translation, speedBleed = 0.99 }
    }
}