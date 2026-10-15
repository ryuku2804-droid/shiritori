// 作品「海の断面」(海の間)。明るい珊瑚の浅瀬から、光の届かない深海までを、横から切り取った水槽。URP 用。
// Cube の中をレイマーチングして描く。Cube の座標は -0.5〜0.5、下の 0.08 は黒い台。
//
// 見どころ:
//   ・左は色とりどりの珊瑚の棚 (浅瀬)。その先は切り立った崖で、右は深い海の底へ落ちていく
//   ・水は、上ほど明るい青、下ほど暗い紺。水面から光の筋が差し込み、浅瀬の底には光の網目
//   ・浅瀬をぐるぐる回る銀色の魚の群れ。深いところには、ほのかに光るクラゲと、光るプランクトン
// 仕掛け (_Event 0〜1): 生物発光。真ん中から青い光の波が広がり、プランクトンもクラゲも魚も一斉に光って、深海の闇が輝く
//
// 外から見たとき、水面より上 (空気の所) は透明にして、ガラスケースの向こうの部屋が見えるようにする。
// 中に入ったとき (カメラが箱の中) は、水の中にいる。水面を見上げると、ゆらぐ光の窓が見える
//
// _Steps / _ShadowSteps は DioramaLOD が距離で下げる。_Event / _EventTime は DioramaWork が渡す。
// _HeightTex は DioramaWork が再生の最初に作る、珊瑚の棚の高さの表 (なければ式で計算する)
Shader "NightShards/Diorama/DeepSea"
{
    Properties
    {
        _Steps ("Ray Steps", Range(16, 200)) = 130
        _ShadowSteps ("Shadow Steps", Range(0, 32)) = 16
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
            Blend One OneMinusSrcAlpha // 空気の所は透明 (色はあらかじめ不透明度を掛けて出す)

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma multi_compile_instancing

            #define ID_BASE   0.0
            #define ID_GROUND 1.0

            #define INNER 0.47
            #define SURF 0.36        // 水面の高さ
            #define FISH 36
            #define JELLIES 5
            #define SIGMA 1.6        // 水のにごり (大きいほど、遠くが見えない)
            static const float3 GLOW_CENTER = float3(0.15, -0.1, 0.0); // 生物発光が広がり始める所

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

            float Hash11(float n) { return frac(sin(n * 127.1) * 43758.5453); }

            float Hash21(float2 p)
            {
                p = frac(p * float2(123.34, 456.21));
                p += dot(p, p + 45.32);
                return frac(p.x * p.y);
            }

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

            // ---------------------------------------------------------------- 地形
            // ※ ShelfTop・CliffX・AbyssFloor を変えたら、C# の DioramaTerrain も同じに直す (中を歩くときの地面になる)

            // 珊瑚の棚の高さ。ところどころ、珊瑚が盛り上がる
            float ShelfTop(float2 xz)
            {
                float h = 0.15 + 0.02 * Fbm3(xz * 5.0 + _Seed);
                float c1 = 1.0 - abs(ValueNoise(xz * 22.0 + _Seed) * 2.0 - 1.0);
                float c2 = 1.0 - abs(ValueNoise(xz * 50.0 + _Seed * 1.3) * 2.0 - 1.0);
                float coral = c1 * c1 * 0.8 + c2 * c2 * 0.4;
                h += 0.03 * coral * smoothstep(0.35, 0.6, ValueNoise(xz * 7.0 + _Seed * 2.0));
                return h;
            }

            // 珊瑚の棚の高さ (速い版)。再生中は、最初に 1 回だけ計算して保存した表を読むだけ
            float ShelfTopFast(float2 xz)
            {
                [branch] if (_HeightTexOn > 0.5)
                    return SAMPLE_TEXTURE2D_LOD(_HeightTex, sampler_linear_clamp, xz / (2.0 * INNER) + 0.5, 0).r;
                return ShelfTop(xz);
            }

            // 崖の面の x。奥行きと高さで、でこぼこする
            float CliffX(float y, float z)
            {
                return 0.02 + 0.05 * sin(z * 5.0 + _Seed) + 0.06 * (ValueNoise(float2(z * 12.0, y * 10.0) + _Seed) - 0.5);
            }

            // 深い海の底
            float AbyssFloor(float2 xz)
            {
                return -0.38 + 0.03 * Fbm3(xz * 4.0 + _Seed);
            }

            // ---------------------------------------------------------------- 世界の形

            // 世界の形 (距離)。exact が true なら正確な珊瑚 (地面の向きを出すとき)、false なら速い版 (線を進めるとき)
            float2 MapX(float3 p, bool exact)
            {
                float2 res = float2(SdBox(p - float3(0, -0.46, 0), float3(0.5, 0.04, 0.5)), ID_BASE);
                float column = SdBox(p - float3(0, 0.04, 0), float3(INNER, 0.46, INNER));
                float top;
                if (exact) top = ShelfTop(p.xz);
                else top = ShelfTopFast(p.xz);
                float shelf = max((p.y - top) * 0.5, (p.x - CliffX(p.y, p.z)) * 0.5);
                float abyss = (p.y - AbyssFloor(p.xz)) * 0.5;
                float ground = max(min(shelf, abyss), column);
                if (ground < res.x) res = float2(ground, ID_GROUND);
                return res;
            }

            float2 Map(float3 p) { return MapX(p, false); }

            float3 SceneNormal(float3 p)
            {
                const float2 e = float2(0.0007, -0.0007);
                float3 g = e.xyy * MapX(p + e.xyy, true).x + e.yyx * MapX(p + e.yyx, true).x +
                           e.yxy * MapX(p + e.yxy, true).x + e.xxx * MapX(p + e.xxx, true).x;
                return g / max(length(g), 1e-7); // 0 で割らないように
            }

            float AmbientOcclusion(float3 p, float3 n)
            {
                float occ = 0.0;
                float w = 1.0;
                for (int i = 1; i <= 4; i++)
                {
                    float d = 0.01 * i;
                    occ += (d - Map(p + n * d).x) * w;
                    w *= 0.6;
                }
                return saturate(1.0 - occ * 14.0);
            }

            // ---------------------------------------------------------------- 光と生物発光

            // 水面からの日の光が、深さ y までにどれだけ届くか
            float SunReach(float y) { return exp(-max(SURF - y, 0.0) * 3.2); }

            // 生物発光の光の波: 真ん中から広がり、通った所は光り続ける
            float GlowWave(float3 p)
            {
                if (_Event < 0.01) return 0.0;
                float R = _EventTime * 0.14;
                float d = length(p - GLOW_CENTER);
                float x = (d - R) / 0.05;
                return (smoothstep(R, R - 0.1, d) * 0.6 + exp(-x * x) * 1.2) * saturate(_Event * 1.5);
            }

            // ---------------------------------------------------------------- 魚とクラゲ

            // 魚 i 番の場所と、泳ぐ向き。群れは浅瀬の上をゆっくり回り、1 匹ずつは群れの中をぐるぐる回る
            float3 FishPos(int i, out float3 dir)
            {
                float fi = i;
                float t = _Time.y;
                float3 center = float3(-0.22 + 0.08 * sin(t * 0.25), 0.26 + 0.025 * sin(t * 0.4), 0.12 * cos(t * 0.25));
                float a = Hash11(fi) * 6.2831 + t * (0.7 + 0.4 * Hash11(fi + 3.0));
                float rad = 0.025 + 0.045 * Hash11(fi + 7.0);
                float3 pos = center + float3(cos(a) * rad, (Hash11(fi + 11.0) - 0.5) * 0.05 + 0.006 * sin(t * 2.0 + fi), sin(a) * rad);
                dir = normalize(float3(-sin(a), 0.0, cos(a)));
                return pos;
            }

            // クラゲ j 番の場所 (深いほうで、ゆっくり上下する)
            float3 JellyPos(int j)
            {
                float fj = j;
                float t = _Time.y;
                return float3(0.08 + 0.32 * Hash11(fj + 1.0), -0.25 + 0.35 * Hash11(fj + 2.0) + 0.03 * sin(t * 0.3 + fj * 2.0),
                              -0.35 + 0.7 * Hash11(fj + 3.0));
            }

            // 線と縦の線分 (a から下へ len) の一番近い所の距離の 2 乗と、線の上の位置
            float SegmentDist2(float3 ro, float3 rd, float3 a, float len, out float sc, out float k)
            {
                float3 w0 = ro - a;
                float b = -rd.y;
                float dd = dot(rd, w0);
                float e = -w0.y;
                float den = 1.0 - b * b;
                sc = den > 0.0001 ? (b * e - dd) / den : 0.0;
                float u = clamp(den > 0.0001 ? (e - b * dd) / den : 0.0, 0.0, len);
                k = u / len;
                float3 diff = ro + rd * sc - (a - float3(0, u, 0));
                return dot(diff, diff);
            }

            // 魚とクラゲの光。水の中を通ってくる分だけ、にごりで弱める
            float3 Creatures(float3 ro, float3 rd, float tMax, float tWater)
            {
                float3 col = 0;
                float t = _Time.y;
                // 魚: 銀色の細長い小さな光。日の光を受けてきらりと光る。生物発光のときは青く光る
                for (int i = 0; i < FISH; i++)
                {
                    float3 dir;
                    float3 pos = FishPos(i, dir);
                    float3 w = pos - ro;
                    float tc = dot(w, rd);
                    if (tc < 0.0 || tc > tMax) continue;
                    float3 d = ro + rd * tc - pos;
                    float along = dot(d, dir);
                    float across2 = max(dot(d, d) - along * along, 0.0);
                    float L = max(0.006, tc * 0.002), Wd = max(0.002, tc * 0.0008);
                    float shape = exp(-(along * along / (L * L) + across2 / (Wd * Wd)));
                    float glint = 0.5 + 0.5 * sin(t * 6.0 + i * 1.7);
                    float3 c = float3(0.7, 0.8, 0.85) * SunReach(pos.y) * (0.4 + 0.8 * glint) + float3(0.2, 0.6, 1.5) * GlowWave(pos);
                    col += c * shape * exp(-SIGMA * max(tc - tWater, 0.0));
                }
                // クラゲ: ぽうっと光るかさと、細い触手
                for (int j = 0; j < JELLIES; j++)
                {
                    float3 pos = JellyPos(j);
                    float pulse = 1.0 + 0.15 * sin(t * 2.0 + j * 1.3);
                    float rad = 0.02 * pulse;
                    float3 w = pos - ro;
                    float tc = dot(w, rd);
                    if (tc < 0.0 || tc > tMax + 0.05) continue;
                    float3 hue = j % 2 == 0 ? float3(0.9, 0.35, 0.8) : float3(0.35, 0.6, 1.2);
                    float bright = 0.5 + 3.0 * GlowWave(pos);
                    float3 d = ro + rd * tc - pos;
                    d.y *= 1.6; // 平たいかさ
                    float bell = exp(-dot(d, d) / (rad * rad)) * 0.9 + exp(-dot(d, d) / (rad * rad * 6.0)) * 0.15;
                    float att = exp(-SIGMA * max(tc - tWater, 0.0));
                    col += hue * bell * bright * att * step(tc, tMax);
                    // 触手: かさの下から 3 本、ゆらゆら垂れる
                    for (int k = 0; k < 3; k++)
                    {
                        float3 a = pos + float3((k - 1) * 0.008 + 0.004 * sin(t * 1.5 + k + j), -0.004, 0.003 * cos(t + k));
                        float sc, kk;
                        float d2 = SegmentDist2(ro, rd, a, 0.07, sc, kk);
                        if (sc < 0.0 || sc > tMax) continue;
                        float thin = max(0.0012, sc * 0.0007);
                        col += hue * exp(-d2 / (thin * thin)) * (1.0 - kk) * 0.5 * bright * att;
                    }
                }
                return col;
            }

            // ---------------------------------------------------------------- 水 (立体)

            // 水の中を進みながら、にごりで後ろを隠し、日の光の筋・深さの色・プランクトンの光を足す
            float4 Water(float3 ro, float3 rd, float t0, float t1)
            {
                if (t1 <= t0) return float4(0, 0, 0, 1);
                int steps = clamp((int)(_Steps / 4.0), 12, 40);
                float dt = (t1 - t0) / steps;
                float t = t0 + dt * Hash21(rd.xy * 517.0 + _Time.y);
                float time = _Time.y;
                float3 col = 0;
                float trans = 1.0;
                for (int i = 0; i < 40; i++)
                {
                    if (i >= steps) break;
                    float3 p = ro + rd * t;
                    float depth = SURF - p.y;
                    // 水の色: 浅いところは明るい青、深いところは暗い紺
                    float3 tint = lerp(float3(0.0, 0.012, 0.03), float3(0.06, 0.38, 0.5), SunReach(p.y));
                    // 光の筋: 水面のゆらぎが作る、ななめに差し込む明るい帯
                    float ray = Noise3(float3(p.x * 9.0 + p.y * 3.0, p.z * 9.0 + p.y * 2.0, time * 0.25));
                    float shafts = 0.6 + 1.6 * pow(ray, 4.0) * exp(-depth * 2.0);
                    // プランクトン: ところどころ、ちらちら光る青い粒
                    float spark = pow(Noise3(p * 55.0 + float3(0, time * 0.05, 0)), 12.0);
                    float glow = GlowWave(p);
                    float3 emit = float3(0.2, 0.6, 1.4) * spark * (0.4 * smoothstep(0.2, -0.2, p.y) + 25.0 * glow);
                    emit += float3(0.02, 0.08, 0.2) * glow; // 光の波そのものの、ぼんやりした青
                    float a = 1.0 - exp(-SIGMA * dt);
                    col += trans * (a * tint * shafts + emit * dt * 6.0);
                    trans *= 1.0 - a;
                    t += dt;
                }
                return float4(col, trans);
            }

            // ---------------------------------------------------------------- 色を塗る

            float3 Shade(float3 ro, float3 rd, float3 p, float id, float3 faceNormal)
            {
                float t = _Time.y;
                if (id == ID_BASE)
                    return float3(0.015, 0.014, 0.014) + 0.02 * pow(saturate(1.0 - abs(dot(rd, faceNormal))), 4.0);

                float3 n = SceneNormal(p);
                float ao = AmbientOcclusion(p, n);
                float sun = SunReach(p.y);
                // 底の光の網目 (浅いほど強い)
                float c1 = 1.0 - abs(ValueNoise(p.xz * 60.0 + t * 0.5) - 0.5) * 2.0;
                float c2 = 1.0 - abs(ValueNoise(p.xz * 95.0 - t * 0.4 + 3.0) - 0.5) * 2.0;
                float caustic = (pow(c1, 8.0) + pow(c2, 8.0)) * saturate(n.y);
                float3 light = float3(0.6, 0.9, 1.0) * sun * (0.5 * saturate(n.y * 0.7 + 0.3) + caustic * 1.2) + float3(0.02, 0.05, 0.08) * sun;

                float3 albedo;
                float onShelf = p.y > 0.1 && p.x < 0.1 ? 1.0 : 0.0;
                if (onShelf > 0.5 && n.y > 0.3)
                {
                    // 珊瑚: ます目ごとに色を変える (ピンク・オレンジ・紫・黄・緑)。すきまは白い砂
                    float cell = Hash21(floor(p.xz * 40.0) + _Seed);
                    float3 coral = cell < 0.2 ? float3(0.9, 0.35, 0.5) : cell < 0.4 ? float3(0.95, 0.55, 0.2)
                                 : cell < 0.6 ? float3(0.55, 0.3, 0.85) : cell < 0.8 ? float3(0.9, 0.8, 0.3) : float3(0.3, 0.75, 0.45);
                    float isCoral = smoothstep(0.004, 0.012, p.y - (0.15 + 0.02 * Fbm3(p.xz * 5.0 + _Seed)));
                    albedo = lerp(float3(0.75, 0.7, 0.58), coral, isCoral);
                }
                else
                {
                    // 崖と深い底: 暗い岩と泥。ところどころ、海綿の色
                    float sponge = smoothstep(0.65, 0.8, Noise3(p * 40.0 + _Seed));
                    albedo = lerp(float3(0.12, 0.11, 0.1), float3(0.5, 0.3, 0.2), sponge * sun);
                }
                float3 c = albedo * light * ao;
                // 生物発光のとき、底にも青い光がうつる
                c += albedo * float3(0.1, 0.35, 0.9) * GlowWave(p) * 0.6;
                return c;
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
                float tStart = max(box.x, 0.0);
                float t = tStart;

                float3 entry = ro + rd * t;
                float3 ae = abs(entry);
                float3 faceNormal = ae.x > ae.y && ae.x > ae.z ? float3(sign(entry.x), 0, 0)
                                  : (ae.y > ae.z ? float3(0, sign(entry.y), 0) : float3(0, 0, sign(entry.z)));

                // 珊瑚の棚より上の、水だけの所は飛ばす
                const float maxHeight = 0.22;
                if (ro.y > maxHeight && rd.y < 0.0) t = max(t, (maxHeight - ro.y) / rd.y);

                bool hit = false;
                float id = 0.0;
                int steps = (int)_Steps;
                for (int i = 0; i < 200; i++)
                {
                    if (i >= steps || t > box.y) break;
                    float3 pos = ro + rd * t;
                    if (rd.y > 0.0 && pos.y > maxHeight + 0.01) break; // 上を向いて棚より上に出た線は、もう地形に当たらない
                    float2 m = Map(pos);
                    if (m.x < 0.0003 * (1.0 + t))
                    {
                        hit = true;
                        id = m.y;
                        break;
                    }
                    t += m.x;
                }
                if (hit)
                {
                    for (int r = 0; r < 2; r++) t += MapX(ro + rd * t, true).x; // 正確な形で 2 回だけ合わせ直す
                }
                float tHit = hit ? t : box.y;

                // 水の中を通る区間 [tw0, tw1] と、水面に当たる所
                float tSurf = abs(rd.y) > 1e-5 ? (SURF - ro.y) / rd.y : -1.0;
                bool startInWater = (ro + rd * tStart).y < SURF;
                float tw0 = startInWater ? tStart : (rd.y < 0.0 ? max(tSurf, tStart) : 1e9);
                float tw1 = tHit;
                bool hitsSurfaceFromBelow = startInWater && rd.y > 0.0 && tSurf > tStart && tSurf < tHit;
                if (hitsSurfaceFromBelow) tw1 = tSurf;
                bool throughWater = tw1 > tw0;

                float3 col = 0;
                float alpha = 0.0;
                if (hit && (!hitsSurfaceFromBelow))
                {
                    col = Shade(ro, rd, ro + rd * tHit, id, faceNormal);
                    alpha = 1.0;
                }
                else if (hitsSurfaceFromBelow)
                {
                    // 水面を下から見上げる: 真上ほど明るい光の窓、ななめは水の中を映す暗い鏡。ゆらゆら揺れる
                    float3 sp = ro + rd * tSurf;
                    float wob = ValueNoise(sp.xz * 40.0 + _Time.y * 0.8) + ValueNoise(sp.xz * 90.0 - _Time.y);
                    float window = smoothstep(0.55, 0.85, rd.y + (wob - 1.0) * 0.08);
                    col = lerp(float3(0.02, 0.15, 0.22), float3(0.7, 0.95, 1.05), window) * (0.8 + 0.3 * wob);
                    alpha = 1.0;
                }
                else if (!outside)
                {
                    col = float3(0.35, 0.6, 0.85); // 中から水面の上へ出たときの空
                    alpha = 1.0;
                }

                // 水面を上から見る: 空を映し、その下の水が透けて見える
                if (!startInWater && rd.y < 0.0 && tSurf > tStart && tSurf < tHit)
                {
                    float3 sp = ro + rd * tSurf;
                    float2 slope = (float2(ValueNoise(sp.xz * 80.0 + _Time.y * 0.6), ValueNoise(sp.xz * 80.0 + 5.0 - _Time.y * 0.5)) - 0.5) * 0.1;
                    float3 n = normalize(float3(slope.x, 1.0, slope.y));
                    float fres = 0.02 + 0.98 * pow(1.0 - saturate(dot(-rd, n)), 5.0);
                    float4 w = Water(ro, rd, tw0, tw1);
                    float3 under = col * w.a + w.rgb + Creatures(ro, rd, tw1, tw0);
                    col = lerp(under, float3(0.5, 0.7, 0.9), fres);
                    alpha = 1.0;
                }
                else if (throughWater)
                {
                    float4 w = Water(ro, rd, tw0, tw1);
                    col = col * w.a + w.rgb + Creatures(ro, rd, tw1, tw0);
                    alpha = 1.0; // 水の入った水槽は、向こうが見えない
                }

                // ガラス: 外から見ているときだけ、映り込みと金属の枠
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

                // 壊れた値のピクセルがあると、ブルームで画面全体が白く点滅するので、最後に範囲へ収める
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
