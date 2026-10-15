// 作品「夜のパリ」(ヨーロッパの間)。実物の寸法 (1 m = 0.001) で作った、夜のパリの街。URP 用。
// Cube の中をレイマーチングして描く。Cube の座標は -0.5〜0.5、下の 0.08 は黒い台。
//
// 見どころ (どれも実物の大きさ・形に合わせた):
//   ・凱旋門 (高さ 50 m・幅 45 m・奥行き 22 m): 大アーチと左右に抜ける小アーチ、軒、30 の盾の帯、4 つの彫刻群、無名戦士の墓の炎
//   ・エトワール広場から星形にのびる 12 本の大通り。その 1 本がシャンゼリゼ通り (8 車線と、2 列の並木と街灯)
//   ・オスマン様式のアパルトマン: 角を斜めに切った街区、中庭、軒の高さ約 20 m、2 階と 5 階の鉄のバルコニー、
//     45 度の亜鉛のマンサード屋根と屋根窓、煙突。1 階はお店、その上に中 2 階
//   ・エッフェル塔 (高さ 300 m・アンテナ込み 330 m): 4 本の格子の脚が 2 階で 1 本になる。3 つの展望台と、脚の間の飾りアーチ。
//     格子は本当に穴が空いていて、向こうがすけて見える
//   ・8 m 下を流れるセーヌ川と川辺の道、5 つのアーチのイエナ橋、川を行き来する遊覧船
// 仕掛け (_Event 0〜1): エッフェル塔が白いフラッシュでキラキラきらめき、頂上の灯台の光が強くなる
//
// 外から見たとき、街のない所 (空) は透明にして、ガラスケースの向こうの部屋が見えるようにする。
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

            // ---------------------------------------------------------------- 実物の寸法 (1 m = 0.001)
            // ※ 街区を置く条件 (BlockAllowed) と、凱旋門・エッフェル塔の場所を変えたら、C# の DioramaTerrain も同じに直す (当たり判定)

            #define M 0.001
            #define GROUND -0.3
            #define CELL 0.06              // 街区のます目
            #define CARS 28
            static const float3 ARC = float3(0.0, -0.3, 0.25);      // 凱旋門 (エトワール広場の中心)
            static const float3 EIFFEL = float3(-0.06, -0.3, -0.32); // エッフェル塔の中心
            static const float3 MOON_DIR = float3(0.4, 0.55, -0.7);
            #define RIVER_N -0.2           // セーヌ川の向こう岸 (z)
            #define RIVER_S -0.11          // セーヌ川の手前の岸 (z)

            float Hash11(float n) { return frac(sin(n * 127.1) * 43758.5453); }

            // ---------------------------------------------------------------- 街の作り

            bool BlockAllowed(float2 c)
            {
                if (abs(c.x) > 0.44 || abs(c.y) > 0.44) return false;
                float2 d = c - ARC.xz;
                float r = length(d);
                if (r < 0.15) return false;                                        // エトワール広場とまわり
                float ang = atan2(d.y, d.x);
                float sector = 6.2831853 / 12.0;                                   // 広場から星形にのびる 12 本の大通り
                float a2 = (frac(ang / sector + 0.5) - 0.5) * sector;
                if (r < 0.4 && abs(sin(a2)) * r < 0.03) return false;
                if (abs(c.x) < 0.06 && c.y > RIVER_S && c.y < 0.14) return false;  // シャンゼリゼ通り
                if (c.y > RIVER_N - 0.03 && c.y < RIVER_S + 0.03) return false;    // セーヌ川と岸
                if (c.x > -0.16 && c.x < 0.04 && c.y < RIVER_N) return false;      // エッフェル塔とシャン・ド・マルス
                return Hash21(c * 7.3 + _Seed) < 0.95;
            }

            // 軒の高さ (オスマン様式は、軒が約 20 m にそろう)
            float BlockHeight(float2 c) { return (19.0 + 2.0 * Hash21(c * 3.1 + _Seed + 5.0)) * M; }

            // 街の地面: セーヌ川は 8 m 下を流れ、岸には一段低い川辺の道
            float GroundY(float2 xz)
            {
                float z = xz.y;
                if (z < RIVER_N || z > RIVER_S) return GROUND;
                float edge = min(z - RIVER_N, RIVER_S - z);
                return GROUND - (edge < 0.007 ? 0.006 : 0.012);
            }

            // ---------------------------------------------------------------- オスマン様式のアパルトマン

            // 1 つの街区: 角を斜めに切った (パン・クーペ) 外形、中庭、軒の張り出し、2 階と 5 階の通しバルコニー、
            // 45 度の亜鉛のマンサード屋根、屋根窓、煙突。l は街区の中心からの位置、y は地面からの高さ
            float Haussmann(float2 l, float y, float h)
            {
                float2 a = abs(l);
                float foot = max(max(a.x, a.y) - 0.024, (a.x + a.y - 0.043) * 0.7071);
                float court = max(a.x, a.y) - 0.009;
                float plan = max(foot, -court);
                float body = max(plan, max(-y, y - h));
                // マンサード屋根: 軒から内へ 45 度で 7.5 m 上がる
                float roof = max(plan + max(y - h, 0.0), max(h - y, y - (h + 0.0075))) * 0.7071;
                float d = min(body, roof);
                // 軒の張り出しと、2 階・5 階の通しバルコニー
                float cornice = max(plan - 0.0008, abs(y - (h - 0.0005)) - 0.0005);
                float balcony = max(plan - 0.0007, min(abs(y - 0.0075), abs(y - 0.0165)) - 0.0002);
                d = min(d, min(cornice, balcony));
                // 屋根窓: 屋根の下のほうの斜面に、3.5 m おきに小さな箱と三角の屋根
                bool faceX = a.x > a.y;
                float u = faceX ? l.y : l.x;
                float outward = faceX ? a.x : a.y;
                float um = u - round(u / 0.0035) * 0.0035;
                float dormer = SdBox(float3(um, y - (h + 0.0022), outward - 0.0215), float3(0.0007, 0.0014, 0.0014));
                if (abs(u) < 0.019) d = min(d, dormer);
                // 煙突: 屋根の上に、12 m おきに
                float um2 = u - round(u / 0.012) * 0.012;
                float chimney = SdBox(float3(um2, y - (h + 0.0085), outward - 0.0165), float3(0.0018, 0.0014, 0.0008));
                d = min(d, chimney);
                return d;
            }

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
                if (y > h + 0.012) return min(y - h - 0.01, bound);
                return min(Haussmann(local, y, h), bound);
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

            // ---------------------------------------------------------------- 並木・橋・遊覧船

            // シャンゼリゼの並木: 歩道に 2 列ずつ、四角く刈り込んだプラタナス
            float Trees(float3 p)
            {
                float ax = abs(p.x);
                float row = ax < 0.0235 ? ax - 0.018 : ax - 0.029;
                if (abs(row) > 0.008 || p.z < RIVER_S + 0.01 || p.z > 0.13 || p.y > GROUND + 0.016) return max(max(abs(row) - 0.006, p.y - GROUND - 0.015), 0.002);
                float z = p.z - round(p.z / 0.008) * 0.008;
                float3 q = float3(row, p.y - GROUND, z);
                float crown = SdBox(q - float3(0, 0.0105, 0), float3(0.0028, 0.0035, 0.0034)) - 0.0008;
                float trunk = max(length(q.xz) - 0.0004, abs(q.y - 0.0035) - 0.0035);
                return min(crown, trunk);
            }

            // イエナ橋: エッフェル塔の前でセーヌ川をわたる、5 つのアーチの石の橋
            float Bridge(float3 p)
            {
                float3 q = p - float3(EIFFEL.x, GROUND, (RIVER_N + RIVER_S) * 0.5);
                float halfLen = (RIVER_S - RIVER_N) * 0.5 + 0.004;
                if (abs(q.x) > 0.022 || abs(q.z) > halfLen + 0.004 || q.y > 0.004) return max(max(abs(q.x) - 0.02, abs(q.z) - halfLen), max(q.y - 0.003, 0.002));
                float deck = SdBox(q - float3(0, -0.006, 0), float3(0.0175, 0.006, halfLen));
                float spacing = (2.0 * halfLen) / 5.0;
                float zz = q.z + halfLen - (floor((q.z + halfLen) / spacing) + 0.5) * spacing;
                float arch = length(float2(zz / 1.15, q.y + 0.012)) - 0.0075; // 平たいアーチ (間に橋脚が残る)
                float parapet = SdBox(float3(abs(q.x) - 0.0168, q.y - 0.0008, q.z), float3(0.0007, 0.0008, halfLen));
                return min(max(deck, -arch), parapet);
            }

            // 遊覧船 (バトー・ムーシュ): ガラス屋根の細長い船が、川をゆっくり行き来する
            float3 BoatPos(int i)
            {
                float t = _Time.y;
                float u = frac(t * 0.01 + i * 0.5);
                float x = lerp(-0.42, 0.42, i == 0 ? u : 1.0 - u);
                return float3(x, GROUND - 0.0117, i == 0 ? -0.145 : -0.17);
            }

            float Boats(float3 p)
            {
                float d = 1.0;
                for (int i = 0; i < 2; i++)
                {
                    float3 q = p - BoatPos(i);
                    d = min(d, SdBox(q - float3(0, 0.0012, 0), float3(0.016, 0.0012, 0.0025)) - 0.0004);
                }
                return d;
            }

            // ---------------------------------------------------------------- 世界の形

            #define ID_BASE     0.0
            #define ID_GROUND   1.0
            #define ID_WATER    2.0
            #define ID_BUILDING 3.0
            #define ID_ARC      4.0
            #define ID_EIFFEL   5.0
            #define ID_TREE     6.0
            #define ID_BRIDGE   7.0
            #define ID_BOAT     8.0

            float2 Map(float3 p)
            {
                float2 res = float2(SdBox(p - float3(0, -0.46, 0), float3(0.5, 0.04, 0.5)), ID_BASE);
                float column = SdBox(p - float3(0, 0.04, 0), float3(INNER, 0.46, INNER));
                // 地面と、セーヌ川の掘り込み (川辺の道の段と、さらに低い水路)
                float zc = abs(p.z - (RIVER_N + RIVER_S) * 0.5);
                float halfRiver = (RIVER_S - RIVER_N) * 0.5;
                float quay = max(zc - halfRiver, (GROUND - 0.006) - p.y);
                float channel = max(zc - (halfRiver - 0.007), (GROUND - 0.012) - p.y);
                float ground = max(max(p.y - GROUND, -min(quay, channel)), column);
                if (ground < res.x) res = float2(ground, ID_GROUND);
                float water = max(max(p.y - (GROUND - 0.0105), max(RIVER_N - p.z, p.z - RIVER_S)), column);
                if (water < res.x) res = float2(water, ID_WATER);
                float2 cc;
                float b = max(Blocks(p, cc), column);
                if (b < res.x) res = float2(b, ID_BUILDING);
                float part;
                float arc = Arc(p, part);
                if (arc < res.x) res = float2(arc, ID_ARC);
                float eiffel = Eiffel(p, part);
                if (eiffel < res.x) res = float2(eiffel, ID_EIFFEL);
                float trees = Trees(p);
                if (trees < res.x) res = float2(trees, ID_TREE);
                float bridge = Bridge(p);
                if (bridge < res.x) res = float2(bridge, ID_BRIDGE);
                float boats = Boats(p);
                if (boats < res.x) res = float2(boats, ID_BOAT);
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
                for (int i = 1; i <= 4; i++)
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
                // 車: シャンゼリゼの 8 車線。左側は手前へ来る (白いヘッドライト)、右側は奥へ行く (赤いテールライト)
                for (int i = 0; i < CARS; i++)
                {
                    float fi = i;
                    bool toward = (i % 2) == 0;
                    float lane = 0.0018 + 0.0032 * floor(Hash11(fi + 5.0) * 4.0);
                    float u = frac(t * (0.02 + 0.008 * Hash11(fi)) + Hash11(fi + 3.0));
                    float z = toward ? lerp(RIVER_S + 0.005, 0.13, u) : lerp(0.13, RIVER_S + 0.005, u);
                    float x = toward ? -lane : lane;
                    float3 colr = toward ? float3(1.6, 1.5, 1.3) : float3(1.6, 0.12, 0.06);
                    col += PointGlow(ro, rd, tMax, float3(x - 0.0008, GROUND + 0.0007, z), colr, 0.0004);
                    col += PointGlow(ro, rd, tMax, float3(x + 0.0008, GROUND + 0.0007, z), colr, 0.0004);
                }
                // 街灯: シャンゼリゼの車道の両側と、川岸
                for (int k = 0; k < 15; k++)
                {
                    float z = RIVER_S + 0.012 + k * 0.016;
                    col += PointGlow(ro, rd, tMax, float3(-0.0155, GROUND + 0.009, z), float3(1.8, 1.25, 0.65), 0.0005);
                    col += PointGlow(ro, rd, tMax, float3(0.0155, GROUND + 0.009, z), float3(1.8, 1.25, 0.65), 0.0005);
                }
                for (int q = 0; q < 12; q++)
                {
                    float x = -0.42 + q * 0.076;
                    col += PointGlow(ro, rd, tMax, float3(x, GROUND + 0.008, RIVER_S - 0.002), float3(1.8, 1.25, 0.65), 0.0005);
                    col += PointGlow(ro, rd, tMax, float3(x + 0.038, GROUND + 0.008, RIVER_N + 0.002), float3(1.8, 1.25, 0.65), 0.0005);
                }
                // 遊覧船の明かり
                for (int b = 0; b < 2; b++)
                {
                    float3 bp = BoatPos(b);
                    for (int l = 0; l < 4; l++)
                        col += PointGlow(ro, rd, tMax, bp + float3(-0.012 + l * 0.008, 0.0028, 0.0026), float3(1.6, 1.3, 0.8), 0.0004);
                }
                // 無名戦士の墓の炎 (凱旋門の下で、ゆらゆら燃え続ける)
                float flame = 0.8 + 0.2 * sin(t * 17.0) * sin(t * 7.3);
                col += PointGlow(ro, rd, tMax, ARC + float3(0, 0.0006, 0), float3(2.0, 0.8, 0.2) * flame, 0.0003);
                // 灯台: エッフェル塔の頂上から、2 本の光の帯が夜空を回る (毎晩)。仕掛けの最中は明るく
                float3 top = EIFFEL + float3(0, 0.3, 0);
                for (int s = 0; s < 2; s++)
                {
                    float a = t * 0.6 + s * 3.1416;
                    float3 dir = normalize(float3(cos(a), -0.05, sin(a)));
                    float sc, kk;
                    float d2 = SegmentDist2(ro, rd, top, top + dir * 0.7, sc, kk);
                    if (sc < 0.0 || sc > tMax) continue;
                    float width = 0.003 + kk * 0.03;
                    col += float3(1.2, 1.1, 0.9) * exp(-d2 / (width * width)) * (1.0 - kk) * (0.12 + 0.3 * _Event);
                }
                return col;
            }

            // エッフェル塔の金色の光を、川面に映ったように足す
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
                if (y < 0.0 || y > 0.3) return 0;
                float2 dxz = pt.xz - EIFFEL.xz;
                float w = EiffelW(y);
                return float3(1.8, 1.1, 0.4) * exp(-dot(dxz, dxz) / (w * w)) * 0.5;
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

            // アパルトマンの窓の並び。u は壁にそった位置、y は地面からの高さ。窓なら 1 を返し、id に窓の番号を入れる
            //   1 階 (0〜4.2 m): 大きなお店のショーウィンドウ / 中 2 階 (〜6.2 m): 低い窓 / その上: 3.2 m ごとの階に、縦長の窓
            float WindowMask(float u, float y, float h, out float2 id, out float kind)
            {
                float uc = round(u / 0.0035);
                float um = abs(u - uc * 0.0035);
                id = float2(uc, 0);
                kind = 0;
                if (y < 0.0042)
                {
                    kind = 1;
                    return step(um, 0.0013) * step(0.0003, y) * step(y, 0.0036);
                }
                if (y < 0.0062)
                {
                    id.y = 1;
                    return step(um, 0.00065) * step(0.0046, y) * step(y, 0.0058);
                }
                if (y > h - 0.0008) return 0;
                float fl = floor((y - 0.0062) / 0.0032);
                float fy = (y - 0.0062) - fl * 0.0032;
                id.y = 2 + fl;
                return step(um, 0.00065) * step(0.0005, fy) * step(fy, 0.0027);
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
                float3 street = float3(1.0, 0.62, 0.3) * 0.35 * exp(-max(y, 0.0) / 0.008);

                if (id == ID_BASE)
                    return float3(0.015, 0.014, 0.014) + 0.03 * pow(saturate(1.0 - abs(dot(rd, faceNormal))), 4.0);

                float3 n = SceneNormal(p);
                float ao = AmbientOcclusion(p, n);

                if (id == ID_WATER)
                {
                    // セーヌ川: 暗い水面に、エッフェル塔と街灯・遊覧船の光が揺れて映る
                    float2 q = p.xz * float2(90.0, 300.0);
                    float2 slope = (float2(ValueNoise(q + t * 0.5), ValueNoise(q.yx - t * 0.6)) - 0.5) * 0.12;
                    float3 wn = normalize(float3(slope.x, 1.0, slope.y));
                    float3 r = reflect(rd, wn);
                    float fres = 0.02 + 0.98 * pow(1.0 - saturate(dot(v, wn)), 5.0);
                    float3 refl = Sky(r) + EiffelReflection(p, r) + Lights(p + r * 0.001, r, 1.0) * 0.6;
                    return float3(0.008, 0.012, 0.016) + refl * (0.3 + 0.7 * fres);
                }

                if (id == ID_EIFFEL)
                {
                    // エッフェル塔: 「エッフェル・ブラウン」の鉄。ナトリウム灯の金色の照明が、格子の内側から照らす
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

                if (id == ID_TREE)
                {
                    // プラタナスの並木: 街灯に下から照らされて、葉の裏が明るい
                    float3 albedo = float3(0.07, 0.13, 0.05) * (0.7 + 0.6 * Noise3(p * 2000.0));
                    float3 col = Surface(albedo, BumpNormal(n, p, 3000.0, 1.0), v, L, moonCol, 1.0, ao, 0.8, 0.03, 0.3, skyTop, skyLow);
                    return col + albedo * street * 5.0 * (0.5 + 0.5 * saturate(-n.y + 0.5));
                }

                if (id == ID_BRIDGE)
                {
                    float3 stone = float3(0.6, 0.57, 0.5) * (0.85 + 0.15 * Noise3(p * 2500.0));
                    float3 col = Surface(stone, BumpNormal(n, p, 2500.0, 0.6), v, L, moonCol, 1.0, ao, 0.65, 0.04, 0.0, skyTop, skyLow);
                    return col + stone * street * 2.0;
                }

                if (id == ID_BOAT)
                {
                    // 遊覧船: 白い船体に、明るいガラスの客室
                    float3 col;
                    float rel = p.y - (GROUND - 0.0117);
                    if (rel > 0.0016)
                    {
                        float3 r = reflect(rd, n);
                        col = float3(1.4, 1.1, 0.7) * 0.5 + Sky(r) * 0.4;
                    }
                    else
                    {
                        col = Surface(float3(0.7, 0.7, 0.72), n, v, L, moonCol, 1.0, ao, 0.4, 0.05, 0.0, skyTop, skyLow);
                    }
                    return col;
                }

                if (id == ID_BUILDING)
                {
                    float2 cc;
                    Blocks(p, cc);
                    float h = BlockHeight(cc);
                    float2 l = p.xz - cc;
                    bool faceX = abs(n.x) > abs(n.z);
                    float u = faceX ? l.y : l.x;
                    float3 stone = float3(0.8, 0.74, 0.62) * (0.9 + 0.1 * Noise3(p * 2500.0));
                    if (y > h + 0.0068 && max(abs(l.x), abs(l.y)) < 0.0175 && max(abs(l.x), abs(l.y)) > 0.0155)
                    {
                        // 煙突: 石と、上にテラコッタの煙突ポット
                        float3 alb = y > h + 0.0095 ? float3(0.45, 0.2, 0.12) : stone * 0.8;
                        return Surface(alb, n, v, L, moonCol, 1.0, ao, 0.7, 0.04, 0.0, skyTop, skyLow) + alb * 0.08;
                    }
                    if (y > h + 0.0002 && n.y > 0.3)
                    {
                        // マンサード屋根: 青灰色の亜鉛の板。継ぎ目の縦の筋。夜空を映す
                        float seam = step(abs(frac(u / 0.0006) - 0.5), 0.08);
                        float3 zinc = float3(0.26, 0.29, 0.33) * (1.0 - 0.25 * seam);
                        return Surface(zinc, n, v, L, moonCol, 1.0, ao, 0.3, 0.35, 0.0, skyTop, skyLow);
                    }
                    if (y > h + 0.0002)
                    {
                        // 屋根窓: 半分くらいに灯り
                        float lit = step(0.45, Hash21(float2(round(u / 0.0035), 0) + cc * 13.0 + 7.0));
                        float3 col = Surface(float3(0.75, 0.72, 0.68), n, v, L, moonCol, 1.0, ao, 0.5, 0.05, 0.0, skyTop, skyLow);
                        float um = abs(u - round(u / 0.0035) * 0.0035);
                        float win = step(um, 0.0004) * step(abs(y - h - 0.002), 0.0007);
                        return lerp(col, float3(1.6, 1.0, 0.45) * lit + float3(0.02, 0.02, 0.03), win);
                    }
                    // 石の壁: 切り石の目地。軒の下と、1 階の石は横の溝 (ルスティカ)
                    float joint = step(abs(frac(y / 0.0006) - 0.5), 0.05);
                    float rust = y < 0.0062 ? step(abs(frac(y / 0.0009) - 0.5), 0.12) : 0.0;
                    stone *= 1.0 - 0.1 * joint - 0.25 * rust;
                    float2 wid;
                    float kind;
                    float window = WindowMask(u, y, h, wid, kind) * step(abs(n.y), 0.3);
                    float hsh = Hash21(wid + cc * 13.0);
                    float lit = step(0.5, hsh);
                    float3 warm = lerp(float3(1.7, 1.05, 0.5), float3(1.5, 1.2, 0.85), step(0.85, Hash21(wid + 3.7)));
                    if (Hash21(wid * 1.7 + cc) > 0.93) warm = float3(0.5, 0.7, 1.4) * (0.8 + 0.2 * sin(t * 3.0 + hsh * 20.0)); // テレビの青い光
                    float3 glass = float3(0.02, 0.025, 0.035);
                    float3 albedo = lerp(stone, glass, window);
                    float3 col = Surface(albedo, n, v, L, moonCol, 1.0, ao, lerp(0.7, 0.05, window), lerp(0.04, 0.1, window), 0.0, skyTop, skyLow);
                    col += stone * street * 1.5 * (1.0 - window);
                    float3 inside = kind > 0.5 ? float3(1.5, 0.95, 0.5) * (0.6 + 0.5 * hsh) : warm * lit;
                    col += inside * window * 0.8;
                    // 2 階・5 階の鉄のバルコニー: 黒い手すりの縦の棒が、窓の前を横切る
                    float rail = (step(abs(y - 0.0081), 0.0005) + step(abs(y - 0.0171), 0.0005));
                    float bars = step(abs(frac(u / 0.00025) - 0.5), 0.2);
                    float railMask = saturate(rail * (0.4 + 0.6 * bars) + step(abs(y - 0.0086), 0.00008) + step(abs(y - 0.0176), 0.00008));
                    col = lerp(col, float3(0.012, 0.012, 0.014) + col * 0.15, railMask);
                    return col;
                }

                if (id == ID_GROUND && max(abs(p.x), abs(p.z)) > INNER - 0.0015 && abs(n.y) < 0.5)
                    return float3(0.03, 0.026, 0.024) * (0.8 + 0.4 * Noise3(p * 900.0)); // 地面の切り口 (土と石)

                // 地面: 場所ごとに、車道 (濡れたアスファルト)・石畳・歩道・芝生・砂利・川辺の石
                float3 albedo = float3(0.24, 0.22, 0.19);
                float rough = 0.6;
                float bump = 0.6;
                bool reflective = false;
                float2 d = p.xz - ARC.xz;
                float r = length(d);
                float ang = atan2(d.y, d.x);
                float sector = 6.2831853 / 12.0;
                float a2 = (frac(ang / sector + 0.5) - 0.5) * sector;
                float avenue = abs(sin(a2)) * r;
                float2 cellL = p.xz - (floor(p.xz / CELL) + 0.5) * CELL;
                float edgeDist = max(abs(cellL.x), abs(cellL.y));
                bool river = p.z > RIVER_N && p.z < RIVER_S;
                bool champ = p.x > -0.16 && p.x < 0.04 && p.z < RIVER_N;
                if (river)
                {
                    // 川辺: 石の岸壁と、石畳の川辺の道
                    albedo = float3(0.4, 0.37, 0.32) * (0.85 + 0.15 * Noise3(p * 2500.0));
                    rough = 0.55;
                }
                else if (r < 0.03)
                {
                    // 凱旋門の足元の石の床 (広場の石畳より明るい、大きな板石)
                    float2 g = abs(frac(p.xz / 0.0015) - 0.5);
                    albedo = float3(0.2, 0.19, 0.17) * (1.0 - 0.3 * step(0.45, max(g.x, g.y)));
                    rough = 0.35;
                }
                else if (r < 0.11)
                {
                    // エトワール広場の石畳 (パヴェ): 細かな四角い石が、濡れて光る
                    float2 g = abs(frac(p.xz / 0.00012) - 0.5);
                    albedo = float3(0.12, 0.115, 0.11) * (0.7 + 0.6 * Hash21(floor(p.xz / 0.00012))) * (1.0 - 0.4 * step(0.42, max(g.x, g.y)));
                    rough = 0.2;
                    bump = 0.3;
                    reflective = true;
                }
                else if (r < 0.12 && avenue > 0.008)
                {
                    albedo = float3(0.36, 0.34, 0.3); // 広場のまわりの歩道
                }
                else if (abs(p.x) < 0.0135 && p.z > RIVER_S && p.z < 0.15)
                {
                    // シャンゼリゼの車道: 濡れたアスファルト。車線の白い破線
                    albedo = float3(0.045, 0.045, 0.05);
                    float lane = abs(frac((abs(p.x)) / 0.0032) - 0.5) * 0.0032;
                    float dash = step(frac(p.z / 0.006), 0.5);
                    albedo += float3(0.35, 0.35, 0.33) * step(lane, 0.00008) * dash * step(0.002, abs(p.x));
                    rough = 0.12;
                    bump = 0.15;
                    reflective = true;
                }
                else if (abs(p.x) < 0.035 && p.z > RIVER_S && p.z < 0.15)
                {
                    // シャンゼリゼの歩道: 明るい花こう岩の板石
                    float2 g = abs(frac(p.xz / 0.0012) - 0.5);
                    albedo = float3(0.5, 0.47, 0.42) * (1.0 - 0.2 * step(0.46, max(g.x, g.y)));
                    rough = 0.4;
                }
                else if (champ)
                {
                    // シャン・ド・マルス: 刈り込んだ芝生の四角と、砂利の道。塔の足元は砂利の広場
                    float2 q = p.xz - EIFFEL.xz;
                    bool gravel = max(abs(q.x), abs(q.y)) < 0.075 || abs(q.x) < 0.006 || abs(frac(q.y / 0.04) - 0.5) * 0.04 < 0.003;
                    albedo = gravel ? float3(0.42, 0.36, 0.27) : float3(0.07, 0.13, 0.05) * (0.8 + 0.4 * Noise3(p * 3000.0));
                    rough = gravel ? 0.8 : 0.9;
                    bump = gravel ? 1.0 : 0.6;
                }
                else if (edgeDist > 0.0275 || (avenue < 0.03 && r < 0.4 && avenue > 0.0))
                {
                    // 街区のあいだの道と、星形の大通り: アスファルト
                    albedo = float3(0.05, 0.05, 0.055);
                    rough = 0.18;
                    bump = 0.2;
                    reflective = true;
                }
                else
                {
                    albedo = float3(0.33, 0.31, 0.28); // 街区のまわりの歩道
                    rough = 0.5;
                }
                float3 nb = BumpNormal(n, p, 2500.0, bump);
                float3 col = Surface(albedo, nb, v, L, moonCol, 1.0, ao, rough, 0.04, champ ? 0.3 : 0.0, skyTop, skyLow);
                col += albedo * street * 2.5;
                if (reflective)
                {
                    // 濡れた路面に映る光: 反射した線の先にある車のライトと街灯を、ぼんやり足す
                    float3 rr = reflect(rd, BumpNormal(n, p, 1500.0, 0.06));
                    col += Lights(p + rr * 0.0005, rr, 0.5) * 0.35;
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

                const float maxHeight = 0.036; // エッフェル塔のアンテナの先
                if (ro.y > maxHeight && rd.y < 0.0) t = max(t, (maxHeight - ro.y) / rd.y);

                bool hit = false;
                float id = 0.0;
                int steps = (int)_Steps;
                for (int i = 0; i < 200; i++)
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
