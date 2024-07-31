package editor

import "../engine/level"
import im "../engine/external/imgui"
import "../engine/rendering"
import "../engine/math/mathf"
import cam "../engine/camera"
import "../engine/transform"

import rl "vendor:raylib"
import rlgl "vendor:raylib/rlgl"
import "core:fmt"
import "core:math"
import "core:math/linalg"

@(private)
scenery_ObjectSelected := -1
@(private="file")
draggingAxis := -1
@(private="file")
draggingOffsetVector: mathf.vec3 = {}

draw_scenery_editor_gui :: proc(scenery: ^level.LevelData) {
    im.Begin("Level-Objects", &sceneWindowOpen)

    levelCName := fmt.caprintf("%s", scenery.levelName)
    im.SeparatorText(levelCName)

    im.BeginChild("Objects", { im.GetContentRegionAvail()[0] / 3, im.GetContentRegionAvail()[1] }, {}, { im.WindowFlag.HorizontalScrollbar })

    for objInd := 0; objInd < len(scenery.levelObjects); objInd += 1 {
        obj := &scenery.levelObjects[objInd]
        
        objCname := fmt.caprintf("%v", obj.objectName)
        if im.Selectable(objCname, scenery_ObjectSelected == objInd) do select_scenery_object(scenery, objInd)

        delete(objCname)
    }
    im.EndChild()
    im.SameLine()
    im.BeginChild("Selected Object", { im.GetContentRegionAvail()[0], im.GetContentRegionAvail()[1] }, {}, {})
    if scenery_ObjectSelected != -1 {
        obj := &scenery.levelObjects[scenery_ObjectSelected]
        im.Text("Name: %s", obj.objectName)
    
        imgui_transform_inspector(&obj.objectTransform)
        if im.Button("Invalidate Transform") do level.invalidate_level_obj(obj, scenery)
        
        
        if obj.objectMesh == -1 do rendering.add_3D_future(rendering.CubeWires{ obj.objectTransform.position, { 0.5, 0.5, 0.5 }, rl.RED })
        else do rendering.add_3D_future(rendering.Box{ obj.boundingBox, rl.RED })
    
        im.SeparatorText("Metadata")
        
        tag_mask_gui(&obj.objectTags, scenery)
        im.SameLine()
        im.Checkbox("Collision", &obj.collision)
    
        if im.Button("Mesh") do im.OpenPopup("object_mesh_popup")
        if im.IsItemClicked(im.MouseButton.Middle) do select_mesh(obj.objectMesh, scenery)
        im.SameLine()
        if im.Button("Material") do im.OpenPopup("object_material_popup")
        if im.IsItemClicked(im.MouseButton.Middle) do select_material_and_mesh(obj.objectMaterial, obj.objectMesh, scenery)
    
        if im.BeginPopup("object_material_popup") {
            if im.Selectable("None", obj.objectMaterial == -1) do obj.objectMaterial = -1
    
            for i := 0; i < len(scenery.levelMaterials); i += 1 {
                materialCName := fmt.caprintf("%v", scenery.levelMaterials[i].name)
                if im.Selectable(materialCName, obj.objectMaterial == i) do obj.objectMaterial = i
                if im.IsItemClicked(im.MouseButton.Middle) do select_material_and_mesh(i, obj.objectMesh, scenery)
                delete(materialCName)
            }
            im.EndPopup()
        }
    
        if im.BeginPopup("object_mesh_popup") {
            if im.Selectable("None", obj.objectMesh == -1) do obj.objectMesh = -1
    
            for i := 0; i < len(scenery.levelMeshes); i += 1 {
                meshCName := fmt.caprintf("%v", scenery.levelMeshes[i].name)
                if im.Selectable(meshCName, obj.objectMesh == i) do obj.objectMesh = i
                if im.IsItemClicked(im.MouseButton.Middle) do select_mesh(i, scenery)
                delete(meshCName)
            }
            im.EndPopup()
        }
    }
    else {
        im.Text("NONE")
    }
    im.EndChild()

    check_cursor_inside_imgui_window()
    im.End()
    delete(levelCName)
}

draw_scenery_gizmos :: proc(scenery: ^level.LevelData) {
    draw_empty_objects(scenery)
    draw_arrow_handles(scenery)
}

@(private="file")
select_scenery_object :: proc(scenery: ^level.LevelData, selectedObject: int) {
    if scenery_ObjectSelected == selectedObject do return

    sceneWindowOpen = true
    scenery_ObjectSelected = selectedObject
    generate_arrow_matricies(scenery)
}

@(private="file")
generate_arrow_matricies :: proc(scenery: ^level.LevelData) {
    if scenery_ObjectSelected == -1 do return

    obj := &scenery.levelObjects[scenery_ObjectSelected]
    for axis := 0; axis < 3; axis += 1 {
        angles: mathf.vec3 = { 0, 0, 0 }
        angles[axis] = 1
        angles *= (90 * math.RAD_PER_DEG)

        transMat := rl.MatrixTranslate(obj.objectTransform.position[0], obj.objectTransform.position[1], obj.objectTransform.position[2])
        transMat *= rl.MatrixRotateZYX(angles)

        arrowModels[axis] = rl.LoadModelFromMesh(arrowMesh)
        arrowModels[axis].transform = transMat
    }
}

@(private="file")
draw_empty_objects :: proc(scenery: ^level.LevelData) {
    for obj in scenery.levelObjects {
        if obj.objectMesh == -1 {
            rl.DrawSphereWires(obj.objectTransform.position, 0.05, 8, 8, rl.BLACK)
            rl.DrawLine3D(obj.objectTransform.position, obj.objectTransform.position + { 1, 0, 0}, rl.RED)
            rl.DrawLine3D(obj.objectTransform.position, obj.objectTransform.position + { 0, 1, 0}, rl.GREEN)
            rl.DrawLine3D(obj.objectTransform.position, obj.objectTransform.position + { 0, 0, 1}, rl.BLUE)
        }
    }
}

@(private="file")
get_axis_holding_offset :: proc(scenery: ^level.LevelData, camera: ^cam.Camera) {
    if scenery_ObjectSelected == -1 do return

    draggingOffsetVector = scenery.levelObjects[scenery_ObjectSelected].objectTransform.position - project_cursor_to_axis(scenery, camera)
}

@(private="file")
project_cursor_to_axis :: proc(scenery: ^level.LevelData, camera: ^cam.Camera) -> mathf.vec3 {
    if scenery_ObjectSelected == -1 do return { 0, 0, 0 }

    obj := &scenery.levelObjects[scenery_ObjectSelected]

    objectScreenPos := rl.GetWorldToScreen(obj.objectTransform.position, camera.viewCamera)
    axisVector: mathf.vec3
    axisVector[draggingAxis] = 1

    handleScreenPos := rl.GetWorldToScreen(obj.objectTransform.position + axisVector, camera.viewCamera)
    directionVector := linalg.vector_normalize0(handleScreenPos - objectScreenPos)

    mousePos := rl.GetMousePosition()
    mouseDirectionVector := mousePos - objectScreenPos

    //rendering.add_2D_future(rendering.Line2D{ objectScreenPos + directionVector * 1000, objectScreenPos - directionVector * 1000, rl.BLACK })
    //rendering.add_2D_future(rendering.Line2D{ objectScreenPos, mousePos, rl.BLACK })

    //Project onto screen-space-axis
    normal := mathf.vec2{ directionVector[1], -directionVector[0] }

    directionMag := linalg.vector_length2(directionVector)
    distScalar := mouseDirectionVector[0] * normal[0] + mouseDirectionVector[1] * normal[1]
    projectedPoint := mouseDirectionVector - distScalar * normal

    rendering.add_2D_future(rendering.Circle{ objectScreenPos + projectedPoint, 2, rl.RED })

    //Get World-Space Ray
    worldRay := rl.GetMouseRay(objectScreenPos + projectedPoint, camera.viewCamera)
    translatedRayPoint := worldRay.position - obj.objectTransform.position

    dist : f32 = 0
    for axis := 0; axis < 3; axis += 1 {
        if axis == draggingAxis do continue
        dist = translatedRayPoint[axis] / worldRay.direction[axis]
        dist *= -1
        break
    }

    worldPos := worldRay.position + (worldRay.direction * dist)
    return worldPos
}

update_scenery_editor :: proc(scenery: ^level.LevelData, camera: ^cam.Camera) {
    if IsAnyWindowHovered do return

    if rl.IsMouseButtonReleased(rl.MouseButton.LEFT) && draggingAxis != -1 && scenery_ObjectSelected != -1 {
        draggingAxis = -1
    }
    else if rl.IsMouseButtonDown(rl.MouseButton.LEFT) && draggingAxis != -1 && scenery_ObjectSelected != -1 {
        if scenery_ObjectSelected == -1 {
            draggingAxis = -1
            return
        }

        moveDir := mathf.vec3{ 0, 0, 0 }
        moveDir[draggingAxis] = 1
        scenery.levelObjects[scenery_ObjectSelected].objectTransform.position = project_cursor_to_axis(scenery, camera) + draggingOffsetVector
        level.invalidate_level_obj(&scenery.levelObjects[scenery_ObjectSelected], scenery)
    }

    //If Dragging, block all other input
    if draggingAxis != -1 do return

    if rl.IsKeyPressed(rl.KeyboardKey.F) && scenery_ObjectSelected != -1{
        cam.look_at(camera, scenery.levelObjects[scenery_ObjectSelected].objectTransform.position)
    }

    if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
        ray := rl.GetMouseRay(rl.GetMousePosition(), camera.viewCamera)

        //First, check for ArrowHandle interaction
        for axis := 0; axis < 3; axis += 1 {
            if scenery_ObjectSelected == -1 do break

            obj := scenery.levelObjects[scenery_ObjectSelected]
            meshIntersect := rl.GetRayCollisionMesh(ray, arrowMesh, arrowModels[axis].transform)
            if !meshIntersect.hit do continue

            draggingAxis = axis
            get_axis_holding_offset(scenery, camera)
            return
        }

        for &obj, ind in scenery.levelObjects {

            if obj.objectMesh == -1 {
                rayEmptySphereCollision := rl.GetRayCollisionSphere(ray, obj.objectTransform.position, 0.25)
                if !rayEmptySphereCollision.hit do continue

                scenery_ObjectSelected = ind
                return
            }

            rayBoxCollision := rl.GetRayCollisionBox(ray, obj.boundingBox)
            if !rayBoxCollision.hit do continue

            rayMeshCollision := rl.GetRayCollisionMesh(ray, scenery.levelMeshes[obj.objectMesh].mesh, obj.objectTransform.transformMatrix)
            if !rayMeshCollision.hit do continue

            scenery_ObjectSelected = ind
            return
        }

        scenery_ObjectSelected = -1
    }
}

@(private="file")
draw_arrow_handles :: proc(scenery: ^level.LevelData) {
    if scenery_ObjectSelected == -1 do return

    rlgl.DisableDepthTest()
        
    generate_arrow_matricies(scenery)
    rl.DrawSphere(scenery.levelObjects[scenery_ObjectSelected].objectTransform.position, 0.05, rl.BLACK)

    for i := 0; i < 3; i += 1 {
        rl.DrawModel(arrowModels[i], { 0, 0 ,0 }, 1, axisColors[i])
    }
    
    rlgl.EnableDepthTest()
}