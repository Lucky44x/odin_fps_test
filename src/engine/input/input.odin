package input

import rl "vendor:raylib"
import "core:fmt"
import "core:math/linalg"
import "core:strings"

Clear :: struct {}
MouseAxis :: enum {
    HORIZONTAL,
    VERTICAL,
    MIDDLE,
    UNKNOWN
}

VirtualAxis :: struct {
    positiveBind: KeyAndMouseButton,
    negativeBind: KeyAndMouseButton
}

InputAxis :: union {
    MouseAxis,
    VirtualAxis
}

KeyAndMouseButton :: union {
    rl.KeyboardKey,
    rl.MouseButton
}

KeyAndMouseInput :: union {
    KeyAndMouseButton,
    InputAxis,
    Clear
}

InputBind :: struct {
    name: cstring,
    keyboardInput: KeyAndMouseInput
}

DefaultBind :: struct {
    input: KeyAndMouseInput,
    name: cstring,
    id: string
}

BindingMap :: struct {
    bindingsMap: map[string]InputBind,
}

@(private)
input_queue: [dynamic]rl.KeyboardKey

@(private)
contextMap: ^BindingMap

axis_to_cstring :: proc(axis: InputAxis) -> []cstring {
    ret := []cstring{}
    
    switch &type in axis {
        case MouseAxis:
            ret = make([]cstring, 1)
            ret[0] = mouse_axis_to_cstring(type)
        case VirtualAxis:
            ret = make([]cstring, 2)

            axPos := input_to_cstring(type.positiveBind)
            defer delete(axPos)

            axNeg := input_to_cstring(type.negativeBind)
            defer delete(axNeg)

            ret[0] = axPos
            ret[1] = axNeg
    }

    return ret
}

input_to_cstring :: proc(input: KeyAndMouseButton) -> cstring {
    buttonRaw := fmt.aprintf("%v", input)
    defer delete(buttonRaw)

    if strings.contains(buttonRaw, "&"){
        buttonParts := strings.split(buttonRaw, "&")
        defer delete(buttonParts)
    
        buttonRaw = buttonParts[1]
    }

    if strings.contains(buttonRaw, "{}"){
        buttonParts := strings.split(buttonRaw, "{")
        defer delete(buttonParts)

        buttonRaw = buttonParts[0] 
    }

    buttonC := strings.clone_to_cstring(buttonRaw)
    return buttonC
}

setup_debug_input :: proc() -> (enq: proc(rl.KeyboardKey), unl: proc(), clr: proc()) {
    input_queue = make([dynamic]rl.KeyboardKey)

    return enqueue_debug_key_press, unload_debug_input_data, clear_debug_key_press_queue
}

@(private)
enqueue_debug_key_press :: proc(key: rl.KeyboardKey) {
    append(&input_queue, key)
}


@(private)
dequeue_debug_key_press :: proc() -> rl.KeyboardKey {
    if len(input_queue) <= 0 {
        return rl.KeyboardKey.KEY_NULL
    }

    return pop(&input_queue)
}

@(private)
clear_debug_key_press_queue :: proc() {
    clear(&input_queue)
}

set_context :: proc(keymap: ^BindingMap) {
    contextMap = keymap
}

unload_debug_input_data :: proc() {
    delete(input_queue)
}

get_key_pressed :: proc() -> rl.KeyboardKey {
    when ODIN_DEBUG {
        return dequeue_debug_key_press()
    }
    
    return rl.GetKeyPressed()
}

gen_bindings_map :: proc(defBinds: []DefaultBind) -> BindingMap {
    newMap := BindingMap {
        bindingsMap = make(map[string]InputBind)
    }

    for &bind in defBinds {
        newMap.bindingsMap[bind.id] = InputBind{
            name = bind.name,
            keyboardInput = bind.input
        }
    }

    //defer delete(newMap.bindingsMap)

    return newMap
}

@(private)
check_context :: proc() -> bool {
    if contextMap == nil {
        fmt.eprintln("NO CONTEXT FOR INPUT SYSTEM SET... PLEASE PROVIDE A VALID CONTEXT BEFORE QUERRYING")
        return false
    }

    return true
}

mouse_axis_to_cstring :: proc(axis: MouseAxis) -> cstring {
    switch axis {
        case .HORIZONTAL: return "Mouse-X"
        case .VERTICAL: return "Mouse-Y"
        case .MIDDLE: return "Mouse-Middle"
        case .UNKNOWN: return "UNKNOWN"
    }

    return "UNKNOWN"
}

is_bind_pressed :: proc(id: string) -> bool {
    if !check_context() do return false

    bindData, ok := contextMap.bindingsMap[id]
    if !ok do return false

    #partial switch &type in bindData.keyboardInput {
        case KeyAndMouseButton:
            switch &bind in type {
                case rl.KeyboardKey:
                    return rl.IsKeyPressed(bind)
                case rl.MouseButton:
                    return rl.IsMouseButtonPressed(bind)   
            }
    }

    fmt.eprintfln("Could not get pressed-state of bind \"%v\": is of type axis", id)

    return false
}

is_bind_down :: proc(id: string) -> bool {
    if !check_context() do return false

    bindData, ok := contextMap.bindingsMap[id]
    if !ok do return false

    #partial switch &type in bindData.keyboardInput {
        case KeyAndMouseButton:
            switch &bind in type {
                case rl.KeyboardKey:
                    return rl.IsKeyDown(bind)
                case rl.MouseButton:
                    return rl.IsMouseButtonDown(bind)   
            }
    }

    fmt.eprintfln("Could not get pressed-state of bind \"%v\": is of type axis", id)

    return false
}

is_bind_up :: proc(id: string) -> bool {
    if !check_context() do return false

    bindData, ok := contextMap.bindingsMap[id]
    if !ok do return false

    #partial switch &type in bindData.keyboardInput {
        case KeyAndMouseButton:
            switch &bind in type {
                case rl.KeyboardKey:
                    return rl.IsKeyUp(bind)
                case rl.MouseButton:
                    return rl.IsMouseButtonUp(bind)   
            }
    }

    fmt.eprintfln("Could not get pressed-state of bind \"%v\": is of type axis", id)

    return false
}

is_bind_released :: proc(id: string) -> bool {
    if !check_context() do return false

    bindData, ok := contextMap.bindingsMap[id]
    if !ok do return false

    #partial switch &type in bindData.keyboardInput {
        case KeyAndMouseButton:
            switch &bind in type {
                case rl.KeyboardKey:
                    return rl.IsKeyReleased(bind)
                case rl.MouseButton:
                    return rl.IsMouseButtonReleased(bind)   
            }
    }

    fmt.eprintfln("Could not get pressed-state of bind \"%v\": is of type axis", id)

    return false
}

get_axis_pressed_repeat :: proc(id: string) -> (positive: bool, negative: bool) {
    if !check_context() do return false, false

    bindData, ok := contextMap.bindingsMap[id]
    if !ok do return false, false

    #partial switch &type in bindData.keyboardInput {
        case InputAxis:
            switch &axis in type {
                case MouseAxis:
                    fmt.eprintf("Could not get axis-pressed-state of \"%v\": is of type Mouse-Axis", id)
                case VirtualAxis:
                    return is_button_pressed_repeat(axis.positiveBind), is_button_pressed_repeat(axis.negativeBind)
            }
    }

    fmt.eprintfln("Could not get axis-pressed-state of bind \"%v\": is of type button", id)

    return false, false
}

get_axis_down :: proc(id: string) -> (positive: bool, negative: bool) {
    if !check_context() do return false, false

    bindData, ok := contextMap.bindingsMap[id]
    if !ok do return false, false

    #partial switch &type in bindData.keyboardInput {
        case InputAxis:
            switch &axis in type {
                case MouseAxis:
                    fmt.eprintf("Could not get axis-pressed-state of \"%v\": is of type Mouse-Axis", id)
                case VirtualAxis:
                    return is_button_down(axis.positiveBind), is_button_down(axis.negativeBind)
            }
    }

    fmt.eprintfln("Could not get axis-pressed-state of bind \"%v\": is of type button", id)

    return false, false
}

get_axis_pressed :: proc(id: string) -> (positive: bool, negative: bool) {
    if !check_context() do return false, false

    bindData, ok := contextMap.bindingsMap[id]
    if !ok do return false, false

    #partial switch &type in bindData.keyboardInput {
        case InputAxis:
            switch &axis in type {
                case MouseAxis:
                    fmt.eprintf("Could not get axis-pressed-state of \"%v\": is of type Mouse-Axis", id)
                case VirtualAxis:
                    return is_button_pressed(axis.positiveBind), is_button_pressed(axis.negativeBind)
            }
    }

    fmt.eprintfln("Could not get axis-pressed-state of bind \"%v\": is of type button", id)

    return false, false
}

@(private)
is_button_pressed_repeat :: proc(button: KeyAndMouseButton) -> bool {
    if !check_context() do return false

    switch &type in button {
        case rl.KeyboardKey:
            return rl.IsKeyPressedRepeat(type)
        case rl.MouseButton:
            return rl.IsMouseButtonDown(type)
    }

    return false
}

@(private)
is_button_down :: proc(button: KeyAndMouseButton) -> bool {
    if !check_context() do return false

    switch &type in button {
        case rl.KeyboardKey:
            return rl.IsKeyDown(type)
        case rl.MouseButton:
            return rl.IsMouseButtonDown(type)
    }

    return false
}

@(private)
is_button_pressed :: proc(button: KeyAndMouseButton) -> bool {
    if !check_context() do return false

    switch &type in button {
        case rl.KeyboardKey:
            return rl.IsKeyPressed(type)
        case rl.MouseButton:
            return rl.IsMouseButtonPressed(type)
    }

    return false
}

get_axis_value :: proc(id: string) -> f32 {
    if !check_context() do return 0.0

    bindData, ok := contextMap.bindingsMap[id]
    if !ok do return 0.0

    axisValue : f32 = 0.0

    switch &type in bindData.keyboardInput {
        case InputAxis:
            switch &axis in type {
                case MouseAxis:
                    mouseDelta := rl.GetMouseDelta()
                    #partial switch axis {
                        case .HORIZONTAL:
                            axisValue = mouseDelta[0]
                            break
                        case .VERTICAL:
                            axisValue = mouseDelta[1]
                            break
                        case .MIDDLE:
                            axisValue = rl.GetMouseWheelMove()
                            break
                    }

                case VirtualAxis:
                    if is_button_down(axis.positiveBind) do axisValue += 1
                    if is_button_down(axis.negativeBind) do axisValue -= 1
            }
        case KeyAndMouseButton:
            fmt.eprintfln("Could not get axis-value of bind \"%v\": is of type button", id)
        case Clear:
            fmt.eprintfln("Could not get axis-value of bind \"%v\": is of type CLEAR", id)
    }

    return axisValue
}