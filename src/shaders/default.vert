#version 330

// Input vertex attributes
layout (location = 0) in vec3 vertexPosition;
layout (location = 1) in vec3 instancePosition; 
layout (location = 2) in vec4 instanceColor; 

// Input uniform values
uniform mat4 mvp;
uniform float currentTime;
    
out vec4 fragColor; 

void main()
{
    // Unpack data from vertexPosition
    //vec2  pos    = vertexPosition.xy + instancePosition.xy;
    //float period = vertexPosition.z;
    
    vec3 worldPos = vertexPosition + instancePosition; 

    // Calculate final vertex position (jiggle it around a bit horizontally)
    //pos += vec2(100, 0) * sin(period * currentTime);
    //gl_Position = mvp * vec4(pos, 0.0, 1.0);
    gl_Position = mvp * vec4(worldPos, 1.0); 

    // Calculate the screen space size of this particle (also vary it over time)
    //gl_PointSize = 10 - 5 * abs(sin(period * currentTime));

    fragColor = instanceColor; 
}
