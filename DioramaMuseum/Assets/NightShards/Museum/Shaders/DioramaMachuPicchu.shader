// 作品「マチュピチュ」(アンデスの間)。晴れた日の空中都市。見張り小屋の高台から見下ろす、絵はがきの眺めを再現した。URP 用。
// Cube の中をレイマーチングして描く。Cube の座標は -0.5〜0.5、下の 0.08 は黒い台。
//
// 形は実物の寸法 (1 m = 0.0007)。美術館の正面 (+z) が南、右 (-x) が東。
//   ・尾根の上の都市: まん中に細長い緑の大広場。左 (西) は少し高い神殿の地区、右 (東) は段々に下がる住居の地区。
//     屋根のない灰色の石の家が、すきまなくびっしり並ぶ (高さも向きも少しずつ違う。半分ほどは両はしに三角の破風)。
//     段の境は石垣。インティワタナの丘、半円の壁の太陽の神殿
//   ・手前と右の斜面に、明るい緑の段々畑と石垣。見張り小屋とリャマ
//   ・奥にそびえる、とがって急なワイナピチュと、その左の小さなウチュイピチュ
//   ・左右には、深い緑の高い山並み。右の深い谷の底には、ウルバンバ川が白く光る。奥には青くかすむ山々
// 仕掛け (_Event 0〜1): 谷から雲海がわき上がって都市をすっかり包み、やがて引いて、金色の日差しが都市を照らし出す
//
// 軽くする工夫: 地形は高さの表 (_HeightTex) で進み、坂の急さに合わせて歩幅を決める。当たったら、正確な式で 2 回合わせ直す。
//   神殿・リャマの高さは、画素ごとに 1 回だけ調べて使い回す。雲海は仕掛けの最中だけ計算する
//
// 外から見たとき、何もない所 (空) は透明にして、ガラスケースの向こうの部屋が見えるようにする。
// 中に入ったとき (カメラが箱の中) だけ、空を描く
Shader "NightShards/Diorama/MachuPicchu"
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
            #pragma use_dxc vulkan // Quest (Vulkan) 用は新しいコンパイラー (DXC) で変換する。古いほうだと大きいシェーダーが時間切れになる
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

            float SdCapsule(float3 p, float3 a, float3 b, float r)
            {
                float3 pa = p - a, ba = b - a;
                float h = saturate(dot(pa, ba) / dot(ba, ba));
                return length(pa - ba * h) - r;
            }

            float SdEllipsoidLite(float3 p, float3 r)
            {
                float k0 = length(p / r);
                float k1 = length(p / (r * r));
                return k0 * (k0 - 1.0) / max(k1, 1e-6);
            }

            // ---------------------------------------------------------------- 場所と寸法 (1 m = 0.0007)
            // ※ Height() と建物の置き方を変えたら、C# の DioramaTerrain (MachuPicchu) も同じに直す (歩く地面と当たり判定)

            #define ID_BASE    0.0
            #define ID_GROUND  1.0
            #define ID_HOUSE   2.0
            #define ID_THATCH  3.0
            #define ID_TEMPLE  4.0
            #define ID_LLAMA   5.0

            #define CITY_Y -0.07                                   // 大広場の高さ
            #define RIVER_Y -0.37                                  // 谷底 (ウルバンバ川)
            #define TERRACE_H 0.0021                               // 段々畑の 1 段 (約 3 m)
            #define CELL_X 0.0105                                  // 家を並べるます目 (15 m × 12 m)
            #define CELL_Z 0.0085
            #define LLAMAS 5
            static const float2 HUAYNA = float2(-0.01, -0.3);      // ワイナピチュの頂上
            static const float2 HUCHUY = float2(0.05, -0.205);     // ウチュイピチュ (小さな峰)
            static const float2 INTI = float2(0.055, -0.085);      // インティワタナの丘
            static const float2 TORREON = float2(0.045, 0.06);     // 太陽の神殿
            static const float2 GUARD = float2(0.075, 0.21);       // 見張り小屋
            static const float3 SUN_DIR = float3(0.55, 0.7, 0.45); // 左手前の高い日差し

            // 画素ごとに 1 回だけ調べて使い回す高さ (Frag の最初で入れる)
            static float gIntiY, gTorreonY, gGuardY;
            static float3 gLlama[LLAMAS];
            static float2 gLlamaDir[LLAMAS];

            // ---------------------------------------------------------------- 地形

            float RidgeX(float z) { return 0.012 * sin(z * 6.0); }

            float CityMask(float2 xz)
            {
                float ax = abs(xz.x - RidgeX(xz.y));
                return (1.0 - smoothstep(0.09, 0.1, ax)) * smoothstep(-0.14, -0.12, xz.y) * (1.0 - smoothstep(0.14, 0.16, xz.y));
            }

            float TerraceMask(float2 xz)
            {
                float ax = abs(xz.x - RidgeX(xz.y));
                float slopeBand = smoothstep(0.095, 0.105, ax) * (1.0 - smoothstep(0.17, 0.19, ax)) * smoothstep(-0.08, -0.05, xz.y) * (1.0 - smoothstep(0.2, 0.22, xz.y));
                float south = smoothstep(0.13, 0.15, xz.y) * (1.0 - smoothstep(0.12, 0.14, ax)) * (1.0 - smoothstep(0.29, 0.31, xz.y));
                return saturate(max(slopeBand, south));
            }

            // 段: 幅 w ごとに高さ TERRACE_H ずつ下がる (段の境の石垣は急)
            float Steps(float u, float w) { float f = u / w; return (floor(f) + smoothstep(0.85, 1.0, frac(f))) * TERRACE_H; }

            float Height(float2 xz)
            {
                float x = xz.x, z = xz.y;
                float ax = abs(x - RidgeX(z));
                // 尾根: 都市の所は幅広く、北の鞍部で細く低くなる。南のはしは谷へ下がる
                float north = smoothstep(0.13, 0.23, -z);
                float w = lerp(0.1, 0.025, north);
                // 南 (手前) は見張り小屋の丘へ上がり (段々畑)、そのさきで谷へ下がる
                float ridge = CITY_Y - 0.035 * north - 1.3 * max(ax - w, 0.0) + 0.15 * clamp(z - 0.13, 0.0, 0.17) - 2.6 * max(z - 0.32, 0.0);
                // ワイナピチュ (都市より 290 m 高い、急なとがった山) と、ウチュイピチュ
                float2 hq = (xz - HUAYNA) * float2(1.0, 1.25);
                float r = length(hq);
                float huayna = 0.19 - 1.0 * r - 9.0 * r * r + 0.03 * (Fbm3(xz * 13.0 + 5.0) - 0.4);
                float r2 = length(xz - HUCHUY);
                float huchuy = -0.035 - 1.0 * r2 - 25.0 * r2 * r2;
                // 左右と奥の高い山並み (尾根と谷筋のある、けわしい山)
                float ridged = 1.0 - abs(ValueNoise(float2(x * 9.0 + 3.0, z * 9.0)) * 2.0 - 1.0);
                float left = smoothstep(0.24, 0.46, x) * (1.0 - smoothstep(0.15, 0.32, z));
                float right = smoothstep(0.26, 0.47, -x) * (1.0 - smoothstep(0.05, 0.3, z));
                float back = smoothstep(0.3, 0.47, -z);
                float ridged2 = 1.0 - abs(ValueNoise(float2(x * 20.0 - 4.0, z * 20.0 + 1.0)) * 2.0 - 1.0);
                float mm = max(max(0.48 * left, 0.45 * right), 0.42 * back);
                float mtn = RIVER_Y + mm * (0.5 + 0.25 * Fbm3(xz * 6.0 + 9.0) + 0.17 * ridged + 0.08 * ridged2);
                float h = max(max(ridge, huayna), max(huchuy, mtn));
                // 斜面の谷筋と尾根
                float depth = max(max(ax - w, z - 0.32), 0.0);
                float city = CityMask(xz);
                h += (0.03 * (Fbm3(xz * 9.0 + 2.0) - 0.4) + depth * 0.4 * (abs(ValueNoise(xz * 7.0 + 3.1) * 2.0 - 1.0) - 0.5)) * smoothstep(0.0, 0.04, depth) * (1.0 - city);
                // 都市: 大広場 (まん中・少し低い)、西の神殿の地区 (高い)、東の住居の地区 (東へ段々に下がる)
                float rx = x - RidgeX(z);
                float west = CITY_Y + 0.005 + 0.004 * smoothstep(0.0, 0.1, z) - Steps(max(rx - 0.065, 0.0), 0.011);
                float east = CITY_Y - Steps(max(-rx - 0.022, 0.0), 0.012);
                float cityH = rx > 0.022 ? west : (rx < -0.022 ? east : CITY_Y - 0.0015);
                h = lerp(h, cityH, city);
                // 段々畑
                float terr = (floor(h / TERRACE_H) + smoothstep(0.82, 1.0, frac(h / TERRACE_H))) * TERRACE_H;
                h = lerp(h, terr, TerraceMask(xz));
                return max(h, RIVER_Y);
            }

            float HeightFast(float2 xz)
            {
                [branch] if (_HeightTexOn > 0.5)
                    return SAMPLE_TEXTURE2D_LOD(_HeightTex, sampler_linear_clamp, xz / (2.0 * INNER) + 0.5, 0).r;
                return Height(xz);
            }

            // ---------------------------------------------------------------- 石の家 (屋根のない壁と、三角の破風)

            bool HouseAllowed(float2 c)
            {
                float rx = c.x - RidgeX(c.y);
                if (abs(rx) < 0.023 || abs(rx) > 0.09) return false;
                if (c.y < -0.12 || c.y > 0.135) return false;
                if (length(c - INTI) < 0.022 || length(c - TORREON) < 0.012) return false;
                return Hash21(c * 5.3 + 1.7) < 0.93;
            }

            float Houses(float3 p, out float part)
            {
                part = 0;
                float rx0 = p.x - RidgeX(p.z);
                float region = max(max(abs(rx0) - 0.095, max(-0.125 - p.z, p.z - 0.14)), p.y - (CITY_Y + 0.02));
                if (region > 0.002) return region;
                float2 cell = floor(p.xz / float2(CELL_X, CELL_Z));
                float2 c = (cell + 0.5) * float2(CELL_X, CELL_Z);
                float2 l = p.xz - c;
                float2 toEdge = 0.5 * float2(CELL_X, CELL_Z) - abs(l);
                float bound = max(min(toEdge.x, toEdge.y), 0.0) + 0.002;
                if (!HouseAllowed(c)) return bound;
                float base = HeightFast(c) - 0.003;           // 地面の下から立てる (段の上でも浮かないように)
                float y = p.y - base;
                float wallH = 0.0058 + 0.0016 * Hash21(c * 4.1);
                if (y > wallH + 0.0035) return min(y - wallH - 0.003, bound);
                float2 jit = (Hash22b(c * 7.7) - 0.5) * float2(0.0015, 0.001);
                float3 q = float3(l.x - jit.x, y, l.y - jit.y);
                // 細長い家は、向きが半々
                float2 hs = float2(0.0042, 0.003) + Hash21(c * 2.3) * float2(0.0008, 0.0006);
                if (Hash21(c * 9.1) < 0.4)
                {
                    q = float3(q.z, q.y, q.x);       // 向きを 90 度かえる (ます目は横長なので、少し小さく)
                    hs = float2(0.0034, 0.0028);
                }
                float outer = SdBox(q - float3(0, wallH * 0.5, 0), float3(hs.x, wallH * 0.5, hs.y));
                float inner = SdBox(q - float3(0, wallH * 0.5 + 0.003, 0), float3(hs.x - 0.00045, wallH * 0.5, hs.y - 0.00045));
                float d = max(outer, -inner);
                // 半分ほどの家は、短い辺の壁が三角に高い (破風)
                if (Hash21(c * 6.7) < 0.5)
                {
                    float gable = max(max(abs(abs(q.x) - (hs.x - 0.0002)) - 0.00022, abs(q.z) - hs.y), (q.y - wallH - 0.0032) + abs(q.z) * 1.1);
                    gable = max(gable, wallH - 0.0005 - q.y);
                    d = min(d, gable * 0.8);
                }
                // 戸口と台形の窓 (長い辺)
                d = max(d, -SdBox(q - float3(0, 0.003 + 0.0013, hs.y), float3(0.00055 - (q.y - 0.003) * 0.06, 0.0013, 0.001)));
                d = max(d, -SdBox(q - float3(hs.x * 0.55, wallH - 0.0012, hs.y), float3(0.0003, 0.0004, 0.001)));
                // 1 割ほどは、復元したかやぶき屋根
                if (Hash21(c * 3.1) < 0.1)
                {
                    float roof = max(max(abs(q.x) - hs.x - 0.0004, (q.y - wallH - 0.0045) + abs(q.z) * 1.3), wallH - 0.001 - q.y);
                    if (roof < d) part = 1;
                    d = min(d, roof * 0.75);
                }
                return min(d, bound);
            }

            // ---------------------------------------------------------------- 神殿 (インティワタナ・太陽の神殿・見張り小屋)

            float Temples(float3 p, out float part)
            {
                part = 0;
                float3 q = p - float3(INTI.x, gIntiY - 0.002, INTI.y);
                float d;
                if (length(q.xz) < 0.03)
                {
                    d = 1e5;
                    [loop] for (int k = 0; k < 4; k++)
                    {
                        float r = 0.016 - k * 0.0035;
                        d = min(d, max(length(q.xz * float2(1.0, 1.3)) - r, abs(q.y - (k + 0.5) * 0.003) - 0.0015));
                    }
                    d = min(d, SdBox(q - float3(0, 0.0125, 0), float3(0.0009, 0.0013, 0.0006)));
                }
                else d = length(q.xz) - 0.028;
                q = p - float3(TORREON.x, gTorreonY - 0.002, TORREON.y);
                float rock = SdEllipsoidLite(q - float3(0, 0.0015, 0), float3(0.007, 0.004, 0.006));
                float ring = max(abs(length(q.xz) - 0.0045) - 0.0005, abs(q.y - 0.0055) - 0.003);
                ring = max(ring, -q.x - 0.001);
                d = min(d, min(rock, ring));
                q = p - float3(GUARD.x, gGuardY - 0.001, GUARD.y);
                float hut = SdBox(q - float3(0, 0.002, 0), float3(0.004, 0.002, 0.0026));
                float roof = max(max(abs(q.x) - 0.0045, (q.y - 0.0072) + abs(q.z) * 1.6), 0.0035 - q.y) * 0.7;
                if (roof < min(d, hut)) part = 1;
                return min(d, min(hut, roof));
            }

            // ---------------------------------------------------------------- リャマ (体高 1.2 m)

            float3 LlamaPos(int i, out float2 dir)
            {
                float fi = i;
                float t = _Time.y * 0.03 + fi * 1.7;
                float2 c = float2(0.03 + 0.035 * sin(fi * 2.0), 0.2 + 0.03 * cos(fi * 1.3));
                float2 xz = c + float2(cos(t), sin(t)) * 0.01;
                dir = normalize(float2(-sin(t), cos(t)));
                return float3(xz.x, HeightFast(xz), xz.y);
            }

            float Llamas(float3 p)
            {
                float box = max(max(-0.02 - p.x, p.x - 0.09), max(max(0.15 - p.z, p.z - 0.25), p.y - (CITY_Y + 0.05)));
                if (box > 0.002) return box;
                float d = 1e5;
                [loop] for (int i = 0; i < LLAMAS; i++)
                {
                    float3 r = p - gLlama[i];
                    if (dot(r, r) > 0.003 * 0.003) { d = min(d, length(r) - 0.0025); continue; }
                    float2 dir = gLlamaDir[i];
                    float3 q = float3(dot(r.xz, dir), r.y, dot(r.xz, float2(-dir.y, dir.x)));
                    float body = SdEllipsoidLite(q - float3(0, 0.0009, 0), float3(0.0007, 0.00035, 0.0003));
                    float neck = SdCapsule(q, float3(0.0005, 0.001, 0), float3(0.0007, 0.0017, 0), 0.00012);
                    float head = SdEllipsoidLite(q - float3(0.0008, 0.0018, 0), float3(0.0002, 0.00011, 0.0001));
                    float legs = SdCapsule(float3(abs(q.x), q.y, abs(q.z)), float3(0.0005, 0.0008, 0.0002), float3(0.0005, 0.0, 0.0002), 0.00006);
                    d = min(d, min(min(body, neck), min(head, legs)));
                }
                return d;
            }

            // 画素ごとに 1 回: 神殿とリャマの高さ
            void PrepareFrame()
            {
                gIntiY = HeightFast(INTI);
                gTorreonY = HeightFast(TORREON);
                gGuardY = HeightFast(GUARD);
                [loop] for (int i = 0; i < LLAMAS; i++)
                {
                    float2 dir;
                    gLlama[i] = LlamaPos(i, dir);
                    gLlamaDir[i] = dir;
                }
            }

            // ---------------------------------------------------------------- 世界の形

            float2 MapX(float3 p, bool exact)
            {
                float2 res = float2(SdBox(p - float3(0, -0.46, 0), float3(0.5, 0.04, 0.5)), ID_BASE);
                float column = SdBox(p - float3(0, 0.04, 0), float3(INNER, 0.46, INNER));
                float ground;
                if (exact) ground = (p.y - Height(p.xz)) * 0.5;
                else
                {
                    // 高さの表で進む。地面から遠い所は、いちばん急な崖 (傾き 3) でも行き過ぎない歩幅。
                    // 地面のすぐ近くだけ、その場所の坂の急さを調べて、なだらかな所は大きく進む
                    float h = HeightFast(p.xz);
                    float above = p.y - h;
                    if (above > 0.008) ground = above * 0.31;
                    else
                    {
                        float hx = HeightFast(p.xz + float2(0.003, 0.0)), hz = HeightFast(p.xz + float2(0.0, 0.003));
                        float2 g = float2(hx - h, hz - h) / 0.003;
                        ground = above * 0.8 / sqrt(1.0 + dot(g, g) * 1.5);
                    }
                }
                ground = max(ground, column);
                if (ground < res.x) res = float2(ground, ID_GROUND);
                float part;
                float houses = Houses(p, part);
                if (houses < res.x) res = float2(houses, part > 0.5 ? ID_THATCH : ID_HOUSE);
                float tp;
                float temples = Temples(p, tp);
                if (temples < res.x) res = float2(temples, tp > 0.5 ? ID_THATCH : ID_TEMPLE);
                float ll = Llamas(p);
                if (ll < res.x) res = float2(ll, ID_LLAMA);
                return res;
            }

            float2 Map(float3 p) { return MapX(p, false); }

            float3 SceneNormal(float3 p)
            {
                const float2 e = float2(0.00015, -0.00015);
                float3 g = e.xyy * MapX(p + e.xyy, true).x + e.yyx * MapX(p + e.yyx, true).x + e.yxy * MapX(p + e.yxy, true).x + e.xxx * MapX(p + e.xxx, true).x;
                return g / max(length(g), 1e-12);
            }

            float SoftShadow(float3 p, float3 l)
            {
                float res = 1.0;
                float t = 0.003; // 高さの表は少しなまっているので、すぐ近くは調べない (急な斜面が自分の影に入らないように)
                int n = clamp((int)_ShadowSteps, 8, 16);
                [loop] for (int i = 0; i < 16; i++)
                {
                    if (i >= n) break;
                    float3 sp = p + l * t;
                    if (max(abs(sp.x), abs(sp.z)) > INNER) break; // 箱の外へ出たら、もう何もない (切り口が影を落とさないように)
                    if (sp.y > 0.25) break;
                    float h = Map(sp).x;
                    res = min(res, 14.0 * h / t);
                    t += clamp(h, 0.0015, 0.06);
                    if (res < 0.01 || t > 0.5) break;
                }
                return saturate(res);
            }

            float AmbientOcclusion(float3 p, float3 n)
            {
                float occ = 0.0;
                float w = 1.0;
                [loop] for (int i = 1; i <= 3; i++)
                {
                    float d = 0.003 * i;
                    occ += (d - Map(p + n * d).x) * w;
                    w *= 0.6;
                }
                return saturate(1.0 - occ * 30.0);
            }

            // ---------------------------------------------------------------- 雲海 (仕掛け)

            float Cover() { return _Event * smoothstep(0.0, 4.0, _EventTime) * (1.0 - smoothstep(7.0, 11.0, _EventTime)); }
            float Golden() { return _Event * smoothstep(8.0, 12.0, _EventTime); }
            float FogTop() { return lerp(-0.42, 0.02, Cover()); }

            float FogDensity(float3 p)
            {
                float top = FogTop() + 0.03 * (Noise3(float3(p.xz * 12.0, _Time.y * 0.05)) - 0.5);
                float k = 1.0 - smoothstep(top - 0.03, top, p.y);
                if (k <= 0.0) return 0.0;
                float n = Noise3(p * 30.0 + float3(_Time.y * 0.03, 0, 0)) * 0.6 + Noise3(p * 70.0) * 0.4;
                return k * saturate(n * 1.6 - 0.3);
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
                // まわりの空の光: 上を向く面ほど空の上の色、横向きは地平線の色。ななめから見ると空が映る (ざらざらの面ほど、映らない)
                float3 skyDiffuse = lerp(skyLow, skyTop, saturate(n.y * 0.5 + 0.5));
                float3 r = reflect(-v, n);
                float3 skySpec = lerp(skyLow, skyTop, saturate(r.y));
                float Fv = f0 + (1.0 - f0) * pow(1.0 - ndv, 5.0);
                float3 ambient = (albedo * skyDiffuse * (1.0 - Fv) + skySpec * Fv * (1.0 - rough) * (1.0 - rough)) * ao;
                // 光が透ける: 逆光の葉や草が、明るく光って見える
                float back = pow(saturate(dot(v, -L)), 4.0) * sss;
                float3 trans = albedo * sunCol * back * (0.5 + 0.5 * sh) * 0.8;
                return direct + ambient + trans;
            }

            // ---------------------------------------------------------------- 色を塗る

            // 朝の空: 東 (右) の地平線が明るい
            float3 Sky(float3 rd)
            {
                float3 L = normalize(SUN_DIR);
                float up = saturate(rd.y);
                // 高地の、濃い青空
                float3 c = lerp(float3(0.62, 0.78, 0.97), float3(0.04, 0.24, 0.75), pow(up, 0.55));
                // 山の上に浮かぶ、白いすじ雲
                float2 cp = rd.xz / max(rd.y + 0.05, 0.02);
                float cloud = smoothstep(0.5, 0.8, Fbm3(cp * float2(1.5, 3.0) + 7.0)) * smoothstep(0.02, 0.12, rd.y) * (1.0 - smoothstep(0.25, 0.5, rd.y));
                c = lerp(c, float3(1.0, 1.0, 1.0), cloud * 0.85);
                float sd = dot(rd, L);
                c += float3(4.0, 3.6, 3.0) * smoothstep(0.9994, 0.9997, sd) + float3(0.6, 0.55, 0.4) * pow(saturate(sd), 20.0) * 0.3;
                return c;
            }

            // 石垣の模様: インカの石組み (大きさのそろわない、ぴったり合わさった石)
            float StoneJoints(float2 uv, float size)
            {
                float row = floor(uv.y / size);
                float2 g = float2(uv.x / (size * (1.2 + 0.5 * Hash21(float2(row, 1.0)))) + Hash21(float2(row, 2.0)), uv.y / size);
                float2 f = frac(g);
                return 1.0 - smoothstep(0.0, 0.07, min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y)));
            }

            float3 Shade(float3 ro, float3 rd, float3 p, float id, float3 faceNormal)
            {
                float3 L = normalize(SUN_DIR);
                float golden = Golden();
                float3 sunCol = float3(2.3, 2.1, 1.85) * (1.0 + 0.3 * golden) * lerp(float3(1, 1, 1), float3(1.1, 0.85, 0.6), golden);
                float3 skyTop = float3(0.22, 0.38, 0.75);
                float3 skyLow = float3(0.45, 0.47, 0.45);
                float3 v = -rd;

                if (id == ID_BASE)
                    return float3(0.015, 0.014, 0.014) + 0.03 * pow(saturate(1.0 - abs(dot(rd, faceNormal))), 4.0);

                float3 n = SceneNormal(p);
                float sh = SoftShadow(p + n * 0.001, L);
                float ao = AmbientOcclusion(p, n);
                // 雲海の中は、日が届きにくい
                sh *= 1.0 - 0.7 * smoothstep(0.0, 0.03, FogTop() - p.y);

                if (id == ID_HOUSE || id == ID_TEMPLE)
                {
                    // 灰色の花こう岩の石組み
                    float2 uv = float2(abs(n.x) > abs(n.z) ? p.z : p.x, p.y) / 0.0007;
                    float3 granite = float3(0.52, 0.48, 0.42) * (0.8 + 0.25 * Noise3(p * 3000.0)) * (0.85 + 0.15 * Hash21(floor(uv * float2(0.7, 1.0))));
                    granite *= 1.0 - 0.35 * StoneJoints(uv, 0.6) * step(abs(n.y), 0.6);
                    // 上を向いた面には、苔と草が少し
                    granite = lerp(granite, float3(0.3, 0.38, 0.2), smoothstep(0.7, 0.95, n.y) * 0.4);
                    return Surface(granite, BumpNormal(n, p, 5000.0, 0.4), v, L, sunCol, sh, ao, 0.75, 0.04, 0.0, skyTop, skyLow);
                }
                if (id == ID_THATCH)
                {
                    // かやぶき屋根: 黄土色のわらの筋
                    float3 straw = float3(0.62, 0.48, 0.28) * (0.75 + 0.35 * Noise3(p * float3(2000.0, 30000.0, 2000.0)));
                    return Surface(straw, BumpNormal(n, p, 6000.0, 0.8), v, L, sunCol, sh, ao, 0.9, 0.03, 0.2, skyTop, skyLow);
                }
                if (id == ID_LLAMA)
                    return Surface(float3(0.85, 0.8, 0.72), n, v, L, sunCol, sh, ao, 0.9, 0.03, 0.2, skyTop, skyLow);

                if (max(abs(p.x), abs(p.z)) > INNER - 0.0015 && abs(n.y) < 0.5)
                    return Surface(float3(0.35, 0.3, 0.25) * (0.8 + 0.4 * Noise3(p * 900.0)), n, v, L, sunCol, 1.0, 1.0, 0.9, 0.03, 0.0, skyTop, skyLow); // 切り口

                // 地面: 都市と段々畑は、刈り込んだ芝と石垣。斜面は雲霧林の深い緑、急な所は灰色の岩
                float city = CityMask(p.xz);
                float terr = TerraceMask(p.xz);
                float3 albedo;
                float rough = 0.85, sss = 0.3;
                float3 nb = n;
                if ((terr > 0.5 || city > 0.5) && n.y < 0.75)
                {
                    // 段々畑の石垣
                    float2 uv = float2(p.x + p.z, p.y) / 0.0007;
                    albedo = float3(0.5, 0.46, 0.4) * (0.8 + 0.25 * Noise3(p * 3000.0));
                    albedo *= 1.0 - 0.3 * StoneJoints(uv, 0.55);
                    sss = 0.0;
                }
                else if (terr > 0.5 || city > 0.5)
                {
                    // 段のふち: 手前 (高い側) の石垣の上の、石の縁と、その下の影の線
                    float hHere = Height(p.xz);
                    float edge = 0.0;
                    [loop] for (int k = 0; k < 4; k++)
                    {
                        float2 o = float2(k == 0 ? 0.0015 : (k == 1 ? -0.0015 : 0.0), k == 2 ? 0.0015 : (k == 3 ? -0.0015 : 0.0));
                        edge = max(edge, saturate((hHere - Height(p.xz + o)) / (TERRACE_H * 0.5)));
                    }
                    float stripe = 0.92 + 0.08 * step(0.5, frac(p.x * 300.0));
                    albedo = float3(0.27, 0.5, 0.08) * stripe * (0.85 + 0.25 * Noise3(p * 2000.0));
                    albedo = lerp(albedo, float3(0.5, 0.46, 0.4) * (0.8 + 0.3 * Noise3(p * 3000.0)), edge);
                    nb = BumpNormal(n, p, 4000.0, 0.4);
                }
                else
                {
                    float steep = 1.0 - smoothstep(0.35, 0.6, n.y);
                    // 雲霧林: 濃い緑の木々のこんもりした頭 (明るい所と、木のあいだの暗い所)
                    float crowns = Noise3(p * 1800.0) * 0.6 + Noise3(p * 600.0) * 0.4;
                    float3 forest = lerp(float3(0.02, 0.07, 0.025), float3(0.07, 0.18, 0.05), crowns) * (0.8 + 0.4 * Noise3(p * 150.0));
                    float3 rock = float3(0.3, 0.29, 0.26) * (0.75 + 0.35 * Noise3(p * 1500.0));
                    albedo = lerp(forest, rock, steep * smoothstep(0.62, 0.78, Noise3(p * 150.0)) * 0.4);
                    nb = BumpNormal(n, p, 1800.0, 1.6);
                }
                if (p.y < RIVER_Y + 0.003)
                {
                    // 谷底: ウルバンバ川 (白くあわ立つ流れ) と、川原
                    float rxv = abs(p.x + 0.3 + 0.04 * sin(p.z * 9.0));
                    albedo = rxv < 0.012 ? float3(0.75, 0.75, 0.7) * (0.8 + 0.3 * Noise3(p * 2000.0 + _Time.y)) : (rxv < 0.03 ? float3(0.35, 0.33, 0.28) : float3(0.05, 0.13, 0.04) * (0.7 + 0.6 * Noise3(p * 900.0)));
                }
                return Surface(albedo, nb, v, L, sunCol, sh, ao, rough, 0.04, sss, skyTop, skyLow);
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
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input); // VR: 左右どちらの目を描いているか
                UNITY_SETUP_INSTANCE_ID(input);

                PrepareFrame();
                float3 ro = TransformWorldToObject(GetCameraPositionWS());
                float3 rd = normalize(input.positionOS - ro);
                float2 box = BoxHit(ro, rd, float3(0.5, 0.5, 0.5));
                bool outside = box.x > 0.0;
                float t = max(box.x, 0.0);

                float3 entry = ro + rd * t;
                float3 ae = abs(entry);
                float3 faceNormal = ae.x > ae.y && ae.x > ae.z ? float3(sign(entry.x), 0, 0)
                                  : (ae.y > ae.z ? float3(0, sign(entry.y), 0) : float3(0, 0, sign(entry.z)));

                const float maxHeight = 0.21; // ワイナピチュのてっぺんより少し上
                if (ro.y > maxHeight && rd.y < 0.0) t = max(t, (maxHeight - ro.y) / rd.y);

                bool hit = false;
                float id = 0.0;
                float lastD = 1.0, lastId = 0.0;
                bool ranOut = false;
                int steps = (int)_Steps;
                [loop] for (int i = 0; i <= 200; i++)
                {
                    if (t > box.y) break;
                    if (i >= steps) { ranOut = true; break; }
                    float3 pos = ro + rd * t;
                    if (rd.y > 0.0 && pos.y > maxHeight + 0.002) break;
                    float2 m = Map(pos);
                    lastD = m.x;
                    lastId = m.y;
                    if (m.x < 0.00003 + 0.0003 * t)
                    {
                        hit = true;
                        id = m.y;
                        break;
                    }
                    t += m.x;
                }
                if (!hit && ranOut && lastD < 0.0005 + 0.002 * t)
                {
                    hit = true;
                    id = lastId;
                }
                // 高さの表で当たった所を、正確な式で 2 回合わせ直す (段々畑や石垣が、なまらないように)
                // (地面の高さとの差が 0 になる所を、2 点を結ぶ直線で 2 回さがす。急な崖でも、地面の中へ入りすぎない)
                if (hit && id == ID_GROUND)
                {
                    float ta = t - 0.002, tb = t;
                    float3 pa = ro + rd * ta, pb = ro + rd * tb;
                    float fa = pa.y - Height(pa.xz), fb = pb.y - Height(pb.xz);
                    for (int r = 0; r < 2; r++)
                    {
                        if (abs(fb - fa) < 1e-7) break;
                        float tn = clamp(tb - fb * (tb - ta) / (fb - fa), t - 0.004, t + 0.004);
                        ta = tb; fa = fb;
                        tb = tn;
                        float3 pn = ro + rd * tb;
                        fb = pn.y - Height(pn.xz);
                    }
                    t = tb;
                }
                float tHit = hit ? t : box.y;

                float3 col = 0;
                if (hit) col = Shade(ro, rd, ro + rd * t, id, faceNormal);
                else if (!outside) col = Sky(rd);
                float alpha = (hit || !outside) ? 1.0 : 0.0;

                // 山の空気: 遠くほど青白くかすむ
                float travel = tHit - max(box.x, 0.0);
                if (hit) col = lerp(col, float3(0.42, 0.58, 0.85), (1.0 - exp(-travel * 1.0)) * 0.3); // 遠い山ほど、青くかすむ

                // 雲海: 雲の上面より下を通る所だけ、16 か所で濃さを調べて重ねる
                float top = FogTop() + 0.03;
                float tA = max(box.x, 0.0), tB = tHit;
                if (rd.y < 0.0) tA = max(tA, (top - ro.y) / rd.y);
                else if (ro.y > top) tB = tA;
                else tB = min(tB, (top - ro.y) / max(rd.y, 1e-4));
                if (tB > tA && Cover() > 0.001)
                {
                    float3 L = normalize(SUN_DIR);
                    float dt = (tB - tA) / 16.0;
                    float trans = 1.0;
                    float3 fog = 0;
                    [loop] for (int k = 0; k < 16; k++)
                    {
                        float3 pos = ro + rd * (tA + dt * (k + 0.5));
                        if (max(abs(pos.x), abs(pos.z)) > INNER) continue;
                        float dens = FogDensity(pos);
                        if (dens <= 0.001) continue;
                        // 雲の上ほど、朝日で明るい
                        float lit = smoothstep(FogTop() - 0.06, FogTop() + 0.02, pos.y);
                        float3 c = lerp(float3(0.55, 0.58, 0.65), float3(1.1, 1.0, 0.9) * (1.0 + 0.4 * Golden()), lit);
                        float a = 1.0 - exp(-dens * dt * 120.0);
                        fog += trans * a * c;
                        trans *= 1.0 - a;
                        if (trans < 0.02) break;
                    }
                    col = col * trans + fog;
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
            #pragma use_dxc vulkan // Quest (Vulkan) 用は新しいコンパイラー (DXC) で変換する。古いほうだと大きいシェーダーが時間切れになる
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
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input); // VR: 左右どちらの目を描いているか
                return input.positionCS.z;
            }
            ENDHLSL
        }
    }
}
