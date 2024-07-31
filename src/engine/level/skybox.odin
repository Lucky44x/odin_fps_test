package level

import rl "vendor:raylib"
import rlgl "vendor:raylib/rlgl"

@(private)
CubeMapShader: rl.Shader
@(private)
SkyboxMesh: rl.Mesh
@(private)
environmentMapData := int(rl.MaterialMapIndex.CUBEMAP)
@(private)
gammaData := 0
@(private)
vFlippedData := 0
@(private)
equirectangularData := 0

init_skybox_system :: proc() {
    SkyboxMesh = rl.GenMeshCube(1, 1, 1)
    CubeMapShader = rl.LoadShader("assets/engine/shaders/cubemap/cubemap.vert", "assets/engine/shaders/cubemap/cubemap.frag")
    rl.SetShaderValue(CubeMapShader, rl.GetShaderLocation(CubeMapShader, "equirectangularMap"), &equirectangularData, rl.ShaderUniformDataType.INT)
}

load_skybox :: proc(skyboxFileName: cstring, vertexShader: cstring, fragmentShader: cstring) -> (skybox: rl.Model, err: LevelError) {
    skybox = rl.LoadModelFromMesh(SkyboxMesh)
    skybox.materials[0].shader = rl.LoadShader(vertexShader, fragmentShader)

    rl.SetShaderValue(skybox.materials[0].shader, rl.GetShaderLocation(skybox.materials[0].shader, "environmentMap"), &environmentMapData, rl.ShaderUniformDataType.INT)
    rl.SetShaderValue(skybox.materials[0].shader, rl.GetShaderLocation(skybox.materials[0].shader, "doGamma"), &gammaData, rl.ShaderUniformDataType.INT);
    rl.SetShaderValue(skybox.materials[0].shader, rl.GetShaderLocation(skybox.materials[0].shader, "vflipped"), &vFlippedData, rl.ShaderUniformDataType.INT);

    //TODO: Add HDR support

    skyboxTexture := rl.LoadImage(skyboxFileName)
    skybox.materials[0].maps[rl.MaterialMapIndex.CUBEMAP].texture = rl.LoadTextureCubemap(skyboxTexture, rl.CubemapLayout.AUTO_DETECT)
    rl.UnloadImage(skyboxTexture)

    return
}

DrawSkybox :: proc(skybox: ^LevelSkybox) {
    //When Skybox is of type color, do nothing
    #partial switch type in skybox {
        case rl.Model:       
            rlgl.DisableBackfaceCulling()
            rlgl.DisableDepthMask()
                rl.DrawModel(type, { 0, 0, 0 }, 1.0, rl.WHITE)
            rlgl.EnableDepthMask()
            rlgl.EnableBackfaceCulling()
            break
    }
}