const std = @import("std");
const c = @cImport({
    @cInclude("raylib.h");
    @cInclude("rlgl.h"); 
    @cInclude("raymath.h"); 
    @cInclude("rcamera.h"); 
    @cDefine("GL_GLEXT_PROTOTYPES", "1");
    @cInclude("GL/glcorearb.h");
});
const Vec2 = c.Vector2; 

// Constants
const MAX_PARTICLES = 1000;
const GLSL_VERSION = 330;

// Particle struct using packed attribute to match C memory layout
const Particle = extern struct {
    x: f32,
    y: f32,
    period: f32,
};

const Quad = struct {
    position: [3]f32,
    color: [4]f32
}; 

pub fn main() !void {
    // Initialization
    const screenWidth = 800;
    const screenHeight = 450;

    c.InitWindow(screenWidth, screenHeight, "raylib - point particles");

    var player: c.Rectangle = .{
        .x = screenWidth / 2,  // Start player in middle of world
        .y =  screenHeight / 2,
        .width = 100,
        .height = 100
    };

    var camera: c.Camera2D = undefined; 
    camera.target = c.Vector2{.x = player.x, .y = player.y}; 
    camera.offset = c.Vector2{.x = screenWidth / 2, .y = screenHeight / 2}; 
    camera.rotation = 0.0; 
    camera.zoom = 1.0; 

    // Load shaders with proper version
    const shader = c.LoadShader(c.TextFormat("src/shaders/default.vert"), c.TextFormat("src/shaders/default.frag")); 

    const currentTimeLoc = c.GetShaderLocation(shader, "currentTime");
    const colorLoc = c.GetShaderLocation(shader, "color");

    // Initialize particle array
    //var particles: [MAX_PARTICLES]Particle = undefined;
    var prng = std.Random.DefaultPrng.init(@intCast(std.time.timestamp()));
    const random = prng.random();

    // Initialize particles with random values
    //var particle = Particle{
    //    .x = 0,
    //    .y = 0,
    //    .period = @as(f32, @floatFromInt(random.intRangeAtMost(i32, 10, 30))) / 10.0,
    //};


    //const vertices = [_]f32{
    //    -0.5, -0.5, 0.0,   // Bottom left
    //    -0.5,  0.5, 0.0,  // Top left
    //     0.5, -0.5, 0.0,  // Bottom right
    //     0.5,  0.5, 0.0  // Top right
    //};
    
    const vertices = [_]f32{
        0.0,  0.0,  0.0,   // Bottom left
        0.0,  32.0, 0.0,  // Top left
        32.0, 0.0,  0.0,  // Bottom right
        32.0, 32.0,  0.0  // Top right
    };
    

    // OpenGL setup
    var vao: c.GLuint = 0;
    var vbo: c.GLuint = 0;
    c.glGenVertexArrays(1, &vao);
    c.glBindVertexArray(vao);
    
    c.glGenBuffers(1, &vbo);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    //OLD for particle struct
    //c.glBufferData(
    //    c.GL_ARRAY_BUFFER,
    //    @intCast(MAX_PARTICLES * @sizeOf(Particle)),
    //    @as(*anyopaque, @ptrCast(&particle)),
    //    c.GL_STATIC_DRAW
    //);
    
    //for vertices array 
     c.glBufferData(
        c.GL_ARRAY_BUFFER,
        vertices.len * @sizeOf(f32),
        &vertices,
        c.GL_STATIC_DRAW
    );

    c.glVertexAttribPointer(
        @intCast(shader.locs[c.SHADER_LOC_VERTEX_POSITION]),
        3,
        c.GL_FLOAT,
        c.GL_FALSE,
        0,
        null
    );
    c.glEnableVertexAttribArray(0);
        
    //good practice but not necessary
    //c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);
    //c.glBindVertexArray(0);

    c.glBindVertexArray(vao);
    var instanceVBO: c_uint = undefined;
    c.glGenBuffers(1, &instanceVBO);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, instanceVBO);

    c.glBufferData(
        c.GL_ARRAY_BUFFER,
        @sizeOf(Quad) * MAX_PARTICLES,
        null,  //no data yet
        c.GL_STATIC_DRAW
    );
    
    //position attribute in instance data
    c.glVertexAttribPointer(
        1, //location
        3, //size (3 floats)
        c.GL_FLOAT,
        c.GL_FALSE,
        @sizeOf(Quad),
        @ptrFromInt(0), //no offset
    );
    c.glEnableVertexAttribArray(1);
    c.glVertexAttribDivisor(1, 1);

    // Add color attribute
    c.glVertexAttribPointer(
        2, // location
        4, // size (4 floats for vec4 color)
        c.GL_FLOAT,
        c.GL_FALSE,
        @sizeOf(Quad),
        @ptrFromInt(@offsetOf(Quad, "color")) // offset for color
    );
    c.glEnableVertexAttribArray(2);
    c.glVertexAttribDivisor(2, 1);

    //instance data creation
    var instance_data: [MAX_PARTICLES]Quad = undefined;
    for (0..instance_data.len) |i| {
        instance_data[i] = .{
            .position = .{
                @as(f32, @floatFromInt(random.intRangeAtMost(i32, 20, screenWidth - 20))),
                @as(f32, @floatFromInt(random.intRangeAtMost(i32, 50, screenHeight - 20))),
                0
            },
             .color = .{
                random.float(f32),     // r
                random.float(f32),     // g
                random.float(f32),     // b
                1.0,                   // a
            },
        };
    }

     //upload to our instance VBO
    c.glBindBuffer(c.GL_ARRAY_BUFFER, instanceVBO);
    c.glBufferSubData(
        c.GL_ARRAY_BUFFER,
        0, //no offset
        @sizeOf(Quad) * MAX_PARTICLES,
        &instance_data
    );


    // Enable point size control in vertex shader
    c.glEnable(c.GL_PROGRAM_POINT_SIZE);

    //c.SetTargetFPS(60);

    // Main game loop
    while (!c.WindowShouldClose()) {
        const deltaTime = c.GetFrameTime();
        const moveSpeed = 200; 

        if (c.IsKeyDown(c.KEY_A)) player.x -= moveSpeed * deltaTime;
        if (c.IsKeyDown(c.KEY_D)) player.x += moveSpeed * deltaTime;
        if (c.IsKeyDown(c.KEY_W)) player.y -= moveSpeed * deltaTime;
        if (c.IsKeyDown(c.KEY_S)) player.y += moveSpeed * deltaTime;

        camera.target = c.Vector2{.x = player.x, .y = player.y};

        // Drawing
        c.BeginDrawing();
        
        c.ClearBackground(c.WHITE);
        
         c.BeginMode2D(camera); 

        // Draw UI elements
        c.DrawRectangle(10, 10, 275, 30, c.MAROON);
        c.DrawText(
            std.fmt.comptimePrint("{d} quads rendered as instances in world space!", .{MAX_PARTICLES}).ptr,
            20,
            20,
            10,
            c.RAYWHITE
        );

        c.rlDrawRenderBatchActive();

        // OpenGL rendering
        c.glUseProgram(shader.id);

        c.glUniform1f(currentTimeLoc, @floatCast(c.GetTime())); 

        const color = c.ColorNormalize(.{
            .r = 255,
            .g = 0,
            .b = 0,
            .a = 128,
        });
        c.glUniform4fv(colorLoc, 1, @ptrCast(&color));

        // Get and set modelview projection matrix
        const modelViewProjection = c.MatrixMultiply(
            c.rlGetMatrixModelview(),
            c.rlGetMatrixProjection()
        );
        c.glUniformMatrix4fv(
            shader.locs[c.SHADER_LOC_MATRIX_MVP],
            1,
            c.GL_FALSE,
            &c.MatrixToFloat(modelViewProjection)
        );

        // Draw particles
        c.glBindVertexArray(vao);
        //c.glDrawArraysInstanced(c.GL_POINTS, 0, 1, MAX_PARTICLES);
        c.glDrawArraysInstanced(c.GL_TRIANGLE_STRIP, 0, 4, MAX_PARTICLES);
        c.glBindVertexArray(0);

        c.glUseProgram(0);

        c.DrawRectangleRec(player, c.BLUE);

        c.EndMode2D();

        c.DrawFPS(screenWidth - 100, 10);

        c.EndDrawing();
    }

    // Cleanup
    c.glDeleteBuffers(1, &vbo);
    c.glDeleteVertexArrays(1, &vao);
    c.UnloadShader(shader);
    c.CloseWindow();
}
