package menuState

import "../../../engine/window"
import "../../../engine/ui"
import "../../../engine/input"
import rl "vendor:raylib"

import "core:fmt"

MenuState :: struct {
    mainMenuUI: ui.LevelUI
}

init_menu_state :: proc() {
    ui.init_ui(
        rl.LoadSound("assets/sounds/ui/blip.wav"), 
        rl.LoadSound("assets/sounds/ui/blip2.wav"),
        rl.LoadSound("assets/sounds/ui/error.wav")
    )
}

do_menu_update :: proc(state: ^MenuState) {
    ui.do_ui_update(&state.mainMenuUI)
}

do_menu_render :: proc(state: ^MenuState) {
    ui.do_ui_render(&state.mainMenuUI)
}

generate_key_binds_menu :: proc(keymap: ^input.BindingMap) -> []ui.Field {
    fields: [dynamic]ui.Field = make([dynamic]ui.Field)

    for bindId, &bind in keymap.bindingsMap {
        append(&fields, ui.ControlsInput{
            text = bind.name,
            bindMap = keymap,
            keyBind = &bind,
            selected = 0
        })
    }

    backButton := ui.Button{
        text = "< Back",
        leftPress = true,
        func = proc(lui: ^ui.LevelUI, butt: ^ui.Button) {
            lui.selectedui = 1
        }
    }

    append(&fields, backButton)
    return fields[:]
}