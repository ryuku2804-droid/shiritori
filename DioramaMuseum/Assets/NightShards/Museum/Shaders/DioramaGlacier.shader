// 作品「月下の氷河」(月の間)。月夜の雪の峰と、湖へ流れ込む氷河。URP 用。
// Cube の中をレイマーチングして描く。Cube の座標は -0.5〜0.5、下の 0.08 は黒い台。
//
// 見どころ:
//   ・するどい雪の峰に囲まれた谷。奥の峰のあいだから、青白い氷河が流れ下ってくる
//   ・氷河の表面には横向きの割れ目 (クレバス)。割れ目の奥が、月の光で青く透ける
//   ・氷河の先は、湖に切り立った青い氷の崖。湖面には、月から手前へのびる一本の光の道
//   ・雪のきらめき、湖の上をはうもや
// 仕掛け (_Event 0〜1): 氷河の崖が崩れる。氷の塊が倒れて湖に落ち、しぶきが上がり、波紋が湖いっぱいに広がって、氷山として浮かぶ
//
// 外から見たとき、地形のない所 (空) は透明にして、ガラスケースの向こうの部屋が見えるようにする。
// 中に入ったとき (カメラが箱の中) だけ、空と月を描く
//
// _Steps / _ShadowSteps は DioramaLOD が距離で下げる。_Event / _EventTime は DioramaWork が渡す。
// _HeightTex は DioramaWork が再生の最初に作る、岩の地形の高さの表 (なければ式で計算する)
Shader "NightShards/Diorama/Glacier"
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
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma multi_compile_instancing

            #define ID_BASE   0.0
            #define ID_GROUND 1.0
            #define ID_WATER  2.0
            #define ID_ICE    3.0

            #define INNER 0.47
            #define WATER -0.2
            static const float3 MOON_DIR = float3(-0.35, 0.6, -0.72); // 奥の左の空。正規化は使う所で

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

            // とがった尾根のノイズ: 山の稜線のように、するどい峰ができる
            float Ridged(float2 p)
            {
                float s = 0.0, a = 0.5, w = 1.0;
                [loop] for (int i = 0; i < 4; i++)
                {
                    float n = 1.0 - abs(ValueNoise(p) * 2.0 - 1.0);
                    n = n * n * w;
                    w = saturate(n * 1.5); // 前の峰が高い所ほど、細かい峰も強く出る
                    s += n * a;
                    p = p * 2.07 + 13.1;
                    a *= 0.5;
                }
                return s;
            }

            float SdBox(float3 p, float3 b)
            {
                float3 q = abs(p) - b;
                return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
            }

            // ---------------------------------------------------------------- 地形
            // ※ ValleyX・FloorY・RockHeight・TerminusZ・GlacierTop を変えたら、C# の DioramaTerrain も同じに直す

            // 谷の真ん中の線 (x)。奥へ向かって少しくねる
            float ValleyX(float z) { return 0.05 * sin(z * 5.0 + _Seed); }

            // 谷底の高さ。奥ほど高く、手前の岸で少し上がる
            float FloorY(float z)
            {
                return lerp(-0.26, 0.02, smoothstep(0.0, -0.45, z)) + 0.11 * smoothstep(0.24, 0.44, z);
            }

            // 岩と雪の山 (氷河は別)。谷の両側と奥に、するどい峰が立つ
            float RockHeight(float2 xz)
            {
                float side = abs(xz.x - ValleyX(xz.y));
                float back = smoothstep(-0.12, -0.44, xz.y);
                float m = 0.3 * max(smoothstep(0.1, 0.42, side), back);
                float h = FloorY(xz.y) + m * (0.15 + 0.85 * Ridged(xz * 4.0 + _Seed));
                h += 0.008 * Fbm3(xz * 20.0 + _Seed) - 0.004;
                return h;
            }

            // 岩の高さ (速い版)。再生中は、最初に 1 回だけ計算して保存した表を読むだけ
            float HeightFast(float2 xz)
            {
                [branch] if (_HeightTexOn > 0.5)
                    return SAMPLE_TEXTURE2D_LOD(_HeightTex, sampler_linear_clamp, xz / (2.0 * INNER) + 0.5, 0).r;
                return RockHeight(xz);
            }

            // 氷河の先 (湖に面した崖) の z。真ん中ほど湖へ張り出す
            float TerminusZ(float x)
            {
                float dx = (x - ValleyX(-0.02)) / 0.2;
                return -0.04 + 0.05 * saturate(1.0 - dx * dx);
            }

            // 氷河の割れ目 (クレバス) の深さ 0〜1
            float Crevasse(float2 xz, float dx)
            {
                float cv = sin((xz.y + 0.05 * dx * dx) * 140.0 + ValueNoise(xz * 30.0 + _Seed) * 3.0);
                return smoothstep(0.7, 1.0, cv);
            }

            // 氷河の表面の高さ。谷の真ん中ほど盛り上がり、横向きの割れ目が入る
            float GlacierTop(float2 xz)
            {
                float dx = (xz.x - ValleyX(xz.y)) / 0.2;
                float prof = saturate(1.0 - dx * dx * dx * dx);
                return FloorY(xz.y) + 0.13 * prof - 0.005 * Crevasse(xz, dx) * prof;
            }

            // ---------------------------------------------------------------- 崩れる氷の塊 (仕掛け)

            // 崩れる塊の、もとの場所 (崖の真ん中) の情報。x = 真ん中の x、y = 崖の高さ、z = 崖の z
            float3 ChunkInfo()
            {
                float cx = ValleyX(-0.02);
                float zt = TerminusZ(cx);
                float height = GlacierTop(float2(cx, zt - 0.01)) - (WATER - 0.02) + 0.01;
                return float3(cx, height, zt);
            }

            // 崩れる前の塊の形 (崖から切り取る所)
            float ChunkHome(float3 p, float3 info)
            {
                float3 center = float3(info.x, WATER - 0.02 + info.y * 0.5, info.z - 0.0175);
                return SdBox(p - center, float3(0.045, info.y * 0.5, 0.0175));
            }

            bool Calving() { return _Event > 0.01 && _EventTime > 1.5; }

            // 倒れて湖に落ち、氷山として浮かぶ塊の形
            float Block(float3 p, float3 info)
            {
                float te = _EventTime;
                float k = smoothstep(1.6, 3.0, te);
                float a = 1.5708 * k * k;                                       // 根元を軸に、手前へ倒れる
                float3 pivot = float3(info.x, WATER - 0.02, info.z);
                pivot.z += 0.012 * max(0.0, te - 3.0);                          // 落ちたあとは、ゆっくり流される
                pivot.y += 0.002 * sin(te * 2.0) * step(3.0, te) - 0.05 * smoothstep(12.0, 17.0, te); // 揺れて、最後は沈む
                float3 q = p - pivot;
                float s = sin(a), c = cos(a);
                float3 local = float3(q.x, q.y * c + q.z * s, -q.y * s + q.z * c);
                float d = SdBox(local - float3(0, info.y * 0.5, -0.0175), float3(0.045, info.y * 0.5, 0.0175)) - 0.002;
                return d - 0.003 * ValueNoise(local.xy * 80.0 + local.z * 40.0);
            }

            // 氷河 (距離)。上の面と、湖に面した崖の面で囲む。崩れたあとは、塊の所がえぐれる
            float Glacier(float3 p, float3 info)
            {
                float top = (p.y - GlacierTop(p.xz)) * 0.5;
                float front = (p.z - TerminusZ(p.x)) * 0.7;
                front -= 0.004 * ValueNoise(float2(p.x * 90.0, p.y * 25.0) + _Seed); // 崖の縦の筋 (セラック)
                float d = max(top, front);
                if (Calving()) d = max(d, -ChunkHome(p, info));
                return d;
            }

            // ---------------------------------------------------------------- 世界の形

            // 世界の形 (距離)。exact が true なら正確な地形 (地面の向きを出すとき)、false なら速い地形 (線を進めるとき)
            float2 MapX(float3 p, bool exact)
            {
                float2 res = float2(SdBox(p - float3(0, -0.46, 0), float3(0.5, 0.04, 0.5)), ID_BASE);
                float column = SdBox(p - float3(0, 0.04, 0), float3(INNER, 0.46, INNER));
                float h;
                if (exact) h = RockHeight(p.xz);
                else h = HeightFast(p.xz);
                float ground = max((p.y - h) * 0.5, column);
                if (ground < res.x) res = float2(ground, ID_GROUND);
                float3 info = 0;
                if (Calving()) info = ChunkInfo(); // 崩れる塊の情報は、仕掛けの最中だけ計算する
                float ice = max(Glacier(p, info), column);
                if (Calving()) ice = min(ice, max(Block(p, info), column));
                if (ice < res.x) res = float2(ice, ID_ICE);
                float water = max(p.y - WATER, column);
                if (water < res.x) res = float2(water, ID_WATER);
                return res;
            }

            float2 Map(float3 p) { return MapX(p, false); }

            float3 SceneNormal(float3 p)
            {
                const float2 e = float2(0.0008, -0.0008);
                float3 g = e.xyy * MapX(p + e.xyy, true).x + e.yyx * MapX(p + e.yyx, true).x +
                           e.yxy * MapX(p + e.yxy, true).x + e.xxx * MapX(p + e.xxx, true).x;
                return g / max(length(g), 1e-7); // 0 で割らないように
            }

            float SoftShadow(float3 p, float3 l)
            {
                float res = 1.0;
                float t = 0.006;
                int n = (int)_ShadowSteps;
                [loop] for (int i = 0; i < 32; i++)
                {
                    if (i >= n) break;
                    float h = Map(p + l * t).x;
                    res = min(res, 10.0 * h / t);
                    t += clamp(h, 0.004, 0.05);
                    if (res < 0.01 || t > 1.0) break;
                }
                return saturate(res);
            }

            float AmbientOcclusion(float3 p, float3 n)
            {
                float occ = 0.0;
                float w = 1.0;
                [loop] for (int i = 1; i <= 4; i++)
                {
                    float d = 0.012 * i;
                    occ += (d - Map(p + n * d).x) * w;
                    w *= 0.6;
                }
                return saturate(1.0 - occ * 14.0);
            }

            // ---------------------------------------------------------------- しぶきと、湖の上のもや

            // 塊が湖に落ちた所 (しぶきと波紋の中心)
            float3 ImpactPoint(float3 info)
            {
                return float3(info.x, WATER, info.z + info.y * 0.7);
            }

            float MistDensity(float3 p, float3 impact)
            {
                float y = p.y - WATER;
                float dens = 0.0;
                // 湖の上をはう、うすいもや
                if (y > 0.0 && y < 0.03)
                    dens += smoothstep(0.03, 0.0, y) * Noise3(float3(p.x * 25.0 + _Time.y * 0.02, y * 50.0, p.z * 25.0)) * 3.0;
                // しぶき: 塊が落ちた瞬間に白く吹き上がり、広がりながら消える
                float ts = _EventTime - 2.9;
                if (_Event > 0.01 && ts > 0.0 && ts < 4.0)
                {
                    float3 q = p - impact;
                    float rad = 0.02 + 0.07 * sqrt(ts);
                    float lift = 0.06 * ts * exp(-ts * 0.8);
                    float shape = saturate(1.0 - length(float3(q.x, (q.y - lift) * 1.4, q.z)) / rad);
                    float n = Noise3(q * 70.0 + float3(0, -ts * 3.0, 0));
                    dens += max(0.0, shape * 1.4 + n * 0.8 - 1.0) * 120.0 * exp(-ts * 0.9);
                }
                return dens;
            }

            float4 Mist(float3 ro, float3 rd, float tMax, float3 impact)
            {
                float3 bmin = float3(-INNER, WATER, -INNER);
                float3 bmax = float3(INNER, WATER + 0.2, INNER);
                float3 inv = 1.0 / rd;
                float3 t0 = (bmin - ro) * inv, t1 = (bmax - ro) * inv;
                float3 tsmall = min(t0, t1), tbig = max(t0, t1);
                float tin = max(max(max(tsmall.x, tsmall.y), tsmall.z), 0.0);
                float tout = min(min(min(tbig.x, tbig.y), tbig.z), tMax);
                if (tout <= tin) return float4(0, 0, 0, 1);

                const int steps = 18;
                float dt = (tout - tin) / steps;
                float t = tin + dt * Hash21(rd.xy * 517.0 + _Time.y);
                float3 col = 0;
                float trans = 1.0;
                [loop] for (int i = 0; i < steps; i++)
                {
                    float3 p = ro + rd * t;
                    float dens = MistDensity(p, impact);
                    if (dens > 0.0)
                    {
                        float a = 1.0 - exp(-dens * dt);
                        col += trans * a * float3(0.2, 0.24, 0.32); // 月に照らされた、青白い霧
                        trans *= 1.0 - a;
                        if (trans < 0.02) break;
                    }
                    t += dt;
                }
                return float4(col, trans);
            }

            // ---------------------------------------------------------------- 空 (中に入ったとき)

            float3 Sky(float3 rd)
            {
                float up = saturate(rd.y);
                float3 c = lerp(float3(0.03, 0.045, 0.09), float3(0.004, 0.008, 0.025), sqrt(up));
                // 星
                float3 sp = rd * 220.0;
                float3 cell = floor(sp);
                float star = step(0.993, Hash31(cell)) * smoothstep(0.25, 0.1, length(frac(sp) - 0.5));
                c += star * 0.8 * smoothstep(0.05, 0.3, rd.y);
                // 満月と、そのまわりの光の輪
                float3 md = normalize(MOON_DIR);
                float mc = dot(rd, md);
                float disc = smoothstep(0.99935, 0.9996, mc);
                float maria = 0.85 + 0.15 * ValueNoise((rd - md * mc).xy * 900.0); // 月の模様
                c += float3(2.2, 2.2, 2.1) * disc * maria;
                c += float3(0.35, 0.42, 0.6) * (pow(saturate(mc), 300.0) * 0.5 + pow(saturate(mc), 20.0) * 0.06);
                return c;
            }

            // ---------------------------------------------------------------- 湖の映り込み

            float3 Reflection(float3 p, float3 r, float3 info, float3 moonDir, float3 moonCol)
            {
                float t = 0.004;
                [loop] for (int i = 0; i < 40; i++)
                {
                    float3 q = p + r * t;
                    if (abs(q.x) > INNER || abs(q.z) > INNER || q.y > 0.45) break;
                    float rock = (q.y - HeightFast(q.xz)) * 0.5;
                    float ice = Glacier(q, info);
                    float d = min(rock, ice);
                    if (d < 0.0008)
                    {
                        // 映った山と氷河: 高い所ほど雪で白く、氷は青白い
                        float snow = smoothstep(-0.18, 0.05, q.y);
                        float3 c = ice < rock ? float3(0.16, 0.26, 0.38) : lerp(float3(0.02, 0.022, 0.03), float3(0.2, 0.23, 0.3), snow);
                        return c * (moonCol * 0.8 + 0.1);
                    }
                    t += max(d, 0.002);
                }
                return Sky(r);
            }

            // ---------------------------------------------------------------- 色を塗る

            float3 Shade(float3 ro, float3 rd, float3 p, float id, bool crossSection, float3 faceNormal, float3 info, float3 impact)
            {
                float3 moonDir = normalize(MOON_DIR);
                float3 moonCol = float3(0.55, 0.62, 0.82);
                float3 skyAmb = float3(0.025, 0.035, 0.065);
                float t = _Time.y;

                if (id == ID_BASE)
                    return float3(0.015, 0.014, 0.014) + 0.03 * pow(saturate(dot(reflect(rd, faceNormal), moonDir)), 8.0);

                if (crossSection)
                {
                    if (id == ID_WATER)
                    {
                        float depth = WATER - p.y;
                        return lerp(float3(0.01, 0.03, 0.05), float3(0.002, 0.006, 0.015), saturate(depth * 8.0));
                    }
                    // 断面: 氷は年ごとの層が青く、岩は黒い層
                    float band = 0.5 + 0.5 * sin(p.y * 140.0 + ValueNoise(p.xz * 40.0 + p.y * 30.0) * 4.0);
                    if (id == ID_ICE) return lerp(float3(0.05, 0.16, 0.3), float3(0.12, 0.28, 0.45), band) * 0.5;
                    return lerp(float3(0.03, 0.03, 0.035), float3(0.08, 0.075, 0.08), band) * 0.3;
                }

                if (id == ID_WATER)
                {
                    // 夜の湖: さざ波で月を細かく映し、光の道をつくる。仕掛けの最中は、落ちた所から波紋が広がる
                    float2 q = p.xz * float2(60.0, 140.0); // 手前から奥への向きに細かい波 → 光の道が縦にのびる
                    float2 slope = (float2(ValueNoise(q + t * 0.6), ValueNoise(q.yx * 1.3 - t * 0.7)) - 0.5) * 0.18;
                    if (_Event > 0.01 && _EventTime > 3.0)
                    {
                        float2 dv = p.xz - impact.xz;
                        float d = length(dv);
                        float front = (_EventTime - 3.0) * 0.06;
                        float rr = (d - front) / 0.06;
                        float ring = sin((d - front) * 160.0) * exp(-rr * rr) * exp(-(_EventTime - 3.0) * 0.25);
                        slope += dv / max(d, 0.001) * ring * 0.35;
                    }
                    float3 n = normalize(float3(slope.x, 1.0, slope.y));
                    float3 r = reflect(rd, n);
                    float fres = 0.02 + 0.98 * pow(1.0 - saturate(dot(-rd, n)), 5.0);
                    float3 refl = Reflection(p, r, info, moonDir, moonCol);
                    float3 body = float3(0.004, 0.01, 0.02);
                    float3 c = lerp(body, refl, fres);
                    // 月の光の道: 波のひとつひとつが月をきらりと映す
                    c += float3(1.6, 1.7, 1.9) * (pow(saturate(dot(r, moonDir)), 600.0) * 6.0 + pow(saturate(dot(r, moonDir)), 60.0) * 0.12);
                    return c;
                }

                float3 n = SceneNormal(p);
                float sh = SoftShadow(p + n * 0.002, moonDir);
                float ao = AmbientOcclusion(p, n);
                float diffuse = saturate(dot(n, moonDir)) * sh;

                if (id == ID_ICE)
                {
                    // 氷河: 平らな所は雪におおわれ、切り立った所と割れ目の奥は、青く透ける氷
                    float dx = (p.x - ValleyX(p.z)) / 0.2;
                    float crev = Crevasse(p.xz, dx);
                    float snow = smoothstep(0.55, 0.85, n.y) * (1.0 - crev);
                    float3 albedo = lerp(float3(0.22, 0.48, 0.75), float3(0.78, 0.83, 0.9), snow);
                    float3 c = albedo * (moonCol * diffuse + skyAmb * (0.6 + 0.4 * n.y)) * ao;
                    // 氷の中を通ってくる光 (青く光って見える)。崖の面と割れ目の奥ほど強い
                    float glow = (1.0 - snow) * (0.5 + 0.5 * sh) + crev * 0.8;
                    c += float3(0.02, 0.1, 0.2) * glow * (0.8 + 0.4 * ValueNoise(float2(p.x * 60.0, p.y * 20.0)));
                    // 雪のきらめき
                    float3 cell = floor(p * 1800.0);
                    float sparkle = step(0.985, Hash31(cell)) * pow(saturate(dot(reflect(rd, n), moonDir)), 4.0);
                    c += sparkle * snow * 1.5;
                    return c;
                }

                // 岩と雪の山: なだらかな所は雪、切り立った所は黒い岩
                float snowLine = smoothstep(0.5, 0.75, n.y + 0.15 * ValueNoise(p.xz * 60.0) + 0.1 * smoothstep(-0.1, 0.2, p.y));
                float band = 0.5 + 0.5 * sin(p.y * 90.0 + ValueNoise(p.xz * 30.0) * 3.0);
                float3 rock = lerp(float3(0.035, 0.034, 0.04), float3(0.08, 0.078, 0.085), band);
                float3 albedo = lerp(rock, float3(0.8, 0.84, 0.9), snowLine);
                float3 c = albedo * (moonCol * diffuse + skyAmb * (0.5 + 0.5 * n.y)) * ao;
                float3 cell = floor(p * 1800.0);
                float sparkle = step(0.985, Hash31(cell)) * pow(saturate(dot(reflect(rd, n), moonDir)), 4.0) * sh;
                c += sparkle * snowLine * 1.5;
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

                // 山より上の何もない空間は飛ばす
                const float maxHeight = 0.34;
                if (ro.y > maxHeight && rd.y < 0.0) t = max(t, (maxHeight - ro.y) / rd.y);

                bool hit = false;
                float id = 0.0;
                int steps = (int)_Steps;
                [loop] for (int i = 0; i < 200; i++)
                {
                    if (i >= steps || t > box.y) break;
                    float3 pos = ro + rd * t;
                    if (rd.y > 0.0 && pos.y > maxHeight + 0.01) break; // 山より上に出て上を向いている線は、もう何にも当たらない
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
                    // 当たった所を、正確な地形で 2 回だけ合わせ直す
                    for (int r = 0; r < 2; r++) t += MapX(ro + rd * t, true).x;
                }
                float tHit = hit ? t : box.y;

                float3 info = ChunkInfo();
                float3 impact = ImpactPoint(info);

                float3 col = 0;
                if (hit)
                {
                    float3 p = ro + rd * t;
                    bool crossSection = outside && (abs(p.x) > INNER - 0.002 || abs(p.z) > INNER - 0.002);
                    col = Shade(ro, rd, p, id, crossSection, faceNormal, info, impact);
                }
                else if (!outside)
                {
                    col = Sky(rd); // 中に入っているときだけ、空を描く
                }

                // 霞: 遠くの山ほど、夜の青い空気に沈む
                float travel = tHit - max(box.x, 0.0);
                float3 haze = float3(0.02, 0.03, 0.06);
                if (hit) col = lerp(col, haze, 1.0 - exp(-travel * 0.6));
                else if (!outside) col = lerp(col, haze, (1.0 - exp(-travel * 0.6)) * 0.3);

                // 不透明度。外から見た空の所は 0 (透明) から始めて、もやとしぶきが濃いほど不透明にする
                float alpha = (hit || !outside) ? 1.0 : 0.0;
                float4 mist = Mist(ro, rd, tHit, impact);
                col = col * mist.a + mist.rgb;
                alpha = 1.0 - (1.0 - alpha) * mist.a;

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
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input); // VR: 左右どちらの目を描いているか
                return input.positionCS.z;
            }
            ENDHLSL
        }
    }
}
