package editor

import rl "vendor:raylib"
import im "../engine/external/imgui"
import "core:fmt"
import "../engine/transform"
import "../engine/camera"
import "../engine/level"
import "../engine/physics"

character_controller_editor :: proc(character: ^physics.CharacterController, scenery: ^level.LevelData) {
    im.InputFloat3("position", character.position)
    im.InputFloat3("forward", character.forward)
    im.InputFloat3("right", character.right)

    if im.CollapsingHeader("Settings") {
        im.InputFloat("Height",&character.height)
        im.InputFloat("Width",&character.width)
        im.InputFloat("Max Collision Distance",&character.maxCollisionDist)
        im.InputFloat("Max Slope Angle",&character.maxSlopeAngle)
        im.Spacing()

        tag_mask_gui(&character.collisionTagMask, scenery, "Collision Mask")
        im.SameLine()
        tag_mask_gui(&character.groundTagMask, scenery, "Ground Mask")
    }
    if im.CollapsingHeader("State") {
        im.InputFloat("Slope Angle", &character.currentSlopeAngle, 0.0, 0.0, "%.3f", { im.InputTextFlag.ReadOnly })
        im.BeginDisabled()
        im.Checkbox("Grounded", &character.isGrounded)
        im.EndDisabled()
    }
}