#version 330

// Input uniform values
uniform vec4 color;
    
in vec4 fragColor; 
in vec2 fragTexCoord; 
in float fragLayer; 

uniform sampler2D texture0;
// Output fragment color
out vec4 finalColor;

// NOTE: Add here your custom variables

void main()
{
    vec4 texColor = texture(texture0, fragTexCoord);
    finalColor = texColor * fragColor; 
}
