package editor

import "../engine/level"
import im "../engine/external/imgui"
import "../engine/rendering"

import rl "vendor:raylib"
import "core:fmt"

@(private="file")
FILE_RELOAD_MODAL := false
@(private="file")
FILE_SAVE_MODAL := false
@(private="file")
WINDOW_POPUP := false

draw_main_menu_bar :: proc(levelData: ^level.LevelData) {
    if im.BeginMainMenuBar() {

        if im.BeginMenu("File") {
            if im.MenuItem("Save") do FILE_SAVE_MODAL = true
            if im.MenuItem("Reload") do FILE_RELOAD_MODAL = true
            im.EndMenu()
        }

        if im.BeginMenu("Assets") {
            if im.MenuItem("Reload Meshes") {

            }

            if im.MenuItem("Reload Materials") {

            }

            if im.MenuItem("Reload Tags") {

            }

            if im.MenuItem("Reload Skybox") {

            }
            im.EndMenu()
        }

        if im.BeginMenu("Objects") {

            if im.MenuItem("Add Empty Object") {
                append(&levelData.levelObjects, level.LevelObject{ objectName = "IDK", objectMesh = -1 })
            }

            if im.MenuItem("Remove Selected") {
                ordered_remove(&levelData.levelObjects, scenery_ObjectSelected)
                if scenery_ObjectSelected >= len(levelData.levelObjects) do scenery_ObjectSelected -= 1
            }

            im.EndMenu()
        }

        if im.BeginMenu("Windows") {
            im.MenuItemBoolPtr("Scene", "", &sceneWindowOpen)

            for &editor in CustomEditors {
                im.MenuItemBoolPtr(editor.name, "", &editor.open)
            }

            im.MenuItemBoolPtr("Meshes", "", &meshWindowOpen)
            im.MenuItemBoolPtr("Materials", "", &materialsWindowOpen)
            im.MenuItemBoolPtr("Textures", "", &texturesWindowOpen)

            im.EndMenu()
        }

        if FILE_SAVE_MODAL {
            im.OpenPopup("Save?")
            FILE_SAVE_MODAL = false
        }

        center := im.Viewport_GetCenter(im.GetMainViewport())
        im.SetNextWindowPos(center, im.Cond.Appearing, { 0.5, 0.5 })
        if im.BeginPopupModal("Save?", nil, { im.WindowFlag.AlwaysAutoResize }) {
            im.Text("You will overwrite the original file")
            im.Spacing()
            im.Spacing()
            if im.Button("Proceed", { 120, 0 }) {
                im.CloseCurrentPopup()
            }
            im.SetItemDefaultFocus()
            im.SameLine()
            if im.Button("Cancel", { 120, 0 }) {
                im.CloseCurrentPopup()
            }

            im.EndPopup()
        }

        
        if FILE_RELOAD_MODAL {
            im.OpenPopup("Reload?")
            FILE_RELOAD_MODAL = false
        }

        if im.BeginPopupModal("Reload?", nil, { im.WindowFlag.AlwaysAutoResize }) {
            im.Text("You will lose any changes made to\nthe scene")
            im.Spacing()
            im.Spacing()
            if im.Button("Proceed", { 120, 0 }) {
                im.CloseCurrentPopup()
            }
            im.SetItemDefaultFocus()
            im.SameLine()
            if im.Button("Cancel", { 120, 0 }) {
                im.CloseCurrentPopup()
            }

            im.EndPopup()
        }

        im.EndMainMenuBar()
    }
}