// 作品「マチュピチュ」(アンデスの間)。雲海から現れる空中都市。URP 用。
// Cube の中をレイマーチングして描く。Cube の座標は -0.5〜0.5、下の 0.08 は黒い台。
//
// 形は実物の寸法 (1 m = 0.0007)。美術館の正面 (+z) が南、右 (-x) が東。南の見張り小屋の高台から北を見る、絵はがきと同じ眺め。
//   ・標高 2430 m の尾根の上の都市。両側は 400 m 下のウルバンバ川の谷へ落ちる急な崖
//   ・奥 (北) にそびえる、とがったワイナピチュ (都市より 290 m 高い)
//   ・都市: まん中の芝生の大広場。西 (左) は神殿の地区、東 (右) は住居の地区。屋根のない石の家が並び、両はしに三角の破風。
//     いくつかは、復元したかやぶき屋根
//   ・インティワタナ (日時計の石) の段々の丘、半円の壁の太陽の神殿、南の斜面の段々畑 (高さ約 3 m の石垣と芝)
//   ・見張り小屋 (かやぶき屋根)。段々畑には、リャマ
//   ・谷には、雲海がたまっている
// 仕掛け (_Event 0〜1): 谷の雲海がわき上がって都市をすっかり包み、やがて引いて、朝日が都市を金色に照らし出す
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
            #define CELL_X 0.016                                   // 家を並べるます目
            #define CELL_Z 0.011
            static const float2 HUAYNA = float2(0.0, -0.34);       // ワイナピチュの頂上
            static const float2 INTI = float2(0.058, -0.088);      // インティワタナの丘
            static const float2 TORREON = float2(0.045, 0.062);    // 太陽の神殿
            static const float2 GUARD = float2(-0.058, 0.205);     // 見張り小屋
            static const float3 SUN_DIR = float3(-0.78, 0.4, 0.12); // 東からの朝日

            // ---------------------------------------------------------------- 地形

            // 尾根の中心の線 (少しくねる)
            float RidgeX(float z) { return 0.01 * sin(z * 6.0); }

            // 都市のある所か (尾根の上の平らな所)
            float CityMask(float2 xz)
            {
                float ax = abs(xz.x - RidgeX(xz.y));
                return (1.0 - smoothstep(0.085, 0.095, ax)) * smoothstep(-0.13, -0.11, xz.y) * (1.0 - smoothstep(0.14, 0.16, xz.y));
            }

            // 段々畑のある所か (都市の南と、両側の斜面の上のほう)
            float TerraceMask(float2 xz)
            {
                float ax = abs(xz.x - RidgeX(xz.y));
                float slopeBand = smoothstep(0.09, 0.1, ax) * (1.0 - smoothstep(0.17, 0.19, ax)) * smoothstep(-0.08, -0.05, xz.y);
                float south = smoothstep(0.13, 0.15, xz.y) * (1.0 - smoothstep(0.11, 0.13, ax)) * (1.0 - smoothstep(0.24, 0.26, xz.y));
                return saturate(max(slopeBand * (1.0 - smoothstep(0.2, 0.22, xz.y)), south));
            }

            float Height(float2 xz)
            {
                float x = xz.x, z = xz.y;
                float ax = abs(x - RidgeX(z));
                // 北の鞍部: 尾根が低く細くなる
                float north = smoothstep(0.12, 0.22, -z);
                float top = CITY_Y - 0.03 * north;
                float w = lerp(0.095, 0.025, north);
                float ridge = top - 1.3 * max(ax - w, 0.0);
                // 南のはし (手前) は、谷へ下がる (箱の手前から見て、山の形がわかるように)
                ridge -= 1.5 * max(z - 0.27, 0.0);
                // ワイナピチュ: とがった山
                // ワイナピチュ: 上がまるい、砂糖のかたまりのような急な山。少し東へかたむき、でこぼこの岩と緑
                float2 hq = (xz - HUAYNA) * float2(1.0, 1.35);
                float r = length(hq + float2(0.01, 0.0) * saturate(0.06 - length(hq)) * 10.0);
                float huayna = 0.15 - 0.9 * r - 6.0 * r * r + 0.04 * (Fbm3(xz * 11.0 + 5.0) - 0.4) + 0.02 * (Fbm3(xz * 30.0) - 0.4);
                float h = max(ridge, huayna);
                // 崖の岩のでこぼこ (都市の外)
                h += 0.035 * (Fbm3(xz * 9.0 + 2.0) - 0.4) * smoothstep(0.0, 0.05, max(ax - w, z - 0.27)) * (1.0 - CityMask(xz));
                // 斜面の谷筋と尾根: 尾根から離れて深い所ほど、大きくでこぼこ
                float depth = max(max(ax - w, z - 0.27), 0.0);
                h += depth * 0.45 * (abs(ValueNoise(float2(x * 7.0, z * 7.0) + 3.1) * 2.0 - 1.0) - 0.5) * (1.0 - CityMask(xz));
                // 都市: 西の神殿の地区は少し高く、東の住居の地区は東へ段々に下がる
                float rx = x - RidgeX(z);
                float city = CITY_Y + 0.006 * smoothstep(0.02, 0.032, rx) + 0.003 * smoothstep(0.02, 0.032, -rx) - 0.004 * smoothstep(0.05, 0.09, -rx);
                h = lerp(h, city, CityMask(xz));
                // 段々畑: 高さを段に切る (石垣の所だけ、急に上がる)
                float f = h / TERRACE_H;
                float terr = (floor(f) + smoothstep(0.82, 1.0, frac(f))) * TERRACE_H;
                h = lerp(h, terr, TerraceMask(xz));
                return max(h, RIVER_Y);
            }

            float HeightFast(float2 xz)
            {
                [branch] if (_HeightTexOn > 0.5)
                    return SAMPLE_TEXTURE2D_LOD(_HeightTex, sampler_linear_clamp, xz / (2.0 * INNER) + 0.5, 0).r;
                return Height(xz);
            }

            // ---------------------------------------------------------------- 石の家 (屋根のない壁と、両はしの三角の破風)

            // そのます目に家を建てるか。西の地区と東の地区だけ (大広場・インティワタナ・太陽の神殿は空ける)
            bool HouseAllowed(float2 c)
            {
                float rx = c.x - RidgeX(c.y);
                if (abs(rx) < 0.03 || abs(rx) > 0.085) return false;
                if (c.y < -0.1 || c.y > 0.125) return false;
                if (length(c - INTI) < 0.025 || length(c - TORREON) < 0.014) return false;
                return Hash21(c * 5.3 + 1.7) < 0.85;
            }

            // 家: 外寸 11 m × 7.5 m・壁の高さ 3.5 m・厚さ 0.6 m。短い辺の壁は三角に高い (破風)。part 1 ならかやぶき屋根
            float Houses(float3 p, out float part)
            {
                part = 0;
                // 家があるのは、都市の地区の中の、低い所だけ。外なら、その範囲までの距離を返す (ます目の境で歩みが細かくならないように)
                float rx0 = p.x - RidgeX(p.z);
                float region = max(max(abs(rx0) - 0.09, max(-0.11 - p.z, p.z - 0.135)), p.y - (CITY_Y + 0.016));
                if (region > 0.002) return region;
                float2 cell = floor(p.xz / float2(CELL_X, CELL_Z));
                float2 c = (cell + 0.5) * float2(CELL_X, CELL_Z);
                float2 l = p.xz - c;
                float2 toEdge = 0.5 * float2(CELL_X, CELL_Z) - abs(l);
                float bound = max(min(toEdge.x, toEdge.y), 0.0) + 0.002;
                if (!HouseAllowed(c)) return bound;
                float base = HeightFast(c) - 0.002;
                float y = p.y - base;
                if (y > 0.0075) return min(y - 0.007, bound);
                // 家ごとに、少しずらし、大きさも少し変える (きっちり並びすぎないように)
                float2 jit = (Hash22b(c * 7.7) - 0.5) * float2(0.004, 0.0025);
                float3 q = float3(l.x - jit.x, y, l.y - jit.y);
                float2 hs = float2(0.0034, 0.0023) + Hash21(c * 2.3) * float2(0.0012, 0.0006);
                float outer = SdBox(q - float3(0, 0.0034, 0), float3(hs.x, 0.0034, hs.y));
                float inner = SdBox(q - float3(0, 0.0034, 0), float3(hs.x - 0.0004, 0.01, hs.y - 0.0004));
                float walls = max(outer, -inner);
                // 破風: 短い辺 (x の両はし) の壁が、三角に高くなる
                float gable = max(max(abs(abs(q.x) - (hs.x - 0.0002)) - 0.0002, abs(q.z) - hs.y), (q.y - 0.0068) + abs(q.z) * 1.4);
                gable = max(gable, 0.0024 - q.y);
                float d = min(walls, gable * 0.8);
                // 戸口 (長い辺のまん中) と、台形の窓
                d = max(d, -SdBox(q - float3(0, 0.0013, hs.y), float3(0.0006 - q.y * 0.05, 0.0013, 0.001)));
                // いくつかの家は、復元したかやぶき屋根
                if (Hash21(c * 3.1) < 0.2)
                {
                    float roof = max(max(abs(q.x) - hs.x - 0.0004, (q.y - 0.0075) + abs(q.z) * 1.3), 0.0045 - q.y);
                    if (roof < d) part = 1;
                    d = min(d, roof * 0.75);
                }
                return min(d, bound);
            }

            // ---------------------------------------------------------------- 神殿 (インティワタナ・太陽の神殿・見張り小屋)

            float Temples(float3 p, out float part)
            {
                part = 0;
                // インティワタナ: 4 段の石垣の丘と、てっぺんの日時計の石
                float3 q = p - float3(INTI.x, HeightFast(INTI) - 0.002, INTI.y);
                float d = 1e5;
                if (length(q.xz) < 0.03)
                {
                    for (int k = 0; k < 4; k++)
                    {
                        float r = 0.016 - k * 0.0035;
                        d = min(d, max(length(q.xz * float2(1.0, 1.3)) - r, abs(q.y - (k + 0.5) * 0.003) - 0.0015));
                    }
                    float stone = SdBox(q - float3(0, 0.0125, 0), float3(0.0009, 0.0013, 0.0006));
                    d = min(d, stone);
                }
                else d = length(q.xz) - 0.028;
                // 太陽の神殿 (トレオン): 大きな岩の上の、半円の壁の塔
                q = p - float3(TORREON.x, HeightFast(TORREON) - 0.002, TORREON.y);
                float rock = SdEllipsoidLite(q - float3(0, 0.0015, 0), float3(0.007, 0.004, 0.006));
                float ring = max(abs(length(q.xz) - 0.0045) - 0.0005, abs(q.y - 0.0055) - 0.003);
                ring = max(ring, -q.x - 0.001); // 半円 (東側は直線の壁)
                d = min(d, min(rock, ring));
                // 見張り小屋: 石の壁と、高いかやぶき屋根
                q = p - float3(GUARD.x, HeightFast(GUARD) - 0.001, GUARD.y);
                float hut = SdBox(q - float3(0, 0.002, 0), float3(0.004, 0.002, 0.0026));
                float roof = max(max(abs(q.x) - 0.0045, (q.y - 0.0072) + abs(q.z) * 1.6), 0.0035 - q.y) * 0.7;
                if (roof < min(d, hut)) part = 1;
                d = min(d, min(hut, roof));
                return d;
            }

            // ---------------------------------------------------------------- リャマ (体高 1.2 m)

            #define LLAMAS 5
            float3 LlamaPos(int i, out float2 dir)
            {
                float fi = i;
                float t = _Time.y * 0.03 + fi * 1.7;
                float2 c = float2(-0.06 + 0.03 * sin(fi * 2.0), 0.16 + 0.05 * cos(fi * 1.3));
                float2 xz = c + float2(cos(t), sin(t)) * 0.012;
                dir = normalize(float2(-sin(t), cos(t)));
                return float3(xz.x, HeightFast(xz), xz.y);
            }

            float Llamas(float3 p)
            {
                if (p.z < 0.08 || p.z > 0.25 || p.x > 0.0 || p.x < -0.12) return max(max(0.08 - p.z, p.z - 0.25), max(p.x, -0.12 - p.x)) + 0.001;
                float d = 1e5;
                for (int i = 0; i < LLAMAS; i++)
                {
                    float2 dir;
                    float3 c = LlamaPos(i, dir);
                    float3 r = p - c;
                    if (dot(r, r) > 0.003 * 0.003) { d = min(d, length(r) - 0.0025); continue; }
                    float3 q = float3(dot(r.xz, dir), r.y, dot(r.xz, float2(-dir.y, dir.x)));
                    float body = SdEllipsoidLite(q - float3(0, 0.0009, 0), float3(0.0007, 0.00035, 0.0003));
                    float neck = SdCapsule(q, float3(0.0005, 0.001, 0), float3(0.0007, 0.0017, 0), 0.00012);
                    float head = SdEllipsoidLite(q - float3(0.0008, 0.0018, 0), float3(0.0002, 0.00011, 0.0001));
                    float legs = min(SdCapsule(float3(abs(q.x), q.y, abs(q.z)), float3(0.0005, 0.0008, 0.0002), float3(0.0005, 0.0, 0.0002), 0.00006), 1.0);
                    d = min(d, min(min(body, neck), min(head, legs)));
                }
                return d;
            }

            // ---------------------------------------------------------------- 世界の形

            float2 MapX(float3 p, bool exact)
            {
                float2 res = float2(SdBox(p - float3(0, -0.46, 0), float3(0.5, 0.04, 0.5)), ID_BASE);
                float column = SdBox(p - float3(0, 0.04, 0), float3(INNER, 0.46, INNER));
                float h = exact ? Height(p.xz) : HeightFast(p.xz);
                float ground = max((p.y - h) * (p.z < -0.15 ? 0.3 : 0.5), column); // ワイナピチュは急なので小さく進む
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
                return g / max(length(g), 1e-12); // 1e-7 だと、なだらかな所で向きが短くなってしまう
            }

            float SoftShadow(float3 p, float3 l)
            {
                float res = 1.0;
                float t = 0.0008;
                int n = clamp((int)_ShadowSteps, 8, 24);
                for (int i = 0; i < 24; i++)
                {
                    if (i >= n) break;
                    float3 sp = p + l * t;
                    if (sp.y > 0.21) break;
                    float h = Map(sp).x;
                    res = min(res, 16.0 * h / t);
                    t += clamp(h, 0.001, 0.05);
                    if (res < 0.01 || t > 0.6) break;
                }
                return saturate(res);
            }

            float AmbientOcclusion(float3 p, float3 n)
            {
                float occ = 0.0;
                float w = 1.0;
                for (int i = 1; i <= 4; i++)
                {
                    float d = 0.0025 * i;
                    occ += (d - Map(p + n * d).x) * w;
                    w *= 0.6;
                }
                return saturate(1.0 - occ * 30.0);
            }

            // ---------------------------------------------------------------- 雲海 (仕掛け)

            // 雲海の上面の高さ: ふだんは谷にたまり、仕掛けで都市の上までわき上がって、また引く
            float Cover() { return _Event * smoothstep(0.0, 4.0, _EventTime) * (1.0 - smoothstep(7.0, 11.0, _EventTime)); }
            float Golden() { return _Event * smoothstep(8.0, 12.0, _EventTime); }
            float FogTop() { return lerp(-0.27, 0.02, Cover()); }

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
                float3 c = lerp(float3(0.85, 0.82, 0.78), float3(0.3, 0.5, 0.82), pow(up, 0.5));
                float sd = dot(rd, L);
                c += float3(1.0, 0.75, 0.45) * pow(saturate(sd), 8.0) * (0.4 + 0.6 * Golden());
                c += float3(4.0, 3.5, 2.6) * smoothstep(0.9994, 0.9997, sd);
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
                float3 sunCol = float3(2.0, 1.75, 1.4) * (1.0 + 0.4 * golden) * lerp(float3(1, 1, 1), float3(1.1, 0.85, 0.6), golden);
                float3 skyTop = float3(0.3, 0.42, 0.65);
                float3 skyLow = float3(0.55, 0.55, 0.55);
                float3 v = -rd;

                if (id == ID_BASE)
                    return float3(0.015, 0.014, 0.014) + 0.03 * pow(saturate(1.0 - abs(dot(rd, faceNormal))), 4.0);

                float3 n = SceneNormal(p);
                float sh = SoftShadow(p + n * 0.0005, L);
                float ao = AmbientOcclusion(p, n);
                // 雲海の中は、日が届きにくい
                sh *= 1.0 - 0.7 * smoothstep(0.0, 0.03, FogTop() - p.y);

                if (id == ID_HOUSE || id == ID_TEMPLE)
                {
                    // 灰色の花こう岩の石組み
                    float2 uv = float2(abs(n.x) > abs(n.z) ? p.z : p.x, p.y) / 0.0007;
                    float3 granite = float3(0.6, 0.58, 0.55) * (0.8 + 0.25 * Noise3(p * 3000.0)) * (0.85 + 0.15 * Hash21(floor(uv * float2(0.7, 1.0))));
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
                    albedo = float3(0.55, 0.53, 0.5) * (0.8 + 0.25 * Noise3(p * 3000.0));
                    albedo *= 1.0 - 0.3 * StoneJoints(uv, 0.55);
                    sss = 0.0;
                }
                else if (terr > 0.5 || city > 0.5)
                {
                    float stripe = 0.92 + 0.08 * step(0.5, frac(p.x * 300.0));
                    albedo = float3(0.17, 0.32, 0.09) * stripe * (0.85 + 0.25 * Noise3(p * 2000.0));
                    nb = BumpNormal(n, p, 4000.0, 0.4);
                }
                else
                {
                    float steep = 1.0 - smoothstep(0.35, 0.6, n.y);
                    // 雲霧林: 濃い緑の木々のこんもりした頭 (明るい所と、木のあいだの暗い所)
                    float crowns = Noise3(p * 1800.0) * 0.6 + Noise3(p * 600.0) * 0.4;
                    float3 forest = lerp(float3(0.02, 0.07, 0.025), float3(0.07, 0.18, 0.05), crowns) * (0.8 + 0.4 * Noise3(p * 150.0));
                    float3 rock = float3(0.3, 0.29, 0.26) * (0.75 + 0.35 * Noise3(p * 1500.0));
                    albedo = lerp(forest, rock, steep * smoothstep(0.55, 0.7, Noise3(p * 200.0)) * 0.8);
                    nb = BumpNormal(n, p, 1800.0, 1.6);
                }
                if (p.y < RIVER_Y + 0.003) albedo = float3(0.25, 0.3, 0.25); // 谷底の川
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

                const float maxHeight = 0.21; // ワイナピチュのてっぺんより少し上
                if (ro.y > maxHeight && rd.y < 0.0) t = max(t, (maxHeight - ro.y) / rd.y);

                bool hit = false;
                float id = 0.0;
                float lastD = 1.0, lastId = 0.0;
                bool ranOut = false;
                int steps = (int)_Steps;
                for (int i = 0; i <= 200; i++)
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
                float tHit = hit ? t : box.y;

                float3 col = 0;
                if (hit) col = Shade(ro, rd, ro + rd * t, id, faceNormal);
                else if (!outside) col = Sky(rd);
                float alpha = (hit || !outside) ? 1.0 : 0.0;

                // 山の空気: 遠くほど青白くかすむ
                float travel = tHit - max(box.x, 0.0);
                if (hit) col = lerp(col, float3(0.75, 0.8, 0.88), (1.0 - exp(-travel * 0.9)) * 0.25);

                // 雲海: 雲の上面より下を通る所だけ、16 か所で濃さを調べて重ねる
                float top = FogTop() + 0.03;
                float tA = max(box.x, 0.0), tB = tHit;
                if (rd.y < 0.0) tA = max(tA, (top - ro.y) / rd.y);
                else if (ro.y > top) tB = tA;
                else tB = min(tB, (top - ro.y) / max(rd.y, 1e-4));
                if (tB > tA)
                {
                    float3 L = normalize(SUN_DIR);
                    float dt = (tB - tA) / 16.0;
                    float trans = 1.0;
                    float3 fog = 0;
                    for (int k = 0; k < 16; k++)
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
