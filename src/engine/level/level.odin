package level

import "../external/gltf2"
import "../math/mathf"
import "../transform"

import "core:encoding/json"
import rl "vendor:raylib"
import "core:strings"
import "core:path/filepath"
import "core:fmt"
import "core:math"
import "core:os"

LevelError :: union {
    LevelIOError,
    LevelJSONError
}

LevelIOError :: struct {
    message: string
}

LevelJSONError :: struct {
    message: string
}

LevelMesh :: struct {
    name: string,
    mesh: rl.Mesh,
    source: cstring
}

LevelTexture :: struct {
    name: string,
    texture: rl.Texture2D,
    source: cstring
}

LevelMaterial :: struct {
    name: string,
    material: rl.Material,
    vertSource: cstring,
    fragSource: cstring
}

LevelSkybox :: union {
    rl.Model,
    rl.Color
}

TagMask :: bit_set[i32(0)..=31; i32]

LevelObject :: struct {
    objectName: string,
    objectTags: TagMask,
    objectTransform: transform.Transform,
    cachedTransform: rl.Matrix,
    boundingBox: rl.BoundingBox,
    objectMesh: int,
    objectMaterial: int,
    collision: bool
}

LevelData :: struct {
    skybox: LevelSkybox,
    levelName: string,
    levelTags: [64]string,
    usedTags: int,
    levelTextures: []LevelTexture,
    levelMaterials: []LevelMaterial,
    levelMeshes: []LevelMesh,
    levelObjects: [dynamic]LevelObject
}

init_level_system :: proc() {
    init_skybox_system()
}

apply_tags_and_materials :: proc(level: ^LevelData) {

}

get_objects_by_tag :: proc(mask: TagMask, level: ^LevelData) -> []^LevelObject {
    objects: [dynamic]^LevelObject = make([dynamic]^LevelObject)
    for &obj, ind in level.levelObjects {
        if card(obj.objectTags & mask) == 0 do continue

        append(&objects, &obj)
    }

    retArray := objects[:]
    delete(objects)
    return retArray
}

invalidate_level_objects :: proc(level: ^LevelData) {
    for &obj, ind in level.levelObjects {
        if obj.cachedTransform == obj.objectTransform.transformMatrix do continue
        invalidate_level_obj(&obj, level)
    }
}

invalidate_level_obj :: proc(obj: ^LevelObject, level: ^LevelData) {
    if obj.objectMesh == -1 do return

    mesh := level.levelMeshes[obj.objectMesh]
    boundingBox := rl.GetMeshBoundingBox(mesh.mesh)

    boundingBox.max *= obj.objectTransform.scale
    boundingBox.min *= obj.objectTransform.scale

    rotX := math.mod(obj.objectTransform.rotation[0], 90) / 90
    rotY := math.mod(obj.objectTransform.rotation[1], 90) / 90
    rotZ := math.mod(obj.objectTransform.rotation[2], 90) / 90
    rotTransform := mathf.vec3{ 
        1 - (rotZ - rotY),
        1 - (rotX - rotZ),
        1 - (rotX - rotY)
    }

    boundingBox.max *= rotTransform
    boundingBox.min *= rotTransform

    boundingBox.max += obj.objectTransform.position
    boundingBox.min += obj.objectTransform.position

    obj.boundingBox = boundingBox

    transform.update_transform(&obj.objectTransform)
    obj.cachedTransform = obj.objectTransform.transformMatrix
}

generate_matrix_from_vectors :: proc(translation, rotation, scaling: mathf.vec3) -> rl.Matrix {
    mat: rl.Matrix = rl.MatrixTranslate(
        translation[0],
        translation[1],
        translation[2]
    )

    mat *= rl.MatrixRotateXYZ(rotation)

    mat *= rl.MatrixScale(
        scaling[0],
        scaling[1],
        scaling[2]
    )

    return mat
}

reload_texture :: proc(texture: ^LevelTexture) {
    //TODO Reload texture
}

reload_mesh :: proc(mesh: ^LevelMesh) {
    //TODO Reload mesh
}

render_instanced_objects :: proc(levelData: ^LevelData) {
    drawRecord: []bool = make([]bool, len(levelData.levelObjects))
    matricies: [dynamic]rl.Matrix = make([dynamic]rl.Matrix)

    for &material, matInd in levelData.levelMaterials {
        for mesh, meshInd in levelData.levelMeshes {
            clear(&matricies)
            instances: i32 = 0

            for &obj, objInd in levelData.levelObjects {
                if drawRecord[objInd] do continue
                if obj.objectMesh != meshInd do continue
                if obj.objectMaterial != matInd do continue
    
                instances += 1
                drawRecord[objInd] = true
                append(&matricies, obj.objectTransform.transformMatrix)
            }

            if instances <= 0 do continue

            //TODO: Wont Draw AND breaks viewport GUIs
            rl.DrawMeshInstanced(mesh.mesh, material.material, raw_data(matricies[:]), instances)
        }
    }

    delete(matricies)
    delete(drawRecord)
}

load_level_from_disk :: proc(mapDir: string) -> (level: LevelData, err: LevelError) {
    descriptorFile := filepath.join({ mapDir, "map.json" })
    descriptorData, ok := os.read_entire_file_from_filename(descriptorFile)
    if !ok {
        err = LevelIOError{ fmt.aprintf("Could not read mapfile: %v", descriptorFile) }
        return
    }
    defer delete(descriptorData)

    json_data, jErr := json.parse(descriptorData)
    if err != nil {
        err = LevelJSONError{ fmt.aprintf("Could not parse descriptor: %v ... error: %v", descriptorFile, jErr) }
        return
    }
    defer json.destroy_value(json_data)

    //ROOT
    jRoot := json_data.(json.Object)
    level.levelName = fmt.aprintf("%s", jRoot["name"].(json.String))

    fileTags := jRoot["tags"].(json.Array)
    if len(fileTags) > 64 do fmt.eprintf("[ERROR]: Cannot handle more than 64 tags")
    level.usedTags = len(fileTags)

    for ind := 0; ind < len(fileTags); ind += 1 {
        level.levelTags[ind] = fmt.aprintf("%f", fileTags[ind].(json.String))
    }

    fileSkybox, skyboxOk := jRoot["skybox"]
    if skyboxOk {
        skyboxObj := fileSkybox.(json.Object)
        skyBoxColorRaw, skyboxColorMode := skyboxObj["color"]
        if skyboxColorMode {
            skyboxColorArray := skyBoxColorRaw.(json.Array)
            skyboxColor: rl.Color

            for colorValRaw, ind in skyboxColorArray {
                skyboxColor[ind] = u8(colorValRaw.(json.Float))
            }
            
            level.skybox = skyboxColor
        }
        else {
            skyboxTexture := filepath.join({ mapDir, skyboxObj["cubemap"].(json.String) })
            skyboxVert := filepath.join({ mapDir, skyboxObj["vertex-shader"].(json.String) })
            skyboxFrag := filepath.join({ mapDir, skyboxObj["fragment-shader"].(json.String) })
    
            skyboxTextPath := strings.clone_to_cstring(skyboxTexture)
            skyboxVertPath := strings.clone_to_cstring(skyboxVert)
            skyboxFragPath := strings.clone_to_cstring(skyboxFrag)
            defer delete(skyboxTextPath)
            defer delete(skyboxFragPath)
            defer delete(skyboxVertPath)
    
            level.skybox, err = load_skybox(skyboxTextPath, skyboxVertPath, skyboxFragPath)
            if err != nil {
                fmt.eprintln(err)
                level.skybox = nil
            }
        }
    }
    else{
        level.skybox = nil
    }

    fileTextures := jRoot["textures"].(json.Array)
    level.levelTextures = make([]LevelTexture, len(fileTextures))

    for rawTexture, ind in fileTextures {
        obj := rawTexture.(json.Object)
        level.levelTextures[ind].name = fmt.aprintf("%s", obj["name"].(json.String))

        texSource := filepath.join({ mapDir, obj["src"].(json.String) })
        level.levelTextures[ind].source = strings.clone_to_cstring(texSource)

        level.levelTextures[ind].texture = rl.LoadTexture(level.levelTextures[ind].source)
    }

    fileMaterials := jRoot["materials"].(json.Array)
    level.levelMaterials = make([]LevelMaterial, len(fileMaterials))

    for rawMaterial, ind in fileMaterials {
        obj := rawMaterial.(json.Object)
        level.levelMaterials[ind].name = fmt.aprintf("%s", obj["name"].(json.String))
        level.levelMaterials[ind].material = rl.LoadMaterialDefault()
        
        vsFilePath := filepath.join({ mapDir, obj["vertex-shader"].(json.String) })
        fsFilePath := filepath.join({ mapDir, obj["fragment-shader"].(json.String) })
        vsFilePathC := strings.clone_to_cstring(vsFilePath, context.temp_allocator)
        fsFilePathC := strings.clone_to_cstring(fsFilePath, context.temp_allocator)
        level.levelMaterials[ind].fragSource = fsFilePathC
        level.levelMaterials[ind].vertSource = vsFilePathC

        level.levelMaterials[ind].material.shader = rl.LoadShader(vsFilePathC, fsFilePathC)
        
        fileTexMaps := obj["texture-maps"].(json.Array)
        for rawTexMap in fileTexMaps {
            texMapObj := rawTexMap.(json.Object)
            texMapIndex := texMapObj["map-index"]
            mapIndex : i32 = 0

            #partial switch type in texMapIndex {
                case json.Float:
                    mapIndex = i32(type)
                    break
                case json.String:
                    mapIndex = texture_map_name_to_index(type)
                    break
            }

            colorRaw, colorOK := texMapObj["color"].(json.Array)
            if colorOK {
                color: rl.Color = rl.WHITE

                for colorOBJ, ind in colorRaw {
                    color[ind] = u8(colorOBJ.(json.Float))
                }

                level.levelMaterials[ind].material.maps[mapIndex].color = color
            }

            textureIndex, textureIndexOK := texMapObj["texture"].(json.Float)
            if textureIndexOK {
                level.levelMaterials[ind].material.maps[mapIndex].texture = level.levelTextures[int(textureIndex)].texture
            }

            dataRaw, dataOK := texMapObj["data"].(json.Float)
            if dataOK {
                level.levelMaterials[ind].material.maps[mapIndex].value = f32(dataRaw)
            }
        }
    }

    fileMeshes := jRoot["meshes"].(json.Array)
    level.levelMeshes = make([]LevelMesh, len(fileMeshes) + 2)

    for rawMesh, ind in fileMeshes {
        obj := rawMesh.(json.Object)

        level.levelMeshes[ind].name = fmt.aprintf("%s", obj["name"].(json.String))
        
        meshSource := obj["src"].(json.String)

        if strings.contains(meshSource, ":") {
            parts, _ := strings.split(meshSource, ":", context.temp_allocator)
            if parts[0] == "primitive" {
                switch parts[1] {
                    case "plane": level.levelMeshes[ind].mesh = rl.GenMeshPlane(1, 1, 5, 5)
                    case "cube": level.levelMeshes[ind].mesh = rl.GenMeshCube(1, 1, 1)
                    case "cylinder": level.levelMeshes[ind].mesh = rl.GenMeshCylinder(1, 1, 32)
                    case "sphere": level.levelMeshes[ind].mesh = rl.GenMeshSphere(1, 32, 32)
                }
            }
            else if parts[0] == "heightmap" {
                heightmapPath := filepath.join({ mapDir, parts[1] })
                heightmapPathC := strings.clone_to_cstring(heightmapPath, context.temp_allocator)
                hghtMp := rl.LoadImage(heightmapPathC)

                level.levelMeshes[ind].mesh = rl.GenMeshHeightmap(hghtMp, { 1, 1, 1 })
                rl.UnloadImage(hghtMp)
            }
        }
        else {
            meshSource = filepath.join({ mapDir, meshSource })
            meshSourceC := strings.clone_to_cstring(meshSource, context.temp_allocator)
            level.levelMeshes[ind].source = meshSourceC

            level.levelMeshes[ind].mesh = rl.LoadModel(meshSourceC).meshes[0]
        }

        meshSourceC := strings.clone_to_cstring(meshSource)
        level.levelMeshes[ind].source = meshSourceC
    }

    level.levelMeshes[len(level.levelMeshes) - 2] = {
        name = "MATERIAL_PREVIEW_SPHERE",
        mesh = rl.GenMeshSphere(1, 32, 32),
        source = "primitive:sphere"
    }

    level.levelMeshes[len(level.levelMeshes) - 1] = {
        name = "MATERIAL_PREVIEW_CUBE",
        mesh = rl.GenMeshCube(1, 1, 1),
        source = "primitive:cube"
    }

    fileObjects := jRoot["objects"].(json.Array)
    level.levelObjects = make([dynamic]LevelObject)

    for rawOBJ, ind in fileObjects {
        obj := rawOBJ.(json.Object)
        levelObject := LevelObject{}

        objectName := obj["name"].(json.String)
        levelObject.objectName = fmt.aprintf("%s", objectName)

        meshTagArray := obj["tags"].(json.Array)
        for val, tagInd in meshTagArray {
            rawTag := val.(json.Float)
            if rawTag > 31 do continue
            tagId := i32(rawTag)
            
            levelObject.objectTags = levelObject.objectTags + TagMask{ tagId }
        }

        objectPositionArray := obj["pos"].(json.Array)
        pos: mathf.vec3
        pos[0] = f32(objectPositionArray[0].(json.Float))
        pos[1] = f32(objectPositionArray[1].(json.Float))
        pos[2] = f32(objectPositionArray[2].(json.Float))
        levelObject.objectTransform.position = pos

        objectRotationArray := obj["rot"].(json.Array)
        rot: mathf.vec3
        rot[0] = f32(objectRotationArray[0].(json.Float))
        rot[1] = f32(objectRotationArray[1].(json.Float))
        rot[2] = f32(objectRotationArray[2].(json.Float))
        levelObject.objectTransform.rotation = rot

        levelObject.objectMesh = int(obj["mesh"].(json.Float))
        levelObject.objectMaterial = int(obj["material"].(json.Float))

        levelObject.collision = obj["collision"].(json.Boolean)

        objectSizeArray := obj["size"].(json.Array)
        scale: mathf.vec3
        scale[0] = f32(objectSizeArray[0].(json.Float))
        scale[1] = f32(objectSizeArray[1].(json.Float))
        scale[2] = f32(objectSizeArray[2].(json.Float))
        levelObject.objectTransform.scale = scale

        transform.update_transform(&levelObject.objectTransform)

        append(&level.levelObjects, levelObject)
    }

    return
}

texture_map_name_to_index :: proc (mapName: string) -> i32 {
    switch strings.to_upper(mapName) {
        case "DIFFUSE": fallthrough
        case "ALBEDO": return 0
        case "METAL": fallthrough
        case "METALLNESS": return 1
        case "NORMAL": return 2
        case "ROUGHNESS": fallthrough
        case "ROUGH": return 3
        case "OCCLUSION": return 4
        case "EMISSION": return 5
        case "HEIGHT": return 6
        case "CUBEMAP": return 7
        case "IRRADIANCE": return 8
        case "PREFILTER": return 9
        case "BRDF": return 10
    }

    return 0
}