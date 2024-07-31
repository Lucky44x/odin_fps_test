package mapstate

import im "../../engine/external/imgui"
import rl "vendor:raylib"
import "core:fmt"

import "../../engine/math/mathf"

PlayerState :: union {
    PlayerWalkState,
    PlayerFallingState,
    PlayerJumpState,
    PlayerSlideState,
    PlayerNoclipState
}

Player :: struct {
    movementSpeed: f32,
    turnSpeed: f32,
    cam: rl.Camera3D,
    cam_offset: mathf.vec3,
    translation: mathf.vec3,
    time_scale: f32,
    can_move: bool,
    noclip: bool,
    isnoclip: bool,
    isGrounded: bool,
    state: PlayerState
}

gen_default_cam :: proc(player: ^Player, spawnPos: mathf.vec3) {
    player.cam = {
        spawnPos,
        { 0.0, 0.0, 0.0 }, 
        { 0.0, 1.0, 0.0 }, 
        45, 
        .PERSPECTIVE
    }

    fmt.println(player.cam.position)
}

gen_default_player :: proc(spawnPos: mathf.vec3) -> (player: Player) {
    player.state = PlayerWalkState {}
    player.can_move = true
    player.time_scale = 1.0
    player.turnSpeed = 10.0
    player.movementSpeed = 10.0
    player.isGrounded = true
    player.cam_offset = { 0, 2, 0 }
    gen_default_cam(&player, spawnPos)
    return
}

player_update :: proc(player: ^Player) {
    if player.noclip && !player.isnoclip {
        player.state = PlayerNoclipState{
            speed = 5
        }
        player.isnoclip = true
        return
    }

    switch &state in player.state {
        case PlayerFallingState:
            do_player_fall_physics(player, &state)
        case PlayerJumpState:
            do_player_jump_physics(player, &state)
        case PlayerWalkState:
            do_player_walk_physics(player, &state)
        case PlayerSlideState:
            do_player_slide_physics(player, &state)
        case PlayerNoclipState:
            do_player_noclip_physics(player, &state)
    }

    handle_input(player)

    delta3 : mathf.vec3 = { rl.GetMouseDelta()[0], rl.GetMouseDelta()[1], 0 }
    mouseDelta := delta3 * player.turnSpeed * rl.GetFrameTime() * player.time_scale

    rl.UpdateCameraPro(&player.cam, player.translation, mouseDelta, 0)
}

handle_input :: proc(player: ^Player) {
    if rl.IsKeyDown(.Z) do player.cam.target = { 0, 0, 0 }

    when !ODIN_DEBUG do return
    if rl.IsKeyPressed(.X) do player.noclip = !player.noclip
    if rl.IsKeyPressed(.Y) do player.time_scale = player.time_scale == 0.0 ? 1.0 : 0.0
}