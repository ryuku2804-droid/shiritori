// 作品「海の断面」(海の間)。明るい珊瑚の浅瀬から、光の届かない深海までを、横から切り取った水槽。URP 用。
// Cube の中をレイマーチングして描く。Cube の座標は -0.5〜0.5、下の 0.08 は黒い台。
//
// 見どころ:
//   ・本物の海と同じ光り方: 赤い光ほど早く水に吸われるので、深いほど青く、もっと深いと真っ暗になる。白いマリンスノーが漂う
//   ・左は色とりどりの珊瑚の棚 (砂の波紋・脳みそのような珊瑚・枝の珊瑚)。その先は切り立った崖で、右は深い海の底
//   ・立体の生き物:
//       魚の群れ (尾びれ・背びれ・目があり、体をくねらせて泳ぐ。背中は暗い青、おなかは銀色)
//       クラゲ (半透明のかさが拍動し、縁が光る。長い触手と、ひらひらした口腕)
//       深海の底: ダイオウグソクムシ (節のある殻・しっぽの扇・触角・14 本の脚で歩く)、ナマコ、クモヒトデ、チョウチンアンコウ (光る誘引突起)
// 仕掛け (_Event 0〜1): 生物発光。真ん中から青い光の波が広がり、プランクトンもクラゲも魚も一斉に光って、深海の闇と生き物が浮かび上がる
//
// 外から見たとき、水面より上 (空気の所) は透明にして、ガラスケースの向こうの部屋が見えるようにする。
// 中に入ったとき (カメラが箱の中) は、水の中にいる。水面を見上げると、ゆらぐ光の窓が見える
//
// _Steps / _ShadowSteps は DioramaLOD が距離で下げる。_Event / _EventTime は DioramaWork が渡す。
// _HeightTex は DioramaWork が再生の最初に作る、珊瑚の棚の高さの表 (なければ式で計算する)
Shader "NightShards/Diorama/DeepSea"
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
        TEXTURE2D(_HeightTex);
        SAMPLER(sampler_linear_clamp);
        ENDHLSL

        Pass
        {
            Name "Diorama"
            Tags { "LightMode" = "UniversalForward" }
            Cull Front
            ZWrite On
            Blend One OneMinusSrcAlpha // 空気の所は透明 (色はあらかじめ不透明度を掛けて出す)

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma multi_compile_instancing

            #define ID_BASE   0.0
            #define ID_GROUND 1.0

            #define INNER 0.47
            #define SURF 0.36        // 水面の高さ

            // 生き物の種類と数
            #define K_FISH 0
            #define K_JELLY 1
            #define K_ISOPOD 2
            #define K_CUCUMBER 3
            #define K_STAR 4
            #define K_ANGLER 5
            #define N_FISH 24
            #define N_JELLY 5
            #define N_ISOPOD 2
            #define N_CUCUMBER 3
            #define N_STAR 3
            #define N_CREATURES 38   // 全部の数 (上の合計)
            #define FISH_LEN 0.014

            // 見る線にかかる水のにごり (赤・緑・青)。小さいほど透き通った水。赤ほど大きい = 赤い光ほど早く吸われる
            static const float3 SIGMA = float3(1.5, 0.55, 0.36);
            // 水面からの日の光が、深さで弱まる速さ (こちらは強めにして、深海はちゃんと暗くする)
            static const float3 LIGHT_SIGMA = float3(3.2, 1.45, 1.0);
            static const float3 GLOW_CENTER = float3(0.15, -0.1, 0.0); // 生物発光が広がり始める所

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

            // ---------------------------------------------------------------- ノイズと形の道具

            float Hash11(float n) { return frac(sin(n * 127.1) * 43758.5453); }

            float Hash21(float2 p)
            {
                p = frac(p * float2(123.34, 456.21));
                p += dot(p, p + 45.32);
                return frac(p.x * p.y);
            }

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

            float SdCapsule(float3 p, float3 a, float3 b, float r)
            {
                float3 pa = p - a, ba = b - a;
                float h = saturate(dot(pa, ba) / dot(ba, ba));
                return length(pa - ba * h) - r;
            }

            // だ円体 (近い値の距離)
            float SdEllipsoid(float3 p, float3 r)
            {
                float k0 = length(p / r);
                float k1 = length(p / (r * r));
                return k0 * (k0 - 1.0) / max(k1, 1e-6);
            }

            float SminK(float a, float b, float k)
            {
                float h = saturate(0.5 + 0.5 * (b - a) / k);
                return lerp(b, a, h) - k * h * (1.0 - h);
            }

            // ---------------------------------------------------------------- 地形
            // ※ ShelfTop・CliffX・AbyssFloor を変えたら、C# の DioramaTerrain も同じに直す (中を歩くときの地面になる)

            float ShelfTop(float2 xz)
            {
                float h = 0.15 + 0.02 * Fbm3(xz * 5.0 + _Seed);
                float c1 = 1.0 - abs(ValueNoise(xz * 22.0 + _Seed) * 2.0 - 1.0);
                float c2 = 1.0 - abs(ValueNoise(xz * 50.0 + _Seed * 1.3) * 2.0 - 1.0);
                float coral = c1 * c1 * 0.8 + c2 * c2 * 0.4;
                h += 0.03 * coral * smoothstep(0.35, 0.6, ValueNoise(xz * 7.0 + _Seed * 2.0));
                return h;
            }

            float ShelfTopFast(float2 xz)
            {
                [branch] if (_HeightTexOn > 0.5)
                    return SAMPLE_TEXTURE2D_LOD(_HeightTex, sampler_linear_clamp, xz / (2.0 * INNER) + 0.5, 0).r;
                return ShelfTop(xz);
            }

            // 崖の面: ゆるやかにうねり、横に重なる岩の層が、少しずつ段になる
            float CliffX(float y, float z)
            {
                return 0.03 + 0.04 * sin(z * 4.0 + _Seed) + 0.016 * (ValueNoise(float2(z * 5.0, y * 3.0) + _Seed) - 0.5)
                     + 0.004 * sin(y * 55.0 + sin(z * 3.0) * 2.0);
            }

            float AbyssFloor(float2 xz)
            {
                return -0.38 + 0.03 * Fbm3(xz * 4.0 + _Seed);
            }

            float2 MapX(float3 p, bool exact)
            {
                float2 res = float2(SdBox(p - float3(0, -0.46, 0), float3(0.5, 0.04, 0.5)), ID_BASE);
                float column = SdBox(p - float3(0, 0.04, 0), float3(INNER, 0.46, INNER));
                float top;
                if (exact) top = ShelfTop(p.xz);
                else top = ShelfTopFast(p.xz);
                float shelf = max((p.y - top) * 0.5, (p.x - CliffX(p.y, p.z)) * 0.5);
                float abyss = (p.y - AbyssFloor(p.xz)) * 0.5;
                float ground = max(min(shelf, abyss), column);
                if (ground < res.x) res = float2(ground, ID_GROUND);
                return res;
            }

            float2 Map(float3 p) { return MapX(p, false); }

            float3 SceneNormal(float3 p)
            {
                const float2 e = float2(0.0007, -0.0007);
                float3 g = e.xyy * MapX(p + e.xyy, true).x + e.yyx * MapX(p + e.yyx, true).x +
                           e.yxy * MapX(p + e.yxy, true).x + e.xxx * MapX(p + e.xxx, true).x;
                return g / max(length(g), 1e-7);
            }

            float AmbientOcclusion(float3 p, float3 n)
            {
                float occ = 0.0;
                float w = 1.0;
                for (int i = 1; i <= 4; i++)
                {
                    float d = 0.008 * i;
                    occ += (d - Map(p + n * d).x) * w;
                    w *= 0.6;
                }
                return saturate(1.0 - occ * 16.0);
            }

            // ---------------------------------------------------------------- 光

            // 水面からの日の光が、深さ y まで届く量 (赤・緑・青)。深いほど青だけが残り、やがて消える
            float3 SunReach(float y) { return exp(-LIGHT_SIGMA * max(SURF - y, 0.0)); }

            // 光の届かない深海でも、生き物の形がほんのり分かるくらいの、ごく弱い青い明るさ
            static const float3 DEEP_AMBIENT = float3(0.004, 0.014, 0.03);

            // 生物発光の光の波: 真ん中から広がり、通った所は光り続ける
            float GlowWave(float3 p)
            {
                if (_Event < 0.01) return 0.0;
                float R = _EventTime * 0.14;
                float d = length(p - GLOW_CENTER);
                float x = (d - R) / 0.05;
                return (smoothstep(R, R - 0.1, d) * 0.6 + exp(-x * x) * 1.2) * saturate(_Event * 1.5);
            }

            // ---------------------------------------------------------------- 生き物の場所と向き

            // 生き物 c 番 (0〜37) の種類と、その種類の中の番号
            void CreatureKind(int c, out int kind, out int idx)
            {
                if (c < N_FISH) { kind = K_FISH; idx = c; }
                else if (c < N_FISH + N_JELLY) { kind = K_JELLY; idx = c - N_FISH; }
                else if (c < N_FISH + N_JELLY + N_ISOPOD) { kind = K_ISOPOD; idx = c - N_FISH - N_JELLY; }
                else if (c < N_FISH + N_JELLY + N_ISOPOD + N_CUCUMBER) { kind = K_CUCUMBER; idx = c - N_FISH - N_JELLY - N_ISOPOD; }
                else if (c < N_FISH + N_JELLY + N_ISOPOD + N_CUCUMBER + N_STAR) { kind = K_STAR; idx = c - N_FISH - N_JELLY - N_ISOPOD - N_CUCUMBER; }
                else { kind = K_ANGLER; idx = 0; }
            }

            // 生き物の中心・向き (y 軸まわりの角度。体の前が +x)・包む球の半径
            void CreatureFrame(int kind, int idx, out float3 C, out float yaw, out float radius)
            {
                float t = _Time.y;
                float fi = idx;
                if (kind == K_FISH)
                {
                    // 群れは浅瀬の上をゆっくり回り、1 匹ずつは群れの中をぐるぐる回る
                    float3 center = float3(-0.22 + 0.08 * sin(t * 0.25), 0.27 + 0.025 * sin(t * 0.4), 0.12 * cos(t * 0.25));
                    float a = Hash11(fi) * 6.2831 + t * (0.6 + 0.3 * Hash11(fi + 3.0));
                    float rad = 0.03 + 0.05 * Hash11(fi + 7.0);
                    C = center + float3(cos(a) * rad, (Hash11(fi + 11.0) - 0.5) * 0.06 + 0.005 * sin(t * 1.3 + fi), sin(a) * rad);
                    yaw = atan2(cos(a), -sin(a));
                    radius = FISH_LEN * 0.8;
                }
                else if (kind == K_JELLY)
                {
                    C = float3(0.08 + 0.32 * Hash11(fi + 1.0), -0.22 + 0.32 * Hash11(fi + 2.0) + 0.03 * sin(t * 0.3 + fi * 2.0),
                               -0.35 + 0.7 * Hash11(fi + 3.0));
                    yaw = fi;
                    radius = 0.03;
                }
                else if (kind == K_ISOPOD)
                {
                    // 深い底を、ゆっくり大きな輪をえがいて歩く
                    float dirSign = idx == 0 ? 1.0 : -1.0;
                    float a = t * 0.012 * dirSign + fi * 2.0;
                    float2 o = float2(0.27, -0.15 + 0.3 * fi);
                    float2 xz = o + float2(cos(a), sin(a)) * 0.07;
                    float2 dir = float2(-sin(a), cos(a)) * dirSign;
                    C = float3(xz.x, AbyssFloor(xz) + 0.0055, xz.y);
                    yaw = atan2(dir.y, dir.x);
                    radius = 0.05;
                }
                else if (kind == K_CUCUMBER)
                {
                    float2 xz = float2(0.16 + 0.1 * fi, -0.32 + 0.28 * fi + 0.05 * Hash11(fi + 5.0));
                    C = float3(xz.x, AbyssFloor(xz) + 0.003, xz.y);
                    yaw = Hash11(fi + 9.0) * 6.2831;
                    radius = 0.016;
                }
                else if (kind == K_STAR)
                {
                    float2 xz = float2(0.36 - 0.08 * fi, 0.05 + 0.13 * fi - 0.2);
                    C = float3(xz.x, AbyssFloor(xz) + 0.0012, xz.y);
                    yaw = Hash11(fi + 13.0) * 6.2831 + t * 0.02;
                    radius = 0.02;
                }
                else
                {
                    // チョウチンアンコウ: 底の近くで、ほとんど動かずに漂う
                    C = float3(0.33 + 0.03 * sin(t * 0.08), -0.29 + 0.008 * sin(t * 0.3), 0.18);
                    yaw = 2.6 + 0.3 * sin(t * 0.05);
                    radius = 0.03;
                }
            }

            float3 ToLocal(float3 v, float yaw)
            {
                float c = cos(yaw), s = sin(yaw);
                return float3(v.x * c + v.z * s, v.y, -v.x * s + v.z * c);
            }

            // ---------------------------------------------------------------- 生き物の形 (それぞれの体の向きの座標で)

            // 魚: 細長い体、尾びれ、背びれ。後ろほど大きく体をくねらせる
            float FishSDF(float3 p, float fi)
            {
                float L = FISH_LEN;
                float x = p.x / L;
                p.z += sin(x * 6.0 - _Time.y * (9.0 + 2.0 * Hash11(fi))) * 0.07 * L * saturate(0.35 - x);
                float body = SdEllipsoid(p, float3(0.5 * L, 0.16 * L, 0.07 * L));
                float3 q = p - float3(-0.5 * L, 0, 0);
                float tail = max(max(abs(q.z) - 0.008 * L, abs(q.y) - (0.03 * L + max(-q.x, 0.0) * 1.3)), max(q.x - 0.03 * L, -q.x - 0.2 * L));
                float3 q2 = p - float3(0.02 * L, 0.13 * L, 0);
                float dorsal = max(max(abs(q2.z) - 0.006 * L, q2.y - 0.1 * L + abs(q2.x) * 0.9), -q2.y);
                return min(body, min(tail, dorsal));
            }

            // クラゲのかさ: 薄い殻。拍動して、ひらいたりすぼまったりする。下はあいている
            float JellySDF(float3 p, float fi)
            {
                float pulse = sin(_Time.y * 1.6 + fi * 1.3);
                float R = 0.018;
                float3 r = float3(R * (1.0 + 0.1 * pulse), R * 0.72 * (1.0 - 0.12 * pulse), R * (1.0 + 0.1 * pulse));
                float shell = abs(SdEllipsoid(p, r)) - 0.0012;
                return max(shell, -p.y - 0.1 * R);
            }

            // ダイオウグソクムシ: 平たいドームの殻に節のみぞ、しっぽの扇、触角 2 本、脚 7 対で歩く
            float IsopodSDF(float3 p, float fi)
            {
                float L = 0.026;
                float body = SdEllipsoid(p, float3(L, 0.0085, 0.0135));
                body = max(body, -p.y - 0.001);                                            // おなかは平ら
                float groove = 1.0 - smoothstep(0.0, 0.22, abs(sin(p.x / L * 3.1416 * 4.5 + 0.6)));
                body += 0.0007 * groove * smoothstep(-0.7 * L, -0.4 * L, -abs(p.x));        // 背中の節のみぞ
                float tail = SdEllipsoid(p - float3(-0.95 * L, -0.0015, 0), float3(0.008, 0.0028, 0.011));
                float d = SminK(body, tail, 0.002);
                // 触角: 頭の先から、外へ曲がりながら前へ
                for (int s = -1; s <= 1; s += 2)
                {
                    float fs = s;
                    float3 a0 = float3(0.95 * L, 0.0005, 0.004 * fs);
                    float3 a1 = float3(1.35 * L, 0.002, 0.011 * fs);
                    float3 a2 = float3(1.7 * L, 0.0005, 0.02 * fs);
                    d = min(d, min(SdCapsule(p, a0, a1, 0.0006), SdCapsule(p, a1, a2, 0.0004)));
                }
                // 脚: 7 対。左右で互い違いに前後へ動いて歩く
                float walk = _Time.y * 3.0 + fi * 2.0;
                if (p.y < 0.0)
                {
                    for (int k = 0; k < 7; k++)
                    {
                        float fk = k;
                        float x = L * (0.7 - fk * 0.21);
                        for (int s2 = -1; s2 <= 1; s2 += 2)
                        {
                            float fs = s2;
                            float swing = 0.0025 * sin(walk + fk * 1.1 + fs * 1.57);
                            float3 hip = float3(x, -0.002, 0.009 * fs);
                            float3 foot = float3(x + swing, -0.0055, 0.0155 * fs);
                            d = min(d, SdCapsule(p, hip, foot, 0.0009));
                        }
                    }
                }
                return d;
            }

            // ナマコ: いぼのある、ずんぐりした筒
            float CucumberSDF(float3 p, float fi)
            {
                float breathe = 1.0 + 0.04 * sin(_Time.y * 0.7 + fi);
                float d = SdCapsule(p, float3(-0.009, 0, 0), float3(0.009, 0.0005, 0), 0.0034 * breathe);
                d -= 0.0007 * Noise3(p * 900.0 + fi * 7.0);
                return max(d, -p.y - 0.0028);
            }

            // クモヒトデ: 小さな円盤から、細い腕が 5 本。腕はゆっくりうねる
            float StarSDF(float3 p, float fi)
            {
                float d = SdEllipsoid(p, float3(0.004, 0.0012, 0.004));
                for (int a = 0; a < 5; a++)
                {
                    float fa = a;
                    float ang = fa * 1.2566 + fi;
                    float2 dir = float2(cos(ang), sin(ang));
                    float2 side = float2(-dir.y, dir.x);
                    float wave = sin(_Time.y * 0.8 + fa * 1.7 + fi) * 0.003;
                    float3 p0 = float3(dir.x * 0.003, 0, dir.y * 0.003);
                    float3 p1 = float3(dir.x * 0.009 + side.x * wave, 0, dir.y * 0.009 + side.y * wave);
                    float3 p2 = float3(dir.x * 0.017 - side.x * wave, 0, dir.y * 0.017 - side.y * wave);
                    d = min(d, min(SdCapsule(p, p0, p1, 0.0011), SdCapsule(p, p1, p2, 0.0007)));
                }
                return d;
            }

            // チョウチンアンコウ: 丸い体と大きな頭、頭の上から前へのびる竿 (先が光る)
            float AnglerSDF(float3 p)
            {
                float body = SdEllipsoid(p, float3(0.013, 0.01, 0.008));
                float jaw = SdEllipsoid(p - float3(0.007, -0.004, 0), float3(0.007, 0.004, 0.0075));
                float tail = SdEllipsoid(p - float3(-0.016, 0, 0), float3(0.006, 0.005, 0.001));
                float rod = min(SdCapsule(p, float3(0.006, 0.009, 0), float3(0.013, 0.016, 0), 0.0004),
                                SdCapsule(p, float3(0.013, 0.016, 0), float3(0.019, 0.013, 0), 0.0004));
                return min(SminK(body, jaw, 0.002), min(tail, rod));
            }

            float CreatureSDF(int kind, int idx, float3 p)
            {
                float fi = idx;
                if (kind == K_FISH) return FishSDF(p, fi);
                if (kind == K_JELLY) return JellySDF(p, fi);
                if (kind == K_ISOPOD) return IsopodSDF(p, fi);
                if (kind == K_CUCUMBER) return CucumberSDF(p, fi);
                if (kind == K_STAR) return StarSDF(p, fi);
                return AnglerSDF(p);
            }

            float3 CreatureNormal(int kind, int idx, float3 p)
            {
                const float2 e = float2(0.00015, -0.00015);
                float3 g = e.xyy * CreatureSDF(kind, idx, p + e.xyy) + e.yyx * CreatureSDF(kind, idx, p + e.yyx) +
                           e.yxy * CreatureSDF(kind, idx, p + e.yxy) + e.xxx * CreatureSDF(kind, idx, p + e.xxx);
                return g / max(length(g), 1e-7);
            }

            // 線が生き物に当たるかを調べる。生き物ごとに、包む球の中だけを進むので軽い。
            // 当たったら true。いちばん手前の生き物の種類・番号・距離・その生き物の座標での当たった所と線の向きを返す
            bool TraceCreatures(float3 ro, float3 rd, float tMax, out float tHit, out int hitKind, out int hitIdx, out float3 hitLocal, out float3 dirLocal, out float3 hitCenter)
            {
                tHit = tMax;
                hitKind = -1;
                hitIdx = 0;
                hitLocal = 0;
                dirLocal = 0;
                hitCenter = 0;
                for (int c = 0; c < N_CREATURES; c++)
                {
                    int kind, idx;
                    CreatureKind(c, kind, idx);
                    float3 C;
                    float yaw, radius;
                    CreatureFrame(kind, idx, C, yaw, radius);
                    float3 oc = ro - C;
                    float b = dot(oc, rd);
                    float disc = b * b - (dot(oc, oc) - radius * radius);
                    if (disc <= 0.0) continue;
                    float sq = sqrt(disc);
                    float t0 = max(-b - sq, 0.0);
                    float t1 = min(-b + sq, tHit);
                    if (t1 <= t0) continue;
                    float3 o = ToLocal(oc, yaw);
                    float3 v = ToLocal(rd, yaw);
                    float t = t0;
                    for (int s = 0; s < 24; s++)
                    {
                        float d = CreatureSDF(kind, idx, o + v * t);
                        if (d < 0.00012)
                        {
                            tHit = t;
                            hitKind = kind;
                            hitIdx = idx;
                            hitLocal = o + v * t;
                            dirLocal = v;
                            hitCenter = C;
                            break;
                        }
                        t += max(d, 0.0002);
                        if (t > t1) break;
                    }
                }
                return hitKind >= 0;
            }

            // ---------------------------------------------------------------- 生き物の色 (a は不透明度。クラゲだけ半透明)

            float4 ShadeCreature(int kind, int idx, float3 p, float3 v, float3 C)
            {
                float3 n = CreatureNormal(kind, idx, p);
                float fi = idx;
                float3 sun = SunReach(C.y);
                float glow = GlowWave(C);
                float up = saturate(n.y * 0.5 + 0.5);
                float3 light = sun * (0.25 + 0.9 * up) + DEEP_AMBIENT * 3.0 + float3(0.1, 0.35, 0.9) * glow * 0.6;
                float fres = pow(1.0 - saturate(dot(-v, n)), 4.0);
                float3 h = normalize(float3(0, 1, 0) - v);
                float spec = pow(saturate(dot(n, h)), 40.0);

                if (kind == K_FISH)
                {
                    // 背中は暗い青、おなかは銀色 (下から見上げた敵に見つかりにくい配色)。体の横に黄色い筋。目は黒く光る
                    float L = FISH_LEN;
                    float3 back = float3(0.08, 0.16, 0.26), belly = float3(0.82, 0.86, 0.9);
                    float3 albedo = lerp(belly, back, smoothstep(-0.03 * L, 0.06 * L, p.y));
                    float sy = (p.y - 0.01 * L) / (0.025 * L);
                    float stripe = exp(-sy * sy) * smoothstep(-0.4 * L, -0.1 * L, p.x);
                    albedo = lerp(albedo, float3(0.95, 0.8, 0.25), stripe * (Hash11(fi + 2.0) > 0.5 ? 0.7 : 0.0));
                    float2 eye = float2(p.x - 0.36 * L, p.y - 0.03 * L);
                    float eyeMask = smoothstep(0.045 * L, 0.03 * L, length(eye)) * step(0.03 * L, abs(p.z));
                    albedo = lerp(albedo, float3(0.01, 0.01, 0.015), eyeMask);
                    float3 col = albedo * light + sun * (spec * 1.5 + fres * 0.4) * (0.6 + 0.4 * Noise3(p * 2500.0)); // うろこのきらめき
                    col += float3(0.2, 0.6, 1.5) * glow * 0.8;
                    return float4(col, 1.0);
                }
                if (kind == K_JELLY)
                {
                    // 半透明のかさ: 縁ほど光って見える (横から見ると、膜が厚く重なるため)。内側に 4 つの模様
                    float3 hue = idx % 2 == 0 ? float3(0.95, 0.5, 0.85) : float3(0.45, 0.7, 1.2);
                    float pattern = smoothstep(0.6, 0.9, abs(sin(atan2(p.z, p.x) * 2.0))) * smoothstep(0.004, 0.0, abs(p.y - 0.006));
                    float bright = 0.25 + 2.5 * glow;
                    float3 col = hue * (0.08 + fres * 0.9 + pattern * 0.3) * (light * 0.8 + bright);
                    return float4(col, 0.25 + 0.6 * fres);
                }
                if (kind == K_ISOPOD)
                {
                    // ダイオウグソクムシ: うす紫がかった灰色のかたい殻。節のみぞは暗く、殻はつやがある。目は黒い
                    float L = 0.026;
                    float groove = 1.0 - smoothstep(0.0, 0.25, abs(sin(p.x / L * 3.1416 * 4.5 + 0.6)));
                    float3 albedo = lerp(float3(0.62, 0.6, 0.66), float3(0.35, 0.32, 0.38), groove * 0.8);
                    albedo *= 0.85 + 0.15 * Noise3(p * 1500.0);
                    float eyeMask = smoothstep(0.003, 0.002, length(float2(p.x - 0.8 * L, abs(p.z) - 0.0085))) * step(0.0, p.y);
                    albedo = lerp(albedo, float3(0.03, 0.03, 0.035), eyeMask);
                    float3 col = albedo * light + (spec * 0.6 + fres * 0.2) * (light + 0.05);
                    return float4(col, 1.0);
                }
                if (kind == K_CUCUMBER)
                {
                    float bump = Noise3(p * 900.0 + fi * 7.0);
                    float3 albedo = lerp(float3(0.35, 0.12, 0.08), float3(0.75, 0.45, 0.35), smoothstep(0.55, 0.8, bump));
                    return float4(albedo * light + spec * 0.15 * light, 1.0);
                }
                if (kind == K_STAR)
                {
                    float band = 0.5 + 0.5 * sin(length(p.xz) * 2000.0);
                    float3 albedo = lerp(float3(0.75, 0.45, 0.3), float3(0.9, 0.75, 0.6), band * 0.5);
                    return float4(albedo * light, 1.0);
                }
                // チョウチンアンコウ: 黒っぽい茶色で、ぬめりのあるつや
                float3 albedo = float3(0.08, 0.06, 0.05);
                float3 col = albedo * light + (spec * 0.4 + fres * 0.15) * float3(0.2, 0.5, 0.7) * 0.3;
                return float4(col, 1.0);
            }

            // ---------------------------------------------------------------- 光るもの (触手・誘引突起)

            // 線と縦の線分 (a から下へ len) の一番近い所の距離の 2 乗と、線の上の位置
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

            float3 Glows(float3 ro, float3 rd, float tMax)
            {
                float3 col = 0;
                float t = _Time.y;
                // クラゲの触手 (細く長く、ゆらゆら) と口腕 (太く短く、ひらひら)
                for (int j = 0; j < N_JELLY; j++)
                {
                    float3 C;
                    float yaw, radius;
                    CreatureFrame(K_JELLY, j, C, yaw, radius);
                    float3 w = C - ro;
                    float tc = dot(w, rd);
                    if (tc < 0.0 || dot(w, w) - tc * tc > 0.012) continue; // 遠いクラゲは飛ばす
                    float3 hue = j % 2 == 0 ? float3(0.95, 0.5, 0.85) : float3(0.45, 0.7, 1.2);
                    float bright = (0.35 + 3.0 * GlowWave(C)) * exp(-SIGMA.b * tc * 0.5);
                    for (int k = 0; k < 8; k++)
                    {
                        float fk = k;
                        float ang = fk * 0.785 + j;
                        float3 a = C + float3(cos(ang) * 0.016, -0.002, sin(ang) * 0.016);
                        float sway = sin(t * 0.9 + fk + j) * 0.008;
                        float3 m = a + float3(sway, -0.05, sway * 0.5);
                        float3 b = m + float3(-sway * 1.5, -0.05, sway);
                        float sc, kk;
                        float d2 = SegmentDist2(ro, rd, a, m, sc, kk);
                        float thin = max(0.0005, sc * 0.0005);
                        if (sc > 0.0 && sc < tMax) col += hue * exp(-d2 / (thin * thin)) * 0.45 * bright;
                        d2 = SegmentDist2(ro, rd, m, b, sc, kk);
                        if (sc > 0.0 && sc < tMax) col += hue * exp(-d2 / (thin * thin)) * 0.45 * (1.0 - kk) * bright;
                    }
                    for (int k2 = 0; k2 < 4; k2++)
                    {
                        float fk = k2;
                        float ang = fk * 1.5708 + j + 0.4;
                        float3 a = C + float3(cos(ang) * 0.003, -0.003, sin(ang) * 0.003);
                        float3 b = a + float3(cos(ang) * 0.004 + sin(t * 1.2 + fk) * 0.003, -0.035, sin(ang) * 0.004);
                        float sc, kk;
                        float d2 = SegmentDist2(ro, rd, a, b, sc, kk);
                        float frill = 0.0016 * (0.7 + 0.3 * sin(kk * 40.0 + t * 2.0)); // ひらひら
                        float thick = max(frill, sc * 0.0007);
                        if (sc > 0.0 && sc < tMax) col += hue * exp(-d2 / (thick * thick)) * 0.35 * bright;
                    }
                }
                // チョウチンアンコウの誘引突起: 竿の先でぼうっと光り、ゆっくり明滅する
                {
                    float3 C;
                    float yaw, radius;
                    CreatureFrame(K_ANGLER, 0, C, yaw, radius);
                    float c = cos(yaw), s = sin(yaw);
                    float3 lure = C + float3(0.019 * c, 0.013, 0.019 * s);
                    float3 w = lure - ro;
                    float tc = dot(w, rd);
                    if (tc > 0.0 && tc < tMax + 0.002)
                    {
                        float d2 = dot(w, w) - tc * tc;
                        float core = max(0.0015, tc * 0.0012);
                        float blink = 0.7 + 0.3 * sin(t * 1.3);
                        col += float3(0.5, 0.95, 1.2) * (exp(-d2 / (core * core)) * 2.0 + exp(-d2 / (core * core * 30.0)) * 0.15) * blink;
                    }
                }
                return col;
            }

            // ---------------------------------------------------------------- 水 (立体)

            // 水の中を進みながら、色ごとのにごりで後ろを隠し (赤から先に消える)、
            // 日の光の筋・深さの色・マリンスノー・プランクトンの光を足す。rgb = 足す光、trans = 後ろが見える割合 (色ごと)
            float3 Water(float3 ro, float3 rd, float t0, float t1, out float3 trans)
            {
                trans = 1.0;
                if (t1 <= t0) return 0;
                int steps = clamp((int)(_Steps / 4.0), 12, 40);
                float dt = (t1 - t0) / steps;
                float t = t0 + dt * Hash21(rd.xy * 517.0 + _Time.y);
                float time = _Time.y;
                float3 col = 0;
                float3 stepTrans = exp(-SIGMA * dt);
                for (int i = 0; i < 40; i++)
                {
                    if (i >= steps) break;
                    float3 p = ro + rd * t;
                    float depth = SURF - p.y;
                    float3 reach = SunReach(p.y);
                    // 光の筋: 水面のゆらぎが作る、ななめに差し込むやわらかい帯 (浅いほどはっきり)
                    float ray = Noise3(float3(p.x * 4.5 + p.y * 1.5, p.z * 4.5 + p.y * 1.0, time * 0.15));
                    float shafts = 0.7 + 1.0 * ray * ray * exp(-depth * 2.5);
                    float3 scatter = reach * float3(0.3, 0.7, 0.8) * shafts * 0.8 + DEEP_AMBIENT;
                    // マリンスノー: ゆっくり沈む、ごく小さな白い粒 (ほんの少しだけ)
                    float snow = pow(Noise3(p * 200.0 + float3(0, time * 0.03, 0)), 30.0) * 25.0;
                    // プランクトン: ふだんはほとんど見えず、生物発光で一斉に光る
                    float spark = pow(Noise3(p * 70.0 + float3(0, time * 0.05, 0)), 14.0);
                    float glow = GlowWave(p);
                    float3 emit = float3(0.2, 0.6, 1.4) * spark * (0.08 * smoothstep(0.1, -0.25, p.y) + 25.0 * glow) + float3(0.02, 0.08, 0.2) * glow;
                    emit += (reach * 0.8 + 0.02) * snow;
                    col += trans * ((1.0 - stepTrans) * scatter + emit * dt * 6.0);
                    trans *= stepTrans;
                    t += dt;
                }
                return col;
            }

            // ---------------------------------------------------------------- 色を塗る (地形)

            float3 Shade(float3 ro, float3 rd, float3 p, float id, float3 faceNormal)
            {
                float t = _Time.y;
                if (id == ID_BASE)
                    return float3(0.015, 0.014, 0.014) + 0.02 * pow(saturate(1.0 - abs(dot(rd, faceNormal))), 4.0);

                float3 n = SceneNormal(p);
                float ao = AmbientOcclusion(p, n);
                float3 sun = SunReach(p.y);
                // 底の光の網目 (浅いほど強い)
                float c1 = 1.0 - abs(ValueNoise(p.xz * 60.0 + t * 0.5) - 0.5) * 2.0;
                float c2 = 1.0 - abs(ValueNoise(p.xz * 95.0 - t * 0.4 + 3.0) - 0.5) * 2.0;
                float caustic = (pow(c1, 10.0) + pow(c2, 10.0)) * saturate(n.y);
                float3 light = sun * (0.45 * saturate(n.y * 0.7 + 0.3) + caustic * 1.6) + sun * float3(0.05, 0.1, 0.12) + DEEP_AMBIENT * 2.0;

                float3 albedo;
                bool onShelf = p.y > 0.1 && p.x < 0.12;
                if (onShelf && n.y > 0.3)
                {
                    float base = 0.15 + 0.02 * Fbm3(p.xz * 5.0 + _Seed);
                    float isCoral = smoothstep(0.004, 0.012, p.y - base);
                    // 砂: 波紋の筋
                    float ripple = 0.5 + 0.5 * sin(dot(p.xz, float2(0.8, 0.6)) * 420.0 + ValueNoise(p.xz * 30.0) * 4.0);
                    float3 sand = float3(0.78, 0.72, 0.58) * (0.85 + 0.15 * ripple);
                    // 珊瑚: ます目ごとに種類と色を変える。脳みそのような筋の珊瑚と、小さな粒 (ポリプ) の珊瑚
                    float cell = Hash21(floor(p.xz * 40.0) + _Seed);
                    float3 coral = cell < 0.2 ? float3(0.9, 0.35, 0.5) : cell < 0.4 ? float3(0.95, 0.55, 0.2)
                                 : cell < 0.6 ? float3(0.55, 0.3, 0.85) : cell < 0.8 ? float3(0.9, 0.8, 0.3) : float3(0.3, 0.75, 0.45);
                    float brain = 0.5 + 0.5 * sin((p.x + ValueNoise(p.xz * 80.0) * 0.02) * 1400.0);
                    float polyp = smoothstep(0.6, 0.8, Noise3(p * 1800.0));
                    coral *= cell < 0.5 ? (0.75 + 0.25 * brain) : (0.8 + 0.3 * polyp);
                    albedo = lerp(sand, coral, isCoral);
                    // 珊瑚は光を少し中に通すので、陰の側もほんのり明るい
                    light += sun * coral * 0.15 * isCoral;
                }
                else
                {
                    // 崖と深い底: 崖は、横に重なる岩の層の縞 (色の濃さが少しずつちがう)。浅い所にだけ、海綿の色がうっすら
                    float strata = 0.5 + 0.5 * sin(p.y * 55.0 + sin(p.z * 3.0) * 2.0);
                    float tone = ValueNoise(float2(p.y * 25.0, p.z * 4.0) + _Seed);
                    albedo = lerp(float3(0.14, 0.13, 0.12), float3(0.24, 0.22, 0.2), strata * 0.6 + tone * 0.4);
                    float sponge = smoothstep(0.7, 0.85, ValueNoise(float2(p.z * 12.0, p.y * 12.0) + _Seed * 3.0));
                    albedo = lerp(albedo, float3(0.5, 0.32, 0.24), sponge * saturate(sun.g * 2.0) * 0.6);
                    if (p.y < -0.3)
                    {
                        float track = smoothstep(0.03, 0.0, abs(sin(p.x * 60.0 + p.z * 25.0 + ValueNoise(p.xz * 20.0) * 3.0)));
                        albedo = lerp(float3(0.3, 0.28, 0.27), float3(0.22, 0.2, 0.2), track * 0.5);
                    }
                }
                float3 c = albedo * light * ao;
                c += albedo * float3(0.1, 0.35, 0.9) * GlowWave(p) * 0.6;
                return c;
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
                float tStart = max(box.x, 0.0);
                float t = tStart;

                float3 entry = ro + rd * t;
                float3 ae = abs(entry);
                float3 faceNormal = ae.x > ae.y && ae.x > ae.z ? float3(sign(entry.x), 0, 0)
                                  : (ae.y > ae.z ? float3(0, sign(entry.y), 0) : float3(0, 0, sign(entry.z)));

                const float maxHeight = 0.22;
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
                    if (m.x < 0.0003 * (1.0 + t))
                    {
                        hit = true;
                        id = m.y;
                        break;
                    }
                    t += m.x;
                }
                if (hit)
                {
                    for (int r = 0; r < 2; r++) t += MapX(ro + rd * t, true).x;
                }
                float tHit = hit ? t : box.y;

                // 水の中を通る区間と、水面に当たる所
                float tSurf = abs(rd.y) > 1e-5 ? (SURF - ro.y) / rd.y : -1.0;
                bool startInWater = (ro + rd * tStart).y < SURF;
                bool fromAbove = !startInWater && rd.y < 0.0 && tSurf > tStart && tSurf < tHit;
                bool hitsSurfaceFromBelow = startInWater && rd.y > 0.0 && tSurf > tStart && tSurf < tHit;
                float tw0 = startInWater ? tStart : (fromAbove ? tSurf : 1e9);
                float tw1 = hitsSurfaceFromBelow ? tSurf : tHit;
                bool throughWater = tw1 > tw0;

                // 生き物 (水の中の区間だけ)
                float tC;
                int cKind, cIdx;
                float3 cLocal, cDir, cCenter;
                bool creature = throughWater && TraceCreatures(ro, rd, tw1, tC, cKind, cIdx, cLocal, cDir, cCenter);

                float3 col = 0;
                float alpha = 0.0;
                if (hit && !hitsSurfaceFromBelow)
                {
                    col = Shade(ro, rd, ro + rd * tHit, id, faceNormal);
                    alpha = 1.0;
                }
                else if (hitsSurfaceFromBelow)
                {
                    // 水面を下から見上げる: 真上ほど明るい光の窓、ななめは水の中を映す暗い鏡。ゆらゆら揺れる
                    float3 sp = ro + rd * tSurf;
                    float wob = ValueNoise(sp.xz * 40.0 + _Time.y * 0.8) + ValueNoise(sp.xz * 90.0 - _Time.y);
                    float window = smoothstep(0.55, 0.85, rd.y + (wob - 1.0) * 0.08);
                    col = lerp(float3(0.02, 0.15, 0.22), float3(0.75, 0.97, 1.05), window) * (0.8 + 0.3 * wob);
                    alpha = 1.0;
                }
                else if (!outside)
                {
                    col = float3(0.35, 0.6, 0.85); // 中から水面の上へ出たときの空
                    alpha = 1.0;
                }

                float tFront = tw1;
                if (creature)
                {
                    float4 cc = ShadeCreature(cKind, cIdx, cLocal, cDir, cCenter);
                    col = lerp(col, cc.rgb, cc.a); // クラゲは半透明で、後ろが透ける
                    tFront = tC; // 水のにごりは、生き物までの分だけかける
                    alpha = 1.0;
                }

                if (throughWater)
                {
                    float3 trans;
                    float3 water = Water(ro, rd, tw0, tFront, trans);
                    col = col * trans + water;
                    col += Glows(ro, rd, tw1);
                    if (fromAbove)
                    {
                        // 水面を上から見る: 空を映し、その下の水が透けて見える
                        float3 sp = ro + rd * tSurf;
                        float2 slope = (float2(ValueNoise(sp.xz * 80.0 + _Time.y * 0.6), ValueNoise(sp.xz * 80.0 + 5.0 - _Time.y * 0.5)) - 0.5) * 0.1;
                        float3 n = normalize(float3(slope.x, 1.0, slope.y));
                        float fres = 0.02 + 0.98 * pow(1.0 - saturate(dot(-rd, n)), 5.0);
                        col = lerp(col, float3(0.5, 0.7, 0.9), fres);
                    }
                    alpha = 1.0; // 水の入った水槽は、向こうが見えない
                }

                // ガラス: 外から見ているときだけ、映り込みと金属の枠
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

                // 壊れた値のピクセルがあると、ブルームで画面全体が白く点滅するので、最後に範囲へ収める
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
