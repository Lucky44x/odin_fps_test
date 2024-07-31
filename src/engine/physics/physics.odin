package physics

import "core:math/linalg"
import "../math/mathf"
import el "../level"
import "../rendering"

import "core://fmt"
import "core:math"

import rl "vendor:raylib"

MAX_BOUNCES :: 4
RAY_RESOLUTION :: 9
DEG2RAD :: 0.017453292

CharacterController :: struct {
    position, forward, right: ^mathf.vec3,
    height, width, maxCollisionDist, maxSlopeAngle: f32,
    groundTagMask: el.TagMask, collisionTagMask: el.TagMask,
    currentSlopeAngle: f32,
    isGrounded: bool
}

CollisionInfo :: struct {
    collides: bool,
    collisionHit: rl.RayCollision,
    collisionObject: ^el.LevelObject
}

link_controller :: proc(position_pointer, forward_pointer, right_pointer: ^mathf.vec3, controller: ^CharacterController) {
    if controller.position != nil do return

    controller.position = position_pointer
    controller.forward = forward_pointer
    controller.right = right_pointer
}

update_level_objects :: proc(level: ^el.LevelData) {
    el.invalidate_level_objects(level)
}

apply_gravity :: proc(gravity_value: f32, character: ^CharacterController, scenery: ^el.LevelData) {
    finalTranslation := mathf.vec3{ 0, 0, 0 }
    angle, ok := get_slope_angle(character, scenery)

    character.isGrounded = ok
    character.currentSlopeAngle = angle * math.DEG_PER_RAD

    maxBounceIndex := character.currentSlopeAngle <= character.maxSlopeAngle ? 0 : MAX_BOUNCES

    finalTranslation = do_gravity_collision(mathf.vec3{ 0, -gravity_value, 0 }, character, scenery, maxBounceIndex)

    character.position ^+= finalTranslation
    ////fmt.printfln("translation: %v, charpos: %v", finalTranslation, character.position)
}

check_grounded :: proc(character: ^CharacterController, scenery: ^el.LevelData) -> bool {
    collision := char_controller_cast_downwards({ 0, -1, 0 }, character.position^ + { 0, character.height / 2, 0 }, character, scenery)
    if !collision.collides do return false

    return card(collision.collisionObject.objectTags & character.groundTagMask) > 0
}

//"Public" accessor
do_gravity_collision :: proc(translation: mathf.vec3, character: ^CharacterController, scenery: ^el.LevelData, bounces := MAX_BOUNCES) -> (new_translation: mathf.vec3) {
    return do_collide_and_slide(translation, character.position^, character, character.height / 2, scenery, 0, bounces, char_controller_cast_downwards)
}

apply_velocity :: proc(translation: mathf.vec3, character: ^CharacterController, scenery: ^el.LevelData) {
    finalTranslation := do_movement_collision(translation, character, scenery)

    character.position ^+= finalTranslation
}

do_movement_collision :: proc(translation: mathf.vec3, character: ^CharacterController, scenery: ^el.LevelData) -> (new_translation: mathf.vec3) {
    return do_collide_and_slide(translation, character.position^, character, character.width, scenery, 0, 0)
}

@(private)
get_slope_angle :: proc(character: ^CharacterController, scenery: ^el.LevelData) -> (angle: f32, hasGround: bool) {
    downCastDBGColor = rl.GRAY
    groundCollision := char_controller_cast_downwards({ 0, -1, 0 }, character.position^, character, scenery)
    downCastDBGColor = rl.ORANGE

    if !groundCollision.collides do return

    angle = rl.Vector3Angle(groundCollision.collisionHit.normal, { 0, 1, 0 })
    hasGround = true

    return
}

@(private)
do_collide_and_slide :: proc(
    translation: mathf.vec3, 
    origin: mathf.vec3, 
    character: ^CharacterController,
    collisionOffset: f32,
    scenery: ^el.LevelData, 
    bounce_index: int,
    max_bounce_index: int = MAX_BOUNCES, 
    casting_provider: proc(mathf.vec3, mathf.vec3, ^CharacterController, ^el.LevelData) -> CollisionInfo = char_controller_cast
) -> (new_translation: mathf.vec3) {
    if bounce_index > max_bounce_index do return { 0, 0 ,0 }

    collision := casting_provider(translation, origin, character, scenery)
    if !collision.collides do return translation

    translationDir := linalg.vector_normalize0(translation)

    offsetPoint := origin + (translationDir * collision.collisionHit.distance) - (linalg.vector_normalize0(translation) * collisionOffset)
    //Translation up to out chosen point
    new_translation = offsetPoint - character.position^
    //Remainder of the translation
    remainder := translation - new_translation
    remainderLen := linalg.vector_length(remainder)

    distScalar := remainder[0] * collision.collisionHit.normal[0] + remainder[1] * collision.collisionHit.normal[1] + remainder[2] * collision.collisionHit.normal[2]
    projectedRemainder := remainder - distScalar * collision.collisionHit.normal

    new_translation += do_collide_and_slide(projectedRemainder, origin + new_translation, character, collisionOffset, scenery, bounce_index + 1, max_bounce_index, casting_provider)

    return
}

downCastDBGColor := rl.ORANGE
@(private)
char_controller_cast_downwards :: proc(translation: mathf.vec3, origin: mathf.vec3, character: ^CharacterController, scenery: ^el.LevelData) -> (collision: CollisionInfo) {
    closestCollisionData: rl.RayCollision
    collisionObj: ^el.LevelObject
    closestCollisionData.distance = max(f32)

    normalizedTranslation := linalg.vector_normalize0(translation)

    for &obj, ind in scenery.levelObjects {
        //fmt.printfln("Checking obejct %v -- %v", ind, obj.objectName)

        if !obj.collision do continue
        if obj.objectMesh == -1 do continue

        dist := linalg.distance(origin, obj.objectTransform.position)

        //Distance Check
        if dist > character.maxCollisionDist do continue

        //TODO: Check if objectposition is above playerpos + height + threshold --> Easy way to lighten load, PROBLEM: No Big-Ass whole Map meshes possible
        when ODIN_DEBUG do rendering.add_3D_future(rendering.Box{ obj.boundingBox, downCastDBGColor })
        widthOffset := character.width / (RAY_RESOLUTION - 1)

        //Define Ray-Start position (left upper corner)
        rayStartCached := origin - character.right^ * widthOffset * ((RAY_RESOLUTION + 1) / 2) - character.forward^ * widthOffset * (RAY_RESOLUTION / 2)
        rayStartCached += { 0, character.height / 2, 0 }
        rayStart := rayStartCached

        ////fmt.printfln("%v", origin)

        for columnIndex := 0; columnIndex < RAY_RESOLUTION; columnIndex += 1 {
            for rowIndex := 0; rowIndex < RAY_RESOLUTION; rowIndex += 1 {
                rayStart += character.right^ * widthOffset

                ray: rl.Ray = {
                    position = rayStart,
                    direction = normalizedTranslation * (character.height / 2)
                }

                //Bounding box filter
                collision := rl.GetRayCollisionBox(ray, obj.boundingBox)
                if !collision.hit {
                    //Check if character is INSIDE the bounding box
                    if !rl.CheckCollisionBoxSphere(obj.boundingBox, rayStart, character.width) do continue
                }

                collision = rl.GetRayCollisionMesh(ray, scenery.levelMeshes[obj.objectMesh].mesh, obj.objectTransform.transformMatrix)

                if !collision.hit do continue

                when ODIN_DEBUG do rl.DrawLine3D(ray.position, collision.point, downCastDBGColor)

                rendering.add_3D_future(rendering.SphereWires{ origin, 0.005, rl.YELLOW })

                if collision.distance > (character.height / 2) + 0.05 do continue

                if collision.distance < closestCollisionData.distance {
                    collision.point[0] = origin[0]
                    collision.point[2] = origin[2]
                    closestCollisionData = collision
                    collisionObj = &obj
                }
            }
            rayStart -= character.right^ * widthOffset * RAY_RESOLUTION
            rayStart += character.forward^ * widthOffset
        }
    }

    //fmt.println(closestCollisionData)

    if closestCollisionData.distance == max(f32) do return
    when ODIN_DEBUG do draw_ray_hit(closestCollisionData, downCastDBGColor)

    collision.collides = true
    collision.collisionHit = closestCollisionData
    collision.collisionObject = collisionObj
    return
}

@(private)
char_controller_cast :: proc(translation: mathf.vec3, origin: mathf.vec3, character: ^CharacterController, scenery: ^el.LevelData) -> (collision: CollisionInfo) {
    closestCollisionData: rl.RayCollision
    collisionObj: ^el.LevelObject
    closestCollisionData.distance = max(f32)

    normTranslation := rl.Vector3Normalize(translation)
    rightVector := linalg.vector_cross3(normTranslation, mathf.vec3{ 0, 1, 0 })
    rightVector = linalg.normalize0(rightVector)

    for &obj, ind in scenery.levelObjects {
        dist := linalg.distance(origin, obj.objectTransform.position)

        //Distance and collision toggle filter
        if dist >= character.maxCollisionDist do continue
        if !obj.collision do continue
        if card(obj.objectTags & character.collisionTagMask) == 0 do continue

        when ODIN_DEBUG do rendering.add_3D_future(rendering.Box{ obj.boundingBox, rl.YELLOW })

        //Define "RayStartPosition" (offset feet by 0.05 to the top, so the ray isn't IN the ground)
        rayStart := origin + rightVector * (-character.width / 2)
        heightOffset := character.height / (RAY_RESOLUTION - 1)
        widthOffset := character.width / (RAY_RESOLUTION - 1)

        for columnIndex := 0; columnIndex < RAY_RESOLUTION; columnIndex += 1 {
            for rowIndex := 0; rowIndex < RAY_RESOLUTION; rowIndex += 1 {
                if rowIndex == 0 do rayStart[1] = origin[1] + 0.05
                else do rayStart[1] = origin[1] + heightOffset * f32(rowIndex)
                
                ray: rl.Ray = {
                    direction = normTranslation,
                    position = rayStart
                }

                //Bounding box filter
                collision := rl.GetRayCollisionBox(ray, obj.boundingBox)
                if !collision.hit {
                    //Check if character is INSIDE the bounding box
                    if !rl.CheckCollisionBoxSphere(obj.boundingBox, rayStart, character.width) do continue
                }

                if obj.objectMesh == -1 do continue
                collision = rl.GetRayCollisionMesh(ray, scenery.levelMeshes[obj.objectMesh].mesh, obj.objectTransform.transformMatrix)

                if !collision.hit do continue
                when ODIN_DEBUG do rendering.add_3D_future(rendering.Line3D{ ray.position, collision.point, rl.PURPLE })

                normalizedDist := collision.distance / rl.Vector3Length(collision.distance)
                //fmt.printfln("%v, %v, %v, %v", collision.distance, normalizedDist, rl.Vector3Length(collision.distance), obj.objectName)
                if normalizedDist > character.width do continue

                if collision.distance < closestCollisionData.distance {
                    closestCollisionData = collision
                    collisionObj = &obj
                }
            }

            rayStart += rightVector * widthOffset
        }
    }

    if closestCollisionData.distance == max(f32) do return
    when ODIN_DEBUG do draw_ray_hit(closestCollisionData, rl.PURPLE)
    
    collision.collides = true
    collision.collisionHit = closestCollisionData
    collision.collisionObject = collisionObj
    return
}

draw_ray_hit :: proc(coll: rl.RayCollision, col: rl.Color = rl.RED) {
    rendering.add_3D_future(rendering.CubeWires{ coll.point, { 0.15, 0.15, 0.15 }, col })
    rendering.add_3D_future(rendering.Line3D{ coll.point, coll.point + coll.normal, col })
}

draw_debug_box :: proc(point: mathf.vec3, col: rl.Color = rl.RED) {
    rendering.add_3D_future(rendering.CubeWires{ point, { 0.15, 0.15, 0.15 }, col })
}

draw_char_controller :: proc(controller: ^CharacterController, col: rl.Color = rl.GREEN) {
    rendering.add_3D_future(rendering.CapsuleWires{ controller.position^ + { 0, 0.5, 0 }, controller.position^ + { 0, controller.height - 0.5, 0 }, controller.width, col })
    //rl.DrawCircle3D(controller.position^, controller.width, { 1, 0, 0 }, 90, col)
    
    charCenter := controller.position^ + { 0, controller.height / 2, 0 }
    rendering.add_3D_future(rendering.SphereWires{ charCenter, 0.05, rl.PURPLE })

    rightStart := charCenter - controller.right^ * controller.width
    rendering.add_3D_future(rendering.SphereWires{ rightStart, 0.05, rl.RED })

    forwardStart := charCenter + controller.forward^ * controller.width
    rendering.add_3D_future(rendering.SphereWires{ forwardStart, 0.05, rl.BLUE })
}