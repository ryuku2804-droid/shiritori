// 作品「環礁」(海の間)。昼の空に浮かぶ、ターコイズの環礁の島。URP 用。
// Cube の中をレイマーチングして描く。Cube の座標は -0.5〜0.5、下の 0.08 は黒い台。
//
// 見どころ:
//   ・丸い海のかけらが、ケースの中に浮かぶ。下は、岩が根のように細くなっていく土台
//   ・白い砂のサンゴ礁の輪と、輪の上の小島 (ヤシの木)。輪の内側は明るいターコイズの浅い礁湖、外側は濃い青
//   ・浅瀬の底に揺れる光の網目 (コースティクス) と、水面を流れる雲の影
//   ・島の縁の 4 か所から、海の水が滝になって空中へこぼれ落ち、下で霧になって消える。島のまわりには小さな雲
// 仕掛け (_Event 0〜1): 潮が引く。水面が下がって、白い砂の道 (サンゴ礁の輪) が小島と小島をつなぐように現れ、滝が細くなる
//
// 外から見たとき、島のない所 (空) は透明にして、ガラスケースの向こうの部屋が見えるようにする。
// 中に入ったとき (カメラが箱の中) だけ、青空と、はるか下の雲の海を描く
//
// _Steps / _ShadowSteps は DioramaLOD が距離で下げる。_Event / _EventTime は DioramaWork が渡す。
// _HeightTex は DioramaWork が再生の最初に作る、海の底 (と小島) の高さの表 (なければ式で計算する)
Shader "NightShards/Diorama/Atoll"
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
            Blend One OneMinusSrcAlpha // 空の所は透明 (色はあらかじめ不透明度を掛けて出す)

            HLSLPROGRAM
            #pragma target 3.5
            #pragma use_dxc vulkan // Quest (Vulkan) 用は新しいコンパイラー (DXC) で変換する。古いほうだと大きいシェーダーが時間切れになる
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma multi_compile_instancing

            #define ID_BASE   0.0
            #define ID_GROUND 1.0
            #define ID_WATER  2.0
            #define ID_PALM   3.0

            #define INNER 0.47
            #define SEA 0.05        // ふだんの水面の高さ
            #define YBOT -0.36      // 島の土台の、いちばん下
            #define MOTUS 5
            #define FALLS 4
            #define CLOUDS 6
            static const float3 SUN_DIR = float3(0.45, 0.75, 0.35); // 正規化は使う所で
            static const float MOTU_A[MOTUS] = { 0.3, 1.55, 2.7, 3.95, 5.15 };   // 小島の向き
            static const float FALL_A[FALLS] = { 0.95, 2.2, 3.35, 4.6 };         // 滝の向き
            static const float4 CLOUD[CLOUDS] =                                  // 雲 (xyz と大きさ)
            {
                float4(-0.36, -0.12, 0.25, 0.07), float4(0.34, -0.2, -0.28, 0.08), float4(0.3, 0.12, 0.33, 0.05),
                float4(-0.3, 0.2, -0.3, 0.06), float4(0.05, -0.3, 0.36, 0.07), float4(-0.12, -0.26, -0.38, 0.06)
            };

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

            float SdCapsule(float3 p, float3 a, float3 b, float r)
            {
                float3 pa = p - a, ba = b - a;
                float h = saturate(dot(pa, ba) / dot(ba, ba));
                return length(pa - ba * h) - r;
            }

            float AngDist(float a, float b) { return abs(atan2(sin(a - b), cos(a - b))); }

            // ---------------------------------------------------------------- 島の形
            // ※ DiskR・RingR・SpillDip・Seabed を変えたら、C# の DioramaTerrain も同じに直す (中を歩くときの地面になる)

            // 島 (海のかけら) の縁までの半径。向きによって少しでこぼこ
            float DiskR(float th) { return 0.35 + 0.02 * sin(th * 3.0 + _Seed) + 0.012 * sin(th * 7.0 + _Seed * 2.1); }

            // サンゴ礁の輪の半径
            float RingR(float th) { return 0.21 + 0.015 * sin(th * 3.0 + _Seed * 1.7); }

            // 滝がこぼれる所ほど 1
            float SpillDip(float th)
            {
                float s = 0.0;
                [loop] for (int k = 0; k < FALLS; k++)
                {
                    float d = AngDist(th, FALL_A[k]) / 0.1;
                    s = max(s, exp(-d * d));
                }
                return s;
            }

            // 海の底の高さ (小島と、縁の堤も含む)
            float Seabed(float2 xz)
            {
                float r = length(xz);
                float th = atan2(xz.y, xz.x);
                float R = DiskR(th);
                float ring = RingR(th);
                // 輪の外: 縁に近いほど深い。輪の内 (礁湖): 浅くて平ら
                float outer = lerp(SEA - 0.055, SEA - 0.02, smoothstep(R - 0.02, ring + 0.05, r));
                float lagoon = SEA - 0.022 + 0.006 * Fbm3(xz * 12.0 + _Seed);
                float h = lerp(lagoon, outer, smoothstep(ring - 0.01, ring + 0.01, r));
                // サンゴ礁の輪: 水面すれすれ (潮が引くと出てくる白い砂の道)
                float rd = (r - ring) / 0.022;
                h = max(h, SEA - 0.006 + 0.004 * ValueNoise(xz * 60.0 + _Seed) - 0.03 * (1.0 - exp(-rd * rd)));
                // 小島: 輪の上に 5 つ。水面より上に出る
                [loop] for (int k = 0; k < MOTUS; k++)
                {
                    float a = MOTU_A[k];
                    float2 c = float2(cos(a), sin(a)) * RingR(a);
                    float2 d = (xz - c) / (0.038 + 0.006 * (1.0 + sin(k * 2.3 + _Seed)));
                    h = max(h, SEA - 0.012 + (0.035 + 0.006 * ValueNoise(xz * 40.0)) * exp(-dot(d, d)));
                }
                // 縁の堤: 海の水をためておく、水面より少し高いふち。滝の所だけ低い
                float lip = (r - (R - 0.008)) / 0.007;
                h = max(h, SEA + 0.002 - 0.009 * SpillDip(th) - 0.06 * (1.0 - exp(-lip * lip)));
                return h;
            }

            // 海の底の高さ (速い版)。再生中は、最初に 1 回だけ計算して保存した表を読むだけ
            float SeabedFast(float2 xz)
            {
                [branch] if (_HeightTexOn > 0.5)
                    return SAMPLE_TEXTURE2D_LOD(_HeightTex, sampler_linear_clamp, xz / (2.0 * INNER) + 0.5, 0).r;
                return Seabed(xz);
            }

            // 潮の高さ: 仕掛けの最中は、ゆっくり下がる
            float SeaLevel() { return SEA - 0.012 * smoothstep(0.0, 1.0, _Event); }

            // 島の土台 (距離)。縁から下へ、根のように細くなっていく岩
            float Body(float3 p)
            {
                float r = length(p.xz);
                float th = atan2(p.z, p.x);
                float k = saturate((p.y - YBOT) / (SEA - 0.03 - YBOT));
                float rb = DiskR(th) * pow(k, 0.7);
                rb -= 0.025 * Noise3(p * 14.0 + _Seed) * (1.0 - k * 0.7); // 下ほど、ごつごつ
                return (r - rb) * 0.55;
            }

            // ---------------------------------------------------------------- ヤシの木

            float Palms(float3 p)
            {
                float d = 1.0;
                [loop] for (int k = 0; k < MOTUS; k++)
                {
                    float a = MOTU_A[k];
                    float2 c = float2(cos(a), sin(a)) * RingR(a);
                    float2 dc = p.xz - c;
                    if (dot(dc, dc) > 0.0064 || p.y > SEA + 0.12) continue; // 小島から遠い所は飛ばす
                    for (int j = 0; j < 2; j++)
                    {
                        float fk = k * 2 + j;
                        float2 bxz = c + (float2(Hash11(fk + 1.1), Hash11(fk + 2.3)) - 0.5) * 0.04;
                        float3 base = float3(bxz.x, SeabedFast(bxz) - 0.002, bxz.y);
                        float lean = Hash11(fk + 4.7) * 6.2831;
                        float3 top = base + float3(cos(lean) * 0.012, 0.05 + 0.012 * Hash11(fk + 5.9), sin(lean) * 0.012);
                        float3 q = p - top;
                        if (dot(q, q) > 0.0036 && length(p - base) > 0.06) continue;
                        d = min(d, SdCapsule(p, base, top, 0.0022));
                        // 葉: てっぺんから 6 枚、外へのびて垂れ下がる
                        [loop] for (int f = 0; f < 6; f++)
                        {
                            float b = f * 1.047 + fk;
                            float3 dir = float3(cos(b), 0.0, sin(b));
                            float3 mid = top + dir * 0.02 + float3(0, 0.004, 0);
                            float3 tip = top + dir * 0.034 + float3(0, -0.01, 0);
                            d = min(d, min(SdCapsule(p, top, mid, 0.0016), SdCapsule(p, mid, tip, 0.0012)));
                        }
                    }
                }
                return d;
            }

            // ---------------------------------------------------------------- 世界の形

            // 世界の形 (距離)。exact が true なら正確な海の底 (地面の向きを出すとき)、false なら速い版 (線を進めるとき)
            float2 MapX(float3 p, bool exact)
            {
                float2 res = float2(SdBox(p - float3(0, -0.46, 0), float3(0.5, 0.04, 0.5)), ID_BASE);
                float h;
                if (exact) h = Seabed(p.xz);
                else h = SeabedFast(p.xz);
                float rock = max((p.y - h) * 0.5, Body(p));
                if (rock < res.x) res = float2(rock, ID_GROUND);
                // 海の水: 縁の内側で、底から水面まで
                float r = length(p.xz);
                float R = DiskR(atan2(p.z, p.x));
                float water = max(max(p.y - SeaLevel(), r - (R - 0.004)), (SEA - 0.08) - p.y);
                if (water < res.x) res = float2(water, ID_WATER);
                float palm = Palms(p);
                if (palm < res.x) res = float2(palm, ID_PALM);
                return res;
            }

            float2 Map(float3 p) { return MapX(p, false); }

            float3 SceneNormal(float3 p)
            {
                const float2 e = float2(0.0006, -0.0006);
                float3 g = e.xyy * MapX(p + e.xyy, true).x + e.yyx * MapX(p + e.yyx, true).x +
                           e.yxy * MapX(p + e.yxy, true).x + e.xxx * MapX(p + e.xxx, true).x;
                return g / max(length(g), 1e-7); // 0 で割らないように
            }

            float SoftShadow(float3 p, float3 l)
            {
                float res = 1.0;
                float t = 0.004;
                int n = (int)_ShadowSteps;
                [loop] for (int i = 0; i < 32; i++)
                {
                    if (i >= n) break;
                    float h = Map(p + l * t).x;
                    res = min(res, 10.0 * h / t);
                    t += clamp(h, 0.003, 0.04);
                    if (res < 0.01 || t > 0.8) break;
                }
                return saturate(res);
            }

            float AmbientOcclusion(float3 p, float3 n)
            {
                float occ = 0.0;
                float w = 1.0;
                [loop] for (int i = 1; i <= 4; i++)
                {
                    float d = 0.008 * i;
                    occ += (d - Map(p + n * d).x) * w;
                    w *= 0.6;
                }
                return saturate(1.0 - occ * 16.0);
            }

            // 水面を流れる雲の影 (1 が日なた)
            float CloudShadow(float2 xz)
            {
                return lerp(0.55, 1.0, smoothstep(0.35, 0.6, Fbm3(xz * 3.0 + float2(_Time.y * 0.03, _Time.y * 0.01))));
            }

            // ---------------------------------------------------------------- 滝 (立体)

            // 縁からこぼれ落ちる滝を、滝ごとの向きにそろえた箱の中で進みながら重ねる。下へ行くほど広がって、霧になって消える
            float4 Falls(float3 ro, float3 rd, float tMax, float3 sunCol)
            {
                float3 col = 0;
                float trans = 1.0;
                float flow = 1.0 - 0.75 * smoothstep(0.0, 1.0, _Event); // 潮が引くと細くなる
                [loop] for (int k = 0; k < FALLS; k++)
                {
                    float a = FALL_A[k];
                    float2 dir = float2(cos(a), sin(a));
                    float2 side = float2(-dir.y, dir.x);
                    float R = DiskR(a);
                    // 滝の向きにそろえた座標 (x: 横、y: 高さ、z: 外向き)
                    float3 o = float3(dot(ro.xz, side), ro.y, dot(ro.xz, dir));
                    float3 v = float3(dot(rd.xz, side), rd.y, dot(rd.xz, dir));
                    float3 bmin = float3(-0.07, -0.45, R - 0.01);
                    float3 bmax = float3(0.07, SEA + 0.008, R + 0.1);
                    float3 inv = 1.0 / v;
                    float3 t0 = (bmin - o) * inv, t1 = (bmax - o) * inv;
                    float3 tsmall = min(t0, t1), tbig = max(t0, t1);
                    float tin = max(max(max(tsmall.x, tsmall.y), tsmall.z), 0.0);
                    float tout = min(min(min(tbig.x, tbig.y), tbig.z), tMax);
                    if (tout <= tin) continue;
                    const int steps = 16;
                    float dt = (tout - tin) / steps;
                    float t = tin + dt * Hash21(rd.xy * 331.0 + _Time.y + k);
                    [loop] for (int s = 0; s < steps; s++)
                    {
                        float3 q = o + v * t;
                        float fallen = max(SEA - q.y, 0.0);
                        float zc = R + 0.006 + 0.03 * sqrt(fallen);          // 縁から少し前へ飛び出してから落ちる
                        float w = (0.016 + 0.08 * fallen) * flow;           // 下ほど広がる
                        float thick = 0.004 + 0.05 * fallen;
                        float fx = saturate(1.0 - abs(q.x) / max(w, 0.001));
                        float fz = saturate(1.0 - abs(q.z - zc) / thick);
                        float streak = Noise3(float3(q.x * 140.0, q.y * 12.0 + _Time.y * 3.0, k * 5.0));
                        float dens = fx * fz * (0.4 + streak) * 60.0 * exp(-fallen * 4.0) * flow;
                        if (dens > 0.0)
                        {
                            float aa = 1.0 - exp(-dens * dt);
                            col += trans * aa * (float3(0.75, 0.85, 0.95) * (0.35 + 0.65 * sunCol.r));
                            trans *= 1.0 - aa;
                        }
                        t += dt;
                    }
                }
                return float4(col, trans);
            }

            // ---------------------------------------------------------------- 雲

            float CloudDensity(float3 p)
            {
                float dens = 0.0;
                [loop] for (int k = 0; k < CLOUDS; k++)
                {
                    float4 c = CLOUD[k];
                    float3 q = p - c.xyz - float3(sin(_Time.y * 0.05 + k) * 0.02, 0, 0);
                    q.y *= 1.8; // 平たい雲
                    float shape = saturate(1.0 - length(q) / c.w);
                    if (shape <= 0.0) continue;
                    float n = Noise3(q * 40.0 + float3(_Time.y * 0.02, 0, k * 3.0)) * 0.6 + Noise3(q * 90.0) * 0.4;
                    dens += max(0.0, shape * 1.3 + n * 0.7 - 0.85) * 60.0;
                }
                return dens;
            }

            float4 Clouds(float3 ro, float3 rd, float tMax, float3 sunDir)
            {
                float3 bmin = float3(-INNER, -0.42, -INNER);
                float3 bmax = float3(INNER, 0.3, INNER);
                float3 inv = 1.0 / rd;
                float3 t0 = (bmin - ro) * inv, t1 = (bmax - ro) * inv;
                float3 tsmall = min(t0, t1), tbig = max(t0, t1);
                float tin = max(max(max(tsmall.x, tsmall.y), tsmall.z), 0.0);
                float tout = min(min(min(tbig.x, tbig.y), tbig.z), tMax);
                if (tout <= tin) return float4(0, 0, 0, 1);
                int steps = clamp((int)(_Steps / 6.0), 8, 24);
                float dt = (tout - tin) / steps;
                float t = tin + dt * Hash21(rd.zx * 517.0 + _Time.y);
                float3 col = 0;
                float trans = 1.0;
                [loop] for (int i = 0; i < 24; i++)
                {
                    if (i >= steps) break;
                    float3 p = ro + rd * t;
                    float dens = CloudDensity(p);
                    if (dens > 0.0)
                    {
                        float lit = exp(-CloudDensity(p + sunDir * 0.02) * 0.02); // 日の当たる側ほど白く、陰は青灰色
                        float a = 1.0 - exp(-dens * dt);
                        col += trans * a * lerp(float3(0.45, 0.52, 0.65), float3(1.15, 1.12, 1.05), lit);
                        trans *= 1.0 - a;
                        if (trans < 0.02) break;
                    }
                    t += dt;
                }
                return float4(col, trans);
            }

            // ---------------------------------------------------------------- 空 (中に入ったとき)

            float3 Sky(float3 rd, float3 sunDir)
            {
                float up = saturate(rd.y);
                float3 c = lerp(float3(0.75, 0.85, 0.95), float3(0.2, 0.45, 0.85), pow(up, 0.6));
                float sd = dot(rd, sunDir);
                c += float3(2.5, 2.3, 2.0) * smoothstep(0.9995, 0.9998, sd) + float3(0.5, 0.4, 0.25) * pow(saturate(sd), 60.0) * 0.4;
                // はるか下の雲の海
                float below = saturate(-rd.y);
                float sea = Fbm3(rd.xz / max(-rd.y, 0.05) * 1.5 + _Time.y * 0.005);
                c = lerp(c, lerp(float3(0.8, 0.85, 0.92), float3(1.05, 1.05, 1.05), sea), smoothstep(0.0, 0.08, below));
                return c;
            }

            // ---------------------------------------------------------------- 色を塗る

            float3 Shade(float3 ro, float3 rd, float3 p, float id, bool outside, float3 faceNormal, float3 sunDir, float3 sunCol, float3 skyCol)
            {
                if (id == ID_BASE)
                {
                    if (outside) return float3(0.015, 0.014, 0.014) + 0.03 * pow(saturate(1.0 - abs(dot(rd, faceNormal))), 4.0);
                    // 中に入っているときは、台ははるか下の雲の海に見せる
                    float n = Fbm3(p.xz * 6.0 + _Time.y * 0.01);
                    return lerp(float3(0.75, 0.8, 0.88), float3(1.05, 1.05, 1.05), n);
                }

                float shade = CloudShadow(p.xz);
                float t = _Time.y;

                if (id == ID_WATER)
                {
                    // 波: 向きと大きさのちがう波を 3 つ重ねる
                    float2 w1 = float2(ValueNoise(p.xz * 60.0 + float2(t * 0.6, t * 0.2)), ValueNoise(p.xz * 60.0 + 7.0 - float2(t * 0.3, t * 0.5)));
                    float2 w2 = float2(ValueNoise(p.xz * 150.0 + float2(-t * 0.9, t * 0.4)), ValueNoise(p.xz * 150.0 + 3.0 + float2(t * 0.5, -t * 0.8)));
                    float2 w3 = float2(ValueNoise(p.xz * 330.0 + t * 1.4), ValueNoise(p.xz * 330.0 + 11.0 - t * 1.2));
                    float2 slope = (w1 - 0.5) * 0.07 + (w2 - 0.5) * 0.05 + (w3 - 0.5) * 0.025;
                    float3 n = normalize(float3(slope.x, 1.0, slope.y));
                    float3 r = reflect(rd, n);
                    float fres = 0.02 + 0.98 * pow(1.0 - saturate(dot(-rd, n)), 5.0);

                    // 屈折: 水の中へ曲がって入る線で、底の少しずれた所を見る (波で底がゆらいで見える)
                    float3 rr = refract(rd, n, 0.75);
                    float down = max(-rr.y, 0.2);
                    float depth0 = max(p.y - SeabedFast(p.xz), 0.0);
                    float3 bp = p + rr * (depth0 / down);
                    float depth = max(p.y - SeabedFast(bp.xz), 0.0);
                    float path = depth / down + depth; // 日の光が底まで届く道のりと、底から目まで戻る道のり

                    // 底: 白い砂の波紋、海草の茂み、サンゴのかたまり
                    float ripple = 0.5 + 0.5 * sin(dot(bp.xz, float2(0.7, 0.7)) * 500.0 + ValueNoise(bp.xz * 40.0) * 5.0);
                    float grass = smoothstep(0.55, 0.7, Fbm3(bp.xz * 9.0 + _Seed));
                    float coral = smoothstep(0.62, 0.75, ValueNoise(bp.xz * 25.0 + 3.0));
                    float3 bedCol = float3(0.95, 0.9, 0.78) * (0.86 + 0.14 * ripple);
                    bedCol = lerp(bedCol, float3(0.16, 0.3, 0.1), grass * 0.8);
                    bedCol = lerp(bedCol, float3(0.55, 0.42, 0.38), coral * 0.7);
                    // 浅瀬を泳ぐ魚の影
                    float fishShadow = 1.0;
                    [loop] for (int k = 0; k < 6; k++)
                    {
                        float fk = k;
                        float a = t * (0.25 + 0.04 * fk) + fk * 1.1;
                        float rad = 0.08 + 0.05 * sin(fk * 1.7);
                        float2 fc = float2(cos(a), sin(a)) * rad;
                        float2 dir = float2(-sin(a), cos(a));
                        float2 dv = bp.xz - fc;
                        float along = dot(dv, dir) / 0.007;
                        float across = (dv.x * dir.y - dv.y * dir.x) / 0.0025;
                        fishShadow *= 1.0 - 0.45 * exp(-(along * along + across * across));
                    }
                    // 底の光の網目: くっきりした細い線が、ゆらゆら動く
                    float c1 = 1.0 - abs(ValueNoise(bp.xz * 70.0 + t * 0.5) - 0.5) * 2.0;
                    float c2 = 1.0 - abs(ValueNoise(bp.xz * 110.0 - t * 0.4 + 3.0) - 0.5) * 2.0;
                    float caustic = (pow(c1, 12.0) + pow(c2, 12.0)) * 1.5;
                    float3 bedLit = bedCol * (sunCol * shade * (0.55 + caustic * exp(-depth * 20.0)) * fishShadow + 0.25);

                    // 水の色: 赤い光ほど早く吸われる。浅い所は透明で底が見え、深くなるとターコイズ、さらに深いと青
                    float3 absorb = exp(-float3(38.0, 9.0, 5.5) * path);
                    float3 scatterCol = float3(0.04, 0.4, 0.5) * (sunCol.g * shade * 0.6 + 0.3);
                    float3 under = bedLit * absorb + scatterCol * (1.0 - absorb.g);

                    // 空の映り込みと、日のきらめき
                    float3 sky = lerp(float3(0.75, 0.85, 0.95), float3(0.25, 0.5, 0.9), saturate(r.y));
                    float3 c = lerp(under, sky, fres);
                    float sd = saturate(dot(r, sunDir));
                    c += sunCol * (pow(sd, 800.0) * 10.0 + pow(sd, 80.0) * 0.25) * shade;

                    // 白い波: サンゴ礁と小島の浅い縁で砕け、岸へ寄せる筋になる
                    float edge = smoothstep(0.008, 0.0, depth0);
                    float surf = smoothstep(0.35, 0.75, Noise3(float3(p.xz * 120.0, t * 0.8))) * (0.6 + 0.4 * sin(t * 2.0 - depth0 * 900.0));
                    float foam = saturate(edge * surf * 1.4);
                    c = lerp(c, float3(0.95, 0.97, 1.0) * (sunCol * shade * 0.55 + 0.3), foam * 0.85);
                    return c;
                }

                float3 n = SceneNormal(p);
                float sh = SoftShadow(p + n * 0.002, sunDir);
                float ao = AmbientOcclusion(p, n);
                float diffuse = saturate(dot(n, sunDir)) * sh * shade;
                float3 amb = float3(0.3, 0.42, 0.6) * (0.4 + 0.6 * saturate(n.y)) * 0.6;

                if (id == ID_PALM)
                {
                    // ヤシ: 幹は茶色、葉は緑 (葉は細いので、高い所ほど葉とみなす)
                    float bed = SeabedFast(p.xz);
                    float leaf = smoothstep(SEA + 0.04, SEA + 0.05, p.y);
                    float3 albedo = lerp(float3(0.3, 0.22, 0.13), float3(0.12, 0.38, 0.1), leaf);
                    return albedo * (sunCol * diffuse + amb) * ao;
                }

                // 島: 水面より上の小島は、砂浜と緑。土台は、茶色い岩の層とこけ
                float above = p.y - SeaLevel();
                float3 albedo;
                if (p.y > SEA - 0.035)
                {
                    float green = smoothstep(0.008, 0.016, above + 0.004 * ValueNoise(p.xz * 80.0)) * smoothstep(0.4, 0.75, n.y);
                    // 砂浜: 細かい砂粒のむらと、風の波紋。波打ち際は濡れて暗い
                    float grain = 0.9 + 0.1 * Noise3(p * 2500.0);
                    float windRipple = 0.95 + 0.05 * sin(dot(p.xz, float2(0.6, 0.8)) * 700.0);
                    float3 sand = float3(0.94, 0.89, 0.74) * grain * windRipple;
                    sand *= 1.0 - 0.35 * smoothstep(0.006, 0.0, above);
                    // 草地: 緑のむらと、ところどころの土
                    float3 leafy = lerp(float3(0.12, 0.34, 0.1), float3(0.25, 0.48, 0.15), Noise3(p * 400.0));
                    albedo = lerp(sand, leafy, green);
                    // 水の中だった所 (潮が引いて出てきた所) は、少し濡れて暗い
                    albedo *= above < 0.012 * smoothstep(0.0, 1.0, _Event) ? 0.75 : 1.0;
                }
                else
                {
                    float band = 0.5 + 0.5 * sin(p.y * 90.0 + Noise3(p * 20.0) * 3.0);
                    albedo = lerp(float3(0.22, 0.17, 0.13), float3(0.42, 0.34, 0.26), band);
                    float moss = smoothstep(0.5, 0.7, Noise3(p * 30.0 + 5.0)) * smoothstep(-0.2, 0.0, p.y);
                    albedo = lerp(albedo, float3(0.16, 0.3, 0.12), moss * 0.7);
                }
                return albedo * (sunCol * diffuse + amb) * ao;
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

                float3 ro = TransformWorldToObject(GetCameraPositionWS());
                float3 rd = normalize(input.positionOS - ro);
                float2 box = BoxHit(ro, rd, float3(0.5, 0.5, 0.5));
                bool outside = box.x > 0.0;
                float t = max(box.x, 0.0);

                float3 entry = ro + rd * t;
                float3 ae = abs(entry);
                float3 faceNormal = ae.x > ae.y && ae.x > ae.z ? float3(sign(entry.x), 0, 0)
                                  : (ae.y > ae.z ? float3(0, sign(entry.y), 0) : float3(0, 0, sign(entry.z)));

                // 島 (ヤシ) より上の何もない空間は飛ばす
                const float maxHeight = 0.2;
                if (ro.y > maxHeight && rd.y < 0.0) t = max(t, (maxHeight - ro.y) / rd.y);

                bool hit = false;
                float id = 0.0;
                int steps = (int)_Steps;
                [loop] for (int i = 0; i < 200; i++)
                {
                    if (i >= steps || t > box.y) break;
                    float3 pos = ro + rd * t;
                    if (rd.y > 0.0 && pos.y > maxHeight + 0.01) break; // 島より上に出て上を向いている線は、もう何にも当たらない
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
                    // 当たった所を、正確な形で 2 回だけ合わせ直す
                    for (int r = 0; r < 2; r++) t += MapX(ro + rd * t, true).x;
                }
                float tHit = hit ? t : box.y;

                float3 sunDir = normalize(SUN_DIR);
                float3 sunCol = float3(1.6, 1.5, 1.3);
                float3 skyCol = float3(0.45, 0.65, 0.9);

                float3 col = 0;
                if (hit)
                {
                    float3 p = ro + rd * t;
                    col = Shade(ro, rd, p, id, outside, faceNormal, sunDir, sunCol, skyCol);
                }
                else if (!outside)
                {
                    col = Sky(rd, sunDir); // 中に入っているときだけ、空を描く
                }

                // 霞: 遠くほど、昼の空の色に溶ける
                float travel = tHit - max(box.x, 0.0);
                if (hit) col = lerp(col, float3(0.6, 0.72, 0.85), (1.0 - exp(-travel * 0.35)) * 0.5);

                float alpha = (hit || !outside) ? 1.0 : 0.0;

                // 滝と雲を重ねる (色は不透明度を掛けた形で持つ)
                float4 falls = Falls(ro, rd, tHit, sunCol);
                col = col * falls.a + falls.rgb;
                alpha = 1.0 - (1.0 - alpha) * falls.a;
                float4 clouds = Clouds(ro, rd, tHit, sunDir);
                col = col * clouds.a + clouds.rgb;
                alpha = 1.0 - (1.0 - alpha) * clouds.a;

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
