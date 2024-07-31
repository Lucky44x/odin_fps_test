package main

import "engine/window"
import "state/mapState"
import "state/menuState"

import rl "vendor:raylib"

import "core:fmt"

GameState :: union {
    mapState.MapGameState,
    menuState.MenuGameState
}

@(private)
currentState: GameState = menuState.MenuGameState{}

@(private)
windowTitle: cstring : "FPS TEST -- DEBUG" when ODIN_DEBUG else "FPS TEST -- RELEASE"

main :: proc() {
    window.setup_window(windowTitle, 250)

    state_switch_map(mapState.MapGameState {
        {{ 
            { {5, 1, 0}, {2, 2, 2} },
            { {-5, 1, 0}, {2, 2, 2} } 
        }}, 
        mapState.gen_default_player({ 10.0, 10.0, 10.0 }),
        {}
    })

    window.init_window(update, render)
}

@(private)
update :: proc() {
    switch &state in currentState {
        case mapState.MapGameState:
            mapState.update_map(&state)
        case menuState.MenuGameState:
            menuState.update_menu(&state)
    }
}

@(private)
render :: proc() {
    switch &state in currentState {
        case mapState.MapGameState:
            mapState.render_map(&state)
        case menuState.MenuGameState:
            menuState.render_menu(&state)
    }
}

state_switch_menu :: proc(state: menuState.MenuGameState) {
    currentState = state
    window.set_clearColor(rl.GREEN)
    rl.EnableCursor()
}

state_switch_map :: proc(state: mapState.MapGameState) {    
    currentState = state
    mapState.init_map(&currentState.(mapState.MapGameState))
    window.set_clearColor(rl.DARKGRAY)
    rl.DisableCursor()
}