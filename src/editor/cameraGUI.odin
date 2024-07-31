package editor

import rl "vendor:raylib"
import im "../engine/external/imgui"
import "core:fmt"
import "../engine/camera"

imgui_camera_inspector :: proc(cam: ^camera.Camera) {
    if im.CollapsingHeader("Camera") {
        previewValue: cstring = cam.viewCamera.projection == rl.CameraProjection.PERSPECTIVE ? "Perspective" : "Orthographic"
        if im.BeginCombo("Projection", previewValue) {
            if im.Selectable("Perspective") do cam.viewCamera.projection = rl.CameraProjection.PERSPECTIVE
            if im.Selectable("Orthographic") do cam.viewCamera.projection = rl.CameraProjection.ORTHOGRAPHIC
            im.EndCombo()
        }
    
        im.InputFloat("FovY", &cam.viewCamera.fovy)
        
        im.InputFloat("Near", &cam.nearPlane)
        im.InputFloat("Far", &cam.farPlane)
        im.InputFloat("Aspect", &cam.aspect)
    
        imgui_transform_inspector(&cam.transform, "Camera-Transform")
    }
}