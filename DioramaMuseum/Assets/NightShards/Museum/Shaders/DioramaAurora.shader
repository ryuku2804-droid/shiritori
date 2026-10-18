// 作品「オーロラの夜」(月の間)。凍った湖と雪の森の上で、オーロラのカーテンが揺れる。URP 用。
// Cube の中をレイマーチングして描く。Cube の座標は -0.5〜0.5、下の 0.08 は黒い台。
//
// 見どころ:
//   ・鏡のように凍った湖。白いひびと、ところどころの雪だまり。氷にオーロラが映る
//   ・湖を囲む雪の針葉樹の森と、奥の雪山
//   ・ケースの上のほうに浮かぶ、緑から紫へ色が変わるオーロラのカーテン。縦の光の筋がゆっくり流れ、すそが波打つ
//   ・雪原はオーロラの光で、ほんのり緑に染まる
// 仕掛け (_Event 0〜1): オーロラ嵐。カーテンが明るく速く大きく踊り、上のほうに赤が混ざり、雪原と森が緑に照らされる
//
// 外から見たとき、地形のない所 (空) は透明にして、ガラスケースの向こうの部屋が見えるようにする (オーロラだけが光って浮かぶ)。
// 中に入ったとき (カメラが箱の中) だけ、星空を描く
//
// _Steps / _ShadowSteps は DioramaLOD が距離で下げる。_Event / _EventTime は DioramaWork が渡す。
// _HeightTex は DioramaWork が再生の最初に作る、地形の高さの表 (なければ式で計算する)
Shader "NightShards/Diorama/Aurora"
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
            #pragma use_dxc vulkan // Quest (Vulkan) 用は新しいコンパイラー (DXC) で変換する。古いほうだと大きいシェーダーが時間切れになる
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma multi_compile_instancing

            #define ID_BASE   0.0
            #define ID_GROUND 1.0
            #define ID_ICE    2.0
            #define ID_TREE   3.0

            #define INNER 0.47
            #define ICE_Y -0.2        // 凍った湖の面の高さ
            #define TREE_CELL 0.055
            #define AURORA_LOW 0.02   // オーロラがある高さの範囲
            #define AURORA_HIGH 0.48

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

            float SdBox(float3 p, float3 b)
            {
                float3 q = abs(p) - b;
                return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
            }

            // ---------------------------------------------------------------- 地形

            float LandHeight(float2 xz)
            {
                // 真ん中に湖のくぼみ、まわりに岸、奥に丸い雪山
                float2 q = (xz - float2(0.0, -0.03)) * float2(1.0, 1.35);
                float r = length(q);
                float h = -0.24 + 0.1 * smoothstep(0.18, 0.32, r);
                float back = smoothstep(-0.15, -0.44, xz.y);
                h += 0.22 * back * (0.3 + 0.7 * Fbm3(xz * 3.0 + _Seed));
                h += 0.03 * Fbm3(xz * 6.0 + _Seed * 1.3) * smoothstep(0.25, 0.35, r);
                h += 0.006 * Fbm3(xz * 20.0 + _Seed) - 0.003;
                // ※ この式を変えたら、C# の DioramaTerrain.AuroraHeight も同じに直す (中を歩くときの地面になる)
                return h;
            }

            // 地形の高さ (速い版)。再生中は、最初に 1 回だけ計算して保存した表を読むだけ
            float HeightFast(float2 xz)
            {
                [branch] if (_HeightTexOn > 0.5)
                    return SAMPLE_TEXTURE2D_LOD(_HeightTex, sampler_linear_clamp, xz / (2.0 * INNER) + 0.5, 0).r;
                return LandHeight(xz);
            }

            // ---------------------------------------------------------------- 雪の針葉樹

            // 針葉樹 (距離)。地面をます目に分け、ます目ごとにくじを引いて 1 本立てる。湖の上には生えない
            float Spruces(float3 p, float groundH)
            {
                if (p.y - groundH > 0.11) return p.y - groundH - 0.1;
                float2 cell = floor(p.xz / TREE_CELL);
                float2 local = p.xz - (cell + 0.5) * TREE_CELL;
                float2 toEdge = 0.5 * TREE_CELL - abs(local);
                float bound = max(min(toEdge.x, toEdge.y), 0.0) + 0.003; // 隣のます目に入るまでは、この距離だけ進んでよい
                float2 id = cell + _Seed * 0.37;
                if (Hash21(id) > 0.55) return bound;
                float2 base = (cell + 0.5) * TREE_CELL + (Hash22(id + 1.3) - 0.5) * TREE_CELL * 0.5;
                if (abs(base.x) > INNER - 0.02 || abs(base.y) > INNER - 0.02) return bound;
                float by = HeightFast(base);
                if (by < ICE_Y + 0.012) return bound;
                float height = 0.045 + 0.05 * Hash21(id + 3.3);
                float3 q = p - float3(base.x, by - 0.003, base.y);
                float k = saturate(q.y / height);
                // 円すいに、枝の段のふくらみをつける
                float rad = height * 0.28 * (1.0 - k) * (0.78 + 0.22 * sin(k * 31.4)) + 0.0008;
                float d = max(length(q.xz) - rad, max(-q.y, q.y - height)) * 0.6;
                return min(d, bound);
            }

            // ---------------------------------------------------------------- 世界の形

            // 世界の形 (距離)。exact が true なら正確な地形 (地面の向きを出すとき)、false なら速い地形 (線を進めるとき)
            float2 MapX(float3 p, bool exact)
            {
                float2 res = float2(SdBox(p - float3(0, -0.46, 0), float3(0.5, 0.04, 0.5)), ID_BASE);
                float column = SdBox(p - float3(0, 0.04, 0), float3(INNER, 0.46, INNER));
                float h;
                if (exact) h = LandHeight(p.xz);
                else h = HeightFast(p.xz);
                float ground = max((p.y - h) * 0.5, column);
                if (ground < res.x) res = float2(ground, ID_GROUND);
                float tree = max(Spruces(p, h), column);
                if (tree < res.x) res = float2(tree, ID_TREE);
                float ice = max(p.y - ICE_Y, column);
                if (ice < res.x) res = float2(ice, ID_ICE);
                return res;
            }

            float2 Map(float3 p) { return MapX(p, false); }

            float3 SceneNormal(float3 p)
            {
                const float2 e = float2(0.0007, -0.0007);
                float3 g = e.xyy * MapX(p + e.xyy, true).x + e.yyx * MapX(p + e.yyx, true).x +
                           e.yxy * MapX(p + e.yxy, true).x + e.xxx * MapX(p + e.xxx, true).x;
                return g / max(length(g), 1e-7); // 0 で割らないように
            }

            float AmbientOcclusion(float3 p, float3 n)
            {
                float occ = 0.0;
                float w = 1.0;
                [loop] for (int i = 1; i <= 4; i++)
                {
                    float d = 0.01 * i;
                    occ += (d - Map(p + n * d).x) * w;
                    w *= 0.6;
                }
                return saturate(1.0 - occ * 14.0);
            }

            // ---------------------------------------------------------------- オーロラ

            // オーロラのカーテン 3 枚を、線に沿って進みながら光を足していく (オーロラは自分で光り、後ろを隠さない)
            float3 Aurora(float3 ro, float3 rd, float tMax, int steps)
            {
                float3 bmin = float3(-INNER, AURORA_LOW, -INNER);
                float3 bmax = float3(INNER, AURORA_HIGH, INNER);
                float3 inv = 1.0 / rd;
                float3 t0 = (bmin - ro) * inv, t1 = (bmax - ro) * inv;
                float3 tsmall = min(t0, t1), tbig = max(t0, t1);
                float tin = max(max(max(tsmall.x, tsmall.y), tsmall.z), 0.0);
                float tout = min(min(min(tbig.x, tbig.y), tbig.z), tMax);
                if (tout <= tin) return 0;

                float dt = (tout - tin) / steps;
                float t = tin + dt * Hash21(rd.xy * 613.0 + _Time.y);
                float tt = _Time.y * (1.0 + 2.0 * _Event); // 嵐のときは速く踊る
                float amp = 1.0 + 0.8 * _Event;
                float w = max(0.014 + 0.008 * _Event, dt * 0.5); // カーテンの厚み (粗く進むときは、取りこぼさないよう厚く)
                float3 col = 0;
                [loop] for (int s = 0; s < 64; s++)
                {
                    if (s >= steps) break;
                    float3 p = ro + rd * t;
                    for (int c = 0; c < 3; c++)
                    {
                        float fc = c;
                        // カーテンの位置: 横へ波打ちながら、ゆっくり形を変える
                        float zc = -0.1 - 0.12 * fc + (0.09 * sin(p.x * 4.0 + tt * 0.12 + fc * 2.1) + 0.035 * sin(p.x * 11.0 - tt * 0.27 + fc * 1.3)) * amp;
                        float dz = (p.z - zc) / w;
                        float band = exp(-dz * dz);
                        if (band < 0.01) continue;
                        // すそ: 下の端はくっきり、上へ行くほど薄くなる
                        float y0 = 0.1 + 0.03 * sin(p.x * 7.0 + tt * 0.4 + fc) + 0.04 * fc;
                        float yy = p.y - y0;
                        float vert = yy < 0.0 ? exp(yy / 0.008) : exp(-yy / (0.16 + 0.1 * _Event));
                        // 縦の光の筋と、カーテンを横へ走る明るさの波
                        float rays = ValueNoise(float2(p.x * 70.0 + tt * 0.6 + fc * 13.0, fc * 7.0));
                        rays = 0.25 + 1.2 * rays * rays;
                        float pulse = 0.6 + 0.4 * sin(p.x * 18.0 - tt * 1.5 + fc * 2.0);
                        // 色: すそは緑、上へ行くほど紫。嵐のときは、いちばん上に赤
                        float k = saturate(yy / 0.25);
                        float3 hue = lerp(float3(0.1, 1.0, 0.4), float3(0.55, 0.15, 0.85), k);
                        hue += float3(0.9, 0.1, 0.25) * smoothstep(0.18, 0.32, yy) * _Event;
                        float strength = c < 2 ? 1.0 : 0.4 + 0.6 * _Event;
                        col += hue * band * vert * rays * pulse * strength;
                    }
                    t += dt;
                }
                return col * dt * 60.0 * (1.0 + 2.0 * _Event);
            }

            // ---------------------------------------------------------------- 空 (中に入ったとき)

            float3 Sky(float3 rd)
            {
                float up = saturate(rd.y);
                float3 c = lerp(float3(0.01, 0.02, 0.035), float3(0.002, 0.004, 0.012), sqrt(up));
                // 天の川
                float3 axis = normalize(float3(-0.4, 0.4, 0.82));
                float bandD = dot(rd, axis) / 0.2;
                float band = exp(-bandD * bandD) * (0.5 + 0.8 * Noise3(rd * 9.0)) * smoothstep(0.0, 0.25, rd.y);
                c += float3(0.04, 0.045, 0.06) * band;
                // 星
                float3 sp = rd * 230.0;
                float3 cell = floor(sp);
                float star = step(0.992 - band * 0.01, Hash31(cell)) * smoothstep(0.25, 0.1, length(frac(sp) - 0.5));
                c += star * lerp(float3(0.7, 0.8, 1.0), float3(1.0, 0.9, 0.75), Hash31(cell + 3.0)) * smoothstep(0.02, 0.2, rd.y);
                return c;
            }

            // ---------------------------------------------------------------- 色を塗る

            float3 Shade(float3 ro, float3 rd, float3 p, float id, bool crossSection, float3 faceNormal)
            {
                // 月のない夜。光は、オーロラ (上から、緑) と星明かり
                float3 auroraLight = float3(0.04, 0.22, 0.12) * (0.6 + 1.8 * _Event);
                float3 starLight = float3(0.015, 0.02, 0.035);
                float t = _Time.y;

                if (id == ID_BASE)
                    return float3(0.015, 0.014, 0.014) + 0.03 * pow(saturate(1.0 - abs(dot(rd, faceNormal))), 4.0);

                if (crossSection)
                {
                    if (id == ID_ICE)
                    {
                        // 湖の断面: 上は厚い氷、下は暗い水
                        float depth = ICE_Y - p.y;
                        return depth < 0.012 ? float3(0.05, 0.1, 0.14) : float3(0.004, 0.01, 0.02);
                    }
                    float band = 0.5 + 0.5 * sin(p.y * 120.0 + ValueNoise(p.xz * 40.0 + p.y * 30.0) * 4.0);
                    return lerp(float3(0.03, 0.03, 0.035), float3(0.08, 0.075, 0.08), band) * 0.3;
                }

                if (id == ID_ICE)
                {
                    // 凍った湖: 鏡のようにオーロラを映す。白いひびと、ところどころの雪だまり
                    float crack = 1.0 - smoothstep(0.0, 0.035, abs(ValueNoise(p.xz * 25.0 + _Seed) - 0.5));
                    float crack2 = (1.0 - smoothstep(0.0, 0.03, abs(ValueNoise(p.xz * 70.0 + _Seed * 2.0) - 0.5))) * 0.5;
                    float snow = smoothstep(0.55, 0.75, Fbm3(p.xz * 8.0 + _Seed));
                    float2 bump = (float2(ValueNoise(p.xz * 90.0), ValueNoise(p.xz * 90.0 + 7.0)) - 0.5) * 0.02;
                    float3 n = normalize(float3(bump.x, 1.0, bump.y));
                    float3 r = reflect(rd, n);
                    float fres = 0.3 + 0.7 * pow(1.0 - saturate(dot(-rd, n)), 5.0);
                    float3 refl = Aurora(p, r, 1.0, 20) + Sky(r) * 0.6;
                    float3 c = float3(0.004, 0.01, 0.022) + refl * fres * (1.0 - snow);
                    c += (float3(0.7, 0.75, 0.82) * (auroraLight + starLight)) * snow;
                    c += float3(0.35, 0.42, 0.5) * (auroraLight + starLight) * max(crack, crack2) * (1.0 - snow);
                    return c;
                }

                float3 n = SceneNormal(p);
                float ao = AmbientOcclusion(p, n);
                float sky = 0.4 + 0.6 * saturate(n.y);

                if (id == ID_TREE)
                {
                    // 雪をかぶった針葉樹: 上を向いた所に雪、そのほかは暗い緑
                    float snow = smoothstep(0.25, 0.6, n.y + 0.3 * ValueNoise(p.xz * 300.0 + p.y * 200.0) - 0.15);
                    float3 albedo = lerp(float3(0.012, 0.028, 0.02), float3(0.7, 0.74, 0.8), snow);
                    return albedo * (auroraLight + starLight) * sky * ao * 1.6;
                }

                // 雪原と雪山: ほとんど雪。切り立った所だけ岩が出る
                float rock = smoothstep(0.75, 0.55, n.y);
                float3 albedo = lerp(float3(0.75, 0.79, 0.86), float3(0.04, 0.04, 0.045), rock);
                float3 c = albedo * (auroraLight + starLight) * sky * ao * 1.6;
                // 雪のきらめき (オーロラの光で)
                float3 cell = floor(p * 1800.0);
                c += step(0.988, Hash31(cell)) * (1.0 - rock) * (0.15 + 0.6 * _Event) * float3(0.4, 1.0, 0.6);
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

                // 山と木より上の何もない空間は飛ばす (オーロラは別に計算する)
                const float maxHeight = 0.21;
                if (ro.y > maxHeight && rd.y < 0.0) t = max(t, (maxHeight - ro.y) / rd.y);

                bool hit = false;
                float id = 0.0;
                int steps = (int)_Steps;
                [loop] for (int i = 0; i < 200; i++)
                {
                    if (i >= steps || t > box.y) break;
                    float3 pos = ro + rd * t;
                    if (rd.y > 0.0 && pos.y > maxHeight + 0.01) break; // 山より上に出て上を向いている線は、もう何にも当たらない
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
                    // 当たった所を、正確な地形で 2 回だけ合わせ直す
                    for (int r = 0; r < 2; r++) t += MapX(ro + rd * t, true).x;
                }
                float tHit = hit ? t : box.y;

                float3 col = 0;
                if (hit)
                {
                    float3 p = ro + rd * t;
                    bool crossSection = outside && (abs(p.x) > INNER - 0.002 || abs(p.z) > INNER - 0.002);
                    col = Shade(ro, rd, p, id, crossSection, faceNormal);
                }
                else if (!outside)
                {
                    col = Sky(rd); // 中に入っているときだけ、星空を描く
                }

                // 霞: 遠くほど、夜の空気に沈む (オーロラの光で、ほんのり緑)
                float travel = tHit - max(box.x, 0.0);
                float3 haze = float3(0.006, 0.016, 0.018) + float3(0.0, 0.02, 0.01) * _Event;
                if (hit) col = lerp(col, haze, 1.0 - exp(-travel * 0.5));

                float alpha = (hit || !outside) ? 1.0 : 0.0;

                // オーロラの光を足す (外から見た空の所では、透明のまま光だけが浮かぶ)
                col += Aurora(ro, rd, tHit, clamp(steps / 3, 24, 56));

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
