#version 330

// Input fragment attributes (from fragment shader)
in vec2 fragTexCoord;
in vec4 fragColor;

uniform float u_time;
uniform sampler2D reflection; 

out vec4 finalColor; 

void main() {
    
    vec2 reflectionUV = vec2(fragTexCoord.x, fragTexCoord.y); 
    
    reflectionUV.y += sin(reflectionUV.x * 10.0 + u_time) / 20 * 0.1; 
        
    vec4 ref = texture(reflection, reflectionUV); 

    if (ref.g > 0.5) discard; 
    //if (ref.r > 0.9) discard; 

    finalColor = vec4(ref.xyz, 0.3); 
}
