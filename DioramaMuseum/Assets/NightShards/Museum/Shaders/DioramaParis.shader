// 作品「夜のパリ」(ヨーロッパの間)。凱旋門からのびる光の大通りと、セーヌ川の向こうで輝くエッフェル塔。URP 用。
// Cube の中をレイマーチングして描く。Cube の座標は -0.5〜0.5、下の 0.08 は黒い台。
//
// 見どころ:
//   ・手前に凱旋門と、まわりの円い広場 (エトワール)
//   ・凱旋門から奥へまっすぐのびるシャンゼリゼ通り。車のヘッドライト (白) とテールライト (赤) が光の川になって流れる。並木と街灯
//   ・通りの両側に、石造りのアパルトマン (クリーム色の石の壁、青灰色の亜鉛のマンサード屋根)。窓のあちこちに灯り
//   ・奥のセーヌ川と、その向こうで金色に輝くエッフェル塔。川面には、塔と街灯の光が揺れて映る
// 仕掛け (_Event 0〜1): エッフェル塔が白いフラッシュでキラキラきらめき、頂上の 2 本のサーチライトが夜空をぐるりと照らす
//
// 外から見たとき、街のない所 (空) は透明にして、ガラスケースの向こうの部屋が見えるようにする。
// 中に入ったとき (カメラが箱の中) だけ、夜空を描く
Shader "NightShards/Diorama/Paris"
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

            #define ID_BASE     0.0
            #define ID_GROUND   1.0
            #define ID_WATER    2.0
            #define ID_BUILDING 3.0
            #define ID_ARC      4.0
            #define ID_EIFFEL   5.0
            #define ID_TREE     6.0

            #define INNER 0.47
            #define GROUND -0.3          // 街の地面の高さ
            #define CELL 0.06            // 街区のます目の大きさ
            #define CARS 24
            #define EIFFEL_H 0.56        // エッフェル塔の高さ
            static const float3 ARC = float3(0.0, -0.3, 0.27);     // 凱旋門の場所
            static const float3 EIFFEL = float3(-0.12, -0.3, -0.32); // エッフェル塔の場所
            static const float3 MOON_DIR = float3(0.4, 0.55, -0.7);

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

            // だ円体 (近い値の距離)
            float SdEllipsoidLite(float3 p, float3 r)
            {
                float k0 = length(p / r);
                float k1 = length(p / (r * r));
                return k0 * (k0 - 1.0) / max(k1, 1e-6);
            }

            float Hash11(float n) { return frac(sin(n * 127.1) * 43758.5453); }

            // ---------------------------------------------------------------- 街の作り
            // ※ BlockHeight と、街区を置く条件 (BlockAllowed) を変えたら、C# の DioramaTerrain も同じに直す (当たり判定)

            bool InRiver(float z) { return z > -0.19 && z < -0.12; }

            // そのます目に建物を建てるか。通り・広場・川・エッフェル塔の公園には建てない
            bool BlockAllowed(float2 c)
            {
                if (abs(c.x) > 0.44 || abs(c.y) > 0.44) return false;
                if (abs(c.x) < 0.05 && c.y > -0.12) return false;                // シャンゼリゼ通り
                if (length(c - ARC.xz) < 0.11) return false;                     // 凱旋門の広場
                if (c.y > -0.22 && c.y < -0.09) return false;                    // セーヌ川
                if (c.x > -0.32 && c.x < 0.08 && c.y < -0.2) return false;       // シャン・ド・マルス公園
                return Hash21(c * 7.3 + _Seed) < 0.92;                           // ところどころ小さな広場
            }

            float BlockHeight(float2 c) { return 0.045 + 0.02 * Hash21(c * 3.1 + _Seed + 5.0); }

            // 街の地面: 川の所だけ低い
            float GroundY(float2 xz)
            {
                float river = smoothstep(0.004, 0.0, max(-0.19 - xz.y, xz.y + 0.12));
                return GROUND - 0.03 * river;
            }

            // アパルトマン: 石の壁の箱と、斜めに切ったマンサード屋根。ます目の中だけを調べる
            float Blocks(float3 p, out float2 cellCenter)
            {
                float2 cell = floor(p.xz / CELL);
                cellCenter = (cell + 0.5) * CELL;
                float2 local = p.xz - cellCenter;
                float2 toEdge = 0.5 * CELL - abs(local);
                float bound = max(min(toEdge.x, toEdge.y), 0.0) + 0.002;
                if (!BlockAllowed(cellCenter)) return bound;
                float h = BlockHeight(cellCenter);
                float y = p.y - GROUND;
                if (y > h + 0.01) return min(y - h, bound);
                float body = SdBox(float3(local.x, y - h * 0.5, local.y), float3(0.022, h * 0.5, 0.022));
                float mansard = ((max(abs(local.x), abs(local.y)) - 0.015) + (y - h)) * 0.707;
                return min(max(body, mansard), bound);
            }

            // 凱旋門: 大きな箱に、前後に抜ける大きなアーチと、左右に抜ける小さなアーチ
            float Arc(float3 p)
            {
                float3 q = p - ARC;
                float body = SdBox(q - float3(0, 0.025, 0), float3(0.024, 0.025, 0.012));
                float attic = SdBox(q - float3(0, 0.0475, 0), float3(0.0255, 0.0025, 0.0135)); // 上のでっぱり
                float mainArch = min(length(q.xy - float2(0, 0.021)) - 0.009, SdBox(q - float3(0, 0.0105, 0), float3(0.009, 0.0105, 1.0)));
                float sideArch = min(length(q.zy - float2(0, 0.012)) - 0.0045, SdBox(q - float3(0, 0.006, 0), float3(1.0, 0.006, 0.0045)));
                return max(min(body, attic), -min(mainArch, sideArch));
            }

            // エッフェル塔の、高さ y での半分の幅 (下ほど大きく開く)
            float EiffelW(float y) { return 0.075 * exp(-y * 5.2) + 0.002; }

            // エッフェル塔: 下は 4 本の脚、上は 1 本の柱になって細くなる。3 つの展望台
            float Eiffel(float3 p)
            {
                float3 q = p - EIFFEL;
                float y = q.y;
                float2 a = abs(q.xz);
                if (max(a.x, a.y) > 0.1 || y > EIFFEL_H + 0.02) return max(max(a.x, a.y) - 0.09, y - EIFFEL_H - 0.01); // 遠い所は、塔を包む箱までの距離
                float w = EiffelW(y);
                float d;
                if (y < 0.19)
                {
                    float c = w * 0.82;
                    float s = 0.011 * exp(-y * 4.0) + 0.003;
                    float2 l = abs(a - c) - s;
                    d = length(max(l, 0.0)) + min(max(l.x, l.y), 0.0);
                }
                else
                {
                    d = max(a.x, a.y) - w;
                }
                d = max(d * 0.7, max(-y, y - EIFFEL_H));
                float lv1 = SdBox(float3(a.x, y - 0.095, a.y) - float3(0, 0, 0), float3(EiffelW(0.095) + 0.006, 0.003, EiffelW(0.095) + 0.006));
                float lv2 = SdBox(float3(a.x, y - 0.19, a.y), float3(EiffelW(0.19) + 0.004, 0.0025, EiffelW(0.19) + 0.004));
                float lv3 = SdBox(float3(a.x, y - 0.5, a.y), float3(EiffelW(0.5) + 0.003, 0.002, EiffelW(0.5) + 0.003));
                return min(d, min(lv1, min(lv2, lv3)));
            }

            // シャンゼリゼ通りの並木 (丸い木が 2 列)
            float Trees(float3 p)
            {
                float side = abs(p.x) - 0.045;
                if (abs(side) > 0.012 || p.z < -0.1 || p.z > 0.19 || p.y > GROUND + 0.02) return max(max(abs(side) - 0.01, p.y - GROUND - 0.018), 0.003);
                float z = p.z - (round(p.z / 0.014) * 0.014);
                float3 q = float3(side, p.y - GROUND - 0.009, z);
                float crown = length(q * float3(1.0, 1.2, 1.0)) - 0.0055;
                float trunk = max(length(q.xz) - 0.0006, abs(q.y + 0.006) - 0.004);
                return min(crown, trunk);
            }

            // ---------------------------------------------------------------- 世界の形

            float2 Map(float3 p)
            {
                float2 res = float2(SdBox(p - float3(0, -0.46, 0), float3(0.5, 0.04, 0.5)), ID_BASE);
                float column = SdBox(p - float3(0, 0.04, 0), float3(INNER, 0.46, INNER));
                float ground = max((p.y - GroundY(p.xz)) * 0.8, column);
                if (ground < res.x) res = float2(ground, ID_GROUND);
                float water = max(max(p.y - (GROUND - 0.012), max(-0.188 - p.z, p.z + 0.122)), column);
                if (water < res.x) res = float2(water, ID_WATER);
                float2 cc;
                float b = max(Blocks(p, cc), column);
                if (b < res.x) res = float2(b, ID_BUILDING);
                float arc = Arc(p);
                if (arc < res.x) res = float2(arc, ID_ARC);
                float eiffel = Eiffel(p);
                if (eiffel < res.x) res = float2(eiffel, ID_EIFFEL);
                float trees = Trees(p);
                if (trees < res.x) res = float2(trees, ID_TREE);
                return res;
            }

            float3 SceneNormal(float3 p)
            {
                const float2 e = float2(0.0004, -0.0004);
                float3 g = e.xyy * Map(p + e.xyy).x + e.yyx * Map(p + e.yyx).x + e.yxy * Map(p + e.yxy).x + e.xxx * Map(p + e.xxx).x;
                return g / max(length(g), 1e-7);
            }

            float AmbientOcclusion(float3 p, float3 n)
            {
                float occ = 0.0;
                float w = 1.0;
                for (int i = 1; i <= 4; i++)
                {
                    float d = 0.006 * i;
                    occ += (d - Map(p + n * d).x) * w;
                    w *= 0.6;
                }
                return saturate(1.0 - occ * 18.0);
            }

            // ---------------------------------------------------------------- 光 (車・街灯・サーチライト)

            float SegmentDist2(float3 ro, float3 rd, float3 a, float3 b, out float sc, out float k)
            {
                float3 s = b - a;
                float len = length(s);
                s /= max(len, 1e-6);
                float3 w0 = ro - a;
                float bb = dot(rd, s);
                float dd = dot(rd, w0);
                float e = dot(s, w0);
                float den = 1.0 - bb * bb;
                sc = den > 0.0001 ? (bb * e - dd) / den : 0.0;
                float u = clamp(den > 0.0001 ? (e - bb * dd) / den : 0.0, 0.0, len);
                k = u / max(len, 1e-6);
                float3 diff = ro + rd * sc - (a + s * u);
                return dot(diff, diff);
            }

            float3 PointGlow(float3 ro, float3 rd, float tMax, float3 pos, float3 colr, float size)
            {
                float3 w = pos - ro;
                float tc = dot(w, rd);
                if (tc < 0.0 || tc > tMax + 0.002) return 0;
                float d2 = dot(w, w) - tc * tc;
                float core = max(size, tc * 0.0011);
                return colr * (exp(-d2 / (core * core)) + 0.04 * exp(-d2 / (core * core * 30.0)));
            }

            float3 Lights(float3 ro, float3 rd, float tMax)
            {
                float3 col = 0;
                float t = _Time.y;
                // 車: 左の車線は手前へ来る (白いヘッドライト)、右の車線は奥へ行く (赤いテールライト)。ライトは 2 つずつ
                for (int i = 0; i < CARS; i++)
                {
                    float fi = i;
                    bool toward = (i % 2) == 0;
                    float u = frac(t * (0.025 + 0.01 * Hash11(fi)) + Hash11(fi + 3.0));
                    float z = toward ? lerp(-0.1, 0.19, u) : lerp(0.19, -0.1, u);
                    float x = toward ? -0.012 - 0.008 * step(0.5, Hash11(fi + 5.0)) : 0.012 + 0.008 * step(0.5, Hash11(fi + 6.0));
                    float3 colr = toward ? float3(1.6, 1.5, 1.3) : float3(1.6, 0.12, 0.06);
                    col += PointGlow(ro, rd, tMax, float3(x - 0.002, GROUND + 0.002, z), colr, 0.0007);
                    col += PointGlow(ro, rd, tMax, float3(x + 0.002, GROUND + 0.002, z), colr, 0.0007);
                }
                // 街灯: 通りの両側と、川岸に並ぶ
                for (int k = 0; k < 11; k++)
                {
                    float z = -0.095 + k * 0.028;
                    col += PointGlow(ro, rd, tMax, float3(-0.033, GROUND + 0.011, z), float3(1.8, 1.2, 0.6), 0.0008);
                    col += PointGlow(ro, rd, tMax, float3(0.033, GROUND + 0.011, z), float3(1.8, 1.2, 0.6), 0.0008);
                }
                for (int q = 0; q < 12; q++)
                {
                    float x = -0.42 + q * 0.076;
                    col += PointGlow(ro, rd, tMax, float3(x, GROUND + 0.01, -0.117), float3(1.8, 1.2, 0.6), 0.0008);
                    col += PointGlow(ro, rd, tMax, float3(x + 0.038, GROUND + 0.01, -0.193), float3(1.8, 1.2, 0.6), 0.0008);
                }
                // サーチライト: エッフェル塔の頂上から、2 本の光の帯が夜空を回る (仕掛けの最中)
                if (_Event > 0.01)
                {
                    float3 top = EIFFEL + float3(0, 0.53, 0);
                    for (int b = 0; b < 2; b++)
                    {
                        float a = t * 0.8 + b * 3.1416;
                        float3 dir = normalize(float3(cos(a), -0.06, sin(a)));
                        float sc, kk;
                        float d2 = SegmentDist2(ro, rd, top, top + dir * 0.7, sc, kk);
                        if (sc < 0.0 || sc > tMax) continue;
                        float width = 0.004 + kk * 0.03;
                        col += float3(1.2, 1.1, 0.9) * exp(-d2 / (width * width)) * (1.0 - kk) * 0.35 * _Event;
                    }
                }
                return col;
            }

            // エッフェル塔の金色の光を、川面に映ったように足す (反射した線と塔の中心の線の近さから)
            float3 EiffelReflection(float3 ro, float3 rd)
            {
                float3 w0 = ro - EIFFEL;
                float b = rd.y;
                float den = 1.0 - b * b;
                if (den < 0.0001) return 0;
                float sc = (b * w0.y - dot(rd, w0)) / den;
                if (sc < 0.0) return 0;
                float3 pt = ro + rd * sc;
                float y = pt.y - EIFFEL.y;
                if (y < 0.0 || y > EIFFEL_H) return 0;
                float2 dxz = pt.xz - EIFFEL.xz;
                float w = EiffelW(y);
                return float3(1.8, 1.1, 0.4) * exp(-dot(dxz, dxz) / (w * w)) * 0.7;
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

            // ---------------------------------------------------------------- 色を塗る

            float3 Sky(float3 rd)
            {
                float up = saturate(rd.y);
                float3 c = lerp(float3(0.12, 0.07, 0.1), float3(0.01, 0.012, 0.035), sqrt(up)); // 地平線は街の灯りでほんのり明るい
                float3 sp = rd * 220.0;
                float3 cell = floor(sp);
                c += step(0.995, Hash31(cell)) * smoothstep(0.25, 0.1, length(frac(sp) - 0.5)) * smoothstep(0.1, 0.4, rd.y) * 0.6;
                float3 md = normalize(MOON_DIR);
                float mc = dot(rd, md);
                c += float3(1.8, 1.8, 1.7) * smoothstep(0.99955, 0.9997, mc) + float3(0.3, 0.32, 0.4) * pow(saturate(mc), 60.0) * 0.1;
                return c;
            }

            float3 Shade(float3 ro, float3 rd, float3 p, float id, float3 faceNormal, float tHit)
            {
                float3 L = normalize(MOON_DIR);
                float3 moonCol = float3(0.12, 0.14, 0.2);
                float3 skyTop = float3(0.02, 0.025, 0.05);
                float3 skyLow = float3(0.12, 0.08, 0.1);
                float3 v = -rd;
                float t = _Time.y;
                float y = p.y - GROUND;
                // 街灯の暖かい光: 地面に近いほど強い
                float3 street = float3(1.0, 0.62, 0.3) * 0.35 * exp(-max(y, 0.0) / 0.025);

                if (id == ID_BASE)
                    return float3(0.015, 0.014, 0.014) + 0.03 * pow(saturate(1.0 - abs(dot(rd, faceNormal))), 4.0);

                float3 n = SceneNormal(p);
                float ao = AmbientOcclusion(p, n);

                if (id == ID_WATER)
                {
                    // セーヌ川: 暗い水面に、エッフェル塔と街灯の光が揺れて映る
                    float2 q = p.xz * float2(60.0, 200.0);
                    float2 slope = (float2(ValueNoise(q + t * 0.5), ValueNoise(q.yx - t * 0.6)) - 0.5) * 0.12;
                    float3 wn = normalize(float3(slope.x, 1.0, slope.y));
                    float3 r = reflect(rd, wn);
                    float fres = 0.04 + 0.96 * pow(1.0 - saturate(dot(v, wn)), 5.0);
                    float3 refl = Sky(r) + EiffelReflection(p, r) + Lights(p + r * 0.001, r, 1.0) * 0.6;
                    return float3(0.01, 0.015, 0.02) + refl * (0.3 + 0.7 * fres);
                }

                if (id == ID_EIFFEL)
                {
                    // エッフェル塔: 鉄の格子が金色の照明で光る。仕掛けの最中は、白いフラッシュがキラキラまたたく
                    float3 q = p - EIFFEL;
                    float u = abs(n.x) > abs(n.z) ? q.z : q.x;
                    float k = 260.0;
                    float l1 = abs(frac((u + q.y) * k) - 0.5);
                    float l2 = abs(frac((u - q.y) * k) - 0.5);
                    float lattice = smoothstep(0.38, 0.5, max(l1, l2));
                    float3 iron = float3(0.18, 0.12, 0.08);
                    float3 col = Surface(iron, n, v, L, moonCol, 1.0, ao, 0.5, 0.06, 0.0, skyTop, skyLow);
                    col += float3(1.6, 0.95, 0.35) * (0.35 + 1.2 * lattice) * (0.85 + 0.15 * smoothstep(0.0, 0.1, q.y));
                    float2 cell = floor(float2(u, q.y) * 300.0);
                    float sparkle = step(0.93, Hash21(cell + floor(t * 12.0) * 0.37)) * _Event;
                    col += float3(4.0, 4.0, 4.5) * sparkle;
                    return col;
                }

                if (id == ID_ARC)
                {
                    // 凱旋門: 白っぽい石。下から照らされて、浮き上がって見える
                    float3 nb = BumpNormal(n, p, 1500.0, 0.5);
                    float3 stone = float3(0.82, 0.78, 0.68);
                    float3 col = Surface(stone, nb, v, L, moonCol, 1.0, ao, 0.6, 0.04, 0.0, skyTop, skyLow);
                    col += stone * float3(1.4, 1.0, 0.6) * 0.45 * exp(-max(p.y - ARC.y, 0.0) / 0.04);
                    return col;
                }

                if (id == ID_TREE)
                {
                    float3 albedo = float3(0.08, 0.14, 0.06) * (0.8 + 0.4 * Noise3(p * 900.0));
                    return Surface(albedo, BumpNormal(n, p, 1200.0, 0.8), v, L, moonCol, 1.0, ao, 0.8, 0.03, 0.3, skyTop, skyLow) + albedo * street * 3.0;
                }

                if (id == ID_BUILDING)
                {
                    float2 cc;
                    Blocks(p, cc);
                    float h = BlockHeight(cc);
                    if (y > h - 0.0075 && n.y > 0.3)
                    {
                        // マンサード屋根: 青灰色の亜鉛。夜空を少し映す。小さな屋根窓に灯り
                        float3 zinc = float3(0.25, 0.28, 0.32);
                        float3 col = Surface(zinc, n, v, L, moonCol, 1.0, ao, 0.35, 0.3, 0.0, skyTop, skyLow);
                        float dormer = step(0.6, frac((p.x + p.z) * 250.0)) * step(abs(y - (h - 0.004)), 0.0012) * step(0.6, Hash21(floor((p.x + p.z) * 250.0) + cc));
                        return col + float3(1.4, 0.9, 0.45) * dormer * 0.6;
                    }
                    // 石の壁と窓: 階ごと・窓ごとに、灯りがついていたり消えていたり
                    float u = abs(n.x) > abs(n.z) ? p.z : p.x;
                    float fu = u / 0.0045, fy = y / 0.0065;
                    float2 wq = frac(float2(fu, fy));
                    float window = step(0.3, wq.x) * step(wq.x, 0.7) * step(0.25, wq.y) * step(wq.y, 0.8);
                    float lit = step(0.45, Hash21(floor(float2(fu, fy)) + cc * 13.0));
                    float shop = step(y, 0.006); // 1 階はお店。明るい
                    float3 stone = float3(0.78, 0.72, 0.6) * (0.9 + 0.1 * Noise3(p * 1200.0));
                    float3 glass = float3(0.02, 0.025, 0.035);
                    float3 albedo = lerp(stone, glass, window);
                    float3 col = Surface(albedo, n, v, L, moonCol, 1.0, ao, lerp(0.7, 0.1, window), lerp(0.04, 0.08, window), 0.0, skyTop, skyLow);
                    col += stone * street * (1.0 - window);
                    col += float3(1.6, 1.0, 0.45) * window * max(lit, shop) * (0.6 + 0.6 * shop);
                    return col;
                }

                // 地面: 通りは濡れたようにつやのある石畳で、車と街灯の光を映す。公園は芝生
                bool park = p.x > -0.32 && p.x < 0.08 && p.z < -0.2;
                bool road = (abs(p.x) < 0.035 && p.z > -0.12) || abs(length(p.xz - ARC.xz) - 0.085) < 0.022;
                float3 albedo = park ? float3(0.08, 0.14, 0.06) : (road ? float3(0.06, 0.06, 0.065) : float3(0.25, 0.23, 0.2));
                float rough = park ? 0.85 : (road ? 0.15 : 0.6);
                float3 col = Surface(albedo, BumpNormal(n, p, 2000.0, road ? 0.15 : 0.6), v, L, moonCol, 1.0, ao, rough, 0.04, 0.0, skyTop, skyLow);
                col += albedo * street * 2.5;
                if (road)
                {
                    // 濡れた通りに映る光: 反射した線の先にある車のライトと街灯を、ぼんやり足す
                    float3 r = reflect(rd, BumpNormal(n, p, 900.0, 0.08));
                    col += Lights(p + r * 0.001, r, 0.5) * 0.35;
                }
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

                const float maxHeight = 0.28; // エッフェル塔のてっぺん
                if (ro.y > maxHeight && rd.y < 0.0) t = max(t, (maxHeight - ro.y) / rd.y);

                bool hit = false;
                float id = 0.0;
                int steps = (int)_Steps;
                for (int i = 0; i < 200; i++)
                {
                    if (i >= steps || t > box.y) break;
                    float3 pos = ro + rd * t;
                    if (rd.y > 0.0 && pos.y > maxHeight + 0.01) break;
                    float2 m = Map(pos);
                    if (m.x < 0.00015 * (1.0 + t))
                    {
                        hit = true;
                        id = m.y;
                        break;
                    }
                    t += m.x;
                }
                float tHit = hit ? t : box.y;

                float3 col = 0;
                if (hit) col = Shade(ro, rd, ro + rd * t, id, faceNormal, tHit);
                else if (!outside) col = Sky(rd);

                // 夜の街の霞: 遠くほど、街の灯りでほんのり明るい紫がかった空気に沈む
                float travel = tHit - max(box.x, 0.0);
                if (hit) col = lerp(col, float3(0.06, 0.04, 0.05), (1.0 - exp(-travel * 0.7)) * 0.5);

                float alpha = (hit || !outside) ? 1.0 : 0.0;
                col += Lights(ro, rd, tHit);

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
