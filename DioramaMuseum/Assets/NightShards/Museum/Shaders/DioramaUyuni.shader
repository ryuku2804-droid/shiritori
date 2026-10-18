// 作品「ウユニ塩湖」(アンデスの間)。雨季の「天空の鏡」。URP 用。
// Cube の中をレイマーチングして描く。Cube の座標は -0.5〜0.5、下の 0.08 は黒い台。
//
// 形は実物の寸法 (1 m = 0.01)。
//   ・真っ白な塩の平原に、数 cm の雨水が張り、空と雲を鏡のように映す。水の下には、塩の六角形の模様 (1 辺 1〜2 m) が透ける
//   ・ガラスケースの中に、もくもくの積雲が浮かび、その下の鏡にも映る。地平線が消え、空の中に浮かんでいるように見える
//   ・鏡の上に、ランドクルーザー (長さ 4.9 m・屋根に荷物) と、写真を撮る人たち。足元から小さな波の輪が広がる
//   ・奥に、トゥヌパ火山 (赤・黄土色の地層の山) と、低い山並み
// 仕掛け (_Event 0〜1): 夕焼けに染まり、やがて夜になる。満天の星と天の川が、空と鏡の上下に広がり、星の中に浮かぶ
//
// 外から見たとき、何もない所 (空) は透明にして、ガラスケースの向こうの部屋が見えるようにする (雲と鏡は見える)。
// 中に入ったとき (カメラが箱の中) だけ、空を描く
Shader "NightShards/Diorama/Uyuni"
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

            float SdCapsule(float3 p, float3 a, float3 b, float r)
            {
                float3 pa = p - a, ba = b - a;
                float h = saturate(dot(pa, ba) / dot(ba, ba));
                return length(pa - ba * h) - r;
            }

            float SdRoundBox(float3 p, float3 b, float r) { return SdBox(p, b - r) - r; }

            // ---------------------------------------------------------------- 場所と寸法 (1 m = 0.01)
            // ※ 車・人・山の場所を変えたら、C# の DioramaTerrain (Uyuni) も同じに直す (当たり判定)

            #define ID_BASE   0.0
            #define ID_CAR    1.0
            #define ID_PERSON 2.0
            #define ID_MOUNT  3.0
            #define ID_TIRE   4.0

            #define GROUND -0.3
            #define WATER -0.2995                                   // 塩の上の雨水 (5 cm)
            #define PEOPLE 5
            static const float3 CAR = float3(0.12, -0.2995, 0.05);  // 車の真ん中 (水面の高さ)
            static const float3 TUNUPA = float3(-0.16, -0.3, -0.62); // トゥヌパ火山の中心 (箱の奥の外側。上の部分が見える)
            static const float3 SUN_DAY = float3(0.55, 0.62, -0.55);

            // 夜になる割合と、夕焼けの割合 (仕掛け)
            float Night() { return _Event * smoothstep(2.5, 6.5, _EventTime); }
            float Sunset() { return saturate(_Event - Night()) * (1.0 - Night()); }

            float3 SunDir()
            {
                // 夕焼けでは、太陽が奥の地平線へ沈む
                return normalize(lerp(SUN_DAY, float3(0.25, 0.05, -1.0), saturate(Sunset() * 1.5 + Night())));
            }

            // ---------------------------------------------------------------- 山 (高さの式)

            float MountH(float2 xz)
            {
                float2 c = xz - TUNUPA.xz;
                float r = length(c);
                float ridge = 1.0 - abs(ValueNoise(float2(atan2(c.y, c.x) * 6.0, r * 20.0)) * 2.0 - 1.0);
                float cone = 0.17 * pow(saturate(1.0 - r / 0.42), 1.3) * (0.85 + 0.15 * ridge);
                // 奥に低くつらなる山並み
                float range = (0.035 + 0.025 * Fbm3(float2(xz.x * 6.0, 1.7))) * smoothstep(0.38, 0.47, -xz.y);
                return GROUND + max(cone, range);
            }

            float Mountains(float3 p)
            {
                // 山のない所 (手前・上) では、高さの式を計算しない
                if (p.z > -0.17) return p.z + 0.19;
                if (p.y > GROUND + 0.18) return p.y - GROUND - 0.17;
                float d = (p.y - MountH(p.xz)) * 0.55;
                return max(d, p.z + 0.19); // 山は奥 (z < -0.19) にしかない (そこで高さはほぼ 0 になる)
            }

            // ---------------------------------------------------------------- ランドクルーザー (長さ 4.9 m・幅 1.9 m・高さ 1.9 m)

            float Car(float3 p, out float part)
            {
                part = 0;
                float3 q = p - CAR;
                // 少し斜めに止まっている
                float a = 0.5;
                q = float3(cos(a) * q.x - sin(a) * q.z, q.y, sin(a) * q.x + cos(a) * q.z);
                if (length(q) > 0.045) return length(q) - 0.04;
                float body = SdRoundBox(q - float3(0, 0.0085, 0), float3(0.0245, 0.0045, 0.0095), 0.0015);
                float cabin = SdRoundBox(q - float3(-0.003, 0.0155, 0), float3(0.016, 0.0035, 0.009), 0.0012);
                float rack = SdBox(q - float3(-0.003, 0.0198, 0), float3(0.015, 0.0006, 0.0088));
                float bags = SdRoundBox(q - float3(-0.004, 0.0222, 0), float3(0.011, 0.0018, 0.0075), 0.0012); // 屋根の荷物
                float d = min(min(body, cabin), min(rack, bags));
                float3 w = float3(abs(q.x) - 0.0155, q.y - 0.004, abs(q.z) - 0.0085);
                float tire = max(length(w.xy) - 0.004, abs(w.z) - 0.0013);
                if (tire < d) part = 1;
                if (cabin < d && abs(q.y - 0.0155) < 0.0028 && max(abs(q.x + 0.003) - 0.0145, abs(q.z) - 0.0075) > -0.0015) part = 2; // 窓
                if (bags < min(d, tire)) part = 3;
                return min(d, tire);
            }

            // ---------------------------------------------------------------- 人 (身長 1.7 m)

            float3 PersonPos(int i)
            {
                float fi = i;
                return float3(-0.05 + 0.07 * cos(fi * 2.1) + fi * 0.02, WATER, 0.12 + 0.07 * sin(fi * 1.7));
            }

            float People(float3 p, out float which)
            {
                which = 0;
                if (p.y > WATER + 0.03) return p.y - WATER - 0.029;
                // 5 人がいる範囲の外なら、範囲までの距離だけ
                float group = max(max(-0.09 - p.x, p.x - 0.12), max(0.03 - p.z, p.z - 0.21));
                if (group > 0.002) return group;
                float d = 1e5;
                float t = _Time.y;
                [loop] for (int i = 0; i < PEOPLE; i++)
                {
                    float3 q = p - PersonPos(i);
                    // 1 人は、写真のためにジャンプしている
                    if (i == 2) q.y -= 0.004 * max(sin(t * 2.2), 0.0);
                    if (length(q - float3(0, 0.009, 0)) > 0.014) { d = min(d, length(q - float3(0, 0.009, 0)) - 0.012); continue; }
                    float fi = i;
                    float arm = (i == 0 || i == 2) ? 1.0 : 0.0; // 両手を上げている人
                    float s = (i % 2 == 0) ? 1.0 : 0.94;
                    q /= s;
                    float legs = min(SdCapsule(q, float3(0.0012, 0.0, 0), float3(0.001, 0.008, 0), 0.0008),
                                     SdCapsule(q, float3(-0.0012, 0.0, 0), float3(-0.001, 0.008, 0), 0.0008));
                    float torso = SdCapsule(q, float3(0, 0.0088, 0), float3(0, 0.0135, 0), 0.0021);
                    float head = length(q - float3(0, 0.0158, 0)) - 0.0012;
                    float3 hand = arm > 0.5 ? float3(0.0045, 0.0195, 0) : float3(0.0035, 0.008, 0.001);
                    float arms = min(SdCapsule(q, float3(0.0024, 0.0132, 0), hand, 0.0006),
                                     SdCapsule(q, float3(-0.0024, 0.0132, 0), hand * float3(-1, 1, 1), 0.0006));
                    float di = min(min(legs, torso), min(head, arms)) * s;
                    if (di < d) { d = di; which = fi; }
                }
                return d;
            }

            // ---------------------------------------------------------------- 世界の形 (水面より上の物。地面は平らな水面として、別に計算する)

            float2 Map(float3 p)
            {
                float2 res = float2(SdBox(p - float3(0, -0.46, 0), float3(0.5, 0.04, 0.5)), ID_BASE);
                float column = SdBox(p - float3(0, 0.04, 0), float3(INNER, 0.46, INNER));
                float m = max(Mountains(p), column);
                if (m < res.x) res = float2(m, ID_MOUNT);
                float part;
                float car = Car(p, part);
                if (car < res.x) res = float2(car, part > 0.5 && part < 1.5 ? ID_TIRE : ID_CAR);
                float which;
                float ppl = People(p, which);
                if (ppl < res.x) res = float2(ppl, ID_PERSON);
                return res;
            }

            float3 SceneNormal(float3 p)
            {
                const float2 e = float2(0.0001, -0.0001);
                float3 g = e.xyy * Map(p + e.xyy).x + e.yyx * Map(p + e.yyx).x + e.yxy * Map(p + e.yxy).x + e.xxx * Map(p + e.xxx).x;
                return g / max(length(g), 1e-12); // 1e-7 だと、なだらかな所で向きが短くなってしまう
            }

            // ---------------------------------------------------------------- 雲 (ガラスケースの中に浮かぶ積雲)

            #define CLOUD_LO -0.23
            #define CLOUD_HI 0.1
            static const float4 PUFF[6] = {
                float4(-0.22, -0.12, -0.1, 0.095), float4(0.17, -0.08, -0.19, 0.11), float4(-0.05, -0.05, 0.18, 0.08),
                float4(0.26, -0.13, 0.2, 0.07), float4(-0.27, -0.1, 0.24, 0.075), float4(0.0, -0.15, -0.28, 0.085)
            };

            // 雲の濃さ: もくもくの塊 (下は平ら、上はふくらむ) を、ノイズでちぎる
            float CloudDensity(float3 p)
            {
                float d = 0.0;
                [loop] for (int i = 0; i < 6; i++)
                {
                    float4 c = PUFF[i];
                    float3 q = (p - c.xyz) / c.w;
                    q.y = q.y > 0.0 ? q.y * 0.9 : q.y * 2.2; // 下は平ら
                    // 1 つの雲は、大小 3 つのふくらみ (カリフラワーのような形)
                    float r = length(q * float3(1.0, 1.0, 1.3));
                    r = min(r, length((q - float3(0.45, 0.25, 0.1)) * 1.5));
                    r = min(r, length((q - float3(-0.5, 0.1, -0.15)) * 1.7));
                    d = max(d, 1.0 - r);
                }
                if (d <= 0.0) return 0.0;
                float n = Noise3(p * 40.0 + float3(_Time.y * 0.02, 0, 0)) * 0.6 + Noise3(p * 95.0) * 0.4;
                return saturate(d * 2.4 - (1.0 - n) * 1.1);
            }

            // 雲を、線にそって 14 か所で調べ、色と、向こうが見える割合 (trans) を返す
            float3 Clouds(float3 ro, float3 rd, float tMax, float3 sunCol, float3 skyCol, int steps, out float trans)
            {
                trans = 1.0;
                float t0, t1;
                if (abs(rd.y) < 1e-4) { t0 = 0.0; t1 = tMax; }
                else
                {
                    float a = (CLOUD_LO - ro.y) / rd.y, b = (CLOUD_HI - ro.y) / rd.y;
                    t0 = max(min(a, b), 0.0);
                    t1 = min(max(a, b), tMax);
                }
                if (t1 <= t0) return 0;
                // 線が通る雲の塊の範囲だけを調べる (どの塊にも当たらない線は、すぐに終わる)
                float s0 = 1e5, s1 = -1e5;
                [loop] for (int i = 0; i < 6; i++)
                {
                    float4 c = PUFF[i];
                    float rad = c.w * 1.75;
                    float3 oc = ro - c.xyz;
                    float b = dot(oc, rd);
                    float h = b * b - (dot(oc, oc) - rad * rad);
                    if (h > 0.0)
                    {
                        h = sqrt(h);
                        s0 = min(s0, -b - h);
                        s1 = max(s1, -b + h);
                    }
                }
                t0 = max(t0, s0);
                t1 = min(t1, s1);
                if (t1 <= t0) return 0;
                float3 col = 0;
                float dt = (t1 - t0) / steps;
                float3 L = SunDir();
                [loop] for (int k = 0; k < 14; k++)
                {
                    if (k >= steps) break;
                    float3 pos = ro + rd * (t0 + dt * (k + 0.5));
                    if (max(abs(pos.x), abs(pos.z)) > INNER) continue;
                    float dens = CloudDensity(pos);
                    if (dens <= 0.001) continue;
                    // 光: 雲の上のほうほど明るい (塊の中心からの高さで決める。太陽の側を調べ直さない)
                    float shade = saturate(0.35 + (pos.y + 0.12) * 9.0 + dot(normalize(pos - float3(0, -0.15, 0)), L) * 0.2);
                    float3 lit = sunCol * (0.35 + 0.65 * shade) + skyCol * 0.5;
                    float a = 1.0 - exp(-dens * dt * 90.0);
                    col += trans * a * lit;
                    trans *= 1.0 - a;
                    if (trans < 0.02) break;
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

            float3 SunColor()
            {
                float3 day = float3(2.0, 1.9, 1.75);
                float3 dusk = float3(2.2, 0.95, 0.4);
                float3 night = float3(0.08, 0.1, 0.18);   // 月のない夜は、星あかりだけ
                return lerp(lerp(day, dusk, Sunset()), night, Night());
            }

            // 空: 昼は高原の濃い青 (標高 3700 m)、夕焼けは橙と桃色、夜は満天の星と天の川
            float3 Sky(float3 rd)
            {
                float3 L = SunDir();
                float up = saturate(rd.y);
                float night = Night(), sunset = Sunset();
                float3 day = lerp(float3(0.62, 0.78, 0.95), float3(0.12, 0.32, 0.78), pow(up, 0.45));
                float3 dusk = lerp(float3(1.0, 0.5, 0.25), float3(0.25, 0.22, 0.5), pow(up, 0.5));
                dusk = lerp(dusk, float3(0.95, 0.45, 0.55), exp(-up * 5.0) * 0.4 * (1.0 - saturate(dot(rd.xz, normalize(L.xz)))));
                float3 c = lerp(day, dusk, sunset);
                float sd = dot(rd, L);
                c += (1.0 - night) * (float3(4.0, 3.6, 3.0) * smoothstep(0.9993, 0.9997, sd) + lerp(float3(0.5, 0.45, 0.35), float3(1.0, 0.45, 0.15), sunset) * pow(saturate(sd), 14.0) * 0.6);
                if (night > 0.001)
                {
                    float3 nc = lerp(float3(0.03, 0.035, 0.07), float3(0.004, 0.006, 0.018), sqrt(up));
                    // 天の川: 空を横切る帯。暗い筋 (ちり) が混じる
                    float3 axis = normalize(float3(0.6, 0.3, 0.75));
                    float bd = dot(rd, axis) / 0.22;
                    float band = exp(-bd * bd);
                    float dust = smoothstep(0.5, 0.75, Noise3(rd * 30.0)) * exp(-bd * bd * 8.0);
                    nc += float3(0.05, 0.048, 0.06) * band * (0.5 + 0.8 * Noise3(rd * 12.0)) * (1.0 - 0.6 * dust);
                    // 星
                    float3 sp = rd * 260.0;
                    float3 cell = floor(sp);
                    float star = step(0.992 - band * 0.012, Hash31(cell)) * smoothstep(0.3, 0.05, length(frac(sp) - 0.5));
                    nc += star * lerp(float3(0.7, 0.8, 1.0), float3(1.0, 0.9, 0.7), Hash31(cell + 3.0)) * (0.6 + 1.4 * Hash31(cell + 7.0));
                    c = lerp(c, nc, night);
                }
                return c;
            }

            // 夜の明かり: 車のヘッドライトと、人が持つランタン
            float3 PointGlow(float3 ro, float3 rd, float tMax, float3 pos, float3 colr, float size)
            {
                float3 w = pos - ro;
                float tc = dot(w, rd);
                if (tc < 0.0 || tc > tMax + 0.002) return 0;
                float d2 = dot(w, w) - tc * tc;
                float core = max(size, tc * 0.0011);
                return colr * (exp(-d2 / (core * core)) + 0.05 * exp(-d2 / (core * core * 30.0)));
            }

            float3 Lights(float3 ro, float3 rd, float tMax)
            {
                float night = Night();
                if (night < 0.01) return 0;
                float3 col = 0;
                float a = 0.5;
                float3 fwd = float3(cos(a), 0, -sin(a));
                float3 side = float3(sin(a), 0, cos(a));
                float3 front = CAR + fwd * 0.025 + float3(0, 0.009, 0);
                col += PointGlow(ro, rd, tMax, front + side * 0.007, float3(2.0, 1.9, 1.6), 0.0012);
                col += PointGlow(ro, rd, tMax, front - side * 0.007, float3(2.0, 1.9, 1.6), 0.0012);
                col += PointGlow(ro, rd, tMax, PersonPos(1) + float3(0.0035, 0.009, 0.001), float3(2.0, 1.2, 0.5), 0.001);
                return col * night;
            }

            float3 Shade(float3 rd, float3 p, float id, float3 faceNormal)
            {
                float3 L = SunDir();
                float3 sunCol = SunColor();
                float night = Night();
                float3 skyTop = lerp(lerp(float3(0.3, 0.45, 0.75), float3(0.35, 0.28, 0.45), Sunset()), float3(0.02, 0.025, 0.05), night);
                float3 skyLow = lerp(lerp(float3(0.75, 0.78, 0.82), float3(0.9, 0.55, 0.4), Sunset()), float3(0.03, 0.03, 0.05), night);
                float3 v = -rd;

                if (id == ID_BASE)
                    return float3(0.015, 0.014, 0.014) + 0.03 * pow(saturate(1.0 - abs(dot(rd, faceNormal))), 4.0);

                float3 n = SceneNormal(p);
                if (id == ID_MOUNT)
                {
                    if (max(abs(p.x), abs(p.z)) > INNER - 0.0015 && abs(n.y) < 0.5)
                        return Surface(float3(0.5, 0.42, 0.36), n, v, L, sunCol, 1.0, 1.0, 0.9, 0.03, 0.0, skyTop, skyLow) * 0.8; // 切り口
                    // トゥヌパ火山: 赤・黄土・灰色の地層の縞
                    float band = frac((p.y - GROUND) * 45.0 + Noise3(p * 25.0) * 0.8);
                    float3 rock = lerp(float3(0.6, 0.32, 0.22), float3(0.78, 0.6, 0.38), smoothstep(0.3, 0.6, band));
                    rock = lerp(rock, float3(0.55, 0.52, 0.5), smoothstep(0.75, 0.9, band));
                    return Surface(rock * (0.8 + 0.3 * Noise3(p * 200.0)), n, v, L, sunCol, 1.0, 1.0, 0.9, 0.03, 0.0, skyTop, skyLow);
                }
                if (id == ID_CAR)
                {
                    float part;
                    Car(p, part);
                    if (part > 2.5) return Surface(float3(0.25, 0.3, 0.5), n, v, L, sunCol, 1.0, 1.0, 0.8, 0.04, 0.0, skyTop, skyLow); // 青いシートの荷物
                    if (part > 1.5)
                    {
                        // 窓: 空を映す黒いガラス
                        float3 r = reflect(rd, n);
                        return float3(0.02, 0.02, 0.025) + Sky(r) * (0.1 + 0.6 * pow(1.0 - saturate(dot(v, n)), 3.0));
                    }
                    return Surface(float3(0.86, 0.87, 0.88), n, v, L, sunCol, 1.0, 1.0, 0.25, 0.3, 0.0, skyTop, skyLow); // 白いボディ (つや)
                }
                if (id == ID_TIRE) return Surface(float3(0.04, 0.04, 0.045), n, v, L, sunCol, 1.0, 1.0, 0.7, 0.04, 0.0, skyTop, skyLow);
                // 人: それぞれの服の色。顔と手は肌の色
                float which;
                People(p, which);
                float3 q = p - PersonPos((int)which);
                float3 shirt = which < 0.5 ? float3(0.85, 0.15, 0.1) : (which < 1.5 ? float3(0.95, 0.75, 0.1) : (which < 2.5 ? float3(0.1, 0.45, 0.85) : (which < 3.5 ? float3(0.2, 0.6, 0.3) : float3(0.9, 0.4, 0.6))));
                float y = q.y / 0.017;
                float3 alb = y > 0.88 ? float3(0.75, 0.55, 0.42) : (y > 0.5 ? shirt : float3(0.12, 0.13, 0.2));
                return Surface(alb, n, v, L, sunCol, 1.0, 1.0, 0.8, 0.04, 0.2, skyTop, skyLow);
            }

            // 水面より上の物と雲を、線にそってたどって色を出す (鏡に映る景色にも使う)
            float3 TraceAbove(float3 ro, float3 rd, float tStart, float tMax, bool inside, int maxSteps, int cloudSteps, out bool hitAny, out float tHit, out float cloudTrans)
            {
                float t = tStart;
                hitAny = false;
                float id = 0;
                [loop] for (int i = 0; i < 90; i++)
                {
                    if (t > tMax || i >= maxSteps) break;
                    float3 pos = ro + rd * t;
                    if (rd.y > 0.0 && pos.y > CLOUD_HI) break;
                    float2 m = Map(pos);
                    if (m.x < 0.00003 + 0.0003 * t) { hitAny = true; id = m.y; break; }
                    t += m.x;
                }
                tHit = hitAny ? t : tMax;
                float3 col = hitAny ? Shade(rd, ro + rd * t, id, float3(0, 1, 0)) : (inside ? Sky(rd) : 0);
                float trans;
                float3 cl = Clouds(ro, rd, tHit, SunColor(), lerp(float3(0.5, 0.6, 0.8), float3(0.02, 0.025, 0.05), Night()), cloudSteps, trans);
                col = col * trans + cl;
                cloudTrans = trans;
                col += Lights(ro, rd, tHit);
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
                float t0 = max(box.x, 0.0);

                float3 entry = ro + rd * t0;
                float3 ae = abs(entry);
                float3 faceNormal = ae.x > ae.y && ae.x > ae.z ? float3(sign(entry.x), 0, 0)
                                  : (ae.y > ae.z ? float3(0, sign(entry.y), 0) : float3(0, 0, sign(entry.z)));

                // 水面 (鏡) までの距離。箱の内側 (INNER) だけが水面
                float tW = rd.y < 0.0 ? (WATER - ro.y) / rd.y : 1e5;
                float3 wp = ro + rd * tW;
                bool onWater = tW > t0 && tW < box.y && max(abs(wp.x), abs(wp.z)) < INNER && ro.y > WATER;
                float tEnd = onWater ? tW : box.y;

                bool hitAny;
                float tHit, trans;
                float3 col = TraceAbove(ro, rd, t0, tEnd, !outside, 90, 14, hitAny, tHit, trans);
                float alpha = (hitAny || !outside) ? 1.0 : 0.0;
                alpha = alpha + (1.0 - alpha) * (1.0 - trans); // 雲の不透明さ (もう一度計算しない)

                if (!hitAny && onWater)
                {
                    // 鏡: 水面ではね返った線で、上の景色 (物・雲・空) をもう一度たどる
                    float3 n = float3(0, 1, 0);
                    // 人の足元から広がる、小さな波の輪
                    [loop] for (int k = 0; k < PEOPLE; k++)
                    {
                        float2 d = wp.xz - PersonPos(k).xz;
                        float r = length(d);
                        if (r < 0.04)
                        {
                            float w = sin(r * 900.0 - _Time.y * 6.0) * exp(-r * 90.0) * 0.08;
                            n = float3(n.x + d.x / max(r, 1e-4) * w, n.y, n.z + d.y / max(r, 1e-4) * w);
                        }
                    }
                    n = normalize(n);
                    float3 rr = reflect(rd, n);
                    float2 rbox = BoxHit(wp, rr, float3(0.5, 0.5, 0.5));
                    bool rh;
                    float rt, rtrans;
                    // 映り込みは、少ない歩数と、粗い雲で十分 (さざ波でゆれるので、細かさは見分けにくい)
                    float3 refl = TraceAbove(wp + rr * 0.0003, rr, 0.0, rbox.y, true, 48, 8, rh, rt, rtrans);
                    // 水の下の塩: 白く、六角形の模様のふちが少し盛り上がる (真上から見ると透けて見える)
                    float2 g = wp.xz * 70.0;
                    float2 hx = float2(g.x + g.y * 0.5, g.y * 0.866);
                    float2 cell = frac(hx) - 0.5;
                    float2 cell2 = frac(hx + float2(0.5, 0.0)) - 0.5;
                    float edge = smoothstep(0.38, 0.47, max(abs(cell.x) + abs(cell.y) * 0.5, abs(cell.y)));
                    float3 salt = lerp(float3(0.85, 0.85, 0.83), float3(0.7, 0.7, 0.7), edge * 0.6);
                    float3 L = SunDir();
                    float3 under = salt * (SunColor() * saturate(L.y) * 0.6 + lerp(float3(0.5, 0.55, 0.65), float3(0.02, 0.025, 0.05), Night()));
                    float fres = 0.35 + 0.65 * pow(1.0 - saturate(-rd.y), 3.0);
                    col = lerp(under, refl, fres);
                    alpha = 1.0;
                }

                // 中に入ったとき、足元より下 (水面がない所) は台の色
                if (!hitAny && !onWater && !outside && rd.y < 0.0) col = Sky(float3(rd.x, -rd.y, rd.z)); // 鏡の続き (地平線にすきまができないように)

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
