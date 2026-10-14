// 作品「青い火の火口湖」(火の間)。青い炎の滝が流れ落ちる、夜の崖と滝つぼ。URP 用。
// Cube の中をレイマーチングして描く。Cube の座標は -0.5〜0.5、下の 0.08 は黒い台。
// モデル: インドネシアのイジェン火山 (溶けた硫黄が燃えながら流れ落ち、夜に青い炎の川や滝に見える)
//
// 見どころ:
//   ・円形劇場のように滝つぼを囲む、黒い玄武岩の崖 (柱状節理の縦の筋)
//   ・崖のてっぺんの切れ込みから流れ落ちる、青い炎の滝。上の台地には、滝へ向かう青い炎の川
//   ・滝つぼは、白く濁ったターコイズの酸の湖。滝の青い光を映す
//   ・崖の割れ目から噴き出す、小さな青い炎。まわりには黄色い硫黄の結晶
//   ・滝つぼから立ちのぼる湯気、湖の上をはうもや、空いっぱいの星と天の川
// 仕掛け (_Event 0〜1): 滝が太く明るくなり、滝つぼから湖の表面へ青い炎が燃え広がって、湖全体が燃えるように光る
//
// 外から見たとき、地形のない所 (空) は透明にして、ガラスケースの向こうの部屋が見えるようにする。
// 中に入ったとき (カメラが箱の中) だけ、空を描く
//
// _Steps / _ShadowSteps は DioramaLOD が距離で下げる。_Event / _EventTime は DioramaWork が渡す
Shader "NightShards/Diorama/BlueFire"
{
    Properties
    {
        _Steps ("Ray Steps", Range(16, 200)) = 130
        _ShadowSteps ("Shadow Steps", Range(0, 32)) = 16
        _Glass ("Glass Reflection", Range(0, 1)) = 0.3
        _Event ("Event (0-1)", Range(0, 1)) = 0
        _EventTime ("Event Time (s)", Float) = 0
        _Seed ("Seed", Float) = 0
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
        CBUFFER_END
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

            #define INNER 0.47
            #define WATER -0.17
            #define JETS 5
            static const float2 POOL = float2(0.0, -0.03);           // 滝つぼの湖の中心
            static const float3 MOON_DIR = float3(0.55, 0.5, 0.65);  // 正規化は使う所で (手前の上から照らす)

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
            // ※ CliffLine・PlateauTop・Lowland を変えたら、C# の DioramaTerrain も同じに直す (中を歩くときの地面になる)

            // 崖の面が、x の所で z のどこにあるか。滝つぼを囲むように左右が手前へ回り込み、真ん中 (滝の所) は奥へえぐれる
            float CliffLine(float x)
            {
                return -0.15 + 0.9 * x * x - 0.035 * exp(-(x * x) / (0.06 * 0.06)) + 0.012 * sin(x * 17.0 + _Seed);
            }

            // 崖の上の台地の高さ。奥ほど少し高く、真ん中には滝へ流れ込む溝がある
            float PlateauTop(float2 xz)
            {
                float top = 0.2 + 0.03 * Fbm3(xz * 6.0 + _Seed) - xz.y * 0.1;
                top -= 0.025 * exp(-(xz.x * xz.x) / (0.03 * 0.03));
                return top;
            }

            // 崖の下の低い土地: 滝つぼの湖と、それを囲む岸
            float Lowland(float2 xz)
            {
                float2 q = (xz - POOL) * float2(1.0, 1.3);
                float r = length(q);
                float h = -0.30 + 0.18 * smoothstep(0.06, 0.28, r);
                h += 0.012 * Fbm3(xz * 14.0 + _Seed) - 0.006;
                float rid = 1.0 - abs(ValueNoise(xz * 38.0 + _Seed * 1.7) * 2.0 - 1.0);
                float rid2 = 1.0 - abs(ValueNoise(xz * 81.0 + _Seed * 2.3 + 7.0) * 2.0 - 1.0);
                h += (0.006 * rid * rid + 0.0025 * rid2 * rid2) * smoothstep(WATER - 0.02, WATER + 0.04, h);
                return h;
            }

            // 崖と台地のかたまり (奥行きの距離)。崖の面には、柱状節理の縦の筋と、ごつごつした凹凸
            float Cliff(float3 p)
            {
                float face = p.z - CliffLine(p.x);                       // 負なら崖の中
                face -= 0.004 * abs(sin(p.x * 140.0 + Fbm3(float2(p.x * 20.0, p.y * 6.0)) * 3.0)); // 縦の柱
                face -= 0.008 * Fbm3(float2(p.x * 25.0, p.y * 25.0) + _Seed);
                float top = p.y - PlateauTop(p.xz);
                return max(face * 0.45, top * 0.7);
            }

            // 歩くときの地面の高さに近いもの (崖の向こうは台地の上)
            float Height(float2 xz)
            {
                float h = Lowland(xz);
                if (xz.y < CliffLine(xz.x)) h = max(h, PlateauTop(xz));
                return h;
            }

            // ---------------------------------------------------------------- 滝の形

            // 滝の落ち口 (崖の切れ込みの、台地の溝の縁)
            float LipZ() { return CliffLine(0.0); }
            float LipY() { return PlateauTop(float2(0.0, LipZ())); }

            // 高さ y の所の、滝の中心の z (落ち口から少し前へ飛び出してから、まっすぐ落ちる) と、幅の半分
            float FallZ(float y, float lipZ, float lipY)
            {
                float k = saturate((lipY - y) / (lipY - WATER));
                return lipZ + 0.008 + 0.025 * sqrt(k);
            }

            float FallWidth(float y, float lipY)
            {
                float k = saturate((lipY - y) / (lipY - WATER));
                return (0.022 + 0.022 * k) * (1.0 + 0.8 * _Event);
            }

            float3 FallColor(float k) // k: 落ち口 0 → 滝つぼ 1
            {
                return lerp(float3(0.7, 1.05, 3.2), float3(0.15, 0.35, 2.0), k);
            }

            // ---------------------------------------------------------------- 燃える硫黄 (台地の川・湖の炎)

            // 湖の炎がどこまで広がったか (滝つぼからの距離)。ふだんは滝つぼのまわりだけ
            float LakeFireRadius()
            {
                float grow = _Event > 0.001 ? saturate((_EventTime - 1.0) / 5.0) : 0.0;
                return lerp(0.035, 0.26, grow * saturate(_Event * 1.5));
            }

            // 台地の溝を、滝へ向かって流れる青い炎の川 (x = 強さ、y = ゆらめき)
            float2 ChannelAt(float2 xz, float lipZ, float widthScale)
            {
                float w = 0.012 * (1.0 + 0.6 * _Event) * widthScale;
                float behind = lipZ - xz.y; // 落ち口からの奥行き
                float m = exp(-(xz.x * xz.x) / (w * w)) * smoothstep(-0.004, 0.004, behind) * smoothstep(0.3, 0.2, behind);
                float flame = ValueNoise(float2(behind * 200.0 + _Time.y * 3.0, xz.x * 150.0));
                return float2(m, flame);
            }

            // 湖の表面で燃える炎の明るさ
            float3 LakeFire(float2 xz, float2 impact)
            {
                float d = length(xz - impact);
                float R = LakeFireRadius();
                float edge = smoothstep(R, R - 0.03, d);
                float crawl = Noise3(float3(xz * 70.0, _Time.y * 1.5)) * Noise3(float3(xz * 160.0 + 3.0, _Time.y * 3.0));
                return float3(0.2, 0.45, 2.2) * edge * (0.25 + 1.8 * crawl) * (0.5 + _Event);
            }

            // ---------------------------------------------------------------- 世界の形

            float2 Map(float3 p)
            {
                float2 res = float2(SdBox(p - float3(0, -0.46, 0), float3(0.5, 0.04, 0.5)), ID_BASE);
                float column = SdBox(p - float3(0, 0.04, 0), float3(INNER, 0.46, INNER));
                float low = max((p.y - Lowland(p.xz)) * 0.5, column);
                float cliff = max(Cliff(p), column);
                float ground = min(low, cliff);
                if (ground < res.x) res = float2(ground, ID_GROUND);
                float water = max(p.y - WATER, column);
                if (water < res.x) res = float2(water, ID_WATER);
                return res;
            }

            float3 SceneNormal(float3 p)
            {
                const float2 e = float2(0.0009, -0.0009);
                return normalize(e.xyy * Map(p + e.xyy).x + e.yyx * Map(p + e.yyx).x +
                                 e.yxy * Map(p + e.yxy).x + e.xxx * Map(p + e.xxx).x);
            }

            float SoftShadow(float3 p, float3 l)
            {
                float res = 1.0;
                float t = 0.006;
                int n = (int)_ShadowSteps;
                for (int i = 0; i < 32; i++)
                {
                    if (i >= n) break;
                    float h = Map(p + l * t).x;
                    res = min(res, 10.0 * h / t);
                    t += clamp(h, 0.004, 0.05);
                    if (res < 0.01 || t > 1.0) break;
                }
                return saturate(res);
            }

            // くぼみの暗がり: 法線の方向へ少しずつ離れながら、まわりの地形の近さを調べる
            float AmbientOcclusion(float3 p, float3 n)
            {
                float occ = 0.0;
                float w = 1.0;
                for (int i = 1; i <= 4; i++)
                {
                    float d = 0.012 * i;
                    occ += (d - Map(p + n * d).x) * w;
                    w *= 0.6;
                }
                return saturate(1.0 - occ * 14.0);
            }

            // ---------------------------------------------------------------- 青い炎の滝 (立体)

            // 滝のまわりの箱の中を前から順に進み、滝の光を足していく (炎は自分で光り、後ろを隠さない)
            float3 Waterfall(float3 ro, float3 rd, float tMax, float lipZ, float lipY)
            {
                float3 bmin = float3(-0.1, WATER - 0.005, lipZ - 0.01);
                float3 bmax = float3(0.1, lipY + 0.015, lipZ + 0.075);
                float3 inv = 1.0 / rd;
                float3 t0 = (bmin - ro) * inv, t1 = (bmax - ro) * inv;
                float3 tsmall = min(t0, t1), tbig = max(t0, t1);
                float tin = max(max(max(tsmall.x, tsmall.y), tsmall.z), 0.0);
                float tout = min(min(min(tbig.x, tbig.y), tbig.z), tMax);
                if (tout <= tin) return 0;

                const int steps = 40;
                float dt = (tout - tin) / steps;
                float t = tin + dt * Hash21(rd.xy * 391.0 + _Time.y);
                float time = _Time.y;
                float3 col = 0;
                for (int s = 0; s < steps; s++)
                {
                    float3 p = ro + rd * t;
                    float k = saturate((lipY - p.y) / (lipY - WATER));
                    // 縁は細かくちぎれて、しずくになって散る
                    float fray = Noise3(float3(p.x * 60.0, p.y * 30.0 + time * 6.0, 0.0));
                    float w = FallWidth(p.y, lipY) * (0.8 + 0.4 * fray);
                    float thick = 0.006 + 0.012 * k;
                    float fx = saturate(1.0 - abs(p.x) / w);
                    float fz = saturate(1.0 - abs(p.z - FallZ(p.y, lipZ, lipY)) / thick);
                    float f = sqrt(fx) * fz;
                    if (f > 0.0 && p.y < lipY + 0.005)
                    {
                        // 縦の筋が、勢いよく下へ流れる
                        float streak = Noise3(float3(p.x * 150.0, p.y * 10.0 + time * 4.0, p.z * 60.0));
                        float e = f * (0.35 + 1.3 * streak * streak);
                        col += FallColor(k) * e * dt * 250.0 * (1.0 + 0.6 * _Event);
                    }
                    t += dt;
                }
                return col;
            }

            // 湖の上で燃える炎の舌 (仕掛けの最中だけ)。湖の面のすぐ上の薄い層を進んで、光を足していく
            float3 LakeFlames(float3 ro, float3 rd, float tMax, float2 impact)
            {
                float R = LakeFireRadius();
                if (_Event < 0.01) return 0;
                float3 bmin = float3(impact.x - R, WATER, impact.y - R);
                float3 bmax = float3(impact.x + R, WATER + 0.05, impact.y + R);
                float3 inv = 1.0 / rd;
                float3 t0 = (bmin - ro) * inv, t1 = (bmax - ro) * inv;
                float3 tsmall = min(t0, t1), tbig = max(t0, t1);
                float tin = max(max(max(tsmall.x, tsmall.y), tsmall.z), 0.0);
                float tout = min(min(min(tbig.x, tbig.y), tbig.z), tMax);
                if (tout <= tin) return 0;

                const int steps = 28;
                float dt = (tout - tin) / steps;
                float t = tin + dt * Hash21(rd.zy * 271.0 + _Time.y);
                float3 col = 0;
                for (int s = 0; s < steps; s++)
                {
                    float3 p = ro + rd * t;
                    float d = length(p.xz - impact);
                    float y = p.y - WATER;
                    float hf = 0.04 * _Event * Noise3(float3(p.x * 60.0, _Time.y * 1.5, p.z * 60.0)) * smoothstep(R, R - 0.04, d);
                    if (y < hf)
                    {
                        float k = y / max(hf, 0.0001);
                        float n = Noise3(float3(p.x * 220.0, y * 200.0 - _Time.y * 8.0, p.z * 220.0));
                        col += lerp(float3(0.5, 0.85, 3.0), float3(0.1, 0.25, 1.6), k) * (1.0 - k) * (0.4 + n) * dt * 120.0;
                    }
                    t += dt;
                }
                return col;
            }

            // ---------------------------------------------------------------- 崖の割れ目の炎

            // 炎 i 番の根元 (崖の面のすぐ前) と、炎の高さ (w)
            float4 JetAt(int i)
            {
                float fi = i;
                float x = (fi - 2.0) * 0.12 + (Hash11(fi + _Seed) - 0.5) * 0.06;
                x += x > -0.03 && x < 0.03 ? 0.08 : 0.0;          // 滝の真ん中は避ける
                float y = lerp(-0.1, 0.12, Hash11(fi * 4.1 + 2.0));
                float z = CliffLine(x) + 0.006;
                float flick = Noise3(float3(fi * 7.1, _Time.y * 4.0, 0.0));
                float height = (0.014 + 0.01 * flick) * (1.0 + 1.5 * _Event);
                return float4(x, y, z, height);
            }

            // 炎の柱に一番近づく所の距離から、ぼんやり光る炎の舌として足す
            float3 Jets(float3 ro, float3 rd, float tMax)
            {
                float3 col = 0;
                for (int i = 0; i < JETS; i++)
                {
                    float4 j = JetAt(i);
                    // 線と、根元から上へのびる縦の線分との、一番近い所
                    float3 a = j.xyz;
                    float3 w0 = ro - a;
                    float b = dot(rd, float3(0, 1, 0));
                    float dd = dot(rd, w0);
                    float e = w0.y;
                    float den = 1.0 - b * b;
                    float sc = den > 0.0001 ? (b * e - dd) / den : 0.0; // 線の上の位置
                    float tcv = clamp(den > 0.0001 ? (e - b * dd) / den : 0.0, 0.0, j.w); // 炎の上の位置
                    if (sc < 0.0 || sc > tMax) continue;
                    float3 diff = (ro + rd * sc) - (a + float3(0, tcv, 0));
                    float k = tcv / j.w;
                    float rad = 0.004 * pow(1.0 - k, 0.5) + 0.001;
                    float glow = exp(-dot(diff, diff) / (rad * rad));
                    float n = Noise3(float3(i * 3.3, k * 6.0 - _Time.y * 7.0, 0.0));
                    col += lerp(float3(0.6, 0.95, 3.0), float3(0.1, 0.25, 1.6), k) * glow * (1.0 - k * 0.7) * (0.6 + 0.8 * n) * 1.2;
                }
                return col;
            }

            // ---------------------------------------------------------------- 湯気と、湖の上のもや

            float FumeDensity(float3 p, float2 impact)
            {
                float t = _Time.y;
                float dens = 0.0;
                // 滝つぼから立ちのぼる湯気。少し右へ流れ、崖の上を越えていく
                float y = p.y - WATER;
                if (y > 0.0 && y < 0.36)
                {
                    float2 q = p.xz - impact;
                    q.x -= y * 0.3 + y * y * 1.2;
                    q.y += y * 0.15;
                    float rad = 0.03 + y * 0.4;
                    float shape = saturate(1.0 - length(q) / rad) * smoothstep(0.36, 0.12, y);
                    if (shape > 0.0)
                    {
                        float3 np = float3(q.x, y - t * 0.04, q.y) * 22.0;
                        float n = Noise3(np) * 0.55 + Noise3(np * 2.1 + 5.3) * 0.3 + Noise3(np * 4.3 + 9.1) * 0.15;
                        dens = max(0.0, shape * 1.2 + n * 0.9 - 0.97) * 30.0 * (1.0 + 0.8 * _Event);
                    }
                }
                // 湖の上をはう、うすいもや
                if (y > 0.0 && y < 0.025 && length((p.xz - POOL) * float2(1.0, 1.3)) < 0.22)
                {
                    float m = smoothstep(0.025, 0.0, y) * Noise3(float3(p.x * 30.0 + t * 0.02, y * 60.0, p.z * 30.0));
                    dens += m * 4.0;
                }
                return dens;
            }

            float4 Fumes(float3 ro, float3 rd, float tMax, float2 impact, float3 fallLight)
            {
                float3 bmin = float3(-INNER, WATER, -INNER);
                float3 bmax = float3(INNER, WATER + 0.37, INNER);
                float3 inv = 1.0 / rd;
                float3 t0 = (bmin - ro) * inv, t1 = (bmax - ro) * inv;
                float3 tsmall = min(t0, t1), tbig = max(t0, t1);
                float tin = max(max(max(tsmall.x, tsmall.y), tsmall.z), 0.0);
                float tout = min(min(min(tbig.x, tbig.y), tbig.z), tMax);
                if (tout <= tin) return float4(0, 0, 0, 1);

                int steps = clamp((int)(_Steps / 5.0), 10, 36);
                float dt = (tout - tin) / steps;
                float t = tin + dt * Hash21(rd.xy * 517.0 + _Time.y);
                float3 col = 0;
                float trans = 1.0;
                float3 impact3 = float3(impact.x, WATER + 0.02, impact.y);
                for (int i = 0; i < 36; i++)
                {
                    if (i >= steps) break;
                    float3 p = ro + rd * t;
                    float dens = FumeDensity(p, impact);
                    if (dens > 0.0)
                    {
                        float3 moonLit = float3(0.07, 0.075, 0.085);
                        float3 fireLit = fallLight * exp(-length(p - impact3) * 9.0);
                        float a = 1.0 - exp(-dens * dt);
                        col += trans * a * (moonLit + fireLit);
                        trans *= 1.0 - a;
                        if (trans < 0.02) break;
                    }
                    t += dt;
                }
                return float4(col, trans);
            }

            // ---------------------------------------------------------------- 空

            float3 Sky(float3 rd)
            {
                float up = saturate(rd.y);
                float3 c = lerp(float3(0.012, 0.016, 0.03), float3(0.002, 0.004, 0.012), sqrt(up));
                // 天の川: 空を斜めに横切る、淡い光の帯
                float3 axis = normalize(float3(0.3, 0.5, 0.8));
                float bandD = dot(rd, axis) / 0.2;
                float band = exp(-bandD * bandD) * (0.5 + 0.8 * Noise3(rd * 9.0)) * smoothstep(0.0, 0.25, rd.y);
                c += float3(0.05, 0.05, 0.07) * band;
                // 星: 天の川の中ほど多い
                float3 sp = rd * 220.0;
                float3 cell = floor(sp);
                float3 f = frac(sp) - 0.5;
                float star = step(0.993 - band * 0.015, Hash31(cell)) * smoothstep(0.25, 0.1, length(f));
                c += star * lerp(float3(0.7, 0.8, 1.0), float3(1.0, 0.9, 0.7), Hash31(cell + 3.0)) * smoothstep(0.02, 0.2, rd.y);
                // 月
                float3 md = normalize(MOON_DIR);
                float mc = dot(rd, md);
                c += float3(1.5, 1.45, 1.3) * smoothstep(0.99965, 0.9998, mc);
                c += float3(0.4, 0.45, 0.6) * (pow(saturate(mc), 400.0) * 0.2 + pow(saturate(mc), 30.0) * 0.03);
                return c;
            }

            // ---------------------------------------------------------------- 湖の映り込み

            // 湖面で反射した線を、地形だけを相手にもう一度進める。崖が当たれば暗い岩肌と滝の光、当たらなければ空。
            // 滝そのものは、滝のある面と交わる所を調べて、滝の幅の中なら滝の色を足す
            float3 Reflection(float3 p, float3 r, float lipZ, float lipY, float3 fallLight)
            {
                float3 c = 0;
                bool hit = false;
                float t = 0.004;
                for (int i = 0; i < 40; i++)
                {
                    float3 q = p + r * t;
                    if (abs(q.x) > INNER || abs(q.z) > INNER || q.y > 0.5) break;
                    float d = min((q.y - Lowland(q.xz)) * 0.5, Cliff(q));
                    if (d < 0.0006)
                    {
                        float3 toF = float3(0.0, (lipY + WATER) * 0.5, lipZ + 0.02) - q;
                        c = float3(0.01, 0.011, 0.013) + fallLight * 0.08 / (1.0 + dot(toF, toF) * 60.0);
                        hit = true;
                        break;
                    }
                    t += max(d, 0.002);
                }
                if (!hit) c = Sky(r);
                // 滝の映り込み
                float fz = lipZ + 0.025;
                if (r.z < -0.001)
                {
                    float tf = (fz - p.z) / r.z;
                    float3 q = p + r * tf;
                    if (tf > 0.0 && (!hit || tf < t) && q.y < lipY && abs(q.x) < FallWidth(q.y, lipY))
                    {
                        float k = saturate((lipY - q.y) / (lipY - WATER));
                        float streak = Noise3(float3(q.x * 150.0, q.y * 10.0 + _Time.y * 4.0, 0.0));
                        c += FallColor(k) * (0.4 + streak) * 0.7;
                    }
                }
                return c;
            }

            // ---------------------------------------------------------------- 色を塗る

            float3 Shade(float3 ro, float3 rd, float3 p, float id, bool crossSection, float3 faceNormal,
                         float lipZ, float lipY, float2 impact, float3 fallLight)
            {
                float3 moonDir = normalize(MOON_DIR);
                float3 moonCol = float3(0.28, 0.33, 0.48);
                float3 skyAmb = float3(0.012, 0.015, 0.028);

                if (id == ID_BASE)
                    return float3(0.015, 0.014, 0.014) + 0.03 * pow(saturate(dot(reflect(rd, faceNormal), moonDir)), 8.0);

                if (crossSection && id == ID_GROUND)
                {
                    // 断面: 玄武岩の溶岩が何枚も重なった層
                    float band = 0.5 + 0.5 * sin(p.y * 120.0 + ValueNoise(p.xz * 40.0 + p.y * 30.0) * 4.0);
                    return lerp(float3(0.04, 0.038, 0.04), float3(0.1, 0.09, 0.085), band) * 0.25;
                }
                if (crossSection && id == ID_WATER)
                {
                    float depth = WATER - p.y;
                    return lerp(float3(0.03, 0.1, 0.095), float3(0.006, 0.025, 0.03), saturate(depth * 8.0));
                }

                // 滝の光: 滝の中心を通る縦の線分からの距離で弱まる
                float3 fallMid = float3(0.0, clamp(p.y, WATER, lipY), lipZ + 0.02);
                float3 toFall = fallMid - p;
                float fallAtten = 1.0 / (1.0 + dot(toFall, toFall) * 120.0);
                // 湖の炎の光 (仕掛けの最中)
                float3 toLake = float3(impact.x, WATER + 0.02, impact.y) - p;
                float lakeAtten = LakeFireRadius() * 8.0 / (1.0 + dot(toLake, toLake) * 40.0) * _Event;

                if (id == ID_WATER)
                {
                    // 酸の湖: 乳白色のターコイズ。さざ波で向きを揺らし、崖と青い滝を映す
                    float t = _Time.y;
                    float2 q = p.xz * 80.0;
                    float dImpact = length(p.xz - impact);
                    float choppy = 0.12 + 0.5 * exp(-dImpact * 25.0); // 滝つぼの近くは波立つ
                    float3 n = normalize(float3((ValueNoise(q + t * 0.8) - 0.5) * choppy, 1.0, (ValueNoise(q.yx * 1.3 - t * 0.9) - 0.5) * choppy));
                    float3 rv = reflect(rd, n);
                    float fres = 0.02 + 0.98 * pow(1.0 - saturate(dot(-rd, n)), 5.0);
                    float3 refl = Reflection(p, rv, lipZ, lipY, fallLight);
                    float depth = WATER - Lowland(p.xz);
                    float3 body = float3(0.02, 0.085, 0.08) * (0.4 + 0.6 * saturate(dot(n, moonDir)));
                    body += float3(0.05, 0.16, 0.4) * fallLight.b * fallAtten * 0.5;   // 滝の光が、濁った水の中に広がる
                    body = lerp(float3(0.06, 0.13, 0.11), body, saturate(depth * 30.0)); // 岸近くの浅い所は明るい
                    float3 c = lerp(body, refl, fres);
                    c += moonCol * pow(saturate(dot(rv, moonDir)), 200.0) * 2.0;
                    // 滝つぼの白い泡と、岸の黄白い泡
                    float cr = (dImpact - 0.02) / 0.02;
                    float churn = exp(-cr * cr) * (0.5 + 0.5 * Noise3(float3(p.xz * 120.0, t * 3.0)));
                    c += churn * (float3(0.1, 0.14, 0.2) + fallLight * 0.08);
                    float foam = smoothstep(0.01, 0.0, depth) * (0.5 + 0.5 * sin(t * 1.5 - depth * 500.0 + ValueNoise(p.xz * 90.0) * 4.0));
                    c += foam * float3(0.06, 0.06, 0.035);
                    // 湖の上で燃える炎
                    c += LakeFire(p.xz, impact);
                    return c;
                }

                // 地面 (岸と崖と台地)
                float3 n = SceneNormal(p);
                float sh = SoftShadow(p + n * 0.002, moonDir);
                float ao = AmbientOcclusion(p, n);
                float slope = 1.0 - n.y;

                // 黒い玄武岩。崖の面は縦の筋がわかるよう、少しだけ明るさにむらをつける
                float3 albedo = lerp(float3(0.035, 0.034, 0.036), float3(0.08, 0.075, 0.072), Fbm3(p.xz * 30.0 + p.y * 20.0));
                // 台地の上と岸のなだらかな所には、まばらな草
                float level = smoothstep(0.35, 0.15, slope);
                float grass = level * smoothstep(WATER + 0.03, WATER + 0.08, p.y) * (p.y > 0.1 ? 1.0 : 0.5);
                albedo = lerp(albedo, float3(0.02, 0.035, 0.022) * (0.7 + 0.6 * ValueNoise(p.xz * 50.0)), grass * 0.7);
                // 硫黄の結晶: 割れ目の炎のまわりと、滝つぼのまわりの岸
                float sd = length(p.xz - impact) * 0.6;
                for (int i = 0; i < JETS; i++)
                {
                    float4 j = JetAt(i);
                    sd = min(sd, length(p - j.xyz) * 1.4);
                }
                float sulfur = exp(-sd * sd / (0.035 * 0.035)) * (0.5 + 0.5 * ValueNoise(p.xz * 120.0 + p.y * 80.0));
                albedo = lerp(albedo, float3(0.34, 0.28, 0.03), saturate(sulfur * 1.3));
                // 湖の水位が上下した跡: 岸の少し上に、白っぽい帯
                float ring = (p.y - WATER - 0.012) / 0.008;
                albedo = lerp(albedo, float3(0.13, 0.12, 0.09), exp(-ring * ring) * 0.6 * level);

                float3 c = albedo * (moonCol * saturate(dot(n, moonDir)) * sh + skyAmb * (0.5 + 0.5 * n.y)) * ao;
                c += albedo * fallLight * fallAtten * saturate(dot(n, normalize(toFall)) * 0.6 + 0.4) * 3.0;
                c += albedo * float3(0.2, 0.45, 2.0) * lakeAtten * saturate(dot(n, normalize(toLake)) * 0.6 + 0.4);
                // 台地の溝を流れる、燃える硫黄の川と、そのまわりの照り返し
                float2 river = ChannelAt(p.xz, lipZ, 1.0);
                float2 riverGlow = ChannelAt(p.xz, lipZ, 4.0);
                float onTop = smoothstep(lipY - 0.03, lipY - 0.01, p.y);
                c += float3(0.25, 0.55, 2.6) * river.x * (0.55 + 0.7 * river.y) * (1.0 + _Event) * onTop;
                c += albedo * float3(0.3, 0.6, 2.0) * riverGlow.x * onTop;
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
                float t = max(box.x, 0.0);

                float3 entry = ro + rd * t;
                float3 ae = abs(entry);
                float3 faceNormal = ae.x > ae.y && ae.x > ae.z ? float3(sign(entry.x), 0, 0)
                                  : (ae.y > ae.z ? float3(0, sign(entry.y), 0) : float3(0, 0, sign(entry.z)));

                // 地形より上の何もない空間は飛ばす (滝・炎・湯気は別に計算する)
                const float maxHeight = 0.3;
                if (ro.y > maxHeight && rd.y < 0.0) t = max(t, (maxHeight - ro.y) / rd.y);

                bool hit = false;
                float id = 0.0;
                int steps = (int)_Steps;
                for (int i = 0; i < 200; i++)
                {
                    if (i >= steps || t > box.y) break;
                    float2 m = Map(ro + rd * t);
                    if (m.x < 0.0003 * (1.0 + t))
                    {
                        hit = true;
                        id = m.y;
                        break;
                    }
                    t += m.x;
                }
                float tHit = hit ? t : box.y;

                // 滝の落ち口と、滝つぼ (滝が湖に落ちる所)
                float lipZ = LipZ();
                float lipY = LipY();
                float2 impact = float2(0.0, FallZ(WATER, lipZ, lipY));
                float flicker = 0.85 + 0.15 * sin(_Time.y * 11.0) * sin(_Time.y * 6.7);
                float3 fallLight = float3(0.25, 0.5, 1.6) * (0.7 + 1.8 * _Event) * flicker;

                float3 col = 0;
                if (hit)
                {
                    float3 p = ro + rd * t;
                    bool crossSection = outside && (abs(p.x) > INNER - 0.002 || abs(p.z) > INNER - 0.002);
                    col = Shade(ro, rd, p, id, crossSection, faceNormal, lipZ, lipY, impact, fallLight);
                }
                else if (!outside)
                {
                    col = Sky(rd); // 中に入っているときだけ、空を描く
                }

                // 霞: 線がケースの中を進んだ距離が長いほど、夜の空気の色に沈める
                float travel = tHit - max(box.x, 0.0);
                float3 haze = float3(0.01, 0.014, 0.025) + float3(0.0, 0.01, 0.04) * _Event;
                if (hit) col = lerp(col, haze, 1.0 - exp(-travel * 0.45));
                else if (!outside) col = lerp(col, haze, (1.0 - exp(-travel * 0.45)) * 0.3);

                // 不透明度。外から見た空の所は 0 (透明) から始めて、湯気が濃いほど不透明にする
                float alpha = (hit || !outside) ? 1.0 : 0.0;

                // 湯気を重ね、滝・湖の炎・割れ目の炎の光を足す (色は不透明度を掛けた形で持つ)
                float4 fumes = Fumes(ro, rd, tHit, impact, fallLight);
                col = col * fumes.a + fumes.rgb;
                alpha = 1.0 - (1.0 - alpha) * fumes.a;
                col += Waterfall(ro, rd, tHit, lipZ, lipY);
                col += LakeFlames(ro, rd, tHit, impact);
                col += Jets(ro, rd, tHit);

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

                // ほぼ透明で光もない所は描かない (奥にある部屋の火の粉などを隠さないように、奥行きも書かない)
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
