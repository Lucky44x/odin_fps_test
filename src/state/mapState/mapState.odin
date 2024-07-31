package mapstate

import "core:math/linalg"
import "core:strings"
import "core:fmt"
import rl "vendor:raylib"
import im "../../engine/external/imgui"

import "../../engine/math/mathf"
import "../../engine/math/mathi"

Box :: struct {
    position: mathf.vec3,
    size: mathf.vec3
}

MapData :: struct {
    boxes: []Box
}

MapGameState :: struct {
    mapData: MapData,
    player: Player,
    rendTex: rl.RenderTexture2D,
}

isMapWindowOpen : bool = false

init_map :: proc(stateInst: ^MapGameState) {
    stateInst.rendTex = rl.LoadRenderTexture(rl.GetRenderWidth(), rl.GetRenderHeight())
}

update_map :: proc(state: ^MapGameState) {
    player_update(&state.player)
    render_collision_map(state)
}

render_map :: proc(state: ^MapGameState) {

    rl.BeginMode3D(state.player.cam)

    for &box in state.mapData.boxes {
        //rl.DrawCube(box.position, box.size[0], 0, box.size[2], rl.GREEN)
        rl.DrawCube(box.position, box.size[0], box.size[1], box.size[2], rl.MAROON)
    }
    
    rl.DrawGrid(10, 1.0)
    rl.EndMode3D()

    render_imgui(state)
    render_collision_imgui(state)
}

@(private)
render_collision_map :: proc(state: ^MapGameState) {    
    width, height := f32(state.rendTex.texture.width), f32(state.rendTex.texture.height)

    rl.BeginTextureMode(state.rendTex)
    rl.ClearBackground({ 0, 0, 0, 0 })

    rl.DrawCircle(i32(width / 2), i32(height / 2), 2.5, rl.RED)

    for &box, ind in state.mapData.boxes {
        boxPos := box.position - state.player.cam.position
        boxPos *= 50
        boxPos += { width / 2, 0, height / 2 }

        boxCenter : mathf.vec3 = { box.position[0] + (box.size[0] / 2), box.position[1] + (box.size[1] / 2), box.position[2] + (box.size[2] / 2) }
        dist := linalg.distance(boxCenter, state.player.cam.position)

        debCol := dist <= 2 ? rl.GREEN : rl.MAROON

        rl.DrawRectangle(
            i32(boxPos[0]),
            i32(boxPos[2]),
            i32(box.size[0] * 50),
            i32(box.size[2] * 50),
            debCol
        )

        rl.DrawCircleLines(i32(boxPos[0]) + i32(box.size[0] * 50) / 2, i32(boxPos[2]) + i32(box.size[2] * 50) / 2, 100, debCol)
    }

    rl.EndTextureMode()
}

@(private)
render_collision_imgui :: proc(state: ^MapGameState) {
    when !ODIN_DEBUG do return

    im.SetNextWindowSize({ f32(state.rendTex.texture.width) / 2, f32(state.rendTex.texture.height) / 2 })
    if im.Begin("Collision Map", nil, { im.WindowFlag.NoResize }) {
        im.Image(&state.rendTex.texture.id, im.GetContentRegionAvail(), {0, 1}, {1, 0})
    }
    im.End()
}

@(private)
render_imgui :: proc(state: ^MapGameState) {
    //Lock IMGUI out if we aren't in DEBUG mode
    when !ODIN_DEBUG do return

    if im.Begin("Cheats") {
        im.Checkbox("Noclip: X", &state.player.noclip)
        im.InputFloat("Timescale: Y", &state.player.time_scale)
    }
    im.End()

    if im.Begin("Debug-Map-State") {
        if im.CollapsingHeader("Player-Data") {
            im.Spacing()
            im.InputFloat("Desired Movement Speed", &state.player.movementSpeed)
            im.InputFloat("Desired Turn Speed", &state.player.turnSpeed)
            im.Text("Translation: [ %f, %f, %f ]", state.player.translation[0], state.player.translation[1], state.player.translation[2])
            im.Text("Cam Offset: [ %f, %f, %f ]", state.player.cam_offset[0], state.player.cam_offset[1], state.player.cam_offset[2])
            im.Text("Can Move: %i", state.player.can_move)
            im.Spacing()

            title := fmt.aprint(state.player.state)
            defer delete_string(title)

            titleParts := strings.split(title, "{")
            defer delete(titleParts)

            cTitle := strings.clone_to_cstring(titleParts[0])
            defer delete_cstring(cTitle)

            if im.CollapsingHeader(cTitle) {
                im.Spacing()
                switch &pState in state.player.state {
                    case PlayerWalkState:
                        im.InputFloat("Run-Modifier", &pState.runModifier)
                        im.Text("Is Running: %i", pState.isRunning)
                    case PlayerFallingState:
                        im.InputFloat("Gravity", &pState.GRAVITY)
                        im.Text("Velocity: [ %f, %f, %f ]", pState.velocity[0], pState.velocity[1], pState.velocity[2])
                    case PlayerSlideState:
                        im.InputFloat("speedBleed", &pState.speedBleed)
                        im.InputFloat3("Velocity", &pState.velocity)
                    case PlayerJumpState:
                        im.Text("Jump Impulse: %f", pState.jumpImpulse)
                        im.Text("Jump Dropoff: %f", pState.jumpDropoff)
                        im.Text("Fall Threshold: [ %f, %f, %f ]", pState.velocity[0], pState.velocity[1], pState.velocity[2])
                    case PlayerNoclipState:
                        im.InputFloat("Speed", &pState.speed)
                }
                im.Spacing()
            }
            if im.CollapsingHeader("Camera State") {
                im.Spacing()
                im.Text("Position: [ %f, %f, %f ]", state.player.cam.position[0], state.player.cam.position[1], state.player.cam.position[2])
                im.Text("Target: [ %f, %f, %f ]", state.player.cam.target[0], state.player.cam.target[1], state.player.cam.target[2])
                im.Text("Up: [ %f, %f, %f ]", state.player.cam.up[0], state.player.cam.up[1], state.player.cam.up[2])
                im.Text("FOV: %f", state.player.cam.fovy)

                //Have to manually clear those bytes, because why tf not
                camProjection : cstring = fmt.caprintf("%v", state.player.cam.projection)
                defer delete(camProjection)

                im.Text("Projection: %s", camProjection)
            }
        }
        im.Spacing()
        im.Separator()
        im.Spacing()
        if im.CollapsingHeader("Map-Data") {
            im.Spacing()
            if im.CollapsingHeader("Boxes") {
                im.Spacing()
                for &box, ind in state.mapData.boxes {
                    boxTitle := fmt.caprintf("Box %v", ind)
                    defer delete(boxTitle)
                    if im.CollapsingHeader(boxTitle) {
                        im.InputFloat3("Position", &box.position)
                        im.InputFloat3("Size", &box.size)
                    }
                }
            }
        }
    }

    if im.IsWindowFocused() {
        state.player.can_move = false
    }
    else {
        state.player.can_move = true
    }

    im.End()
}

/**
@(private)
debug_game_viewport :: proc() {
    when !ODIN_DEBUG do return

    if im.Begin("Scene") {
        im.BeginChild("GameRender")

        contSize := im.GetContentRegionAvail()
        factor : f32 = 0.0
        if contSize[0] < contSize[1] do factor = contSize[0] / f32(GAME_VIEWPORT_TEXTURE.texture.width)
        else do factor = contSize[1] / f32(GAME_VIEWPORT_TEXTURE.texture.height)

        im.Image(&GAME_VIEWPORT_TEXTURE.texture.id, { f32(GAME_VIEWPORT_TEXTURE.texture.width) * factor, f32(GAME_VIEWPORT_TEXTURE.texture.height) * factor }, {0, 1}, {1, 0})
        im.EndChild()
    }
    im.End()
}
**/