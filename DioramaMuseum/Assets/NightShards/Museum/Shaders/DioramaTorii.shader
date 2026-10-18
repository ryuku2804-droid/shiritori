// 作品「千本鳥居の山」(夕の間)。霧の杉山を、朱の鳥居のトンネルがらせんに巻いて山頂の社まで登る。URP 用。
// Cube の中をレイマーチングして描く。Cube の座標は -0.5〜0.5、下の 0.08 は黒い台。
//
// 見どころ:
//   ・杉の森におおわれた円すいの山。そのまわりを、石の参道が 2 周と少し、らせんに巻いて登る
//   ・参道には朱の鳥居が約 600 基、すき間なく並んでトンネルになる (黒い笠木、柱の根元も黒)。12 基ごとに石灯籠
//   ・山頂には朱の社。山の中腹には、霧の帯がかかる
//   ・くっきりした影: 鳥居のすき間から差す夕日が、石段に光と影の縞を作る
//   ・材質ごとのつや (朱塗りはつやつやで空を映し、石は少し、杉の葉は逆光で透ける)
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

        // Quest で 1 にする (QuestQuality が Shader.SetGlobalFloat で入れる)。1 のとき、影と陰の計算を省く。

        // マテリアルごとの値の箱 (UnityPerMaterial) の外に置くので、全部のジオラマに一度に効く

        float _DioramaLite;

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
            #pragma use_dxc vulkan // Quest (Vulkan) 用は新しいコンパイラー (DXC) で変換する。古いほうだと大きいシェーダーが時間切れになる
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
            // pc は p の真下の参道の位置 (PathCoord)。呼ぶ側で 1 回だけ計算して渡す (計算を使い回して軽くする)
            float ToriiRow(float3 p, float2 pc, out float3 local, out float isLantern)
            {
                local = 0;
                isLantern = 0;
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

            float Cedars(float3 p, float groundH, float2 pc)
            {
                if (p.y - groundH > 0.095) return p.y - groundH - 0.085;
                float2 cell = floor(p.xz / TREE_CELL);
                float2 local = p.xz - (cell + 0.5) * TREE_CELL;
                float2 toEdge = 0.5 * TREE_CELL - abs(local);
                float bound = max(min(toEdge.x, toEdge.y), 0.0) + 0.003;
                float2 id = cell + _Seed * 0.37;
                if (Hash21(id) > 0.65) return bound;
                float2 base = (cell + 0.5) * TREE_CELL + (Hash22b(id + 1.3) - 0.5) * TREE_CELL * 0.5;
                if (abs(base.x) > INNER - 0.02 || abs(base.y) > INNER - 0.02) return bound;
                // 参道と山頂には生えない。木の根元の参道からのずれは、p の参道の位置から近似して求める (らせんの計算をやり直さない)
                float acrossBase = pc.y > 0.9 ? 1.0 : pc.y + dot(base - p.xz, p.xz / max(length(p.xz), 1e-4));
                if (abs(acrossBase) < 0.026 || length(base) < 0.06) return bound;
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
                float2 pc = PathCoord(p.xz); // 参道の位置は、ここで 1 回だけ計算して使い回す
                float tree = max(Cedars(p, h, pc), column);
                if (tree < res.x) res = float2(tree, ID_TREE);
                float3 local;
                float lantern;
                float torii = ToriiRow(p, pc, local, lantern);
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
                if (_DioramaLite > 0.5) return 1.0; // Quest では省く
                float res = 1.0;
                float t = 0.0015;
                int n = max((int)_ShadowSteps, 8);
                // 近く (鳥居の柱の影の縞が落ちる範囲) だけ、鳥居も木も入れて細かく調べる
                [loop] for (int i = 0; i < 24; i++)
                {
                    if (i >= n || t > 0.05) break;
                    float h = Map(p + l * t).x;
                    res = min(res, 32.0 * h / t); // くっきりした影 (鳥居の細い柱の影も、はっきり落ちる)
                    t += clamp(h, 0.0012, 0.02);
                    if (res < 0.01) return 0.0;
                }
                // 遠くは、山の高さの表だけで、山の陰に入るかを大まかに調べる (軽い)
                [loop] for (int j = 0; j < 10; j++)
                {
                    float3 q = p + l * t;
                    if (abs(q.x) > INNER || abs(q.z) > INNER || q.y > 0.3) break;
                    float d = q.y - HeightFast(q.xz);
                    res = min(res, 8.0 * d / t);
                    if (res < 0.01) return 0.0;
                    t += 0.04;
                }
                return saturate(res);
            }

            float AmbientOcclusion(float3 p, float3 n)
            {
                if (_DioramaLite > 0.5) return 1.0; // Quest では省く
                float occ = 0.0;
                float w = 1.0;
                [loop] for (int i = 1; i <= 4; i++)
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
                int steps = clamp((int)(_Steps / 11.0), 6, 12); // 霧は細かく調べなくても見た目が変わらないので、少なめに
                float dt = (tout - tin) / steps;
                float t = tin + dt * Hash21(rd.xy * 517.0 + _Time.y);
                // 夕日のほうを向くほど、霧が明るく輝く (光が前へ散らばる)
                float phase = 0.3 + 2.2 * pow(saturate(dot(rd, normalize(SUN_DIR))), 8.0);
                float3 col = 0;
                float trans = 1.0;
                [loop] for (int i = 0; i < 22; i++)
                {
                    if (i >= steps) break;
                    float3 p = ro + rd * t;
                    float dens = MistDensity(p);
                    if (dens > 0.0)
                    {
                        float a = 1.0 - exp(-dens * dt);
                        col += trans * a * (float3(0.5, 0.42, 0.44) + sunCol * 0.25 * phase);
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

            float3 Shade(float3 ro, float3 rd, float3 p, float id, float3 faceNormal)
            {
                float e = smoothstep(0.0, 1.0, _Event);
                float3 L = normalize(SUN_DIR);
                float3 sunCol = lerp(float3(1.1, 0.62, 0.38), float3(2.1, 1.1, 0.5), e); // 霧が晴れると、夕日が強く差す
                float3 skyTop = float3(0.22, 0.2, 0.36);
                float3 skyLow = float3(0.7, 0.42, 0.3);
                float3 v = -rd;

                if (id == ID_BASE)
                    return float3(0.015, 0.014, 0.014) + 0.03 * pow(saturate(1.0 - abs(dot(rd, faceNormal))), 4.0);

                float3 n = SceneNormal(p);
                float sh = SoftShadow(p + n * 0.001, L);
                float ao = AmbientOcclusion(p, n);

                if (id == ID_TORII)
                {
                    float3 local;
                    float isLantern;
                    ToriiRow(p, PathCoord(p.xz), local, isLantern);
                    if (isLantern > 0.5)
                    {
                        // 石灯籠: ざらっとした灰色の石。火袋は、仕掛けで火がともる
                        float3 q = local - float3(0.0128, 0, 0);
                        float fire = step(abs(q.y - 0.0072), 0.0011) * step(max(abs(q.x), abs(q.z)), 0.00155);
                        float3 stone = float3(0.45, 0.43, 0.4) * (0.85 + 0.2 * Noise3(p * 1500.0));
                        float3 nb = BumpNormal(n, p, 2000.0, 0.8);
                        float flicker = 0.85 + 0.15 * sin(_Time.y * 9.0 + p.x * 900.0);
                        return Surface(stone, nb, v, L, sunCol, sh, ao, 0.75, 0.03, 0.0, skyTop, skyLow) + float3(2.4, 1.2, 0.4) * fire * e * flicker;
                    }
                    // 鳥居: つやのある朱塗り (空と夕日がつやに映る)。笠木と柱の根元は黒塗り。ところどころ塗りが古びる
                    float black = saturate(step(0.0171, local.y) + step(local.y, 0.0018));
                    float wear = smoothstep(0.6, 0.8, Noise3(p * 3000.0)) * 0.3;
                    float3 albedo = lerp(float3(0.82, 0.16, 0.05), float3(0.03, 0.025, 0.025), black);
                    albedo = lerp(albedo, albedo * 0.6 + float3(0.05, 0.03, 0.02), wear);
                    return Surface(albedo, n, v, L, sunCol, sh, ao, lerp(0.25, 0.6, wear), 0.05, 0.0, skyTop, skyLow);
                }

                if (id == ID_SHRINE)
                {
                    float roof = step(PathY(1.0) + 0.002 + 0.0165, p.y);
                    float3 albedo = lerp(float3(0.8, 0.18, 0.06), float3(0.08, 0.07, 0.07), roof);
                    return Surface(albedo, n, v, L, sunCol, sh, ao, lerp(0.3, 0.5, roof), 0.05, 0.0, skyTop, skyLow);
                }

                if (id == ID_TREE)
                {
                    float3 nb = BumpNormal(n, p, 700.0, 0.8);
                    float3 albedo = float3(0.05, 0.1, 0.05) * (0.8 + 0.4 * Noise3(p * 600.0));
                    return Surface(albedo, nb, v, L, sunCol, sh, ao, 0.75, 0.03, 0.6, skyTop, skyLow);
                }

                // 地面: 参道は石段 (段の線、すり減った所はつるつる、苔)。それ以外は杉の落ち葉とこけ
                float2 pc = PathCoord(p.xz);
                float onPath = saturate(smoothstep(0.012, 0.008, abs(pc.y)) + smoothstep(0.05, 0.035, length(p.xz)));
                float stepLine = smoothstep(0.08, 0.0, frac(PathArc(pc.x) / 0.003));
                float worn = smoothstep(0.006, 0.0, abs(pc.y)); // 人が歩く真ん中は、すり減ってなめらか
                float moss = smoothstep(0.55, 0.75, Noise3(p * 400.0)) * (1.0 - worn);
                float3 stone = float3(0.42, 0.4, 0.36) * (0.85 + 0.2 * Noise3(p * 900.0)) * (1.0 - 0.35 * stepLine);
                stone = lerp(stone, float3(0.18, 0.28, 0.1), moss * 0.6);
                float3 floorCol = lerp(float3(0.18, 0.13, 0.08), float3(0.12, 0.2, 0.08), Noise3(p * 300.0));
                float3 albedo = lerp(floorCol, stone, onPath);
                float3 nb = BumpNormal(n, p, 1200.0, lerp(0.9, 0.4 + 0.4 * (1.0 - worn), onPath));
                float rough = lerp(0.9, lerp(0.6, 0.4, worn), onPath);
                return Surface(albedo, nb, v, L, sunCol, sh, ao, rough, 0.04, lerp(0.3, 0.0, onPath), skyTop, skyLow);
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

                const float maxHeight = 0.3;
                if (ro.y > maxHeight && rd.y < 0.0) t = max(t, (maxHeight - ro.y) / rd.y);

                bool hit = false;
                float id = 0.0;
                int steps = (int)_Steps;
                [loop] for (int i = 0; i < 200; i++)
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
            #pragma use_dxc vulkan // Quest (Vulkan) 用は新しいコンパイラー (DXC) で変換する。古いほうだと大きいシェーダーが時間切れになる
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
