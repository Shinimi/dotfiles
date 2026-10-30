#version 300 es
// Colour vibrance for the whole screen (125%). Written by apply-settings.sh. Made by Claude.
precision highp float;
in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;
void main() {
    vec4 c = texture(tex, v_texcoord);
    float l = dot(c.rgb, vec3(0.2126, 0.7152, 0.0722));
    fragColor = vec4(clamp(mix(vec3(l), c.rgb, 1.25), 0.0, 1.0), c.a);
}
