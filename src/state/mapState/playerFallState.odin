package mapstate

import "../../engine/math/mathf"
import rl "vendor:raylib"

PlayerFallingState :: struct {
    GRAVITY: f32,
    velocity: mathf.vec3
}

do_player_fall_physics :: proc(player: ^Player, state: ^PlayerFallingState) {

    if player.cam.position[1] < player.cam_offset[1] {
        player.cam.position[1] = player.cam_offset[1]

        if rl.IsKeyPressedRepeat(.C) {
            player.state = PlayerSlideState{ velocity = state.velocity }
            return
        }

        player.state = PlayerWalkState{ runModifier = 2.0 }
        return
    }

    state.velocity[2] -= state.GRAVITY * rl.GetFrameTime() * player.time_scale
    player.translation = { 0.0, 0.0, 0.0 }
    if player.time_scale > 0 do player.translation = state.velocity
}