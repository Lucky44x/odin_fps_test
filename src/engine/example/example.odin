package example

import imgui_rl "../external/imgui/imgui_impl_raylib"
import imgui "../external/imgui"

import rl "vendor:raylib"

import "../input"

main :: proc() {
    rl.SetConfigFlags({ rl.ConfigFlag.WINDOW_RESIZABLE })
    rl.InitWindow(800, 600, "raylib basic window")
    defer rl.CloseWindow()

    imgui.CreateContext(nil)
	defer imgui.DestroyContext(nil)

    imgui_rl.init(input.setup_debug_input)
	defer imgui_rl.shutdown()

    imgui_rl.build_font_atlas()

    for !rl.WindowShouldClose() {
		imgui_rl.process_events()
		imgui_rl.new_frame()
		imgui.NewFrame()

        rl.BeginDrawing()
		rl.ClearBackground(rl.RAYWHITE)

        imgui.ShowDemoWindow(nil)

        imgui.Render()
		imgui_rl.render_draw_data(imgui.GetDrawData())

        rl.EndDrawing()
    }
}