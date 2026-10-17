// 作品「ギザのピラミッド」(砂漠と塩の間)。夕暮れの三大ピラミッドとスフィンクス。URP 用。
// Cube の中をレイマーチングして描く。Cube の座標は -0.5〜0.5、下の 0.08 は黒い台。
//
// 形は実物の寸法 (1 m = 0.0011)。並びは実物の地図の位置を 0.77 倍に詰めたもの。美術館の正面 (+z) が東。
//   ・クフ王のピラミッド: 底辺 230 m・今の高さ 139 m (頂上は平ら。元の頂点の高さに、目印の柱)。北の面に入口。東に 3 つの王妃のピラミッド
//   ・カフラー王のピラミッド: 底辺 215 m・高さ 136 m。10 m 高い岩盤の上に立つので、いちばん高く見える。頂上に、なめらかな化粧石が残る
//   ・メンカウラー王のピラミッド: 底辺 102 m・高さ 65 m。下の段は赤い花こう岩。南に 3 つの王妃のピラミッド
//   ・大スフィンクス: 長さ 73 m・高さ 20 m・幅 19 m。東を向いて、掘り下げた岩の囲いの中に伏せる。
//     顔: 幅 4.1 m。眉、深く彫られたアーモンド形の目 (まぶたと眼球)、付け根だけ残って欠けた鼻、幅 2.3 m の唇と口の線、あご、耳。
//     ネメス頭巾: 平らぎみの頭頂、額のふち、聖蛇 (ウラエウス) のあと、下ほど広がる左右の垂れ布、後ろの束。横じまの溝
//     胴: 風で削られた地層の段、腰、たたんだ後ろ足、右の腰に巻きつく尾。前にのびる前足と 4 つの指。
//     前足のあいだに夢の碑文 (花こう岩の石碑)。足元は、あとから修理した石積み
//   ・石は 1.5 m ほどの段に積まれ、近くで見ると階段のようにギザギザ。砂丘と風紋、ラクダの隊列
// 仕掛け (_Event 0〜1): 西から砂嵐が吹き抜け、ピラミッドがかすむ。過ぎ去ると、夕日がいっそう強く赤く差す
//
// 外から見たとき、何もない所 (空) は透明にして、ガラスケースの向こうの部屋が見えるようにする。
// 中に入ったとき (カメラが箱の中) だけ、夕焼けの空を描く
Shader "NightShards/Diorama/Pyramids"
{
    Properties
    {
        _Steps ("Ray Steps", Range(16, 200)) = 160
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

            float SdEllipsoidLite(float3 p, float3 r)
            {
                float k0 = length(p / r);
                float k1 = length(p / (r * r));
                return k0 * (k0 - 1.0) / max(k1, 1e-6);
            }

            float SdRoundBox(float3 p, float3 b, float r) { return SdBox(p, b - r) - r; }

            float SdCapsule(float3 p, float3 a, float3 b, float r)
            {
                float3 pa = p - a, ba = b - a;
                float h = saturate(dot(pa, ba) / dot(ba, ba));
                return length(pa - ba * h) - r;
            }

            // ---------------------------------------------------------------- 場所と寸法 (1 m = 0.0011)
            // ※ ここと Height() を変えたら、C# の DioramaTerrain (Pyramids) も同じに直す (歩く地面と当たり判定)

            #define ID_BASE    0.0
            #define ID_GROUND  1.0
            #define ID_PYRAMID 2.0
            #define ID_SPHINX  3.0
            #define ID_CAMEL   4.0

            #define GROUND -0.3
            #define COURSE 0.0016                                  // 石の段の高さ (約 1.5 m)
            static const float2 KHUFU = float2(-0.3, 0.11);
            static const float2 KHAFRE = float2(-0.008, -0.169);
            static const float2 MENKAURE = float2(0.332, -0.39);
            static const float2 SPHINX = float2(0.068, 0.389);
            static const float3 SUN_DIR = float3(0.6, 0.16, -0.78);  // 南西の低い夕日

            // ---------------------------------------------------------------- 地面

            // ギザの台地: 西 (-z) へ行くほど高い
            float Plateau(float z) { return GROUND + 0.012 * smoothstep(-0.25, 0.35, -z); }

            // 長方形の台 (中心 c・半分の大きさ hs) の外へ、幅 w で元の地面にもどる割合 (台の上は 0)
            float PadMask(float2 xz, float2 c, float2 hs, float w)
            {
                float2 d = abs(xz - c) - hs;
                return smoothstep(0.0, w, max(d.x, d.y));
            }

            // 地面の高さ: 台地と砂丘。ピラミッドの下は平らにならし、スフィンクスのまわりは掘り下げた囲い
            float Height(float2 xz)
            {
                float h = Plateau(xz.y) + 0.008 * Fbm3(xz * 7.0 + 3.7);
                // ならした台の高さは、まわりの砂丘のふつうの高さ (+0.0035) にそろえる (台がくぼんで見えないように)
                h = lerp(Plateau(KHUFU.y) + 0.0035, h, PadMask(xz, float2(-0.3, 0.15), float2(0.135, 0.17), 0.04));
                h = lerp(Plateau(KHAFRE.y) + 0.0035, h, PadMask(xz, KHAFRE, float2(0.125, 0.125), 0.04));
                h = lerp(Plateau(MENKAURE.y) + 0.0035, h, PadMask(xz, float2(0.36, -0.39), float2(0.09, 0.065), 0.04));
                h = lerp(GROUND - 0.008, h, PadMask(xz, SPHINX, float2(0.028, 0.05), 0.006));
                return h;
            }

            float HeightFast(float2 xz)
            {
                [branch] if (_HeightTexOn > 0.5)
                    return SAMPLE_TEXTURE2D_LOD(_HeightTex, sampler_linear_clamp, xz / (2.0 * INNER) + 0.5, 0).r;
                return Height(xz);
            }

            // ---------------------------------------------------------------- ピラミッド

            // 石を段に積んだピラミッド。q は底の中心から。hs は底辺の半分、h0 は元の頂点の高さ、top は今の高さ。
            // 段は 1 段ずつ箱にして、今の段と上下の段だけを調べる。
            // cased より上は、なめらかな化粧石 (カフラー王の頂上)。layer に何段目かを返す
            float StepPyramid(float3 q, float hs, float h0, float top, float cased, out float layer)
            {
                float y = q.y;
                float ax = max(abs(q.x), abs(q.z));
                layer = floor(y / COURSE);
                float slope = hs / h0;
                float plane = (ax - hs + max(y, 0.0) * slope) * rsqrt(1.0 + slope * slope);
                float far = max(max(plane, -y - 0.012), y - top);
                if (far > 0.004) return far - 0.001; // 段は少し外へはみ出すので、その分だけ控えめに
                float d = 1e5;
                for (int j = -1; j <= 1; j++)
                {
                    float k = layer + j;
                    if (k < 0.0) continue;
                    float y0 = k * COURSE;
                    if (y0 >= top || y0 >= cased) continue;
                    float y1 = min(min(y0 + COURSE, top), cased);
                    float w = hs * (1.0 - (y0 + COURSE * 0.5) / h0);
                    float yb = k < 0.5 ? -0.012 : y0; // いちばん下の段は、地面の下まで深くのばす (地面とすきまができないように)
                    d = min(d, SdBox(float3(q.x, y - (yb + y1) * 0.5, q.z), float3(w, (y1 - yb) * 0.5, w)));
                }
                if (cased < top)
                    d = min(d, max(max(plane, cased - COURSE - y), y - top));
                return d;
            }

            // 3 つのピラミッドと、6 つの王妃のピラミッド。part: 0 石灰岩 / 1 化粧石 / 2 花こう岩 / 3 目印の柱
            float Pyramids(float3 p, out float part)
            {
                part = 0;
                float layer;
                float d = 1e5;
                // クフ王: 底辺 230.3 m・元の高さ 146.6 m・今の高さ 138.5 m
                // 底の高さは、描いている地面と同じ高さ (中心の真下) に合わせる
                float3 q = p - float3(KHUFU.x, HeightFast(KHUFU), KHUFU.y);
                d = StepPyramid(q, 0.1267, 0.1613, 0.1524, 1.0, layer);
                float mast = max(length(q.xz) - 0.0003, max(0.1524 - q.y, q.y - 0.1613));
                if (mast < d) part = 3;
                d = min(d, mast);
                // クフ王の王妃のピラミッド (東に 3 つ)
                for (int i = 0; i < 3; i++)
                {
                    float3 qq = q - float3(-0.06 + i * 0.06, 0, 0.162);
                    float dq = StepPyramid(qq, 0.024, 0.033, 0.03, 1.0, layer);
                    if (dq < d) part = 0;
                    d = min(d, dq);
                }
                // カフラー王: 底辺 215.3 m・元の高さ 143.5 m・今の高さ 136.4 m。上の 25 m に化粧石が残る
                q = p - float3(KHAFRE.x, HeightFast(KHAFRE), KHAFRE.y);
                float dk = StepPyramid(q, 0.1184, 0.1579, 0.15, 0.123, layer);
                if (dk < d) part = q.y > 0.122 ? 1 : 0;
                d = min(d, dk);
                // メンカウラー王: 底辺 102.2 m・元の高さ 65.5 m・今の高さ 61 m。下の 16 段は赤い花こう岩
                q = p - float3(MENKAURE.x, HeightFast(MENKAURE), MENKAURE.y);
                float dm = StepPyramid(q, 0.0567, 0.072, 0.067, 1.0, layer);
                if (dm < d) part = q.y < 16.0 * COURSE ? 2 : 0;
                d = min(d, dm);
                for (int k = 0; k < 3; k++)
                {
                    float3 qq = q - float3(0.0867, 0, -0.045 + k * 0.045);
                    float dq = StepPyramid(qq, 0.016, 0.022, 0.02, 1.0, layer);
                    if (dq < d) part = 0;
                    d = min(d, dq);
                }
                return d;
            }

            // ---------------------------------------------------------------- 大スフィンクス (長さ 73 m・高さ 20 m・幅 19 m。東 = +z を向く)
            // 形は 1 m = 1 の「メートルの座標」で作り、最後に 0.0011 倍する。原点は胴の真下の囲いの床、+z が顔の向き、+x が右 (南)

            float SMin(float a, float b, float k)
            {
                float h = saturate(0.5 + 0.5 * (b - a) / k);
                return lerp(b, a, h) - k * h * (1.0 - h);
            }

            float SMax(float a, float b, float k) { return -SMin(-a, -b, k); }

            // 頭: 顔 (目・鼻のあと・唇・あご・耳) とネメス頭巾。part: 0 石 / 1 顔 / 2 目のくぼみ
            float SphinxHead(float3 m, inout float part)
            {
                float3 s = float3(abs(m.x), m.y, m.z);
                // 顔の土台: 幅 4.1 m、生え際からあごまで 5 m
                float face = SdEllipsoidLite(m - float3(0, 15.9, 4.45), float3(2.0, 2.75, 2.05));
                float chin = SdEllipsoidLite(m - float3(0, 13.9, 5.3), float3(1.25, 0.85, 0.95));
                float cheek = SdEllipsoidLite(s - float3(1.1, 15.3, 5.0), float3(0.95, 1.2, 1.1));
                float d = SMin(SMin(face, chin, 0.5), cheek, 0.6);
                // 眉の張り出しと、深く彫られたアーモンド形の目 (上まぶた・下まぶた・眼球)
                float brow = SdEllipsoidLite(s - float3(0.95, 17.2, 5.95), float3(0.7, 0.17, 0.32));
                d = SMin(d, brow, 0.3);
                float socket = SdEllipsoidLite(s - float3(0.85, 16.75, 6.4), float3(0.6, 0.28, 0.28));
                d = SMax(d, -socket, 0.15);
                float eyeball = SdEllipsoidLite(s - float3(0.85, 16.75, 6.08), float3(0.48, 0.22, 0.2));
                if (eyeball < d) part = 2;
                d = min(d, eyeball);
                // 鼻: 付け根だけ残り、先は欠けて平らに削れている (幅 1.7 m)
                float nose = SdCapsule(m, float3(0, 17.0, 6.15), float3(0, 15.9, 6.4), 0.38);
                nose = max(nose, m.z - 6.38);
                d = SMin(d, nose, 0.3);
                // 唇 (幅 2.3 m): 上唇と下唇、そのあいだの口の線、口の両はしのくぼみ
                float lipU = SdEllipsoidLite(m - float3(0, 14.95, 6.15), float3(1.15, 0.3, 0.4));
                float lipL = SdEllipsoidLite(m - float3(0, 14.45, 6.0), float3(1.0, 0.32, 0.38));
                d = SMin(d, min(lipU, lipL), 0.2);
                d = max(d, -SdBox(m - float3(0, 14.7, 6.45), float3(1.05, 0.05, 0.45)));
                // 耳: 頭巾の前に出る (高さ 1.4 m)
                float ear = SdEllipsoidLite(s - float3(1.95, 16.4, 4.4), float3(0.28, 0.85, 0.55));
                d = SMin(d, ear, 0.15);
                if (d < 0.3) part = max(part, 1.0);
                // ネメス頭巾: 頭をおおう布。額の帯から、耳の後ろを通り、肩の上で広がる垂れ布
                // 頭のてっぺんは平らぎみ。後ろへ少し下がる
                float crown = SdBox(m - float3(0, 17.9, 3.2), float3(2.35, 1.6, 2.6) - 0.9) - 0.9;
                crown = max(crown, (m.y - 19.6) + max(3.0 - m.z, 0.0) * 0.25);
                crown = max(crown, -(SdEllipsoidLite(m - float3(0, 15.8, 6.0), float3(2.05, 2.75, 2.2)))); // 顔の前をあける
                float band = SdCapsule(s, float3(0, 18.5, 5.1), float3(2.0, 18.0, 4.2), 0.12);           // 額の帯 (頭巾のふち)
                // 左右の垂れ布: 耳の後ろから肩へ、下ほど外へ広がる台形 (正面から見ると、頭全体が台形になる)
                float outer = s.x - (2.25 + max(17.6 - m.y, 0.0) * 0.32);
                float lappet = max(max(outer, 1.7 - s.x), max(abs(m.y - 14.4) - 3.3, abs(m.z - 4.0) - 1.0));
                lappet = max(lappet, -(SdEllipsoidLite(m - float3(0, 15.6, 6.0), float3(2.15, 3.2, 2.0))));
                lappet *= 0.9;
                float queue = SdCapsule(m, float3(0, 16.0, 1.0), float3(0, 12.5, 0.2), 0.9);            // 後ろに垂れる束
                float nemes = min(min(crown, band), min(lappet, queue));
                // 額の聖蛇 (ウラエウス) のあと
                float uraeus = length(m - float3(0, 18.55, 5.45)) - 0.22;
                nemes = min(nemes, uraeus);
                if (nemes < d) part = 0;
                return min(d, nemes);
            }

            float SphinxM(float3 m, out float part)
            {
                part = 0;
                float3 s = float3(abs(m.x), m.y, m.z);
                // 胴: 伏せた獅子の長い背中 (背中は高さ 14 m ほど、腰へ向かって少し下がる)
                float back = 13.0 - max(-m.z - 20.0, 0.0) * 0.06;
                float body = SdBox(m - float3(0, back * 0.5, -24.0), float3(5.6, back * 0.5, 26.0) - 2.5) - 2.5;
                // 風で削られた地層: やわらかい層ほど深くへこみ、横の縞の段になる
                body += 0.35 * (0.5 + 0.5 * sin(m.y * 2.4)) * smoothstep(3.5, 5.0, m.y);
                float haunch = SdEllipsoidLite(s - float3(5.0, 5.5, -40.0), float3(4.3, 5.5, 8.0));
                float hindLeg = SdEllipsoidLite(s - float3(6.8, 2.0, -33.0), float3(2.4, 2.0, 9.0));
                float chest = SdEllipsoidLite(m - float3(0, 7.8, 2.5), float3(6.2, 7.6, 5.2));
                float neck = SdEllipsoidLite(m - float3(0, 12.6, 2.4), float3(4.2, 4.2, 3.6));
                float d = SMin(body, chest, 2.0);
                d = SMin(d, SMin(haunch, hindLeg, 1.0), 1.5);
                d = SMin(d, neck, 1.5);
                // 前足: 胸から前へ 15 m。指先は 4 つのふくらみ
                float foreleg = SdEllipsoidLite(s - float3(5.2, 3.6, 2.5), float3(2.8, 3.6, 4.0));
                float paw = SdBox(s - float3(5.0, 1.9, 13.0), float3(2.6, 1.9, 9.0) - 1.0) - 1.0;
                float toes = 1e5;
                for (int k = 0; k < 4; k++)
                    toes = min(toes, SdEllipsoidLite(s - float3(3.3 + k * 1.15, 1.3, 21.7), float3(0.6, 1.2, 0.8)));
                float legs = SMin(SMin(foreleg, paw, 1.0), toes, 0.4);
                d = SMin(d, legs, 1.0);
                // 尾: 右の腰に巻きつく
                d = min(d, SdCapsule(m, float3(4.0, 1.0, -48.0), float3(8.6, 1.4, -38.0), 0.65));
                d = min(d, SdCapsule(m, float3(8.6, 1.4, -38.0), float3(8.9, 2.4, -30.0), 0.55));
                // 夢の碑文 (トトメス 4 世の石碑): 前足のあいだに立つ、上の丸い花こう岩の板 (高さ 3.6 m)
                float stela = max(SdBox(m - float3(0, 1.8, 6.6), float3(1.1, 1.8, 0.35)), length(m.xy - float2(0, 2.5)) - 1.95);
                if (stela < d) part = 3;
                d = min(d, stela);
                // 頭
                float hp = 0;
                float head = SphinxHead(m, hp);
                if (head < d) part = hp;
                return min(d, head);
            }

            float Sphinx(float3 p, out float part)
            {
                part = 0;
                float3 q = p - float3(SPHINX.x, GROUND - 0.008, SPHINX.y + 0.0155);
                float3 c = q - float3(0, 0.011, -0.0155);
                if (length(c) > 0.05) return length(c) - 0.046;
                return SphinxM(q / 0.0011, part) * 0.0011 * 0.65;
            }

            // ---------------------------------------------------------------- ラクダの隊列

            #define CAMELS 4
            float3 CamelPos(int i, out float2 dir)
            {
                // 東の砂漠を、南から北へゆっくり進み、また南から現れる
                float t = _Time.y;
                float u = frac(t * 0.006 + 0.3) * 1.0;
                float x = lerp(0.45, -0.1, u) + i * 0.012;
                float z = 0.3 + 0.02 * sin(x * 9.0);
                dir = normalize(float2(-1.0, 0.18 * cos(x * 9.0)));
                return float3(x, HeightFast(float2(x, z)), z);
            }

            float Camels(float3 p)
            {
                if (p.y > GROUND + 0.02 || p.z < 0.26 || p.z > 0.34) return max(max(p.y - GROUND - 0.016, 0.26 - p.z), max(p.z - 0.34, 0.003));
                float d = 1e5;
                float t = _Time.y;
                for (int i = 0; i < CAMELS; i++)
                {
                    float2 dir;
                    float3 c = CamelPos(i, dir);
                    float3 r = p - c;
                    if (dot(r, r) > 0.006 * 0.006) { d = min(d, length(r) - 0.004); continue; }
                    // ラクダの向きにそろえる (x が前)
                    float3 q = float3(dot(r.xz, dir), r.y, dot(r.xz, float2(-dir.y, dir.x)));
                    float body = SdEllipsoidLite(q - float3(0, 0.0019, 0), float3(0.0013, 0.00055, 0.00045));
                    float hump = SdEllipsoidLite(q - float3(-0.0001, 0.0025, 0), float3(0.0006, 0.00045, 0.0004));
                    float neck = SdCapsule(q, float3(0.0011, 0.0021, 0), float3(0.0018, 0.0028, 0), 0.00018);
                    float head = SdEllipsoidLite(q - float3(0.0021, 0.0028, 0), float3(0.00035, 0.00016, 0.00014));
                    float rider = SdCapsule(q, float3(-0.0001, 0.0028, 0), float3(-0.0001, 0.0036, 0), 0.00022);
                    float legs = 1e5;
                    for (int k = 0; k < 4; k++)
                    {
                        float fx = k < 2 ? 0.0009 : -0.0009;
                        float fz = (k % 2 == 0) ? 0.0003 : -0.0003;
                        float swing = sin(t * 4.0 + i * 1.3 + k * 1.57) * 0.0003;
                        legs = min(legs, SdCapsule(q, float3(fx, 0.0016, fz), float3(fx + swing, 0.0, fz), 0.00012));
                    }
                    d = min(d, min(min(min(body, hump), min(neck, head)), min(rider, legs)));
                }
                return d;
            }

            // ---------------------------------------------------------------- 世界の形

            float2 MapX(float3 p, bool exact)
            {
                float2 res = float2(SdBox(p - float3(0, -0.46, 0), float3(0.5, 0.04, 0.5)), ID_BASE);
                float column = SdBox(p - float3(0, 0.04, 0), float3(INNER, 0.46, INNER));
                float h = exact ? Height(p.xz) : HeightFast(p.xz);
                float ground = max((p.y - h) * 0.85, column);
                if (ground < res.x) res = float2(ground, ID_GROUND);
                float part;
                float pyr = Pyramids(p, part);
                if (pyr < res.x) res = float2(pyr, ID_PYRAMID);
                float sph = Sphinx(p, part);
                if (sph < res.x) res = float2(sph, ID_SPHINX);
                float cam = Camels(p);
                if (cam < res.x) res = float2(cam, ID_CAMEL);
                return res;
            }

            float2 Map(float3 p) { return MapX(p, false); }

            float3 SceneNormal(float3 p)
            {
                const float2 e = float2(0.0002, -0.0002);
                float3 g = e.xyy * MapX(p + e.xyy, true).x + e.yyx * MapX(p + e.yyx, true).x + e.yxy * MapX(p + e.yxy, true).x + e.xxx * MapX(p + e.xxx, true).x;
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
                    if (sp.y > -0.13) break; // ピラミッドより上に出たら、もう何にも当たらない
                    float h = Map(sp).x;
                    res = min(res, 16.0 * h / t);
                    t += clamp(h, 0.001, 0.05);
                    if (res < 0.01 || t > 1.4) break;
                }
                return saturate(res);
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
                return saturate(1.0 - occ * 18.0);
            }

            // ---------------------------------------------------------------- 仕掛け: 砂嵐と、そのあとの夕日

            // 砂嵐の強さ (最初の 6〜9 秒)、夕日の強まり (そのあと)
            float Storm() { return _Event * (1.0 - smoothstep(5.5, 9.0, _EventTime)); }
            float Blaze() { return _Event * smoothstep(6.0, 9.5, _EventTime); }

            // 砂嵐の濃さ: 低い所ほど濃く、西から東へ (+z へ) 流れる
            float Dust(float3 p)
            {
                float y = p.y - GROUND;
                float3 q = p * float3(9.0, 14.0, 9.0) - float3(0, 0, _Time.y * 1.6);
                float n = Noise3(q) * 0.6 + Noise3(q * 2.3 + 7.1) * 0.4;
                return saturate(n * 1.6 - 0.35) * exp(-max(y, 0.0) / 0.09);
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

            // 夕焼けの空: 地平線は橙と桃色、上は紫がかった青。西に沈みかけの太陽
            float3 Sky(float3 rd)
            {
                float3 L = normalize(SUN_DIR);
                float up = saturate(rd.y);
                float blaze = Blaze();
                float3 c = lerp(float3(1.0, 0.55, 0.3), float3(0.18, 0.2, 0.42), pow(up, 0.45));
                c = lerp(c, float3(0.95, 0.5, 0.55), exp(-up * 6.0) * 0.35 * (1.0 - saturate(dot(rd.xz, normalize(L.xz)))));
                float sd = dot(rd, L);
                float3 sun = float3(4.0, 2.4, 1.0) * (1.0 + blaze);
                c += sun * smoothstep(0.9994, 0.9997, sd) + float3(1.0, 0.45, 0.15) * pow(saturate(sd), 12.0) * (0.5 + 0.8 * blaze);
                // 細い雲が夕日に染まる
                float2 cp = rd.xz / max(rd.y + 0.08, 0.02);
                float cloud = smoothstep(0.55, 0.8, Fbm3(cp * float2(1.2, 4.0) + 3.0)) * smoothstep(0.02, 0.15, rd.y) * (1.0 - smoothstep(0.25, 0.6, rd.y));
                c = lerp(c, float3(1.0, 0.5, 0.35) * (0.6 + 0.8 * pow(saturate(sd * 0.5 + 0.5), 4.0)), cloud * 0.6);
                return c;
            }

            float3 Shade(float3 ro, float3 rd, float3 p, float id, float3 faceNormal)
            {
                float3 L = normalize(SUN_DIR);
                float storm = Storm();
                float blaze = Blaze();
                float3 sunCol = float3(2.6, 1.35, 0.6) * (1.0 - 0.75 * storm) * (1.0 + 0.6 * blaze) * lerp(float3(1, 1, 1), float3(1.1, 0.8, 0.6), blaze);
                float3 skyTop = float3(0.12, 0.13, 0.27);
                float3 skyLow = float3(0.42, 0.26, 0.2) * (1.0 + 1.5 * storm);
                float3 v = -rd;

                if (id == ID_BASE)
                    return float3(0.015, 0.014, 0.014) + 0.03 * pow(saturate(1.0 - abs(dot(rd, faceNormal))), 4.0);

                float3 n = SceneNormal(p);
                float sh = SoftShadow(p + n * 0.0006, L);
                float ao = AmbientOcclusion(p, n);

                if (id == ID_PYRAMID)
                {
                    float part;
                    Pyramids(p, part);
                    if (part > 2.5)
                        return Surface(float3(0.35, 0.3, 0.25), n, v, L, sunCol, sh, ao, 0.6, 0.04, 0.0, skyTop, skyLow); // 目印の柱
                    // 石の積み方: 段ごとに、横に 1.2〜1.8 m の石が互い違いに並ぶ。石ごとに色と風化が少し違う
                    float layer = floor((p.y - GROUND) / COURSE);
                    float u = abs(n.x) > abs(n.z) ? p.z : p.x;
                    float bw = 0.0017 + 0.0005 * Hash21(float2(layer, 3.0));
                    float bi = floor(u / bw + Hash21(float2(layer, 7.0)));
                    float bf = frac(u / bw + Hash21(float2(layer, 7.0)));
                    float stone = Hash21(float2(bi, layer));
                    float3 lime = float3(0.82, 0.66, 0.46) * (0.82 + 0.25 * stone) * (0.85 + 0.15 * Noise3(p * 3000.0));
                    float joint = (1.0 - smoothstep(0.0, 0.06, min(bf, 1.0 - bf))) * step(abs(n.y), 0.7);
                    lime *= 1.0 - 0.35 * joint;
                    float rough = 0.85;
                    if (part > 0.5 && part < 1.5)
                    {
                        lime = float3(0.9, 0.82, 0.68) * (0.92 + 0.08 * Noise3(p * 2000.0)); // なめらかな化粧石
                        rough = 0.45;
                    }
                    if (part > 1.5)
                        lime = float3(0.58, 0.36, 0.3) * (0.8 + 0.3 * stone);                 // 赤い花こう岩
                    // クフ王の北の面の入口 (少し東寄り。暗い穴)
                    float3 kq = p - float3(KHUFU.x, Plateau(KHUFU.y), KHUFU.y);
                    if (n.x < -0.3 && abs(kq.z + 0.008) < 0.0022 && abs(kq.y - 0.018) < 0.003) lime *= 0.15;
                    float3 nb = BumpNormal(n, p, 4000.0, 0.35);
                    return Surface(lime, nb, v, L, sunCol, sh, ao, rough, 0.04, 0.0, skyTop, skyLow);
                }

                if (id == ID_SPHINX)
                {
                    float part;
                    Sphinx(p, part);
                    float3 m = (p - float3(SPHINX.x, GROUND - 0.008, SPHINX.y + 0.0155)) / 0.0011; // メートルの座標
                    if (part > 2.5)
                    {
                        // 夢の碑文: 赤みのある花こう岩に、文字と絵の彫りの行
                        float3 gr = float3(0.48, 0.36, 0.33) * (0.85 + 0.2 * Noise3(p * 6000.0));
                        gr *= 1.0 - 0.25 * step(0.75, frac(m.y / 0.25)) * step(m.y, 2.6);
                        return Surface(gr, n, v, L, sunCol, sh, ao, 0.5, 0.05, 0.0, skyTop, skyLow);
                    }
                    // 石灰岩の地層: 下 (硬い灰色がかった層)、胴 (風で削られた黄土色と白の縞)、頭 (きめの細かい層)
                    float band = frac(m.y / 1.3);
                    float3 rock = lerp(float3(0.8, 0.62, 0.42), float3(0.64, 0.48, 0.32), smoothstep(0.35, 0.65, band));
                    if (m.y < 3.5) rock = float3(0.66, 0.58, 0.48);
                    if (m.y > 13.5) rock = float3(0.82, 0.66, 0.46);
                    rock *= 0.85 + 0.2 * Noise3(p * 2500.0);
                    // 足元と前足の、あとから修理した石積み (明るい四角い石)
                    if (m.y < 3.8 && (abs(m.x) > 2.4 || m.z < 4.0))
                    {
                        float row = floor(m.y / 0.7);
                        float2 b = frac(float2((m.z + abs(m.x)) / 1.1 + row * 0.5, m.y / 0.7));
                        float joint = step(0.9, max(b.x, b.y));
                        rock = lerp(float3(0.84, 0.74, 0.6), float3(0.5, 0.42, 0.33), joint) * (0.9 + 0.15 * Hash21(floor(float2((m.z + abs(m.x)) / 1.1 + row * 0.5, row))));
                    }
                    // ネメス頭巾の縞 (横の溝)。顔にかすかに残る赤い顔料
                    if (part < 0.5 && m.y > 12.0) rock *= 1.0 - 0.2 * step(0.55, frac(m.y / 0.55));
                    if (part > 0.5 && part < 1.5) rock = lerp(rock, float3(0.78, 0.5, 0.36), 0.25);
                    if (part > 1.5) rock *= 0.6;
                    // 欠けた鼻のあと: ざらざらの割れ口
                    if (part > 0.5 && abs(m.x) < 0.55 && m.y > 15.5 && m.y < 17.1 && m.z > 6.35) rock *= 0.8 + 0.2 * Noise3(p * 20000.0);
                    // 顔の細かいくぼみ (目・唇・耳のまわり) を暗くする: 小さな距離で調べる陰
                    float cav = 0.0;
                    for (int k = 1; k <= 3; k++)
                    {
                        float dd = 0.00025 * k;
                        cav += (dd - Map(p + n * dd).x) / dd;
                    }
                    rock *= saturate(1.0 - cav * 0.35);
                    float3 nb = BumpNormal(n, p, 3000.0, m.y > 13.5 ? 0.25 : 0.7);
                    return Surface(rock, nb, v, L, sunCol, sh, ao, 0.9, 0.03, 0.0, skyTop, skyLow);
                }

                if (id == ID_CAMEL)
                    return Surface(float3(0.45, 0.32, 0.2), n, v, L, sunCol, sh, ao, 0.9, 0.03, 0.0, skyTop, skyLow);

                if (max(abs(p.x), abs(p.z)) > INNER - 0.0015 && abs(n.y) < 0.5)
                    return Surface(float3(0.5, 0.36, 0.22) * (0.8 + 0.4 * Noise3(p * 900.0)), n, v, L, sunCol, 1.0, 1.0, 0.9, 0.03, 0.0, skyTop, skyLow); // 地面の切り口

                // 砂: 風紋 (風に直角な細かい波)。ピラミッドのまわりは、石のかけらまじりの固い地面
                float rip = sin(dot(p.xz, float2(0.35, 0.94)) * 2600.0 + Noise3(p * 400.0) * 6.0);
                float3 nr = normalize(n + float3(0.35, 0.0, 0.94) * rip * 0.12);
                float rocky = 1.0 - min(min(PadMask(p.xz, float2(-0.3, 0.15), float2(0.135, 0.17), 0.04), PadMask(p.xz, KHAFRE, float2(0.125, 0.125), 0.04)),
                                        PadMask(p.xz, float2(0.36, -0.39), float2(0.09, 0.065), 0.04));
                float3 sand = float3(0.86, 0.62, 0.38) * (0.85 + 0.2 * Noise3(p * 600.0));
                float3 hard = float3(0.78, 0.58, 0.38) * (0.85 + 0.2 * Hash21(floor(p.xz / 0.0012)));
                float3 albedo = lerp(sand, hard, rocky * 0.5);
                float3 nb = lerp(nr, BumpNormal(n, p, 3000.0, 0.6), rocky);
                float3 col = Surface(albedo, nb, v, L, sunCol, sh, ao, 0.9, 0.03, 0.0, skyTop, skyLow);
                // 砂嵐の最中: 地面を走る砂の筋
                if (storm > 0.01)
                {
                    float streak = smoothstep(0.6, 0.9, Noise3(float3(p.x * 300.0, 0, p.z * 40.0 - _Time.y * 8.0)));
                    col += float3(0.9, 0.6, 0.35) * streak * storm * 0.08;
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

                const float maxHeight = -0.135; // カフラー王のピラミッドのてっぺんより少し上
                if (ro.y > maxHeight && rd.y < 0.0) t = max(t, (maxHeight - ro.y) / rd.y);
                float tStart = t;

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
                // 地面すれすれを進む線は、歩みが細かくなって回数が足りなくなる。そのときは、ほぼ届いていれば当たりにする
                // (足りないまま空の色にすると、地面に明るいすきまの帯ができる)
                if (!hit && ranOut && lastD < 0.0005 + 0.002 * t)
                {
                    hit = true;
                    id = lastId;
                }
                float tHit = hit ? t : box.y;

                float3 col = 0;
                if (hit) col = Shade(ro, rd, ro + rd * t, id, faceNormal);
                else if (!outside) col = Sky(rd);

                // 夕方の空気: 遠くほど、橙色にかすむ
                float travel = tHit - max(box.x, 0.0);
                if (hit) col = lerp(col, float3(0.95, 0.6, 0.4), (1.0 - exp(-travel * 0.6)) * 0.15);
                float alpha = (hit || !outside) ? 1.0 : 0.0;

                // 砂嵐: 視線にそって砂の濃さを足し合わせる (仕掛けの最中だけ)
                float storm = Storm();
                if (storm > 0.01)
                {
                    float3 L = normalize(SUN_DIR);
                    float t0 = max(box.x, 0.0);
                    float t1 = min(tHit, t0 + 1.2);
                    float dt = (t1 - t0) / 12.0;
                    float trans = 1.0;
                    float3 dust = 0;
                    for (int k = 0; k < 12; k++)
                    {
                        float3 pos = ro + rd * (t0 + dt * (k + Hash21(input.positionCS.xy + k)));
                        if (max(abs(pos.x), abs(pos.z)) > INNER) continue;
                        float dens = Dust(pos) * storm * 14.0;
                        float a = 1.0 - exp(-dens * dt);
                        float3 lit = float3(1.0, 0.62, 0.36) * (0.45 + 0.6 * pow(saturate(dot(rd, L) * 0.5 + 0.5), 3.0));
                        dust += trans * a * lit;
                        trans *= 1.0 - a;
                    }
                    col = col * trans + dust;
                    alpha = alpha + (1.0 - alpha) * (1.0 - trans);
                }

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
