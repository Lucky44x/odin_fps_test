package rendering

import "../math/mathi"
import "../math/mathf"
import rl "vendor:raylib"

RenderFuture2D :: union{
    Rect,
    RectLines,
    Circle,
    CircleLines,
    Line2D,
    proc()
}

RenderFuture3D :: union {
    Box,
    Line3D,
    SphereWires,
    CubeWires,
    Model,
    Ray3D,
    CapsuleWires,
    proc()
}

Model :: struct {
    model: rl.Model,
    position: mathf.vec3,
    size: f32,
    col: rl.Color
}

Box :: struct {
    box: rl.BoundingBox,
    col: rl.Color
}

CubeWires :: struct {
    point, size: mathf.vec3,
    col: rl.Color
}

Line2D :: struct {
    start: mathf.vec2,
    end: mathf.vec2,
    col: rl.Color
}

Ray3D :: struct {
    ray: rl.Ray,
    col: rl.Color
}

Line3D :: struct {
    start: mathf.vec3,
    end: mathf.vec3,
    col: rl.Color
}

SphereWires :: struct {
    point: mathf.vec3,
    radius: f32,
    col: rl.Color
}

CapsuleWires :: struct {
    start, end: mathf.vec3,
    radius: f32,
    col: rl.Color
}

RectLines :: struct {
    pos, size: mathi.vec2,
    col: rl.Color
}

Rect :: struct {
    pos, size: mathi.vec2,
    col: rl.Color
}

CircleLines :: struct {
    pos: mathi.vec2,
    radius: f32,
    col: rl.Color
}

Circle :: struct {
    pos: mathf.vec2,
    radius: f32,
    col: rl.Color
}

@(private)
RenderFutures2D: [dynamic]RenderFuture2D = make([dynamic]RenderFuture2D)
@(private)
RenderFutures3D: [dynamic]RenderFuture3D = make([dynamic]RenderFuture3D)

destory_render_futures :: proc() {
    delete(RenderFutures2D)
}

add_2D_future :: proc(command: RenderFuture2D) {
    append(&RenderFutures2D, command)
}

add_3D_future :: proc(command: RenderFuture3D) {
    append(&RenderFutures3D, command)
}

render_2D_futures :: proc() {
    if len(RenderFutures2D) <= 0 do return

    for command in RenderFutures2D {
        switch &type in command {
            case Rect:
                rl.DrawRectangle(type.pos[0], type.pos[1], type.size[0], type.size[1], type.col)
                break
            case RectLines:
                rl.DrawRectangleLines(type.pos[0], type.pos[1], type.size[0], type.size[1], type.col)
                break
            case Circle:
                rl.DrawCircleV(type.pos, type.radius, type.col)
                break
            case CircleLines:
                rl.DrawCircleLines(type.pos[0], type.pos[1], type.radius, type.col)
                break
            case Line2D:
                rl.DrawLineV(type.start, type.end, type.col)
                break
            case proc():
                type()
                break
        }
    }
    clear_dynamic_array(&RenderFutures2D)
}

render_3D_futures :: proc() {
    if len(RenderFutures3D) <= 0 do return

    for command in RenderFutures3D {
        switch &type in command {
            case Box:
                rl.DrawBoundingBox(type.box, type.col)
                break
            case Line3D:
                rl.DrawLine3D(type.start, type.end, type.col)
                break
            case SphereWires:
                rl.DrawSphereWires(type.point, type.radius, 8, 8, type.col)
                break
            case CubeWires:
                rl.DrawCubeWiresV(type.point, type.size, type.col)
                break
            case Model:
                rl.DrawModel(type.model, type.position, type.size, type.col)
                break
            case Ray3D:
                rl.DrawRay(type.ray, type.col)
                break
            case CapsuleWires:
                rl.DrawCapsuleWires(type.start, type.end, type.radius, 16, 16, type.col)
                break
            case proc():
                type()
                break
        }
    }
    clear_dynamic_array(&RenderFutures3D)
}