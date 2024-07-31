package editor

import "../engine/level"
import im "../engine/external/imgui"
import "../engine/rendering"

import rl "vendor:raylib"
import "core:fmt"

@(private)
texture_TextureSelectedIndex := -1
@(private="file")
texture_selected_gpu_id : u32 = 0

select_texture :: proc(selectedTexture: int, levelData: ^level.LevelData) {
    texture_selected_gpu_id = levelData.levelTextures[selectedTexture].texture.id
    texture_TextureSelectedIndex = selectedTexture
}

draw_texture_editor_gui :: proc(levelData: ^level.LevelData) {
    im.Begin("Level-Textures", &texturesWindowOpen)
    levelCName := fmt.caprintf("%s", levelData.levelName)
    im.SeparatorText(levelCName)

    im.BeginChild("Textures", { im.GetContentRegionAvail()[0] / 3, im.GetContentRegionAvail()[1] }, {}, { im.WindowFlag.HorizontalScrollbar })
    for texInd := 0; texInd < len(levelData.levelTextures); texInd += 1 {
        texture := &levelData.levelTextures[texInd]
        
        texCname := fmt.caprintf("%v", texture.name)
        if im.Selectable(texCname, texture_TextureSelectedIndex == texInd) do select_texture(texInd, levelData)

        delete(texCname)
    }
    im.EndChild()
    im.SameLine()
    im.BeginChild("Selected Texture", { im.GetContentRegionAvail()[0], im.GetContentRegionAvail()[1] }, {}, {})

    name := texture_TextureSelectedIndex == -1 ? "NAN" : levelData.levelTextures[texture_TextureSelectedIndex].source
    im.Text("Source: %s", name)

    size := im.GetContentRegionAvail()
    minSize := min(size[0], size[1])
    if texture_TextureSelectedIndex != -1 do im.Image(&texture_selected_gpu_id, { minSize, minSize }, { 0, 1 }, { 1, 0 })

    im.EndChild()

    check_cursor_inside_imgui_window()
    im.End()
    delete(levelCName)
}