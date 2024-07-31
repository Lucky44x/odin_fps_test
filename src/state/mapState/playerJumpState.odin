package mapstate

import "../../engine/math/mathf"

PlayerJumpState :: struct {
    jumpImpulse: f32,
    jumpDropoff: f32,
    fallThreshold: f32,
    velocity: mathf.vec3,
    inAir: bool
}

do_player_jump_physics :: proc(player: ^Player, state: ^PlayerJumpState) {
    if !state.inAir {
        if player.time_scale == 0 do return

        state.velocity[2] = state.jumpImpulse
        player.translation = state.velocity * player.time_scale
        state.inAir = true
        return
    }

    if state.velocity[2] <= state.fallThreshold {
        state.velocity[2] = 0
        player.state = PlayerFallingState{ GRAVITY = 0.5, velocity = state.velocity }
        return
    }

    state.velocity[2] *= state.jumpDropoff
    player.translation = state.velocity * player.time_scale
}