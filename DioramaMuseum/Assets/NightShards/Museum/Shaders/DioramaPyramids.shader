// 作品「ギザのピラミッド」(砂漠と塩の間)。夕暮れの三大ピラミッドとスフィンクス。URP 用。
// Cube の中をレイマーチングして描く。Cube の座標は -0.5〜0.5、下の 0.08 は黒い台。
//
// 形は実物の寸法 (1 m = 0.0011)。並びは実物の地図の位置を 0.77 倍に詰めたもの。美術館の正面 (+z) が東。
//   ・クフ王のピラミッド: 底辺 230 m・今の高さ 139 m (頂上は平ら。元の頂点の高さに、目印の柱)。北の面に入口。東に 3 つの王妃のピラミッド
//   ・カフラー王のピラミッド: 底辺 215 m・高さ 136 m。10 m 高い岩盤の上に立つので、いちばん高く見える。頂上に、なめらかな化粧石が残る
//   ・メンカウラー王のピラミッド: 底辺 102 m・高さ 65 m。下の段は赤い花こう岩。南に 3 つの王妃のピラミッド
//   ・大スフィンクス: 長さ 73 m・高さ 20 m。東を向いて、掘り下げた岩の囲いの中に伏せる。頭にネメス頭巾、前にのびる前足、地層の縞
//   ・石は 1.5 m ほどの段に積まれ、近くで見ると階段のようにギザギザ。砂丘と風紋、ラクダの隊列
// 仕掛け (_Event 0〜1): 西から砂嵐が吹き抜け、ピラミッドがかすむ。過ぎ去ると、夕日がいっそう強く赤く差す
//
// 外から見たとき、何もない所 (空) は透明にして、ガラスケースの向こうの部屋が見えるようにする。
// 中に入ったとき (カメラが箱の中) だけ、夕焼けの空を描く
Shader "NightShards/Diorama/Pyramids"
{
    Properties
    {
        _Steps ("Ray Steps", Range(16, 200)) = 160
        _ShadowSteps ("Shadow Steps", Range(0, 32)) = 20
        _Glass ("Glass Reflection", Range(0, 1)) = 0.3
        _Event ("Event (0-1)", Range(0, 1)) = 0
        _EventTime ("Event Time (s)", Float) = 0
        _Seed ("Seed", Float) = 0
        [NoScaleOffset] _HeightTex ("Baked Height (自動で作る)", 2D) = "black" {}
        _HeightTexOn ("Use Baked Height", Float) = 0
    }

    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" "RenderPipeline" = "UniversalPipeline" }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float _Steps;
            float _ShadowSteps;
            float _Glass;
            float _Event;
            float _EventTime;
            float _Seed;
            float _HeightTexOn;
        CBUFFER_END
        TEXTURE2D(_HeightTex);
        SAMPLER(sampler_linear_clamp);
        ENDHLSL

        Pass
        {
            Name "Diorama"
            Tags { "LightMode" = "UniversalForward" }
            Cull Front
            ZWrite On
            Blend One OneMinusSrcAlpha // 空の所は透明 (色はあらかじめ不透明度を掛けて出す)

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma multi_compile_instancing

            #define INNER 0.47

            struct Attributes
            {
                float4 positionOS : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionOS : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            // ---------------------------------------------------------------- ノイズ

            float Hash21(float2 p)
            {
                p = frac(p * float2(123.34, 456.21));
                p += dot(p, p + 45.32);
                return frac(p.x * p.y);
            }

            float2 Hash22(float2 p)
            {
                return frac(sin(float2(dot(p, float2(127.1, 311.7)), dot(p, float2(269.5, 183.3)))) * 43758.5453);
            }

            // 木の場所に使う乱数 (C# と同じ結果になるよう、sin を使わない)
            float2 Hash22b(float2 p) { return float2(Hash21(p), Hash21(p + 17.3)); }

            float Hash31(float3 p)
            {
                p = frac(p * 0.3183099 + 0.1);
                p *= 17.0;
                return frac(p.x * p.y * p.z * (p.x + p.y + p.z));
            }

            float ValueNoise(float2 p)
            {
                float2 i = floor(p);
                float2 f = frac(p);
                float2 u = f * f * (3.0 - 2.0 * f);
                return lerp(lerp(Hash21(i), Hash21(i + float2(1, 0)), u.x),
                            lerp(Hash21(i + float2(0, 1)), Hash21(i + float2(1, 1)), u.x), u.y);
            }

            float Noise3(float3 x)
            {
                float3 i = floor(x);
                float3 f = frac(x);
                f = f * f * (3.0 - 2.0 * f);
                return lerp(lerp(lerp(Hash31(i), Hash31(i + float3(1, 0, 0)), f.x),
                                 lerp(Hash31(i + float3(0, 1, 0)), Hash31(i + float3(1, 1, 0)), f.x), f.y),
                            lerp(lerp(Hash31(i + float3(0, 0, 1)), Hash31(i + float3(1, 0, 1)), f.x),
                                 lerp(Hash31(i + float3(0, 1, 1)), Hash31(i + float3(1, 1, 1)), f.x), f.y), f.z);
            }

            float Fbm3(float2 p)
            {
                return 0.5 * ValueNoise(p) + 0.25 * ValueNoise(p * 2.03 + 17.1) + 0.125 * ValueNoise(p * 4.1 + 31.7);
            }

            float SdBox(float3 p, float3 b)
            {
                float3 q = abs(p) - b;
                return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
            }

            float Hash11(float n) { return frac(sin(n * 127.1) * 43758.5453); }

            float SdEllipsoidLite(float3 p, float3 r)
            {
                float k0 = length(p / r);
                float k1 = length(p / (r * r));
                return k0 * (k0 - 1.0) / max(k1, 1e-6);
            }

            float SdRoundBox(float3 p, float3 b, float r) { return SdBox(p, b - r) - r; }

            float SdCapsule(float3 p, float3 a, float3 b, float r)
            {
                float3 pa = p - a, ba = b - a;
                float h = saturate(dot(pa, ba) / dot(ba, ba));
                return length(pa - ba * h) - r;
            }

            // ---------------------------------------------------------------- 場所と寸法 (1 m = 0.0011)
            // ※ ここと Height() を変えたら、C# の DioramaTerrain (Pyramids) も同じに直す (歩く地面と当たり判定)

            #define ID_BASE    0.0
            #define ID_GROUND  1.0
            #define ID_PYRAMID 2.0
            #define ID_SPHINX  3.0
            #define ID_CAMEL   4.0

            #define GROUND -0.3
            #define COURSE 0.0016                                  // 石の段の高さ (約 1.5 m)
            static const float2 KHUFU = float2(-0.3, 0.11);
            static const float2 KHAFRE = float2(-0.008, -0.169);
            static const float2 MENKAURE = float2(0.332, -0.39);
            static const float2 SPHINX = float2(0.068, 0.389);
            static const float3 SUN_DIR = float3(0.6, 0.16, -0.78);  // 南西の低い夕日

            // ---------------------------------------------------------------- 地面

            // ギザの台地: 西 (-z) へ行くほど高い
            float Plateau(float z) { return GROUND + 0.012 * smoothstep(0.25, -0.35, z); }

            // 長方形の台 (中心 c・半分の大きさ hs) の外へ、幅 w で元の地面にもどる割合 (台の上は 0)
            float PadMask(float2 xz, float2 c, float2 hs, float w)
            {
                float2 d = abs(xz - c) - hs;
                return smoothstep(0.0, w, max(d.x, d.y));
            }

            // 地面の高さ: 台地と砂丘。ピラミッドの下は平らにならし、スフィンクスのまわりは掘り下げた囲い
            float Height(float2 xz)
            {
                float h = Plateau(xz.y) + 0.008 * Fbm3(xz * 7.0 + 3.7);
                h = lerp(Plateau(KHUFU.y), h, PadMask(xz, float2(-0.3, 0.15), float2(0.135, 0.17), 0.04));
                h = lerp(Plateau(KHAFRE.y), h, PadMask(xz, KHAFRE, float2(0.125, 0.125), 0.04));
                h = lerp(Plateau(MENKAURE.y), h, PadMask(xz, float2(0.36, -0.39), float2(0.09, 0.065), 0.04));
                h = lerp(GROUND - 0.008, h, PadMask(xz, SPHINX, float2(0.028, 0.05), 0.006));
                return h;
            }

            float HeightFast(float2 xz)
            {
                [branch] if (_HeightTexOn > 0.5)
                    return SAMPLE_TEXTURE2D_LOD(_HeightTex, sampler_linear_clamp, xz / (2.0 * INNER) + 0.5, 0).r;
                return Height(xz);
            }

            // ---------------------------------------------------------------- ピラミッド

            // 石を段に積んだピラミッド。q は底の中心から。hs は底辺の半分、h0 は元の頂点の高さ、top は今の高さ。
            // 段は 1 段ずつ箱にして、今の段と上下の段だけを調べる。
            // cased より上は、なめらかな化粧石 (カフラー王の頂上)。layer に何段目かを返す
            float StepPyramid(float3 q, float hs, float h0, float top, float cased, out float layer)
            {
                float y = q.y;
                float ax = max(abs(q.x), abs(q.z));
                layer = floor(y / COURSE);
                float slope = hs / h0;
                float plane = (ax - hs + max(y, 0.0) * slope) * rsqrt(1.0 + slope * slope);
                float far = max(max(plane, -y), y - top);
                if (far > 0.004) return far - 0.001; // 段は少し外へはみ出すので、その分だけ控えめに
                float d = 1e5;
                for (int j = -1; j <= 1; j++)
                {
                    float k = layer + j;
                    if (k < 0.0) continue;
                    float y0 = k * COURSE;
                    if (y0 >= top || y0 >= cased) continue;
                    float y1 = min(min(y0 + COURSE, top), cased);
                    float w = hs * (1.0 - (y0 + COURSE * 0.5) / h0);
                    d = min(d, SdBox(float3(q.x, y - (y0 + y1) * 0.5, q.z), float3(w, (y1 - y0) * 0.5, w)));
                }
                if (cased < top)
                    d = min(d, max(max(plane, cased - COURSE - y), y - top));
                return d;
            }

            // 3 つのピラミッドと、6 つの王妃のピラミッド。part: 0 石灰岩 / 1 化粧石 / 2 花こう岩 / 3 目印の柱
            float Pyramids(float3 p, out float part)
            {
                part = 0;
                float layer;
                float d = 1e5;
                // クフ王: 底辺 230.3 m・元の高さ 146.6 m・今の高さ 138.5 m
                float3 q = p - float3(KHUFU.x, Plateau(KHUFU.y), KHUFU.y);
                d = StepPyramid(q, 0.1267, 0.1613, 0.1524, 1.0, layer);
                float mast = max(length(q.xz) - 0.0003, max(0.1524 - q.y, q.y - 0.1613));
                if (mast < d) part = 3;
                d = min(d, mast);
                // クフ王の王妃のピラミッド (東に 3 つ)
                for (int i = 0; i < 3; i++)
                {
                    float3 qq = q - float3(-0.06 + i * 0.06, 0, 0.162);
                    float dq = StepPyramid(qq, 0.024, 0.033, 0.03, 1.0, layer);
                    if (dq < d) part = 0;
                    d = min(d, dq);
                }
                // カフラー王: 底辺 215.3 m・元の高さ 143.5 m・今の高さ 136.4 m。上の 25 m に化粧石が残る
                q = p - float3(KHAFRE.x, Plateau(KHAFRE.y), KHAFRE.y);
                float dk = StepPyramid(q, 0.1184, 0.1579, 0.15, 0.123, layer);
                if (dk < d) part = q.y > 0.122 ? 1 : 0;
                d = min(d, dk);
                // メンカウラー王: 底辺 102.2 m・元の高さ 65.5 m・今の高さ 61 m。下の 16 段は赤い花こう岩
                q = p - float3(MENKAURE.x, Plateau(MENKAURE.y), MENKAURE.y);
                float dm = StepPyramid(q, 0.0567, 0.072, 0.067, 1.0, layer);
                if (dm < d) part = q.y < 16.0 * COURSE ? 2 : 0;
                d = min(d, dm);
                for (int k = 0; k < 3; k++)
                {
                    float3 qq = q - float3(0.0867, 0, -0.045 + k * 0.045);
                    float dq = StepPyramid(qq, 0.016, 0.022, 0.02, 1.0, layer);
                    if (dq < d) part = 0;
                    d = min(d, dq);
                }
                return d;
            }

            // ---------------------------------------------------------------- 大スフィンクス (長さ 73 m・高さ 20 m・幅 19 m。東 = +z を向く)

            float Sphinx(float3 p)
            {
                float3 q = p - float3(SPHINX.x, GROUND - 0.008, SPHINX.y);
                if (length(q - float3(0, 0.011, 0)) > 0.06) return length(q - float3(0, 0.011, 0)) - 0.055;
                float3 s = float3(abs(q.x), q.y, q.z);
                // 胴: 伏せた獅子の背中。後ろ足の腰が少し盛り上がる
                float body = SdRoundBox(q - float3(0, 0.0075, -0.012), float3(0.0095, 0.0075, 0.028), 0.004);
                float haunch = SdEllipsoidLite(s - float3(0.006, 0.0075, -0.03), float3(0.0055, 0.0075, 0.011));
                float chest = SdEllipsoidLite(q - float3(0, 0.0095, 0.012), float3(0.0085, 0.0095, 0.008));
                // 前にのびる前足 (長さ 15 m)
                float paw = SdRoundBox(s - float3(0.0055, 0.0024, 0.026), float3(0.0032, 0.0024, 0.016), 0.0013);
                // 頭: 顔と、ネメス頭巾 (上がすぼまった頭巾と、胸へ垂れる左右の垂れ布)
                float face = SdEllipsoidLite(q - float3(0, 0.0172, 0.0192), float3(0.0026, 0.0042, 0.003));
                float neck = SdEllipsoidLite(q - float3(0, 0.0135, 0.0155), float3(0.0042, 0.004, 0.004));
                float w = 0.0046 - max(q.y - 0.017, 0.0) * 0.35;
                float nemes = SdRoundBox(q - float3(0, 0.0182, 0.0168), float3(max(w, 0.0018), 0.0036, 0.0034), 0.0012);
                nemes = max(nemes, -SdBox(q - float3(0, 0.0168, 0.0215), float3(0.0024, 0.005, 0.0025))); // 顔の前はあける
                float lappet = SdRoundBox(s - float3(0.0034, 0.013, 0.018), float3(0.0011, 0.0038, 0.0014), 0.0005);
                float d = min(min(body, haunch), min(chest, paw));
                d = min(d, min(min(face, nemes), min(lappet, neck)));
                // 後ろに丸めた尾 (右側)
                d = min(d, SdCapsule(q, float3(-0.009, 0.0012, -0.038), float3(-0.0105, 0.0012, -0.015), 0.0007));
                return d;
            }

            // ---------------------------------------------------------------- ラクダの隊列

            #define CAMELS 4
            float3 CamelPos(int i, out float2 dir)
            {
                // 東の砂漠を、南から北へゆっくり進み、また南から現れる
                float t = _Time.y;
                float u = frac(t * 0.006 + 0.3) * 1.0;
                float x = lerp(0.45, -0.1, u) + i * 0.012;
                float z = 0.3 + 0.02 * sin(x * 9.0);
                dir = normalize(float2(-1.0, 0.18 * cos(x * 9.0)));
                return float3(x, HeightFast(float2(x, z)), z);
            }

            float Camels(float3 p)
            {
                if (p.y > GROUND + 0.02 || p.z < 0.26 || p.z > 0.34) return max(max(p.y - GROUND - 0.016, 0.26 - p.z), max(p.z - 0.34, 0.003));
                float d = 1e5;
                float t = _Time.y;
                for (int i = 0; i < CAMELS; i++)
                {
                    float2 dir;
                    float3 c = CamelPos(i, dir);
                    float3 r = p - c;
                    if (dot(r, r) > 0.006 * 0.006) { d = min(d, length(r) - 0.004); continue; }
                    // ラクダの向きにそろえる (x が前)
                    float3 q = float3(dot(r.xz, dir), r.y, dot(r.xz, float2(-dir.y, dir.x)));
                    float body = SdEllipsoidLite(q - float3(0, 0.0019, 0), float3(0.0013, 0.00055, 0.00045));
                    float hump = SdEllipsoidLite(q - float3(-0.0001, 0.0025, 0), float3(0.0006, 0.00045, 0.0004));
                    float neck = SdCapsule(q, float3(0.0011, 0.0021, 0), float3(0.0018, 0.0028, 0), 0.00018);
                    float head = SdEllipsoidLite(q - float3(0.0021, 0.0028, 0), float3(0.00035, 0.00016, 0.00014));
                    float rider = SdCapsule(q, float3(-0.0001, 0.0028, 0), float3(-0.0001, 0.0036, 0), 0.00022);
                    float legs = 1e5;
                    for (int k = 0; k < 4; k++)
                    {
                        float fx = k < 2 ? 0.0009 : -0.0009;
                        float fz = (k % 2 == 0) ? 0.0003 : -0.0003;
                        float swing = sin(t * 4.0 + i * 1.3 + k * 1.57) * 0.0003;
                        legs = min(legs, SdCapsule(q, float3(fx, 0.0016, fz), float3(fx + swing, 0.0, fz), 0.00012));
                    }
                    d = min(d, min(min(min(body, hump), min(neck, head)), min(rider, legs)));
                }
                return d;
            }

            // ---------------------------------------------------------------- 世界の形

            float2 MapX(float3 p, bool exact)
            {
                float2 res = float2(SdBox(p - float3(0, -0.46, 0), float3(0.5, 0.04, 0.5)), ID_BASE);
                float column = SdBox(p - float3(0, 0.04, 0), float3(INNER, 0.46, INNER));
                float h = exact ? Height(p.xz) : HeightFast(p.xz);
                float ground = max((p.y - h) * 0.7, column);
                if (ground < res.x) res = float2(ground, ID_GROUND);
                float part;
                float pyr = Pyramids(p, part);
                if (pyr < res.x) res = float2(pyr, ID_PYRAMID);
                float sph = Sphinx(p);
                if (sph < res.x) res = float2(sph, ID_SPHINX);
                float cam = Camels(p);
                if (cam < res.x) res = float2(cam, ID_CAMEL);
                return res;
            }

            float2 Map(float3 p) { return MapX(p, false); }

            float3 SceneNormal(float3 p)
            {
                const float2 e = float2(0.0002, -0.0002);
                float3 g = e.xyy * MapX(p + e.xyy, true).x + e.yyx * MapX(p + e.yyx, true).x + e.yxy * MapX(p + e.yxy, true).x + e.xxx * MapX(p + e.xxx, true).x;
                return g / max(length(g), 1e-7);
            }

            float SoftShadow(float3 p, float3 l)
            {
                float res = 1.0;
                float t = 0.001;
                int n = max((int)_ShadowSteps, 8);
                for (int i = 0; i < 32; i++)
                {
                    if (i >= n) break;
                    float3 sp = p + l * t;
                    if (sp.y > -0.13) break; // ピラミッドより上に出たら、もう何にも当たらない
                    float h = Map(sp).x;
                    res = min(res, 16.0 * h / t);
                    t += clamp(h, 0.001, 0.05);
                    if (res < 0.01 || t > 1.4) break;
                }
                return saturate(res);
            }

            float AmbientOcclusion(float3 p, float3 n)
            {
                float occ = 0.0;
                float w = 1.0;
                for (int i = 1; i <= 4; i++)
                {
                    float d = 0.004 * i;
                    occ += (d - Map(p + n * d).x) * w;
                    w *= 0.6;
                }
                return saturate(1.0 - occ * 18.0);
            }

            // ---------------------------------------------------------------- 仕掛け: 砂嵐と、そのあとの夕日

            // 砂嵐の強さ (最初の 6〜9 秒)、夕日の強まり (そのあと)
            float Storm() { return _Event * (1.0 - smoothstep(5.5, 9.0, _EventTime)); }
            float Blaze() { return _Event * smoothstep(6.0, 9.5, _EventTime); }

            // 砂嵐の濃さ: 低い所ほど濃く、西から東へ (+z へ) 流れる
            float Dust(float3 p)
            {
                float y = p.y - GROUND;
                float3 q = p * float3(9.0, 14.0, 9.0) - float3(0, 0, _Time.y * 1.6);
                float n = Noise3(q) * 0.6 + Noise3(q * 2.3 + 7.1) * 0.4;
                return saturate(n * 1.6 - 0.35) * exp(-max(y, 0.0) / 0.09);
            }

            // ---------------------------------------------------------------- 質感 (つやのある、本物らしい光り方)

            // 表面の細かい凹凸で、向きを少しゆらす (近くで見ると、手ざわりのある陰影が出る)
            float3 BumpNormal(float3 n, float3 p, float freq, float amount)
            {
                float e = 0.35 / freq;
                float n0 = Noise3(p * freq);
                float3 g = float3(Noise3((p + float3(e, 0, 0)) * freq), Noise3((p + float3(0, e, 0)) * freq), Noise3((p + float3(0, 0, e)) * freq)) - n0;
                g -= n * dot(g, n);
                return normalize(n - g * amount);
            }

            // 材質ごとの光り方。
            //   rough: 0 つるつる 〜 1 ざらざら (つるつるほど、光の照り返しが小さく強い)
            //   f0: 正面から見たときの映り込みの強さ (ななめから見るほど、空が強く映る)
            //   sss: 光が透ける強さ (葉・草・紙は、逆光で光って見える)
            float3 Surface(float3 albedo, float3 n, float3 v, float3 L, float3 sunCol, float sh, float ao,
                           float rough, float f0, float sss, float3 skyTop, float3 skyLow)
            {
                float ndl = saturate(dot(n, L));
                float ndv = saturate(dot(n, v)) + 1e-4;
                float3 h = normalize(L + v);
                float ndh = saturate(dot(n, h));
                float a = max(rough * rough, 0.002);
                float a2 = a * a;
                float dd = ndh * ndh * (a2 - 1.0) + 1.0;
                float D = a2 / (3.14159 * dd * dd);
                float k = a * 0.5;
                float Vis = 0.25 / ((ndl * (1.0 - k) + k) * (ndv * (1.0 - k) + k));
                float F = f0 + (1.0 - f0) * pow(1.0 - saturate(dot(h, v)), 5.0);
                float3 direct = sunCol * sh * ndl * (albedo * (1.0 - F) + D * Vis * F);
                // まわりの空の光: 上を向く面ほど空の上の色、横向きは地平線の色。ななめから見ると空が映る
                float3 skyDiffuse = lerp(skyLow, skyTop, saturate(n.y * 0.5 + 0.5));
                float3 r = reflect(-v, n);
                float3 skySpec = lerp(skyLow, skyTop, saturate(r.y));
                float Fv = f0 + (1.0 - f0) * pow(1.0 - ndv, 5.0);
                float3 ambient = (albedo * skyDiffuse * (1.0 - Fv) + skySpec * Fv * (1.0 - rough * 0.8)) * ao;
                // 光が透ける: 逆光の葉や草が、明るく光って見える
                float back = pow(saturate(dot(v, -L)), 4.0) * sss;
                float3 trans = albedo * sunCol * back * (0.5 + 0.5 * sh) * 0.8;
                return direct + ambient + trans;
            }

            // ---------------------------------------------------------------- 色を塗る

            // 夕焼けの空: 地平線は橙と桃色、上は紫がかった青。西に沈みかけの太陽
            float3 Sky(float3 rd)
            {
                float3 L = normalize(SUN_DIR);
                float up = saturate(rd.y);
                float blaze = Blaze();
                float3 c = lerp(float3(1.0, 0.55, 0.3), float3(0.18, 0.2, 0.42), pow(up, 0.45));
                c = lerp(c, float3(0.95, 0.5, 0.55), exp(-up * 6.0) * 0.35 * (1.0 - saturate(dot(rd.xz, normalize(L.xz)))));
                float sd = dot(rd, L);
                float3 sun = float3(4.0, 2.4, 1.0) * (1.0 + blaze);
                c += sun * smoothstep(0.9994, 0.9997, sd) + float3(1.0, 0.45, 0.15) * pow(saturate(sd), 12.0) * (0.5 + 0.8 * blaze);
                // 細い雲が夕日に染まる
                float2 cp = rd.xz / max(rd.y + 0.08, 0.02);
                float cloud = smoothstep(0.55, 0.8, Fbm3(cp * float2(1.2, 4.0) + 3.0)) * smoothstep(0.02, 0.15, rd.y) * smoothstep(0.6, 0.25, rd.y);
                c = lerp(c, float3(1.0, 0.5, 0.35) * (0.6 + 0.8 * pow(saturate(sd * 0.5 + 0.5), 4.0)), cloud * 0.6);
                return c;
            }

            float3 Shade(float3 ro, float3 rd, float3 p, float id, float3 faceNormal)
            {
                float3 L = normalize(SUN_DIR);
                float storm = Storm();
                float blaze = Blaze();
                float3 sunCol = float3(2.6, 1.35, 0.6) * (1.0 - 0.75 * storm) * (1.0 + 0.6 * blaze) * lerp(float3(1, 1, 1), float3(1.1, 0.8, 0.6), blaze);
                float3 skyTop = float3(0.12, 0.13, 0.27);
                float3 skyLow = float3(0.42, 0.26, 0.2) * (1.0 + 1.5 * storm);
                float3 v = -rd;

                if (id == ID_BASE)
                    return float3(0.015, 0.014, 0.014) + 0.03 * pow(saturate(1.0 - abs(dot(rd, faceNormal))), 4.0);

                float3 n = SceneNormal(p);
                float sh = SoftShadow(p + n * 0.0006, L);
                float ao = AmbientOcclusion(p, n);

                if (id == ID_PYRAMID)
                {
                    float part;
                    Pyramids(p, part);
                    if (part > 2.5)
                        return Surface(float3(0.35, 0.3, 0.25), n, v, L, sunCol, sh, ao, 0.6, 0.04, 0.0, skyTop, skyLow); // 目印の柱
                    // 石の積み方: 段ごとに、横に 1.2〜1.8 m の石が互い違いに並ぶ。石ごとに色と風化が少し違う
                    float layer = floor((p.y - GROUND) / COURSE);
                    float u = abs(n.x) > abs(n.z) ? p.z : p.x;
                    float bw = 0.0017 + 0.0005 * Hash21(float2(layer, 3.0));
                    float bi = floor(u / bw + Hash21(float2(layer, 7.0)));
                    float bf = frac(u / bw + Hash21(float2(layer, 7.0)));
                    float stone = Hash21(float2(bi, layer));
                    float3 lime = float3(0.82, 0.66, 0.46) * (0.82 + 0.25 * stone) * (0.85 + 0.15 * Noise3(p * 3000.0));
                    float joint = smoothstep(0.06, 0.0, min(bf, 1.0 - bf)) * step(abs(n.y), 0.7);
                    lime *= 1.0 - 0.35 * joint;
                    float rough = 0.85;
                    if (part > 0.5 && part < 1.5)
                    {
                        lime = float3(0.9, 0.82, 0.68) * (0.92 + 0.08 * Noise3(p * 2000.0)); // なめらかな化粧石
                        rough = 0.45;
                    }
                    if (part > 1.5)
                        lime = float3(0.58, 0.36, 0.3) * (0.8 + 0.3 * stone);                 // 赤い花こう岩
                    // クフ王の北の面の入口 (少し東寄り。暗い穴)
                    float3 kq = p - float3(KHUFU.x, Plateau(KHUFU.y), KHUFU.y);
                    if (n.x < -0.3 && abs(kq.z + 0.008) < 0.0022 && abs(kq.y - 0.018) < 0.003) lime *= 0.15;
                    float3 nb = BumpNormal(n, p, 4000.0, 0.35);
                    return Surface(lime, nb, v, L, sunCol, sh, ao, rough, 0.04, 0.0, skyTop, skyLow);
                }

                if (id == ID_SPHINX)
                {
                    // 石灰岩の地層: 硬い層と、風に削られたやわらかい層が、横縞になる
                    float3 q = p - float3(SPHINX.x, GROUND - 0.008, SPHINX.y);
                    float band = frac(q.y / 0.0021);
                    float3 rock = lerp(float3(0.78, 0.6, 0.4), float3(0.62, 0.46, 0.3), smoothstep(0.4, 0.6, band)) * (0.85 + 0.2 * Noise3(p * 2500.0));
                    // ネメス頭巾の縦じま (頭のまわりだけ)
                    if (q.y > 0.0145 && q.z > 0.012 && q.z < 0.021)
                        rock *= 1.0 - 0.18 * step(0.5, frac(q.y / 0.0006));
                    float3 nb = BumpNormal(n, p, 3000.0, 0.8);
                    return Surface(rock, nb, v, L, sunCol, sh, ao, 0.9, 0.03, 0.0, skyTop, skyLow);
                }

                if (id == ID_CAMEL)
                    return Surface(float3(0.45, 0.32, 0.2), n, v, L, sunCol, sh, ao, 0.9, 0.03, 0.0, skyTop, skyLow);

                if (max(abs(p.x), abs(p.z)) > INNER - 0.0015 && abs(n.y) < 0.5)
                    return Surface(float3(0.5, 0.36, 0.22) * (0.8 + 0.4 * Noise3(p * 900.0)), n, v, L, sunCol, 1.0, 1.0, 0.9, 0.03, 0.0, skyTop, skyLow); // 地面の切り口

                // 砂: 風紋 (風に直角な細かい波)。ピラミッドのまわりは、石のかけらまじりの固い地面
                float rip = sin(dot(p.xz, float2(0.35, 0.94)) * 2600.0 + Noise3(p * 400.0) * 6.0);
                float3 nr = normalize(n + float3(0.35, 0.0, 0.94) * rip * 0.12);
                float rocky = 1.0 - min(min(PadMask(p.xz, float2(-0.3, 0.15), float2(0.135, 0.17), 0.04), PadMask(p.xz, KHAFRE, float2(0.125, 0.125), 0.04)),
                                        PadMask(p.xz, float2(0.36, -0.39), float2(0.09, 0.065), 0.04));
                float3 sand = float3(0.86, 0.62, 0.38) * (0.85 + 0.2 * Noise3(p * 600.0));
                float3 hard = float3(0.7, 0.55, 0.38) * (0.75 + 0.35 * Hash21(floor(p.xz / 0.0012)));
                float3 albedo = lerp(sand, hard, rocky * 0.7);
                float3 nb = lerp(nr, BumpNormal(n, p, 3000.0, 0.6), rocky);
                float3 col = Surface(albedo, nb, v, L, sunCol, sh, ao, 0.9, 0.03, 0.0, skyTop, skyLow);
                // 砂嵐の最中: 地面を走る砂の筋
                if (storm > 0.01)
                {
                    float streak = smoothstep(0.6, 0.9, Noise3(float3(p.x * 300.0, 0, p.z * 40.0 - _Time.y * 8.0)));
                    col += float3(0.9, 0.6, 0.35) * streak * storm * 0.08;
                }
                return col;
            }

            // ---------------------------------------------------------------- 本体

            float2 BoxHit(float3 ro, float3 rd, float3 b)
            {
                float3 m = 1.0 / rd;
                float3 n = m * ro;
                float3 k = abs(m) * b;
                float3 t1 = -n - k;
                float3 t2 = -n + k;
                return float2(max(max(t1.x, t1.y), t1.z), min(min(t2.x, t2.y), t2.z));
            }

            Varyings Vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.positionOS = input.positionOS.xyz;
                return output;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);

                float3 ro = TransformWorldToObject(GetCameraPositionWS());
                float3 rd = normalize(input.positionOS - ro);
                float2 box = BoxHit(ro, rd, float3(0.5, 0.5, 0.5));
                bool outside = box.x > 0.0;
                float t = max(box.x, 0.0);

                float3 entry = ro + rd * t;
                float3 ae = abs(entry);
                float3 faceNormal = ae.x > ae.y && ae.x > ae.z ? float3(sign(entry.x), 0, 0)
                                  : (ae.y > ae.z ? float3(0, sign(entry.y), 0) : float3(0, 0, sign(entry.z)));

                const float maxHeight = -0.135; // カフラー王のピラミッドのてっぺんより少し上
                if (ro.y > maxHeight && rd.y < 0.0) t = max(t, (maxHeight - ro.y) / rd.y);
                float tStart = t;

                bool hit = false;
                float id = 0.0;
                int steps = (int)_Steps;
                for (int i = 0; i < 200; i++)
                {
                    if (i >= steps || t > box.y) break;
                    float3 pos = ro + rd * t;
                    if (rd.y > 0.0 && pos.y > maxHeight + 0.002) break;
                    float2 m = Map(pos);
                    if (m.x < 0.00003 + 0.0003 * t)
                    {
                        hit = true;
                        id = m.y;
                        break;
                    }
                    t += m.x;
                }
                float tHit = hit ? t : box.y;

                float3 col = 0;
                if (hit) col = Shade(ro, rd, ro + rd * t, id, faceNormal);
                else if (!outside) col = Sky(rd);

                // 夕方の空気: 遠くほど、橙色にかすむ
                float travel = tHit - max(box.x, 0.0);
                if (hit) col = lerp(col, float3(0.95, 0.6, 0.4), (1.0 - exp(-travel * 0.6)) * 0.15);
                float alpha = (hit || !outside) ? 1.0 : 0.0;

                // 砂嵐: 視線にそって砂の濃さを足し合わせる (仕掛けの最中だけ)
                float storm = Storm();
                if (storm > 0.01)
                {
                    float3 L = normalize(SUN_DIR);
                    float t0 = max(box.x, 0.0);
                    float t1 = min(tHit, t0 + 1.2);
                    float dt = (t1 - t0) / 12.0;
                    float trans = 1.0;
                    float3 dust = 0;
                    for (int k = 0; k < 12; k++)
                    {
                        float3 pos = ro + rd * (t0 + dt * (k + Hash21(input.positionCS.xy + k)));
                        if (max(abs(pos.x), abs(pos.z)) > INNER) continue;
                        float dens = Dust(pos) * storm * 14.0;
                        float a = 1.0 - exp(-dens * dt);
                        float3 lit = float3(1.0, 0.62, 0.36) * (0.45 + 0.6 * pow(saturate(dot(rd, L) * 0.5 + 0.5), 3.0));
                        dust += trans * a * lit;
                        trans *= 1.0 - a;
                    }
                    col = col * trans + dust;
                    alpha = alpha + (1.0 - alpha) * (1.0 - trans);
                }

                if (outside)
                {
                    float fres = 0.04 + 0.96 * pow(1.0 - saturate(dot(-rd, faceNormal)), 5.0);
                    float k = fres * _Glass;
                    col = col * (1.0 - k) + float3(0.75, 0.8, 0.85) * 0.5 * k;
                    alpha = alpha + (1.0 - alpha) * k;
                    float3 d = 0.5 - ae;
                    float edge = d.x + d.y + d.z - max(d.x, max(d.y, d.z));
                    float frame = 1.0 - smoothstep(0.004, 0.006, edge);
                    col = col * (1.0 - frame) + (float3(0.05, 0.05, 0.055) + 0.15 * fres) * frame;
                    alpha = alpha + (1.0 - alpha) * frame;
                }

                col = min(max(col, 0.0), 64.0);
                alpha = min(max(alpha, 0.0), 1.0);
                if (alpha < 0.01 && max(col.r, max(col.g, col.b)) < 0.002) discard;
                return half4(col, alpha);
            }
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }
            Cull Front
            ZWrite On
            ColorMask R

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex DepthVert
            #pragma fragment DepthFrag
            #pragma multi_compile_instancing

            struct Attributes
            {
                float4 positionOS : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings DepthVert(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                return output;
            }

            half DepthFrag(Varyings input) : SV_Target
            {
                return input.positionCS.z;
            }
            ENDHLSL
        }
    }
}
