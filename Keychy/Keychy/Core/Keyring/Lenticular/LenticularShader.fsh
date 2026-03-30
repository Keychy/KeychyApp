// ┌──────────────────────────────────────────┐
// │           조정 가능한 값들                │
// ├──────────────────────────────────────────┤
// │ LENS_DENSITY  : 렌즈 배열 밀도 (200)     │
// │ REFRACTION    : 굴절 강도 (0.4)          │
// │ SNAP_LOW/HIGH : 스냅 전환 구간 (0.25~0.75)│
// │ GHOSTING      : 반대 이미지 비침 (0.03)   │
// │ SHIMMER_WIDTH : 광택 밴드 너비 (0.12)     │
// │ SHIMMER_PEAK  : 광택 최대 밝기 (0.18)     │
// └──────────────────────────────────────────┘

void main() {
    float LENS_DENSITY  = 200.0;
    float REFRACTION    = 0.4;
    float SNAP_LOW      = 0.25;
    float SNAP_HIGH     = 0.75;
    float GHOSTING      = 0.03;
    float SHIMMER_WIDTH = 0.12;
    float SHIMMER_PEAK  = 0.18;

    vec2 uv = v_tex_coord;

    // Texture sampling
    vec2 uvA = vec2(uv.x * 0.5, uv.y);
    vec2 uvB = vec2(uv.x * 0.5 + 0.5, uv.y);
    vec4 colorA = texture2D(u_texture, uvA);
    vec4 colorB = texture2D(u_texture, uvB);

    // Lenticular blend
    float blend = u_tilt;
    float axis = mix(uv.x, uv.y, u_direction);
    float lens = sin(axis * LENS_DENSITY * 3.14159265);
    blend = clamp(blend + lens * REFRACTION * 0.15, 0.0, 1.0);
    blend = smoothstep(SNAP_LOW, SNAP_HIGH, blend);

    // Ghosting
    float ghost = (1.0 + lens) * 0.5;
    float ghostBlend = mix(
        ghost * GHOSTING,
        1.0 - ghost * GHOSTING,
        blend
    );
    vec4 color = mix(colorA, colorB, ghostBlend);

    // Shimmer
    float shimmerPos = u_tilt;
    float dist = axis - shimmerPos;
    float shimmer = exp(-(dist * dist) / (2.0 * SHIMMER_WIDTH * SHIMMER_WIDTH));
    float transitionIntensity = max(1.0 - abs(u_tilt * 2.0 - 1.0), 0.3);
    shimmer *= SHIMMER_PEAK * transitionIntensity;
    color.rgb += vec3(shimmer);

    gl_FragColor = color;
}
