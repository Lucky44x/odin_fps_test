package transform

import "../math/mathf"
import rl "vendor:raylib"

import im "../external/imgui"

import "core:math"
import "core:math/linalg"

Transform :: struct {
    position: mathf.vec3,
    rotation: mathf.vec3,
    scale: mathf.vec3,

    FORWARD: mathf.vec3,
    RIGHT: mathf.vec3,
    UP: mathf.vec3,

    transformMatrix: rl.Matrix
}

//For Camera -> Camera doesn't have to recalculate transformationMatrix every frame...
apply_transform_rotation :: proc(transform: ^Transform) {
    update_direction_vectors(transform)
}

update_transform :: proc(transform: ^Transform) {
    transform.transformMatrix = rl.MatrixTranslate(
        transform.position[0],
        transform.position[1],
        transform.position[2]
    )

    transform.transformMatrix *= rl.MatrixRotateXYZ(
        transform.rotation
    )

    transform.transformMatrix *= rl.MatrixScale(
        transform.scale[0],
        transform.scale[1],
        transform.scale[2]
    )

    update_direction_vectors(transform)
}

@(private="file")
update_direction_vectors :: proc(transform: ^Transform) {
    viewRotMatrix := linalg.matrix3_from_yaw_pitch_roll(
        transform.rotation[1],
        transform.rotation[0],
        transform.rotation[2]
    )

    transform.FORWARD = linalg.vector_normalize(
        linalg.matrix_mul_vector(viewRotMatrix, mathf.vec3{ 0, 0, 1 })
    )

    transform.RIGHT = linalg.vector_normalize(
        linalg.matrix_mul_vector(viewRotMatrix, mathf.vec3{ 1, 0, 0 })
    )

    transform.UP = linalg.vector_normalize(
        linalg.matrix_mul_vector(viewRotMatrix, mathf.vec3{ 0, 1, 0 })
    )
}