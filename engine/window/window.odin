package window

import "core:fmt"
import "core:mem"
import "vendor:raylib"
import imgui_rl "../external/imgui/imgui_impl_raylib"
import im "../external/imgui"

@(private)
clearColor: raylib.Color = raylib.RAYWHITE

@(private)
ImGUI :: struct {
    listen_key: i32,
    open: bool,
    guiFunc: proc()
}

/*
@(private)
DEBUG_GUIS: map[u8]ImGUI
@(private)
NEXT_GUI_HANDLE: u8 = 0
*/

@(private)
tracking_alloc: mem.Tracking_Allocator

setup_window :: proc(title: cstring, target_fps: i32 = 60, width: i32 = 1240, height: i32 = 720, init_callback: proc() = nil) {
    raylib.InitWindow(width, height, title)
    raylib.SetExitKey(.KEY_NULL)

    if init_callback != nil do init_callback()

    raylib.SetTargetFPS(target_fps)
}

init_window :: proc(update_callback: proc() = nil, render_callback: proc() = nil, lateUpdate_callback: proc() = nil, exit_callback: proc() = nil) {
    
    when ODIN_DEBUG {
        /*
        DEBUG_GUIS = make(map[u8]ImGUI)
        glfw.SetKeyCallback(cast(glfw.WindowHandle)raylib.GetWindowHandle(), key_callback)
        */
        mem.tracking_allocator_init(&tracking_alloc, context.allocator)
        context.allocator = mem.tracking_allocator(&tracking_alloc)

        im.CreateContext(nil)
        imgui_rl.init()
        imgui_rl.build_font_atlas()
    }

    for !raylib.WindowShouldClose() {
        when ODIN_DEBUG {
            imgui_rl.process_events()
            imgui_rl.new_frame()
            im.NewFrame()
        }
        
        if update_callback != nil do update_callback()

        raylib.BeginDrawing()
        raylib.ClearBackground(clearColor);

        if render_callback != nil do render_callback()

        when ODIN_DEBUG {
            raylib.DrawText("DEBUG_V_0.1", 20, 20, 10, raylib.BLACK)

            im.Render()
            imgui_rl.render_draw_data(im.GetDrawData())
        }
        raylib.EndDrawing()

        if lateUpdate_callback != nil do lateUpdate_callback()

        free_all(context.temp_allocator)
    }

    if exit_callback != nil do exit_callback()
    
    when ODIN_DEBUG {
        imgui_rl.shutdown()
        im.DestroyContext(nil)
        //delete(DEBUG_GUIS)

        leaks := false
        totalLeakage := 0
        for _, value in tracking_alloc.allocation_map {
            fmt.printfln("%v: Leaked %v bytes", value.location, value.size)
            totalLeakage += value.size
            leaks = true
        }

        if leaks do fmt.printfln("Program leaked a total of %v at %v leaks", totalLeakage, len(tracking_alloc.allocation_map))
        mem.tracking_allocator_clear(&tracking_alloc)
    }

    raylib.CloseWindow()
}

set_clearColor_raw :: proc(color: [4]u8) {
    set_clearColor(transmute(raylib.Color)color)
}

set_clearColor :: proc(color: raylib.Color) {
    clearColor = color
}

/*
@(private)
key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
    context = runtime.default_context()
    if action != glfw.PRESS do return

    for handle, &value in DEBUG_GUIS {
        if value.listen_key != key do continue
        value.open = !value.open
    }
}

register_gui :: proc(open_key: i32, gui_function: proc(), default_open: bool = true) -> (handle: u8) {
    when !ODIN_DEBUG do return 0
    DEBUG_GUIS[NEXT_GUI_HANDLE] = {
        listen_key = open_key,
        guiFunc = gui_function,
        open = default_open
    }
    handle = NEXT_GUI_HANDLE
    
    for i : u8 = 0; i < 255; i += 1 {
        taken := i in DEBUG_GUIS
        if taken do continue

        NEXT_GUI_HANDLE = i
        break
    }

    return
}

unregister_gui :: proc(gui_handle: u8) {
    when !ODIN_DEBUG do return
    if gui_handle == 0 do return

    ok := gui_handle in DEBUG_GUIS
    if !ok do return

    delete_key(&DEBUG_GUIS, gui_handle)
    NEXT_GUI_HANDLE = gui_handle
}
    */