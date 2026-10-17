// 作品「日本の庭」(アジアの間)。秋の金閣寺 (鹿苑寺)。鏡湖池に映る、金色の舎利殿。URP 用。
// Cube の中をレイマーチングして描く。Cube の座標は -0.5〜0.5、下の 0.08 は黒い台。
//
// 形は実物の寸法 (1 m = 0.008)。美術館の正面 (+z) が南。池の南の岸から、北の舎利殿を見る、いちばん有名な眺め。
//   ・舎利殿 (金閣): 3 層。1 層は寝殿造りの白木の柱と白い蔀戸 (法水院)、2 層は金箔の武家造り (潮音洞)、
//     3 層は金箔の禅宗様の仏殿 (究竟頂)、花頭窓。こけら葺きの屋根が 3 重に張り出し、てっぺんに金の鳳凰。池に張り出した舟着き
//   ・鏡湖池: 静かな水面が、金閣と紅葉と空を、鏡のように映す。葦原島 (松の島) と、小さな島々・岩
//   ・まわり: 赤・橙・黄色のもみじと、緑の松。奥は衣笠山
// 仕掛け (_Event 0〜1): 風が吹き、もみじの葉が舞い散って、池の水面に浮かんでいく
//
// 外から見たとき、何もない所 (空) は透明にして、ガラスケースの向こうの部屋が見えるようにする。
// 中に入ったとき (カメラが箱の中) だけ、空を描く
Shader "NightShards/Diorama/Kinkaku"
{
    Properties
    {
        _Steps ("Ray Steps", Range(16, 200)) = 150
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

            // ---------------------------------------------------------------- 場所と寸法 (1 m = 0.008)
            // ※ Height と金閣の場所を変えたら、C# の DioramaTerrain (Kinkaku) も同じに直す (歩く地面と当たり判定)

            #define ID_BASE    0.0
            #define ID_GROUND  1.0
            #define ID_WOOD    2.0   // 1 層の白木
            #define ID_GOLD    3.0   // 金箔
            #define ID_ROOF    4.0   // こけら葺きの屋根
            #define ID_PLASTER 5.0   // 白い壁・蔀戸
            #define ID_WINDOW  6.0   // 暗い窓・戸口

            #define GROUND -0.28
            #define WATER -0.286                                   // 池の水面
            #define LEAVES 60
            static const float3 KINKAKU = float3(0.02, -0.28, -0.2);  // 舎利殿の中心 (1 層の床の高さ)
            #define KS 2.0                                          // 金閣を大きくする倍率 (形は 1 m = 0.008 で作り、2 倍に置く)
            static const float3 SUN_DIR = float3(-0.45, 0.6, 0.66);  // 南東からの、秋の日差し

            // ---------------------------------------------------------------- 地形

            // 池の形: 1 より小さい所が池 (東西に長い、くねった形)
            float PondShape(float2 xz)
            {
                float2 q = (xz - float2(0.0, 0.07)) / float2(0.44, 0.24);
                float wob = 0.12 * (ValueNoise(xz * 6.0 + 2.0) - 0.5) + 0.06 * sin(xz.x * 14.0);
                return length(q) + wob;
            }

            // 島: 葦原島 (大きな松の島) と、小さな島々
            float Islands(float2 xz)
            {
                float a = 1.0 - smoothstep(0.03, 0.06, length((xz - float2(-0.17, 0.08)) * float2(1.0, 1.4)));
                float b = 1.0 - smoothstep(0.008, 0.02, length(xz - float2(0.2, 0.02)));
                float c = 1.0 - smoothstep(0.006, 0.016, length(xz - float2(0.3, 0.12)));
                float d = 1.0 - smoothstep(0.005, 0.013, length(xz - float2(0.1, 0.16)));
                return max(max(a, b), max(c, d));
            }

            // 木の生えている所 (0〜1)。池・金閣のまわり・手前の参道には生えない
            float TreeMask(float2 xz)
            {
                float shore = smoothstep(1.05, 1.18, PondShape(xz));
                float nearK = smoothstep(0.05, 0.08, max(abs(xz.x - KINKAKU.x) - 0.14, abs(xz.y - KINKAKU.z) - 0.11));
                float path = smoothstep(0.26, 0.3, xz.y) * (1.0 - smoothstep(0.36, 0.42, abs(xz.x))); // 手前 (南) の岸と参道は木がない (両はしだけ木)
                float island = smoothstep(0.3, 0.6, Islands(xz));
                return max(shore * nearK * (1.0 - path), island);
            }

            // 木々の上面のでこぼこ (もこもこした木の頭)
            float Canopy(float2 xz)
            {
                float c = 0.5 * ValueNoise(xz * 70.0) + 0.3 * ValueNoise(xz * 150.0 + 3.0) + 0.2 * ValueNoise(xz * 25.0 + 9.0);
                return 0.018 + 0.03 * c;
            }

            float Height(float2 xz)
            {
                float pond = PondShape(xz);
                // 奥 (北) の衣笠山と、まわりのゆるやかな起伏
                float h = GROUND + 0.004 * ValueNoise(xz * 10.0) + 0.22 * smoothstep(0.22, 0.47, -xz.y) * (0.7 + 0.3 * Fbm3(xz * 5.0));
                // 池の底と岸
                h = lerp(GROUND - 0.022, h, smoothstep(0.92, 1.02, pond));
                h = max(h, lerp(GROUND - 0.03, GROUND - 0.002 + 0.002 * ValueNoise(xz * 80.0), smoothstep(0.0, 0.6, Islands(xz))));
                // 金閣の土台: 平らにならす
                float k = 1.0 - smoothstep(0.0, 0.015, max(abs(xz.x - KINKAKU.x) - 0.14, abs(xz.y - KINKAKU.z) - 0.11));
                h = lerp(h, GROUND, k);
                // 木々 (島の松は、低くまるい)
                float tm = TreeMask(xz);
                float isl = Islands(xz);
                h += Canopy(xz) * tm * lerp(1.0, 0.6 * isl, smoothstep(0.05, 0.3, isl));
                return h;
            }

            float HeightFast(float2 xz)
            {
                [branch] if (_HeightTexOn > 0.5)
                    return SAMPLE_TEXTURE2D_LOD(_HeightTex, sampler_linear_clamp, xz / (2.0 * INNER) + 0.5, 0).r;
                return Height(xz);
            }

            // ---------------------------------------------------------------- 金閣 (舎利殿)

            // 屋根: 上へ行くほどすぼまる台形 (軒先は、少し反り上がる)
            float RoofShape(float3 q, float2 hs, float y0, float y1, float slope)
            {
                float y = q.y - y0;
                float2 a = abs(q.xz) - hs + max(y, 0.0) * slope;
                float body = max(max(a.x, a.y) * 0.6, max(-y + 0.0006 * (1.0 - saturate((max(abs(q.x) - hs.x, abs(q.z) - hs.y) + 0.004) / 0.004)), y - (y1 - y0)));
                return body;
            }

            // 建物の壁と柱: hs は半分の大きさ、y0〜y1 の高さ。柱の間隔 bay
            float Story(float3 q, float2 hs, float y0, float y1, float bay, out float part)
            {
                part = 0;
                float y = q.y;
                float outer = SdBox(q - float3(0, (y0 + y1) * 0.5, 0), float3(hs.x, (y1 - y0) * 0.5, hs.y));
                // 壁は柱より少し奥
                float wall = SdBox(q - float3(0, (y0 + y1) * 0.5, 0), float3(hs.x - 0.0012, (y1 - y0) * 0.5, hs.y - 0.0012));
                float2 pc = float2(q.x - round(q.x / bay) * bay, q.z - round(q.z / bay) * bay);
                float2 a = abs(q.xz) - hs;
                float onEdge = max(a.x, a.y);
                float shell = max(onEdge, -(onEdge + 0.003));     // 外まわりの、厚さ 3 mm の所だけ
                // 柱: 前後の面では x の位置、左右の面では z の位置に並ぶ
                float postLine = (a.y > a.x ? abs(pc.x) : abs(pc.y)) - 0.0012;
                float posts = max(max(postLine, shell), abs(y - (y0 + y1) * 0.5) - (y1 - y0) * 0.5);
                // 柱と柱の間の横木 (上と下)
                float beams = max(shell, min(abs(y - y1 + 0.0015), abs(y - y0 - 0.001)) - 0.0012);
                float frame = min(posts, beams);
                if (wall < frame) part = 1;
                return min(max(outer, min(wall, frame)), min(wall, frame));
            }

            float Kinkaku(float3 p, out float id)
            {
                id = ID_WOOD;
                float3 q = (p - KINKAKU) / KS;  // 形を作った座標へ (KS 倍に大きく見せる)
                if (max(abs(q.x) - 0.11, max(abs(q.z) - 0.1, q.y - 0.115)) > 0.004) return max(max(abs(q.x) - 0.105, abs(q.z) - 0.095), q.y - 0.11) * KS;
                float d = 1e5, dd;
                float part;
                // 石の基壇と、池に張り出した舟着き (南西)
                dd = SdBox(q - float3(0, 0.0015, 0), float3(0.066, 0.0035, 0.053));
                dd = min(dd, SdBox(q - float3(-0.045, 0.0005, 0.065), float3(0.016, 0.0025, 0.016)));
                if (dd < d) { d = dd; id = ID_ROOF; }
                // 1 層 (法水院): 白木の柱と、白い蔀戸。南は開け放した縁側
                dd = Story(q, float2(0.0608, 0.048), 0.005, 0.028, 0.0243, part);
                if (dd < d) { d = dd; id = part > 0.5 ? ID_PLASTER : ID_WOOD; }
                // 1 層の屋根 (ひさし)
                dd = RoofShape(q, float2(0.075, 0.062), 0.028, 0.034, 1.1);
                if (dd < d) { d = dd; id = ID_ROOF; }
                // 2 層 (潮音洞): 金箔。南に縁の手すり
                dd = Story(q, float2(0.058, 0.046), 0.034, 0.056, 0.0232, part);
                float rail = max(SdBox(q - float3(0, 0.0365, 0.051), float3(0.06, 0.0025, 0.0045)), -SdBox(q - float3(0, 0.0365, 0.051), float3(0.059, 0.0015, 0.0035)));
                dd = min(dd, rail);
                if (dd < d) { d = dd; id = ID_GOLD; }
                // 2 層の屋根
                dd = RoofShape(q, float2(0.072, 0.06), 0.056, 0.063, 1.0);
                if (dd < d) { d = dd; id = ID_ROOF; }
                // 3 層 (究竟頂): 金箔の正方形の仏殿。花頭窓
                float dq = SdBox(q - float3(0, 0.072, 0), float3(0.029, 0.009, 0.029));
                float3 w = float3(abs(q.x), q.y - 0.071, abs(q.z));
                float u = w.x > w.z ? q.z : q.x;
                float um = abs(u - round(u / 0.0195) * 0.0195);
                // 花頭窓: 上が火炎の形にとがる窓 (くぼみ)
                float arch = max(um - 0.0045 + max(w.y, 0.0) * 0.6, abs(w.y) - 0.0055);
                float face = abs(max(w.x, w.z) - 0.029) - 0.001;
                bool win = max(arch, face) < 0.0;
                dd = dq;
                if (dd < d) { d = dd; id = win ? ID_WINDOW : ID_GOLD; }
                // 3 層の屋根: 宝形造り (四方から頂上へ。反りのあるこけら葺き)
                float y = q.y - 0.081;
                float2 a = abs(q.xz);
                float m = max(a.x, a.y);
                float roof = max(m - (0.05 - y * 1.9 + y * y * 14.0), max(-y, y - 0.022)) * 0.5;
                if (roof < d) { d = roof; id = ID_ROOF; }
                // 金の鳳凰 (頂上)
                float ph = SdBox(q - float3(0, 0.106, 0), float3(0.002, 0.004, 0.0012));
                ph = min(ph, SdBox(q - float3(0, 0.107, 0.0), float3(0.0006, 0.0015, 0.0035)));
                if (ph < d) { d = ph; id = ID_GOLD; }
                return d * KS;
            }

            // ---------------------------------------------------------------- 世界の形 (水面は別に計算する)

            float2 MapX(float3 p, bool exact)
            {
                float2 res = float2(SdBox(p - float3(0, -0.46, 0), float3(0.5, 0.04, 0.5)), ID_BASE);
                float column = SdBox(p - float3(0, 0.04, 0), float3(INNER, 0.46, INNER));
                float ground;
                if (exact) ground = (p.y - Height(p.xz)) * 0.5;
                else
                {
                    // 高さの表で進む。地面から遠い所は、木々のふちの急な所でも行き過ぎない歩幅。近い所だけ、坂の急さで歩幅を広げる
                    float h = HeightFast(p.xz);
                    float above = p.y - h;
                    if (above > 0.006) ground = above * 0.3;
                    else
                    {
                        float hx = HeightFast(p.xz + float2(0.002, 0.0)), hz = HeightFast(p.xz + float2(0.0, 0.002));
                        float2 g = float2(hx - h, hz - h) / 0.002;
                        ground = above * 0.8 / sqrt(1.0 + dot(g, g) * 1.5);
                    }
                }
                ground = max(ground, column);
                if (ground < res.x) res = float2(ground, ID_GROUND);
                float kid;
                float k = Kinkaku(p, kid);
                if (k < res.x) res = float2(k, kid);
                return res;
            }

            float2 Map(float3 p) { return MapX(p, false); }

            float3 SceneNormal(float3 p)
            {
                const float2 e = float2(0.0002, -0.0002);
                float3 g = e.xyy * MapX(p + e.xyy, true).x + e.yyx * MapX(p + e.yyx, true).x + e.yxy * MapX(p + e.yxy, true).x + e.xxx * MapX(p + e.xxx, true).x;
                return g / max(length(g), 1e-12);
            }

            float SoftShadow(float3 p, float3 l)
            {
                float res = 1.0;
                float t = 0.0015;
                int n = clamp((int)_ShadowSteps, 8, 16);
                for (int i = 0; i < 16; i++)
                {
                    if (i >= n) break;
                    float3 sp = p + l * t;
                    if (sp.y > 0.0 || max(abs(sp.x), abs(sp.z)) > INNER) break;
                    float h = Map(sp).x;
                    res = min(res, 14.0 * h / t);
                    t += clamp(h, 0.001, 0.05);
                    if (res < 0.01 || t > 0.4) break;
                }
                return saturate(res);
            }

            float AmbientOcclusion(float3 p, float3 n)
            {
                float occ = 0.0;
                float w = 1.0;
                for (int i = 1; i <= 3; i++)
                {
                    float d = 0.004 * i;
                    occ += (d - Map(p + n * d).x) * w;
                    w *= 0.6;
                }
                return saturate(1.0 - occ * 25.0);
            }

            // ---------------------------------------------------------------- 仕掛け: 舞い散るもみじ

            float Wind() { return _Event; }

            // i 番目の葉の場所 (金閣のまわりの木から、風で舞いながら池へ落ちる)
            float3 LeafPos(int i)
            {
                float fi = i;
                float life = 6.0;
                float t = _EventTime + Hash11(fi) * life;
                float u = frac(t / life);
                float3 start = float3(-0.4 + 0.8 * Hash11(fi + 1.0), GROUND + 0.06 + 0.06 * Hash11(fi + 2.0), -0.3 + 0.1 * Hash11(fi + 3.0));
                float3 drift = float3(0.12 + 0.08 * Hash11(fi + 4.0), -0.08, 0.25 + 0.1 * Hash11(fi + 5.0));
                float3 pos = start + drift * u + 0.012 * float3(sin(t * 3.0 + fi), sin(t * 2.3 + fi * 1.7), cos(t * 2.7 + fi));
                pos.y = max(pos.y, WATER);
                return pos;
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

            float3 Sky(float3 rd)
            {
                float3 L = normalize(SUN_DIR);
                float up = saturate(rd.y);
                float3 c = lerp(float3(0.78, 0.84, 0.92), float3(0.25, 0.47, 0.85), pow(up, 0.5));
                float2 cp = rd.xz / max(rd.y + 0.05, 0.02);
                float cloud = smoothstep(0.55, 0.8, Fbm3(cp * float2(1.5, 2.5) + 3.0)) * smoothstep(0.03, 0.15, rd.y) * (1.0 - smoothstep(0.3, 0.6, rd.y));
                c = lerp(c, float3(1.0, 1.0, 1.0), cloud * 0.7);
                float sd = dot(rd, L);
                c += float3(4.0, 3.6, 3.0) * smoothstep(0.9994, 0.9997, sd) + float3(0.5, 0.45, 0.35) * pow(saturate(sd), 20.0) * 0.3;
                return c;
            }

            float3 Shade(float3 ro, float3 rd, float3 p, float id, float3 faceNormal, bool lite)
            {
                float3 L = normalize(SUN_DIR);
                float3 sunCol = float3(2.1, 1.9, 1.6);
                float3 skyTop = float3(0.28, 0.42, 0.72);
                float3 skyLow = float3(0.5, 0.48, 0.42);
                float3 v = -rd;

                if (id == ID_BASE)
                    return float3(0.015, 0.014, 0.014) + 0.03 * pow(saturate(1.0 - abs(dot(rd, faceNormal))), 4.0);

                float3 n = SceneNormal(p);
                float sh = lite ? 1.0 : SoftShadow(p + n * 0.0008, L);
                float ao = lite ? 1.0 : AmbientOcclusion(p, n);
                float3 q = (p - KINKAKU) / KS;

                if (id == ID_GOLD)
                {
                    // 金箔: よく光る金属。空とまわりの紅葉を映す。箔の継ぎ目のかすかな格子
                    float2 g = abs(frac(float2(q.x + q.z, q.y) / 0.0024) - 0.5);
                    float3 gold = float3(1.0, 0.6, 0.14) * (0.9 + 0.1 * step(0.46, max(g.x, g.y)));
                    // 金属なので、色は「映ったもの × 金色」。上は空、下は紅葉と池の色
                    float3 r = reflect(rd, n);
                    float3 env = lerp(float3(0.5, 0.22, 0.08), Sky(r) * 0.75, saturate(r.y * 2.5 + 0.2));
                    float ndl = saturate(dot(n, L));
                    float3 h = normalize(L + v);
                    float spec = pow(saturate(dot(n, h)), 60.0) * 2.0;
                    return gold * (env * 0.85 + sunCol * ndl * sh * 0.35 + sunCol * spec * sh) * (0.6 + 0.4 * ao);
                }
                if (id == ID_ROOF)
                {
                    // こけら葺き (薄い板を重ねた屋根): こげ茶色の細い横の筋。基壇は灰色の石
                    if (q.y < 0.005) return Surface(float3(0.42, 0.4, 0.37), n, v, L, sunCol, sh, ao, 0.8, 0.04, 0.0, skyTop, skyLow);
                    float3 shingle = float3(0.08, 0.06, 0.045) * (0.85 + 0.25 * step(0.5, frac(q.y / 0.0006 + (q.x + q.z) * 0.0)));
                    return Surface(shingle, BumpNormal(n, p, 5000.0, 0.4), v, L, sunCol, sh, ao, 0.7, 0.04, 0.0, skyTop, skyLow);
                }
                if (id == ID_WOOD)
                    return Surface(float3(0.42, 0.3, 0.2) * (0.85 + 0.2 * Noise3(p * float3(4000.0, 400.0, 4000.0))), n, v, L, sunCol, sh, ao, 0.7, 0.04, 0.0, skyTop, skyLow);
                if (id == ID_PLASTER)
                {
                    // 1 層の白い蔀戸 (格子) と、2 層より上の壁は金
                    if (q.y > 0.03) return Surface(float3(1.0, 0.72, 0.28) * 0.6, n, v, L, sunCol, sh, ao, 0.3, 0.8, 0.0, skyTop, skyLow);
                    float2 g = abs(frac(float2(q.x + q.z, q.y) / 0.0018) - 0.5);
                    float3 alb = float3(0.86, 0.84, 0.8) * (1.0 - 0.35 * step(0.42, max(g.x, g.y)));
                    // 南の縁側の奥は、開け放して暗い
                    if (q.z > 0.04 && abs(q.x) < 0.035) alb = float3(0.06, 0.05, 0.04);
                    return Surface(alb, n, v, L, sunCol, sh, ao, 0.7, 0.04, 0.0, skyTop, skyLow);
                }
                if (id == ID_WINDOW) return float3(0.03, 0.02, 0.01);

                if (max(abs(p.x), abs(p.z)) > INNER - 0.0015 && abs(n.y) < 0.5)
                    return Surface(float3(0.32, 0.27, 0.22) * (0.8 + 0.4 * Noise3(p * 900.0)), n, v, L, sunCol, 1.0, 1.0, 0.9, 0.03, 0.0, skyTop, skyLow); // 切り口

                // 地面: 木々 (もみじと松)、苔と岩の岸、砂利の参道
                float tree = TreeMask(p.xz);
                float3 albedo;
                float sss = 0.0;
                float3 nb = n;
                if (tree > 0.4 && p.y > Height(p.xz) - 0.004 - 0.02 * (1.0 - tree))
                {
                    float isl = Islands(p.xz);
                    float m1 = Noise3(p * 90.0), m2 = Noise3(p * 200.0 + 7.0);
                    float3 red = float3(0.55, 0.06, 0.03), orange = float3(0.65, 0.22, 0.04), yellow = float3(0.7, 0.5, 0.08), pine = float3(0.05, 0.16, 0.06);
                    float3 leaf = lerp(lerp(red, orange, smoothstep(0.35, 0.55, m1)), yellow, smoothstep(0.65, 0.85, m1));
                    float pineAmt = saturate(smoothstep(0.55, 0.75, m2) + isl * 0.9 + smoothstep(0.3, 0.42, -p.z) * 0.4);
                    leaf = lerp(leaf, pine, pineAmt);
                    leaf *= 0.45 + 0.75 * (Noise3(p * 2500.0) * 0.6 + Noise3(p * 800.0) * 0.4);
                    albedo = leaf;
                    sss = 0.5;
                    nb = BumpNormal(n, p, 2500.0, 1.4);
                }
                else
                {
                    float rock = smoothstep(0.55, 0.7, Noise3(p * 400.0)) * (1.0 - smoothstep(1.0, 1.15, PondShape(p.xz)));
                    float3 moss = float3(0.16, 0.26, 0.08) * (0.8 + 0.4 * Noise3(p * 1500.0));
                    float3 gravel = float3(0.6, 0.57, 0.5) * (0.85 + 0.2 * Noise3(p * 3000.0));
                    albedo = p.z > 0.36 ? gravel : lerp(moss, float3(0.45, 0.43, 0.4), rock);
                    if (p.y < WATER + 0.001) albedo = float3(0.15, 0.17, 0.12); // 水の中の底
                    nb = BumpNormal(n, p, 3000.0, 0.6);
                }
                return Surface(albedo, nb, v, L, sunCol, sh, ao, 0.85, 0.03, sss, skyTop, skyLow);
            }

            // 水面より上の景色を、線にそってたどる (映り込み用は歩数を少なく)
            float3 TraceScene(float3 ro, float3 rd, float tStart, float tMax, bool inside, int maxSteps, bool lite, float3 faceNormal, out bool hitAny, out float tHit)
            {
                float t = tStart;
                hitAny = false;
                float id = 0;
                float lastD = 1.0, lastId = 0.0;
                bool ranOut = false;
                for (int i = 0; i <= 200; i++)
                {
                    if (t > tMax) break;
                    if (i >= maxSteps) { ranOut = true; break; }
                    float3 pos = ro + rd * t;
                    if (rd.y > 0.0 && pos.y > 0.0) break;
                    float2 m = Map(pos);
                    lastD = m.x; lastId = m.y;
                    if (m.x < 0.00003 + 0.0003 * t) { hitAny = true; id = m.y; break; }
                    t += m.x;
                }
                if (!hitAny && ranOut && lastD < 0.0005 + 0.002 * t) { hitAny = true; id = lastId; }
                // 高さの表で当たった地面を、正確な式で合わせ直す (2 点を結ぶ直線で、2 回)。木々のふちがなまらないように
                if (hitAny && id == ID_GROUND && !lite)
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
                tHit = hitAny ? t : tMax;
                return hitAny ? Shade(ro, rd, ro + rd * t, id, faceNormal, lite) : (inside ? Sky(rd) : 0);
            }

            // 舞い散るもみじ (小さな赤い葉が、くるくる回りながら光る)
            float3 Leaves(float3 ro, float3 rd, float tMax)
            {
                if (_Event < 0.01) return 0;
                float3 col = 0;
                float t = _Time.y;
                for (int i = 0; i < LEAVES; i++)
                {
                    float3 pos = LeafPos(i);
                    float3 w = pos - ro;
                    float tc = dot(w, rd);
                    if (tc < 0.0 || tc > tMax + 0.001) continue;
                    float d2 = dot(w, w) - tc * tc;
                    float size = max(0.0022, tc * 0.0016) * (0.5 + 0.5 * abs(sin(t * 4.0 + i))); // くるくる回ると、見える大きさが変わる
                    float3 c = lerp(float3(0.9, 0.12, 0.04), float3(1.0, 0.5, 0.05), Hash11(i + 9.0));
                    col += c * exp(-d2 / (size * size)) * _Event;
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
                float t0 = max(box.x, 0.0);

                float3 entry = ro + rd * t0;
                float3 ae = abs(entry);
                float3 faceNormal = ae.x > ae.y && ae.x > ae.z ? float3(sign(entry.x), 0, 0)
                                  : (ae.y > ae.z ? float3(0, sign(entry.y), 0) : float3(0, 0, sign(entry.z)));

                const float maxHeight = 0.0; // 衣笠山のてっぺんより少し上
                float tS = t0;
                if (ro.y > maxHeight && rd.y < 0.0) tS = max(tS, (maxHeight - ro.y) / rd.y);

                bool hit;
                float tHit;
                float3 col = TraceScene(ro, rd, tS, box.y, !outside, (int)_Steps, false, faceNormal, hit, tHit);
                float alpha = (hit || !outside) ? 1.0 : 0.0;

                // 鏡湖池: 物に当たる前に水面を通ったら、水の色と映り込みを重ねる
                float tW = rd.y < 0.0 ? (WATER - ro.y) / rd.y : -1.0;
                float3 wp = ro + rd * tW;
                if (ro.y > WATER && tW > t0 && tW < tHit && max(abs(wp.x), abs(wp.z)) < INNER)
                {
                    float tt = _Time.y;
                    // かすかなさざ波 (風が吹くと強くなる)
                    float2 rq = wp.xz * 160.0;
                    float amp = 0.012 + 0.05 * Wind();
                    float2 slope = (float2(ValueNoise(rq + tt * 0.4), ValueNoise(rq.yx - tt * 0.35)) - 0.5) * amp;
                    float3 wn = normalize(float3(slope.x, 1.0, slope.y));
                    float3 rr = reflect(rd, wn);
                    float2 rbox = BoxHit(wp, rr, float3(0.5, 0.5, 0.5));
                    bool rh;
                    float rt;
                    float3 refl = TraceScene(wp + rr * 0.0005, rr, 0.0, rbox.y, true, 64, true, faceNormal, rh, rt);
                    // 水の中: 浅いので底が少し見える、深い緑の水
                    float len = tHit - tW;
                    float3 absorb = exp(-float3(60.0, 35.0, 40.0) * len);
                    float3 under = col * absorb + float3(0.03, 0.07, 0.05) * (1.0 - absorb);
                    float fres = 0.25 + 0.75 * pow(1.0 - saturate(dot(-rd, wn)), 4.0);
                    col = lerp(under, refl, fres);
                    // 水面に浮かぶもみじ (仕掛けのあいだ、だんだん増える)
                    if (_Event > 0.01)
                    {
                        float2 cell = floor(wp.xz / 0.003);
                        float2 f = frac(wp.xz / 0.003) - 0.5;
                        float on = step(1.0 - 0.18 * _Event * saturate(_EventTime / 10.0), Hash21(cell + 4.2));
                        float leaf = on * (1.0 - smoothstep(0.15, 0.3, length(f + (Hash22b(cell) - 0.5) * 0.4)));
                        col = lerp(col, lerp(float3(0.6, 0.06, 0.03), float3(0.75, 0.32, 0.04), Hash21(cell)), leaf);
                    }
                    alpha = 1.0;
                    tHit = tW;
                }

                // 遠くほど、少しかすむ
                float travel = tHit - t0;
                if (alpha > 0.5) col = lerp(col, float3(0.7, 0.76, 0.85), (1.0 - exp(-travel * 1.0)) * 0.2);

                col += Leaves(ro, rd, tHit);

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
