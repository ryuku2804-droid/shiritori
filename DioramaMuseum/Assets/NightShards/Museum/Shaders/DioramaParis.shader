// 作品「夜のパリ」(ヨーロッパの間)。夜のエッフェル塔と凱旋門だけを、大きく実物どおりに作った。URP 用。
// Cube の中をレイマーチングして描く。Cube の座標は -0.5〜0.5、下の 0.08 は黒い台。
//
// 形は実物の寸法 (1 m = 0.001) で作り、置くときに大きくする (エッフェル塔は 2.2 倍、凱旋門は 3 倍)。
//   ・エッフェル塔 (高さ 300 m・アンテナ込み 330 m・土台 125 m 四方): 4 本の格子の脚が 2 階の上で 1 本になる。
//     3 つの展望台と、脚の間の飾りアーチ。格子は本当に穴が空いていて、向こうがすけて見える。足元はシャン・ド・マルスの芝生
//   ・凱旋門 (高さ 50 m・幅 45 m・奥行き 22 m): 大アーチと左右に抜ける小アーチ、軒、30 の盾の帯、4 つの彫刻群、
//     アーチの天井の格間、無名戦士の墓の炎。まわりのエトワール広場の石畳を、車のライトがぐるぐる回る
// 仕掛け (_Event 0〜1): エッフェル塔が白いフラッシュでキラキラきらめき、頂上の灯台の光が強くなる
//
// 外から見たとき、何もない所 (空) は透明にして、ガラスケースの向こうの部屋が見えるようにする。
// 中に入ったとき (カメラが箱の中) だけ、夜空を描く
Shader "NightShards/Diorama/Paris"
{
    Properties
    {
        _Steps ("Ray Steps", Range(16, 200)) = 150
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
            #pragma use_dxc vulkan // Quest (Vulkan) 用は新しいコンパイラー (DXC) で変換する。古いほうだと大きいシェーダーが時間切れになる
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

            // ---------------------------------------------------------------- 寸法と置き場所
            // ※ 置き場所・倍率を変えたら、C# の DioramaTerrain (ParisProps) も同じに直す (当たり判定)

            #define GROUND -0.3
            #define CARS 16
            #define ES 2.2                 // エッフェル塔を大きくする倍率 (1 m = 0.0022)
            #define AS 3.0                 // 凱旋門を大きくする倍率 (1 m = 0.003)
            #define RING_IN 0.1            // 凱旋門のまわりの、車が回る環状の道 (内側の半径)
            #define RING_OUT 0.13          // 〃 (外側の半径)
            #define PLAZA 0.16             // エトワール広場の半径
            static const float3 ARC = float3(0.14, -0.3, 0.25);      // 凱旋門 (エトワール広場の中心)
            static const float3 EIFFEL = float3(-0.07, -0.3, -0.17);  // エッフェル塔の中心
            static const float3 MOON_DIR = float3(0.4, 0.55, -0.7);

            float Hash11(float n) { return frac(sin(n * 127.1) * 43758.5453); }

            // 置いた場所 → 形を作った座標 (実物の寸法)。形は大きく見せたいので、逆に縮めて調べる
            float3 ToArc(float3 p) { return ARC + (p - ARC) / AS; }
            float3 ToEiffel(float3 p) { return EIFFEL + (p - EIFFEL) / ES; }

            // 広場から塔へ向かう道の、真ん中の線からの距離と、道にそった位置 (0〜1)
            float PathDist(float2 xz, out float k)
            {
                float2 a = ARC.xz, b = EIFFEL.xz;
                float2 ab = b - a;
                k = saturate(dot(xz - a, ab) / dot(ab, ab));
                return length(xz - (a + ab * k));
            }

            // ---------------------------------------------------------------- 凱旋門 (高さ 50 m・幅 45 m・奥行き 22 m)

            float Arc(float3 p, out float part)
            {
                float3 q = p - ARC;
                part = 0;
                if (max(abs(q.x) - 0.026, max(abs(q.z) - 0.014, q.y - 0.052)) > 0.004) return max(abs(q.x) - 0.025, max(abs(q.z) - 0.013, q.y - 0.051));
                float body = SdBox(q - float3(0, 0.025, 0), float3(0.0225, 0.025, 0.011));
                // 大アーチ: 幅 14.6 m・高さ 29.2 m (前後に抜ける)。小アーチ: 幅 8.4 m・高さ 18.7 m (左右に抜ける)
                float mainArch = min(length(q.xy - float2(0, 0.0219)) - 0.0073, SdBox(q - float3(0, 0.01095, 0), float3(0.0073, 0.01095, 1.0)));
                float sideArch = min(length(q.zy - float2(0, 0.0145)) - 0.0042, SdBox(q - float3(0, 0.00725, 0), float3(1.0, 0.00725, 0.0042)));
                float d = max(body, -min(mainArch, sideArch));
                // 軒の張り出し (コーニス) と、その下の帯 (フリーズ)、台座
                float cornice = SdBox(q - float3(0, 0.0383, 0), float3(0.0232, 0.0008, 0.0117));
                float frieze = SdBox(q - float3(0, 0.0355, 0), float3(0.0228, 0.002, 0.0113));
                float plinth = max(SdBox(q - float3(0, 0.0012, 0), float3(0.0229, 0.0012, 0.0115)), -min(mainArch, sideArch));
                d = min(d, min(cornice, min(frieze, plinth)));
                // 4 つの彫刻群: 正面と裏の、柱の面に浮き出る (ラ・マルセイエーズなど)
                float3 sq = float3(abs(q.x) - 0.0149, q.y - 0.0105, abs(q.z) - 0.0118);
                float sculpture = SdBox(sq, float3(0.0045, 0.0062, 0.0016)) - 0.0009 * Noise3(q * 3000.0);
                // 大アーチの付け根の帯 (インポスト) と、柱の上の帯
                float impost = max(SdBox(q - float3(0, 0.0219, 0), float3(0.0229, 0.0005, 0.0115)), -min(mainArch, sideArch));
                d = min(d, impost);
                if (sculpture < d) part = 1;
                return min(d, sculpture);
            }

            // ---------------------------------------------------------------- エッフェル塔 (高さ 300 m・アンテナ込み 330 m・土台 125 m 四方)

            // 高さ y での、塔の外側の半分の幅。展望台 (57.6 m・115.7 m・276 m) での実物の幅に合わせた
            float EiffelW(float y)
            {
                if (y < 0.1157) return 0.0625 * exp(-9.75 * y);
                return 0.0202 * exp(-4.86 * (y - 0.1157));
            }

            // 鉄の格子: 面の上の位置 (u, y) で、X 字の筋交いと横の梁だけが残る。残りは穴 (向こうがすけて見える)
            float Lattice(float u, float y, float period)
            {
                float s1 = abs(frac((u + y * 0.9) / period) - 0.5) * period;
                float s2 = abs(frac((u - y * 0.9) / period) - 0.5) * period;
                float diag = min(s1, s2) * 0.67 - 0.0002;
                float beam = abs(frac(y / 0.008) - 0.5) * 0.008 - 0.00022;
                return min(diag, beam);
            }

            // 箱の形の筒 (半分の大きさ half) を、格子の面で作る。d2 は筒の中心からの位置
            float LatticeTube(float2 d2, float y, float hs)
            {
                float2 l = abs(d2) - hs;
                float box = length(max(l, 0.0)) + min(max(l.x, l.y), 0.0);
                float shell = abs(box) - 0.0004;
                float u = abs(d2.x) > abs(d2.y) ? d2.y : d2.x;
                float lattice = max(shell, Lattice(u, y, 0.007));
                float corners = length(abs(d2) - hs) - 0.0009;  // 角の太い柱
                return min(lattice, corners);
            }

            float Eiffel(float3 p, out float part)
            {
                float3 q = p - EIFFEL;
                float y = q.y;
                float2 a = abs(q.xz);
                part = 0;
                if (max(a.x, a.y) > 0.07 || y > 0.335 || y < -0.01) return max(max(max(a.x, a.y) - 0.065, y - 0.332), 0.002);
                float w = EiffelW(y);
                float d;
                if (y < 0.1157)
                {
                    // 4 本の脚: 外側の角は塔の輪郭に沿い、上へ行くほど細くなる格子の柱
                    float lh = lerp(0.013, 0.007, y / 0.1157);
                    d = LatticeTube(a - (w - lh), y, lh) * 0.75; // 脚は斜めなので、少し小さめに進む
                }
                else if (y < 0.28)
                {
                    d = LatticeTube(q.xz, y, w); // 2 階から上は、4 本が 1 本にまとまる
                }
                else
                {
                    // てっぺんの塔屋と、アンテナ
                    float house = SdBox(float3(q.x, y - 0.29, q.z), float3(0.0045, 0.01, 0.0045));
                    float antenna = max(length(q.xz) - 0.0007, abs(y - 0.315) - 0.017);
                    d = min(house, antenna);
                }
                d = max(d, -y);
                // 展望台: 1 階 (57.6 m)・2 階 (115.7 m)・3 階 (276 m)
                float lv1 = SdBox(float3(a.x, y - 0.0576, a.y), float3(EiffelW(0.0576) + 0.002, 0.0035, EiffelW(0.0576) + 0.002));
                lv1 = max(lv1, -SdBox(float3(a.x, y - 0.0576, a.y), float3(0.012, 0.01, 0.012))); // 1 階は真ん中が吹き抜け
                float lv2 = SdBox(float3(a.x, y - 0.1157, a.y), float3(EiffelW(0.1157) + 0.0015, 0.0025, EiffelW(0.1157) + 0.0015));
                float lv3 = SdBox(float3(a.x, y - 0.276, a.y), float3(EiffelW(0.276) + 0.0012, 0.002, EiffelW(0.276) + 0.0012));
                float levels = min(lv1, min(lv2, lv3));
                if (levels < d) part = 1;
                d = min(d, levels);
                // 脚と脚の間の飾りアーチ (4 面)
                float2 face = a.x > a.y ? float2(q.z, a.x) : float2(q.x, a.y);
                float ring = abs(length(float2(face.x, y + 0.002)) - 0.052) - 0.0012;
                float arch = max(ring, max(abs(face.y - 0.042) - 0.0007, 0.012 - y));
                arch = max(arch, y - 0.054);
                if (arch < d) part = 2;
                return min(d, arch);
            }

            // ---------------------------------------------------------------- 世界の形

            #define ID_BASE     0.0
            #define ID_GROUND   1.0
            #define ID_ARC      2.0
            #define ID_EIFFEL   3.0

            float2 Map(float3 p)
            {
                float2 res = float2(SdBox(p - float3(0, -0.46, 0), float3(0.5, 0.04, 0.5)), ID_BASE);
                float column = SdBox(p - float3(0, 0.04, 0), float3(INNER, 0.46, INNER));
                float ground = max(p.y - GROUND, column);
                if (ground < res.x) res = float2(ground, ID_GROUND);
                float part;
                float arc = Arc(ToArc(p), part) * AS;
                if (arc < res.x) res = float2(arc, ID_ARC);
                float eiffel = Eiffel(ToEiffel(p), part) * ES;
                if (eiffel < res.x) res = float2(eiffel, ID_EIFFEL);
                return res;
            }

            float3 SceneNormal(float3 p)
            {
                const float2 e = float2(0.0002, -0.0002);
                float3 g = e.xyy * Map(p + e.xyy).x + e.yyx * Map(p + e.yyx).x + e.yxy * Map(p + e.yxy).x + e.xxx * Map(p + e.xxx).x;
                return g / max(length(g), 1e-7);
            }

            float AmbientOcclusion(float3 p, float3 n)
            {
                float occ = 0.0;
                float w = 1.0;
                [loop] for (int i = 1; i <= 4; i++)
                {
                    float d = 0.004 * i;
                    occ += (d - Map(p + n * d).x) * w;
                    w *= 0.6;
                }
                return saturate(1.0 - occ * 22.0);
            }

            // ---------------------------------------------------------------- 光 (車・街灯・船・灯台)

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
                // 車: 凱旋門のまわりの石畳を、反時計回りにぐるぐる回る。前は白いヘッドライト、後ろは赤いテールライト
                [loop] for (int i = 0; i < CARS; i++)
                {
                    float fi = i;
                    float r = lerp(RING_IN + 0.005, RING_OUT - 0.005, Hash11(fi + 5.0));
                    float a = t * (0.12 + 0.05 * Hash11(fi)) + Hash11(fi + 3.0) * 6.2831853;
                    float2 c = float2(cos(a), sin(a));
                    float2 fwd = float2(-c.y, c.x);
                    float3 base = ARC + float3(c.x * r, 0.002, c.y * r);
                    float3 side = float3(c.x, 0, c.y) * 0.0025;
                    float3 head = base + float3(fwd.x, 0, fwd.y) * 0.006;
                    float3 tail = base - float3(fwd.x, 0, fwd.y) * 0.006;
                    col += PointGlow(ro, rd, tMax, head + side, float3(1.6, 1.5, 1.3), 0.0008);
                    col += PointGlow(ro, rd, tMax, head - side, float3(1.6, 1.5, 1.3), 0.0008);
                    col += PointGlow(ro, rd, tMax, tail + side, float3(1.6, 0.12, 0.06), 0.0007);
                    col += PointGlow(ro, rd, tMax, tail - side, float3(1.6, 0.12, 0.06), 0.0007);
                }
                // 街灯: 広場のまわりに 16 本と、塔へ向かう道の両側
                [loop] for (int k = 0; k < 16; k++)
                {
                    float a = k * 6.2831853 / 16.0 + 0.2;
                    col += PointGlow(ro, rd, tMax, ARC + float3(cos(a) * PLAZA, 0.012, sin(a) * PLAZA), float3(1.8, 1.25, 0.65), 0.0012);
                }
                float2 dirAE = normalize(EIFFEL.xz - ARC.xz);
                float2 sideAE = float2(-dirAE.y, dirAE.x) * 0.03;
                [loop] for (int q = 0; q < 6; q++)
                {
                    float2 c = ARC.xz + dirAE * (PLAZA + 0.03 + q * 0.04);
                    col += PointGlow(ro, rd, tMax, float3(c.x + sideAE.x, GROUND + 0.012, c.y + sideAE.y), float3(1.8, 1.25, 0.65), 0.0012);
                    col += PointGlow(ro, rd, tMax, float3(c.x - sideAE.x, GROUND + 0.012, c.y - sideAE.y), float3(1.8, 1.25, 0.65), 0.0012);
                }
                // 無名戦士の墓の炎 (凱旋門の下で、ゆらゆら燃え続ける)
                float flame = 0.8 + 0.2 * sin(t * 17.0) * sin(t * 7.3);
                col += PointGlow(ro, rd, tMax, ARC + float3(0, 0.0018, 0), float3(2.0, 0.8, 0.2) * flame, 0.0009);
                // 灯台: エッフェル塔の頂上から、2 本の光の帯が夜空を回る (毎晩)。仕掛けの最中は明るく
                float3 top = EIFFEL + float3(0, 0.3 * ES, 0);
                for (int s = 0; s < 2; s++)
                {
                    float a = t * 0.6 + s * 3.1416;
                    float3 dir = normalize(float3(cos(a), -0.05, sin(a)));
                    float sc, kk;
                    float d2 = SegmentDist2(ro, rd, top, top + dir * 0.9, sc, kk);
                    if (sc < 0.0 || sc > tMax) continue;
                    float width = 0.004 + kk * 0.035;
                    col += float3(1.2, 1.1, 0.9) * exp(-d2 / (width * width)) * (1.0 - kk) * (0.12 + 0.3 * _Event);
                }
                return col;
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

                if (id == ID_BASE)
                    return float3(0.015, 0.014, 0.014) + 0.03 * pow(saturate(1.0 - abs(dot(rd, faceNormal))), 4.0);

                float3 n = SceneNormal(p);
                float ao = AmbientOcclusion(p, n);

                if (id == ID_EIFFEL)
                {
                    // エッフェル塔: 「エッフェル・ブラウン」の鉄。ナトリウム灯の金色の照明が、格子の内側から照らす
                    p = ToEiffel(p); // 模様は実物の寸法の座標で調べる
                    float part;
                    Eiffel(p, part);
                    float3 q = p - EIFFEL;
                    float3 iron = float3(0.3, 0.19, 0.11);
                    float3 col = Surface(iron, n, v, L, moonCol, 1.0, ao, 0.45, 0.08, 0.0, skyTop, skyLow);
                    // 照明は格子の内側から: 外を向いた面ほど少し暗く、奥の鉄骨が明るい (金色の濃淡ができる)
                    float glow = (0.55 + 0.45 * ao) * (0.8 + 0.2 * smoothstep(0.0, 0.12, q.y));
                    if (part > 0.5 && part < 1.5)
                    {
                        // 展望台: 窓の帯がこうこうと明るい
                        float band = step(0.35, frac(atan2(q.z, q.x) * 40.0)) * step(abs(frac(q.y / 0.0012) - 0.5), 0.3);
                        col += float3(1.8, 1.2, 0.6) * (0.6 + 1.2 * band);
                    }
                    else
                    {
                        col += float3(1.25, 0.62, 0.18) * glow * (part > 1.5 ? 1.2 : 1.0);
                    }
                    // きらめき: 仕掛けの最中は、塔じゅうで白い光が 1 つずつまたたく
                    float3 cell = floor(q / 0.0025);
                    float sparkle = step(0.9, Hash31(cell + floor(t * 14.0) * 0.37)) * _Event;
                    col += float3(5.0, 5.0, 5.5) * sparkle;
                    return col;
                }

                if (id == ID_ARC)
                {
                    // 凱旋門: 白っぽい石灰岩。下から照らされて浮き上がる。彫刻の陰影、軒の下の 30 の盾、アーチの天井の格間
                    p = ToArc(p); // 模様は実物の寸法の座標で調べる
                    float part;
                    Arc(p, part);
                    float3 q = p - ARC;
                    float3 nb = BumpNormal(n, p, part > 0.5 ? 4000.0 : 1800.0, part > 0.5 ? 1.2 : 0.4);
                    float3 stone = float3(0.84, 0.8, 0.7) * (0.92 + 0.08 * Noise3(p * 2500.0));
                    // 石を積んだ目地 (横の線)
                    stone *= 1.0 - 0.15 * step(abs(frac(q.y / 0.0011) - 0.5), 0.04);
                    // 軒の下の帯 (アティック) に並ぶ盾: 正面と裏に 30
                    if (abs(q.y - 0.0425) < 0.0018 && n.y < 0.5)
                    {
                        float u = abs(n.x) > abs(n.z) ? q.z : q.x;
                        float s = abs(frac(u / 0.0015) - 0.5) * 0.0015;
                        stone *= 1.0 - 0.35 * smoothstep(0.0005, 0.0003, length(float2(s, q.y - 0.0425)));
                    }
                    // アーチの天井: 格子の格間 (くぼんだ四角に花の飾り)
                    float inMain = abs(length(q.xy - float2(0, 0.0219)) - 0.0073);
                    if (inMain < 0.0004 && q.y > 0.0219)
                    {
                        float ang = atan2(q.y - 0.0219, q.x);
                        float2 g = abs(frac(float2(ang * 6.0, q.z / 0.0018)) - 0.5);
                        stone *= 0.75 + 0.25 * step(max(g.x, g.y), 0.35);
                    }
                    float3 col = Surface(stone, nb, v, L, moonCol, 1.0, ao, 0.6, 0.04, 0.0, skyTop, skyLow);
                    // 足元からの投光: 下ほど明るく、上へ行くほど暗くなる。下を向いた面 (軒の裏) は暗い
                    float flood = exp(-max(q.y, 0.0) / 0.022) * (0.5 + 0.5 * saturate(abs(n.z) + abs(n.x) * 0.6)) * saturate(0.4 - n.y * 0.6 + 0.6);
                    col += stone * float3(1.3, 0.85, 0.45) * 0.45 * flood * ao;
                    // 無名戦士の墓の炎が、アーチの下を照らす
                    float fl = 0.8 + 0.2 * sin(t * 17.0) * sin(t * 7.3);
                    col += stone * float3(1.5, 0.6, 0.15) * fl * 0.6 * exp(-length(q - float3(0, 0.0004, 0)) / 0.004);
                    return col;
                }

                if (max(abs(p.x), abs(p.z)) > INNER - 0.0015 && abs(n.y) < 0.5)
                    return float3(0.03, 0.026, 0.024) * (0.8 + 0.4 * Noise3(p * 900.0)); // 地面の切り口 (土と石)

                // 地面: 凱旋門のまわりはエトワール広場 (濡れた石畳)、塔のまわりはシャン・ド・マルス (芝生と砂利)
                float3 albedo;
                float rough = 0.6;
                float bump = 0.6;
                float sss = 0.0;
                bool reflective = false;
                float r = length(p.xz - ARC.xz);
                float2 e = p.xz - EIFFEL.xz;
                float pk;
                float pathD = PathDist(p.xz, pk);
                if (r < RING_IN - 0.012)
                {
                    // 凱旋門の足元: 大きな板石
                    float2 g = abs(frac(p.xz / 0.0045) - 0.5);
                    albedo = float3(0.22, 0.21, 0.19) * (1.0 - 0.3 * step(0.45, max(g.x, g.y)));
                    rough = 0.35;
                }
                else if (r < RING_IN - 0.006)
                {
                    albedo = float3(0.4, 0.38, 0.34); // 縁石
                    rough = 0.5;
                }
                else if (r < PLAZA - 0.012)
                {
                    // 車の回る石畳 (パヴェ): 小さな四角い石が、濡れて光る
                    float2 g = abs(frac(p.xz / 0.0004) - 0.5);
                    albedo = float3(0.11, 0.105, 0.1) * (0.7 + 0.6 * Hash21(floor(p.xz / 0.0004))) * (1.0 - 0.4 * step(0.42, max(g.x, g.y)));
                    rough = 0.2;
                    bump = 0.3;
                    reflective = true;
                }
                else if (r < PLAZA || pathD < 0.02)
                {
                    // 広場のまわりの歩道と、塔へ向かう道: 明るい板石
                    float2 g = abs(frac(p.xz / 0.003) - 0.5);
                    albedo = float3(0.36, 0.34, 0.3) * (1.0 - 0.2 * step(0.46, max(g.x, g.y)));
                    rough = 0.45;
                }
                else
                {
                    // シャン・ド・マルス: 刈り込んだ芝生の四角と、砂利の道。塔の足元は砂利の広場
                    bool gravel = max(abs(e.x), abs(e.y)) < 0.16 || abs(frac(e.y / 0.2) - 0.5) * 0.2 < 0.004 || abs(frac(e.x / 0.15) - 0.5) * 0.15 < 0.004;
                    albedo = gravel ? float3(0.42, 0.36, 0.27) * (0.85 + 0.3 * Noise3(p * 3000.0)) : float3(0.07, 0.13, 0.05) * (0.8 + 0.4 * Noise3(p * 1500.0));
                    rough = gravel ? 0.8 : 0.9;
                    bump = gravel ? 1.0 : 0.7;
                    sss = gravel ? 0.0 : 0.3;
                }
                float3 nb = BumpNormal(n, p, 2500.0, bump);
                float3 col = Surface(albedo, nb, v, L, moonCol, 1.0, ao, rough, 0.04, sss, skyTop, skyLow);
                // 街灯と、金色に光る塔の照り返し
                float lampLight = exp(-abs(r - PLAZA) / 0.02) + exp(-max(pathD - 0.03, 0.0) / 0.015) * step(PLAZA, r);
                float towerLight = exp(-length(e) / 0.14);
                col += albedo * (float3(1.0, 0.62, 0.3) * 0.35 * lampLight + float3(1.2, 0.6, 0.18) * 0.5 * towerLight);
                if (reflective)
                {
                    // 濡れた石畳に映る光: 反射した線の先にある車のライトと街灯を、ぼんやり足す
                    float3 rr = reflect(rd, BumpNormal(n, p, 1500.0, 0.06));
                    col += Lights(p + rr * 0.0005, rr, 0.6) * 0.35;
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

                const float maxHeight = 0.432; // エッフェル塔のアンテナの先 (大きくしたあと)
                if (ro.y > maxHeight && rd.y < 0.0) t = max(t, (maxHeight - ro.y) / rd.y);

                bool hit = false;
                float id = 0.0;
                int steps = (int)_Steps;
                [loop] for (int i = 0; i < 200; i++)
                {
                    if (i >= steps || t > box.y) break;
                    float3 pos = ro + rd * t;
                    if (rd.y > 0.0 && pos.y > maxHeight + 0.002) break;
                    float2 m = Map(pos);
                    // 当たったとみなす近さ: 遠いほど大きく (遠くの細い格子は、1 画素くらいの太さで描く)
                    if (m.x < 0.00003 + 0.0003 * t)
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
