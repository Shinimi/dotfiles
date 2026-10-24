#version 300 es
// Monochrome mode: the whole screen in black and white, with a touch of contrast so it doesn't look washed out.
// Toggle: SUPER + ALT + M or the control center. Off by itself while a game runs. Made by Claude.
precision highp float;
in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;
void main() {
    vec4 c = texture(tex, v_texcoord);
    float l = dot(c.rgb, vec3(0.2126, 0.7152, 0.0722));
    l = clamp((l - 0.5) * 1.06 + 0.5, 0.0, 1.0);
    fragColor = vec4(vec3(l), c.a);
}
