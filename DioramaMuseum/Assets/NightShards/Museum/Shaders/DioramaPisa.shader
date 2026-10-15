// 作品「ピサの斜塔」(ヨーロッパの間)。午後遅くの金色の光の中の、奇跡の広場。URP 用。
// Cube の中をレイマーチングして描く。Cube の座標は -0.5〜0.5、下の 0.08 は黒い台。
//
// 見どころ:
//   ・緑の芝生に、白い大理石の 3 つの建物: 十字形の大聖堂 (グレーの縞と丸屋根)、円い洗礼堂、そして約 5 度傾いた斜塔
//   ・斜塔は、柱が並ぶ回廊が 6 段重なり、上に鐘楼。大理石はつやがあり、少し光を通す
//   ・芝生の上には白い鳩、奥にはレンガの城壁
// 仕掛け (_Event 0〜1): 鐘が鳴り響き、芝生の鳩の群れが一斉に飛び立って、塔のまわりを旋回する
//
// 外から見たとき、建物のない所 (空) は透明にして、ガラスケースの向こうの部屋が見えるようにする。
// 中に入ったとき (カメラが箱の中) だけ、午後の空を描く
Shader "NightShards/Diorama/Pisa"
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

            #define ID_BASE   0.0
            #define ID_GROUND 1.0
            #define ID_TOWER  2.0
            #define ID_DUOMO  3.0
            #define ID_BAPT   4.0
            #define ID_WALL   5.0

            #define INNER 0.47
            #define GROUND -0.3
            #define BIRDS 36
            #define LEAN 0.087                                     // 斜塔の傾き (約 5 度)
            static const float3 TOWER = float3(0.27, -0.3, 0.12);  // 斜塔の根元
            static const float3 LEAN_DIR = float3(0.96, 0.0, 0.28); // 傾く向き
            static const float3 DUOMO = float3(0.0, -0.3, -0.13);  // 大聖堂の中心
            static const float3 BAPT = float3(-0.3, -0.3, -0.12);  // 洗礼堂の中心
            static const float3 SUN_DIR = float3(0.6, 0.42, 0.55); // 午後遅くの日差し

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

            // ---------------------------------------------------------------- 斜塔

            // 斜塔の座標へ: 根元を原点にして、傾きを戻し、塔がまっすぐ立っている向きにする
            float3 TowerLocal(float3 p)
            {
                float3 q = p - TOWER;
                float3 k = normalize(float3(LEAN_DIR.z, 0.0, -LEAN_DIR.x)); // 傾きの回転軸
                float c = cos(-LEAN), s = sin(-LEAN);
                return q * c + cross(k, q) * s + k * dot(k, q) * (1.0 - c);
            }

            // 斜塔: 1 段目は壁の柱 (めくらアーチ)、2〜7 段目は柱の並ぶ回廊、いちばん上に小さな鐘楼。段の境に、張り出した床
            float Tower(float3 p)
            {
                float3 q = TowerLocal(p);
                float r = length(q.xz);
                float y = q.y;
                if (r > 0.04 || y > 0.18) return max(r - 0.03, y - 0.17);
                float core = max(r - 0.0205, max(-y, y - 0.144));
                float ground = max(r - 0.0245, max(-y, y - 0.03));
                // 回廊の柱: 円のまわりに 30 本
                float sector = 6.2831853 / 30.0;
                float ang = atan2(q.z, q.x);
                float a2 = (frac(ang / sector + 0.5) - 0.5) * sector;
                float colD = length(float2(r * cos(a2) - 0.0242, r * sin(a2))) - 0.0009;
                colD = max(colD, max(0.03 - y, y - 0.144));
                // 段の境の床 (張り出し)
                float kk = clamp(round((y - 0.03) / 0.019), 0.0, 6.0);
                float cornice = max(r - 0.0262, abs(y - (0.03 + kk * 0.019)) - 0.0009);
                // 鐘楼
                float bell = max(r - 0.0155, max(0.144 - y, y - 0.166));
                return min(min(core, ground), min(min(colD, cornice), bell));
            }

            // ---------------------------------------------------------------- 大聖堂と洗礼堂と城壁

            float Duomo(float3 p)
            {
                float3 q = p - DUOMO;
                if (abs(q.x) > 0.21 || abs(q.z) > 0.12 || q.y > 0.11) return max(max(abs(q.x) - 0.2, abs(q.z) - 0.11), q.y - 0.1);
                // 身廊 (中央の高い所) と、両側の側廊
                float nave = SdBox(q - float3(0, 0.0325, 0), float3(0.17, 0.0325, 0.022));
                float aisles = SdBox(q - float3(0, 0.0225, 0), float3(0.17, 0.0225, 0.04));
                float naveRoof = max(abs(q.x) - 0.17, abs(q.z) * 0.45 + (q.y - 0.065) - 0.01); // 切妻の屋根 (てっぺんは 0.01 高い)
                naveRoof = max(naveRoof, -(q.y - 0.065));
                // 翼廊 (十字の横の部分)
                float3 tq = q - float3(0.09, 0, 0);
                float transept = SdBox(tq - float3(0, 0.03, 0), float3(0.028, 0.03, 0.09));
                float tRoof = max(abs(tq.z) - 0.09, max(abs(tq.x) * 0.45 + (tq.y - 0.06) - 0.0126, -(tq.y - 0.06)));
                // 交差部の丸屋根: 太鼓の上に、少しとがった丸屋根
                float drum = max(length(tq.xz) - 0.02, abs(tq.y - 0.07) - 0.01);
                float dome = SdEllipsoidLite(tq - float3(0, 0.08, 0), float3(0.019, 0.022, 0.019));
                // 奥の後陣 (半円)
                float apse = max(length(float2(q.x - 0.17, q.z)) - 0.03, max(abs(q.y - 0.02) - 0.02, 0.17 - q.x));
                return min(min(min(nave, aisles), naveRoof), min(min(transept, tRoof), min(min(drum, dome), apse)));
            }

            float Baptistery(float3 p)
            {
                float3 q = p - BAPT;
                float r = length(q.xz);
                if (r > 0.07 || q.y > 0.13) return max(r - 0.06, q.y - 0.12);
                float body = max(r - 0.05, max(-q.y, q.y - 0.05));
                float ring = max(r - 0.053, abs(q.y - 0.05) - 0.002);
                float dome = SdEllipsoidLite(q - float3(0, 0.05, 0), float3(0.045, 0.05, 0.045));
                float lantern = max(r - 0.007, abs(q.y - 0.105) - 0.008);
                return min(min(body, ring), min(max(dome, -q.y + 0.05), lantern));
            }

            // 奥のレンガの城壁 (上に凹凸の狭間)
            float Wall(float3 p)
            {
                float y = p.y - GROUND;
                float crenel = step(0.5, frac(p.x * 60.0)) * 0.004;
                return max(abs(p.z + 0.43) - 0.008, max(-y, y - (0.028 + crenel)));
            }

            // ---------------------------------------------------------------- 世界の形

            float2 Map(float3 p)
            {
                float2 res = float2(SdBox(p - float3(0, -0.46, 0), float3(0.5, 0.04, 0.5)), ID_BASE);
                float column = SdBox(p - float3(0, 0.04, 0), float3(INNER, 0.46, INNER));
                float ground = max(p.y - GROUND, column);
                if (ground < res.x) res = float2(ground, ID_GROUND);
                float tower = Tower(p);
                if (tower < res.x) res = float2(tower, ID_TOWER);
                float duomo = Duomo(p);
                if (duomo < res.x) res = float2(duomo, ID_DUOMO);
                float bapt = Baptistery(p);
                if (bapt < res.x) res = float2(bapt, ID_BAPT);
                float wall = max(Wall(p), column);
                if (wall < res.x) res = float2(wall, ID_WALL);
                return res;
            }

            float3 SceneNormal(float3 p)
            {
                const float2 e = float2(0.0003, -0.0003);
                float3 g = e.xyy * Map(p + e.xyy).x + e.yyx * Map(p + e.yyx).x + e.yxy * Map(p + e.yxy).x + e.xxx * Map(p + e.xxx).x;
                return g / max(length(g), 1e-7);
            }

            float SoftShadow(float3 p, float3 l)
            {
                float res = 1.0;
                float t = 0.0015;
                int n = max((int)_ShadowSteps, 8);
                for (int i = 0; i < 32; i++)
                {
                    if (i >= n) break;
                    float h = Map(p + l * t).x;
                    res = min(res, 24.0 * h / t);
                    t += clamp(h, 0.0012, 0.03);
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
                    float d = 0.005 * i;
                    occ += (d - Map(p + n * d).x) * w;
                    w *= 0.6;
                }
                return saturate(1.0 - occ * 20.0);
            }

            // ---------------------------------------------------------------- 鳩

            // 鳩 i 番の場所と飛ぶ向き。ふだんは芝生の上。仕掛けで飛び立ち、塔のまわりを回る
            float3 BirdPos(int i, out float3 dir, out float flying)
            {
                float fi = i;
                float t = _Time.y;
                float3 rest = float3(-0.1 + 0.3 * Hash11(fi + 1.0), GROUND + 0.0015, 0.2 + 0.2 * Hash11(fi + 2.0));
                float a = t * (0.7 + 0.3 * Hash11(fi + 3.0)) + Hash11(fi + 4.0) * 6.2831;
                float rad = 0.07 + 0.08 * Hash11(fi + 5.0);
                float3 fly = TOWER + float3(cos(a) * rad, 0.06 + 0.14 * Hash11(fi + 6.0) + 0.01 * sin(t * 1.3 + fi), sin(a) * rad);
                flying = smoothstep(0.3, 2.0, _EventTime - fi * 0.04) * saturate(_Event * 1.3) * step(0.001, _Event);
                dir = normalize(lerp(float3(1, 0, 0), float3(-sin(a), 0.0, cos(a)), flying));
                float lift = sin(flying * 3.1416) * 0.05; // 飛び立つときは、ふわっと上がる
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
                    float L = max(0.0018, tc * 0.0012);
                    float W = max(0.0012, tc * 0.0009) * lerp(1.0, 0.6 + 1.6 * flap, flying); // 羽ばたくと、横に広がったり縮んだり
                    float shape = exp(-(along * along / (L * L) + across2 / (W * W)));
                    col += float3(0.85, 0.85, 0.82) * (sunCol * 0.6 + 0.25) * shape;
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
                float sh = SoftShadow(p + n * 0.001, L);
                float ao = AmbientOcclusion(p, n);
                float y = p.y - GROUND;

                if (id == ID_TOWER || id == ID_DUOMO || id == ID_BAPT)
                {
                    // 白い大理石: つやがあり、光を少し通す。ところどころ、うっすらグレーの筋。大聖堂と洗礼堂は、グレーの横縞
                    float vein = smoothstep(0.55, 0.75, Noise3(p * float3(300.0, 900.0, 300.0)));
                    float3 marble = lerp(float3(0.92, 0.9, 0.85), float3(0.7, 0.7, 0.72), vein * 0.3);
                    if (id != ID_TOWER)
                    {
                        float stripe = step(0.6, frac(y * 250.0));
                        marble = lerp(marble, float3(0.55, 0.56, 0.6), stripe * 0.6 * step(y, 0.045));
                    }
                    // 回廊のアーチの奥は暗い
                    float3 nb = BumpNormal(n, p, 2500.0, 0.25);
                    float3 col = Surface(marble, nb, v, L, sunCol, sh, ao, 0.3, 0.05, 0.25, skyTop, skyLow);
                    if (id == ID_DUOMO || id == ID_BAPT)
                    {
                        // 屋根: 灰色の鉛の板
                        float roof = step(0.45, n.y) * step(0.04, y);
                        float3 lead = float3(0.42, 0.43, 0.45);
                        col = lerp(col, Surface(lead, n, v, L, sunCol, sh, ao, 0.45, 0.2, 0.0, skyTop, skyLow), roof);
                    }
                    return col;
                }

                if (id == ID_WALL)
                {
                    // レンガの城壁
                    float2 bq = float2(p.x * 600.0 + floor(y * 900.0) * 0.5, y * 900.0);
                    float joint = smoothstep(0.08, 0.0, min(frac(bq.x), frac(bq.y)));
                    float3 brick = float3(0.62, 0.32, 0.2) * (0.8 + 0.3 * Hash21(floor(bq))) * (1.0 - 0.5 * joint);
                    return Surface(brick, BumpNormal(n, p, 1500.0, 0.5), v, L, sunCol, sh, ao, 0.85, 0.03, 0.0, skyTop, skyLow);
                }

                // 地面: 刈り込んだ芝生 (縞模様)。建物をつなぐ白い大理石の小道
                float stripes = 0.9 + 0.1 * step(0.5, frac(p.x * 25.0));
                float3 grass = float3(0.2, 0.42, 0.12) * stripes * (0.85 + 0.25 * Noise3(p * 800.0));
                float path1 = step(abs(p.z - 0.05), 0.012) * step(-0.35, p.x);
                float path2 = step(abs(p.x - 0.27), 0.012) * step(0.05, p.z) * step(p.z, 0.12);
                float path = saturate(path1 + path2);
                float3 albedo = lerp(grass, float3(0.85, 0.83, 0.78), path);
                float3 nb = BumpNormal(n, p, 1500.0, path > 0.5 ? 0.2 : 0.8);
                return Surface(albedo, nb, v, L, sunCol, sh, ao, path > 0.5 ? 0.45 : 0.8, 0.04, path > 0.5 ? 0.0 : 0.5, skyTop, skyLow);
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

                const float maxHeight = -0.11; // 塔のてっぺんより少し上
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
                    if (m.x < 0.00012 * (1.0 + t))
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
