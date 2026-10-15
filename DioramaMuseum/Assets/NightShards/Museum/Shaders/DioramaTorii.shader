// 作品「千本鳥居の山」(夕の間)。霧の杉山を、朱の鳥居のトンネルがらせんに巻いて山頂の社まで登る。URP 用。
// Cube の中をレイマーチングして描く。Cube の座標は -0.5〜0.5、下の 0.08 は黒い台。
//
// 見どころ:
//   ・杉の森におおわれた円すいの山。そのまわりを、石の参道が 2 周と少し、らせんに巻いて登る
//   ・参道には朱の鳥居が約 600 基、すき間なく並んでトンネルになる (黒い笠木、柱の根元も黒)。12 基ごとに石灯籠
//   ・山頂には朱の社。山の中腹には、霧の帯がかかる
// 仕掛け (_Event 0〜1): 霧が晴れて、夕日が強く差し、灯籠に火がともる。鳥居のトンネルが金色に輝く
//
// 外から見たとき、地形のない所 (空) は透明にして、ガラスケースの向こうの部屋が見えるようにする。
// 中に入ったとき (カメラが箱の中) だけ、夕焼けの空を描く
//
// _Steps / _ShadowSteps は DioramaLOD が距離で下げる。_Event / _EventTime は DioramaWork が渡す。
// _HeightTex は DioramaWork が再生の最初に作る、地形の高さの表 (なければ式で計算する)
Shader "NightShards/Diorama/Torii"
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
            Blend One OneMinusSrcAlpha // 空の所は透明 (色はあらかじめ不透明度を掛けて出す)

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma multi_compile_instancing

            #define ID_BASE   0.0
            #define ID_GROUND 1.0
            #define ID_TREE   2.0
            #define ID_TORII  3.0
            #define ID_SHRINE 4.0

            #define INNER 0.47
            #define R0 0.37            // 参道のらせんの、ふもとの半径
            #define R1 0.045           // 参道のらせんの、山頂の半径
            #define TURNS 2.25         // らせんの巻き数
            #define TH0 1.5707963      // 参道の入口の向き (手前 +z)
            #define TWO_PI 6.2831853
            #define SP 0.0055          // 鳥居の間隔
            #define TREE_CELL 0.04
            static const float TOTAL = TURNS * TWO_PI;
            static const float3 SUN_DIR = float3(-0.6, 0.28, -0.75); // 奥の左から差す夕日。正規化は使う所で

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

            // ---------------------------------------------------------------- 山と参道
            // ※ MountainBase・PathCoord・Height を変えたら、C# の DioramaTerrain も同じに直す (中を歩くときの地面になる)

            // 山の大まかな高さ (中心からの距離だけで決まる、円すいに近い形)
            float MountainBase(float r) { return -0.26 + 0.5 * pow(saturate(1.0 - r / 0.48), 1.6); }

            // 参道のらせんの上で、xz にいちばん近い所。x = 進み具合 s (0 入口 〜 1 山頂)、y = 参道の中心線からの横のずれ
            float2 PathCoord(float2 xz)
            {
                float r = length(xz);
                float th = atan2(xz.y, xz.x);
                float sr = (R0 - r) / (R0 - R1);                    // 半径から見た、だいたいの進み具合
                float m = round((sr * TOTAL - (th - TH0)) / TWO_PI); // 何周目か
                float sRaw = (th - TH0 + TWO_PI * m) / TOTAL;
                float s = clamp(sRaw, 0.0, 1.0);
                float across = r - lerp(R0, R1, s);
                if (sRaw < -0.002 || sRaw > 1.002) across = 1.0; // らせんの入口より前・山頂より先は、参道ではない
                return float2(s, across);
            }

            float PathY(float s) { return MountainBase(lerp(R0, R1, s)); }

            // 入口から s までの、参道の長さ
            float PathArc(float s) { return TOTAL * (R0 * s - 0.5 * (R0 - R1) * s * s); }

            float Height(float2 xz)
            {
                float r = length(xz);
                float th = atan2(xz.y, xz.x);
                float h = MountainBase(r) + 0.035 * (Fbm3(xz * 5.0 + _Seed) - 0.45);
                h += 0.008 * sin(th * 9.0 + Fbm3(xz * 7.0) * 4.0) * smoothstep(0.05, 0.2, r); // 雨が刻んだ、縦の筋
                // 参道: らせんに沿って、山の斜面を平らに切った道
                float2 pc = PathCoord(xz);
                float onPath = smoothstep(0.016, 0.009, abs(pc.y));
                h = lerp(h, PathY(pc.x) - 0.001, onPath);
                // 山頂: 社を建てる平らな所
                h = lerp(h, PathY(1.0) + 0.002, smoothstep(0.05, 0.035, r));
                return h;
            }

            float HeightFast(float2 xz)
            {
                [branch] if (_HeightTexOn > 0.5)
                    return SAMPLE_TEXTURE2D_LOD(_HeightTex, sampler_linear_clamp, xz / (2.0 * INNER) + 0.5, 0).r;
                return Height(xz);
            }

            // ---------------------------------------------------------------- 鳥居と灯籠

            // 鳥居 1 基の形。q.x = 道を横切る向き、q.y = 道からの高さ、q.z = 道に沿う向き
            float ToriiGate(float3 q)
            {
                float pillar = max(length(float2(abs(q.x) - 0.0062, q.z)) - 0.0008, max(-q.y, q.y - 0.0172));
                float yk = 0.0178 + 0.0012 * (q.x / 0.0098) * (q.x / 0.0098);      // 笠木: 両端が反り上がる
                float kasagi = SdBox(float3(q.x, q.y - yk, q.z), float3(0.0098, 0.0007, 0.0011));
                float shimaki = SdBox(q - float3(0, 0.0165, 0), float3(0.0088, 0.0004, 0.0009));
                float nuki = SdBox(q - float3(0, 0.0135, 0), float3(0.0078, 0.00045, 0.0006));
                return min(min(pillar, kasagi), min(shimaki, nuki));
            }

            // 石灯籠: 台・火袋・笠
            float Lantern(float3 q)
            {
                float post = SdBox(q - float3(0, 0.003, 0), float3(0.0009, 0.003, 0.0009));
                float box = SdBox(q - float3(0, 0.0072, 0), float3(0.0016, 0.0012, 0.0016));
                float cap = SdBox(q - float3(0, 0.0091, 0), float3(0.0024, 0.0006, 0.0024));
                return min(post, min(box, cap));
            }

            // 参道の鳥居と灯籠 (距離)。いちばん近い鳥居 1 基だけを調べる。lanternLight は灯籠の火袋の中か
            float ToriiRow(float3 p, out float3 local, out float isLantern)
            {
                local = 0;
                isLantern = 0;
                float2 pc = PathCoord(p.xz);
                float across = abs(pc.y);
                if (across > 0.02) return min((across - 0.018) * 0.8, 0.02); // 参道から遠い所では、参道までのだいたいの距離 (大きすぎないように)
                float y = p.y - PathY(pc.x);
                if (y > 0.026) return y - 0.024;
                if (pc.x < 0.012 || pc.x > 0.93) return 0.006;   // 入口の手前と山頂の近くには、鳥居を置かない
                float A = PathArc(pc.x);
                float i = round(A / SP);
                float3 q = float3(pc.y, y, A - i * SP);
                local = q;
                float d = ToriiGate(q);
                if (fmod(i, 12.0) < 0.5)
                {
                    float dl = Lantern(q - float3(0.0128, 0, 0));
                    if (dl < d)
                    {
                        d = dl;
                        isLantern = 1;
                    }
                }
                return d;
            }

            // 山頂の社: 朱の壁と、黒い切妻の屋根
            float Shrine(float3 p)
            {
                float3 q = p - float3(0, PathY(1.0) + 0.002, 0);
                float body = SdBox(q - float3(0, 0.008, 0), float3(0.012, 0.008, 0.009));
                float3 r = q - float3(0, 0.0165, 0);
                float roof = max(max(abs(r.x) - 0.016, abs(r.z) * 0.7 + r.y * 0.72 - 0.0105), -r.y);
                return min(body, roof);
            }

            // ---------------------------------------------------------------- 杉

            float Cedars(float3 p, float groundH)
            {
                if (p.y - groundH > 0.095) return p.y - groundH - 0.085;
                float2 cell = floor(p.xz / TREE_CELL);
                float2 local = p.xz - (cell + 0.5) * TREE_CELL;
                float2 toEdge = 0.5 * TREE_CELL - abs(local);
                float bound = max(min(toEdge.x, toEdge.y), 0.0) + 0.003;
                float2 id = cell + _Seed * 0.37;
                if (Hash21(id) > 0.65) return bound;
                float2 base = (cell + 0.5) * TREE_CELL + (Hash22(id + 1.3) - 0.5) * TREE_CELL * 0.5;
                if (abs(base.x) > INNER - 0.02 || abs(base.y) > INNER - 0.02) return bound;
                if (abs(PathCoord(base).y) < 0.026 || length(base) < 0.06) return bound; // 参道と山頂には生えない
                float height = 0.05 + 0.035 * Hash21(id + 3.3);
                float3 q = p - float3(base.x, HeightFast(base) - 0.003, base.y);
                float k = saturate(q.y / height);
                float rad = height * 0.17 * (1.0 - k) * (0.8 + 0.2 * sin(k * 30.0)) + 0.0007;
                float d = max(length(q.xz) - rad, max(-q.y, q.y - height)) * 0.6;
                return min(d, bound);
            }

            // ---------------------------------------------------------------- 世界の形

            float2 MapX(float3 p, bool exact)
            {
                float2 res = float2(SdBox(p - float3(0, -0.46, 0), float3(0.5, 0.04, 0.5)), ID_BASE);
                float column = SdBox(p - float3(0, 0.04, 0), float3(INNER, 0.46, INNER));
                float h;
                if (exact) h = Height(p.xz);
                else h = HeightFast(p.xz);
                float ground = max((p.y - h) * 0.4, column);
                if (ground < res.x) res = float2(ground, ID_GROUND);
                float tree = max(Cedars(p, h), column);
                if (tree < res.x) res = float2(tree, ID_TREE);
                float3 local;
                float lantern;
                float torii = ToriiRow(p, local, lantern);
                if (torii < res.x) res = float2(torii, ID_TORII);
                float shrine = Shrine(p);
                if (shrine < res.x) res = float2(shrine, ID_SHRINE);
                return res;
            }

            float2 Map(float3 p) { return MapX(p, false); }

            float3 SceneNormal(float3 p)
            {
                const float2 e = float2(0.0004, -0.0004);
                float3 g = e.xyy * MapX(p + e.xyy, true).x + e.yyx * MapX(p + e.yyx, true).x +
                           e.yxy * MapX(p + e.yxy, true).x + e.xxx * MapX(p + e.xxx, true).x;
                return g / max(length(g), 1e-7);
            }

            float SoftShadow(float3 p, float3 l)
            {
                float res = 1.0;
                float t = 0.003;
                int n = (int)_ShadowSteps;
                for (int i = 0; i < 32; i++)
                {
                    if (i >= n) break;
                    float h = Map(p + l * t).x;
                    res = min(res, 12.0 * h / t);
                    t += clamp(h, 0.002, 0.04);
                    if (res < 0.01 || t > 0.8) break;
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
                return saturate(1.0 - occ * 18.0);
            }

            // ---------------------------------------------------------------- 霧

            float MistDensity(float3 p)
            {
                float t = _Time.y;
                float a = (p.y + 0.12) / 0.035;
                float b = (p.y - 0.02) / 0.03;
                float band = exp(-a * a) + 0.7 * exp(-b * b);
                if (band < 0.01) return 0.0;
                float n = Noise3(float3(p.x * 9.0 + t * 0.02, p.y * 14.0, p.z * 9.0)) * 0.6 + Noise3(p * 22.0 + t * 0.01) * 0.4;
                return max(0.0, band * 1.3 + n - 1.2) * 30.0 * (1.0 - 0.9 * smoothstep(0.0, 1.0, _Event));
            }

            float4 Mist(float3 ro, float3 rd, float tMax, float3 sunCol)
            {
                float3 bmin = float3(-INNER, -0.26, -INNER);
                float3 bmax = float3(INNER, 0.14, INNER);
                float3 inv = 1.0 / rd;
                float3 t0 = (bmin - ro) * inv, t1 = (bmax - ro) * inv;
                float3 tsmall = min(t0, t1), tbig = max(t0, t1);
                float tin = max(max(max(tsmall.x, tsmall.y), tsmall.z), 0.0);
                float tout = min(min(min(tbig.x, tbig.y), tbig.z), tMax);
                if (tout <= tin) return float4(0, 0, 0, 1);
                int steps = clamp((int)(_Steps / 6.0), 8, 22);
                float dt = (tout - tin) / steps;
                float t = tin + dt * Hash21(rd.xy * 517.0 + _Time.y);
                float3 col = 0;
                float trans = 1.0;
                for (int i = 0; i < 22; i++)
                {
                    if (i >= steps) break;
                    float3 p = ro + rd * t;
                    float dens = MistDensity(p);
                    if (dens > 0.0)
                    {
                        float a = 1.0 - exp(-dens * dt);
                        col += trans * a * (float3(0.55, 0.45, 0.45) + sunCol * 0.2);
                        trans *= 1.0 - a;
                        if (trans < 0.02) break;
                    }
                    t += dt;
                }
                return float4(col, trans);
            }

            // ---------------------------------------------------------------- 空 (中に入ったとき)

            float3 Sky(float3 rd)
            {
                float up = saturate(rd.y);
                float3 sunDir = normalize(SUN_DIR);
                float sd = saturate(dot(rd, sunDir));
                float3 c = lerp(float3(1.2, 0.55, 0.3), float3(0.35, 0.25, 0.45), pow(up, 0.5));
                c = lerp(c, float3(0.1, 0.12, 0.28), smoothstep(0.35, 0.95, up));
                c += float3(1.5, 0.75, 0.35) * pow(sd, 10.0) + float3(3.0, 2.0, 1.2) * smoothstep(0.9993, 0.9997, dot(rd, sunDir));
                return c;
            }

            // ---------------------------------------------------------------- 色を塗る

            float3 Shade(float3 ro, float3 rd, float3 p, float id, float3 faceNormal)
            {
                float e = smoothstep(0.0, 1.0, _Event);
                float3 sunDir = normalize(SUN_DIR);
                float3 sunCol = lerp(float3(1.1, 0.62, 0.38), float3(2.1, 1.1, 0.5), e); // 霧が晴れると、夕日が強く差す
                float3 amb = float3(0.22, 0.17, 0.24);

                if (id == ID_BASE)
                    return float3(0.015, 0.014, 0.014) + 0.03 * pow(saturate(1.0 - abs(dot(rd, faceNormal))), 4.0);

                float3 n = SceneNormal(p);
                float sh = SoftShadow(p + n * 0.0015, sunDir);
                float ao = AmbientOcclusion(p, n);
                float diffuse = saturate(dot(n, sunDir)) * sh;
                float3 lit = sunCol * diffuse + amb * (0.5 + 0.5 * saturate(n.y));
                float3 h = normalize(sunDir - rd);
                float spec = pow(saturate(dot(n, h)), 50.0) * sh;

                if (id == ID_TORII)
                {
                    float3 local;
                    float isLantern;
                    ToriiRow(p, local, isLantern);
                    if (isLantern > 0.5)
                    {
                        // 石灯籠: 灰色の石。火袋は、仕掛けで火がともる
                        float3 q = local - float3(0.0128, 0, 0);
                        float fire = step(abs(q.y - 0.0072), 0.0011) * step(max(abs(q.x), abs(q.z)), 0.00155);
                        float3 stone = float3(0.45, 0.43, 0.4) * (0.85 + 0.2 * Noise3(p * 1500.0));
                        float flicker = 0.85 + 0.15 * sin(_Time.y * 9.0 + p.x * 900.0);
                        return stone * lit * ao + float3(2.4, 1.2, 0.4) * fire * e * flicker;
                    }
                    // 鳥居: 朱塗り (つやがある)。笠木と柱の根元は黒
                    float black = step(0.0171, local.y) + step(local.y, 0.0018);
                    float3 albedo = lerp(float3(0.82, 0.16, 0.05), float3(0.03, 0.025, 0.025), saturate(black));
                    return albedo * lit * ao + spec * sunCol * 0.35;
                }

                if (id == ID_SHRINE)
                {
                    float roof = step(PathY(1.0) + 0.002 + 0.0165, p.y);
                    float3 albedo = lerp(float3(0.8, 0.18, 0.06), float3(0.08, 0.07, 0.07), roof);
                    return albedo * lit * ao + spec * sunCol * 0.25;
                }

                if (id == ID_TREE)
                {
                    float3 albedo = float3(0.05, 0.1, 0.05) * (0.8 + 0.4 * Noise3(p * 600.0));
                    return albedo * lit * ao;
                }

                // 地面: 参道は石段 (段の線が入る)、それ以外は杉の落ち葉とこけ
                float2 pc = PathCoord(p.xz);
                float onPath = smoothstep(0.012, 0.008, abs(pc.y)) + smoothstep(0.05, 0.035, length(p.xz));
                float stepLine = smoothstep(0.08, 0.0, frac(PathArc(pc.x) / 0.003));
                float3 stone = float3(0.42, 0.4, 0.36) * (0.85 + 0.2 * Noise3(p * 900.0)) * (1.0 - 0.35 * stepLine);
                float3 floorCol = lerp(float3(0.18, 0.13, 0.08), float3(0.12, 0.2, 0.08), Noise3(p * 300.0));
                float3 albedo = lerp(floorCol, stone, saturate(onPath));
                return albedo * lit * ao;
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

                const float maxHeight = 0.3;
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
                    if (m.x < 0.0002 * (1.0 + t))
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

                float e = smoothstep(0.0, 1.0, _Event);
                float3 sunCol = lerp(float3(1.1, 0.62, 0.38), float3(2.1, 1.1, 0.5), e);

                float3 col = 0;
                if (hit) col = Shade(ro, rd, ro + rd * t, id, faceNormal);
                else if (!outside) col = Sky(rd);

                float travel = tHit - max(box.x, 0.0);
                if (hit) col = lerp(col, float3(0.55, 0.35, 0.3), (1.0 - exp(-travel * 0.6)) * 0.55 * (1.0 - 0.5 * e));

                float alpha = (hit || !outside) ? 1.0 : 0.0;
                float4 mist = Mist(ro, rd, tHit, sunCol);
                col = col * mist.a + mist.rgb;
                alpha = 1.0 - (1.0 - alpha) * mist.a;

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
