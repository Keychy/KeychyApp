// ┌──────────────────────────────────────────┐
// │           조정 가능한 값들                │
// ├──────────────────────────────────────────┤
// │ LENS_DENSITY  : 렌즈 배열 밀도 (200)     │
// │ REFRACTION    : 굴절 강도 (0.4)          │
// │ SNAP_LOW/HIGH : 스냅 전환 구간 (0.25~0.75)│
// │ GHOSTING      : 반대 이미지 비침 (0.03)   │
// │ SHIMMER_WIDTH : 광택 밴드 너비 (0.15)     │
// │ SHIMMER_PEAK  : 광택 최대 밝기 (0.30)     │
// │ RIDGE_BASE/EDGE: 빗금 (중앙0.04/끝0.10)  │
// └──────────────────────────────────────────┘
// Shimmer modes: 0=메탈릭, 1=홀로그램, 2=얼룩, 3=펄스, 4=모자이크, 5=글리터

// HSV → RGB 변환
vec3 hsv2rgb(float h, float s, float v) {
    vec3 rgb = clamp(
        abs(mod(h * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0,
        0.0, 1.0
    );
    return v * mix(vec3(1.0), rgb, s);
}

// 해시 노이즈
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
    float LENS_DENSITY  = 200.0;
    float REFRACTION    = 0.4;
    float SNAP_LOW      = 0.25;
    float SNAP_HIGH     = 0.75;
    float GHOSTING      = 0.03;
    float SHIMMER_WIDTH = 0.15;
    float SHIMMER_PEAK  = 0.30;

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

    // ── Shimmer ──
    float shimmerPos = u_tilt;
    float dist = axis - shimmerPos;
    float shimmer = exp(-(dist * dist) / (2.0 * SHIMMER_WIDTH * SHIMMER_WIDTH));
    float transitionIntensity = max(1.0 - abs(u_tilt * 2.0 - 1.0), 0.5);
    shimmer *= SHIMMER_PEAK * transitionIntensity;

    vec3 shimmerTint;
    float shimmerFinal = shimmer;

    if (u_shimmer_mode > 4.5) {
        // ── Mode 5: 글리터 (Glitter) ──
        // 큰 원형 반짝임 + 글로우
        float GRID = 25.0;
        vec2 cell = floor(uv * GRID);
        vec2 cellUV = fract(uv * GRID);
        float noise = hash(cell);

        // 큰 반지름 + 소프트 글로우 (별처럼)
        float radius = 0.12 + noise * 0.35;
        float d = length(cellUV - 0.5);
        float star = smoothstep(radius, 0.0, d);

        // 느린 반짝임 (별)
        float twinkle = sin(u_time * 2.0 + noise * 50.0) * 0.5 + 0.5;
        float sparkle = step(0.65, noise) * twinkle * star;

        // 별 색상: 베이스에서 흰색 방향
        vec3 starColor = mix(u_shimmer_color, vec3(0.7, 0.8, 1.0), 0.8);
        shimmerTint = mix(u_shimmer_color * 0.4, starColor, sparkle);
        shimmerFinal = shimmer * 0.3 + sparkle * 0.55;

    } else if (u_shimmer_mode > 3.5) {
        // ── Mode 4: 모자이크 엠보스 시머 ──
        // 기울일 때 시머 밴드에서 작은 타일이 일렁이며 돌출/함몰
        float GRID = 30.0;
        vec2 cell = floor(uv * GRID);
        vec2 cellUV = fract(uv * GRID);
        float cellNoise = hash(cell);

        // 작은 네모 마스크
        float sqSize = 0.28 + cellNoise * 0.15;
        vec2 sq = abs(cellUV - 0.5);
        float isSquare = step(sq.x, sqSize * 0.5) * step(sq.y, sqSize * 0.5);

        // 셀 존재 + 밝기 변화
        float cellExists = step(0.15, cellNoise);
        float cellBright = 0.3 + cellNoise * 0.7;

        // 돌출 vs 함몰 (셀마다 랜덤)
        float isRaised = step(0.45, hash(cell + vec2(7.31, 3.17)));

        // 사인파 기반 일렁임 (셀마다 위상 다름 → 파도처럼 흐름)
        float wave = sin(u_time * 3.0 + cellNoise * 20.0) * 0.5 + 0.5;
        float flicker = 0.3 + wave * 0.7;
        float sqMask = isSquare * cellExists * flicker;

        // 돌출: 밝은 하이라이트 (시머 밴드에서만)
        float raisedAmt = sqMask * isRaised * cellBright * shimmer * 2.5;
        // 함몰: 기존 이미지를 어둡게 (시머 밴드에서만)
        float recessedAmt = sqMask * (1.0 - isRaised) * cellBright * shimmer * 1.5;
        color.rgb *= 1.0 - recessedAmt * 0.08;

        shimmerTint = mix(u_shimmer_color, vec3(0.4, 1.0, 0.5), 0.25);
        shimmerFinal = raisedAmt;

    } else if (u_shimmer_mode > 1.5) {
        // ── Mode 2: 리퀴드 (Liquid Metal) ──
        // 크롬/수은 같은 환경 반사 시뮬레이션
        // 핵심: 여러 주파수 사인파 중첩 → 가짜 환경맵 → 극단적 명암 대비

        // 환경 반사 패턴 (3개 주파수 중첩)
        float e1 = sin(uv.x * 30.0 + uv.y * 20.0 + u_tilt * 8.0) * 0.5 + 0.5;
        float e2 = sin(uv.x * 15.0 - uv.y * 25.0 + u_tilt * 6.0 + 1.0) * 0.5 + 0.5;
        float e3 = sin((uv.x + uv.y) * 18.0 + u_tilt * 10.0 + 2.5) * 0.5 + 0.5;

        // 합성 + 노이즈 왜곡
        float env = e1 * e2 * 0.7 + e3 * 0.3;
        float n = hash(floor(uv * 25.0));
        env += n * 0.15 - 0.075;

        // 크롬 명암: smoothstep → 제곱 (밝은 곳은 더 밝게, 어두운 곳은 더 어둡게)
        float chrome = smoothstep(0.28, 0.72, env);
        chrome = chrome * chrome;

        // 반사 색상: highlight = 거의 화이트, shadow = 틴트의 깊은 그림자
        vec3 highlight = mix(u_shimmer_color, vec3(1.0), 0.7);
        vec3 shadow = u_shimmer_color * 0.12;
        shimmerTint = mix(shadow, highlight, chrome);
        shimmerFinal = shimmer;

    } else if (u_shimmer_mode > 0.5) {
        // ── Mode 1: 홀로그램 ──
        // 왜곡된 포물선 무지개 밴드가 기울임에 따라 지나감
        float cx = uv.x - 0.5;

        // 3개의 포물선 밴드 (각각 다른 곡률/오프셋)
        float w1 = axis + cx * cx * 2.5;
        float w2 = axis - cx * cx * 1.8 + 0.30;
        float w3 = axis + cx * cx * 1.2 + cx * 0.5 - 0.20;

        float bw = 0.08;
        float bw2 = bw * 0.7;
        float bw3 = bw * 1.2;
        float d1 = w1 - shimmerPos;
        float d2 = w2 - shimmerPos;
        float d3 = w3 - shimmerPos;

        float b1 = exp(-(d1 * d1) / (2.0 * bw * bw));
        float b2 = exp(-(d2 * d2) / (2.0 * bw2 * bw2));
        float b3 = exp(-(d3 * d3) / (2.0 * bw3 * bw3));

        // 각 밴드 고유 hue (위치 + 틸트에 따라 색상 변화)
        vec3 c1 = hsv2rgb(fract(w1 * 2.0 + u_tilt), 0.40, 1.0) * b1;
        vec3 c2 = hsv2rgb(fract(w2 * 2.0 + u_tilt + 0.33), 0.40, 1.0) * b2;
        vec3 c3 = hsv2rgb(fract(w3 * 2.0 + u_tilt + 0.66), 0.40, 1.0) * b3;

        shimmerTint = (c1 + c2 + c3) * transitionIntensity * 0.45;
        shimmerFinal = 1.0;

    } else {
        // ── Mode 0: 단색 (Solid) ──
        shimmerTint = u_shimmer_color;
    }

    color.rgb += shimmerTint * shimmerFinal;

    // ── 렌즈 빗금 ──
    float RIDGE_BASE = 0.04;
    float RIDGE_EDGE = 0.10;
    float edgeFactor = abs(u_tilt * 2.0 - 1.0);
    float ridgeStrength = mix(RIDGE_BASE, RIDGE_EDGE, edgeFactor);
    float ridge = lens * lens;
    color.rgb *= 1.0 - ridgeStrength * (1.0 - ridge);

    // ── Rounded rect SDF (코너 + 테두리) ──
    float BORDER_WIDTH = 2.5;

    vec2 halfSize = u_sprite_size * 0.5;
    vec2 p = abs(uv * u_sprite_size - halfSize) - halfSize + vec2(u_cornerRadius);
    float sdf = length(max(p, vec2(0.0))) + min(max(p.x, p.y), 0.0) - u_cornerRadius;

    float cornerAlpha = 1.0 - smoothstep(-0.75, 0.75, sdf);
    float borderMask = smoothstep(-BORDER_WIDTH - 0.75, -BORDER_WIDTH + 0.75, sdf) * cornerAlpha;

    float tiltEdge = abs(u_tilt * 2.0 - 1.0);
    float borderBrightness = 0.72 + 0.23 * tiltEdge;

    // ── 테두리 색상 (모드별) ──
    vec3 borderBase;

    if (u_border_mode > 4.5) {
        // 글리터: 큰 반짝이 알갱이 + 오로라 테두리
        // 픽셀 좌표 기반 그리드 — 테두리 두께(3.5px)에 맞는 스케일
        vec2 pxCoord = uv * u_sprite_size;
        float CELL = 5.0;
        vec2 bCell = floor(pxCoord / CELL);
        vec2 bCellUV = fract(pxCoord / CELL);
        float bNoise = hash(bCell);

        // 큰 원형 글리터 (셀 대비 크게 → 테두리에 잘 보임)
        float bRadius = 0.42 + bNoise * 0.18;
        float bDist = length(bCellUV - 0.5);
        float bStar = smoothstep(bRadius, bRadius * 0.2, bDist);

        // 빠른 반짝임 (눈에 확 띄게)
        float bTwinkle = sin(u_time * 5.0 + bNoise * 30.0) * 0.5 + 0.5;
        float bSparkle = step(0.20, bNoise) * bTwinkle * bStar;

        // 별 색상 (블루~퍼플~화이트)
        float starHue = 0.55 + bNoise * 0.15;
        vec3 starCol = hsv2rgb(starHue, 0.25 * (1.0 - bSparkle * 0.5), 1.0);
        borderBase = mix(u_border_color * 0.5, starCol, bSparkle * 0.85);
        borderBase += u_border_color * (1.0 - bSparkle) * 0.5;

        // 네뷸러 오로라 (테두리를 따라 흐르는 빛)
        float flow1 = sin(axis * 8.0 + u_time * 2.5) * 0.5 + 0.5;
        float flow2 = sin(axis * 5.0 - u_time * 1.8 + 1.5) * 0.5 + 0.5;
        vec3 nebulaCol = hsv2rgb(fract(axis * 0.25 + u_time * 0.08), 0.45, 0.80);
        borderBase += nebulaCol * (flow1 * 0.25 + flow2 * 0.15);

    } else if (u_border_mode > 3.5) {
        // 모자이크: 네모 알갱이 테두리
        float BGRID = 40.0;
        vec2 bCell = floor(uv * BGRID);
        vec2 bCellUV = fract(uv * BGRID);
        float bNoise = hash(bCell);
        float bSize = 0.20 + bNoise * 0.30;
        vec2 bSq = abs(bCellUV - 0.5);
        float bSquare = step(bSq.x, bSize * 0.5) * step(bSq.y, bSize * 0.5);
        float bFall = fract(bNoise * 10.0 + u_time * 0.5 * (0.5 + bNoise));
        float bVis = smoothstep(0.0, 0.2, bFall) * (1.0 - smoothstep(0.6, 1.0, bFall));
        float bSparkle = step(0.65, bNoise) * bVis * bSquare;
        vec3 bBright = mix(u_border_color, vec3(0.5, 1.0, 0.6), 0.4);
        borderBase = mix(u_border_color, bBright, bSparkle);

    } else if (u_border_mode > 2.5) {
        // 펄스: 파동이 테두리를 따라 왕복 sweep (좌하→우상→좌하)
        float PERIOD = 2.5;
        float fullCycle = mod(u_time, PERIOD * 2.0);
        float isReverse = step(PERIOD, fullCycle);
        float t = mod(fullCycle, PERIOD) / PERIOD;

        // 정방향: -0.2→1.2, 역방향: 1.2→-0.2
        float front = mix(t * 1.4 - 0.2, 1.2 - t * 1.4, isReverse);

        // ahead 부호 반전으로 꼬리 방향도 자동 전환
        float ahead = mix(axis - front, front - axis, isReverse);

        // 선두 하이라이트 (날카로운 가우시안)
        float head = exp(-ahead * ahead / 0.003);

        // 꼬리: 지나간 자리 exponential decay
        float TRAIL = 0.15;
        float tail = exp(min(ahead, 0.0) / TRAIL) * step(ahead, 0.0);

        float pulseVal = head * 1.0 + tail * 1.0;

        // 기본: 어두운 베이스 → 펄스 통과 시 밝은 하이라이트
        vec3 pulseHL = mix(u_border_color, vec3(1.0), 0.75);
        borderBase = mix(u_border_color * 0.30, pulseHL, pulseVal);

    } else if (u_border_mode > 1.5) {
        // 얼룩: 크롬 반사 테두리 (shimmer 전용, border UI에선 미사용)
        float ce1 = sin(axis * 25.0 + u_time * 3.0 + u_tilt * 5.0) * 0.5 + 0.5;
        float ce2 = sin(axis * 17.0 - u_time * 2.0 + u_tilt * 3.0 + 1.5) * 0.5 + 0.5;
        float ce3 = sin(axis * 40.0 + u_time * 5.0 + 2.0) * 0.5 + 0.5;

        float bChrome = ce1 * ce2 * 0.7 + ce3 * 0.3;
        bChrome = smoothstep(0.25, 0.75, bChrome);
        bChrome = bChrome * bChrome;

        vec3 bHighlight = mix(u_border_color, vec3(1.0), 0.7);
        vec3 bShadow = u_border_color * 0.12;
        borderBase = mix(bShadow, bHighlight, bChrome);

    } else if (u_border_mode > 0.5) {
        // 홀로그램: 무지개 × 틴트 + 빠른 흐름
        float hue = fract(axis * 2.0 + u_tilt + u_time * 0.5);
        vec3 rainbow = hsv2rgb(hue, 0.4, 1.0);
        borderBase = rainbow * u_border_color;

    } else {
        // 단색: 빛 흐름 효과
        float glow = sin(axis * 6.2832 + u_time * 2.5) * 0.5 + 0.5;
        borderBase = u_border_color + u_border_color * glow * 0.3;
    }

    vec3 borderColor = borderBase * borderBrightness;

    color.rgb = mix(color.rgb, borderColor, borderMask);
    color *= cornerAlpha;

    gl_FragColor = color;
}
