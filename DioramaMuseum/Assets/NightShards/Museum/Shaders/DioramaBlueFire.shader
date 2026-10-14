// 作品「青い火の焦土」(火の間)。青い炎に焼かれ、黒く焦げた夜の大地。URP 用。
// Cube の中をレイマーチングして描く。Cube の座標は -0.5〜0.5、下の 0.08 は黒い台。
//
// 見どころ:
//   ・黒く焦げてひび割れた大地。割れ目の奥が、まだ冷めない熱で青く光る (ゆっくり息をするように明るさが変わる)
//   ・焼け残った黒い枯れ木。幹の割れ目に、青い燠火 (おきび) がくすぶる
//   ・あちこちで燃え続ける青い炎と、そこから舞い上がる青い火の粉
//   ・地をはうように流れる煙。下から青い炎に照らされる
// 仕掛け (_Event 0〜1): 青い炎の輪が、真ん中から大地いっぱいに燃え広がる。輪が通った所は、割れ目も木も強く燃え上がる
//
// 外から見たとき、地形のない所 (空) は透明にして、ガラスケースの向こうの部屋が見えるようにする。
// 中に入ったとき (カメラが箱の中) だけ、空を描く
//
// _Steps / _ShadowSteps は DioramaLOD が距離で下げる。_Event / _EventTime は DioramaWork が渡す
Shader "NightShards/Diorama/BlueFire"
{
    Properties
    {
        _Steps ("Ray Steps", Range(16, 200)) = 130
        _ShadowSteps ("Shadow Steps", Range(0, 32)) = 16
        _Glass ("Glass Reflection", Range(0, 1)) = 0.3
        _Event ("Event (0-1)", Range(0, 1)) = 0
        _EventTime ("Event Time (s)", Float) = 0
        _Seed ("Seed", Float) = 0
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
            #define ID_TREE   2.0

            #define INNER 0.47
            #define FIRES 7      // 燃え続ける炎の場所の数
            #define TONGUES 4    // 1 か所あたりの炎の舌の数
            #define SPARKS 24    // 舞い上がる火の粉の数
            #define TREE_CELL 0.11
            static const float3 MOON_DIR = float3(-0.5, 0.45, 0.6); // 正規化は使う所で
            static const float2 FIRE_XZ[FIRES] =
            {
                float2(-0.25, -0.1), float2(0.05, -0.28), float2(0.3, 0.12), float2(-0.1, 0.18),
                float2(0.22, -0.2), float2(-0.32, 0.27), float2(0.02, 0.02)
            };

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

            float Hash11(float n) { return frac(sin(n * 127.1) * 43758.5453); }

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

            // ひび割れの模様 (ボロノイ)。x = 割れ目 (区画の境目) までの距離、y = 区画ごとの乱数
            float2 Cracks(float2 x)
            {
                float2 n = floor(x);
                float2 f = frac(x);
                float2 mg = 0, mr = 0;
                float md = 8.0;
                for (int j = -1; j <= 1; j++)
                for (int i = -1; i <= 1; i++)
                {
                    float2 g = float2(i, j);
                    float2 r = g + Hash22(n + g) - f;
                    float d = dot(r, r);
                    if (d < md)
                    {
                        md = d;
                        mr = r;
                        mg = g;
                    }
                }
                md = 8.0;
                for (int jj = -2; jj <= 2; jj++)
                for (int ii = -2; ii <= 2; ii++)
                {
                    float2 g = mg + float2(ii, jj);
                    float2 r = g + Hash22(n + g) - f;
                    float2 dr = r - mr;
                    if (dot(dr, dr) > 0.00001) md = min(md, dot(0.5 * (mr + r), normalize(dr)));
                }
                return float2(md, Hash21(n + mg));
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

            // ---------------------------------------------------------------- 地形

            float Height(float2 xz)
            {
                // 焼け野原: ゆるやかな起伏に、低い丘が 2 つと、干上がった川の跡
                float h = -0.2 + 0.05 * Fbm3(xz * 3.0 + _Seed) - 0.025;
                float2 a = (xz - float2(-0.22, -0.22)) / 0.15;
                float2 b = (xz - float2(0.25, -0.05)) / 0.12;
                h += 0.08 * exp(-dot(a, a)) + 0.05 * exp(-dot(b, b));
                float river = (xz.x - 0.1 - 0.08 * sin(xz.y * 6.0 + _Seed)) / 0.03;
                h -= 0.025 * exp(-river * river);
                // 細かい起伏と、岩肌の細かい尾根
                h += 0.01 * Fbm3(xz * 14.0 + _Seed) - 0.005;
                float rid = 1.0 - abs(ValueNoise(xz * 38.0 + _Seed * 1.7) * 2.0 - 1.0);
                float rid2 = 1.0 - abs(ValueNoise(xz * 81.0 + _Seed * 2.3 + 7.0) * 2.0 - 1.0);
                h += 0.004 * rid * rid + 0.002 * rid2 * rid2;
                // ※ この式を変えたら、C# の DioramaTerrain.BlueFireHeight も同じに直す (中を歩くときの地面になる)
                return h;
            }

            // 地形の大まかな高さ (細かい起伏を省いた、軽い版)。木の根元や炎の輪など、細かさのいらない所に使う
            float HeightCoarse(float2 xz)
            {
                float h = -0.2 + 0.05 * Fbm3(xz * 3.0 + _Seed) - 0.025;
                float2 a = (xz - float2(-0.22, -0.22)) / 0.15;
                float2 b = (xz - float2(0.25, -0.05)) / 0.12;
                h += 0.08 * exp(-dot(a, a)) + 0.05 * exp(-dot(b, b));
                float river = (xz.x - 0.1 - 0.08 * sin(xz.y * 6.0 + _Seed)) / 0.03;
                return h - 0.025 * exp(-river * river) + 0.003;
            }

            // ---------------------------------------------------------------- 枯れ木

            // 枯れ木の形 (距離)。地面を TREE_CELL の大きさのます目に分け、ます目ごとにくじを引いて木を 1 本立てる。
            // groundH は p の真下の地面の高さ (地面から遠い所は計算を省く)
            float Trees(float3 p, float groundH)
            {
                if (p.y - groundH > 0.19) return p.y - groundH - 0.18;
                float2 cell = floor(p.xz / TREE_CELL);
                float2 local = p.xz - (cell + 0.5) * TREE_CELL;
                float2 toEdge = 0.5 * TREE_CELL - abs(local);
                float bound = max(min(toEdge.x, toEdge.y), 0.0) + 0.004; // 隣のます目に入るまでは、この距離だけ進んでよい
                float2 id = cell + _Seed * 0.37;
                if (Hash21(id) > 0.42) return bound;
                float2 off = (Hash22(id + 1.3) - 0.5) * TREE_CELL * 0.35;
                float2 base = (cell + 0.5) * TREE_CELL + off;
                if (abs(base.x) > INNER - 0.03 || abs(base.y) > INNER - 0.03) return bound;
                float3 q = p - float3(base.x, HeightCoarse(base) - 0.012, base.y); // 根元は少し地面に埋める (軽い版の高さとの差を隠す)
                float hgt = 0.07 + 0.08 * Hash21(id + 3.3);
                q.x -= q.y * (Hash21(id + 5.5) - 0.5) * 0.3; // 少し傾く
                // 幹: 上へ行くほど細い
                float k = saturate(q.y / hgt);
                float d = SdCapsule(q, float3(0, 0, 0), float3(0, hgt, 0), 0.0055 * (1.0 - 0.6 * k));
                // 枝: 幹の途中から、斜め上へ 3 本
                for (int b = 0; b < 3; b++)
                {
                    float fb = b;
                    float y0 = hgt * (0.45 + 0.17 * fb);
                    float ang = Hash21(id + fb * 9.1) * 6.2831;
                    float len = (0.025 + 0.025 * Hash21(id + fb * 4.7)) * (1.0 - 0.25 * fb);
                    float3 tip = float3(cos(ang) * 0.75, 0.65, sin(ang) * 0.75) * len;
                    d = min(d, SdCapsule(q, float3(0, y0, 0), float3(0, y0, 0) + tip, 0.0022));
                }
                return min(d, bound);
            }

            // ---------------------------------------------------------------- 世界の形

            float2 Map(float3 p)
            {
                float2 res = float2(SdBox(p - float3(0, -0.46, 0), float3(0.5, 0.04, 0.5)), ID_BASE);
                float column = SdBox(p - float3(0, 0.04, 0), float3(INNER, 0.46, INNER));
                float h = Height(p.xz);
                float ground = max((p.y - h) * 0.5, column);
                if (ground < res.x) res = float2(ground, ID_GROUND);
                float tree = max(Trees(p, h), column);
                if (tree < res.x) res = float2(tree, ID_TREE);
                return res;
            }

            float3 SceneNormal(float3 p)
            {
                const float2 e = float2(0.0007, -0.0007);
                float3 g = e.xyy * Map(p + e.xyy).x + e.yyx * Map(p + e.yyx).x +
                           e.yxy * Map(p + e.yxy).x + e.xxx * Map(p + e.xxx).x;
                // 平らすぎて向きが決まらない所でも壊れないように (0 で割ると、画面が白く点滅する原因になる)
                return g / max(length(g), 1e-7);
            }

            float SoftShadow(float3 p, float3 l)
            {
                float res = 1.0;
                float t = 0.006;
                int n = (int)_ShadowSteps;
                for (int i = 0; i < 32; i++)
                {
                    if (i >= n) break;
                    float h = Map(p + l * t).x;
                    res = min(res, 10.0 * h / t);
                    t += clamp(h, 0.004, 0.05);
                    if (res < 0.01 || t > 1.0) break;
                }
                return saturate(res);
            }

            float AmbientOcclusion(float3 p, float3 n)
            {
                float occ = 0.0;
                float w = 1.0;
                for (int i = 1; i <= 4; i++)
                {
                    float d = 0.01 * i;
                    occ += (d - Map(p + n * d).x) * w;
                    w *= 0.6;
                }
                return saturate(1.0 - occ * 14.0);
            }

            // ---------------------------------------------------------------- 炎の輪 (仕掛け)

            // 炎の輪の半径 (真ん中から広がる)。0 なら輪はない
            float FrontRadius()
            {
                return _Event > 0.001 ? saturate(_EventTime / 7.0) * 0.75 : 0.0;
            }

            // 炎の輪がもう通り過ぎた所ほど 1 (焼けて燃え上がっている)
            float Burned(float2 xz)
            {
                float R = FrontRadius();
                return smoothstep(R, R - 0.08, length(xz)) * saturate(_Event * 1.5);
            }

            // 炎の輪のすぐそばほど 1
            float FrontNear(float2 xz)
            {
                float d = (length(xz) - FrontRadius()) / 0.05;
                return _Event > 0.001 ? exp(-d * d) * saturate(_Event * 1.5) : 0.0;
            }

            float3 FlameColor(float k) // k: 炎の根元 0 → 先 1
            {
                return lerp(float3(0.6, 0.95, 3.0), float3(0.1, 0.25, 1.6), k);
            }

            // ---------------------------------------------------------------- 燃え続ける炎 (炎の舌)

            // 炎 i 番の場所の、舌 j 番の根元 (xyz) と高さ (w)
            float4 Tongue(int i, int j, float baseY)
            {
                float fi = i, fj = j;
                float2 xz = FIRE_XZ[i] + (Hash22(float2(fi, fj) + _Seed) - 0.5) * 0.035;
                float flick = Noise3(float3(fi * 7.1 + fj * 2.3, _Time.y * 4.5, 0.0));
                float height = (0.018 + 0.02 * flick) * (1.0 + 1.5 * Burned(xz));
                return float4(xz.x, baseY - 0.002, xz.y, height);
            }

            // 線と、炎の舌 (根元から上へのびる縦の線分) の一番近い所から、ぼんやり光る舌として足す
            float3 TongueGlow(float3 ro, float3 rd, float tMax, float4 tg, float seed)
            {
                float3 w0 = ro - tg.xyz;
                float b = rd.y;
                float dd = dot(rd, w0);
                float e = w0.y;
                float den = 1.0 - b * b;
                if (den < 0.0001) return 0;
                float sc = (b * e - dd) / den;                  // 線の上の位置
                if (sc < 0.0 || sc > tMax) return 0;
                float tc = clamp((e - b * dd) / den, 0.0, tg.w); // 舌の上の位置
                float3 diff = ro + rd * sc - (tg.xyz + float3(0, tc, 0));
                float k = tc / tg.w;
                float rad = 0.0045 * sqrt(1.0 - k) + 0.0012;
                float glow = exp(-dot(diff, diff) / (rad * rad));
                float n = Noise3(float3(seed, k * 6.0 - _Time.y * 7.0, 0.0));
                return FlameColor(k) * glow * (1.0 - k * 0.6) * (0.6 + 0.8 * n) * 1.4;
            }

            float3 Fires(float3 ro, float3 rd, float tMax, float fireY[FIRES])
            {
                float3 col = 0;
                for (int i = 0; i < FIRES; i++)
                {
                    // 線がこの炎の近くを通らなければ飛ばす
                    float3 c = float3(FIRE_XZ[i].x, fireY[i] + 0.02, FIRE_XZ[i].y);
                    float3 w = c - ro;
                    float tcl = dot(w, rd);
                    if (dot(w, w) - tcl * tcl > 0.0036) continue;
                    for (int j = 0; j < TONGUES; j++)
                        col += TongueGlow(ro, rd, tMax, Tongue(i, j, fireY[i]), i * 3.3 + j * 1.7);
                }
                return col;
            }

            // ---------------------------------------------------------------- 火の粉

            // 火の粉 i 番の場所。炎の場所から、ゆらゆら舞いながら昇って、消える
            float3 Spark(int i, float fireY[FIRES], out float life)
            {
                float fi = i;
                int src = (int)(Hash11(fi * 1.7) * FIRES);
                float period = 2.5 + 2.0 * Hash11(fi * 3.1);
                float ph = frac(_Time.y / period + Hash11(fi * 5.3));
                life = ph;
                float rise = ph * (0.12 + 0.1 * Hash11(fi * 2.9)) * (1.0 + _Event);
                float2 sway = float2(sin(_Time.y * 1.3 + fi), cos(_Time.y * 1.1 + fi * 2.0)) * 0.01 * ph;
                float2 drift = float2(0.05, 0.02) * ph * ph; // 風下へ流される
                float2 xz = FIRE_XZ[src] + (Hash22(float2(fi, 3.0)) - 0.5) * 0.03 + sway + drift;
                return float3(xz.x, fireY[src] + 0.01 + rise, xz.y);
            }

            float3 Sparks(float3 ro, float3 rd, float tMax, float fireY[FIRES])
            {
                float3 col = 0;
                for (int i = 0; i < SPARKS; i++)
                {
                    float life;
                    float3 w = Spark(i, fireY, life) - ro;
                    float tc = dot(w, rd);
                    if (tc < 0.0 || tc > tMax) continue;
                    float d2 = dot(w, w) - tc * tc;
                    float core = max(0.0008, tc * 0.0012); // 遠くからでも点として見えるように
                    float fade = sin(life * 3.1416);
                    col += float3(0.4, 0.75, 2.4) * fade * (exp(-d2 / (core * core)) + 0.05 * exp(-d2 / (core * core * 20.0)));
                }
                return col;
            }

            // ---------------------------------------------------------------- 炎の輪 (立体)

            // 地面のすぐ上の薄い層を進んで、広がる炎の壁の光を足す (仕掛けの最中だけ)
            float3 FrontFlames(float3 ro, float3 rd, float tMax)
            {
                float R = FrontRadius();
                if (_Event < 0.01 || R <= 0.0) return 0;
                float3 bmin = float3(-INNER, -0.3, -INNER);
                float3 bmax = float3(INNER, -0.03, INNER);
                float3 inv = 1.0 / rd;
                float3 t0 = (bmin - ro) * inv, t1 = (bmax - ro) * inv;
                float3 tsmall = min(t0, t1), tbig = max(t0, t1);
                float tin = max(max(max(tsmall.x, tsmall.y), tsmall.z), 0.0);
                float tout = min(min(min(tbig.x, tbig.y), tbig.z), tMax);
                if (tout <= tin) return 0;

                const int steps = 22;
                float dt = (tout - tin) / steps;
                float t = tin + dt * Hash21(rd.zy * 271.0 + _Time.y);
                float3 col = 0;
                for (int s = 0; s < steps; s++)
                {
                    float3 p = ro + rd * t;
                    float near = FrontNear(p.xz);
                    if (near > 0.02)
                    {
                        float y = p.y - HeightCoarse(p.xz);
                        float ang = atan2(p.z, p.x);
                        float fh = 0.07 * (0.35 + 0.65 * Noise3(float3(ang * 6.0, _Time.y * 2.0, 0.0))) * near;
                        if (y > 0.0 && y < fh)
                        {
                            float k = y / fh;
                            float n = Noise3(float3(p.x * 220.0, y * 160.0 - _Time.y * 9.0, p.z * 220.0));
                            col += FlameColor(k) * (1.0 - k) * (0.3 + n) * dt * 160.0;
                        }
                    }
                    t += dt;
                }
                return col;
            }

            // ---------------------------------------------------------------- 煙

            float SmokeDensity(float3 p, float fireY[FIRES])
            {
                float t = _Time.y;
                float y = p.y + 0.25; // 地面のあたりを 0 とした高さ
                if (y < 0.0 || y > 0.45) return 0.0;
                // 地をはう煙の層: 低い所ほど濃く、風に流れる
                float3 q = float3(p.x - t * 0.012, y * 3.0, p.z) * 9.0;
                float layer = Noise3(q) * 0.6 + Noise3(q * 2.2 + 4.1) * 0.4;
                float dens = max(0.0, layer - 0.48) * 9.0 * smoothstep(0.2, 0.02, y);
                // 炎の上に立ちのぼる煙の柱 (風下へ曲がる)
                for (int i = 0; i < FIRES; i++)
                {
                    float sy = p.y - fireY[i];
                    if (sy < 0.0) continue;
                    float2 c = p.xz - FIRE_XZ[i] - float2(0.05, 0.02) * sy * 2.0;
                    float rad = 0.02 + sy * 0.3;
                    float s = saturate(1.0 - length(c) / rad) * smoothstep(0.4, 0.1, sy);
                    if (s <= 0.0) continue;
                    float n = Noise3(float3(c.x * 30.0, sy * 30.0 - t * 1.2, c.y * 30.0));
                    dens += max(0.0, s * 1.2 + n * 0.8 - 0.9) * 25.0;
                }
                return dens * (1.0 + 0.8 * _Event);
            }

            float4 Smoke(float3 ro, float3 rd, float tMax, float fireY[FIRES])
            {
                float3 bmin = float3(-INNER, -0.3, -INNER);
                float3 bmax = float3(INNER, 0.2, INNER);
                float3 inv = 1.0 / rd;
                float3 t0 = (bmin - ro) * inv, t1 = (bmax - ro) * inv;
                float3 tsmall = min(t0, t1), tbig = max(t0, t1);
                float tin = max(max(max(tsmall.x, tsmall.y), tsmall.z), 0.0);
                float tout = min(min(min(tbig.x, tbig.y), tbig.z), tMax);
                if (tout <= tin) return float4(0, 0, 0, 1);

                int steps = clamp((int)(_Steps / 7.0), 8, 20);
                float dt = (tout - tin) / steps;
                float t = tin + dt * Hash21(rd.xy * 517.0 + _Time.y);
                float3 col = 0;
                float trans = 1.0;
                for (int i = 0; i < 32; i++)
                {
                    if (i >= steps) break;
                    float3 p = ro + rd * t;
                    float dens = SmokeDensity(p, fireY);
                    if (dens > 0.0)
                    {
                        // 煙は下から青い炎と割れ目に照らされる。上のほうは月明かりで灰色
                        float low = exp(-(p.y + 0.22) * 9.0);
                        float3 light = float3(0.03, 0.032, 0.038) + float3(0.08, 0.18, 0.6) * low * (0.6 + 1.5 * _Event + 2.0 * FrontNear(p.xz));
                        float a = 1.0 - exp(-dens * dt);
                        col += trans * a * light;
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
                // 煙で覆われた暗い夜空。地平線は、遠くの青い炎で青く照らされる
                float3 c = lerp(float3(0.01, 0.014, 0.03), float3(0.003, 0.004, 0.008), sqrt(up));
                c += float3(0.02, 0.06, 0.2) * pow(1.0 - up, 6.0) * (1.0 + 2.0 * _Event);
                float cloud = Noise3(float3(rd.xz / max(rd.y, 0.08) * 2.0, _Time.y * 0.02));
                c *= 0.7 + 0.6 * cloud;
                // 煙の切れ間に、ところどころ星
                float3 sp = rd * 200.0;
                float3 cell = floor(sp);
                float star = step(0.995, Hash31(cell)) * smoothstep(0.25, 0.1, length(frac(sp) - 0.5));
                c += star * 0.8 * smoothstep(0.55, 0.8, cloud) * smoothstep(0.05, 0.3, rd.y);
                return c;
            }

            // ---------------------------------------------------------------- 色を塗る

            float3 Shade(float3 ro, float3 rd, float3 p, float id, bool crossSection, float3 faceNormal, float fireY[FIRES])
            {
                float3 moonDir = normalize(MOON_DIR);
                float3 moonCol = float3(0.16, 0.19, 0.28);
                float3 skyAmb = float3(0.01, 0.013, 0.025);
                float t = _Time.y;

                if (id == ID_BASE)
                    return float3(0.015, 0.014, 0.014) + 0.03 * pow(saturate(dot(reflect(rd, faceNormal), moonDir)), 8.0);

                if (crossSection && id == ID_GROUND)
                {
                    // 断面: 焦げた表土の下に、灰と土の層。表のすぐ下は熱でうっすら青い
                    float h = Height(p.xz);
                    float depth = h - p.y;
                    float band = 0.5 + 0.5 * sin(p.y * 130.0 + ValueNoise(p.xz * 40.0 + p.y * 30.0) * 4.0);
                    float3 soil = lerp(float3(0.04, 0.035, 0.032), float3(0.09, 0.08, 0.07), band) * 0.3;
                    return soil + float3(0.05, 0.12, 0.6) * exp(-depth * 60.0) * (0.5 + _Event);
                }

                float3 n = SceneNormal(p);
                float sh = SoftShadow(p + n * 0.002, moonDir);
                float ao = AmbientOcclusion(p, n);

                // 燃え続ける炎と炎の輪からの、青い光
                float3 fireLight = 0;
                float flicker = 0.85 + 0.15 * sin(t * 11.0) * sin(t * 6.7);
                for (int i = 0; i < FIRES; i++)
                {
                    float3 toF = float3(FIRE_XZ[i].x, fireY[i] + 0.02, FIRE_XZ[i].y) - p;
                    float atten = 1.0 / (1.0 + dot(toF, toF) * 400.0);
                    fireLight += float3(0.2, 0.45, 1.5) * atten * saturate(dot(n, normalize(toF)) * 0.6 + 0.4) * (1.0 + Burned(FIRE_XZ[i]));
                }
                fireLight *= flicker;
                float frontNear = FrontNear(p.xz);
                fireLight += float3(0.2, 0.45, 1.6) * frontNear * 2.5;
                float burned = Burned(p.xz);

                if (id == ID_TREE)
                {
                    // 焼け残った木: 炭のように黒く、割れ目に青い燠火がくすぶる。炎の輪が通ると燃え上がる
                    float3 albedo = float3(0.018, 0.017, 0.018);
                    float ember = smoothstep(0.6, 0.72, Noise3(p * 320.0 + float3(0, -t * 0.3, 0)));
                    float heat = 0.25 + 0.5 * Noise3(float3(p.xz * 30.0, t * 0.4)) + burned * 1.5 + frontNear * 2.0;
                    float3 c = albedo * (moonCol * saturate(dot(n, moonDir)) * sh + skyAmb) * ao + albedo * fireLight * 3.0;
                    c += float3(0.15, 0.4, 2.0) * ember * heat;
                    return c;
                }

                // 焦げた大地: 黒い板に割れ、割れ目の奥が青く光る。板の真ん中には白っぽい灰が積もる
                float2 big = Cracks(p.xz * 22.0 + _Seed);
                float crack = 1.0 - smoothstep(0.0, 0.07, big.x);
                float crack2 = (1.0 - smoothstep(0.0, 0.08, abs(ValueNoise(p.xz * 70.0 + _Seed * 2.0) - 0.5))) * 0.5; // 細かいひびは、軽いノイズの線で
                float ash = smoothstep(0.08, 0.3, big.x) * (0.4 + 0.6 * ValueNoise(p.xz * 90.0)) * (0.5 + 0.5 * big.y);
                float3 albedo = lerp(float3(0.014, 0.013, 0.014), float3(0.085, 0.083, 0.082), ash * (1.0 - burned * 0.7));
                albedo *= 1.0 - max(crack, crack2) * 0.8;

                float3 c = albedo * (moonCol * saturate(dot(n, moonDir)) * sh + skyAmb * (0.5 + 0.5 * n.y)) * ao;
                c += albedo * fireLight * 4.0;
                // 割れ目の熱: ゆっくり息をするように明るさが変わる。炎の近くと、炎の輪が通った所は強い
                float breathe = 0.3 + 0.7 * Noise3(float3(p.xz * 7.0, t * 0.15));
                float nearFire = 0.0;
                for (int k = 0; k < FIRES; k++)
                {
                    float2 dv = p.xz - FIRE_XZ[k];
                    nearFire += exp(-dot(dv, dv) / 0.006);
                }
                float heat = breathe * (0.35 + 0.8 * nearFire) * (0.6 + 0.4 * big.y) + burned * 1.2 + frontNear * 3.0;
                c += float3(0.12, 0.38, 2.2) * (crack + crack2) * heat * heat;
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
                float t = max(box.x, 0.0);

                float3 entry = ro + rd * t;
                float3 ae = abs(entry);
                float3 faceNormal = ae.x > ae.y && ae.x > ae.z ? float3(sign(entry.x), 0, 0)
                                  : (ae.y > ae.z ? float3(0, sign(entry.y), 0) : float3(0, 0, sign(entry.z)));

                // 地形と木より上の何もない空間は飛ばす (炎・火の粉・煙は別に計算する)
                const float maxHeight = 0.1;
                if (ro.y > maxHeight && rd.y < 0.0) t = max(t, (maxHeight - ro.y) / rd.y);

                bool hit = false;
                float id = 0.0;
                int steps = (int)_Steps;
                for (int i = 0; i < 200; i++)
                {
                    if (i >= steps || t > box.y) break;
                    float2 m = Map(ro + rd * t);
                    if (m.x < 0.0003 * (1.0 + t))
                    {
                        hit = true;
                        id = m.y;
                        break;
                    }
                    t += m.x;
                }
                float tHit = hit ? t : box.y;

                // 燃え続ける炎の根元の高さ
                float fireY[FIRES];
                for (int f = 0; f < FIRES; f++) fireY[f] = Height(FIRE_XZ[f]);

                float3 col = 0;
                if (hit)
                {
                    float3 p = ro + rd * t;
                    bool crossSection = outside && (abs(p.x) > INNER - 0.002 || abs(p.z) > INNER - 0.002);
                    col = Shade(ro, rd, p, id, crossSection, faceNormal, fireY);
                }
                else if (!outside)
                {
                    col = Sky(rd); // 中に入っているときだけ、空を描く
                }

                // 霞: 線がケースの中を進んだ距離が長いほど、煙った夜の空気の色に沈める
                float travel = tHit - max(box.x, 0.0);
                float3 haze = float3(0.01, 0.015, 0.03) + float3(0.0, 0.015, 0.06) * _Event;
                if (hit) col = lerp(col, haze, 1.0 - exp(-travel * 0.5));
                else if (!outside) col = lerp(col, haze, (1.0 - exp(-travel * 0.5)) * 0.3);

                // 不透明度。外から見た空の所は 0 (透明) から始めて、煙が濃いほど不透明にする
                float alpha = (hit || !outside) ? 1.0 : 0.0;

                // 煙を重ね、炎・炎の輪・火の粉の光を足す (色は不透明度を掛けた形で持つ)
                float4 smoke = Smoke(ro, rd, tHit, fireY);
                col = col * smoke.a + smoke.rgb;
                alpha = 1.0 - (1.0 - alpha) * smoke.a;
                col += Fires(ro, rd, tHit, fireY);
                col += FrontFlames(ro, rd, tHit);
                col += Sparks(ro, rd, tHit, fireY);

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

                // ほぼ透明で光もない所は描かない (奥にある部屋の火の粉などを隠さないように、奥行きも書かない)
                // 計算が壊れた 1 ピクセル (数でない値や、無限に明るい値) があると、ブルームで画面全体が白く点滅する。
                // 最後に、色を 0〜64、不透明度を 0〜1 に収めて防ぐ (max・min は、壊れた値のときはもう片方を返す)
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
