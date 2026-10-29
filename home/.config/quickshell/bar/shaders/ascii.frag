// ASCII living wallpaper: redraws the wallpaper as glowing characters, with a slow wave of light
// drifting through it and motes that rise and twinkle. It follows the real sky: rain falls as slanted
// streaks, snow drifts down, fog softens it, wind speeds the wave up, and nights are dim with a few stars. Compiled with: qsb --qt6 -o ascii.frag.qsb ascii.frag
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
    float rain;        // 0..1 how hard it rains right now
    float snow;        // 0..1 how hard it snows
    float wind;        // 0..1 wind (0 calm, 1 ≈ 40 km/h)
    float night;       // 0 day … 1 deep night (eases through dusk and dawn)
    float fog;         // 0..1
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
    float wave = sin(uv.x * 7.0 - time * (0.45 + wind * 0.9) + uv.y * 5.0) * 0.5 + 0.5;
    vec2 suv = uv + vec2(0.0, (wave - 0.5) * 0.004);
    vec3 col = texture(src, suv).rgb;
    float l = dot(col, vec3(0.299, 0.587, 0.114));
    l = clamp(l + (wave - 0.5) * 0.14, 0.0, 1.0);
    l = pow(smoothstep(0.13, 0.97, l), 1.35);     // deep blacks stay empty, highlights carry the picture
    l = mix(l, 0.18 + l * 0.45, fog * 0.6);       // fog: flatter, greyer
    l *= 1.0 - night * 0.45;                      // night: the whole picture dims

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

    // rain: thin streaks falling fast, slanted by the wind; each column has its own drops
    if (rain > 0.0) {
        float slant = wind * 0.6;
        float cx = c.x + floor((px.y / cell.y) * slant * 0.25);       // streaks lean as they fall
        float rs = hash(vec2(cx, 3.0));
        float speed = 0.9 + rs * 0.8;
        float head = fract(rs * 17.0 + time * speed * 0.55);
        float tail = 0.035 + rain * 0.03;
        float d = head - uv.y; d = d < 0.0 ? d + 1.0 : d;
        float drop = step(1.0 - rain * 0.42, rs) * smoothstep(tail, 0.0, d);
        float streak = smoothstep(0.16, 0.0, abs(local.x - 0.5 + (local.y - 0.5) * slant));
        v += drop * streak * (0.55 + 0.45 * (1.0 - d / tail));
    }
    // snow: soft flakes drifting down and sideways
    if (snow > 0.0) {
        float ss = hash(vec2(c.x, 11.0));
        float fall = fract(ss * 29.0 + time * (0.03 + ss * 0.04));
        float sway = sin(time * 0.8 + ss * 40.0) * 0.4 + wind * 0.3;
        vec2 fl = vec2(local.x - 0.5 - sway * 0.3, (uv.y - fall) * res.y / cell.y);
        float flake = step(1.0 - snow * 0.35, ss) * smoothstep(0.35, 0.05, length(fl * vec2(1.0, 0.6)));
        v += flake * 0.8;
    }
    // night sky: a few slow stars in the top third
    float star = step(0.9985, hash(c * 1.7)) * smoothstep(0.42, 0.1, uv.y) * (0.5 + 0.5 * sin(time * 1.3 + hash(c) * 30.0));
    v += night * star * dotShape * 0.9;

    v = clamp(v * bright, 0.0, 1.0);
    fragColor = vec4(tintc.rgb * v, v) * qt_Opacity;      // transparent between characters (lets the glow show)
}
