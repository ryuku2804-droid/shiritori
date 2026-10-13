// 作品「大噴火」(火の間)。夜の海に浮かぶ火山島。URP 用。
// Cube の中をレイマーチングして描く。Cube の座標は -0.5〜0.5、下の 0.08 は黒い台。
//
// 見どころ:
//   ・雨で削られた谷が放射状に走る火山の山肌と、火口の溶岩だまり
//   ・山腹を流れ下る溶岩 (表面は冷えて黒い皮、割れ目から赤く光る)。海に届くと湯気が立つ
//   ・火口から立ちのぼる噴煙 (立体的な雲として計算)。下から溶岩に赤く照らされ、中で火山雷が光る
//   ・夜の海: 波打ち際の白い泡、溶岩と噴煙の光を映す水面
// 仕掛け (_Event 0〜1): 大噴火。噴煙が一気に高くなり、溶岩が噴き上がり、流れが海まで届き、雷が増える
//
// _Steps / _ShadowSteps は DioramaLOD が距離で下げる。_Event / _EventTime は DioramaWork が渡す
Shader "NightShards/Diorama/Eruption"
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
        Tags { "RenderType" = "Opaque" "Queue" = "Geometry" "RenderPipeline" = "UniversalPipeline" }

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

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma multi_compile_instancing

            #define ID_BASE   0.0
            #define ID_GROUND 1.0
            #define ID_WATER  2.0

            #define INNER 0.47
            #define BASE_TOP -0.42
            #define WATER -0.22
            static const float3 CRATER = float3(0.02, 0.11, -0.03);
            static const float3 MOON_DIR = float3(-0.55, 0.62, 0.56); // 正規化は使う所で

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

            float Height(float2 xz)
            {
                float2 c = xz - CRATER.xz;
                float r = length(c);
                float th = atan2(c.y, c.x);
                float h = -0.40 + 0.58 * exp(-pow(r / 0.25, 1.7));
                // 雨で削られた谷: 火口から放射状に、尾根と谷がくり返す
                float gully = 1.0 - abs(sin(th * 9.0 + Fbm3(float2(r * 9.0, th * 2.0) + _Seed) * 3.0));
                h += 0.022 * gully * gully * smoothstep(0.03, 0.12, r) * exp(-r * 2.5);
                // 火口のくぼみと、その縁
                h -= 0.075 * exp(-pow(r / 0.045, 2.0));
                h += 0.012 * exp(-pow((r - 0.055) / 0.015, 2.0));
                // 細かい起伏
                h += 0.012 * Fbm3(xz * 14.0 + _Seed) - 0.006;
                return h;
            }

            // ---------------------------------------------------------------- 溶岩の流れ

            // 溶岩の流れの「どれだけ流れの上か」(0〜1) と、流れの先端からの近さ。width を広げると、流れのまわりの照り返しに使える
            float LavaFlow(float2 xz, float widthScale, out float heat)
            {
                float2 c = xz - CRATER.xz;
                float r = length(c);
                float th = atan2(c.y, c.x);
                float m = 0.0;
                heat = 0.0;
                for (int k = 0; k < 3; k++)
                {
                    float fk = k;
                    float baseAngle = 0.6 + fk * 2.05 + Hash11(fk + _Seed) * 0.6;
                    float angle = baseAngle + 0.22 * sin(r * 24.0 + fk * 1.7) + 0.08 * sin(r * 61.0 + fk);
                    float reach = lerp(0.11 + 0.05 * Hash11(fk + 3.0), 0.31, saturate(_Event * 1.3 - fk * 0.15));
                    float d = abs(atan2(sin(th - angle), cos(th - angle))) * r; // 流れの中心線までの距離
                    float w = (0.008 + 0.004 * Hash11(fk + 7.0)) * widthScale * (1.0 + r * 3.0);
                    float along = smoothstep(0.04, 0.06, r) * smoothstep(reach, reach - 0.035, r);
                    float mk = exp(-(d * d) / (w * w)) * along;
                    m = max(m, mk);
                    heat = max(heat, mk * (1.0 - r / max(reach, 0.01) * 0.65));
                }
                // 火口の溶岩だまり
                float lake = smoothstep(0.042, 0.03, r);
                m = max(m, lake);
                heat = max(heat, lake);
                return m;
            }

            // 溶岩の光る色 (黒体の色: 熱いほど黄色、冷めると暗い赤)
            float3 LavaColor(float heat)
            {
                float3 cool = float3(0.5, 0.04, 0.01);
                float3 hot = float3(4.5, 1.4, 0.25);
                return lerp(cool, hot, heat * heat) * heat;
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

            // ---------------------------------------------------------------- 雷・噴石

            // 雷: 時刻を細かく区切り、区切りごとにくじを引いて光らせる。噴火中ほど当たりやすい
            float Lightning(out float3 pos)
            {
                float slot = floor(_Time.y * 9.0);
                float chance = 0.02 + _Event * 0.22;
                float on = step(1.0 - chance, Hash11(slot + _Seed * 13.0));
                float fade = 1.0 - frac(_Time.y * 9.0);
                float hgt = lerp(0.14, 0.33, _Event);
                pos = CRATER + float3((Hash11(slot + 1.3) - 0.5) * 0.09, 0.06 + Hash11(slot + 2.7) * hgt, (Hash11(slot + 4.1) - 0.5) * 0.09);
                return on * fade;
            }

            // 噴石: 火口から放物線を描いて飛ぶ、赤く光る岩。線との一番近い距離から光の粒として足す
            float3 Ejecta(float3 ro, float3 rd, float tMax)
            {
                if (_Event < 0.01) return 0;
                float3 col = 0;
                for (int i = 0; i < 16; i++)
                {
                    float fi = i;
                    float h1 = Hash11(fi * 3.1 + 0.5), h2 = Hash11(fi * 5.7 + 1.5), h3 = Hash11(fi * 7.3 + 2.5);
                    float period = 1.4 + h1;
                    float ph = frac(_Time.y / period + h2);
                    float ft = ph * 1.1;
                    float a = h1 * 6.2831;
                    float3 v = float3(cos(a) * (0.05 + 0.12 * h3), 0.55 + 0.3 * h2, sin(a) * (0.05 + 0.12 * h3));
                    float3 pos = CRATER + float3(0, 0.01, 0) + v * ft + float3(0, -0.5 * 1.1 * ft * ft, 0);
                    if (pos.y < Height(pos.xz)) continue; // 地面に落ちたら消える
                    float3 w = pos - ro;
                    float tc = dot(w, rd);
                    if (tc < 0.0 || tc > tMax) continue;
                    float d2 = dot(w, w) - tc * tc;
                    float glow = exp(-d2 / (0.0035 * 0.0035)) + 0.15 * exp(-d2 / (0.012 * 0.012));
                    col += float3(4.0, 1.3, 0.3) * glow * (1.0 - ph) * _Event;
                }
                return col;
            }

            // ---------------------------------------------------------------- 噴煙 (立体的な雲)

            float PlumeHeight() { return lerp(0.17, 0.37, _Event); }

            // 噴煙の濃さ。火口の上の円すいの中で、ノイズがもくもくと立ちのぼる。風で少したなびく
            float PlumeDensity(float3 p)
            {
                float y = p.y - CRATER.y;
                if (y < -0.01) return 0.0;
                float height = PlumeHeight();
                float3 q = p - float3(CRATER.x, 0.0, CRATER.z);
                q.x -= y * y * 1.4 * (1.0 - _Event * 0.6);
                float rad = 0.022 + y * lerp(0.32, 0.5, _Event) + smoothstep(height * 0.7, height, y) * 0.06 * _Event; // 上で傘のように広がる
                float shape = saturate(1.0 - length(q.xz) / rad) * smoothstep(height, height * 0.65, y);
                float t = _Time.y * lerp(0.05, 0.12, _Event);
                float3 np = float3(q.x, y - t, q.z) * 26.0;
                float n = Noise3(np) * 0.55 + Noise3(np * 2.1 + 5.3) * 0.3 + Noise3(np * 4.3 + 9.1) * 0.15;
                return max(0.0, shape * 1.35 + n * 0.9 - 0.92) * 70.0;
            }

            // 線のうち噴煙の箱の中の区間を、前から順に進みながら色を足す (前にある噴煙ほど、後ろを隠す)
            float4 Plume(float3 ro, float3 rd, float tMax, float3 flashPos, float flash)
            {
                float height = PlumeHeight();
                float3 bmin = float3(CRATER.x - 0.24, CRATER.y - 0.02, CRATER.z - 0.24);
                float3 bmax = float3(CRATER.x + 0.24, CRATER.y + height + 0.04, CRATER.z + 0.24);
                float3 inv = 1.0 / rd;
                float3 t0 = (bmin - ro) * inv, t1 = (bmax - ro) * inv;
                float3 tsmall = min(t0, t1), tbig = max(t0, t1);
                float tin = max(max(max(tsmall.x, tsmall.y), tsmall.z), 0.0);
                float tout = min(min(min(tbig.x, tbig.y), tbig.z), tMax);
                if (tout <= tin) return float4(0, 0, 0, 1);

                int steps = clamp((int)(_Steps / 5.0), 8, 28);
                float dt = (tout - tin) / steps;
                float t = tin + dt * Hash21(rd.xy * 517.0 + _Time.y) ; // 少しずらして縞を消す
                float3 col = 0;
                float trans = 1.0;
                for (int i = 0; i < 28; i++)
                {
                    if (i >= steps) break;
                    float3 p = ro + rd * t;
                    float dens = PlumeDensity(p);
                    if (dens > 0.0)
                    {
                        float y = p.y - CRATER.y;
                        float3 ash = float3(0.05, 0.045, 0.045);
                        float3 lavaLight = float3(1.6, 0.45, 0.08) * exp(-y * 9.0) * (1.0 + 2.5 * _Event);
                        float3 flashLight = float3(2.5, 2.8, 4.0) * flash * 8.0 * exp(-length(p - flashPos) * 22.0);
                        float3 light = ash + lavaLight + flashLight;
                        float a = 1.0 - exp(-dens * dt);
                        col += trans * a * light;
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
                float3 c = lerp(float3(0.03, 0.012, 0.016), float3(0.004, 0.006, 0.018), sqrt(up));
                c += float3(0.3, 0.07, 0.02) * pow(1.0 - up, 5.0) * (0.5 + _Event); // 地平線の赤い照り返し
                float2 sp = rd.xz / max(rd.y, 0.05) * 70.0;
                float star = step(0.996, Hash21(floor(sp))) * smoothstep(0.1, 0.4, rd.y) * (1.0 - _Event * 0.7);
                return c + star * 0.6;
            }

            // ---------------------------------------------------------------- 色を塗る

            float3 Shade(float3 ro, float3 rd, float3 p, float id, bool crossSection, float3 faceNormal, float3 flashPos, float flash)
            {
                float3 moonDir = normalize(MOON_DIR);
                float3 moonCol = float3(0.32, 0.4, 0.62);
                float3 skyAmb = float3(0.015, 0.018, 0.03);
                float h = Height(p.xz);

                if (id == ID_BASE)
                    return float3(0.015, 0.014, 0.014) + 0.03 * pow(saturate(dot(reflect(rd, faceNormal), moonDir)), 8.0);

                if (crossSection && id == ID_GROUND)
                {
                    // 断面: 何層も重なった溶岩の地層。真ん中の深い所に、赤いマグマの通り道
                    float band = 0.5 + 0.5 * sin(p.y * 110.0 + ValueNoise(p.xz * 40.0 + p.y * 30.0) * 4.0);
                    float3 rock = lerp(float3(0.06, 0.05, 0.05), float3(0.13, 0.1, 0.09), band);
                    float conduit = exp(-pow(length(p.xz - CRATER.xz) / 0.03, 2.0));
                    return rock * 0.25 + float3(3.0, 0.6, 0.08) * conduit * (0.6 + 0.4 * _Event);
                }
                if (crossSection && id == ID_WATER)
                {
                    float depth = WATER - p.y;
                    return lerp(float3(0.01, 0.025, 0.03), float3(0.002, 0.006, 0.01), saturate(depth * 8.0));
                }

                // 火口の光 (噴火中は強く、ゆらめく)
                float flicker = 0.85 + 0.15 * sin(_Time.y * 13.0) * sin(_Time.y * 7.3);
                float3 craterLightPos = CRATER + float3(0, 0.02, 0);
                float3 toCrater = craterLightPos - p;
                float craterAtten = 1.0 / (1.0 + dot(toCrater, toCrater) * 90.0);
                float3 craterCol = float3(1.0, 0.33, 0.07) * (0.6 + 3.0 * _Event) * flicker;

                if (id == ID_WATER)
                {
                    // 夜の海: 小さな波で向きを揺らし、空・噴煙の赤・溶岩の光を映す
                    float t = _Time.y;
                    float2 q = p.xz * 70.0;
                    float3 n = normalize(float3((ValueNoise(q + t * 0.8) - 0.5) * 0.2, 1.0, (ValueNoise(q.yx * 1.3 - t) - 0.5) * 0.2));
                    float3 r = reflect(rd, n);
                    float fres = 0.02 + 0.98 * pow(1.0 - saturate(dot(-rd, n)), 5.0);
                    float3 refl = Sky(r) + craterCol * pow(saturate(dot(r, normalize(toCrater))), 18.0) * 1.5;
                    float depth = WATER - h;
                    float3 body = lerp(float3(0.01, 0.03, 0.035), float3(0.002, 0.006, 0.012), saturate(depth * 12.0));
                    float3 c = lerp(body, refl, fres);
                    c += moonCol * pow(saturate(dot(r, moonDir)), 200.0) * 2.0;

                    // 波打ち際の白い泡: 浅い所で、岸へ寄せる波の縞
                    float foam = smoothstep(0.018, 0.0, depth) * (0.55 + 0.45 * sin(t * 2.2 - depth * 420.0 + ValueNoise(p.xz * 90.0) * 4.0));
                    c += foam * (moonCol * 0.6 + craterCol * craterAtten * 2.0 + 0.04);

                    // 溶岩が海に入る所: 水面が赤く照り、湯気が白く立つ
                    float heat;
                    float lavaNear = LavaFlow(p.xz, 3.5, heat);
                    c += float3(1.2, 0.3, 0.06) * lavaNear * smoothstep(0.03, 0.0, depth) * (0.4 + _Event);
                    float steam = lavaNear * smoothstep(0.04, 0.0, depth) * ValueNoise(p.xz * 60.0 + float2(0, -t * 0.6));
                    c += float3(0.35, 0.3, 0.3) * steam * (0.3 + _Event);
                    return c;
                }

                // 地面
                float3 n = SceneNormal(p);
                float sh = SoftShadow(p + n * 0.002, moonDir);
                float ao = AmbientOcclusion(p, n);

                float slope = 1.0 - n.y;
                float3 basalt = lerp(float3(0.045, 0.04, 0.04), float3(0.09, 0.08, 0.075), Fbm3(p.xz * 30.0));
                float3 green = float3(0.035, 0.06, 0.03) * (0.7 + 0.6 * ValueNoise(p.xz * 50.0));
                float3 sand = float3(0.07, 0.06, 0.055);
                float vegetation = smoothstep(-0.05, -0.15, h) * (1.0 - smoothstep(0.3, 0.6, slope));
                float3 albedo = lerp(basalt, green, vegetation * 0.8);
                albedo = lerp(albedo, sand, smoothstep(WATER + 0.02, WATER + 0.004, h));
                albedo = lerp(albedo, float3(0.11, 0.1, 0.1), smoothstep(0.02, 0.1, h) * 0.6); // 山頂の灰

                float heat;
                float flow = LavaFlow(p.xz, 1.0, heat);
                float glowHeat;
                float glowNear = LavaFlow(p.xz, 4.0, glowHeat);
                albedo = lerp(albedo, float3(0.02, 0.015, 0.015), flow); // 溶岩の上は黒い皮

                float3 c = albedo * (moonCol * saturate(dot(n, moonDir)) * sh + skyAmb * (0.5 + 0.5 * n.y)) * ao;
                c += albedo * craterCol * craterAtten * saturate(dot(n, normalize(toCrater)) * 0.7 + 0.3);
                c += albedo * float3(1.0, 0.3, 0.06) * glowNear * glowHeat * 1.5;                // 流れのまわりの照り返し
                c += albedo * float3(0.6, 0.7, 1.0) * flash * 0.6 * exp(-length(p - flashPos) * 4.0); // 雷の閃光

                // 溶岩そのものの光: 冷えた皮の割れ目から光る。割れ目の模様は流れに沿ってゆっくり動く
                float2 crustUV = p.xz * 140.0 + float2(0, _Time.y * 0.4);
                float crack = smoothstep(0.42, 0.5, abs(ValueNoise(crustUV) - 0.5) * 2.0);
                float glow = lerp(0.25, 1.0, 1.0 - crack);
                c += LavaColor(heat) * flow * glow * (1.0 + 0.6 * _Event);
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

                // 地形より上の何もない空間は飛ばす (噴煙は別に計算する)
                const float maxHeight = 0.2;
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

                float3 flashPos;
                float flash = Lightning(flashPos);

                float3 col;
                if (hit)
                {
                    float3 p = ro + rd * t;
                    bool crossSection = outside && (abs(p.x) > INNER - 0.002 || abs(p.z) > INNER - 0.002);
                    col = Shade(ro, rd, p, id, crossSection, faceNormal, flashPos, flash);
                }
                else
                {
                    col = Sky(rd);
                }

                // 噴煙を重ね、噴石の光を足す
                float4 plume = Plume(ro, rd, tHit, flashPos, flash);
                col = col * plume.a + plume.rgb;
                col += Ejecta(ro, rd, tHit);

                // ガラス: 外から見ているときだけ、映り込みと金属の枠
                if (outside)
                {
                    float fres = 0.04 + 0.96 * pow(1.0 - saturate(dot(-rd, faceNormal)), 5.0);
                    col = lerp(col, float3(0.75, 0.8, 0.85) * 0.5, fres * _Glass);
                    float3 d = 0.5 - ae;
                    float edge = d.x + d.y + d.z - max(d.x, max(d.y, d.z));
                    float frame = 1.0 - smoothstep(0.004, 0.006, edge);
                    col = lerp(col, float3(0.05, 0.05, 0.055) + 0.15 * fres, frame);
                }
                return half4(col, 1.0);
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
