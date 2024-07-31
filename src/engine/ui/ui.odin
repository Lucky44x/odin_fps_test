package ui

import "core:fmt"
import rl "vendor:raylib"
import "../../engine/math/mathi"
import "../input"

import "core:strings"

@(private)
UISIZE: i32 = 1

@(private)
blipSound: rl.Sound
@(private)
blipSound2: rl.Sound
@(private)
errorBlipSound: rl.Sound

UIInput :: struct {
    keymap: ^input.BindingMap,
    uiVerticalAxis: string,
    uiHorizotnalAxis: string,
    uiEscape: string
}

LevelUI :: struct {
    inputSettings: UIInput,
    uis: []SubUI,
    selectedui: int
}

SubUI :: struct {
    xOffset: i32,
    yOffset: i32,
    fieldSpacing: i32,
    fields: []Field,
    selectedField: int
}

Field :: union {
    Button,
    TwoSideButton,
    IntInput,
    FloatInput,
    ValueSwitch,
    BoolSwitch,
    ControlsInput,
    Text,
    TextInput,
    Hint
}

Hint :: struct {
    text: cstring,
    extras: []int
}

Text :: struct {
    text: cstring,
    extras: []int
}

TextInput :: struct {
    text: cstring,
    focused: bool,
    extras: []int,
    value: cstring
}

Button :: struct {
    text: cstring,
    leftPress: bool,
    extras: []int,
    func: proc(^LevelUI, ^Button)
}

TwoSideButton :: struct {
    rightSelected: bool,
    leftText: cstring,
    rightText: cstring,
    extras: []int,
    leftFunc: proc(^LevelUI, ^TwoSideButton),
    rightFunc: proc(^LevelUI, ^TwoSideButton)
}

IntInput :: struct {
    text: cstring,
    value: i32,
    maxVal: i32,
    minVal: i32,
    stepSize: i32,
    extras: []int
}

FloatInput :: struct {
    text: cstring,
    value: f32,
    maxVal: f32,
    minVal: f32,
    stepSize: f32,
    extras: []int
}

BoolSwitch :: struct {
    text: cstring,
    value: bool,
    extras: []int
}

ValueSwitch :: struct {
    text: cstring,
    values: []cstring,
    selected: int,
    extras: []int
}

ControlsInput :: struct {
    text: cstring,
    bindMap: ^input.BindingMap,
    keyBind: ^input.InputBind,
    selected: int,
    listening: bool
}

TimedBox :: struct {
    message: cstring,
    textCol: rl.Color,
    backCol: rl.Color,
    lastFor: f32,
    passedTime: f32
}

@(private)
timed_boxes: map[string]TimedBox

@(private)
finishedBoxesBuffer: [dynamic]string

init_ui :: proc(uiSoundMove: rl.Sound, uiSoundChange: rl.Sound, uiSoundError: rl.Sound) {
    blipSound = uiSoundMove
    blipSound2 = uiSoundChange
    errorBlipSound = uiSoundError

    timed_boxes = make(map[string]TimedBox)
    finishedBoxesBuffer = make([dynamic]string)
}

do_ui_update :: proc(state: ^LevelUI) {
    if len(state.uis) <= 0 do return

    handle_input(&state.uis[state.selectedui], state)
}

do_ui_render :: proc(state: ^LevelUI) {
    if state == nil do return

    if len(state.uis) <= 0 do return
    draw_sub_ui(&state.uis[state.selectedui])

    for key, &box in timed_boxes {
        box.passedTime += rl.GetFrameTime()
        if box.lastFor - box.passedTime <= 0 {
            append(&finishedBoxesBuffer, key)
        }

        draw_overlay_box(box.message, 0.05, box.textCol, box.backCol)
    }

    for &id in finishedBoxesBuffer {
        delete_key(&timed_boxes, id)
    }
    clear(&finishedBoxesBuffer)
}

draw_sub_ui :: proc(ui: ^SubUI) {
    ui_y_off := 0

    for &field, ind in ui.fields {
        textCol := ind == ui.selectedField ? rl.RED : rl.GRAY
        position: mathi.vec2 = { ui.xOffset, 50 * UISIZE * i32(ind - ui_y_off) + ui.yOffset + (ui.fieldSpacing * i32(ind - ui_y_off)) }
        
        switch &type in &field {
            case BoolSwitch: draw_bool_input(&type, position, textCol)
            case Button: draw_button(&type, position, textCol)
            case FloatInput: draw_float_input(&type, position, textCol)
            case IntInput: draw_int_input(&type, position, textCol)
            case ValueSwitch: draw_value_switch(&type, position, textCol)
            case TwoSideButton: draw_two_sided_button(&type, position, textCol)
            case Text: draw_text(&type, position)
            case TextInput: draw_text_input(&type, position, textCol)
            case ControlsInput: draw_controls_input(&type, position, textCol)
            case Hint:
                ui_y_off += 1
                position[1] = 50 * UISIZE * i32(ind - ui_y_off) + ui.yOffset + (ui.fieldSpacing * i32(ind - ui_y_off))
                draw_text_hint(&type, position, textCol)
        }
    }
}

get_ui_height :: proc(ui: ^SubUI) -> i32 {
    totalHeight: i32 = 0

    for &field, ind in ui.fields {
        totalHeight += 50 * UISIZE * i32(ind) + ui.yOffset + (ui.fieldSpacing * i32(ind))
    }

    return totalHeight
}

@(private)
draw_overlay_box :: proc(text: cstring, ratio: f32, textCol: rl.Color = rl.WHITE, backCol: rl.Color = rl.GRAY) {
    textW := rl.MeasureText(text, 50 * UISIZE)
    textH := i32(f32(textW) * ratio)

    screenWidth := rl.GetRenderWidth()
    screenHeight := rl.GetRenderHeight()

    boxStartX := (screenWidth / 2) - (textW / 2)
    boxStartY := (screenHeight / 2) - (textH / 2)

    textStartY := boxStartY + (textH / 2) - ((50 * UISIZE) / 2)

    rl.DrawRectangle(boxStartX - 25, boxStartY, textW + 50, textH, backCol)
    rl.DrawText(text, boxStartX, textStartY, 50 * UISIZE, textCol)
}

@(private)
draw_controls_input :: proc(data: ^ControlsInput, pos: mathi.vec2, color: rl.Color) {
    textW := rl.MeasureText(data.text, 50 * UISIZE) + 25 * UISIZE
    rl.DrawText(data.text, pos[0], pos[1], 50 * UISIZE, data.selected == 0 ? color : rl.GRAY)

    #partial switch &type in data.keyBind.keyboardInput {
        case input.InputAxis:
            buttonTexts := input.axis_to_cstring(type)
            defer delete(buttonTexts)

            rl.DrawText(buttonTexts[0], pos[0] + textW, pos[1], 50 * UISIZE, data.selected == 1 ? color : rl.DARKGRAY)
            textW += rl.MeasureText(buttonTexts[0], 50 * UISIZE) + 25 * UISIZE
            
            if len(buttonTexts) == 1 do break

            rl.DrawText(buttonTexts[1], pos[0] + textW, pos[1], 50 * UISIZE, data.selected == 2 ? color : rl.DARKGRAY)
        case input.KeyAndMouseButton:
            keyText := input.input_to_cstring(type)
            defer delete(keyText)

            rl.DrawText(keyText, pos[0] + textW, pos[1], 50 * UISIZE, data.selected == 1 ? color : rl.DARKGRAY)
    }

    if data.listening {
        draw_overlay_box("Press any key to set, or escape to cancel", .15)
    }
}

@(private)
draw_text_hint :: proc(data: ^Hint, pos: mathi.vec2, color: rl.Color) {
    position: mathi.vec2 = { 0, pos[1] + (25 / 2) } 
    textW := rl.MeasureText(data.text, 25 * UISIZE)
    position[0] = rl.GetRenderWidth() - textW - 25 * UISIZE

    rl.DrawText(data.text, position[0], position[1], 25 * UISIZE, rl.DARKGRAY)
}

@(private)
draw_text_input :: proc(data: ^TextInput, pos: mathi.vec2, color: rl.Color) {
    rl.DrawText(data.text, pos[0], pos[1], 50 * UISIZE, rl.GRAY)
}

@(private)
draw_text :: proc(data: ^Text, pos: mathi.vec2) {
    rl.DrawText(data.text, pos[0], pos[1], 50 * UISIZE, rl.GRAY)
}

@(private)
draw_two_sided_button :: proc(data: ^TwoSideButton, pos: mathi.vec2, color: rl.Color) {
    rl.DrawText(data.leftText, pos[0], pos[1], 50 * UISIZE, data.rightSelected ? rl.GRAY : color)
    rightOff := rl.MeasureText(data.leftText, 50 * UISIZE) + 25 * UISIZE

    rl.DrawText("--", pos[0] + rightOff, pos[1], 50 * UISIZE, rl.GRAY)
    rightOff += rl.MeasureText("--", 50 * UISIZE) + 25 * UISIZE

    rl.DrawText(data.rightText, pos[0] + rightOff, pos[1], 50 * UISIZE, data.rightSelected ? color : rl.GRAY)
}

@(private)
draw_button :: proc(data: ^Button, pos: mathi.vec2, color: rl.Color) {
    rl.DrawText(data.text, pos[0], pos[1], 50 * UISIZE, color)
}

@(private)
draw_value_switch :: proc(data: ^ValueSwitch, pos: mathi.vec2, color: rl.Color) {
    textOff := rl.MeasureText(data.text, 50 * UISIZE) + 25 * UISIZE
    rl.DrawText(data.text, pos[0], pos[1], 50 * UISIZE, color)

    if data.selected > 0 {
        textW := rl.MeasureText(data.values[data.selected - 1], 50 * UISIZE) + 25
        rl.DrawText(data.values[data.selected - 1], pos[0] + textOff, pos[1], 50 * UISIZE, rl.LIGHTGRAY)

        textOff += textW
    }

    rl.DrawText(data.values[data.selected], pos[0] + textOff, pos[1], 50 * UISIZE, rl.DARKGRAY)
    textOff += rl.MeasureText(data.values[data.selected], 50 * UISIZE) + 25

    if data.selected < len(data.values) - 1 {
        textW := rl.MeasureText(data.values[data.selected + 1], 50 * UISIZE) + 25
        rl.DrawText(data.values[data.selected + 1], pos[0] + textOff, pos[1], 50 * UISIZE, rl.LIGHTGRAY)

        textOff += textW
    }
}

@(private)
draw_float_input :: proc(data: ^FloatInput, pos: mathi.vec2, color: rl.Color) {
    textW := rl.MeasureText(data.text, 50 * UISIZE) + 25
    rl.DrawText(data.text, pos[0], pos[1], 50 * UISIZE, color)
    textVal := rl.TextFormat("%f", data.value)
    rl.DrawText(textVal, pos[0] + textW, pos[1], 50 * UISIZE, rl.DARKGRAY)
}

@(private)
draw_int_input :: proc(data: ^IntInput, pos: mathi.vec2, color: rl.Color) {
    textW := rl.MeasureText(data.text, 50 * UISIZE) + 25
    rl.DrawText(data.text, pos[0], pos[1], 50 * UISIZE, color)
    textVal := rl.TextFormat("%i", data.value)
    rl.DrawText(textVal, pos[0] + textW, pos[1], 50 * UISIZE, rl.DARKGRAY)
}

@(private)
draw_bool_input :: proc(data: ^BoolSwitch, pos: mathi.vec2, color: rl.Color) {
    textW := rl.MeasureText(data.text, 50 * UISIZE) + 25
    rl.DrawText(data.text, pos[0], pos[1], 50 * UISIZE, color)
    textVal : cstring = data.value ? "TRUE" : "FALSE"
    rl.DrawText(textVal, pos[0] + textW, pos[1], 50 * UISIZE, rl.DARKGRAY)
}

add_timed_box :: proc(id: string, text: cstring, foreColor: rl.Color, backColor: rl.Color, time: f32) {
    _, ok := timed_boxes[id]
    if ok do return

    timed_boxes[id] = TimedBox{
        textCol = foreColor,
        backCol = backColor,
        lastFor = time,
        message = text
    }
}

@(private)
soundRepeatLock: bool = false

@(private)
handle_input :: proc(ui: ^SubUI, state: ^LevelUI) {
    if len(ui.fields) == 0 do return

    input.set_context(state.inputSettings.keymap)

    leftDown, rightDown := input.get_axis_down(state.inputSettings.uiHorizotnalAxis)

    pressedRight, pressedLeft := input.get_axis_pressed(state.inputSettings.uiHorizotnalAxis)
    pressedRightRep, pressedLeftRep := input.get_axis_pressed_repeat(state.inputSettings.uiHorizotnalAxis)

    pressedUp, pressedDown := input.get_axis_pressed(state.inputSettings.uiVerticalAxis)

    if !pressedRight && soundRepeatLock do soundRepeatLock = false

    if input.is_bind_pressed(state.inputSettings.uiEscape) {
        #partial switch &type in ui.fields[ui.selectedField] {
            case ControlsInput:
                type.listening = false
        }
    }

    #partial switch &type in ui.fields[ui.selectedField] {
        case ControlsInput:
            if type.listening {
                //TODO REMAP
                return
            }
    }

    if pressedUp || pressedDown {
        diff := pressedUp ? -1 : 1

        #partial switch &type in ui.fields[ui.selectedField] {
            case ControlsInput:
                if type.selected > 0 {
                    type.listening = true
                    return
                }
        }

        ui.selectedField += diff

        if ui.selectedField < 0 || ui.selectedField >= len(ui.fields) {
            ui.selectedField -= diff
            rl.PlaySound(errorBlipSound)
            return
        }

        change := diff
        #partial switch &type in ui.fields[ui.selectedField] {
            case Text: ui.selectedField += diff; change += diff
            case Hint: ui.selectedField += diff; change += diff
        }

        if ui.selectedField < 0 || ui.selectedField >= len(ui.fields) {
            ui.selectedField -= change
            rl.PlaySound(errorBlipSound)
            return
        }
        else do rl.PlaySound(blipSound)
    }

    if pressedLeft || pressedRight {
        if len(ui.fields) == 0 {
            rl.PlaySound(errorBlipSound)
            return
        }

        direction := pressedRight ? 1 : -1

        #partial switch &type in ui.fields[ui.selectedField] {
            case Button:
                if type.func == nil {
                    rl.PlaySound(errorBlipSound)
                    break
                }
                if type.leftPress && direction == -1 do type.func(state, &type)
                else if !type.leftPress && direction == 1 do type.func(state, &type)
                else {
                    rl.PlaySound(errorBlipSound)
                    break
                }
                rl.PlaySound(blipSound2)
            case IntInput:
                inc := i32(direction) * type.stepSize
                type.value += inc
                if type.value > type.maxVal || type.value < type.minVal{
                    type.value -= inc
                    rl.PlaySound(errorBlipSound)
                    break
                }
                rl.PlaySound(blipSound2)
            case FloatInput:
                inc := f32(direction) * type.stepSize
                type.value += inc
                if type.value > type.maxVal || type.value < type.minVal{
                    type.value -= inc
                    rl.PlaySound(errorBlipSound)
                    break
                }
                rl.PlaySound(blipSound2)
            case BoolSwitch:
                if direction == -1 {
                    rl.PlaySound(errorBlipSound)
                    break
                }
                type.value = !type.value
                rl.PlaySound(blipSound2)
            case ValueSwitch:
                type.selected += direction
                if type.selected < 0 || type.selected >= len(type.values) {
                    type.selected -= direction
                    rl.PlaySound(errorBlipSound)
                    break
                }
                rl.PlaySound(blipSound2)
            case TwoSideButton:
                if direction == 1 {
                    if !type.rightSelected do type.rightSelected = true
                    else {
                        if type.rightFunc == nil {
                            rl.PlaySound(errorBlipSound)
                            break
                        }
                        type.rightFunc(state, &type)
                    }
                }
                else {
                    if type.rightSelected do type.rightSelected = false
                    else {
                        if type.leftFunc == nil {
                            rl.PlaySound(errorBlipSound)
                            break
                        }
                        type.leftFunc(state, &type)
                    }
                }
                rl.PlaySound(blipSound2)
            case ControlsInput:
                type.selected += direction
                maxSel := 1

                #partial switch &axis in type.keyBind.keyboardInput {
                    case input.InputAxis:
                        #partial switch &axisType in axis {
                            case input.VirtualAxis:
                                maxSel = 2
                        }
                }

                if type.selected < 0 || type.selected > maxSel {
                    rl.PlaySound(errorBlipSound)
                    type.selected -= direction
                    break
                }

                rl.PlaySound(blipSound2)
        }
    }

    if pressedLeftRep || pressedRightRep {
        direction := rightDown ? 1 : -1

        #partial switch &type in ui.fields[ui.selectedField] {
            case IntInput:
                inc := i32(direction) * type.stepSize
                type.value += inc
                if type.value > type.maxVal || type.value < type.minVal{
                    type.value -= inc
                    if !soundRepeatLock { 
                        rl.PlaySound(errorBlipSound)
                        soundRepeatLock = true
                    }
                }
            case FloatInput:
                inc := f32(direction) * type.stepSize
                type.value += inc
                if type.value > type.maxVal || type.value < type.minVal{
                    type.value -= inc
                    if !soundRepeatLock { 
                        rl.PlaySound(errorBlipSound)
                        soundRepeatLock = true
                    }
                }
        }
    }
}