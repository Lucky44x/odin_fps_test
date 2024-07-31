package editor

import rl "vendor:raylib"
import im "../engine/external/imgui"
import "core:fmt"
import trans "../engine/transform"

imgui_transform_inspector :: proc(transform: ^trans.Transform, name: cstring = "Transform", updateButton: bool = false) {
    if im.CollapsingHeader(name) {
        im.InputFloat3("Position", &transform.position)
        im.InputFloat3("Scale", &transform.scale)
        im.InputFloat3("Rotation", &transform.rotation)
    
        if updateButton {
            if im.Button("Update Transform") do trans.update_transform(transform)
        }
    }
}