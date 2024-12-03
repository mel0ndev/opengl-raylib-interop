#version 330

// Input vertex attributes
layout (location = 0) in vec3 vertexPosition;
layout (location = 1) in vec3 instancePosition; 
layout (location = 2) in vec4 instanceColor; 
layout (location = 3) in vec2 texCoord; 
layout (location = 4) in float rotation; 

// Input uniform values
uniform mat4 mvp;
uniform float currentTime;
uniform float layer_offset; 
    
out vec4 fragColor; 
out vec2 fragTexCoord;
out float fragLayer; 

void main() {
        
    //fragTexCoord = vec2(texCoord.x, (texCoord.y * layerHeight) + vOffset);
    float layerIndex = mod(float(gl_InstanceID), 8.0); 
    float layerHeight = 1.0 / 8.0;
    float vOffset = layerIndex * layerHeight;
    fragTexCoord = vec2(texCoord.x, (texCoord.y * layerHeight) + vOffset);
        
    vec2 center = vec2(32.0/2.0, 32.0/2.0);  // Using your width/height values
    vec2 localPos = vertexPosition.xy - center;
    float rotationAngle = rotation + currentTime; 
    float cosA = cos(rotationAngle); 
    float sinA = sin(rotationAngle); 
    vec2 rotatedPos = vec2(
        localPos.x * cosA - localPos.y * sinA,
        localPos.x * sinA + localPos.y * cosA
    );
    
    //move back to center
    rotatedPos += center; 
    vec3 worldPos = vec3(rotatedPos, 0.0) + instancePosition; 
    worldPos.y -= layerIndex * layer_offset; 


    gl_Position = mvp * vec4(worldPos, 1.0); 

    fragColor = instanceColor; 
    fragLayer = layerIndex; 
}
