// 作品「黄昏の棚田」(夕の間)。夕焼けを映す、山の斜面の棚田と里の家。URP 用。
// Cube の中をレイマーチングして描く。Cube の座標は -0.5〜0.5、下の 0.08 は黒い台。
//
// 見どころ:
//   ・奥へ高くなる斜面に、水を張った棚田が段々に重なる。田んぼのひとつひとつの水面が、夕焼けの空を映す鏡になる
//   ・田んぼのふちのあぜ道 (草)、段の土手、斜面の上の杉の森
//   ・手前の平らな所に、かやぶき屋根の家が 4 軒。かまどの煙が立ちのぼる
//   ・田んぼの水面には、空だけでなく、山やあぜや森も逆さに映る。風のさざ波が、田んぼから田んぼへ渡っていく
//   ・斜面をただよう夕もやに、山の端を抜けた夕日の光の筋が差す
//   ・材質ごとのつや (草は逆光で透け、木の壁はしっとり、わらは粗い)
// 仕掛け (_Event 0〜1): 日が沈んで夜になる。家の障子に灯がともり、田んぼの上を蛍が舞い、水面に星が映る
//
// 外から見たとき、地形のない所 (空) は透明にして、ガラスケースの向こうの部屋が見えるようにする。
// 中に入ったとき (カメラが箱の中) だけ、夕焼け (夜は星空) を描く
//
// _Steps / _ShadowSteps は DioramaLOD が距離で下げる。_Event / _EventTime は DioramaWork が渡す。
// _HeightTex は DioramaWork が再生の最初に作る、地形の高さの表 (なければ式で計算する)
Shader "NightShards/Diorama/Terraces"
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
            #define ID_TREE   2.0
            #define ID_HOUSE  3.0

            #define INNER 0.47
            #define STEP_H 0.022     // 棚田の一段の高さ
            #define TREE_CELL 0.045
            #define HOUSES 4
            #define FIREFLIES 40
            static const float3 SUN_DIR = float3(-0.3, 0.12, -0.95); // 奥の山へ沈む夕日。正規化は使う所で
            static const float3 HOUSE[HOUSES] = // 家の場所 (x, z) と向き
            {
                float3(0.17, 0.3, 0.3), float3(0.31, 0.23, -0.4), float3(0.08, 0.39, 0.1), float3(0.33, 0.38, 1.2)
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

            // ---------------------------------------------------------------- 地形
            // ※ Slope と Height を変えたら、C# の DioramaTerrain も同じに直す (中を歩くときの地面になる)

            // 棚田を作る前の、なめらかな斜面。奥へ高く、左右にゆるくうねる
            float Slope(float2 xz)
            {
                float back = smoothstep(0.42, -0.45, xz.y);
                return -0.24 + 0.34 * back + 0.05 * sin(xz.x * 4.0 + _Seed) * back + 0.04 * (Fbm3(xz * 3.0 + _Seed) - 0.45);
            }

            // 斜面を段々に切った高さ。段の平らな所が田んぼ、その外側のふちにあぜ、段の間は土手
            float Height(float2 xz)
            {
                float S = Slope(xz);
                float u = S / STEP_H;
                float k = floor(u);
                float f = u - k;
                float terr = (k + smoothstep(0.75, 1.0, f)) * STEP_H;
                float bund = (f - 0.7) / 0.035;
                terr += 0.004 * exp(-bund * bund);
                float mask = smoothstep(-0.21, -0.18, S) * smoothstep(0.08, 0.04, S); // 里の平地と、上の森には棚田を作らない
                float h = lerp(S, terr, mask);
                h += 0.003 * Fbm3(xz * 30.0 + _Seed) * (1.0 - mask * 0.8);
                return h;
            }

            float HeightFast(float2 xz)
            {
                [branch] if (_HeightTexOn > 0.5)
                    return SAMPLE_TEXTURE2D_LOD(_HeightTex, sampler_linear_clamp, xz / (2.0 * INNER) + 0.5, 0).r;
                return Height(xz);
            }

            // そこが田んぼの水面か (段の平らな所の内側)。0〜1
            float PaddyMask(float2 xz)
            {
                float S = Slope(xz);
                float f = frac(S / STEP_H);
                float mask = smoothstep(-0.2, -0.185, S) * smoothstep(0.075, 0.05, S);
                return mask * smoothstep(0.66, 0.6, f) * smoothstep(0.0, 0.04, f);
            }

            // ---------------------------------------------------------------- 杉の森と家

            float Cedars(float3 p, float groundH)
            {
                if (p.y - groundH > 0.09) return p.y - groundH - 0.08;
                float2 cell = floor(p.xz / TREE_CELL);
                float2 local = p.xz - (cell + 0.5) * TREE_CELL;
                float2 toEdge = 0.5 * TREE_CELL - abs(local);
                float bound = max(min(toEdge.x, toEdge.y), 0.0) + 0.003;
                float2 id = cell + _Seed * 0.37;
                if (Hash21(id) > 0.7) return bound;
                float2 base = (cell + 0.5) * TREE_CELL + (Hash22b(id + 1.3) - 0.5) * TREE_CELL * 0.5;
                if (abs(base.x) > INNER - 0.02 || abs(base.y) > INNER - 0.02) return bound;
                if (Slope(base) < 0.06) return bound; // 森は斜面の上のほうだけ
                float height = 0.05 + 0.03 * Hash21(id + 3.3);
                float3 q = p - float3(base.x, HeightFast(base) - 0.003, base.y);
                float k = saturate(q.y / height);
                float rad = height * 0.2 * (1.0 - k) * (0.8 + 0.2 * sin(k * 28.0)) + 0.0008;
                float d = max(length(q.xz) - rad, max(-q.y, q.y - height)) * 0.6;
                return min(d, bound);
            }

            // かやぶきの家: 木の壁の箱と、急な切妻の厚い屋根。q は家の向きの座標 (地面が y=0)
            float HouseSDF(float3 q)
            {
                float body = SdBox(q - float3(0, 0.009, 0), float3(0.016, 0.009, 0.011));
                float3 r = q - float3(0, 0.017, 0);
                float roof = max(max(abs(r.x) - 0.021, abs(r.z) * 0.75 + r.y * 0.66 - 0.011), -r.y);
                return min(body, roof);
            }

            float Houses(float3 p, out int which)
            {
                float d = 1.0;
                which = 0;
                float outside = max(max(-p.x, 0.15 - p.z), p.y + 0.15);
                if (outside > 0.0) return outside + 0.005; // 家は手前右の里だけ。そこから遠い所では、里までの距離を返す
                [loop] for (int i = 0; i < HOUSES; i++)
                {
                    float3 h = HOUSE[i];
                    float3 q = p - float3(h.x, HeightFast(h.xy) - 0.002, h.y);
                    float c = cos(h.z), s = sin(h.z);
                    q = float3(q.x * c + q.z * s, q.y, -q.x * s + q.z * c);
                    float dh = HouseSDF(q);
                    if (dh < d)
                    {
                        d = dh;
                        which = i;
                    }
                }
                return d;
            }

            // ---------------------------------------------------------------- 世界の形

            float2 MapX(float3 p, bool exact)
            {
                float2 res = float2(SdBox(p - float3(0, -0.46, 0), float3(0.5, 0.04, 0.5)), ID_BASE);
                float column = SdBox(p - float3(0, 0.04, 0), float3(INNER, 0.46, INNER));
                float h;
                if (exact) h = Height(p.xz);
                else h = HeightFast(p.xz);
                float ground = max((p.y - h) * 0.38, column); // 段の土手は急なので、ゆっくり進む
                if (ground < res.x) res = float2(ground, ID_GROUND);
                float tree = max(Cedars(p, h), column);
                if (tree < res.x) res = float2(tree, ID_TREE);
                int which;
                float house = Houses(p, which);
                if (house < res.x) res = float2(house, ID_HOUSE);
                return res;
            }

            float2 Map(float3 p) { return MapX(p, false); }

            float3 SceneNormal(float3 p)
            {
                const float2 e = float2(0.0006, -0.0006);
                float3 g = e.xyy * MapX(p + e.xyy, true).x + e.yyx * MapX(p + e.yyx, true).x +
                           e.yxy * MapX(p + e.yxy, true).x + e.xxx * MapX(p + e.xxx, true).x;
                return g / max(length(g), 1e-7);
            }

            float SoftShadow(float3 p, float3 l)
            {
                float res = 1.0;
                float t = 0.005;
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
                    float d = 0.008 * i;
                    occ += (d - Map(p + n * d).x) * w;
                    w *= 0.6;
                }
                return saturate(1.0 - occ * 16.0);
            }

            // ---------------------------------------------------------------- 夕方から夜へ

            // 夜の度合い (0 夕方 〜 1 夜)。仕掛けが始まると 6 秒かけて夜になり、おさまると夕方に戻る
            float Night()
            {
                return min(saturate(_EventTime / 6.0), saturate(_Event * 1.2)) * step(0.001, _Event);
            }

            float3 Sky(float3 rd, float night)
            {
                float up = saturate(rd.y);
                float3 sunDir = normalize(SUN_DIR);
                float sd = saturate(dot(rd, sunDir));
                // 夕焼け: 地平線は燃えるオレンジ、上は紫から群青
                float3 dusk = lerp(float3(1.3, 0.55, 0.25), float3(0.35, 0.25, 0.45), pow(up, 0.5));
                dusk = lerp(dusk, float3(0.08, 0.1, 0.25), smoothstep(0.3, 0.9, up));
                dusk += float3(1.6, 0.8, 0.35) * pow(sd, 12.0) + float3(3.0, 2.0, 1.2) * smoothstep(0.9993, 0.9997, dot(rd, sunDir));
                // 夜: 群青から黒、星
                float3 nightCol = lerp(float3(0.03, 0.04, 0.09), float3(0.004, 0.006, 0.02), sqrt(up));
                float3 sp = rd * 220.0;
                float3 cell = floor(sp);
                float star = step(0.992, Hash31(cell)) * smoothstep(0.25, 0.1, length(frac(sp) - 0.5)) * smoothstep(0.02, 0.2, rd.y);
                nightCol += star * 0.9;
                return lerp(dusk, nightCol, night);
            }

            // ---------------------------------------------------------------- 蛍

            float3 Fireflies(float3 ro, float3 rd, float tMax, float night)
            {
                if (night < 0.05) return 0;
                float3 col = 0;
                float t = _Time.y;
                [loop] for (int i = 0; i < FIREFLIES; i++)
                {
                    float fi = i;
                    float2 home = float2(-0.3 + 0.6 * Hash11(fi + 1.0), -0.15 + 0.45 * Hash11(fi + 2.0));
                    float2 wander = float2(sin(t * 0.3 + fi), cos(t * 0.25 + fi * 1.7)) * 0.03;
                    float2 xz = home + wander;
                    float3 pos = float3(xz.x, HeightFast(xz) + 0.006 + 0.004 * sin(t * 0.7 + fi), xz.y);
                    float3 w = pos - ro;
                    float tc = dot(w, rd);
                    if (tc < 0.0 || tc > tMax) continue;
                    float d2 = dot(w, w) - tc * tc;
                    float core = max(0.0006, tc * 0.0011);
                    float blink = pow(saturate(sin(t * (1.2 + 0.5 * Hash11(fi + 3.0)) + fi * 2.3)), 4.0); // ふわっと光って、消える
                    col += float3(0.7, 1.0, 0.25) * blink * (exp(-d2 / (core * core)) * 1.5 + exp(-d2 / (core * core * 25.0)) * 0.08);
                }
                return col * night;
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

            // ---------------------------------------------------------------- 水鏡 (田んぼに映る景色)

            // 水面で反射した線を、地形 (と森の高さ) を相手にもう一度進める。当たれば山やあぜの色、当たらなければ空
            float3 ReflectTerrain(float3 p, float3 r, float night, float3 sunDir, float3 sunCol, float3 skyLow)
            {
                float t = 0.003;
                [loop] for (int i = 0; i < 36; i++)
                {
                    float3 q = p + r * t;
                    if (abs(q.x) > INNER || abs(q.z) > INNER || q.y > 0.35) break;
                    float h = HeightFast(q.xz);
                    float forest = smoothstep(0.05, 0.09, h);
                    float d = (q.y - (h + 0.045 * forest)) * 0.4;
                    if (d < 0.0008)
                    {
                        float hx = HeightFast(q.xz + float2(0.004, 0)) - h;
                        float hz = HeightFast(q.xz + float2(0, 0.004)) - h;
                        float3 n = normalize(float3(-hx, 0.004, -hz));
                        float3 albedo = lerp(float3(0.2, 0.32, 0.1), float3(0.05, 0.1, 0.05), forest);
                        float lit = saturate(dot(n, sunDir));
                        return albedo * (sunCol * lit * 0.9 + skyLow * 0.5);
                    }
                    t += max(d, 0.002);
                }
                return Sky(r, night);
            }

            // ---------------------------------------------------------------- 夕もやと光の筋とかまどの煙

            // 日の光がそこまで届くか (山と森の高さだけで調べる、軽い影)
            float SunVisible(float3 p, float3 L)
            {
                [loop] for (int k = 1; k <= 5; k++)
                {
                    float3 q = p + L * (0.05 * k);
                    if (abs(q.x) > INNER || abs(q.z) > INNER) break;
                    float h = HeightFast(q.xz);
                    if (q.y < h + 0.045 * smoothstep(0.05, 0.09, h)) return 0.0;
                }
                return 1.0;
            }

            float MistDensity(float3 p, out float smoke)
            {
                float t = _Time.y;
                // 夕もや: 地面のすぐ上にたまり、風に流れる
                float above = p.y - HeightFast(p.xz);
                float n = Noise3(float3(p.x * 8.0 - t * 0.02, p.y * 12.0, p.z * 8.0)) * 0.6 + Noise3(p * 20.0 + t * 0.01) * 0.4;
                float mist = max(0.0, exp(-max(above, 0.0) / 0.03) * 1.2 + n - 1.1) * 18.0;
                // かまどの煙: 家の屋根から細く立ちのぼり、風下へたなびく
                smoke = 0.0;
                [loop] for (int i = 0; i < HOUSES; i++)
                {
                    float3 hs = HOUSE[i];
                    float base = HeightFast(hs.xy) + 0.028;
                    float sy = p.y - base;
                    if (sy < 0.0 || sy > 0.12) continue;
                    float2 c = p.xz - hs.xy - float2(-0.06, -0.02) * sy * 2.0;
                    float rad = 0.003 + sy * 0.15;
                    float sh = saturate(1.0 - length(c) / rad) * smoothstep(0.12, 0.04, sy);
                    if (sh <= 0.0) continue;
                    float sn = Noise3(float3(c.x * 120.0, sy * 60.0 - t * 1.5, c.y * 120.0));
                    smoke += max(0.0, sh * 1.2 + sn * 0.7 - 0.9) * 60.0;
                }
                return mist + smoke;
            }

            float4 Mist(float3 ro, float3 rd, float tMax, float night, float3 sunDir, float3 sunCol, float3 skyLow)
            {
                float3 bmin = float3(-INNER, -0.26, -INNER);
                float3 bmax = float3(INNER, 0.22, INNER);
                float3 inv = 1.0 / rd;
                float3 t0 = (bmin - ro) * inv, t1 = (bmax - ro) * inv;
                float3 tsmall = min(t0, t1), tbig = max(t0, t1);
                float tin = max(max(max(tsmall.x, tsmall.y), tsmall.z), 0.0);
                float tout = min(min(min(tbig.x, tbig.y), tbig.z), tMax);
                if (tout <= tin) return float4(0, 0, 0, 1);
                const int steps = 16;
                float dt = (tout - tin) / steps;
                float t = tin + dt * Hash21(rd.xy * 517.0 + _Time.y);
                // 夕日のほうを向くほど、もやが明るく輝く (光が前へ散らばる)
                float phase = 0.35 + 2.5 * pow(saturate(dot(rd, sunDir)), 8.0);
                float3 col = 0;
                float trans = 1.0;
                [loop] for (int i = 0; i < steps; i++)
                {
                    float3 p = ro + rd * t;
                    float smoke;
                    float dens = MistDensity(p, smoke);
                    if (dens > 0.0)
                    {
                        float vis = SunVisible(p, sunDir);
                        float3 light = skyLow * 0.6 + sunCol * vis * phase * 0.6;
                        light = lerp(light, float3(0.35, 0.33, 0.33) * (0.4 + 0.6 * (1.0 - night)), smoke / max(dens, 1e-4) * 0.5);
                        float a = 1.0 - exp(-dens * dt);
                        col += trans * a * light;
                        trans *= 1.0 - a;
                        if (trans < 0.02) break;
                    }
                    t += dt;
                }
                return float4(col, trans);
            }

            // ---------------------------------------------------------------- 色を塗る

            float3 Shade(float3 ro, float3 rd, float3 p, float id, bool outside, float3 faceNormal)
            {
                float night = Night();
                float3 L = normalize(SUN_DIR);
                float3 sunCol = lerp(float3(1.6, 0.85, 0.45), float3(0.0, 0.0, 0.0), night);
                float3 skyTop = lerp(float3(0.25, 0.22, 0.38), float3(0.012, 0.016, 0.04), night);
                float3 skyLow = lerp(float3(0.75, 0.42, 0.28), float3(0.02, 0.025, 0.05), night);
                float3 v = -rd;
                float t = _Time.y;

                if (id == ID_BASE)
                    return float3(0.015, 0.014, 0.014) + 0.03 * pow(saturate(1.0 - abs(dot(rd, faceNormal))), 4.0);

                float3 n = SceneNormal(p);
                float sh = SoftShadow(p + n * 0.002, L);
                float ao = AmbientOcclusion(p, n);

                if (id == ID_TREE)
                {
                    float3 nb = BumpNormal(n, p, 700.0, 0.8);
                    float3 albedo = float3(0.06, 0.12, 0.06) * (0.8 + 0.4 * Noise3(p * 600.0));
                    return Surface(albedo, nb, v, L, sunCol, sh, ao, 0.75, 0.03, 0.6, skyTop, skyLow);
                }

                if (id == ID_HOUSE)
                {
                    int which;
                    Houses(p, which);
                    float3 hs = HOUSE[which];
                    float3 q = p - float3(hs.x, HeightFast(hs.xy) - 0.002, hs.y);
                    float c = cos(hs.z), s = sin(hs.z);
                    q = float3(q.x * c + q.z * s, q.y, -q.x * s + q.z * c);
                    if (q.y > 0.0175)
                    {
                        // かやぶき屋根: 茶色いわらの筋。粗く、光はほとんど照り返さない
                        float straw = 0.75 + 0.25 * sin((q.y * 1.3 + abs(q.z)) * 2500.0 + Noise3(p * 900.0) * 3.0);
                        float3 nb = BumpNormal(n, p, 1500.0, 1.2);
                        return Surface(float3(0.45, 0.34, 0.2) * straw, nb, v, L, sunCol, sh, ao, 0.95, 0.02, 0.15, skyTop, skyLow);
                    }
                    // 壁: 黒っぽい板 (しっとりしたつや) と、白い障子の窓 (光が透ける)。夜は障子に灯がともる
                    float window = step(abs(q.x), 0.012) * step(0.004, q.y) * step(q.y, 0.014) * step(0.0105, abs(q.z));
                    float frame = step(0.4, frac(q.x * 600.0)) * step(0.4, frac(q.y * 600.0));
                    float paper = window * frame;
                    float grain = 0.85 + 0.15 * sin(q.y * 4000.0 + Noise3(p * 800.0) * 2.0);
                    float3 albedo = lerp(float3(0.16, 0.11, 0.07) * grain, float3(0.8, 0.75, 0.62), paper);
                    float3 col = Surface(albedo, n, v, L, sunCol, sh, ao, lerp(0.5, 0.85, paper), 0.04, paper * 0.7, skyTop, skyLow);
                    float flicker = 0.9 + 0.1 * sin(t * 7.0 + which * 3.0) * sin(t * 4.3);
                    col += float3(1.8, 0.9, 0.35) * paper * smoothstep(0.3, 0.8, night) * flicker;
                    return col;
                }

                // 田んぼの水面: 空と、まわりの山・あぜ・森を逆さに映す。風が通ると、さざ波が田んぼを渡っていく
                float paddy = PaddyMask(p.xz);
                float3 water = 0;
                if (paddy > 0.01)
                {
                    float2 windDir = normalize(float2(0.8, -0.6));
                    float gust = smoothstep(0.45, 0.75, Noise3(float3(p.xz * 6.0 - windDir * t * 0.25, t * 0.1)));
                    float wave = sin(dot(p.xz, windDir) * 420.0 - t * 6.0 + ValueNoise(p.xz * 60.0) * 3.0);
                    float2 slope = windDir * wave * gust * 0.05;
                    slope += (float2(ValueNoise(p.xz * 140.0 + t * 0.4), ValueNoise(p.xz.yx * 140.0 + 3.0 - t * 0.35)) - 0.5) * 0.012;
                    float3 wn = normalize(float3(slope.x, 1.0, slope.y));
                    float3 r = reflect(rd, wn);
                    float fres = 0.02 + 0.98 * pow(1.0 - saturate(dot(v, wn)), 5.0);
                    float3 refl = ReflectTerrain(p + wn * 0.001, r, night, L, sunCol, skyLow);
                    float sd = saturate(dot(r, L));
                    refl += sunCol * pow(sd, 600.0) * 8.0;                      // 夕日のきらめき
                    float3 mud = float3(0.1, 0.08, 0.05) * (skyLow * 0.6 + sunCol * 0.2);
                    water = lerp(mud, refl, 0.3 + 0.7 * fres);
                    // 稲の苗: 水面から点々と出ている緑 (逆光で透ける)
                    float seedling = smoothstep(0.7, 0.85, abs(sin(p.x * 900.0)) * abs(sin(p.z * 900.0)));
                    float3 sprout = Surface(float3(0.25, 0.45, 0.12), n, v, L, sunCol, sh, ao, 0.6, 0.03, 0.8, skyTop, skyLow);
                    water = lerp(water, sprout, seedling * 0.5);
                }
                // あぜと土手と里: 草 (逆光で透けて光る)。急な土手は、苔むした石垣
                float steep = smoothstep(0.8, 0.5, n.y);
                float3 grass = lerp(float3(0.18, 0.3, 0.09), float3(0.3, 0.4, 0.12), Noise3(p * 500.0));
                float2 sw = float2(p.x * 260.0 + p.z * 180.0, p.y * 520.0);
                float2 cellId = floor(float2(sw.x + floor(sw.y) * 0.5, sw.y));
                float joint = smoothstep(0.06, 0.0, min(frac(sw.x + floor(sw.y) * 0.5), frac(sw.y)));
                float3 stone = float3(0.42, 0.38, 0.32) * (0.75 + 0.35 * Hash21(cellId)) * (1.0 - 0.6 * joint);
                stone = lerp(stone, float3(0.2, 0.3, 0.1), smoothstep(0.55, 0.75, Noise3(p * 300.0)) * 0.6); // 苔
                float3 albedo = lerp(grass, stone, steep);
                float3 nb = BumpNormal(n, p, steep > 0.5 ? 600.0 : 900.0, steep > 0.5 ? 0.7 : 0.9);
                float3 land = Surface(albedo, nb, v, L, sunCol, sh, ao, lerp(0.7, 0.6, steep), 0.03, lerp(0.55, 0.0, steep), skyTop, skyLow);
                return lerp(land, water, paddy);
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

                const float maxHeight = 0.27;
                if (ro.y > maxHeight && rd.y < 0.0) t = max(t, (maxHeight - ro.y) / rd.y);

                bool hit = false;
                float id = 0.0;
                int steps = (int)_Steps;
                [loop] for (int i = 0; i < 200; i++)
                {
                    if (i >= steps || t > box.y) break;
                    float3 pos = ro + rd * t;
                    if (rd.y > 0.0 && pos.y > maxHeight + 0.01) break;
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
                    for (int r = 0; r < 2; r++) t += MapX(ro + rd * t, true).x;
                }
                float tHit = hit ? t : box.y;
                float night = Night();

                float3 col = 0;
                if (hit) col = Shade(ro, rd, ro + rd * t, id, outside, faceNormal);
                else if (!outside) col = Sky(rd, night);

                // 霞: 夕方は金色に、夜は青く
                float travel = tHit - max(box.x, 0.0);
                float3 haze = lerp(float3(0.55, 0.32, 0.25), float3(0.02, 0.03, 0.06), night);
                if (hit) col = lerp(col, haze, (1.0 - exp(-travel * 0.6)) * 0.6);

                float alpha = (hit || !outside) ? 1.0 : 0.0;

                // 夕もや・光の筋・かまどの煙を重ねる
                float3 sunDirF = normalize(SUN_DIR);
                float3 sunColF = lerp(float3(1.6, 0.85, 0.45), float3(0.0, 0.0, 0.0), night);
                float3 skyLowF = lerp(float3(0.75, 0.42, 0.28), float3(0.02, 0.025, 0.05), night);
                float4 mist = Mist(ro, rd, tHit, night, sunDirF, sunColF, skyLowF);
                col = col * mist.a + mist.rgb;
                alpha = 1.0 - (1.0 - alpha) * mist.a;

                col += Fireflies(ro, rd, tHit, night);

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
