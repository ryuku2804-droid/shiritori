// 作品「死海」(砂漠と塩の間)。白い塩の結晶の岸と、青緑の水に浮かぶ人。URP 用。
// Cube の中をレイマーチングして描く。Cube の座標は -0.5〜0.5、下の 0.08 は黒い台。
//
// 形は実物の寸法 (1 m = 0.005)。美術館の正面 (+z) がイスラエル側の岸、奥がヨルダン側。
//   ・手前の岸: 塩が固まった白い地面。乾いて、六角形のひび割れの模様になる
//   ・浅瀬: 白い塩の底が透けて、水が明るい青緑に見える。沖へ行くほど深い青緑
//   ・塩のきのこ (エン・ボケックの名物): 浅瀬から生える、直径 2〜3 m の白い塩のかたまり。水面の高さに、塩のふちがぐるりと張り出す
//   ・水面に仰向けに浮かんで、新聞を読む人 (塩分が濃く、体が半分水の上に出る)
//   ・向こう岸のモアブの山並み (地層の縞のある赤茶色の岩山)。かすみの中に見える
//   ・水はとても静かで、空と山を鏡のように映す
// 仕掛け (_Event 0〜1): 塩の結晶 (立方体の岩塩) が水の中から次々にせり上がって育ち、日を受けてきらめく
//
// 軽くする工夫: ループには [loop] を付けて、展開させない (Quest 用の変換が終わらなくなるのを防ぐ) / きのこの帯の外は調べない / 水の底は影と陰を省く /
//   水の映り込みは低い角度の線だけたどり、安い向きの測り方を使う / 影は近くだけ / 平らな所は大きめの歩幅で進む
// 外から見たとき、何もない所 (空) は透明にして、ガラスケースの向こうの部屋が見えるようにする。
// 中に入ったとき (カメラが箱の中) だけ、空を描く
Shader "NightShards/Diorama/DeadSea"
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

            float SdCapsule(float3 p, float3 a, float3 b, float r)
            {
                float3 pa = p - a, ba = b - a;
                float h = saturate(dot(pa, ba) / dot(ba, ba));
                return length(pa - ba * h) - r;
            }

            // ---------------------------------------------------------------- 場所と寸法 (1 m = 0.005)
            // ※ ここと Height() を変えたら、C# の DioramaTerrain (DeadSea) も同じに直す (歩く地面と当たり判定)

            #define ID_BASE     0.0
            #define ID_GROUND   1.0
            #define ID_MUSHROOM 2.0
            #define ID_CRYSTAL  3.0
            #define ID_PERSON   4.0
            #define ID_PAPER    5.0

            #define WATER -0.3                                     // 水面の高さ
            #define MUSHROOMS 9
            #define SC 2.4                                         // 塩のきのこ・結晶・人を大きくする倍率 (1 m = 0.012)
            static const float3 SUN_DIR = float3(0.45, 0.7, 0.55); // 昼過ぎの、かすんだ日差し
            static const float3 FLOATER = float3(0.06, -0.3, -0.05); // 浮かんでいる人

            // 塩のきのこの場所 (x, z) と大きさ
            static const float3 MUSH[MUSHROOMS] = {
                float3(-0.25, 0.12, 1.0), float3(-0.12, 0.05, 1.3), float3(0.02, 0.15, 0.8),
                float3(0.15, 0.08, 1.1), float3(0.3, 0.14, 0.9), float3(-0.35, 0.0, 1.2),
                float3(0.38, -0.02, 1.0), float3(-0.05, -0.02, 0.7), float3(0.22, 0.2, 0.6)
            };

            // ---------------------------------------------------------------- 地面

            // 岸の線 (少し波打つ) からの位置で、深さが決まる。奥 (-z) の向こう岸は、モアブの山並み
            float Height(float2 xz)
            {
                float z = xz.y + 0.04 * (Fbm3(xz * 3.0 + 1.3) - 0.45);
                float h = WATER - 0.035 + 0.032 * smoothstep(-0.15, 0.02, z) + 0.004 * smoothstep(0.18, 0.3, z) + 0.01 * smoothstep(0.26, 0.47, z);
                h += 0.0006 * ValueNoise(xz * 60.0);
                // 山並み: 谷 (ワジ) に刻まれた尾根が、奥へなだらかに高くなる
                float ridge = 1.0 - abs(ValueNoise(xz * float2(14.0, 4.0) + 5.0) * 2.0 - 1.0);
                float zm = xz.y + 0.03 * sin(xz.x * 7.0);
                float mountain = WATER - 0.04 + 0.22 * smoothstep(0.24, 0.47, -zm) * (0.5 + 0.35 * Fbm3(xz * 5.0 + 9.0) + 0.15 * ridge);
                return max(h, mountain);
            }

            float HeightFast(float2 xz)
            {
                [branch] if (_HeightTexOn > 0.5)
                    return SAMPLE_TEXTURE2D_LOD(_HeightTex, sampler_linear_clamp, xz / (2.0 * INNER) + 0.5, 0).r;
                return Height(xz);
            }

            // ---------------------------------------------------------------- 塩のきのこと、育つ結晶

            // 塩のきのこ: 浅瀬の底から立つ太い軸と、水面の高さに張り出す、ふちの丸い白い傘
            float Mushrooms(float3 p)
            {
                if (p.y > WATER + 0.012 * SC * 1.3) return p.y - WATER - 0.012 * SC * 1.3 + 0.001;
                // きのこが並ぶ帯 (z = -0.07〜0.25、x = -0.44〜0.44) の外なら、帯までの距離だけ返す
                float band = max(max(-0.08 - p.z, p.z - 0.26), abs(p.x) - 0.44);
                if (band > 0.002) return band;
                float d = 1e5;
                // [loop]: ループを展開させない。展開すると、きのこ 9 本分の式が何倍にもふくらみ、Quest 用の変換が時間切れになる
                [loop] for (int i = 0; i < MUSHROOMS; i++)
                {
                    float3 m = MUSH[i];
                    float s = m.z * SC;
                    float3 q = p - float3(m.x, WATER, m.y);
                    if (dot(q.xz, q.xz) > 0.02 * 0.02 * s * s) { d = min(d, length(q.xz) - 0.013 * s); continue; }
                    float stalk = max(length(q.xz) - 0.0042 * s, q.y - 0.002 * s);
                    float cap = SdEllipsoidLite(q - float3(0, 0.0032 * s, 0), float3(0.0078, 0.0033, 0.0078) * s);
                    float ledge = SdEllipsoidLite(q - float3(0, 0.0004 * s, 0), float3(0.0092, 0.0008, 0.0092) * s); // 水面の高さの塩のふち
                    float dd = min(min(stalk, cap), ledge);
                    if (dd < 0.004) dd -= 0.0005 * s * Noise3(q * 900.0 / s);   // カリフラワーのような、ぼこぼこした表面 (近い所だけ)
                    d = min(d, dd * 0.8);
                }
                return d;
            }

            // 育つ岩塩の結晶: きのこのまわりに 5 つずつ。立方体が少し傾いて、水の中からせり上がる
            float Crystals(float3 p, float grow)
            {
                if (grow < 0.01) return 1.0;
                if (p.y > WATER + 0.01 * SC) return p.y - WATER - 0.01 * SC + 0.0005;
                float d = 1e5;
                [loop] for (int i = 0; i < MUSHROOMS; i++)
                {
                    float3 m = MUSH[i];
                    float2 c = p.xz - m.xy;
                    if (dot(c, c) > 0.025 * 0.025 * SC * SC) { d = min(d, length(c) - 0.02 * SC); continue; }
                    [loop] for (int k = 0; k < 5; k++)
                    {
                        float fk = i * 5 + k;
                        float a = fk * 2.4 + Hash11(fk) * 1.5;
                        float r = (0.011 + 0.005 * Hash11(fk + 1.0)) * m.z * SC;
                        // 1 つずつ時間をずらして育つ
                        float g = saturate(grow * 1.6 - Hash11(fk + 2.0) * 0.6);
                        float size = 0.002 * SC * g * (0.6 + 0.6 * Hash11(fk + 3.0));
                        if (size < 0.0001) continue;
                        float3 q = p - float3(m.x + cos(a) * r, WATER + (-0.004 + 0.0055 * g) * SC, m.y + sin(a) * r);
                        float yaw = Hash11(fk + 4.0) * 6.28;
                        float cy = cos(yaw), sy = sin(yaw);
                        q = float3(cy * q.x - sy * q.z, q.y, sy * q.x + cy * q.z);
                        float tilt = 0.35 * (Hash11(fk + 5.0) - 0.5);
                        float ct = cos(tilt), st = sin(tilt);
                        q = float3(ct * q.x - st * q.y, st * q.x + ct * q.y, q.z);
                        d = min(d, SdBox(q, float3(size, size, size)) - size * 0.08);
                    }
                }
                return d;
            }

            // ---------------------------------------------------------------- 浮かぶ人 (身長 1.75 m)

            // 体の向き: 頭を -x、足を +x に向けて、仰向けに浮かぶ。波でゆっくり上下・回転する
            float3 FloaterLocal(float3 p)
            {
                float t = _Time.y;
                float3 c = FLOATER + float3(0.01 * sin(t * 0.13), 0.0006 * sin(t * 0.9), 0.008 * sin(t * 0.11));
                float3 q = (p - c) / SC; // 形は 1 m = 0.005 で作り、SC 倍に大きくする
                float a = 0.3 + 0.12 * sin(t * 0.07);
                float ca = cos(a), sa = sin(a);
                return float3(ca * q.x - sa * q.z, q.y, sa * q.x + ca * q.z);
            }

            float Person(float3 p, out float part)
            {
                part = 0;
                float3 q = FloaterLocal(p);
                if (length(q) > 0.008) return (length(q) - 0.0075) * SC;
                float head = length(q - float3(-0.0042, 0.0006, 0)) - 0.00055;
                float torso = SdEllipsoidLite(q - float3(-0.002, 0.0002, 0), float3(0.0017, 0.0007, 0.0009));
                float hips = SdEllipsoidLite(q - float3(-0.0001, 0.0, 0), float3(0.0008, 0.0006, 0.0008));
                float legs = min(SdCapsule(q, float3(0.0002, 0.0, 0.0004), float3(0.0044, 0.0003, 0.0007), 0.00035),
                                 SdCapsule(q, float3(0.0002, 0.0, -0.0004), float3(0.0044, 0.0003, -0.0007), 0.00035));
                // 両腕を前に上げて、新聞を持つ
                float arms = min(SdCapsule(q, float3(-0.003, 0.0004, 0.0008), float3(-0.0024, 0.0016, 0.0005), 0.00022),
                                 SdCapsule(q, float3(-0.003, 0.0004, -0.0008), float3(-0.0024, 0.0016, -0.0005), 0.00022));
                float body = min(min(head, torso), min(min(hips, legs), arms));
                float suit = max(min(hips, torso + 0.0001), -(q.x + 0.0028)); // 水着 (腰と、胸の下まで)
                float paper = SdBox(q - float3(-0.0022, 0.0019, 0), float3(0.0001, 0.0011, 0.0015));
                if (suit < body + 0.00005) part = 1;
                if (paper < body) part = 2;
                return min(body, paper) * SC;
            }

            // ---------------------------------------------------------------- 世界の形

            float Grow() { return _Event * smoothstep(0.0, 8.0, _EventTime); }

            float2 MapX(float3 p, bool exact)
            {
                float2 res = float2(SdBox(p - float3(0, -0.46, 0), float3(0.5, 0.04, 0.5)), ID_BASE);
                float column = SdBox(p - float3(0, 0.04, 0), float3(INNER, 0.46, INNER));
                float h = exact ? Height(p.xz) : HeightFast(p.xz);
                float ground = max((p.y - h) * (p.z < -0.2 ? 0.5 : 0.85), column); // 急な山並みでは、小さめに進む
                if (ground < res.x) res = float2(ground, ID_GROUND);
                float mush = Mushrooms(p);
                if (mush < res.x) res = float2(mush, ID_MUSHROOM);
                float cr = Crystals(p, Grow());
                if (cr < res.x) res = float2(cr, ID_CRYSTAL);
                float part;
                float person = Person(p, part);
                if (person < res.x) res = float2(person, part > 1.5 ? ID_PAPER : ID_PERSON);
                return res;
            }

            float2 Map(float3 p) { return MapX(p, false); }

            float3 SceneNormal(float3 p)
            {
                const float2 e = float2(0.0001, -0.0001);
                float3 g = e.xyy * MapX(p + e.xyy, true).x + e.yyx * MapX(p + e.yyx, true).x + e.yxy * MapX(p + e.yxy, true).x + e.xxx * MapX(p + e.xxx, true).x;
                return g / max(length(g), 1e-12); // 1e-7 だと、なだらかな所で向きが短くなってしまう
            }

            float SoftShadow(float3 p, float3 l)
            {
                float res = 1.0;
                float t = 0.0008;
                int n = clamp((int)_ShadowSteps, 8, 16);
                [loop] for (int i = 0; i < 32; i++)
                {
                    if (i >= n) break;
                    float3 sp = p + l * t;
                    if (max(abs(sp.x), abs(sp.z)) > INNER) break; // 箱の外へ出たら、もう何もない (切り口が影を落とさないように)
                    if (sp.y > 0.0) break;
                    float h = Map(sp).x;
                    res = min(res, 16.0 * h / t);
                    t += clamp(h, 0.0012, 0.04);
                    if (res < 0.01 || t > 0.3) break;
                }
                return saturate(res);
            }

            float AmbientOcclusion(float3 p, float3 n)
            {
                float occ = 0.0;
                float w = 1.0;
                [loop] for (int i = 1; i <= 4; i++)
                {
                    float d = 0.002 * i;
                    occ += (d - Map(p + n * d).x) * w;
                    w *= 0.6;
                }
                return saturate(1.0 - occ * 35.0);
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

            // かすんだ昼の空: 地平線は白っぽく、上は淡い青
            float3 Sky(float3 rd)
            {
                float3 L = normalize(SUN_DIR);
                float up = saturate(rd.y);
                float3 c = lerp(float3(0.95, 0.9, 0.82), float3(0.45, 0.62, 0.85), pow(up, 0.5));
                float sd = dot(rd, L);
                c += float3(4.0, 3.6, 3.0) * smoothstep(0.9994, 0.9997, sd) + float3(0.5, 0.45, 0.35) * pow(saturate(sd), 16.0) * 0.6;
                return c;
            }

            // 材質の色と、つるつるの具合 (反射の絵でも使う)
            float3 Albedo(float3 p, float id, float3 n, out float rough, out float sss)
            {
                rough = 0.8;
                sss = 0.0;
                if (id == ID_MUSHROOM || id == ID_CRYSTAL)
                {
                    // 塩: 白く、少し光を通す。水面の近くほど真っ白で、上は少し黄ばむ
                    float y = p.y - WATER;
                    rough = id == ID_CRYSTAL ? 0.15 : 0.55;
                    sss = 0.6;
                    return lerp(float3(0.9, 0.89, 0.86), float3(0.8, 0.76, 0.68), saturate(y / 0.02)) * (0.92 + 0.08 * Noise3(p * 3000.0));
                }
                if (id == ID_PERSON) { rough = 0.5; sss = 0.3; return float3(0.78, 0.55, 0.42); }
                if (id == ID_PAPER) { rough = 0.9; return float3(0.9, 0.9, 0.86) * (0.85 + 0.15 * step(0.5, frac(p.y * 5000.0))); }
                float y = p.y - WATER;
                if (p.z < -0.3)
                {
                    // モアブの山並み: 赤茶色の地層の縞
                    float band = frac((p.y + 0.004 * Noise3(p * 40.0)) * 70.0);
                    rough = 0.9;
                    return lerp(float3(0.5, 0.27, 0.17), float3(0.7, 0.48, 0.32), smoothstep(0.3, 0.7, band)) * (0.75 + 0.35 * Noise3(p * 300.0));
                }
                // 岸と底: 塩の白。乾いた岸は六角形のひび割れ。水の中の底は、塩の粒でざらざら
                float2 g = p.xz * 110.0;
                float2 hx = float2(g.x + g.y * 0.5, g.y * 0.866);
                float2 cell = frac(hx) - 0.5;
                float crack = smoothstep(0.42, 0.48, max(abs(cell.x), abs(cell.y)));
                float3 salt = float3(0.84, 0.82, 0.78) * (0.9 + 0.1 * Noise3(p * 1200.0));
                float dry = smoothstep(0.0, 0.003, y);
                salt *= 1.0 - 0.25 * crack * dry;
                // 岸の上のほうは、塩の少ない砂利 (灰色がかった茶色)
                salt = lerp(salt, float3(0.74, 0.7, 0.63) * (0.9 + 0.15 * Noise3(p * 1500.0)), smoothstep(0.006, 0.011, y));
                rough = lerp(0.35, 0.85, dry);
                return salt;
            }

            float3 Shade(float3 ro, float3 rd, float3 p, float id, float3 faceNormal, bool lite)
            {
                float3 L = normalize(SUN_DIR);
                float3 sunCol = float3(1.7, 1.55, 1.35);
                float3 skyTop = float3(0.35, 0.48, 0.68);
                float3 skyLow = float3(0.5, 0.48, 0.45);
                float3 v = -rd;

                if (id == ID_BASE)
                    return float3(0.015, 0.014, 0.014) + 0.03 * pow(saturate(1.0 - abs(dot(rd, faceNormal))), 4.0);

                // 映り込み用 (lite) は、高さの表で向きを測る安い方法にする
                float3 n;
                if (lite)
                {
                    const float2 e = float2(0.0004, -0.0004);
                    float3 g = e.xyy * Map(p + e.xyy).x + e.yyx * Map(p + e.yyx).x + e.yxy * Map(p + e.yxy).x + e.xxx * Map(p + e.xxx).x;
                    n = g / max(length(g), 1e-12);
                }
                else n = SceneNormal(p);
                float rough, sss;
                float3 albedo = Albedo(p, id, n, rough, sss);
                if (lite) return Surface(albedo, n, v, L, sunCol, 1.0, 1.0, rough, 0.04, sss, skyTop, skyLow);

                // 水の底は、影と陰を省く (水ごしでは、ほとんど見分けがつかない)
                bool underwater = p.y < WATER - 0.0005;
                float sh = underwater ? 1.0 : SoftShadow(p + n * 0.0004, L);
                float ao = underwater ? 1.0 : AmbientOcclusion(p, n);
                if (id == ID_GROUND && max(abs(p.x), abs(p.z)) > INNER - 0.0015 && abs(n.y) < 0.5)
                    return Surface(float3(0.55, 0.45, 0.35) * (0.8 + 0.4 * Noise3(p * 900.0)), n, v, L, sunCol, 1.0, 1.0, 0.9, 0.03, 0.0, skyTop, skyLow); // 地面の切り口
                float3 nb = BumpNormal(n, p, 3000.0, id == ID_GROUND ? 0.2 : (id == ID_MUSHROOM ? 0.7 : 0.05));
                float3 col = Surface(albedo, nb, v, L, sunCol, sh, ao, rough, id == ID_CRYSTAL ? 0.08 : 0.04, sss, skyTop, skyLow);
                // 結晶のきらめき: 立方体の面が、ちらちらと日を返す
                if (id == ID_CRYSTAL)
                {
                    float3 cell = floor(p / 0.0004);
                    float3 f = frac(p / 0.0004) - 0.5;
                    float spark = step(0.97, Hash31(cell + floor(_Time.y * 6.0))) * smoothstep(0.5, 0.1, length(f));
                    col += float3(4.0, 3.8, 3.4) * spark * Grow() * sh;
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

            // 水面のさざ波 (とても静か。濃い塩水は、ゆっくり、ゆるやかに揺れる)
            float3 WaterNormal(float2 xz)
            {
                float t = _Time.y;
                float2 q = xz * 120.0;
                float2 slope = float2(ValueNoise(q + t * 0.15) - ValueNoise(q + float2(0.3, 0) + t * 0.15),
                                      ValueNoise(q.yx - t * 0.12) - ValueNoise(q.yx + float2(0.3, 0) - t * 0.12));
                return normalize(float3(slope.x * 0.25, 1.0, slope.y * 0.25));
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

                const float maxHeight = -0.02; // 向こう岸の山のてっぺんより少し上
                if (ro.y > maxHeight && rd.y < 0.0) t = max(t, (maxHeight - ro.y) / rd.y);

                bool hit = false;
                float id = 0.0;
                float lastD = 1.0, lastId = 0.0;
                bool ranOut = false;
                int steps = (int)_Steps;
                [loop] for (int i = 0; i <= 200; i++)
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
                if (hit) col = Shade(ro, rd, ro + rd * t, id, faceNormal, false);
                else if (!outside) col = Sky(rd);
                float alpha = (hit || !outside) ? 1.0 : 0.0;

                // 水面: 水面より上から見下ろしていて、物に当たる前に水面を通るなら、水の色と映り込みを重ねる
                float tW = rd.y < 0.0 ? (WATER - ro.y) / rd.y : -1.0;
                float3 wp = ro + rd * tW;
                if (ro.y > WATER && tW > max(box.x, 0.0) && tW < tHit && max(abs(wp.x), abs(wp.z)) < INNER)
                {
                    // 水の中: 深いほど赤が吸われて、青緑になる。浅瀬は白い底が透けて明るい
                    float len = tHit - tW;
                    float3 absorb = exp(-float3(90.0, 24.0, 19.0) * len);
                    float3 under = col * absorb + float3(0.02, 0.2, 0.24) * (1.0 - absorb);
                    // 映り込み: はね返った線で、山ときのこを短くたどる (見つからなければ空)
                    float3 wn = WaterNormal(wp.xz);
                    float3 rr = reflect(rd, wn);
                    float3 refl = Sky(rr);
                    float tr = 0.001;
                    // 上を向いてはね返る線は、空しか映らないので、たどらない (山ときのこは、低い角度の線にだけ映る)
                    if (rr.y < 0.3)
                    {
                        [loop] for (int k = 0; k < 28; k++)
                        {
                            float3 q = wp + rr * tr;
                            if (q.y > maxHeight || max(abs(q.x), abs(q.z)) > INNER) break;
                            float2 m = Map(q);
                            if (m.x < 0.0004 + 0.001 * tr)
                            {
                                refl = Shade(wp, rr, q, m.y, faceNormal, true);
                                break;
                            }
                            tr += m.x * 1.2;
                        }
                    }
                    float fres = 0.02 + 0.98 * pow(1.0 - saturate(dot(-rd, wn)), 5.0);
                    col = lerp(under, refl, fres);
                    // 日のきらめき
                    float3 L = normalize(SUN_DIR);
                    col += float3(3.0, 2.8, 2.4) * pow(saturate(dot(rr, L)), 400.0);
                    alpha = 1.0;
                }

                // 死海のかすみ: 遠くほど白っぽくかすむ (向こう岸の山が、ぼんやり見える)
                float travel = min(tHit, tW > 0.0 && tW < tHit ? tW : tHit) - max(box.x, 0.0);
                if (alpha > 0.5) col = lerp(col, float3(0.85, 0.82, 0.78), (1.0 - exp(-travel * 1.1)) * 0.3);

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
