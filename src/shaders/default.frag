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

    vec4 layerColor;
        if (fragLayer == 0.0) layerColor = vec4(1.0, 0.0, 0.0, 1.0);      // Red
    else if (fragLayer <= 1.0 && fragLayer > 0.0) layerColor = vec4(0.0, 1.0, 0.0, 1.0); // Green
    else if (fragLayer <= 2.0) layerColor = vec4(0.0, 0.0, 1.0, 1.0); // Blue
    else if (fragLayer <= 3.0) layerColor = vec4(1.0, 1.0, 0.0, 1.0); // Yellow
    else if (fragLayer <= 4.0) layerColor = vec4(1.0, 0.0, 1.0, 1.0); // Magenta
    else if (fragLayer <= 5.0) layerColor = vec4(0.0, 1.0, 1.0, 1.0); // Cyan
    else if (fragLayer <= 6.0) layerColor = vec4(0.5, 0.5, 0.5, 1.0); // Gray
    else layerColor = vec4(1.0, 1.0, 1.0, 1.0);                       // White

    finalColor = layerColor * texColor * fragColor; 
    //finalColor = vec4(fragLayer/8.0, 0.0, 0.0, 1.0); // This will show different shades of red for each layer
    //finalColor = color;  
}
