package window

import "core:fmt"
import "core:mem"
import "vendor:raylib"
import imgui_rl "../external/imgui/imgui_impl_raylib"
import im "../external/imgui"
import "../input"
import "../level"
import "../rendering"
import "../../editor"

@(private)
windowTitle: cstring

@(private)
clearColor: raylib.Color = raylib.RAYWHITE

@(private)
shouldClose: bool = false

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
    windowTitle = title
    
    raylib.InitWindow(width, height, title)
    raylib.SetExitKey(.KEY_NULL)

    raylib.InitAudioDevice()

    level.init_level_system()

    if init_callback != nil do init_callback()

    if target_fps > 0 {
        raylib.SetTargetFPS(target_fps)
    }
}

set_close :: proc() {
    shouldClose = true
}

init_window :: proc(update_callback: proc() = nil, render_callback: proc() = nil, lateUpdate_callback: proc() = nil, exit_callback: proc() = nil) {

    when ODIN_DEBUG {
        mem.tracking_allocator_init(&tracking_alloc, context.allocator)
        context.allocator = mem.tracking_allocator(&tracking_alloc)

        im.CreateContext(nil)
        imgui_rl.init(input.setup_debug_input)
        imgui_rl.build_font_atlas()

        editor.init_editor()
    }

    for !raylib.WindowShouldClose() && !shouldClose {

        when ODIN_DEBUG {
            imgui_rl.new_frame()
            imgui_rl.process_events()
            im.NewFrame()

            newTitle := fmt.caprintf("%v --- FPS: %v", windowTitle, raylib.GetFPS())
            raylib.SetWindowTitle(newTitle)
            delete(newTitle)
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
        editor.destroy_editor()

        imgui_rl.shutdown()
        im.DestroyContext(nil)
        //delete(DEBUG_GUIS)

        if len(tracking_alloc.allocation_map) > 0 {
            fmt.eprintf("=== %v allocations not freed: ===\n", len(tracking_alloc.allocation_map))
            for _, entry in tracking_alloc.allocation_map {
                fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
            }
        }
        else do fmt.printf("=== NO BAD ALLOCATIONS FOUND\n")
        if len(tracking_alloc.bad_free_array) > 0 {
            fmt.eprintf("=== %v incorrect frees: ===\n", len(tracking_alloc.bad_free_array))
            for entry in tracking_alloc.bad_free_array {
                fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
            }
        }
        else do fmt.printf("=== NO BAD FREES FOUND\n")

        mem.tracking_allocator_destroy(&tracking_alloc)
    }

    rendering.destory_render_futures()
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