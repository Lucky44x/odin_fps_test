package levelstate
import rl "vendor:raylib"
import im "../../../engine/external/imgui"
import "core:fmt"

do_freecam_imgui :: proc(player: ^Player) {
    if im.Button("Toggle Freecam") do toggle_freecam(player)
    im.Spacing()
    im.Checkbox("Editor Camera", &rightMouseLook)

    if !rightMouseLook {
        im.Spacing()
        im.Spacing()
    
        im.Text("Body - Parameters")
        im.Spacing()
        im.Checkbox("Lock Body-Movement", &player.settings.movement_locked)
        im.Spacing()
        im.Checkbox("Lock Body-Rotation", &player.settings.view_locked)
    
        im.Spacing()
        im.Spacing()
    
        im.Text("Freecam - Parameters")
        im.Spacing()
        im.Checkbox("Lock Freecam-Movement", &freecamMoveLocked)
        im.Spacing()
        im.Checkbox("Lock Freecam-Rotation", &freecamViewLocked)
    
        im.Spacing()
        im.Spacing()
    }
}