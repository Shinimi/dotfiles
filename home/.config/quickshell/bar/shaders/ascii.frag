// ASCII living wallpaper: redraws the wallpaper as glowing characters, with a slow wave of light
// drifting through it and motes that rise and twinkle. Compiled with: qsb --qt6 -o ascii.frag.qsb ascii.frag
// Made by Claude.
#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float glyphs;      // characters in the atlas
    float bright;      // overall brightness
    vec2 res;          // item size in pixels
    vec2 cell;         // one character cell in pixels
    vec4 tintc;        // glow colour (white, or a little of the wallpaper tint)
};
layout(binding = 1) uniform sampler2D src;
layout(binding = 2) uniform sampler2D atlas;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void main() {
    vec2 px = qt_TexCoord0 * res;
    vec2 c = floor(px / cell);
    vec2 local = fract(px / cell);
    vec2 uv = (c + 0.5) * cell / res;

    // slow swell of light travelling diagonally across the picture
    float wave = sin(uv.x * 7.0 - time * 0.45 + uv.y * 5.0) * 0.5 + 0.5;
    vec2 suv = uv + vec2(0.0, (wave - 0.5) * 0.004);
    vec3 col = texture(src, suv).rgb;
    float l = dot(col, vec3(0.299, 0.587, 0.114));
    l = clamp(l + (wave - 0.5) * 0.14, 0.0, 1.0);
    l = pow(smoothstep(0.13, 0.97, l), 1.35);     // deep blacks stay empty, highlights carry the picture

    // pick the character for this brightness and draw it
    float gi = floor(l * (glyphs - 1.0) + 0.5);
    float g = texture(atlas, vec2((gi + local.x) / glyphs, local.y)).a;
    float v = g * (0.10 + 1.1 * l);

    // motes: each column has a few that drift upward and fade in and out
    float col_seed = hash(vec2(c.x, 7.0));
    float rise = fract(col_seed * 13.0 - time * (0.02 + col_seed * 0.03));
    float dotShape = smoothstep(0.32, 0.12, length((local - 0.5) * vec2(1.0, 1.8)));
    float mote = step(0.982, col_seed) * smoothstep(0.012, 0.0, abs(uv.y - rise));
    float twinkle = step(0.9993, hash(c + floor(time * 0.7)));
    v += (mote * 0.85 + twinkle * 0.7) * dotShape;

    v = clamp(v * bright, 0.0, 1.0);
    fragColor = vec4(tintc.rgb * v, v) * qt_Opacity;      // transparent between characters (lets the glow show)
}
