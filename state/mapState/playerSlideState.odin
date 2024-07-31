package mapstate

import "../../engine/math/mathf"
import "core:math/linalg"
import rl "vendor:raylib"

import "core:fmt"

PlayerSlideState :: struct {
    velocity: mathf.vec3,
    speedBleed: f32,
}

do_player_slide_physics :: proc(player: ^Player, state: ^PlayerSlideState) {
    player.cam_offset = { 0, 1, 0 }
    player.cam.position[1] = player.cam_offset[1]

    player.translation = state.velocity
    if player.time_scale == 0 {
        player.translation = { 0, 0, 0 }
        return
    }
    
    state.velocity *= state.speedBleed * player.time_scale

    if state.velocity[0] <= 0.001 do state.velocity[0] = 0
    if state.velocity[1] <= 0.001 do state.velocity[1] = 0
    if state.velocity[2] <= 0.001 do state.velocity[2] = 0

    //Switch to fallstate if slide velocity is smaller or equals zero    
    if linalg.vector_length(state.velocity) <= 0.005 {
        player.state = PlayerFallingState{ GRAVITY = 0.5 }
        player.cam_offset = { 0, 2, 0 }
        return
    }

    //fmt.println(linalg.vector_length(state.velocity))

    if !rl.IsKeyDown(.C) {
        player.state = PlayerFallingState{ GRAVITY = 0.5 }
        player.cam_offset = { 0, 2, 0 }
    }
}