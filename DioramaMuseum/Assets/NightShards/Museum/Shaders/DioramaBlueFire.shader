// 作品「青い火の火口湖」(火の間)。夜の火山の火口と、その底の湖。URP 用。
// Cube の中をレイマーチングして描く。Cube の座標は -0.5〜0.5、下の 0.08 は黒い台。
// モデル: インドネシアのイジェン火山 (硫黄のガスが燃えて、青い炎が夜に光る)
//
// 見どころ:
//   ・切り立った火口の壁と、その底に広がる乳白色のターコイズの酸の湖
//   ・奥の壁の噴気孔で燃える、青い炎 (立体的な炎として計算)。まわりには黄色い硫黄の結晶
//   ・噴気孔から立ちのぼり、火口の上をたなびく硫黄の煙。下から青い炎に照らされる
//   ・火口の壁のつづら折りの道を、ヘッドランプの小さな灯りがゆっくり下りていく (硫黄を運ぶ人たち)
//   ・空いっぱいの星と天の川
// 仕掛け (_Event 0〜1): ガスに火が回る。青い炎が高く燃え上がり、燃える硫黄が青い川になって壁を流れ下り、湖の上に広がる
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
            #define NOTCH -0.6      // 火口の縁が低くなっている所の向き (道の入口)
            #define VENT_TH -2.0    // 噴気孔が並ぶ向き (奥の左の壁)
            #define VENTS 5
            #define LAMPS 6
            static const float3 MOON_DIR = float3(0.55, 0.5, -0.65); // 正規化は使う所で

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

            // 2 つの向き (ラジアン) の差。-π と π の境目をまたいでも正しく測る
            float AngDist(float a, float b) { return abs(atan2(sin(a - b), cos(a - b))); }

            // ---------------------------------------------------------------- 地形

            // 火口の縁が、中心からどれだけ離れているか (向きによって少しでこぼこ)
            float RimRadius(float th)
            {
                return 0.3 + 0.025 * sin(th * 3.0 + _Seed) + 0.015 * sin(th * 5.0 + _Seed * 1.3);
            }

            float Height(float2 xz)
            {
                float r = length(xz);
                float th = atan2(xz.y, xz.x);
                float2 dir = xz / max(r, 0.0001);
                float rim = RimRadius(th);
                // 縁の高さ。向きによって高い所・低い所があり、道の入口の所は低くえぐれている
                float rimH = 0.13 + 0.06 * (Fbm3(dir * 1.5 + _Seed) - 0.45);
                float nd = AngDist(th, NOTCH) / 0.3;
                rimH -= 0.07 * exp(-nd * nd);
                // 縁の内側: 湖の底から縁まで、切り立った壁で立ち上がる
                float s = saturate((r - 0.08) / (rim - 0.08));
                s = s * s * (3.0 - 2.0 * s);
                float inner = -0.30 + (rimH + 0.30) * pow(s, 1.6);
                // 縁の外側: なだらかに下る山すそ
                float od = (r - rim) / 0.16;
                float outer = -0.13 + (rimH + 0.13) * exp(-od * od);
                float h = r < rim ? inner : outer;
                // 内側の壁を、雨が縦に削った溝
                float wall = smoothstep(0.12, 0.22, r) * smoothstep(rim + 0.06, rim - 0.02, r);
                float gully = 1.0 - abs(sin(th * 14.0 + Fbm3(xz * 9.0 + _Seed) * 3.0));
                h += 0.014 * gully * gully * wall;
                // 細かい起伏
                h += 0.012 * Fbm3(xz * 14.0 + _Seed) - 0.006;
                // 岩肌の細かい尾根 (水の上だけ)
                float rid = 1.0 - abs(ValueNoise(xz * 38.0 + _Seed * 1.7) * 2.0 - 1.0);
                float rid2 = 1.0 - abs(ValueNoise(xz * 81.0 + _Seed * 2.3 + 7.0) * 2.0 - 1.0);
                h += (0.006 * rid * rid + 0.0025 * rid2 * rid2) * smoothstep(WATER - 0.02, WATER + 0.04, h);
                // ※ この式を変えたら、C# の DioramaTerrain.BlueFireHeight も同じに直す (中を歩くときの地面になる)
                return h;
            }

            // ---------------------------------------------------------------- 噴気孔と、燃える硫黄の川

            // 噴気孔 i 番の向きと、中心からの距離
            float VentAngle(float fi) { return VENT_TH + (fi - 2.0) * 0.12 + (Hash11(fi + _Seed) - 0.5) * 0.05; }
            float VentRadius(float fi) { return 0.235 + 0.03 * Hash11(fi * 3.3 + 1.0); }

            // 噴気孔の場所 (xyz) と、炎のゆらぎ (w)
            void GetVents(out float4 vents[VENTS])
            {
                for (int i = 0; i < VENTS; i++)
                {
                    float fi = i;
                    float a = VentAngle(fi);
                    float2 xz = float2(cos(a), sin(a)) * VentRadius(fi);
                    float flick = Noise3(float3(fi * 7.1, _Time.y * 4.0, 0.0));
                    vents[i] = float4(xz.x, Height(xz), xz.y, flick);
                }
            }

            // 燃える硫黄の川 (青い炎の流れ)。噴気孔から湖のほうへ流れ下る。
            // x = どれだけ川の上か、y = 炎のゆらめき。widthScale を広げると、まわりの照り返しに使える
            float2 RiverAt(float2 xz, float widthScale)
            {
                float r = length(xz);
                float th = atan2(xz.y, xz.x);
                float best = 0.0;
                float along = 0.0;
                for (int i = 0; i < VENTS; i++)
                {
                    float fi = i;
                    float rv = VentRadius(fi);
                    float a = VentAngle(fi) + 0.03 * sin(r * 80.0 + fi * 2.0); // 少しくねる
                    float dist = rv - r;                                        // 噴気孔から湖のほうへ進んだ距離
                    // 火が回ると、川の先端がだんだん湖へ進み、湖の上に広がる
                    float grow = _Event > 0.001 ? saturate((_EventTime - 0.5 - fi * 0.4) / 4.0) : 0.0;
                    float reach = lerp(0.008 + 0.006 * Hash11(fi + 9.0), rv - 0.15, grow);
                    float onLake = max(0.0, dist - (rv - 0.2));
                    float w = (0.0025 + 0.0015 * Hash11(fi + 4.0)) * widthScale * (1.0 + onLake * 30.0);
                    float d = AngDist(th, a) * r;
                    float front = reach + (ValueNoise(float2(d / w * 1.5 + fi * 5.0, _Time.y * 0.5)) - 0.5) * 0.012;
                    float m = exp(-(d * d) / (w * w)) * smoothstep(-0.004, 0.002, dist) * smoothstep(front, front - 0.008, dist);
                    m *= lerp(1.0, saturate(_Event * 1.5), grow); // 火がおさまると、伸びた川から消えていく
                    if (m > best)
                    {
                        best = m;
                        along = dist;
                    }
                }
                float flame = ValueNoise(float2(along * 300.0 - _Time.y * 3.0, th * 40.0));
                return float2(best, flame);
            }

            float3 RiverColor(float2 river)
            {
                return float3(0.25, 0.55, 2.6) * river.x * (0.55 + 0.7 * river.y) * (1.0 + _Event);
            }

            // ---------------------------------------------------------------- 世界の形

            float2 Map(float3 p)
            {
                float2 res = float2(SdBox(p - float3(0, -0.46, 0), float3(0.5, 0.04, 0.5)), ID_BASE);
                float column = SdBox(p - float3(0, 0.04, 0), float3(INNER, 0.46, INNER));
                float h = Height(p.xz);
                float ground = max((p.y - h) * 0.5, column);
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

            // ---------------------------------------------------------------- 青い炎 (立体)

            float3 FlameColor(float k) // k: 炎の根元 0 → 先 1
            {
                return lerp(float3(0.7, 1.0, 3.2), float3(0.1, 0.25, 1.7), k);
            }

            // 噴気孔の上の炎を、線に沿って前から順に足していく (炎は自分で光り、後ろを隠さない)
            float3 Flames(float3 ro, float3 rd, float tMax, float4 vents[VENTS], float3 fireC)
            {
                float3 bmin = float3(fireC.x - 0.1, fireC.y - 0.04, fireC.z - 0.1);
                float3 bmax = float3(fireC.x + 0.1, fireC.y + 0.14, fireC.z + 0.1);
                float3 inv = 1.0 / rd;
                float3 t0 = (bmin - ro) * inv, t1 = (bmax - ro) * inv;
                float3 tsmall = min(t0, t1), tbig = max(t0, t1);
                float tin = max(max(max(tsmall.x, tsmall.y), tsmall.z), 0.0);
                float tout = min(min(min(tbig.x, tbig.y), tbig.z), tMax);
                if (tout <= tin) return 0;

                const int steps = 32;
                float dt = (tout - tin) / steps;
                float t = tin + dt * Hash21(rd.xy * 391.0 + _Time.y);
                float3 col = 0;
                for (int s = 0; s < steps; s++)
                {
                    float3 p = ro + rd * t;
                    for (int i = 0; i < VENTS; i++)
                    {
                        float3 q = p - vents[i].xyz;
                        float height = (0.016 + 0.012 * vents[i].w) * (1.0 + 3.5 * _Event);
                        if (q.y < 0.0 || q.y > height) continue;
                        float k = q.y / height;
                        // 炎は上へ行くほど細く、風と熱でゆらゆら揺れる
                        float3 wp = float3(i * 3.1, q.y * 60.0 - _Time.y * 6.0, 0.0);
                        q.xz += (float2(Noise3(wp), Noise3(wp + 7.7)) - 0.5) * 0.012 * k * (1.0 + _Event);
                        float rad = 0.006 * (1.0 + 0.8 * _Event) * pow(1.0 - k, 0.6) + 0.0015;
                        float f = saturate(1.0 - length(q.xz) / rad);
                        if (f <= 0.0) continue;
                        float n = Noise3(float3(q.x * 400.0, q.y * 250.0 - _Time.y * 8.0, q.z * 400.0));
                        col += FlameColor(k) * f * f * (0.6 + 0.8 * n) * (1.0 - k) * dt * 260.0 * (1.0 + 0.5 * _Event);
                    }
                    t += dt;
                }
                return col;
            }

            // ---------------------------------------------------------------- 硫黄の煙と、湖の上のもや

            // 煙の濃さ。噴気孔の上から立ちのぼり、風下 (+x) へたなびいて、火口の縁を越えていく
            float FumeDensity(float3 p, float3 fireC)
            {
                float t = _Time.y;
                float dens = 0.0;
                float y = p.y - fireC.y;
                if (y > -0.01 && y < 0.34)
                {
                    float2 q = p.xz - fireC.xz;
                    q.x -= y * 0.6 + y * y * 1.5;
                    q.y -= y * 0.25;
                    float rad = 0.03 + y * 0.45;
                    float shape = saturate(1.0 - length(q) / rad) * smoothstep(0.34, 0.12, y) * smoothstep(-0.01, 0.01, y);
                    if (shape > 0.0)
                    {
                        float3 np = float3(q.x, y - t * 0.03, q.y) * 20.0;
                        float n = Noise3(np) * 0.55 + Noise3(np * 2.1 + 5.3) * 0.3 + Noise3(np * 4.3 + 9.1) * 0.15;
                        dens = max(0.0, shape * 1.2 + n * 0.9 - 0.95) * 35.0 * (1.0 + _Event);
                    }
                }
                // 湖の上をはう、うすいもや
                float my = p.y - WATER;
                if (my > 0.0 && my < 0.025 && length(p.xz) < 0.21)
                {
                    float m = smoothstep(0.025, 0.0, my) * Noise3(float3(p.x * 30.0 + t * 0.02, my * 60.0, p.z * 30.0));
                    dens += m * 4.0;
                }
                return dens;
            }

            float4 Fumes(float3 ro, float3 rd, float tMax, float3 fireC, float fireGlow)
            {
                float3 bmin = float3(-INNER, WATER, -INNER);
                float3 bmax = float3(INNER, fireC.y + 0.35, INNER);
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
                // 火が回った瞬間、煙の中のガスが一気に青く光る
                float ignite = _Event > 0.001 ? exp(-_EventTime * 1.5) * 4.0 : 0.0;
                for (int i = 0; i < 36; i++)
                {
                    if (i >= steps) break;
                    float3 p = ro + rd * t;
                    float dens = FumeDensity(p, fireC);
                    if (dens > 0.0)
                    {
                        float3 moonLit = float3(0.075, 0.08, 0.075) + float3(0.04, 0.035, 0.0) * saturate(p.y * 4.0); // 上のほうは月に照らされて黄みがかる
                        float3 fireLit = float3(0.2, 0.45, 1.4) * (fireGlow + ignite) * exp(-length(p - fireC) * 14.0);
                        float a = 1.0 - exp(-dens * dt);
                        col += trans * a * (moonLit + fireLit);
                        trans *= 1.0 - a;
                        if (trans < 0.02) break;
                    }
                    t += dt;
                }
                return float4(col, trans);
            }

            // ---------------------------------------------------------------- ヘッドランプの灯り

            // 灯り i 番の場所。道の入口 (縁の低い所) から、つづら折りに噴気孔のほうへ下りていく
            float3 LampPos(int i)
            {
                float fi = i;
                float s = frac(fi / LAMPS + _Time.y * 0.005 + Hash11(fi * 1.9) * 0.08);
                float a = lerp(NOTCH, VENT_TH + 0.3, s);
                float zig = abs(frac(s * 6.0) - 0.5) * 4.0 - 1.0; // つづら折り: 行ったり来たり
                float r = lerp(RimRadius(NOTCH) - 0.01, 0.27, s) + 0.01 * zig;
                float2 xz = float2(cos(a), sin(a)) * r;
                return float3(xz.x, Height(xz) + 0.012, xz.y);
            }

            float3 Lamps(float3 ro, float3 rd, float tMax)
            {
                float3 col = 0;
                for (int i = 0; i < LAMPS; i++)
                {
                    float3 w = LampPos(i) - ro;
                    float tc = dot(w, rd);
                    if (tc < 0.0 || tc > tMax) continue;
                    float d2 = dot(w, w) - tc * tc;
                    float core = max(0.0009, tc * 0.0015); // 遠くからでも点として見えるように、距離に合わせて大きくする
                    float blink = 0.85 + 0.15 * sin(_Time.y * 2.0 + i * 1.7);
                    col += float3(1.0, 0.88, 0.7) * blink * (exp(-d2 / (core * core)) * 1.5 + exp(-d2 / (core * core * 25.0)) * 0.06);
                }
                return col;
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
                // 月: 小さく、低い所に
                float3 md = normalize(MOON_DIR);
                float mc = dot(rd, md);
                c += float3(1.5, 1.45, 1.3) * smoothstep(0.99965, 0.9998, mc);
                c += float3(0.4, 0.45, 0.6) * (pow(saturate(mc), 400.0) * 0.2 + pow(saturate(mc), 30.0) * 0.03);
                return c;
            }

            // ---------------------------------------------------------------- 湖の映り込み

            // 湖面で反射した線を、地形だけを相手にもう一度進める。壁が当たれば暗い岩肌と青い火の光、当たらなければ空
            float3 Reflection(float3 p, float3 r, float3 fireC, float3 fireCol)
            {
                float t = 0.004;
                for (int i = 0; i < 40; i++)
                {
                    float3 q = p + r * t;
                    if (abs(q.x) > INNER || abs(q.z) > INNER || q.y > 0.5) break;
                    float d = (q.y - Height(q.xz)) * 0.5;
                    if (d < 0.0006)
                    {
                        float3 toF = fireC - q;
                        float3 c = float3(0.01, 0.011, 0.013) + fireCol * 0.1 / (1.0 + dot(toF, toF) * 150.0);
                        return c + RiverColor(RiverAt(q.xz, 1.0)) * 0.7;
                    }
                    t += max(d, 0.002);
                }
                return Sky(r);
            }

            // ---------------------------------------------------------------- 色を塗る

            float3 Shade(float3 ro, float3 rd, float3 p, float id, bool crossSection, float3 faceNormal, float4 vents[VENTS], float3 fireC, float3 fireCol)
            {
                float3 moonDir = normalize(MOON_DIR);
                float3 moonCol = float3(0.3, 0.36, 0.5);
                float3 skyAmb = float3(0.012, 0.015, 0.028);
                float h = Height(p.xz);
                float r = length(p.xz);

                if (id == ID_BASE)
                    return float3(0.015, 0.014, 0.014) + 0.03 * pow(saturate(dot(reflect(rd, faceNormal), moonDir)), 8.0);

                if (crossSection && id == ID_GROUND)
                {
                    // 断面: 火山灰と溶岩が重なった地層
                    float band = 0.5 + 0.5 * sin(p.y * 120.0 + ValueNoise(p.xz * 40.0 + p.y * 30.0) * 4.0);
                    return lerp(float3(0.05, 0.045, 0.045), float3(0.12, 0.1, 0.085), band) * 0.25;
                }
                if (crossSection && id == ID_WATER)
                {
                    // 湖の断面: 白く濁った、ターコイズの水
                    float depth = WATER - p.y;
                    return lerp(float3(0.03, 0.1, 0.095), float3(0.006, 0.025, 0.03), saturate(depth * 8.0));
                }

                // 青い炎の光 (噴気孔のあたりから)
                float3 toFire = fireC + float3(0, 0.02, 0) - p;
                float fireAtten = 1.0 / (1.0 + dot(toFire, toFire) * 150.0);

                if (id == ID_WATER)
                {
                    // 酸の湖: 乳白色のターコイズ。さざ波で向きを揺らし、壁と青い火を映す
                    float t = _Time.y;
                    float2 q = p.xz * 80.0;
                    float3 n = normalize(float3((ValueNoise(q + t * 0.5) - 0.5) * 0.12, 1.0, (ValueNoise(q.yx * 1.3 - t * 0.6) - 0.5) * 0.12));
                    float3 rv = reflect(rd, n);
                    float fres = 0.02 + 0.98 * pow(1.0 - saturate(dot(-rd, n)), 5.0);
                    float3 refl = Reflection(p, rv, fireC, fireCol);
                    refl += fireCol * 1.5 * pow(saturate(dot(rv, normalize(toFire))), 60.0); // 青い炎が水面に映る筋
                    float depth = WATER - h;
                    float3 body = float3(0.02, 0.085, 0.08) * (0.4 + 0.6 * saturate(dot(n, moonDir))) + float3(0.04, 0.12, 0.35) * fireCol.b * fireAtten * 0.6;
                    body = lerp(float3(0.06, 0.13, 0.11), body, saturate(depth * 30.0)); // 岸近くの浅い所は明るい
                    float3 c = lerp(body, refl, fres);
                    c += moonCol * pow(saturate(dot(rv, moonDir)), 200.0) * 2.0;
                    // 岸の、硫黄で黄白く染まった泡
                    float foam = smoothstep(0.01, 0.0, depth) * (0.5 + 0.5 * sin(t * 1.5 - depth * 500.0 + ValueNoise(p.xz * 90.0) * 4.0));
                    c += foam * float3(0.06, 0.06, 0.035);
                    // 湖の上に広がった、燃える硫黄
                    c += RiverColor(RiverAt(p.xz, 1.0));
                    return c;
                }

                // 地面
                float3 n = SceneNormal(p);
                float sh = SoftShadow(p + n * 0.002, moonDir);
                float ao = AmbientOcclusion(p, n);
                float slope = 1.0 - n.y;
                float th = atan2(p.z, p.x);
                float rim = RimRadius(th);

                // 岩: 内側の壁には、火山灰と溶岩の層が横縞に見える
                float band = 0.5 + 0.5 * sin(p.y * 160.0 + ValueNoise(p.xz * 30.0) * 3.0);
                float3 albedo = lerp(float3(0.05, 0.047, 0.045), float3(0.1, 0.092, 0.085), band * 0.6 + Fbm3(p.xz * 30.0) * 0.4);
                // 外の山すそには、まばらな草木
                float vegetation = smoothstep(rim + 0.015, rim + 0.07, r) * (1.0 - smoothstep(0.4, 0.7, slope));
                albedo = lerp(albedo, float3(0.02, 0.04, 0.022) * (0.7 + 0.6 * ValueNoise(p.xz * 50.0)), vegetation * 0.85);
                // 噴気孔のまわりの、黄色い硫黄の結晶
                float sd = 1.0;
                for (int i = 0; i < VENTS; i++) sd = min(sd, length(p.xz - vents[i].xz));
                float sulfur = exp(-sd * sd / (0.03 * 0.03)) * (0.5 + 0.5 * ValueNoise(p.xz * 120.0));
                albedo = lerp(albedo, float3(0.34, 0.28, 0.03), saturate(sulfur * 1.3));
                // 湖の水位が上下した跡: 岸の少し上に、白っぽい帯
                float ring = (h - WATER - 0.012) / 0.008;
                albedo = lerp(albedo, float3(0.13, 0.12, 0.09), exp(-ring * ring) * 0.7);

                float3 c = albedo * (moonCol * saturate(dot(n, moonDir)) * sh + skyAmb * (0.5 + 0.5 * n.y)) * ao;
                c += albedo * fireCol * fireAtten * saturate(dot(n, normalize(toFire)) * 0.6 + 0.4) * 2.0;
                float2 glow = RiverAt(p.xz, 4.0);
                c += albedo * float3(0.3, 0.6, 2.0) * glow.x * (1.0 + _Event);      // 燃える川のまわりの照り返し
                c += RiverColor(RiverAt(p.xz, 1.0));                                  // 燃える川そのもの
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

                // 地形より上の何もない空間は飛ばす (炎と煙は別に計算する)
                const float maxHeight = 0.24;
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

                // 噴気孔と、青い炎の光の強さ (火が回ると強く、ゆらめく)
                float4 vents[VENTS];
                GetVents(vents);
                float3 fireC = 0;
                for (int v = 0; v < VENTS; v++) fireC += vents[v].xyz;
                fireC /= VENTS;
                float flicker = 0.8 + 0.2 * sin(_Time.y * 11.0) * sin(_Time.y * 6.7);
                float fireGlow = (0.5 + 2.5 * _Event) * flicker;
                float3 fireCol = float3(0.25, 0.5, 1.6) * fireGlow;

                float3 col = 0;
                if (hit)
                {
                    float3 p = ro + rd * t;
                    bool crossSection = outside && (abs(p.x) > INNER - 0.002 || abs(p.z) > INNER - 0.002);
                    col = Shade(ro, rd, p, id, crossSection, faceNormal, vents, fireC, fireCol);
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

                // 不透明度。外から見た空の所は 0 (透明) から始めて、煙が濃いほど不透明にする
                float alpha = (hit || !outside) ? 1.0 : 0.0;

                // 煙を重ね、青い炎とヘッドランプの光を足す (色は不透明度を掛けた形で持つ)
                float4 fumes = Fumes(ro, rd, tHit, fireC, fireGlow);
                col = col * fumes.a + fumes.rgb;
                alpha = 1.0 - (1.0 - alpha) * fumes.a;
                col += Flames(ro, rd, tHit, vents, fireC);
                col += Lamps(ro, rd, tHit);

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
