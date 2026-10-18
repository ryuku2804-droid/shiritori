// ガラスケースに入ったジオラマ (URP 用)。Cube の中をレイマーチングして、小さな世界を描く。
// _Biome で種類を切り替える: 0 アルプス月夜 / 1 火山島 / 2 日本の夕焼け / 3 南国の島
// _Seed で地形と配置を変える (同じバイオームでも作品ごとに違う形になる)。
// _Steps (レイを進める回数) と _ShadowSteps (影を調べる回数) は、DioramaLOD が距離に応じて下げる。
//
// しくみ:
//   Cube の裏側の面を描き (Cull Front)、その画素ごとに「カメラ → 画素」の線を Cube のローカル座標で作る。
//   線が Cube に入る点から出る点まで、地形や木までの距離 (SDF) を測りながら進み、当たった所に色を塗る。
//   カメラが Cube の中にいても描けるので、あとで「ジオラマの世界に入る」のに使える。
//   Cube の座標は -0.5〜0.5。下の 0.08 は黒い台、その上の柱の中に地形がある。
Shader "NightShards/MuseumDiorama"
{
    Properties
    {
        [Enum(Alps,0,Volcano,1,Japan,2,Tropical,3)] _Biome ("Biome", Float) = 0
        _Seed ("Seed", Float) = 0
        _Steps ("Ray Steps", Range(16, 160)) = 96
        _ShadowSteps ("Shadow Steps", Range(0, 32)) = 16
        _Glass ("Glass Reflection", Range(0, 1)) = 0.35
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "Queue" = "Geometry" "RenderPipeline" = "UniversalPipeline" }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        // Quest で 1 にする (QuestQuality が Shader.SetGlobalFloat で入れる)。1 のとき、影と陰の計算を省く。

        // マテリアルごとの値の箱 (UnityPerMaterial) の外に置くので、全部のジオラマに一度に効く

        float _DioramaLite;

        CBUFFER_START(UnityPerMaterial)
            float _Biome;
            float _Seed;
            float _Steps;
            float _ShadowSteps;
            float _Glass;
        CBUFFER_END
        ENDHLSL

        Pass
        {
            Name "Diorama"
            Tags { "LightMode" = "UniversalForward" }
            Cull Front
            ZWrite On

            HLSLPROGRAM
            #pragma target 3.5
            #pragma use_dxc vulkan // Quest (Vulkan) 用は新しいコンパイラー (DXC) で変換する。古いほうだと大きいシェーダーが時間切れになる
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma multi_compile_instancing

            // 当たったものの種類
            #define ID_BASE   0.0
            #define ID_GROUND 1.0
            #define ID_WATER  2.0
            #define ID_TREE   3.0
            #define ID_WALL   4.0
            #define ID_ROOF   5.0
            #define ID_TORII  6.0
            #define ID_TRUNK  7.0
            #define ID_LEAF   8.0

            #define INNER 0.47      // 地形の柱の半分の幅 (ガラスとの間にすき間を残す)
            #define BASE_TOP -0.42  // 黒い台の上面

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
                float3 q = frac(p.xyx * float3(0.1031, 0.1030, 0.0973));
                q += dot(q, q.yzx + 33.33);
                return frac((q.xx + q.yz) * q.zy);
            }

            float ValueNoise(float2 p)
            {
                float2 i = floor(p);
                float2 f = frac(p);
                float2 u = f * f * (3.0 - 2.0 * f);
                float a = Hash21(i);
                float b = Hash21(i + float2(1, 0));
                float c = Hash21(i + float2(0, 1));
                float d = Hash21(i + float2(1, 1));
                return lerp(lerp(a, b, u.x), lerp(c, d, u.x), u.y);
            }

            float Fbm3(float2 p)
            {
                return 0.5 * ValueNoise(p) + 0.25 * ValueNoise(p * 2.03 + 17.1) + 0.125 * ValueNoise(p * 4.1 + 31.7);
            }

            // 尾根のとがったノイズ (山脈用)
            float Ridged(float2 p)
            {
                float v = 0.0;
                float amp = 0.5;
                [loop] for (int k = 0; k < 4; k++)
                {
                    float n = 1.0 - abs(ValueNoise(p) * 2.0 - 1.0);
                    v += amp * n * n;
                    p = p * 2.1 + 13.3;
                    amp *= 0.5;
                }
                return v;
            }

            // ---------------------------------------------------------------- 形の部品 (SDF)

            float SdBox(float3 p, float3 b)
            {
                float3 q = abs(p) - b;
                return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
            }

            float SdCapsule(float3 p, float3 a, float3 b, float r)
            {
                float3 pa = p - a;
                float3 ba = b - a;
                float h = saturate(dot(pa, ba) / dot(ba, ba));
                return length(pa - ba * h) - r;
            }

            float SdEllipsoid(float3 p, float3 r)
            {
                float k0 = length(p / r);
                float k1 = length(p / (r * r));
                return k0 * (k0 - 1.0) / max(k1, 1e-5);
            }

            // ---------------------------------------------------------------- バイオームごとの地形

            float2 SeedOffset() { return float2(_Seed * 1.73, _Seed * 3.11); }

            float WaterLevel()
            {
                if (_Biome < 0.5) return -0.24;
                if (_Biome < 1.5) return -0.22;
                if (_Biome < 2.5) return -0.27;
                return -0.24;
            }

            // 地面の高さ。xz は -0.5〜0.5。手前 (見る人の側) が +z
            float Height(float2 xz)
            {
                float2 s = SeedOffset();
                if (_Biome < 0.5)
                {
                    // アルプス: 奥ほど高い尾根の山脈と、手前の谷と小さな湖
                    float back = smoothstep(0.3, -0.4, xz.y);
                    float h = -0.25 + 0.05 * Fbm3(xz * 4.0 + s) + Ridged(xz * 3.0 + s) * 0.46 * back;
                    float2 lake = xz - float2(-0.15, 0.22);
                    h -= 0.07 * exp(-dot(lake, lake) * 28.0);
                    return h;
                }
                if (_Biome < 1.5)
                {
                    // 火山島: 海に浮かぶ円すいの山と、山頂の火口
                    float2 c = xz - float2(0.02, -0.04);
                    float r2 = dot(c, c);
                    float h = -0.36 + 0.52 * exp(-r2 * 13.0) - 0.13 * exp(-r2 * 420.0);
                    h += 0.03 * Fbm3(xz * 8.0 + s);
                    return h;
                }
                if (_Biome < 2.5)
                {
                    // 日本の夕焼け: 手前に村の平地と川、奥に山なみ
                    float hills = 0.3 * smoothstep(-0.05, -0.45, xz.y) * Fbm3(xz * 2.5 + s + 5.0);
                    float h = -0.25 + 0.04 * Fbm3(xz * 3.0 + s) + hills;
                    float river = abs(xz.y - 0.12 - 0.07 * sin(xz.x * 7.0 + _Seed));
                    h -= 0.045 * smoothstep(0.05, 0.0, river);
                    return h;
                }
                // 南国の島: 浅い海に囲まれた砂の島と、小さな丘
                float2 c1 = xz * float2(1.0, 1.3) - float2(0.03, 0.0);
                float2 c2 = xz - float2(0.12, -0.12);
                float h = -0.33 + 0.16 * exp(-dot(c1, c1) * 14.0) + 0.06 * exp(-dot(c2, c2) * 60.0);
                h += 0.012 * Fbm3(xz * 10.0 + s);
                return h;
            }

            // ---------------------------------------------------------------- 地形の上に置くもの

            // アルプスの針葉樹。0.045 角のます目ごとに、半分ほどの確率で円すいの木を立てる
            float2 Pines(float3 p, float h)
            {
                float2 res = float2(1e5, ID_TREE);
                if (p.y > h + 0.08 || h < -0.235 || h > -0.03) return res;
                const float cell = 0.045;
                float2 id = floor((p.xz + 1.0) / cell);
                if (Hash21(id + _Seed) < 0.45) return res;
                float2 c = (id + 0.5) * cell - 1.0 + (Hash22(id) - 0.5) * 0.008;
                float2 lq = p.xz - c;
                float y = p.y - h;
                float size = lerp(0.7, 1.2, Hash21(id + 7.0));
                float top = 0.006 + 0.055 * size;
                float k = saturate((y - 0.006) / (top - 0.006));
                float radius = 0.015 * size * (1.0 - k);
                res.x = max(length(lq) - radius, max(0.004 - y, y - top)) * 0.6;
                return res;
            }

            // 日本の村: 白壁と瓦屋根の家と、手前の鳥居
            float2 Village(float3 p, float h)
            {
                float2 res = float2(1e5, ID_WALL);
                float y = p.y - h;

                // 家: 手前側の平地にだけ、0.065 角のます目に建てる
                if (y < 0.05 && p.z > -0.05 && p.z < 0.38 && abs(p.x) < 0.42 && h < -0.2 && h > WaterLevel() + 0.006)
                {
                    const float cell = 0.065;
                    float2 id = floor((p.xz + 1.0) / cell);
                    if (Hash21(id + _Seed * 2.0) > 0.5)
                    {
                        float2 c = (id + 0.5) * cell - 1.0;
                        float3 q = float3(p.x - c.x, y, p.z - c.y);
                        float wall = SdBox(q - float3(0, 0.011, 0), float3(0.017, 0.011, 0.013));
                        // 屋根: 断面が三角の切妻屋根
                        float slope = (abs(q.x) * 0.014 + (q.y - 0.022) * 0.022 - 0.022 * 0.014) / 0.026;
                        float roof = max(slope, max(0.022 - q.y, abs(q.z) - 0.016));
                        if (wall < res.x) res = float2(wall, ID_WALL);
                        if (roof < res.x) res = float2(roof, ID_ROOF);
                    }
                }

                // 鳥居: 手前の中央
                float2 lq = p.xz - float2(0.0, 0.3);
                if (length(lq) < 0.08 && y < 0.09)
                {
                    float pillars = min(length(lq - float2(0.03, 0)), length(lq + float2(0.03, 0))) - 0.0035;
                    pillars = max(pillars, max(-y, y - 0.07));
                    float kasagi = SdBox(float3(lq.x, y - 0.072, lq.y), float3(0.045, 0.004, 0.005));
                    float nuki = SdBox(float3(lq.x, y - 0.056, lq.y), float3(0.036, 0.0025, 0.0035));
                    float torii = min(pillars, min(kasagi, nuki));
                    if (torii < res.x) res = float2(torii, ID_TORII);
                }
                return res;
            }

            // 南国の椰子の木: 少し傾いた幹と、垂れた葉 (葉は角度をくり返して1枚ぶんだけ計算する)
            float2 Palms(float3 p)
            {
                float2 res = float2(1e5, ID_TRUNK);
                if (p.y < -0.26 || p.y > 0.0) return res;
                const float2 bases[4] = { float2(0.02, -0.02), float2(0.09, 0.05), float2(-0.07, 0.07), float2(0.13, -0.1) };
                [loop] for (int k = 0; k < 4; k++)
                {
                    float2 b2 = bases[k];
                    if (length(p.xz - b2) > 0.12) continue;
                    float2 lean = (Hash22(b2 * 31.0 + _Seed) - 0.5) * 2.0;
                    float3 b = float3(b2.x, -0.26, b2.y);
                    float3 top = b + float3(lean.x * 0.04, 0.15 + k * 0.012, lean.y * 0.04);
                    float trunk = SdCapsule(p, b, top, 0.0045);
                    if (trunk < res.x) res = float2(trunk, ID_TRUNK);

                    float3 q = p - top;
                    const float sector = 6.2831853 / 7.0;
                    float a = atan2(q.z, q.x);
                    a = fmod(a + sector * 100.5, sector) - sector * 0.5;
                    float r = length(q.xz);
                    float3 lp = float3(r * cos(a), q.y + r * r * 3.0, r * sin(a)); // 外ほど垂れる
                    float leaf = SdEllipsoid(lp - float3(0.035, 0, 0), float3(0.035, 0.004, 0.01));
                    if (leaf < res.x) res = float2(leaf, ID_LEAF);
                }
                return res;
            }

            // ---------------------------------------------------------------- 世界全体

            // 一番近いものまでの距離と、その種類
            float2 Map(float3 p)
            {
                float2 res = float2(SdBox(p - float3(0, -0.46, 0), float3(0.5, 0.04, 0.5)), ID_BASE);

                // 地形は、ガラスの内側の柱の中だけ
                float column = SdBox(p - float3(0, 0.04, 0), float3(INNER, 0.46, INNER));
                float h = Height(p.xz);
                float ground = max((p.y - h) * 0.55, column);
                if (ground < res.x) res = float2(ground, ID_GROUND);

                float water = max(p.y - WaterLevel(), column);
                if (water < res.x) res = float2(water, ID_WATER);

                float2 o = float2(1e5, 0);
                if (_Biome < 0.5) o = Pines(p, h);
                else if (_Biome > 1.5 && _Biome < 2.5) o = Village(p, h);
                else if (_Biome > 2.5) o = Palms(p);
                o.x = max(o.x, column);
                if (o.x < res.x) res = o;

                // 地面の近くでは一歩を小さくして、隣のます目の木や家を飛び越さないようにする
                if (_Biome != 1.0 && p.y < h + 0.09 && column < 0.0) res.x = min(res.x, 0.012);
                return res;
            }

            float3 SceneNormal(float3 p)
            {
                const float2 e = float2(0.0012, -0.0012);
                return normalize(e.xyy * Map(p + e.xyy).x + e.yyx * Map(p + e.yyx).x +
                                 e.yxy * Map(p + e.yxy).x + e.xxx * Map(p + e.xxx).x);
            }

            // やわらかい影。光の方向へ少しずつ進み、途中で何かに近づいたぶんだけ暗くする
            float SoftShadow(float3 p, float3 l)
            {
                if (_DioramaLite > 0.5) return 1.0; // Quest では省く
                float res = 1.0;
                float t = 0.006;
                int n = (int)_ShadowSteps;
                [loop] for (int i = 0; i < 32; i++)
                {
                    if (i >= n) break;
                    float h = Map(p + l * t).x;
                    res = min(res, 10.0 * h / t);
                    t += clamp(h, 0.004, 0.05);
                    if (res < 0.01 || t > 1.2) break;
                }
                return saturate(res);
            }

            // ---------------------------------------------------------------- 光と空

            struct Env
            {
                float3 lightDir;
                float3 lightCol;
                float3 ambient;
            };

            Env GetEnv()
            {
                Env e;
                if (_Biome < 0.5)      { e.lightDir = normalize(float3(-0.5, 0.55, -0.6)); e.lightCol = float3(0.55, 0.65, 1.0) * 1.3; e.ambient = float3(0.04, 0.06, 0.12); }
                else if (_Biome < 1.5) { e.lightDir = normalize(float3(0.3, 0.6, 0.5));    e.lightCol = float3(0.35, 0.3, 0.45) * 0.6; e.ambient = float3(0.08, 0.03, 0.03); }
                else if (_Biome < 2.5) { e.lightDir = normalize(float3(0.7, 0.18, -0.65)); e.lightCol = float3(1.3, 0.65, 0.35);       e.ambient = float3(0.18, 0.12, 0.16); }
                else                   { e.lightDir = normalize(float3(0.4, 0.85, 0.3));   e.lightCol = float3(1.25, 1.18, 1.05);      e.ambient = float3(0.25, 0.32, 0.42); }
                return e;
            }

            float3 Sky(float3 rd, Env e)
            {
                float up = saturate(rd.y);
                float sun = saturate(dot(rd, e.lightDir));
                if (_Biome < 0.5)
                {
                    // 月夜: 濃紺の空、星、月
                    float3 c = lerp(float3(0.03, 0.05, 0.12), float3(0.005, 0.01, 0.035), up);
                    float star = step(0.9975, Hash21(floor(rd.xz / max(rd.y, 0.05) * 90.0))) * smoothstep(0.0, 0.2, rd.y);
                    c += star * 0.8;
                    c += smoothstep(0.9988, 0.9993, sun) * float3(1.6, 1.7, 1.9) + pow(sun, 64.0) * float3(0.15, 0.2, 0.35);
                    return c;
                }
                if (_Biome < 1.5)
                {
                    // 噴火の夜: 赤黒い空。火口の方向が明るい
                    float3 c = lerp(float3(0.22, 0.05, 0.03), float3(0.03, 0.015, 0.04), up);
                    float glow = pow(saturate(1.0 - abs(rd.y - 0.2)), 6.0);
                    return c + glow * float3(0.25, 0.06, 0.02);
                }
                if (_Biome < 2.5)
                {
                    // 夕焼け: 地平は橙、上は紫。低い太陽
                    float3 c = lerp(float3(1.0, 0.45, 0.2), float3(0.22, 0.13, 0.32), pow(up, 0.6));
                    c += smoothstep(0.996, 0.998, sun) * float3(3.0, 2.0, 1.2) + pow(sun, 16.0) * float3(0.6, 0.25, 0.08);
                    return c;
                }
                // 南国の昼: 青い空と白い雲
                float3 c = lerp(float3(0.7, 0.85, 0.95), float3(0.25, 0.5, 0.9), up);
                float cloud = smoothstep(0.55, 0.8, Fbm3(rd.xz / max(rd.y, 0.08) * 1.5 + _Time.y * 0.01));
                c = lerp(c, float3(1.0, 1.0, 1.0), cloud * smoothstep(0.0, 0.25, rd.y));
                c += pow(sun, 200.0) * float3(2.0, 1.9, 1.7);
                return c;
            }

            // ---------------------------------------------------------------- 色を塗る

            // 火山の溶岩: 火口のまわりと、山腹を流れ下る筋が光る
            float3 Lava(float3 p, float h)
            {
                if (_Biome < 0.5 || _Biome > 1.5) return 0;
                float2 c = p.xz - float2(0.02, -0.04);
                float r = length(c);
                float flow = ValueNoise(float2(atan2(c.y, c.x) * 3.0, r * 5.0) + _Seed);
                float stream = smoothstep(0.72, 0.85, flow) * smoothstep(0.32, 0.06, r) * step(-0.19, h);
                float crater = smoothstep(0.07, 0.03, r) * step(0.0, h);
                float pulse = 0.75 + 0.25 * sin(_Time.y * 1.5 + r * 30.0);
                return float3(4.0, 1.1, 0.15) * (stream + crater) * pulse;
            }

            float3 GroundColor(float3 p, float3 n, float h)
            {
                float w = WaterLevel();
                if (_Biome < 0.5)
                {
                    float3 rock = float3(0.22, 0.22, 0.25);
                    float3 grass = float3(0.06, 0.1, 0.06);
                    float3 c = lerp(grass, rock, smoothstep(-0.2, -0.12, h));
                    float snow = max(smoothstep(-0.12, -0.08, h) * smoothstep(0.5, 0.7, n.y), smoothstep(0.0, 0.04, h));
                    return lerp(c, float3(0.9, 0.93, 1.0), snow);
                }
                if (_Biome < 1.5)
                {
                    float3 c = lerp(float3(0.06, 0.05, 0.05), float3(0.16, 0.15, 0.15), smoothstep(-0.1, 0.1, h));
                    return lerp(float3(0.3, 0.25, 0.2), c, smoothstep(w, w + 0.015, h)); // 波打ち際は砂浜
                }
                if (_Biome < 2.5)
                {
                    float3 field = float3(0.25, 0.32, 0.12) * (0.85 + 0.3 * step(0.5, frac(p.x * 40.0))); // 田畑のすじ
                    float3 forest = float3(0.08, 0.16, 0.06);
                    return lerp(field, forest, smoothstep(-0.2, -0.12, h));
                }
                float3 sand = float3(0.85, 0.78, 0.55);
                float3 green = float3(0.2, 0.45, 0.15);
                return lerp(sand, green, smoothstep(w + 0.02, w + 0.04, h));
            }

            float3 WaterColor(float depth)
            {
                float3 shallow, deep;
                if (_Biome < 0.5)      { shallow = float3(0.03, 0.06, 0.1);  deep = float3(0.01, 0.02, 0.05); }
                else if (_Biome < 1.5) { shallow = float3(0.05, 0.04, 0.04); deep = float3(0.01, 0.01, 0.02); }
                else if (_Biome < 2.5) { shallow = float3(0.2, 0.15, 0.12);  deep = float3(0.05, 0.04, 0.06); }
                else                   { shallow = float3(0.15, 0.75, 0.7);  deep = float3(0.0, 0.15, 0.3); }
                return lerp(shallow, deep, saturate(depth * 10.0));
            }

            float3 Shade(float3 ro, float3 rd, float3 p, float id, bool crossSection, float3 faceNormal, Env e)
            {
                float h = Height(p.xz);

                // 黒い台
                if (id == ID_BASE) return float3(0.015, 0.014, 0.014) + 0.03 * pow(saturate(dot(reflect(rd, faceNormal), e.lightDir)), 8.0);

                // ガラス越しに見える地面の断面: 地層のしま模様
                if (crossSection && id == ID_GROUND)
                {
                    float band = 0.5 + 0.5 * sin(p.y * 90.0 + ValueNoise(p.xz * 30.0 + p.y * 20.0) * 3.0);
                    float3 soil = lerp(float3(0.12, 0.08, 0.05), float3(0.22, 0.16, 0.1), band);
                    if (_Biome > 2.5) soil = lerp(soil, float3(0.6, 0.55, 0.4), 0.5);
                    return soil * (e.ambient * 2.0 + 0.15) * (0.6 + 0.4 * smoothstep(BASE_TOP, h, p.y));
                }
                if (crossSection && id == ID_WATER)
                {
                    // 水の断面: 水槽のように、深いほど暗い
                    return WaterColor(WaterLevel() - p.y) * (e.ambient * 3.0 + 0.3);
                }

                float3 n = SceneNormal(p);
                float sh = SoftShadow(p + n * 0.002, e.lightDir);
                float diff = saturate(dot(n, e.lightDir)) * sh;
                float3 amb = e.ambient * (0.5 + 0.5 * n.y);

                if (id == ID_WATER)
                {
                    // 水面: 小さな波で向きを揺らし、空を映す
                    float t = _Time.y;
                    float2 q = p.xz * 60.0;
                    float3 wn = normalize(float3((ValueNoise(q + t) - 0.5) * 0.15, 1.0, (ValueNoise(q.yx - t * 0.8) - 0.5) * 0.15));
                    float3 r = reflect(rd, wn);
                    float fres = 0.02 + 0.98 * pow(1.0 - saturate(dot(-rd, wn)), 5.0);
                    float3 body = WaterColor(WaterLevel() - h) * (amb * 2.0 + e.lightCol * saturate(dot(wn, e.lightDir)) * 0.5);
                    float spec = pow(saturate(dot(r, e.lightDir)), 120.0) * sh;
                    float3 c = lerp(body, Sky(r, e), fres) + e.lightCol * spec;
                    c += Lava(p, 0.2) * 0.15; // 火山の海は溶岩の色を映す
                    return c;
                }

                float3 albedo;
                if (id == ID_GROUND)     albedo = GroundColor(p, n, h);
                else if (id == ID_TREE)  albedo = float3(0.04, 0.09, 0.06);
                else if (id == ID_WALL)  albedo = float3(0.85, 0.82, 0.75);
                else if (id == ID_ROOF)  albedo = float3(0.16, 0.16, 0.2);
                else if (id == ID_TORII) albedo = float3(0.75, 0.12, 0.06);
                else if (id == ID_TRUNK) albedo = float3(0.4, 0.3, 0.2);
                else                     albedo = float3(0.12, 0.4, 0.12);

                float3 c = albedo * (e.lightCol * diff + amb);

                // 火山: 溶岩の光と、火口のまわりを照らす赤い光
                if (_Biome > 0.5 && _Biome < 1.5 && id == ID_GROUND)
                {
                    float3 crater = float3(0.02, 0.12, -0.04) - p;
                    c += albedo * float3(1.0, 0.35, 0.08) * 0.6 / (1.0 + dot(crater, crater) * 60.0);
                    c += Lava(p, h);
                }
                return c;
            }

            // ---------------------------------------------------------------- 本体

            // 線と箱 (-b〜b) の交わり。x: 入る距離、y: 出る距離
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
                Env e = GetEnv();

                // カメラから画素へ向かう線を、Cube のローカル座標で作る
                float3 ro = TransformWorldToObject(GetCameraPositionWS());
                float3 rd = normalize(input.positionOS - ro);
                float2 box = BoxHit(ro, rd, float3(0.5, 0.5, 0.5));
                bool outside = box.x > 0.0;
                float t = max(box.x, 0.0);

                // 入った点の面の向き (ガラスの反射と、断面の判定に使う)
                float3 entry = ro + rd * t;
                float3 ae = abs(entry);
                float3 faceNormal = ae.x > ae.y && ae.x > ae.z ? float3(sign(entry.x), 0, 0)
                                  : (ae.y > ae.z ? float3(0, sign(entry.y), 0) : float3(0, 0, sign(entry.z)));

                // 山より上の何もない空間は飛ばす
                const float maxHeight = 0.26;
                if (ro.y > maxHeight && rd.y < 0.0) t = max(t, (maxHeight - ro.y) / rd.y);

                bool hit = false;
                float id = 0.0;
                int steps = (int)_Steps;
                [loop] for (int i = 0; i < 160; i++)
                {
                    if (i >= steps || t > box.y) break;
                    float2 m = Map(ro + rd * t);
                    if (m.x < 0.0004 * (1.0 + t))
                    {
                        hit = true;
                        id = m.y;
                        break;
                    }
                    t += m.x;
                }

                float3 col;
                if (hit)
                {
                    float3 p = ro + rd * t;
                    // ケースの壁ぎわで当たったら、断面として塗る
                    bool crossSection = outside && (abs(p.x) > INNER - 0.002 || abs(p.z) > INNER - 0.002);
                    col = Shade(ro, rd, p, id, crossSection, faceNormal, e);
                }
                else
                {
                    col = Sky(rd, e);
                }

                // ガラス: 外から見ているときだけ、縁の金属の枠と、斜めから見たときの映り込みを足す
                if (outside)
                {
                    float fres = 0.04 + 0.96 * pow(1.0 - saturate(dot(-rd, faceNormal)), 5.0);
                    col = lerp(col, float3(0.75, 0.8, 0.85) * 0.5, fres * _Glass);
                    float3 d = 0.5 - ae;
                    float edge = d.x + d.y + d.z - max(d.x, max(d.y, d.z)); // 2番目に近い面までの距離に近い値
                    float frame = 1.0 - smoothstep(0.004, 0.006, edge);
                    col = lerp(col, float3(0.05, 0.05, 0.055) + 0.15 * fres, frame);
                }
                return half4(col, 1.0);
            }
            ENDHLSL
        }

        // 奥行きだけを書くパス (URP が前もって奥行きを取るときに使う)。色のパスと同じく裏側の面を書く
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
