// 作品「万里の長城」(アジアの間)。秋の山の尾根を、うねりながら上り下りする長城。URP 用。
// Cube の中をレイマーチングして描く。Cube の座標は -0.5〜0.5、下の 0.08 は黒い台。
//
// 形は実物の寸法 (1 m = 0.002。慕田峪・金山嶺のあたりの、明代の長城)。
//   ・城壁: 高さ 7 m・上の幅 7 m。灰色のれんがと切り石。上は歩ける通路で、北 (外) 側に凸凹の狭間 (のこぎりの歯の形)、南 (内) 側に低い胸壁
//   ・望楼 (敵楼): 11 m 四方・高さ 13 m の 2 階建て。各面に 3 つのアーチ窓、通路が中を通り抜ける。屋上にも狭間と、のろし台
//   ・急な尾根: 城壁は尾根のいちばん高い所をたどる。両側は急な斜面で、谷には雲海
//   ・秋の山: 赤・橙・黄色の紅葉と、緑の松。ところどころ灰色の岩
// 仕掛け (_Event 0〜1): 夕暮れになり、手前の望楼から奥の望楼へ、のろし (烽火) が次々にともって尾根を伝っていく
//
// 軽くする工夫: 地形は高さの表で進む (地面から遠い所は、いちばん急な崖でも行き過ぎない歩幅)。当たったら正確な式で合わせ直す。
//   雲海は、層の中を通る長さから計算する (何度も調べない)
//
// 外から見たとき、何もない所 (空) は透明にして、ガラスケースの向こうの部屋が見えるようにする。
// 中に入ったとき (カメラが箱の中) だけ、空を描く
Shader "NightShards/Diorama/GreatWall"
{
    Properties
    {
        _Steps ("Ray Steps", Range(16, 200)) = 130
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

            // ---------------------------------------------------------------- 場所と寸法 (1 m = 0.002)
            // ※ Path・Crest・Height を変えたら、C# の DioramaTerrain (GreatWall) も同じに直す (歩く地面)

            #define ID_BASE   0.0
            #define ID_GROUND 1.0
            #define ID_WALL   2.0
            #define ID_TOWER  3.0

            #define VALLEY_Y -0.42                                 // 谷底
            #define FOG_Y -0.33                                    // 雲海の上面
            #define WALL_HW 0.0035                                 // 城壁の半分の幅 (7 m)
            #define WALK_H 0.014                                   // 通路の高さ (尾根から 7 m)
            #define TOWERS 4
            #define WS 2.0                                         // 城壁と望楼を大きくする倍率 (形は 1 m = 0.002 で作り、2 倍に置く)
            static const float TOWER_Z[TOWERS] = { 0.27, 0.05, -0.17, -0.38 }; // 望楼の場所 (手前から奥へ)
            static const float3 SUN_DIR = float3(0.55, 0.5, 0.65);

            // 城壁の通る線 (x = Path(z)) と、その傾き
            float Path(float z) { return 0.1 * sin(z * 3.7 + 0.4) + 0.035 * sin(z * 9.1 + 1.0); }
            float PathD(float z) { return 0.37 * cos(z * 3.7 + 0.4) + 0.3185 * cos(z * 9.1 + 1.0); }
            // 尾根のてっぺんの高さ (城壁の足元)
            float Crest(float z) { return -0.12 + 0.07 * sin(z * 4.6 + 2.0) + 0.03 * sin(z * 10.3 + 0.7); }

            // 城壁の線からの、横の距離 (北が -)
            float SideDist(float2 xz) { return (xz.x - Path(xz.y)) / sqrt(1.0 + PathD(xz.y) * PathD(xz.y)); }

            // ---------------------------------------------------------------- 地形

            // ギザギザの尾根のノイズ (0〜1)
            float Ridged(float2 p)
            {
                float a = 1.0 - abs(ValueNoise(p) * 2.0 - 1.0);
                float b = 1.0 - abs(ValueNoise(p * 2.1 + 5.3) * 2.0 - 1.0);
                return a * a * 0.65 + b * b * 0.35;
            }

            float Height(float2 xz)
            {
                float d = abs(SideDist(xz));
                float c = Crest(xz.y);
                // 城壁の尾根: てっぺんは細く平ら、両側は急に落ちる (遠いほど、少しゆるやか)
                float ridge = c - 0.004 - 0.95 * max(d - 0.014, 0.0) + 0.45 * max(d - 0.12, 0.0);
                ridge += (Ridged(xz * 14.0) - 0.5) * 0.035 * smoothstep(0.015, 0.06, d);
                // まわりの山並み (城壁の尾根より低い)
                float other = VALLEY_Y + 0.26 * Ridged(xz * 4.5 + 2.0) + 0.06 * Fbm3(xz * 12.0);
                other = min(other, c - 0.03 - 0.5 * max(0.12 - d, 0.0));
                return max(max(ridge, other), VALLEY_Y);
            }

            float HeightFast(float2 xz)
            {
                [branch] if (_HeightTexOn > 0.5)
                    return SAMPLE_TEXTURE2D_LOD(_HeightTex, sampler_linear_clamp, xz / (2.0 * INNER) + 0.5, 0).r;
                return Height(xz);
            }

            // ---------------------------------------------------------------- 城壁と望楼

            // 城壁: 通路の板と、北の狭間 (凸凹)、南の低い胸壁。d は横の距離、s は線にそった位置、y は尾根からの高さ
            float WallShape(float d, float s, float y)
            {
                float body = max(max(abs(d) - WALL_HW, y - WALK_H), -0.03 - y);
                // 北 (外) 側の狭間: 1.5 m の高さの壁に、2 m おきの凸 (のこぎりの歯)
                float merlon = step(frac(s / 0.0045), 0.55);
                float outer = max(max(abs(d + WALL_HW - 0.0004) - 0.0004, y - (WALK_H + 0.0028 + 0.0022 * merlon)), WALK_H - 0.001 - y);
                // 南 (内) 側の胸壁
                float inner = max(max(abs(d - WALL_HW + 0.0003) - 0.0003, y - (WALK_H + 0.002)), WALK_H - 0.001 - y);
                return min(body, min(outer, inner));
            }

            // 望楼: 11 m 四方の 2 階建て。各面にアーチ窓が 3 つ、通路が中を抜ける。屋上に狭間とのろし台
            float TowerShape(float d, float s, float y)
            {
                float2 a = float2(abs(d), abs(s));
                float body = max(max(max(a.x, a.y) - 0.0055, y - 0.026), -0.03 - y);
                // 通路のトンネル (城壁の通路から入って、反対へ抜ける)
                body = max(body, -max(max(a.x - 0.0016, y - (WALK_H + 0.0042)), WALK_H - y));
                // アーチ窓: 2 階の高さに、各面 3 つ (くぼみ)
                float u = a.x > a.y ? s : d;
                float um = abs(u - round(u / 0.0034) * 0.0034);
                float win = max(max(um - 0.0007, abs(y - 0.0205) - 0.0016), 0.0049 - max(a.x, a.y));
                body = max(body, -win);
                // 屋上: 周りの狭間と、まん中ののろし台
                float merlon = step(frac((a.x > a.y ? s : d) / 0.003 + 0.25), 0.5);
                float roofWall = max(max(abs(max(a.x, a.y) - 0.0051) - 0.0004, y - (0.0285 + 0.0018 * merlon)), 0.0255 - y);
                float beacon = max(max(a.x, a.y) - 0.0016, abs(y - 0.0275) - 0.0015);
                return min(body, min(roofWall, beacon));
            }

            float WallAndTowers(float3 p, out float isTower)
            {
                isTower = 0;
                float d = SideDist(p.xz);
                if (abs(d) > 0.012 * WS) return (abs(d) - 0.0105 * WS) * 0.8;
                float s = p.z;
                float c = Crest(s);
                float y = p.y - c;
                if (y > 0.04 * WS) return (y - 0.035 * WS) * 0.8;
                float w = WallShape(d / WS, s / WS, y / WS) * WS;
                float t = 1e5;
                [unroll] for (int k = 0; k < TOWERS; k++)
                {
                    float sz = TOWER_Z[k];
                    if (abs(s - sz) < 0.012 * WS)
                    {
                        float yt = p.y - Crest(sz);
                        t = min(t, TowerShape(d / WS, (s - sz) / WS, yt / WS) * WS);
                    }
                }
                if (t < w) isTower = 1;
                // 城壁は斜面にそって上下するので、少し小さめに進む
                return min(w, t) * 0.7;
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
                    // 高さの表で進む。地面から遠い所は、いちばん急な崖でも行き過ぎない歩幅。近い所だけ、坂の急さで歩幅を広げる
                    float h = HeightFast(p.xz);
                    float above = p.y - h;
                    if (above > 0.008) ground = above * 0.3;
                    else
                    {
                        float hx = HeightFast(p.xz + float2(0.003, 0.0)), hz = HeightFast(p.xz + float2(0.0, 0.003));
                        float2 g = float2(hx - h, hz - h) / 0.003;
                        ground = above * 0.8 / sqrt(1.0 + dot(g, g) * 1.5);
                    }
                }
                ground = max(ground, column);
                if (ground < res.x) res = float2(ground, ID_GROUND);
                float isTower;
                float wall = max(WallAndTowers(p, isTower), column);
                if (wall < res.x) res = float2(wall, isTower > 0.5 ? ID_TOWER : ID_WALL);
                return res;
            }

            float2 Map(float3 p) { return MapX(p, false); }

            // 面の向き。地面は高さの表から安く測る (細かいでこぼこは、塗るときの凹凸で足す)。建物は形の式から正確に
            float3 SceneNormal(float3 p, float id)
            {
                if (id == ID_GROUND && max(abs(p.x), abs(p.z)) < INNER - 0.003) // 箱の切り口の近くは、正確な式で
                {
                    const float e = 0.0015;
                    float hx = HeightFast(p.xz + float2(e, 0)) - HeightFast(p.xz - float2(e, 0));
                    float hz = HeightFast(p.xz + float2(0, e)) - HeightFast(p.xz - float2(0, e));
                    return normalize(float3(-hx, 2.0 * e, -hz));
                }
                const float2 ee = float2(0.00012, -0.00012);
                float3 g = ee.xyy * MapX(p + ee.xyy, false).x + ee.yyx * MapX(p + ee.yyx, false).x + ee.yxy * MapX(p + ee.yxy, false).x + ee.xxx * MapX(p + ee.xxx, false).x;
                return g / max(length(g), 1e-12);
            }

            float SoftShadow(float3 p, float3 l)
            {
                float res = 1.0;
                float t = 0.002;
                int n = clamp((int)_ShadowSteps, 8, 16);
                for (int i = 0; i < 16; i++)
                {
                    if (i >= n) break;
                    float3 sp = p + l * t;
                    if (sp.y > 0.11 || max(abs(sp.x), abs(sp.z)) > INNER) break; // いちばん高い所より上・箱の外に出たら、もう何もない
                    float h = Map(sp).x;
                    res = min(res, 14.0 * h / t);
                    t += clamp(h, 0.0012, 0.05);
                    if (res < 0.01 || t > 0.5) break;
                }
                return saturate(res);
            }

            float AmbientOcclusion(float3 p, float3 n)
            {
                float occ = 0.0;
                float w = 1.0;
                for (int i = 1; i <= 3; i++)
                {
                    float d = 0.003 * i;
                    occ += (d - Map(p + n * d).x) * w;
                    w *= 0.6;
                }
                return saturate(1.0 - occ * 30.0);
            }

            // ---------------------------------------------------------------- 仕掛け: 夕暮れと、のろし

            float Dusk() { return _Event * smoothstep(0.0, 3.0, _EventTime); }
            // k 番目の望楼に、のろしがともっている強さ (手前から順に、1.3 秒ずつ遅れて)
            float BeaconOn(int k) { return _Event * smoothstep(0.0, 0.6, _EventTime - 2.5 - k * 1.3); }
            float3 BeaconPos(int k) { float z = TOWER_Z[k]; return float3(Path(z), Crest(z) + 0.0305 * WS, z); }

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

            float3 SunDir() { return normalize(lerp(SUN_DIR, float3(0.75, 0.06, -0.65), Dusk())); }

            float3 Sky(float3 rd)
            {
                float3 L = SunDir();
                float dusk = Dusk();
                float up = saturate(rd.y);
                float3 day = lerp(float3(0.75, 0.82, 0.92), float3(0.22, 0.42, 0.8), pow(up, 0.5));
                float3 eve = lerp(float3(1.0, 0.5, 0.25), float3(0.12, 0.12, 0.3), pow(up, 0.45));
                float3 c = lerp(day, eve, dusk);
                float sd = dot(rd, L);
                c += lerp(float3(0.5, 0.45, 0.35), float3(1.2, 0.45, 0.12), dusk) * pow(saturate(sd), 10.0) * 0.6;
                c += float3(4.0, 3.2, 2.2) * smoothstep(0.9993, 0.9997, sd);
                return c;
            }

            float3 PointGlow(float3 ro, float3 rd, float tMax, float3 pos, float3 colr, float size)
            {
                float3 w = pos - ro;
                float tc = dot(w, rd);
                if (tc < 0.0 || tc > tMax + 0.002) return 0;
                float d2 = dot(w, w) - tc * tc;
                float core = max(size, tc * 0.0011);
                return colr * (exp(-d2 / (core * core)) + 0.06 * exp(-d2 / (core * core * 40.0)));
            }

            // のろしの炎と、立ちのぼる煙の柱
            float3 Beacons(float3 ro, float3 rd, float tMax)
            {
                if (_Event < 0.01) return 0;
                float3 col = 0;
                float t = _Time.y;
                [unroll] for (int k = 0; k < TOWERS; k++)
                {
                    float on = BeaconOn(k);
                    if (on < 0.01) continue;
                    float3 bp = BeaconPos(k);
                    float flick = 0.8 + 0.2 * sin(t * 13.0 + k) * sin(t * 7.7 + k * 2.0);
                    col += PointGlow(ro, rd, tMax, bp + float3(0, 0.0015, 0), float3(2.6, 1.0, 0.25) * flick * on, 0.0012);
                    // 煙: 炎の上へ、風で少し流されながら立ちのぼる、かすかな帯
                    float3 w = bp - ro;
                    float3 axis = normalize(float3(0.15, 1.0, -0.1));
                    float3 n = normalize(cross(axis, rd));
                    float dist = abs(dot(w, n));
                    float tc = dot(w, rd);
                    if (tc > 0.0 && tc < tMax)
                    {
                        float3 closest = ro + rd * tc;
                        float along = dot(closest - bp, axis);
                        float wob = 0.003 * sin(along * 90.0 - t * 2.0);
                        float width = 0.003 + along * 0.15;
                        float dd = dist + wob;
                        float smoke = exp(-dd * dd / (width * width)) * smoothstep(0.0, 0.01, along) * exp(-along * 18.0);
                        col += float3(0.22, 0.2, 0.2) * smoke * on * 0.35;
                    }
                }
                return col;
            }

            float3 Shade(float3 ro, float3 rd, float3 p, float id, float3 faceNormal)
            {
                float3 L = SunDir();
                float dusk = Dusk();
                float3 sunCol = lerp(float3(2.0, 1.85, 1.6), float3(2.0, 0.8, 0.35), dusk) * (1.0 - 0.3 * dusk);
                float3 skyTop = lerp(float3(0.28, 0.4, 0.7), float3(0.12, 0.12, 0.25), dusk);
                float3 skyLow = lerp(float3(0.55, 0.55, 0.5), float3(0.45, 0.25, 0.2), dusk);
                float3 v = -rd;

                if (id == ID_BASE)
                    return float3(0.015, 0.014, 0.014) + 0.03 * pow(saturate(1.0 - abs(dot(rd, faceNormal))), 4.0);

                float3 n = SceneNormal(p, id);
                float sh = SoftShadow(p + n * 0.0008, L);
                // 陰: 城壁と望楼だけ、まわりを調べる。山の木々は、木の頭の明暗で十分 (計算を省く)
                float ao = id == ID_GROUND ? 1.0 : AmbientOcclusion(p, n);
                float3 col;

                if (id == ID_WALL || id == ID_TOWER)
                {
                    // 灰色のれんが (37 cm × 9 cm を、1 段ずつずらして積む)。下のほうは大きな切り石
                    float d = SideDist(p.xz);
                    float y = p.y - Crest(p.z);
                    float u = abs(n.x) > abs(n.z) ? p.z : p.x;
                    if (abs(n.y) > 0.7) u = p.x + p.z;
                    float row = floor(y / 0.001);
                    float2 b = float2(u / 0.0022 + row * 0.5, y / 0.001);
                    float2 f = frac(b);
                    float joint = 1.0 - smoothstep(0.0, 0.08, min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y)));
                    float3 brick = float3(0.4, 0.38, 0.35) * (0.8 + 0.25 * Hash21(floor(b)));
                    if (y < 0.008) brick = float3(0.45, 0.42, 0.37) * (0.85 + 0.2 * Hash21(floor(b * float2(0.4, 0.5))));
                    brick *= 1.0 - 0.35 * joint;
                    // 通路の床は、すり減った明るい石畳
                    if (n.y > 0.7) brick = float3(0.48, 0.46, 0.42) * (0.85 + 0.2 * Noise3(p * 3000.0));
                    float3 nb = BumpNormal(n, p, 6000.0, 0.3);
                    col = Surface(brick, nb, v, L, sunCol, sh, ao, 0.8, 0.04, 0.0, skyTop, skyLow);
                    // のろしの炎が、望楼の上を照らす
                    [unroll] for (int k = 0; k < TOWERS; k++)
                    {
                        float on = BeaconOn(k);
                        if (on > 0.01) col += brick * float3(2.0, 0.8, 0.25) * on * 0.8 * exp(-length(p - BeaconPos(k)) / 0.012);
                    }
                    return col;
                }

                if (max(abs(p.x), abs(p.z)) > INNER - 0.0015 && abs(n.y) < 0.5)
                    return Surface(float3(0.35, 0.3, 0.25) * (0.8 + 0.4 * Noise3(p * 900.0)), n, v, L, sunCol, 1.0, 1.0, 0.9, 0.03, 0.0, skyTop, skyLow); // 切り口

                // 秋の山: 木々のこんもりした頭。赤・橙・黄の紅葉と、緑の松。急な所は灰色の岩
                // 色の群れ: 赤・橙・黄・松の緑が、大きなまだらに混ざる。こまかい木の頭の明暗
                float m1 = Noise3(p * 160.0), m2 = Noise3(p * 300.0 + 7.0);
                float3 red = float3(0.36, 0.07, 0.03), orange = float3(0.46, 0.2, 0.05), yellow = float3(0.5, 0.38, 0.08), pine = float3(0.06, 0.14, 0.05);
                float3 leaf = lerp(lerp(red, orange, smoothstep(0.35, 0.55, m1)), yellow, smoothstep(0.6, 0.8, m1));
                leaf = lerp(leaf, pine, smoothstep(0.5, 0.75, m2) * 0.8);
                float crown = Noise3(p * 2500.0) * 0.6 + Noise3(p * 900.0) * 0.4;
                leaf *= 0.45 + 0.75 * crown;
                float steep = 1.0 - smoothstep(0.35, 0.6, n.y);
                float rocky = steep * smoothstep(0.55, 0.7, Noise3(p * 180.0)) * 0.8;
                float3 rock = float3(0.38, 0.36, 0.33) * (0.75 + 0.35 * Noise3(p * 1500.0));
                // 城壁のすぐ足元は、木を切った土と草
                float near = 1.0 - smoothstep(0.008, 0.015, abs(SideDist(p.xz)));
                float3 albedo = lerp(lerp(leaf, rock, rocky), float3(0.3, 0.26, 0.16), near * 0.8);
                float3 nb = BumpNormal(n, p, 2500.0, 1.4 - rocky * 0.8);
                col = Surface(albedo, nb, v, L, sunCol, sh, ao, 0.85, 0.03, 0.4 * (1.0 - rocky), skyTop, skyLow);
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

                const float maxHeight = 0.11; // いちばん高い望楼より少し上
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
                // 高さの表で当たった地面を、正確な式で合わせ直す (2 点を結ぶ直線で、2 回)
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

                // 遠くほど、青くかすむ (夕暮れは橙に)
                float travel = tHit - max(box.x, 0.0);
                float3 hazeCol = lerp(float3(0.6, 0.68, 0.82), float3(0.75, 0.45, 0.35), Dusk());
                if (hit) col = lerp(col, hazeCol, (1.0 - exp(-travel * 1.0)) * 0.3);

                // 雲海: 層 (上面 FOG_Y) の中を通る長さで濃さを決める。上面のもこもこは、入った所のノイズ 1 回で
                if (hit || !outside)
                {
                    float tIn = max(box.x, 0.0), tOut = tHit;
                    if (ro.y > FOG_Y) tIn = rd.y < 0.0 ? max(tIn, (FOG_Y - ro.y) / rd.y) : 1e5;
                    else if (rd.y > 0.0) tOut = min(tOut, (FOG_Y - ro.y) / rd.y);
                    if (tOut > tIn)
                    {
                        float3 ep = ro + rd * tIn;
                        float puff = 0.6 + 0.8 * Noise3(float3(ep.xz * 25.0, _Time.y * 0.03));
                        float a = 1.0 - exp(-(tOut - tIn) * 45.0 * puff);
                        float3 fogCol = lerp(float3(0.95, 0.95, 0.97), float3(1.0, 0.62, 0.45), Dusk()) * (0.85 + 0.15 * puff);
                        col = lerp(col, fogCol, a);
                    }
                }

                col += Beacons(ro, rd, tHit);

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
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input); // VR: 左右どちらの目を描いているか
                return input.positionCS.z;
            }
            ENDHLSL
        }
    }
}
