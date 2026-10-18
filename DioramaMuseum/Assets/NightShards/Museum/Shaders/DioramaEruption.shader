// 作品「大噴火」(火の間)。夜の海に浮かぶ火山島。URP 用。
// Cube の中をレイマーチングして描く。Cube の座標は -0.5〜0.5、下の 0.08 は黒い台。
//
// 見どころ:
//   ・雨で削られた谷が放射状に走る火山の山肌と、火口の溶岩だまり
//   ・山腹を流れ下る、厚みのある溶岩 (表面は冷えて黒い皮、割れ目から赤く光り、模様が流れに乗って下る)
//   ・溶岩は海に入ると扇のように広がり、そこから湯気の柱が立ちのぼる (立体的な雲)
//   ・火口から立ちのぼる噴煙 (立体的な雲)。下から溶岩に赤く照らされ、中で火山雷が光る
//   ・放物線を描いて飛ぶ、球の形をした噴石。割れ目から赤く光り、光の尾を引く
//   ・夜の海: 波打ち際の白い泡、島と溶岩の光を映す水面
// 仕掛け (_Event 0〜1): 大噴火。噴煙が高く昇って傘のように広がり、噴石が飛び、溶岩がゆっくり山を下って海まで届き、雷が増える
//
// 外から見たとき、地形のない所 (空) は透明にして、ガラスケースの向こうの部屋が見えるようにする。
// 中に入ったとき (カメラが箱の中) だけ、空を描く
//
// _Steps / _ShadowSteps は DioramaLOD が距離で下げる。_Event / _EventTime は DioramaWork が渡す
Shader "NightShards/Diorama/Eruption"
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
            #define ID_WATER  2.0
            #define ID_LAVA   3.0
            #define BOMBS 22

            #define INNER 0.47
            #define BASE_TOP -0.42
            #define WATER -0.22
            static const float3 CRATER = float3(0.02, 0.11, -0.03);
            static const float3 MOON_DIR = float3(-0.55, 0.62, 0.56); // 正規化は使う所で

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

            // ---------------------------------------------------------------- 地形

            float Height(float2 xz)
            {
                float2 c = xz - CRATER.xz;
                float r = length(c);
                float th = atan2(c.y, c.x);
                float h = -0.40 + 0.58 * exp(-pow(r / 0.25, 1.7));
                // 雨で削られた谷: 火口から放射状に、尾根と谷がくり返す
                float gully = 1.0 - abs(sin(th * 9.0 + Fbm3(float2(r * 9.0, th * 2.0) + _Seed) * 3.0));
                h += 0.022 * gully * gully * smoothstep(0.03, 0.12, r) * exp(-r * 2.5);
                // 火口のくぼみと、その縁
                h -= 0.075 * exp(-pow(r / 0.045, 2.0));
                h += 0.012 * exp(-pow((r - 0.055) / 0.015, 2.0));
                // 細かい起伏
                h += 0.012 * Fbm3(xz * 14.0 + _Seed) - 0.006;
                // 岩肌の細かい尾根 (陸の上だけ)。中に入って歩いたときに、足元の地面がごつごつして見える
                float rid = 1.0 - abs(ValueNoise(xz * 38.0 + _Seed * 1.7) * 2.0 - 1.0);
                float rid2 = 1.0 - abs(ValueNoise(xz * 81.0 + _Seed * 2.3 + 7.0) * 2.0 - 1.0);
                h += (0.006 * rid * rid + 0.0025 * rid2 * rid2) * smoothstep(-0.25, -0.15, h);
                // ※ この式を変えたら、C# の DioramaTerrain.EruptionHeight も同じに直す (中を歩くときの地面になる)
                return h;
            }

            // 地形の高さ (速い版)。再生中は、DioramaWork が最初に 1 回だけ計算して保存した高さの表 (_HeightTex) を読むだけ。
            // 表がないとき (編集中など) は、式で計算する。地面の向きや色を決める所では、正確な Height を使う
            float HeightFast(float2 xz)
            {
                [branch] if (_HeightTexOn > 0.5)
                    return SAMPLE_TEXTURE2D_LOD(_HeightTex, sampler_linear_clamp, xz / (2.0 * INNER) + 0.5, 0).r;
                return Height(xz);
            }

            // ---------------------------------------------------------------- 溶岩の流れ

            // 流れ k 番の伸び具合 (0〜1)。噴火が始まってからの時間で、先端がゆっくり山を下り、海まで届く
            float FlowGrow(float fk)
            {
                return _Event > 0.001 ? saturate((_EventTime - 0.8 - fk * 1.3) / 7.0) : 0.0;
            }

            // 流れ k 番の先端が、火口からどこまで来ているか
            float FlowReach(float fk)
            {
                return lerp(0.11 + 0.05 * Hash11(fk + 3.0), 0.44, FlowGrow(fk));
            }

            // 流れ k 番が、火口から r の所でどの向きにあるか (谷に沿って、くねくね曲がる)
            float FlowAngle(float fk, float r)
            {
                float baseAngle = 0.6 + fk * 2.05 + Hash11(fk + _Seed) * 0.6;
                return baseAngle + 0.22 * sin(r * 24.0 + fk * 1.7) + 0.08 * sin(r * 61.0 + fk);
            }

            struct Lava
            {
                float mask;   // どれだけ流れの上か (0〜1)
                float heat;   // 熱さ (0〜1)。火口と、進んでいる先端が熱い
                float along;  // 火口からの距離 (流れに沿った向き)
                float side;   // 流れの中心線からの距離 (流れを横切る向き)
                float thick;  // 溶岩の厚み
            };

            // xz の所の溶岩。widthScale を広げると、流れのまわりの照り返しに使える
            Lava LavaAt(float2 xz, float widthScale)
            {
                Lava L = (Lava)0;
                float2 c = xz - CRATER.xz;
                float r = length(c);
                float th = atan2(c.y, c.x);
                L.along = r;
                for (int k = 0; k < 3; k++)
                {
                    float fk = k;
                    float grow = FlowGrow(fk);
                    float reach = FlowReach(fk);
                    float angle = FlowAngle(fk, r);
                    float d = atan2(sin(th - angle), cos(th - angle)) * r; // 流れの中心線までの距離
                    float spread = 1.0 + 7.0 * max(0.0, r - 0.25);       // 海岸の先では、扇のように広がる
                    float w = (0.008 + 0.004 * Hash11(fk + 7.0)) * widthScale * (1.0 + r * 3.0) * spread;
                    // 先端はまっすぐではなく、指のような舌がいくつも出る (ねばりけのある溶岩の先端)
                    float toes = (ValueNoise(float2(d / w * 1.3 + fk * 13.0, _Time.y * 0.03 + fk)) - 0.5) * 0.03 * spread;
                    float front = reach + toes;
                    float mk = exp(-(d * d) / (w * w)) * smoothstep(0.04, 0.06, r) * smoothstep(front, front - 0.02, r);
                    if (mk > L.mask)
                    {
                        L.mask = mk;
                        L.side = d;
                        float cool = 1.0 - r / max(reach, 0.01) * 0.65;                    // 火口から離れるほど冷える
                        float fresh = smoothstep(front - 0.035, front - 0.008, r) * grow; // 進んでいる先端は、中の溶岩がのぞいて熱い
                        float fade = lerp(1.0, saturate(_Event * 1.5), grow);             // 噴火がおさまると、伸びた流れから冷えていく
                        L.heat = saturate(cool + fresh * 0.8) * fade;
                    }
                }
                // 火口の溶岩だまり
                float lake = smoothstep(0.042, 0.03, r);
                if (lake > L.mask)
                {
                    L.mask = lake;
                    L.heat = 1.0;
                }
                // 厚み: 表面のふくらみが、流れに乗ってゆっくり下っていく
                float bulge = ValueNoise(float2(r * 90.0 - _Time.y * 0.15, L.side * 120.0));
                L.thick = L.mask * (0.004 + 0.003 * bulge);
                return L;
            }

            // 溶岩の光る色 (黒体の色: 熱いほど黄色、冷めると暗い赤)
            float3 LavaColor(float heat)
            {
                float3 cool = float3(0.5, 0.04, 0.01);
                float3 hot = float3(4.5, 1.4, 0.25);
                return lerp(cool, hot, heat * heat) * heat;
            }

            // ---------------------------------------------------------------- 世界の形

            // 世界の形 (距離)。exact が true なら正確な地形 (地面の向きを出すとき)、false なら速い地形 (線を進めるとき)
            float2 MapX(float3 p, bool exact)
            {
                float2 res = float2(SdBox(p - float3(0, -0.46, 0), float3(0.5, 0.04, 0.5)), ID_BASE);
                float column = SdBox(p - float3(0, 0.04, 0), float3(INNER, 0.46, INNER));
                float h;
                if (exact) h = Height(p.xz);
                else h = HeightFast(p.xz);
                float ground = max((p.y - h) * 0.5, column);
                if (ground < res.x) res = float2(ground, ID_GROUND);
                float water = max(p.y - WATER, column);
                if (water < res.x) res = float2(water, ID_WATER);
                // 溶岩: 地面 (海の上では水面) の上に、厚み数 mm の流れを盛る。地面から離れた所では計算を省く
                float floorY = max(h, WATER - 0.002);
                float lava = (p.y - floorY - 0.009) * 0.5;
                if (lava < 0.004)
                {
                    Lava L = LavaAt(p.xz, 1.0);
                    lava = (p.y - (floorY + L.thick - 0.001)) * 0.5;
                }
                lava = max(lava, column);
                if (lava < res.x) res = float2(lava, ID_LAVA);
                return res;
            }

            float2 Map(float3 p) { return MapX(p, false); }

            float3 SceneNormal(float3 p)
            {
                const float2 e = float2(0.0009, -0.0009);
                float3 g = e.xyy * MapX(p + e.xyy, true).x + e.yyx * MapX(p + e.yyx, true).x +
                           e.yxy * MapX(p + e.yxy, true).x + e.xxx * MapX(p + e.xxx, true).x;
                // 平らすぎて向きが決まらない所でも壊れないように (0 で割ると、画面が白く点滅する原因になる)
                return g / max(length(g), 1e-7);
            }

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
                    if (res < 0.01 || t > 1.0) break;
                }
                return saturate(res);
            }

            // くぼみの暗がり: 法線の方向へ少しずつ離れながら、まわりの地形の近さを調べる
            float AmbientOcclusion(float3 p, float3 n)
            {
                if (_DioramaLite > 0.5) return 1.0; // Quest では省く
                float occ = 0.0;
                float w = 1.0;
                [loop] for (int i = 1; i <= 4; i++)
                {
                    float d = 0.012 * i;
                    occ += (d - Map(p + n * d).x) * w;
                    w *= 0.6;
                }
                return saturate(1.0 - occ * 14.0);
            }

            // ---------------------------------------------------------------- 雷・噴石

            // 雷: 時刻を細かく区切り、区切りごとにくじを引いて光らせる。噴火中ほど当たりやすい
            float Lightning(out float3 pos)
            {
                float slot = floor(_Time.y * 9.0);
                float chance = 0.02 + _Event * 0.22;
                float on = step(1.0 - chance, Hash11(slot + _Seed * 13.0));
                float fade = 1.0 - frac(_Time.y * 9.0);
                float hgt = lerp(0.14, 0.33, _Event);
                pos = CRATER + float3((Hash11(slot + 1.3) - 0.5) * 0.09, 0.06 + Hash11(slot + 2.7) * hgt, (Hash11(slot + 4.1) - 0.5) * 0.09);
                return on * fade;
            }

            // ---------------------------------------------------------------- 噴石

            // 噴石 i 番の、back 秒前の位置・大きさ・熱さ。飛んでいなければ false。
            // 噴石は飛ぶたびに向きと勢いを変える。ふだんも 3 つだけ、ときどき小さく上がる
            bool BombAt(int i, float back, out float3 pos, out float radius, out float heat)
            {
                float fi = i;
                pos = 0;
                radius = 0;
                heat = 0;
                float active = i < 3 ? max(_Event, 0.5) : _Event;
                if (active < 0.02) return false;
                float h1 = Hash11(fi * 3.1 + 0.5), h2 = Hash11(fi * 5.7 + 1.5), h3 = Hash11(fi * 7.3 + 2.5);
                float period = 1.6 + h1 * 1.2;
                float cycle = floor(_Time.y / period + h2);
                if (i < 3 && _Event < 0.02 && Hash11(cycle * 0.71 + fi) < 0.6) return false; // ふだんは、ときどきだけ
                float ft = frac(_Time.y / period + h2) * period - back;
                if (ft < 0.0) return false;
                float a = Hash11(cycle * 1.37 + fi) * 6.2831;
                float spd = (0.04 + 0.16 * h3) * (0.6 + 0.6 * active);
                float vy = (0.45 + 0.3 * Hash11(cycle + fi * 2.1)) * (0.75 + 0.35 * active);
                pos = CRATER + float3(0, 0.01, 0) + float3(cos(a) * spd, vy, sin(a) * spd) * ft + float3(0, -0.55 * ft * ft, 0);
                if (pos.y < WATER) return false;
                radius = (0.003 + 0.004 * h3) * (i < 3 ? 0.7 : 1.0);
                heat = saturate(1.0 - ft * 0.35) * active;
                return true;
            }

            int BombCount() { return _Event > 0.02 ? BOMBS : 3; }

            // 線が噴石に当たるか。当たったら、その距離を返し、色を bcol に入れる (当たらなければ tMax)
            float BombHit(float3 ro, float3 rd, float tMax, out float3 bcol)
            {
                float best = tMax;
                bcol = 0;
                int count = BombCount();
                [loop] for (int i = 0; i < BOMBS; i++)
                {
                    if (i >= count) break;
                    float3 c;
                    float rad, heat;
                    if (!BombAt(i, 0.0, c, rad, heat)) continue;
                    float3 oc = ro - c;
                    float b = dot(oc, rd);
                    float disc = b * b - (dot(oc, oc) - rad * rad);
                    if (disc < 0.0) continue;
                    float t = -b - sqrt(disc);
                    if (t < 0.0 || t >= best) continue;
                    if (c.y < HeightFast(c.xz)) continue; // もう地面に落ちた
                    best = t;
                    // 黒く冷えた岩の皮が割れて、中の赤い溶岩がのぞく
                    float3 n = normalize(ro + rd * t - c);
                    float crack = 1.0 - smoothstep(0.0, 0.2, abs(Noise3(n * 6.0 + i * 3.7) - 0.5) * 2.0);
                    float3 crust = float3(0.03, 0.026, 0.025) * (0.3 + saturate(dot(n, normalize(MOON_DIR))));
                    float rim = pow(1.0 - saturate(dot(-rd, n)), 3.0);
                    bcol = crust + LavaColor(heat) * (0.15 + crack * 1.3 + rim * 0.4);
                }
                return best;
            }

            // 噴石のまわりの光と、飛んできた跡に残る光の尾
            float3 BombTrails(float3 ro, float3 rd, float tMax)
            {
                float3 col = 0;
                int count = BombCount();
                [loop] for (int i = 0; i < BOMBS; i++)
                {
                    if (i >= count) break;
                    float3 c;
                    float rad, heat;
                    if (!BombAt(i, 0.0, c, rad, heat)) continue;
                    float3 w = c - ro;
                    float tc = dot(w, rd);
                    if (tc < 0.0 || tc > tMax) continue;
                    float d2 = dot(w, w) - tc * tc;
                    if (d2 > 0.0036) continue;          // 線から遠い噴石は飛ばす (尾の長さより遠い)
                    if (c.y < HeightFast(c.xz)) continue;
                    float3 hot = LavaColor(heat);
                    col += hot * 0.35 * exp(-d2 / (rad * rad * 12.0));
                    [loop] for (int j = 1; j <= 5; j++)
                    {
                        float3 q;
                        float qr, qh;
                        if (!BombAt(i, j * 0.035, q, qr, qh)) break;
                        float3 wq = q - ro;
                        float tq = dot(wq, rd);
                        if (tq < 0.0 || tq > tMax) continue;
                        float dq = dot(wq, wq) - tq * tq;
                        col += hot * 0.5 * (1.0 - j / 6.0) * exp(-dq / (qr * qr * 0.6));
                    }
                }
                return col;
            }

            // ---------------------------------------------------------------- 噴煙 (立体的な雲)

            float PlumeHeight() { return lerp(0.16, 0.36, _Event); }

            // 溶岩が海に入る所 (xy = 場所、z = 湯気の強さ)。流れが海岸 (火口から約 0.27) を越えたら湯気が立つ
            void SteamSources(out float4 steam[3])
            {
                const float coast = 0.27;
                for (int k = 0; k < 3; k++)
                {
                    float fk = k;
                    float a = FlowAngle(fk, coast);
                    float s = smoothstep(coast - 0.01, coast + 0.03, FlowReach(fk)) * (0.35 + 0.65 * saturate(_Event * 1.5));
                    steam[k] = float4(CRATER.xz + float2(cos(a), sin(a)) * coast, s, 0);
                }
            }

            // 雲の濃さ。x = 噴煙 (火山灰)、y = 湯気
            float2 PlumeDensity(float3 p, float4 steam[3])
            {
                float2 dens = 0;
                float t = _Time.y;

                // 噴煙: 火口から昇る柱。上へ行くほど太り、てっぺんでは傘のように横へ大きく広がる (噴火中)
                float y = p.y - CRATER.y;
                float height = PlumeHeight();
                if (y > -0.01 && y < height + 0.02)
                {
                    float3 q = p - float3(CRATER.x, 0.0, CRATER.z);
                    q.x -= y * y * 1.4 * (1.0 - _Event * 0.6); // 風で少したなびく
                    float umbrella = smoothstep(height * 0.5, height * 0.92, y);
                    float rad = 0.022 + y * lerp(0.3, 0.42, _Event) + umbrella * lerp(0.05, 0.3, _Event);
                    float shape = saturate(1.0 - length(q.xz) / rad) * smoothstep(height + 0.01, height * 0.82, y); // 傘の上は平ら
                    // もくもく: 柱の中では上へ、傘の中では外へ向かって流れる
                    float2 outward = q.xz / max(length(q.xz), 0.001) * umbrella * t * 0.02;
                    float3 np = float3(q.x - outward.x, y - t * lerp(0.05, 0.12, _Event) * (1.0 - umbrella * 0.7), q.z - outward.y) * 24.0;
                    float n = Noise3(np) * 0.55 + Noise3(np * 2.1 + 5.3) * 0.3 + Noise3(np * 4.3 + 9.1) * 0.15;
                    dens.x = max(0.0, shape * 1.35 + n * 0.9 - 0.92) * 70.0;
                }

                // 湯気: 溶岩が海に入る所から、白い柱が立って風下へ流れる
                float sy = p.y - WATER;
                if (sy > 0.0 && sy < 0.17)
                {
                    for (int k = 0; k < 3; k++)
                    {
                        if (steam[k].z < 0.01) continue;
                        float2 sq = p.xz - steam[k].xy;
                        sq.x -= sy * sy * 3.0;
                        float srad = 0.014 + sy * 0.35;
                        float s = saturate(1.0 - length(sq) / srad) * smoothstep(0.17, 0.05, sy);
                        if (s <= 0.0) continue;
                        float3 sp = float3(sq.x, sy - t * 0.05, sq.y) * 40.0;
                        float sn = Noise3(sp) * 0.6 + Noise3(sp * 2.2 + 3.1) * 0.4;
                        dens.y += max(0.0, s * 1.3 + sn * 0.8 - 0.85) * 40.0 * steam[k].z;
                    }
                }
                return dens;
            }

            // 線のうち雲のある箱の中の区間を、前から順に進みながら色を足す (前にある雲ほど、後ろを隠す)
            float4 Plume(float3 ro, float3 rd, float tMax, float3 flashPos, float flash)
            {
                float4 steam[3];
                SteamSources(steam);
                float height = PlumeHeight();
                float3 bmin = float3(-INNER, WATER, -INNER);
                float3 bmax = float3(INNER, CRATER.y + height + 0.03, INNER);
                float3 inv = 1.0 / rd;
                float3 t0 = (bmin - ro) * inv, t1 = (bmax - ro) * inv;
                float3 tsmall = min(t0, t1), tbig = max(t0, t1);
                float tin = max(max(max(tsmall.x, tsmall.y), tsmall.z), 0.0);
                float tout = min(min(min(tbig.x, tbig.y), tbig.z), tMax);
                if (tout <= tin) return float4(0, 0, 0, 1);

                int steps = clamp((int)(_Steps / 4.0), 10, 48);
                float dt = (tout - tin) / steps;
                float t = tin + dt * Hash21(rd.xy * 517.0 + _Time.y); // 少しずらして縞を消す
                float3 col = 0;
                float trans = 1.0;
                [loop] for (int i = 0; i < 48; i++)
                {
                    if (i >= steps) break;
                    float3 p = ro + rd * t;
                    float2 dens = PlumeDensity(p, steam);
                    float total = dens.x + dens.y;
                    if (total > 0.0)
                    {
                        float3 flashLight = float3(2.5, 2.8, 4.0) * flash * 8.0 * exp(-length(p - flashPos) * 22.0);
                        float3 light = flashLight;
                        if (dens.x > 0.0)
                        {
                            float y = p.y - CRATER.y;
                            float above = PlumeDensity(p + float3(0.0, 0.03, 0.0), steam).x; // 少し上の濃さ = 月の光をさえぎる量
                            float3 ash = float3(0.035, 0.032, 0.032) + float3(0.1, 0.12, 0.17) * exp(-above * 0.035);
                            float3 lavaLight = float3(1.6, 0.45, 0.08) * exp(-y * 9.0) * (1.0 + 2.5 * _Event);
                            light += (ash + lavaLight) * dens.x / total;
                        }
                        if (dens.y > 0.0)
                        {
                            float sy = p.y - WATER;
                            float3 white = float3(0.13, 0.14, 0.17) + float3(1.3, 0.42, 0.1) * exp(-sy * 25.0) * (0.5 + _Event); // 下から溶岩に照らされる
                            light += white * dens.y / total;
                        }
                        float a = 1.0 - exp(-total * dt);
                        col += trans * a * light;
                        trans *= 1.0 - a;
                        if (trans < 0.02) break;
                    }
                    t += dt;
                }
                return float4(col, trans);
            }

            // ---------------------------------------------------------------- 空

            float3 Sky(float3 rd)
            {
                float up = saturate(rd.y);
                float3 c = lerp(float3(0.03, 0.012, 0.016), float3(0.004, 0.006, 0.018), sqrt(up));
                c += float3(0.3, 0.07, 0.02) * pow(1.0 - up, 5.0) * (0.5 + _Event); // 地平線の赤い照り返し
                float2 sp = rd.xz / max(rd.y, 0.05) * 70.0;
                float star = step(0.996, Hash21(floor(sp))) * smoothstep(0.1, 0.4, rd.y) * (1.0 - _Event * 0.7);
                // 月: 噴煙の赤い空にかかる、少し欠けた月と、そのまわりの淡い光の輪
                float3 md = normalize(MOON_DIR);
                float mc = dot(rd, md);
                float disc = smoothstep(0.99955, 0.99975, mc);
                float shade = smoothstep(0.0, 0.004, dot(rd - md * mc, normalize(float3(0.6, 0.2, -0.4))) + 0.006);
                float3 moon = float3(1.6, 1.55, 1.4) * disc * lerp(0.15, 1.0, shade);
                float halo = pow(saturate(mc), 400.0) * 0.25 + pow(saturate(mc), 40.0) * 0.04;
                return c + star * 0.6 + moon + float3(0.5, 0.55, 0.7) * halo;
            }

            // ---------------------------------------------------------------- 水面の映り込み

            // 水面で反射した線を、地形だけを相手にもう一度進める。島が当たれば暗い岩肌と溶岩の光、当たらなければ空
            float3 Reflection(float3 p, float3 r, float3 craterCol)
            {
                float t = 0.004;
                [loop] for (int i = 0; i < 40; i++)
                {
                    float3 q = p + r * t;
                    if (abs(q.x) > INNER || abs(q.z) > INNER || q.y > 0.5) break;
                    float d = (q.y - HeightFast(q.xz)) * 0.5;
                    if (d < 0.0006)
                    {
                        Lava L = LavaAt(q.xz, 1.0);
                        float3 toC = CRATER - q;
                        float3 c = float3(0.012, 0.011, 0.012) + craterCol * 0.12 / (1.0 + dot(toC, toC) * 90.0);
                        return c + LavaColor(L.heat) * L.mask * 0.8;
                    }
                    t += max(d, 0.002);
                }
                return Sky(r);
            }

            // ---------------------------------------------------------------- 色を塗る

            float3 Shade(float3 ro, float3 rd, float3 p, float id, bool crossSection, float3 faceNormal, float3 flashPos, float flash)
            {
                float3 moonDir = normalize(MOON_DIR);
                float3 moonCol = float3(0.32, 0.4, 0.62);
                float3 skyAmb = float3(0.015, 0.018, 0.03);
                float h = Height(p.xz);

                if (id == ID_BASE)
                    return float3(0.015, 0.014, 0.014) + 0.03 * pow(saturate(dot(reflect(rd, faceNormal), moonDir)), 8.0);

                if (crossSection && (id == ID_GROUND || id == ID_LAVA))
                {
                    // 断面: 何層も重なった溶岩の地層。真ん中の深い所に、赤いマグマの通り道
                    float band = 0.5 + 0.5 * sin(p.y * 110.0 + ValueNoise(p.xz * 40.0 + p.y * 30.0) * 4.0);
                    float3 rock = lerp(float3(0.06, 0.05, 0.05), float3(0.13, 0.1, 0.09), band);
                    float conduit = exp(-pow(length(p.xz - CRATER.xz) / 0.03, 2.0));
                    return rock * 0.25 + float3(3.0, 0.6, 0.08) * conduit * (0.6 + 0.4 * _Event);
                }
                if (crossSection && id == ID_WATER)
                {
                    float depth = WATER - p.y;
                    return lerp(float3(0.01, 0.025, 0.03), float3(0.002, 0.006, 0.01), saturate(depth * 8.0));
                }

                // 火口の光 (噴火中は強く、ゆらめく)
                float flicker = 0.85 + 0.15 * sin(_Time.y * 13.0) * sin(_Time.y * 7.3);
                float3 craterLightPos = CRATER + float3(0, 0.02, 0);
                float3 toCrater = craterLightPos - p;
                float craterAtten = 1.0 / (1.0 + dot(toCrater, toCrater) * 90.0);
                float3 craterCol = float3(1.0, 0.33, 0.07) * (0.6 + 3.0 * _Event) * flicker;

                if (id == ID_WATER)
                {
                    // 夜の海: 小さな波で向きを揺らし、空・噴煙の赤・溶岩の光を映す
                    float t = _Time.y;
                    float2 q = p.xz * 70.0;
                    float3 n = normalize(float3((ValueNoise(q + t * 0.8) - 0.5) * 0.2, 1.0, (ValueNoise(q.yx * 1.3 - t) - 0.5) * 0.2));
                    float3 r = reflect(rd, n);
                    float fres = 0.02 + 0.98 * pow(1.0 - saturate(dot(-rd, n)), 5.0);
                    float3 refl = Reflection(p, r, craterCol) + craterCol * pow(saturate(dot(r, normalize(toCrater))), 18.0) * 0.6;
                    float depth = WATER - h;
                    float3 body = lerp(float3(0.01, 0.03, 0.035), float3(0.002, 0.006, 0.012), saturate(depth * 12.0));
                    float3 c = lerp(body, refl, fres);
                    c += moonCol * pow(saturate(dot(r, moonDir)), 200.0) * 2.0;

                    // 波打ち際の白い泡: 浅い所で、岸へ寄せる波の縞
                    float foam = smoothstep(0.018, 0.0, depth) * (0.55 + 0.45 * sin(t * 2.2 - depth * 420.0 + ValueNoise(p.xz * 90.0) * 4.0));
                    c += foam * (moonCol * 0.6 + craterCol * craterAtten * 2.0 + 0.04);

                    // 溶岩が海に入る所: まわりの水面が赤く照り、水面すれすれに湯気がはう
                    Lava W = LavaAt(p.xz, 3.5);
                    c += float3(1.4, 0.35, 0.07) * W.mask * (0.3 + W.heat) * (0.4 + _Event);
                    float steam = W.mask * ValueNoise(p.xz * 60.0 + float2(0, -t * 0.6));
                    c += float3(0.35, 0.3, 0.3) * steam * (0.3 + _Event);
                    return c;
                }

                if (id == ID_LAVA)
                {
                    // 溶岩: 冷えた黒い皮が割れて、中の赤い溶岩がのぞく。割れ目の模様は流れに乗って、ゆっくり山を下る
                    Lava L = LavaAt(p.xz, 1.0);
                    float3 n = SceneNormal(p);
                    float2 uv = float2((L.along - _Time.y * (0.004 + 0.008 * _Event)) * 150.0, L.side * 150.0);
                    float crack = 1.0 - smoothstep(0.0, 0.14, abs(ValueNoise(uv) - 0.5) * 2.0);
                    float crack2 = 1.0 - smoothstep(0.0, 0.1, abs(ValueNoise(uv * 2.3 + 11.0) - 0.5) * 2.0);
                    float open = max(crack, crack2 * 0.6);
                    open = lerp(open, 1.0, smoothstep(0.8, 1.0, L.heat)); // とても熱い所 (火口・進む先端) は皮がなく、全体が光る
                    float3 crust = float3(0.022, 0.018, 0.018);
                    float3 c = crust * (moonCol * saturate(dot(n, moonDir)) + skyAmb) + crust * craterCol * craterAtten * 3.0;
                    float3 r = reflect(rd, n);
                    c += moonCol * pow(saturate(dot(r, moonDir)), 60.0) * 0.3 * (1.0 - open); // ガラス質の皮の照り
                    c += LavaColor(L.heat) * (0.1 + open) * saturate(L.mask * 1.5) * (1.0 + 0.6 * _Event);
                    c += float3(0.6, 0.7, 1.0) * crust * flash * 0.6 * exp(-length(p - flashPos) * 4.0);
                    return c;
                }

                // 地面
                float3 n = SceneNormal(p);
                float sh = SoftShadow(p + n * 0.002, moonDir);
                float ao = AmbientOcclusion(p, n);

                float slope = 1.0 - n.y;
                float3 basalt = lerp(float3(0.045, 0.04, 0.04), float3(0.09, 0.08, 0.075), Fbm3(p.xz * 30.0));
                float3 green = float3(0.035, 0.06, 0.03) * (0.7 + 0.6 * ValueNoise(p.xz * 50.0));
                float3 sand = float3(0.07, 0.06, 0.055);
                float vegetation = smoothstep(-0.05, -0.15, h) * (1.0 - smoothstep(0.3, 0.6, slope));
                float3 albedo = lerp(basalt, green, vegetation * 0.8);
                albedo = lerp(albedo, sand, smoothstep(WATER + 0.02, WATER + 0.004, h));
                albedo = lerp(albedo, float3(0.11, 0.1, 0.1), smoothstep(0.02, 0.1, h) * 0.6); // 山頂の灰

                Lava G = LavaAt(p.xz, 4.0); // まわりの溶岩

                float3 c = albedo * (moonCol * saturate(dot(n, moonDir)) * sh + skyAmb * (0.5 + 0.5 * n.y)) * ao;
                c += albedo * craterCol * craterAtten * saturate(dot(n, normalize(toCrater)) * 0.7 + 0.3);
                c += albedo * float3(1.0, 0.3, 0.06) * G.mask * G.heat * 2.0;                     // 流れのまわりの照り返し
                c += albedo * float3(0.6, 0.7, 1.0) * flash * 0.6 * exp(-length(p - flashPos) * 4.0); // 雷の閃光
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

                // 地形より上の何もない空間は飛ばす (噴煙は別に計算する)
                const float maxHeight = 0.2;
                if (ro.y > maxHeight && rd.y < 0.0) t = max(t, (maxHeight - ro.y) / rd.y);

                bool hit = false;
                float id = 0.0;
                int steps = (int)_Steps;
                [loop] for (int i = 0; i < 200; i++)
                {
                    if (i >= steps || t > box.y) break;
                    float3 pos = ro + rd * t;
                    if (rd.y > 0.0 && pos.y > maxHeight + 0.01) break; // 地形より上に出て上を向いている線は、もう何にも当たらない
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
                    // 当たった所を、正確な地形で 2 回だけ合わせ直す (速い地形との小さなずれをなくす)
                    for (int r = 0; r < 2; r++) t += MapX(ro + rd * t, true).x;
                }
                float tHit = hit ? t : box.y;

                float3 flashPos;
                float flash = Lightning(flashPos);

                // 噴石: 地形より手前にあれば、そちらが見える
                float3 bombCol;
                float tBomb = BombHit(ro, rd, tHit, bombCol);
                bool bomb = tBomb < tHit;

                // 何かに当たったか。外から見て何にも当たらない所 (ケースの中の空) は透明にする
                bool solid = hit || bomb;
                float3 col = 0;
                if (bomb)
                {
                    col = bombCol;
                    tHit = tBomb;
                }
                else if (hit)
                {
                    float3 p = ro + rd * t;
                    bool crossSection = outside && (abs(p.x) > INNER - 0.002 || abs(p.z) > INNER - 0.002);
                    col = Shade(ro, rd, p, id, crossSection, faceNormal, flashPos, flash);
                }
                else if (!outside)
                {
                    col = Sky(rd); // 中に入っているときだけ、空を描く
                }

                // 霞: 線がケースの中を進んだ距離が長いほど、空気の色に沈める
                float travel = tHit - max(box.x, 0.0);
                float3 haze = lerp(float3(0.012, 0.012, 0.02), float3(0.1, 0.035, 0.015), 0.35 + 0.65 * _Event);
                if (solid) col = lerp(col, haze, 1.0 - exp(-travel * 0.45));
                else if (!outside) col = lerp(col, haze, (1.0 - exp(-travel * 0.45)) * 0.3);

                // 不透明度。外から見た空の所は 0 (透明) から始めて、噴煙が濃いほど不透明にする
                float alpha = (solid || !outside) ? 1.0 : 0.0;

                // 噴煙と湯気を重ね、噴石の光の尾を足す (色は不透明度を掛けた形で持つ)
                float4 plume = Plume(ro, rd, tHit, flashPos, flash);
                col = col * plume.a + plume.rgb;
                alpha = 1.0 - (1.0 - alpha) * plume.a;
                col += BombTrails(ro, rd, tHit);

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
