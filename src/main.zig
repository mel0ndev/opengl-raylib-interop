const std = @import("std");
const raylib = @cImport({                                                                
    @cInclude("raylib.h");                                                               
}); 

pub fn main() !void {
 var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        //fail test; can't try in defer as defer is executed after we return
        if (deinit_status == .leak) std.testing.expect(false) catch @panic("TEST FAIL");
    }
    const allocator = gpa.allocator();
    _ = allocator; 

    const screenWidth: f32 = 1280;
    const screenHeight: f32 = 720;

    raylib.SetConfigFlags(raylib.FLAG_WINDOW_RESIZABLE);
    raylib.InitWindow(screenWidth, screenHeight, "Raylib Render Texture Test");

    var player: raylib.Rectangle = .{
        .x = screenWidth / 2 - 50, 
        .y = screenHeight / 2 - 100, 
        .width = 100, 
        .height = 100
    }; 

    var camera: raylib.Camera2D = undefined; 
    camera.target = raylib.Vector2{.x = player.x, .y = player.y}; 
    camera.offset = raylib.Vector2{.x = screenWidth / 2 - 50, .y = screenWidth / 2 - 380}; 
    camera.rotation = 0.0; 
    camera.zoom = 1.0; 



    // Load water shader
    // NOTE: Defining 0 (NULL) for vertex shader forces usage of internal default vertex shader
    const shader = raylib.LoadShader(0, "src/water.frag");
    const world_shader = raylib.LoadShader(0, "src/reflection.frag"); 
    
    const target: raylib.RenderTexture2D = raylib.LoadRenderTexture(screenWidth, screenHeight); 
    const world_target: raylib.RenderTexture2D = raylib.LoadRenderTexture(screenWidth, screenHeight); 

    var u_time: f32 = 0; 
    const u_time_loc = raylib.GetShaderLocation(shader, "u_time");
    const reflection_loc = raylib.GetShaderLocation(shader, "reflection"); 

    const u_time_loc_ref = raylib.GetShaderLocation(world_shader, "u_time");
    const reflection_loc_ref = raylib.GetShaderLocation(world_shader, "reflection"); 

    raylib.SetTargetFPS(60);                   // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!raylib.WindowShouldClose())        // Detect window close button or ESC key
    {
        // Update
        //----------------------------------------------------------------------------------
        const deltaTime = raylib.GetFrameTime();
        u_time += deltaTime;

        camera.target.x = player.x; 
        camera.target.y = player.y; 

        // Set shader required uniform values
        raylib.SetShaderValue(shader, u_time_loc, &u_time, raylib.SHADER_UNIFORM_FLOAT);
        raylib.SetShaderValue(world_shader, u_time_loc_ref, &u_time, raylib.SHADER_UNIFORM_FLOAT);
        //----------------------------------------------------------------------------------
        
        if (raylib.IsKeyDown(raylib.KEY_A)) {
            player.x -= 2.0; 
        }

        if (raylib.IsKeyDown(raylib.KEY_D)) {
            player.x += 2.0; 
        }

        if (raylib.IsKeyDown(raylib.KEY_W)) {
            player.y -= 2.0; 
        }

        if (raylib.IsKeyDown(raylib.KEY_S)) {
            player.y += 2.0; 
        }

        // Draw
        //----------------------------------------------------------------------------------
        raylib.BeginTextureMode(world_target); 
            raylib.ClearBackground(raylib.RAYWHITE);

            raylib.DrawTriangle(
                raylib.Vector2{.x = 50, .y = screenHeight - 150},
                raylib.Vector2{.x = 25, .y = screenHeight - 100},
                raylib.Vector2{.x = 75, .y = screenHeight - 100},
                raylib.PINK
            ); 

            raylib.DrawTriangle(
                raylib.Vector2{.x = 300, .y = screenHeight - 400},
                raylib.Vector2{.x = 250, .y = screenHeight - 350},
                raylib.Vector2{.x = 350, .y = screenHeight - 350},
                raylib.BLUE
            ); 
        raylib.EndTextureMode(); 

        //then we render what we want to reflect to the render texture 
        raylib.BeginTextureMode(target); 
        raylib.BeginMode2D(camera); 
            raylib.ClearBackground(raylib.RAYWHITE);
            raylib.DrawRectangleRec(player, raylib.GREEN);

        raylib.EndMode2D(); 
        raylib.EndTextureMode(); 

        raylib.BeginDrawing();
            raylib.ClearBackground(raylib.WHITE);

             //first, we draw the scene normally
             raylib.BeginMode2D(camera); 
                 raylib.DrawRectangle(0, 0, screenWidth, screenHeight, raylib.RED); 
                 raylib.DrawRectangleRec(player, raylib.GREEN); 

            raylib.DrawTriangle(
                raylib.Vector2{.x = 50, .y = 50},
                raylib.Vector2{.x = 25, .y = 100},
                raylib.Vector2{.x = 75, .y = 100},
                raylib.PINK
            ); 

            raylib.DrawTriangle(
                raylib.Vector2{.x = 300, .y = 300},
                raylib.Vector2{.x = 250, .y = 350},
                raylib.Vector2{.x = 350, .y = 350},
                raylib.BLUE
            ); 

                //raylib.BeginScissorMode(screenWidth / 2 - 250, 0, 500, 1000); 
                raylib.BeginShaderMode(world_shader);

                    raylib.SetShaderValueTexture(world_shader, reflection_loc_ref, world_target.texture); 

                    raylib.DrawTextureRec(
                        world_target.texture,
                        raylib.Rectangle{
                            .x = 0,
                            .y = 0,
                            .width = @floatFromInt(target.texture.width),
                            .height = @floatFromInt(target.texture.height), 
                        },
                        raylib.Vector2{
                            .x = 0, 
                            .y = 0,
                        },
                        raylib.WHITE
                    ); 
                    
                    //raylib.DrawRectanglePro(

                    //); 
                    //
                raylib.EndShaderMode(); 
                //then we begin drawing the reflection shader
                raylib.BeginShaderMode(shader);
                    //set the shader texture value to the texture we set above
                    raylib.SetShaderValueTexture(shader, reflection_loc, target.texture); 

                    //then draw the texture to the screen
                    raylib.DrawTextureRec(
                        target.texture,
                        raylib.Rectangle{
                            .x = 0,
                            .y = 0,
                            .width = @floatFromInt(target.texture.width),
                            .height = @floatFromInt(-target.texture.height), 
                        },
                        raylib.Vector2{
                            .x = camera.target.x - camera.offset.x, 
                            .y = camera.target.y - camera.offset.y
                        },
                        raylib.WHITE
                    ); 
                raylib.EndShaderMode();
                //raylib.EndScissorMode(); 
             raylib.EndMode2D(); 

        raylib.EndDrawing();
        //----------------------------------------------------------------------------------
    }

    // De-Initialization
    //--------------------------------------------------------------------------------------
    raylib.UnloadShader(shader);           // Unload shader

    raylib.CloseWindow();                  // Close window and OpenGL context
    //--------------------------------------------------------------------------------------

}
