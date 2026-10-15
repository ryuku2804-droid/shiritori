// 作品「ピサの斜塔」(ヨーロッパの間)。午後遅くの金色の光の中の、奇跡の広場。実物の寸法と、実物の並び方で作った。URP 用。
// 建物は 1 m = 0.0022 で形を作り、全体を BSCALE 倍 (1 m = 0.003) に大きくして置く
// Cube の中をレイマーチングして描く。Cube の座標は -0.5〜0.5、下の 0.08 は黒い台。
// 美術館の正面 (+z) が南。正面から見ると、左に洗礼堂、まん中に大聖堂、右に斜塔 (絵はがきと同じ眺め)。
// ※ 形を作る式の中は、z が西 → 東、x が北 → 南 の向き (Frag の最初で向きを回している)
//
// 見どころ (どれも実物の大きさ・形に合わせた):
//   ・斜塔 (高さ 56 m・直径 15.5 m): 南へ 3.97 度傾く。1 層目は 15 のめくらアーチ、2〜7 層目は 30 本の柱の回廊が 6 段、
//     上に 12 のアーチ窓の鐘楼。柱のすき間から、回廊の奥が見える
//   ・大聖堂 (長さ 100 m): 5 つの廊の十字形。グレーと白の縞の大理石の壁、正面は 1 階のめくらアーチと 3 つのブロンズの扉、
//     その上に細い柱の回廊が 4 段。交差部に楕円の丸屋根、東に半円の後陣
//   ・洗礼堂 (直径 34 m・高さ 55 m): 20 のアーチ、ゴシックの破風と小尖塔、東半分が赤い瓦・西半分が鉛の丸屋根と、てっぺんの像
//   ・北のカンポサント (墓所の回廊) と、北と西のレンガの城壁。鳩のいる芝生と、大理石の小道
// 仕掛け (_Event 0〜1): 鐘が鳴り響き、芝生の鳩の群れが一斉に飛び立って、塔のまわりを旋回する
//
// 外から見たとき、建物のない所 (空) は透明にして、ガラスケースの向こうの部屋が見えるようにする。
// 中に入ったとき (カメラが箱の中) だけ、午後の空を描く
Shader "NightShards/Diorama/Pisa"
{
    Properties
    {
        _Steps ("Ray Steps", Range(16, 200)) = 140
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

            #define ID_BASE   0.0
            #define ID_GROUND 1.0
            #define ID_TOWER  2.0
            #define ID_DUOMO  3.0
            #define ID_BAPT   4.0
            #define ID_WALL   5.0
            #define ID_CAMPO  6.0

            // ※ 建物の場所を変えたら、C# の DioramaTerrain (PisaProps) も同じに直す (当たり判定。C# は回したあとの向きで書く)
            #define INNER 0.47
            #define GROUND -0.3
            #define BIRDS 40
            #define LEAN 0.0693                                    // 斜塔の傾き (3.97 度)
            #define BSCALE 1.35                                    // 建物を大きくする倍率 (広場の中心が基準。城壁はそのまま)
            static const float3 TOWER = float3(0.06, -0.3, 0.26);  // 斜塔の根元 (大聖堂の東南)
            static const float3 LEAN_DIR = float3(1.0, 0.0, 0.0);  // 傾く向き (南)
            static const float3 DUOMO = float3(0.0, -0.3, 0.0);    // 大聖堂 (正面は z = -0.065、後陣の端は z = 0.16)
            static const float3 BAPT = float3(0.0, -0.3, -0.22);   // 洗礼堂 (大聖堂の正面の西)
            static const float3 CAMPO = float3(-0.165, -0.3, -0.07); // カンポサント (北側)
            static const float3 SUN_DIR = float3(0.7, 0.45, -0.4); // 午後遅くの、南西からの日差し

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

            float SdEllipsoidLite(float3 p, float3 r)
            {
                float k0 = length(p / r);
                float k1 = length(p / (r * r));
                return k0 * (k0 - 1.0) / max(k1, 1e-6);
            }

            // 円のまわりに n 個並ぶものの、いちばん近い 1 個からの位置。ang は角度、r は中心からの距離。
            //   戻り値: x = 中心から外向きの距離、y = 横 (円周にそった) のずれ
            float2 RadialCell(float ang, float r, float n, float shift)
            {
                float sector = 6.2831853 / n;
                float a2 = (frac(ang / sector + 0.5 + shift) - 0.5) * sector;
                return float2(r * cos(a2), r * sin(a2));
            }

            // 半円アーチの形 (2D)。s は横の位置、y はアーチの付け根からの高さ、w はアーチの半分の幅。中ならマイナス
            float ArchShape(float s, float y, float w)
            {
                return y < 0.0 ? abs(s) - w : length(float2(s, y)) - w;
            }

            // 置いた場所 → 形を作った座標 (建物を BSCALE 倍に大きく見せるため、逆に縮める)
            float3 ToB(float3 p) { return float3(p.x / BSCALE, GROUND + (p.y - GROUND) / BSCALE, p.z / BSCALE); }
            float3 FromB(float3 p) { return float3(p.x * BSCALE, GROUND + (p.y - GROUND) * BSCALE, p.z * BSCALE); }

            // ---------------------------------------------------------------- 斜塔 (高さ 56 m・直径 15.5 m・南へ 3.97 度)

            // 斜塔の座標へ: 根元を原点にして、傾きを戻し、塔がまっすぐ立っている向きにする
            float3 TowerLocal(float3 p)
            {
                float3 q = p - TOWER;
                float3 k = normalize(float3(LEAN_DIR.z, 0.0, -LEAN_DIR.x)); // 傾きの回転軸
                float c = cos(-LEAN), s = sin(-LEAN);
                return q * c + cross(k, q) * s + k * dot(k, q) * (1.0 - c);
            }

            // 斜塔: 1 層目は 15 のめくらアーチと付け柱、2〜7 層目は 30 本の柱が並ぶ回廊 (6 段)、いちばん上に鐘楼。
            // part: 0 壁 / 1 柱 / 2 鐘楼の中 (暗い)
            float Tower(float3 p, out float part)
            {
                float3 q = TowerLocal(p);
                float r = length(q.xz);
                float y = q.y;
                part = 0;
                if (r > 0.022 || y > 0.127) return max(max(r - 0.019, y - 0.125), 0.001);
                float ang = atan2(q.z, q.x);
                // 土台の段
                float d = max(r - 0.0182, max(-y - 0.002, y - 0.0015));
                // 1 層目: 壁に、めくらアーチのくぼみと、半分埋まった付け柱
                if (y < 0.026)
                {
                    float2 c = RadialCell(ang, r, 15.0, 0.5);
                    float recess = max(ArchShape(c.y, y - 0.017, 0.0029), 0.0168 - r);
                    float wall = max(max(r - 0.0172, -recess), max(-y, y - 0.024));
                    float2 col = RadialCell(ang, r, 15.0, 0.0);
                    float pil = max(length(float2(col.x - 0.0172, col.y)) - 0.0006, max(0.0015 - y, y - 0.017));
                    d = min(d, min(wall, pil));
                }
                // 層の境の張り出し (7 か所)
                float level = clamp(round((y - 0.024) / 0.0141), 0.0, 6.0);
                float yl = 0.024 + level * 0.0141;
                float cornice = max(r - 0.0178, abs(y - yl) - 0.0006);
                d = min(d, cornice);
                // 回廊 (2〜7 層目)
                if (y > 0.024 && y < 0.1086)
                {
                    float k = floor((y - 0.024) / 0.0141);
                    float y0 = 0.024 + k * 0.0141;
                    float core = r - 0.0125;
                    // 柱: 30 本 (柱の上には、半円のアーチの帯)
                    float2 col = RadialCell(ang, r, 30.0, 0.0);
                    float column = max(length(float2(col.x - 0.0163, col.y)) - 0.00065, abs(y - (y0 + 0.005)) - 0.0045);
                    float2 gap = RadialCell(ang, r, 30.0, 0.5);
                    float band = max(abs(r - 0.01635) - 0.00085, abs(y - (y0 + 0.0118)) - 0.0023);
                    band = max(band, -ArchShape(gap.y, y - (y0 + 0.0095), 0.00106));
                    // 柱の上の柱頭 (少し太い)
                    float capital = max(length(float2(col.x - 0.0163, col.y)) - 0.0009, abs(y - (y0 + 0.0093)) - 0.0003);
                    float colAll = min(column, capital);
                    if (colAll < min(core, band)) part = 1;
                    d = min(d, min(core, min(band, colAll)));
                }
                // 鐘楼: ひとまわり細い円筒に、12 の大きなアーチの窓。中は暗く、鐘が見える
                if (y > 0.1080)
                {
                    float2 c = RadialCell(ang, r, 12.0, 0.5);
                    float shell = max(abs(r - 0.0108) - 0.0007, max(0.108 - y, y - 0.121));
                    shell = max(shell, -ArchShape(c.y, y - 0.115, 0.0021) * step(y, 0.119));
                    float top = max(r - 0.0122, abs(y - 0.1218) - 0.0008);
                    float inner = max(r - 0.008, max(0.108 - y, y - 0.12));
                    if (inner < min(shell, top)) part = 2;
                    d = min(d, min(min(shell, top), inner));
                }
                return d;
            }

            // ---------------------------------------------------------------- 大聖堂 (長さ 100 m・十字形・5 つの廊)

            // 断面 (x: 中心からの横の距離、y: 高さ) を、屋根つきの段で作る。中央が高く、外へ行くほど低い
            float Tier(float ax, float y, float halfW, float wallH, float slope)
            {
                return max(ax - halfW, max(-y, y - (wallH + (halfW - ax) * slope)));
            }

            float NaveProfile(float ax, float y)
            {
                float d = Tier(ax, y, 0.0148, 0.06, 0.54);       // 身廊: 切妻屋根
                d = min(d, Tier(ax, y, 0.026, 0.046, 0.54));     // 内側の側廊: 片流れ屋根
                d = min(d, Tier(ax, y, 0.035, 0.03, 0.67));      // 外側の側廊
                return d;
            }

            // 正面 (西) のファサード: 下は 7 つのめくらアーチと 3 つの扉、上に柱の並ぶ回廊が 4 段、てっぺんに三角の切妻
            float Facade(float3 q, out float part)
            {
                part = 0;
                float ax = abs(q.x);
                float z = q.z + 0.065;
                if (z > 0.004 || ax > 0.037) return max(z - 0.003, ax - 0.036);
                float prof = Tier(ax, q.y, 0.035, 0.04, 0.0);
                prof = min(prof, Tier(ax, q.y, 0.026, 0.05, 0.6));
                prof = min(prof, Tier(ax, q.y, 0.0148, 0.06, 0.54));
                float slab = max(prof, max(-z, z - 0.003));
                // 1 階: めくらアーチのくぼみ (幅 4.4 m ごと)、まん中と左右に扉
                float sx = q.x - round(q.x / 0.01) * 0.01;
                float arch = max(ArchShape(sx, q.y - 0.02, 0.0038), max(z - 0.0006, -q.y + 0.0005));
                arch = max(arch, ax - 0.0345);
                slab = max(slab, -arch);
                // 回廊: 4 段。手前 1.5 m がくぼみ、細い柱だけが残る
                float yy = q.y;
                float tierY = yy < 0.04 ? 0.035 : (yy < 0.05 ? 0.045 : (yy < 0.06 ? 0.0545 : 0.0628));
                float tierH = yy < 0.06 ? 0.0038 : 0.0018;
                float tierW = yy < 0.04 ? 0.0335 : (yy < 0.05 ? 0.0245 : (yy < 0.06 ? 0.0135 : 0.006));
                float gallery = max(max(abs(yy - tierY) - tierH, ax - tierW), z - 0.0015);
                slab = max(slab, -gallery);
                float cx = q.x - (round(q.x / 0.0022 - 0.5) + 0.5) * 0.0022;
                float cols = max(max(length(float2(cx, z - 0.0007)) - 0.00035, abs(yy - tierY) - tierH), ax - tierW);
                if (cols < slab) part = 1;
                return min(slab * 0.85, cols);
            }

            float Duomo(float3 p, out float part)
            {
                float3 q = p - DUOMO;
                part = 0;
                if (abs(q.x) > 0.095 || q.z < -0.07 || q.z > 0.165 || q.y > 0.11) return max(max(abs(q.x) - 0.092, max(-0.067 - q.z, q.z - 0.162)), max(q.y - 0.108, 0.001));
                float ax = abs(q.x);
                // 身廊と側廊 (正面から後陣のつけ根まで)
                float nave = max(NaveProfile(ax, q.y), max(-0.0635 - q.z, q.z - 0.145)) * 0.85;
                // 翼廊: 十字の横棒。両端に小さな後陣
                float dz = abs(q.z - 0.075);
                float tr = min(Tier(dz, q.y, 0.015, 0.055, 0.47), Tier(dz, q.y, 0.021, 0.035, 0.6));
                float transept = max(tr, ax - 0.079) * 0.85;
                float endApse = max(length(float2(ax - 0.079, q.z - 0.075)) - 0.012, max(0.079 - ax, q.y - 0.035));
                float endDome = max(SdEllipsoidLite(float3(ax - 0.079, q.y - 0.035, q.z - 0.075), float3(0.012, 0.007, 0.012)), 0.079 - ax);
                // 東の後陣: 半円の壁と、半分の丸屋根
                float apse = max(length(float2(q.x, q.z - 0.145)) - 0.0148, max(0.145 - q.z, q.y - 0.055));
                float apseDome = max(SdEllipsoidLite(float3(q.x, q.y - 0.055, q.z - 0.145), float3(0.0148, 0.009, 0.0148)), 0.145 - q.z);
                float d = min(min(nave, transept), min(min(endApse, endDome), min(apse, apseDome)));
                // 交差部の丸屋根: 楕円の太鼓 (まわりに小さな柱廊) と、とがり気味の楕円の丸屋根、頂上の小塔
                float3 cq = q - float3(0, 0, 0.075);
                float2 er = float2(0.0125, 0.0095);
                float ell = (length(cq.xz / er) - 1.0) * min(er.x, er.y);
                float drum = max(ell, max(0.06 - q.y, q.y - 0.078));
                float dome = SdEllipsoidLite(cq - float3(0, 0.078, 0), float3(0.0125, 0.023, 0.0095));
                float lantern = max(length(cq.xz) - 0.0018, abs(q.y - 0.103) - 0.004);
                float dom = min(drum, min(dome, lantern));
                if (dom < d) part = 2;
                d = min(d, dom);
                float fp;
                float fac = Facade(q, fp);
                if (fac < d) part = fp > 0.5 ? 1 : 0;
                return min(d, fac);
            }

            // ---------------------------------------------------------------- 洗礼堂 (直径 34 m・高さ 55 m)

            // part: 0 壁 / 1 柱 / 2 東半分の赤い瓦の屋根 / 3 西半分の鉛の屋根
            float Baptistery(float3 p, out float part)
            {
                float3 q = p - BAPT;
                float r = length(q.xz);
                part = 0;
                if (r > 0.044 || q.y > 0.123) return max(max(r - 0.041, q.y - 0.121), 0.001);
                float ang = atan2(q.z, q.x);
                float y = q.y;
                // 1 層目: 20 のめくらアーチと付け柱
                float2 c = RadialCell(ang, r, 20.0, 0.5);
                float recess = max(ArchShape(c.y, y - 0.03, 0.0045), 0.0371 - r);
                float d = max(max(r - 0.0375, -recess), max(-y, y - 0.04));
                float2 pc = RadialCell(ang, r, 20.0, 0.0);
                float pil = max(length(float2(pc.x - 0.0375, pc.y)) - 0.0008, max(-y, y - 0.03));
                // 2 層目: 細い柱の回廊と、その上のゴシックの三角の破風と小尖塔
                float wall2 = max(r - 0.0355, max(0.04 - y, y - 0.068));
                float2 g = RadialCell(ang, r, 60.0, 0.0);
                float col2 = max(length(float2(g.x - 0.0369, g.y)) - 0.0005, max(0.0405 - y, y - 0.056));
                float ledge = max(r - 0.0385, min(abs(y - 0.0402), abs(y - 0.0565)) - 0.0005);
                float2 gb = RadialCell(ang, r, 20.0, 0.5);
                float gable = max(max(abs(gb.x - 0.037) - 0.0006, (abs(gb.y) * 1.6 + (y - 0.068)) * 0.53), 0.057 - y);
                float2 pn = RadialCell(ang, r, 20.0, 0.0);
                float pinnacle = max(length(float2(pn.x - 0.0372, pn.y)) - 0.0012 * saturate((0.075 - y) / 0.018), max(0.057 - y, y - 0.075));
                // 3 層目: 少し細い円筒に、窓と小さな破風
                float wall3 = max(r - 0.0335, max(0.068 - y, y - 0.084));
                float2 w3 = RadialCell(ang, r, 20.0, 0.5);
                wall3 = max(wall3, -max(ArchShape(w3.y, y - 0.077, 0.0016), max(0.0325 - r, 0.071 - y)));
                float gable3 = max(max(abs(w3.x - 0.0338) - 0.0005, (abs(w3.y) * 1.6 + (y - 0.087)) * 0.53), 0.08 - y);
                float body = min(min(d, pil), min(min(wall2, ledge), min(wall3, gable3)));
                body = min(body, min(gable, pinnacle));
                float colAll = col2;
                if (colAll < body) part = 1;
                d = min(body, colAll);
                // 屋根: 丸屋根 (東は赤い瓦、西は鉛) を、てっぺんで円すいの屋根がつき抜ける。頂上に洗礼者ヨハネの像
                float dome = max(SdEllipsoidLite(q - float3(0, 0.084, 0), float3(0.0335, 0.022, 0.0335)), 0.084 - y);
                float cone = max(r - lerp(0.016, 0.0055, saturate((y - 0.098) / 0.016)), max(0.098 - y, y - 0.114));
                float statue = max(length(q.xz) - 0.0011, max(0.114 - y, y - 0.121));
                float roof = min(dome, cone);
                if (roof < d) part = q.z > 0.0 ? 2 : 3;
                d = min(d, roof);
                if (statue < d) part = 0;
                return min(d, statue);
            }

            // ---------------------------------------------------------------- カンポサント (墓所の回廊) と城壁

            float Camposanto(float3 p)
            {
                float3 q = p - CAMPO;
                float y = q.y;
                float e = max(abs(q.x) - 0.055, abs(q.z) - 0.14);
                if (e > 0.004 || y > 0.03) return max(max(e, y - 0.026), 0.001);
                float ring = max(e, -(e + 0.015));                     // 中庭を囲む、幅 33 m の回廊
                float roofH = 0.02 + min(-e, e + 0.015) * 0.6;          // 回廊の切妻屋根
                return max(ring, max(-y, y - roofH));
            }

            // 北と西のレンガの城壁 (上に、凸凹の狭間)
            float Wall(float3 p)
            {
                float y = p.y - GROUND;
                float alongZ = abs(p.x + 0.43) - 0.008;
                float alongX = abs(p.z + 0.43) - 0.008;
                float u = alongZ < alongX ? p.z : p.x;
                float crenel = step(0.5, frac(u / 0.008)) * 0.004;
                return max(min(alongZ, alongX), max(-y, y - (0.024 + crenel)));
            }

            // ---------------------------------------------------------------- 世界の形

            float2 Map(float3 p)
            {
                float2 res = float2(SdBox(p - float3(0, -0.46, 0), float3(0.5, 0.04, 0.5)), ID_BASE);
                float column = SdBox(p - float3(0, 0.04, 0), float3(INNER, 0.46, INNER));
                float ground = max(p.y - GROUND, column);
                if (ground < res.x) res = float2(ground, ID_GROUND);
                float part;
                float3 pb = ToB(p);
                float tower = Tower(pb, part) * BSCALE;
                if (tower < res.x) res = float2(tower, ID_TOWER);
                float duomo = Duomo(pb, part) * BSCALE;
                if (duomo < res.x) res = float2(duomo, ID_DUOMO);
                float bapt = Baptistery(pb, part) * BSCALE;
                if (bapt < res.x) res = float2(bapt, ID_BAPT);
                float campo = Camposanto(pb) * BSCALE;
                if (campo < res.x) res = float2(campo, ID_CAMPO);
                float wall = max(Wall(p), column);
                if (wall < res.x) res = float2(wall, ID_WALL);
                return res;
            }

            float3 SceneNormal(float3 p)
            {
                const float2 e = float2(0.0002, -0.0002);
                float3 g = e.xyy * Map(p + e.xyy).x + e.yyx * Map(p + e.yyx).x + e.yxy * Map(p + e.yxy).x + e.xxx * Map(p + e.xxx).x;
                return g / max(length(g), 1e-7);
            }

            float SoftShadow(float3 p, float3 l)
            {
                float res = 1.0;
                float t = 0.001;
                int n = max((int)_ShadowSteps, 8);
                for (int i = 0; i < 32; i++)
                {
                    if (i >= n) break;
                    float3 sp = p + l * t;
                    if (sp.y > -0.128) break; // いちばん高い建物より上に出たら、もう何にも当たらない
                    float h = Map(sp).x;
                    res = min(res, 24.0 * h / t);
                    t += clamp(h, 0.0008, 0.03);
                    if (res < 0.01 || t > 0.5) break;
                }
                return saturate(res);
            }

            float AmbientOcclusion(float3 p, float3 n)
            {
                float occ = 0.0;
                float w = 1.0;
                for (int i = 1; i <= 4; i++)
                {
                    float d = 0.003 * i;
                    occ += (d - Map(p + n * d).x) * w;
                    w *= 0.6;
                }
                return saturate(1.0 - occ * 30.0);
            }

            // ---------------------------------------------------------------- 鳩

            // 鳩 i 番の場所と飛ぶ向き。ふだんは東の芝生の上。仕掛けで飛び立ち、斜塔のまわりを回る
            float3 BirdPos(int i, out float3 dir, out float flying)
            {
                float fi = i;
                float t = _Time.y;
                float3 rest = float3(0.28 + 0.12 * Hash11(fi + 1.0), GROUND + 0.0006, -0.05 + 0.25 * Hash11(fi + 2.0));
                float a = t * (0.7 + 0.3 * Hash11(fi + 3.0)) + Hash11(fi + 4.0) * 6.2831;
                float rad = 0.04 + 0.06 * Hash11(fi + 5.0);
                float3 fly = FromB(TOWER) + float3(cos(a) * rad, 0.04 + 0.1 * Hash11(fi + 6.0) + 0.008 * sin(t * 1.3 + fi), sin(a) * rad);
                flying = smoothstep(0.3, 2.0, _EventTime - fi * 0.04) * saturate(_Event * 1.3) * step(0.001, _Event);
                dir = normalize(lerp(float3(1, 0, 0), float3(-sin(a), 0.0, cos(a)), flying));
                float lift = sin(flying * 3.1416) * 0.04; // 飛び立つときは、ふわっと上がる
                return lerp(rest, fly, flying) + float3(0, lift, 0);
            }

            float3 Birds(float3 ro, float3 rd, float tMax, float3 sunCol)
            {
                float3 col = 0;
                float t = _Time.y;
                for (int i = 0; i < BIRDS; i++)
                {
                    float3 dir;
                    float flying;
                    float3 pos = BirdPos(i, dir, flying);
                    float3 w = pos - ro;
                    float tc = dot(w, rd);
                    if (tc < 0.0 || tc > tMax + 0.001) continue;
                    float3 d = ro + rd * tc - pos;
                    float along = dot(d, dir);
                    float across2 = max(dot(d, d) - along * along, 0.0);
                    float flap = 0.5 + 0.5 * sin(t * 22.0 + i * 1.7);
                    float L = max(0.00035, tc * 0.0012);
                    float W = max(0.00022, tc * 0.0009) * lerp(1.0, 0.6 + 1.6 * flap, flying); // 羽ばたくと、横に広がったり縮んだり
                    float shape = exp(-(along * along / (L * L) + across2 / (W * W)));
                    // 鳩: 芝生の上では灰色、日を浴びて飛ぶと白っぽく光る
                    float3 feather = lerp(float3(0.32, 0.33, 0.36), float3(0.8, 0.8, 0.82), flying);
                    col += feather * (sunCol * 0.6 + 0.25) * shape * lerp(0.6, 1.0, flying);
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
                float3 c = lerp(float3(1.0, 0.82, 0.6), float3(0.35, 0.55, 0.9), pow(up, 0.6));
                float sd = dot(rd, normalize(SUN_DIR));
                c += float3(3.0, 2.6, 2.0) * smoothstep(0.9993, 0.9997, sd) + float3(0.6, 0.45, 0.25) * pow(saturate(sd), 30.0) * 0.4;
                return c;
            }

            // 白い大理石 (カラーラ近くのサン・ジュリアーノの石): クリーム色に、うっすらグレーの筋。下のほうは、年月で少しくすむ
            float3 Marble(float3 p, float y)
            {
                float vein = smoothstep(0.55, 0.75, Noise3(p * float3(500.0, 1500.0, 500.0)));
                float3 m = lerp(float3(0.93, 0.9, 0.84), float3(0.68, 0.68, 0.7), vein * 0.35);
                m *= 0.92 + 0.08 * Noise3(p * 4000.0);
                m *= lerp(0.86, 1.0, smoothstep(0.0, 0.02, y));
                return m;
            }

            // 石の積み目 (横の線と、互い違いの縦の線)
            float Ashlar(float u, float y, float h, float w)
            {
                float row = floor(y / h);
                float jy = abs(frac(y / h) - 0.5) * h;
                float jx = abs(frac(u / w + row * 0.5) - 0.5) * w;
                return step(h * 0.46, jy) + step(w * 0.48, jx);
            }

            float3 Shade(float3 ro, float3 rd, float3 p, float id, float3 faceNormal)
            {
                float3 L = normalize(SUN_DIR);
                float3 sunCol = float3(1.75, 1.35, 0.9);
                float3 skyTop = float3(0.32, 0.45, 0.7);
                float3 skyLow = float3(0.6, 0.5, 0.4);
                float3 v = -rd;

                if (id == ID_BASE)
                    return float3(0.015, 0.014, 0.014) + 0.03 * pow(saturate(1.0 - abs(dot(rd, faceNormal))), 4.0);

                float3 n = SceneNormal(p);
                float sh = SoftShadow(p + n * 0.0006, L);
                float ao = AmbientOcclusion(p, n);
                float y = p.y - GROUND;
                float3 lead = float3(0.46, 0.47, 0.5);
                // 建物と小道の模様は、形を作った座標で調べる
                float3 pw = p;
                if (id != ID_WALL)
                {
                    p = ToB(p);
                    y = p.y - GROUND;
                }

                if (id == ID_TOWER)
                {
                    float part;
                    Tower(p, part);
                    float3 q = TowerLocal(p);
                    float r = length(q.xz);
                    float ang = atan2(q.z, q.x);
                    float3 m = Marble(p, y);
                    if (part > 1.5)
                    {
                        // 鐘楼の中: 暗がりに、ブロンズの鐘。鐘が鳴ると、揺れて光る
                        float swing = sin(_Time.y * 6.0) * _Event;
                        float3 bronze = float3(0.45, 0.3, 0.12);
                        float3 bc = Surface(bronze, n, v, L, sunCol, sh, ao, 0.3, 0.6, 0.0, skyTop, skyLow);
                        return bc * 0.4 + float3(1.2, 0.8, 0.35) * 0.3 * abs(swing);
                    }
                    if (part < 0.5)
                    {
                        // 壁: 石の積み目。1 層目のアーチのくぼみには、ひし形の象眼 (色の違う大理石のはめこみ)
                        float u = ang * r;
                        m *= 1.0 - 0.12 * saturate(Ashlar(u, q.y, 0.00072, 0.0016));
                        if (q.y < 0.024 && r < 0.01705 && r > 0.0165)
                        {
                            float2 c = RadialCell(ang, r, 15.0, 0.5);
                            float2 lz = float2(c.y, q.y - 0.02);
                            float lozenge = step(abs(lz.x) + abs(lz.y), 0.0012) - step(abs(lz.x) + abs(lz.y), 0.0008);
                            m = lerp(m, float3(0.35, 0.36, 0.38), lozenge * 0.7);
                        }
                        // 回廊の奥の壁: 戸口のアーチが並ぶ (暗い)
                        if (r < 0.0128 && q.y > 0.024)
                        {
                            float k = frac((q.y - 0.024) / 0.0141) * 0.0141;
                            float2 c = RadialCell(ang, r, 15.0, 0.5);
                            float door = step(ArchShape(c.y, k - 0.006, 0.0012), 0.0);
                            m *= 1.0 - 0.75 * door;
                        }
                    }
                    float3 nb = BumpNormal(n, p, 6000.0, 0.15);
                    return Surface(m, nb, v, L, sunCol, sh, ao, 0.28, 0.05, 0.3, skyTop, skyLow);
                }

                if (id == ID_DUOMO)
                {
                    float part;
                    Duomo(p, part);
                    float3 q = p - DUOMO;
                    float3 m = Marble(p, y);
                    float u = abs(n.x) > abs(n.z) ? q.z : q.x;
                    bool roof = n.y > 0.35 && y > 0.028;
                    if (part > 1.5 && q.y > 0.079)
                    {
                        // 丸屋根: 鉛の板と、縦の筋 (リブ)
                        float a = atan2(q.z - 0.075, q.x);
                        float rib = step(abs(frac(a * 24.0 / 6.2831853) - 0.5), 0.06);
                        float3 alb = lead * (1.0 - 0.2 * rib);
                        return Surface(alb, n, v, L, sunCol, sh, ao, 0.4, 0.25, 0.0, skyTop, skyLow);
                    }
                    if (roof)
                    {
                        // 屋根: 灰色の鉛の板。継ぎ目の筋
                        float seam = step(abs(frac(u / 0.0018) - 0.5), 0.05);
                        return Surface(lead * (1.0 - 0.15 * seam), n, v, L, sunCol, sh, ao, 0.45, 0.2, 0.0, skyTop, skyLow);
                    }
                    if (part > 1.5)
                    {
                        // 丸屋根の太鼓: 小さな柱の回廊 (柱のすき間は暗い)
                        float a = atan2(q.z - 0.075, q.x);
                        float gap = step(0.55, frac(a * 40.0 / 6.2831853)) * step(abs(q.y - 0.07), 0.004);
                        m *= 1.0 - 0.7 * gap;
                    }
                    else if (part < 0.5)
                    {
                        // 壁: 下のほうはグレーと白の大理石の縞 (2.4 m ごと)。壁には、付け柱とめくらアーチ、ひし形の象眼
                        float stripe = step(0.6, frac(q.y / 0.0011)) * step(q.y, 0.031);
                        m = lerp(m, float3(0.5, 0.52, 0.56), stripe * 0.75);
                        m *= 1.0 - 0.1 * saturate(Ashlar(u, q.y, 0.00055, 0.0014));
                        bool side = abs(n.x) > 0.7 || abs(n.z) > 0.7;
                        if (side)
                        {
                            float bay = 0.0075;
                            float s = (frac(u / bay) - 0.5) * bay;
                            float pil = step(bay * 0.42, abs(s));
                            float lowTop = q.y < 0.031 ? 0.026 : (q.y < 0.047 ? 0.042 : 0.056);
                            float archLine = step(abs(length(float2(s, max(q.y - lowTop + 0.003, 0.0))) - 0.0033), 0.0003) * step(lowTop - 0.003, q.y) * step(q.y, lowTop + 0.0005);
                            float2 lz = float2(s, q.y - (lowTop - 0.001));
                            float lozenge = step(abs(lz.x) * 1.2 + abs(lz.y), 0.0011) * (1.0 - step(abs(lz.x) * 1.2 + abs(lz.y), 0.0007));
                            m *= 1.0 - 0.15 * pil - 0.3 * archLine;
                            m = lerp(m, float3(0.3, 0.32, 0.36), lozenge * 0.6);
                        }
                        // 正面のブロンズの扉 (まん中と左右)
                        float z = q.z + 0.065;
                        if (z < 0.0012 && n.z < -0.5)
                        {
                            float door = step(abs(q.x), 0.0034) * step(q.y, 0.016) + step(abs(abs(q.x) - 0.02), 0.0028) * step(q.y, 0.012);
                            float panel = step(0.15, abs(frac(q.y / 0.0016) - 0.5)) * step(0.1, abs(frac(q.x / 0.0017) - 0.5));
                            float3 bronze = float3(0.32, 0.21, 0.09) * (0.7 + 0.3 * panel);
                            if (door > 0.5)
                                return Surface(bronze, n, v, L, sunCol, sh, ao, 0.35, 0.55, 0.0, skyTop, skyLow);
                        }
                        // 正面の回廊の奥の壁: 影になり、色の大理石の象眼の模様
                        if (z > 0.001 && z < 0.0018 && q.y > 0.03)
                            m *= 0.55 + 0.15 * step(0.5, frac((q.x + q.y) / 0.0012));
                    }
                    float3 nb = BumpNormal(n, p, 6000.0, 0.15);
                    return Surface(m, nb, v, L, sunCol, sh, ao, 0.3, 0.05, 0.3, skyTop, skyLow);
                }

                if (id == ID_BAPT)
                {
                    float part;
                    Baptistery(p, part);
                    float3 q = p - BAPT;
                    float r = length(q.xz);
                    float ang = atan2(q.z, q.x);
                    if (part > 1.5)
                    {
                        // 屋根: 東の半分は赤い瓦 (横の段々)、西の半分は鉛の板
                        float3 tiles = float3(0.66, 0.32, 0.2) * (0.8 + 0.25 * Hash21(floor(float2(ang * 60.0, q.y / 0.0012))));
                        tiles *= 1.0 - 0.3 * step(0.8, frac(q.y / 0.0012));
                        float3 alb = part < 2.5 ? tiles : lead * (1.0 - 0.15 * step(abs(frac(ang * 48.0 / 6.2831853) - 0.5), 0.05));
                        return Surface(alb, n, v, L, sunCol, sh, ao, part < 2.5 ? 0.7 : 0.4, part < 2.5 ? 0.04 : 0.22, 0.0, skyTop, skyLow);
                    }
                    float3 m = Marble(p, y);
                    // 1 層目はグレーと白の縞。積み目
                    float stripe = step(0.6, frac(q.y / 0.0011)) * step(q.y, 0.04);
                    m = lerp(m, float3(0.52, 0.54, 0.58), stripe * 0.7);
                    m *= 1.0 - 0.1 * saturate(Ashlar(ang * r, q.y, 0.00055, 0.0015));
                    // 3 層目の窓の奥は暗い
                    if (r < 0.0333 && q.y > 0.071 && q.y < 0.084) m *= 0.3;
                    float3 nb = BumpNormal(n, p, 6000.0, 0.15);
                    return Surface(m, nb, v, L, sunCol, sh, ao, 0.3, 0.05, 0.3, skyTop, skyLow);
                }

                if (id == ID_CAMPO)
                {
                    float3 q = p - CAMPO;
                    if (n.y > 0.35)
                        return Surface(lead, n, v, L, sunCol, sh, ao, 0.45, 0.2, 0.0, skyTop, skyLow);
                    // 外の壁: 白い大理石に、細長いめくらアーチが並ぶ
                    float3 m = Marble(p, y);
                    float u = abs(n.x) > abs(n.z) ? q.z : q.x;
                    float s = (frac(u / 0.008) - 0.5) * 0.008;
                    float archLine = step(abs(length(float2(s, max(q.y - 0.014, 0.0))) - 0.0034), 0.0003) * step(0.014, q.y);
                    float pil = step(0.0034, abs(s)) * step(q.y, 0.0145);
                    m *= 1.0 - 0.18 * saturate(archLine + pil);
                    m *= 1.0 - 0.1 * saturate(Ashlar(u, q.y, 0.00055, 0.0015));
                    return Surface(m, BumpNormal(n, p, 6000.0, 0.15), v, L, sunCol, sh, ao, 0.3, 0.05, 0.3, skyTop, skyLow);
                }

                if (id == ID_WALL)
                {
                    // レンガの城壁
                    float u = abs(p.x + 0.43) < abs(p.z + 0.43) ? p.z : p.x;
                    float2 bq = float2(u / 0.0006 + floor(y / 0.00022) * 0.5, y / 0.00022);
                    float joint = smoothstep(0.08, 0.0, min(frac(bq.x), frac(bq.y)));
                    float3 brick = float3(0.62, 0.34, 0.22) * (0.8 + 0.3 * Hash21(floor(bq))) * (1.0 - 0.5 * joint);
                    return Surface(brick, BumpNormal(n, p, 3000.0, 0.5), v, L, sunCol, sh, ao, 0.85, 0.03, 0.0, skyTop, skyLow);
                }

                if (max(abs(pw.x), abs(pw.z)) > INNER - 0.0015 && abs(n.y) < 0.5)
                    return Surface(float3(0.22, 0.17, 0.12) * (0.8 + 0.4 * Noise3(p * 900.0)), n, v, L, sunCol, 1.0, 1.0, 0.9, 0.03, 0.0, skyTop, skyLow); // 地面の切り口 (土)

                // 地面: 刈り込んだ芝生 (縞模様) と、建物をつなぐ大理石の小道
                float2 tw = p.xz - TOWER.xz;
                float2 bp = p.xz - BAPT.xz;
                bool paved = length(tw) < 0.03 || length(bp) < 0.048
                          || (abs(p.x) < 0.045 && p.z > -0.075 && p.z < 0.172)
                          || (abs(p.x) < 0.092 && abs(p.z - 0.075) < 0.026)
                          || (abs(p.x) < 0.008 && p.z > -0.2 && p.z < -0.065)
                          || (abs(p.x - 0.03) < 0.006 && p.z > 0.15 && p.z < 0.26)
                          || p.x > 0.43;
                float3 albedo;
                float rough, bump, sss;
                if (paved)
                {
                    float2 g = abs(frac(p.xz / float2(0.0013, 0.0009) + float2(0.0, floor(p.x / 0.0013) * 0.5)) - 0.5);
                    albedo = float3(0.78, 0.74, 0.66) * (0.85 + 0.15 * Hash21(floor(p.xz / 0.0013))) * (1.0 - 0.25 * step(0.45, max(g.x, g.y)));
                    rough = 0.5;
                    bump = 0.3;
                    sss = 0.0;
                }
                else
                {
                    float stripes = 0.88 + 0.12 * step(0.5, frac(p.z / 0.012));
                    albedo = float3(0.2, 0.42, 0.12) * stripes * (0.8 + 0.3 * Noise3(p * 1500.0));
                    rough = 0.85;
                    bump = 0.9;
                    sss = 0.5;
                }
                float3 nb = BumpNormal(n, p, 3000.0, bump);
                return Surface(albedo, nb, v, L, sunCol, sh, ao, rough, 0.04, sss, skyTop, skyLow);
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
                // 向きを回す: 箱の +z (美術館の正面) を南に、+x を西にする
                ro = float3(ro.z, ro.y, -ro.x);
                rd = float3(rd.z, rd.y, -rd.x);
                float2 box = BoxHit(ro, rd, float3(0.5, 0.5, 0.5));
                bool outside = box.x > 0.0;
                float t = max(box.x, 0.0);

                float3 entry = ro + rd * t;
                float3 ae = abs(entry);
                float3 faceNormal = ae.x > ae.y && ae.x > ae.z ? float3(sign(entry.x), 0, 0)
                                  : (ae.y > ae.z ? float3(0, sign(entry.y), 0) : float3(0, 0, sign(entry.z)));

                const float maxHeight = -0.128; // 斜塔と洗礼堂のてっぺんより少し上 (大きくしたあと)
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
                    // 当たったとみなす近さ: 遠いほど大きく (遠くの細い柱は、1 画素くらいの太さで描く)
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
                if (hit) col = Shade(ro, rd, ro + rd * t, id, faceNormal);
                else if (!outside) col = Sky(rd);

                float travel = tHit - max(box.x, 0.0);
                if (hit) col = lerp(col, float3(0.75, 0.68, 0.6), (1.0 - exp(-travel * 0.5)) * 0.35);

                float alpha = (hit || !outside) ? 1.0 : 0.0;
                col += Birds(ro, rd, tHit, float3(1.75, 1.35, 0.9));

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
