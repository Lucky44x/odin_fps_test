package camera

import "../math/mathf"
import "../transform"

import im "../external/imgui"

import rl "vendor:raylib"
import "core:math/linalg"
import "core:math"

import "core:fmt"

Camera :: struct{
    transform: transform.Transform,
    viewCamera: rl.Camera3D,
    viewRotMatrix: mathf.mat3,
    nearPlane, farPlane, aspect: f32,
}

DEFAULT_CAMERA :: Camera {
    {},
    { 
        { 0, 0, 0 },
        { 0, 0, 0 },
        { 0, 1, 0 },
        60,
        .PERSPECTIVE
    },
    { 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    0, 0, 0
}

look_at :: proc(cam: ^Camera, position: mathf.vec3) {
    //TODO Help
}

apply_position :: proc(cam: ^Camera) {
    cam.viewCamera.position = cam.transform.position
    cam.viewCamera.target = cam.viewCamera.position + cam.transform.FORWARD
    cam.viewCamera.up = linalg.normalize(
        linalg.quaternion_mul_vector3(
            linalg.quaternion_angle_axis(cam.transform.rotation[2] * 1.3, cam.transform.FORWARD),
            mathf.vec3{ 0, 1.0, 0 }
        )
    )
}

apply_rotation :: proc(cam: ^Camera) {
    //TODO Possible: Z-Rotation for walkin/sliding/running juice - Refer line 368 in https://github.com/jakubtomsu/dungeon-of-quake/blob/main/game/state.player.odin

    cam.viewRotMatrix = linalg.matrix3_from_yaw_pitch_roll(
        cam.transform.rotation[1],
        cam.transform.rotation[0],
        cam.transform.rotation[2]
    )

    transform.apply_transform_rotation(&cam.transform)
}

draw_camera :: proc(cam: ^Camera) {
    rl.DrawSphereWires(cam.viewCamera.position, 0.05, 4, 4, rl.ORANGE)
    rl.DrawLine3D(cam.viewCamera.position, cam.viewCamera.target, rl.ORANGE)
}