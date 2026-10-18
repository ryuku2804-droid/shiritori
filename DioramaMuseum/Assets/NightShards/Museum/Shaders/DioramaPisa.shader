// 作品「ピサの斜塔」(ヨーロッパの間)。午後遅くの金色の光の中に立つ、斜塔だけを大きく実物どおりに作った。URP 用。
// Cube の中をレイマーチングして描く。Cube の座標は -0.5〜0.5、下の 0.08 は黒い台。
//
// 形は実物の寸法 (1 m = 0.0022) で作り、TS 倍 (1 m = 0.0121) に大きくして置く。
//   ・高さ 56 m・直径 15.5 m。3.97 度傾く (美術館の正面から見て右へ。正面が西、右が南)
//   ・1 層目: 15 のめくらアーチと付け柱。アーチの中に、色の違う大理石のひし形の象眼
//   ・2〜7 層目: 30 本の柱が並ぶ回廊が 6 段。柱の上に柱頭と半円のアーチの帯。柱のすき間から、回廊の奥の壁と戸口が見える
//   ・いちばん上: 12 のアーチ窓の鐘楼と、中のブロンズの鐘
//   ・足元は大理石の敷石と、刈り込みの縞の芝生。灰色の鳩
// 仕掛け (_Event 0〜1): 鐘が鳴り響き、芝生の鳩の群れが一斉に飛び立って、塔のまわりを旋回する
//
// 外から見たとき、何もない所 (空) は透明にして、ガラスケースの向こうの部屋が見えるようにする。
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

            // ※ 塔の場所・倍率を変えたら、C# の DioramaTerrain (PisaProps) も同じに直す (当たり判定)
            #define INNER 0.47
            #define GROUND -0.3
            #define BIRDS 40
            #define LEAN 0.0693                                     // 斜塔の傾き (3.97 度)
            #define TS 5.5                                          // 塔を大きくする倍率 (1 m = 0.0121)
            static const float3 TOWER = float3(0.02, -0.3, -0.03);  // 斜塔の根元
            static const float3 LEAN_DIR = float3(-1.0, 0.0, 0.0);  // 傾く向き (南。正面から見て右)
            static const float3 SUN_DIR = float3(0.5, 0.5, 0.7);    // 午後遅くの日差し (正面の左上から)

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

            // 置いた場所 → 形を作った座標 (塔を TS 倍に大きく見せるため、逆に縮めて調べる)
            float3 ToB(float3 p) { return TOWER + (p - TOWER) / TS; }

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

            // ---------------------------------------------------------------- 世界の形

            float2 Map(float3 p)
            {
                float2 res = float2(SdBox(p - float3(0, -0.46, 0), float3(0.5, 0.04, 0.5)), ID_BASE);
                float column = SdBox(p - float3(0, 0.04, 0), float3(INNER, 0.46, INNER));
                float ground = max(p.y - GROUND, column);
                if (ground < res.x) res = float2(ground, ID_GROUND);
                float part;
                float tower = Tower(ToB(p), part) * TS;
                if (tower < res.x) res = float2(tower, ID_TOWER);
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
                    if (sp.y > 0.4) break; // いちばん高い建物より上に出たら、もう何にも当たらない
                    float h = Map(sp).x;
                    res = min(res, 24.0 * h / t);
                    t += clamp(h, 0.0008, 0.06);
                    if (res < 0.01 || t > 1.2) break;
                }
                return saturate(res);
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
                return saturate(1.0 - occ * 15.0);
            }

            // ---------------------------------------------------------------- 鳩

            // 鳩 i 番の場所と飛ぶ向き。ふだんは東の芝生の上。仕掛けで飛び立ち、斜塔のまわりを回る
            float3 BirdPos(int i, out float3 dir, out float flying)
            {
                float fi = i;
                float t = _Time.y;
                float3 rest = float3(-0.3 + 0.6 * Hash11(fi + 1.0), GROUND + 0.0006, 0.2 + 0.2 * Hash11(fi + 2.0));
                float a = t * (0.35 + 0.15 * Hash11(fi + 3.0)) + Hash11(fi + 4.0) * 6.2831;
                float rad = 0.15 + 0.15 * Hash11(fi + 5.0);
                float3 fly = TOWER + float3(cos(a) * rad, 0.15 + 0.45 * Hash11(fi + 6.0) + 0.02 * sin(t * 1.3 + fi), sin(a) * rad);
                flying = smoothstep(0.3, 2.0, _EventTime - fi * 0.04) * saturate(_Event * 1.3) * step(0.001, _Event);
                dir = normalize(lerp(float3(1, 0, 0), float3(-sin(a), 0.0, cos(a)), flying));
                float lift = sin(flying * 3.1416) * 0.1; // 飛び立つときは、ふわっと上がる
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
                // 塔と敷石の模様は、形を作った座標 (実物の寸法) で調べる
                float3 pw = p;
                p = ToB(p);
                y = p.y - GROUND;

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

                if (max(abs(pw.x), abs(pw.z)) > INNER - 0.0015 && abs(n.y) < 0.5)
                    return Surface(float3(0.22, 0.17, 0.12) * (0.8 + 0.4 * Noise3(p * 900.0)), n, v, L, sunCol, 1.0, 1.0, 0.9, 0.03, 0.0, skyTop, skyLow); // 地面の切り口 (土)

                // 地面: 塔のまわりの大理石の敷石と、正面からの小道。ほかは刈り込んだ芝生 (縞模様)
                float2 tw = pw.xz - TOWER.xz;
                bool paved = length(tw) < 0.17 || (abs(pw.x) < 0.025 && pw.z > TOWER.z);
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
                    float stripes = 0.88 + 0.12 * step(0.5, frac(pw.x / 0.06));
                    albedo = float3(0.2, 0.42, 0.12) * stripes * (0.8 + 0.3 * Noise3(pw * 600.0));
                    rough = 0.85;
                    bump = 0.9;
                    sss = 0.5;
                }
                float3 nb = BumpNormal(n, pw, paved ? 600.0 : 1500.0, bump);
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

                const float maxHeight = 0.4; // 斜塔のてっぺんより少し上 (大きくしたあと)
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
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input); // VR: 左右どちらの目を描いているか
                return input.positionCS.z;
            }
            ENDHLSL
        }
    }
}
