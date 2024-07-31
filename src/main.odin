package main

import "engine/window"
import rl "vendor:raylib"

import "engine/input"
import "engine/ui"
import engLev "engine/level"

import "game/gamestate/level"
import "game/gamestate/menu"

import "core:fmt"

GameState :: union {
    menu.MenuState,
    level.LevelState
}

@(private)
windowTitle: cstring : "FPS TEST -- DEBUG" when ODIN_DEBUG else "FPS TEST -- RELEASE"

@(private)
currentState: GameState

default_keymap: input.BindingMap

main :: proc() {
    window.setup_window(windowTitle, 280)
    init_state_machine()

    window.set_clearColor(rl.BLUE)

    default_keymap = input.gen_bindings_map({
        { input.InputAxis(input.VirtualAxis{ .D, .A }), "Move Horizontal", "MOVEX" },
        { input.InputAxis(input.VirtualAxis{ .W, .S }), "Move Vertical", "MOVEY" },
        { input.InputAxis(input.MouseAxis.HORIZONTAL), "Look Horizontal", "LOOKX" },
        { input.InputAxis(input.MouseAxis.VERTICAL), "Look Vertical", "LOOKY" },
        { input.KeyAndMouseButton(rl.KeyboardKey.ESCAPE), "Pause", "ESCAPE" },
        { input.KeyAndMouseButton(rl.KeyboardKey.GRAVE), "Debugkey", "DEBUG" }
    })

    currentState = menu.MenuState{
        {
            inputSettings = {
                keymap = &default_keymap,
                uiHorizotnalAxis = "MOVEX",
                uiVerticalAxis = "MOVEY",
                uiEscape = "ESCAPE"
            },
            uis = {
                {
                    xOffset = 50,
                    yOffset = 25,
                    fieldSpacing = 25,
                    fields = {
                        ui.Button{
                            text = "Levels",
                            func = proc(state: ^ui.LevelUI, butt: ^ui.Button) {
                                state.selectedui = 2
                            }
                        },
                        ui.Button{
                            text = "Options",
                            func = proc(state: ^ui.LevelUI, butt: ^ui.Button) {
                                state.selectedui = 1
                            }
                        },
                        ui.Button{
                            text = "Exit",
                            func = proc(state: ^ui.LevelUI, butt: ^ui.Button) {
                               window.set_close()
                            }
                        }
                    }
                },
                {
                    xOffset = 50,
                    yOffset = 25,
                    fieldSpacing = 25,
                    fields = {
                        ui.ValueSwitch{
                            text = "Window Mode:",
                            values = {
                                "Fullscreen",
                                "Fullscreen in Window",
                                "Window"
                            }
                        },
                        ui.BoolSwitch{
                            text = "Vsync"
                        },
                        ui.Button{
                            text = "KeyBinds",
                            func = proc(state: ^ui.LevelUI, butt: ^ui.Button) {
                                state.selectedui = 3
                            }
                        },
                        ui.TwoSideButton{
                            leftText = "< Back",
                            rightText = "Apply",
                            leftFunc = proc(state: ^ui.LevelUI, butt: ^ui.TwoSideButton) {
                                state.selectedui = 0
                            },
                            rightFunc = proc(state: ^ui.LevelUI, butt: ^ui.TwoSideButton) {
                                fmt.printfln("Apply Settings")
                            }
                        }
                    }
                },
                {
                    xOffset = 50,
                    yOffset = 25,
                    fieldSpacing = 25,
                    fields = level.generate_levels("assets/maps"),
                },
                {
                    xOffset = 50,
                    yOffset = 25,
                    fieldSpacing = 25,
                    fields = menu.generate_key_binds_menu(&default_keymap)
                }
            }
        }
    }

    level.set_keymap(&default_keymap)

    window.init_window(update, render)

    exit()
}

@(private)
exit :: proc() {

}

@(private)
update :: proc() {
    switch &state in currentState {
        case level.LevelState:
            level.do_level_update(&state)
        case menu.MenuState:
            menu.do_menu_update(&state)
    }
}

@(private)
render :: proc() {
    switch &state in currentState {
        case level.LevelState:
            level.do_level_render(&state)
        case menu.MenuState:
            menu.do_menu_render(&state)
    }
}

init_state_machine :: proc() {
    level.init_state_machine(
        switchLevelState
    )

    menu.init_menu_state()
}

switchLevelState :: proc(newState: level.LevelState) {
    currentState = newState
    level.init_level(&currentState.(level.LevelState))
}