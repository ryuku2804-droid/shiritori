// 美術館の床・壁・天井・台座の質感 (URP 用)。テクスチャ画像は使わず、ワールド座標からノイズで模様を作る。
// _Kind で種類を切り替える: 0 打ち放しコンクリート / 1 木の床 / 2 石 (研ぎ出し) / 3 漆喰
//                           4 黒曜石と溶岩のひび / 5 水盤 / 6 揺れる水の光 (コースティクス) の映る漆喰
//                           7 ドームの格天井 (メッシュの uv を使う) / 8 ドームの床の方位盤 (メッシュの中心からの位置を使う)
// 光の計算は URP の UniversalFragmentPBR (URP/Lit と同じ) に任せるので、スポットライト・影・霧・環境光がそのまま効く
Shader "NightShards/MuseumSurface"
{
    Properties
    {
        [Enum(Concrete,0,Wood,1,Stone,2,Plaster,3,Obsidian,4,Water,5,Caustic,6,Coffer,7,Compass,8)] _Kind ("Kind", Float) = 0
        _ColorA ("Color A", Color) = (0.46, 0.45, 0.43, 1)
        _ColorB ("Color B", Color) = (0.34, 0.33, 0.32, 1)
        _Smoothness ("Smoothness", Range(0, 1)) = 0.2
        _Scale ("Pattern Scale", Float) = 1
        [HDR] _EmissionColor ("Emission (溶岩・水の光)", Color) = (0, 0, 0, 1)
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "Queue" = "Geometry" }
        LOD 300

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        // マテリアルごとの値は UnityPerMaterial にまとめる (SRP Batcher で速く描ける)
        CBUFFER_START(UnityPerMaterial)
            float _Kind;
            half4 _ColorA;
            half4 _ColorB;
            half _Smoothness;
            float _Scale;
            half4 _EmissionColor;
        CBUFFER_END
        ENDHLSL

        // ------------------------------------------------------------------ 色を塗るパス
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex Vert
            #pragma fragment Frag

            // URP の光と影の切り替え。URP/Lit と同じものを並べる
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile_fragment _ _LIGHT_COOKIES
            #pragma multi_compile _ _FORWARD_PLUS
            #pragma multi_compile _ _CLUSTER_LIGHT_LOOP
            #pragma multi_compile_fog
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            // ---------------------------------------------------------------- ノイズ (MuseumSurface と MuseumArt に同じものが入っている)

            // 0〜1 の疑似乱数
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

            // なめらかな値ノイズ (0〜1)
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

            // 細かさの違うノイズを5枚重ねたもの (0〜1 くらい)
            float Fbm(float2 p)
            {
                float v = 0.0;
                float amp = 0.5;
                for (int k = 0; k < 5; k++)
                {
                    v += amp * ValueNoise(p);
                    p = p * 2.03 + 17.1;
                    amp *= 0.5;
                }
                return v;
            }

            // ボロノイ (ひび割れ模様)。x: いちばん近い点までの距離 / y: 境目までの近さ (0 で境目) / z: 区画ごとの乱数
            float3 Voronoi(float2 x)
            {
                float2 n = floor(x);
                float2 f = frac(x);
                float f1 = 8.0;
                float f2 = 8.0;
                float id = 0.0;
                for (int j = -1; j <= 1; j++)
                {
                    for (int i = -1; i <= 1; i++)
                    {
                        float2 g = float2(i, j);
                        float2 r = g + Hash22(n + g) - f;
                        float d = dot(r, r);
                        if (d < f1)
                        {
                            f2 = f1;
                            f1 = d;
                            id = Hash21(n + g);
                        }
                        else if (d < f2)
                        {
                            f2 = d;
                        }
                    }
                }
                f1 = sqrt(f1);
                f2 = sqrt(f2);
                return float3(f1, f2 - f1, id);
            }

            // 水の底に揺れる光の網目 (コースティクス)。1 単位ごとにくり返す。0〜1 くらい
            float Caustics(float2 uv, float time)
            {
                const float TAU = 6.28318530718;
                float2 p = frac(uv) * TAU - 250.0;
                float2 i = p;
                float c = 1.0;
                const float inten = 0.005;
                for (int n = 0; n < 4; n++)
                {
                    float t = time * (1.0 - (3.5 / float(n + 1)));
                    i = p + float2(cos(t - i.x) + sin(t + i.y), sin(t - i.y) + cos(t + i.x));
                    c += 1.0 / length(float2(p.x / (sin(i.x + t) / inten), p.y / (cos(i.y + t) / inten)));
                }
                c /= 4.0;
                c = 1.17 - pow(abs(c), 1.4);
                return pow(abs(c), 8.0);
            }

            // 線 (継ぎ目・目地) の太さ w を、画面上で1ピクセルより細くならないようにぼかす。遠くでちらつかない。
            // px は1ピクセルが何単位にあたるか。微分 (fwidth) は分岐の中で使えないので、呼ぶ側の最初で計算して渡す
            float LineMask(float dist, float w, float px)
            {
                float aa = max(px, 1e-4);
                return 1.0 - smoothstep(w - aa, w + aa, dist);
            }

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                half fogFactor : TEXCOORD2;
                float2 uv : TEXCOORD3;          // メッシュの uv (格天井で使う)
                float3 positionOS : TEXCOORD4;  // 物の中心から見た位置 (方位盤で使う)
                UNITY_VERTEX_OUTPUT_STEREO
            };

            // ---------------------------------------------------------------- 種類ごとの模様

            // 打ち放しコンクリート: 1800×900 の型枠の継ぎ目と、600×450 間隔のセパ穴 (型枠を留めた丸い穴)
            void Concrete(float2 uv, float px, out float3 albedo, out float gloss, out float occ)
            {
                float cloud = Fbm(uv * 0.55);
                float grain = ValueNoise(uv * 38.0) - 0.5;
                float streak = Fbm(float2(uv.x * 2.5, uv.y * 0.25)); // 縦に流れる雨じみのようなむら
                albedo = lerp(_ColorB.rgb, _ColorA.rgb, saturate(cloud * 1.2 - 0.1));
                albedo *= 1.0 + grain * 0.08;
                albedo *= lerp(0.92, 1.04, streak);
                gloss = _Smoothness * (0.8 + 0.4 * cloud);

                float2 panel = float2(1.8, 0.9);
                float2 g = frac(uv / panel) * panel;
                float seamDist = min(min(g.x, panel.x - g.x), min(g.y, panel.y - g.y));
                float seam = LineMask(seamDist, 0.004, px);

                float2 pitch = float2(0.6, 0.45);
                float2 q = uv - float2(0.3, 0.225);
                q -= pitch * round(q / pitch);
                float r = length(q);
                float hole = LineMask(r, 0.014, px);
                float ring = LineMask(abs(r - 0.022), 0.004, px) * (1.0 - hole);

                albedo *= 1.0 - seam * 0.35;
                albedo *= 1.0 - hole * 0.55;
                albedo *= 1.0 + ring * 0.08;
                occ = 1.0 - hole * 0.6 - seam * 0.3;
                gloss *= 1.0 - hole;
            }

            // 木の床: 幅19cm・長さ1.8mの板を、列ごとにずらして張る。木目は板の長さ方向に伸ばしたノイズ
            void Wood(float2 uv, float px, out float3 albedo, out float gloss, out float occ)
            {
                float w = 0.19;
                float plankLength = 1.8;
                float row = floor(uv.y / w);
                float along = uv.x + Hash21(float2(row, 7.0)) * 3.0;
                float plank = floor(along / plankLength);
                float h = Hash21(float2(row, plank));

                float grain = Fbm(float2(along * 0.7, uv.y * 26.0 + h * 10.0));
                float rings = sin(uv.y * 70.0 + grain * 9.0 + h * 6.0) * 0.5 + 0.5;
                float tone = saturate(grain * 0.8 + rings * 0.25);
                albedo = lerp(_ColorB.rgb, _ColorA.rgb, tone) * (0.82 + 0.32 * h);

                float dy = frac(uv.y / w) * w;
                float dx = frac(along / plankLength) * plankLength;
                float gapDist = min(min(dy, w - dy), min(dx, plankLength - dx));
                float gap = LineMask(gapDist, 0.0015, px);
                albedo *= 1.0 - gap * 0.6;
                gloss = _Smoothness * (0.75 + 0.35 * grain) * (1.0 - gap);
                occ = 1.0 - gap * 0.5;
            }

            // 石の研ぎ出し: 雲のようなむらに細かい粒を散らし、1.2m 角の目地を入れる。よく磨いてあるので光を映す
            void Stone(float2 uv, float px, out float3 albedo, out float gloss, out float occ)
            {
                float cloud = Fbm(uv * 0.8);
                float chip = step(0.86, ValueNoise(uv * 85.0));
                float chip2 = step(0.9, ValueNoise(uv * 140.0 + 31.0));
                albedo = lerp(_ColorA.rgb, _ColorB.rgb, cloud);
                albedo += chip * 0.06 + chip2 * 0.04;

                float tile = 1.2;
                float2 g = frac(uv / tile) * tile;
                float jointDist = min(min(g.x, tile - g.x), min(g.y, tile - g.y));
                float joint = LineMask(jointDist, 0.0015, px);
                albedo *= 1.0 - joint * 0.5;
                gloss = _Smoothness * (0.9 + 0.1 * cloud) * (1.0 - joint * 0.6);
                occ = 1.0 - joint * 0.4;
            }

            // 漆喰: ごく弱いむらだけ。台座や仮の箱に使う
            void Plaster(float2 uv, float px, out float3 albedo, out float gloss, out float occ)
            {
                float cloud = Fbm(uv * 2.0);
                float grain = ValueNoise(uv * 60.0) - 0.5;
                albedo = lerp(_ColorA.rgb, _ColorB.rgb, cloud) * (1.0 + grain * 0.04);
                gloss = _Smoothness * (0.85 + 0.3 * cloud);
                occ = 1.0;
            }

            // 黒曜石の床: 黒く磨かれた石に、ボロノイのひびが走り、奥で溶岩が脈打つように光る
            void Obsidian(float2 uv, float px, float t, out float3 albedo, out float gloss, out float occ, out float3 emission)
            {
                float3 big = Voronoi(uv * 0.9);
                float3 fine = Voronoi(uv * 2.6 + 11.0);
                float crack = max(LineMask(big.y, 0.03, px * 0.9), LineMask(fine.y, 0.012, px * 2.6) * 0.6);
                float heat = exp(-big.y * 9.0);                          // ひびのまわりのにじむ熱
                float pulse = 0.55 + 0.45 * sin(t * 1.1 + big.z * 6.2831); // ひびごとにずれて脈打つ

                albedo = lerp(_ColorA.rgb, _ColorB.rgb, Fbm(uv * 3.0));
                albedo = lerp(albedo, float3(0.05, 0.02, 0.01), crack);
                gloss = _Smoothness * (1.0 - crack);
                occ = 1.0;
                emission = _EmissionColor.rgb * pulse * (crack + heat * 0.18);
            }

            // 格天井: ローマのパンテオンのような、段になった四角いくぼみが並ぶ天井。
            // uv.x が一周 (0〜1)、uv.y が下の縁 0 から天窓の縁 1。上へ行くほどくぼみは自然に小さくなる
            void Coffer(float2 uv, out float3 albedo, out float gloss, out float occ)
            {
                const float columns = 32.0;
                const float rows = 5.0;
                const float top = 0.74;  // くぼみがあるのは、この高さまで。その上はなめらかな面
                float3 plaster = lerp(_ColorB.rgb, _ColorA.rgb, Fbm(uv * float2(60.0, 12.0)));
                albedo = plaster;
                gloss = _Smoothness;
                occ = 1.0;
                if (uv.y < top)
                {
                    float2 c = frac(float2(uv.x * columns, uv.y / top * rows));
                    float d = min(min(c.x, 1.0 - c.x), min(c.y, 1.0 - c.y)); // くぼみの縁からの近さ
                    float shade = 1.0;                       // 縁の太い梁
                    if (d > 0.11) shade = 0.82;              // 1段目
                    if (d > 0.18) shade = 0.68;              // 2段目
                    if (d > 0.24) shade = 0.58 + 0.1 * smoothstep(0.24, 0.5, d); // いちばん奥の面
                    occ = shade;
                    albedo *= lerp(0.85, 1.0, shade);
                }
                // 天窓の縁は、暗い帯で締める
                float rim = smoothstep(0.955, 0.975, uv.y);
                albedo *= 1.0 - rim * 0.7;
            }

            // 方位盤の床: 黒い石に、真鍮の線で 8 方向の筋・円・中央の八芒星を象眼する。
            // p は床の中心からの位置 (m)。真鍮の所は metal = 1 を返す
            void Compass(float2 p, float px, out float3 albedo, out float gloss, out float occ, out float metal)
            {
                float2 uv = p / max(_Scale, 1e-3);
                Stone(uv, px, albedo, gloss, occ);
                metal = 0.0;

                float r = length(p);
                float a = atan2(p.x, p.y);                     // 北 (+z) が 0
                const float sector = 0.785398;                 // 45°
                float aMain = a - round(a / sector) * sector;  // いちばん近い 8 方向の筋からの角度
                float aMinor = a - (round(a / sector - 0.5) + 0.5) * sector;
                float rayMain = r * abs(sin(aMain));           // 筋までの距離 (m)
                float rayMinor = r * abs(sin(aMinor));

                float brass = 0.0;
                brass = max(brass, LineMask(abs(r - 1.25), 0.02, px));
                brass = max(brass, LineMask(abs(r - 1.4), 0.01, px));
                brass = max(brass, LineMask(abs(r - 5.6), 0.02, px));
                brass = max(brass, LineMask(abs(r - 5.75), 0.01, px));
                brass = max(brass, LineMask(abs(r - 10.4), 0.025, px));
                brass = max(brass, LineMask(abs(r - 10.6), 0.012, px));
                brass = max(brass, LineMask(rayMain, 0.022, px) * step(1.4, r) * step(r, 10.4));
                brass = max(brass, LineMask(rayMinor, 0.01, px) * step(5.75, r) * step(r, 10.4));

                // 中央の八芒星: 角度によって半径が 1.15 と 0.5 のあいだを行き来する
                float tri = abs(frac(a / sector) - 0.5) * 2.0;  // 筋の上で 1、筋のあいだで 0
                float starR = lerp(0.5, 1.15, tri * tri);
                float star = 1.0 - smoothstep(starR - px, starR + px, r);
                float hole = 1.0 - smoothstep(0.18 - px, 0.18 + px, r);
                brass = max(brass, star * (1.0 - hole));

                float3 brassColor = float3(0.78, 0.6, 0.32);
                albedo = lerp(albedo, brassColor, brass);
                gloss = lerp(gloss, 0.72, brass);
                metal = brass;
            }

            // 水盤の高さ (さざ波)。法線を傾けるのに使う
            float Ripple(float2 p, float t)
            {
                return ValueNoise(p * 2.5 + float2(t * 0.15, t * 0.1)) + 0.5 * ValueNoise(p * 6.0 - float2(t * 0.2, -t * 0.13));
            }

            // ---------------------------------------------------------------- 本体

            Varyings Vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                VertexPositionInputs pos = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs nrm = GetVertexNormalInputs(input.normalOS);
                output.positionCS = pos.positionCS;
                output.positionWS = pos.positionWS;
                output.normalWS = nrm.normalWS;
                output.fogFactor = ComputeFogFactor(pos.positionCS.z);
                output.uv = input.uv;
                output.positionOS = input.positionOS.xyz;
                return output;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                float3 normalWS = normalize(input.normalWS);

                // 面の向きでいちばん近い平面に投影する (床と天井は xz、壁は xy か zy)
                float3 n = abs(normalWS);
                bool horizontal = n.y > max(n.x, n.z);
                float3 p = input.positionWS;
                float2 uv = horizontal ? p.xz : (n.x > n.z ? p.zy : p.xy);
                uv /= max(_Scale, 1e-3);
                float px = length(fwidth(uv)) * 0.7;

                float t = _Time.y;
                float3 albedo;
                float gloss;
                float occ;
                float3 emission = 0;
                float metal = 0.0;
                // 方位盤は物の中心からの位置で線を引くので、その位置での1ピクセルの大きさも分岐の外で測っておく
                float pxOS = length(fwidth(input.positionOS.xz));
                if (_Kind > 6.5)
                {
                    if (_Kind < 7.5) Coffer(input.uv, albedo, gloss, occ);
                    else             Compass(input.positionOS.xz, pxOS, albedo, gloss, occ, metal);
                }
                else if (_Kind < 0.5) Concrete(uv, px, albedo, gloss, occ);
                else if (_Kind < 1.5) Wood(uv, px, albedo, gloss, occ);
                else if (_Kind < 2.5) Stone(uv, px, albedo, gloss, occ);
                else if (_Kind < 3.5) Plaster(uv, px, albedo, gloss, occ);
                else if (_Kind < 4.5) Obsidian(uv, px, t, albedo, gloss, occ, emission);
                else if (_Kind < 5.5)
                {
                    // 水盤: ほぼ黒い水面。さざ波で法線を少し傾けて、光の映り込みを揺らす
                    albedo = lerp(_ColorA.rgb, _ColorB.rgb, ValueNoise(uv * 0.7));
                    gloss = _Smoothness;
                    occ = 1.0;
                    if (horizontal)
                    {
                        const float e = 0.02;
                        float dx = (Ripple(uv + float2(e, 0), t) - Ripple(uv - float2(e, 0), t)) / (2.0 * e);
                        float dz = (Ripple(uv + float2(0, e), t) - Ripple(uv - float2(0, e), t)) / (2.0 * e);
                        normalWS = normalize(normalWS + float3(-dx, 0, -dz) * 0.05);
                    }
                }
                else
                {
                    // 水の光の映る漆喰: 白い面に、ゆっくり揺れる光の網目が浮かぶ。壁は天井より少し弱く
                    Plaster(uv, px, albedo, gloss, occ);
                    float c = Caustics(uv * 0.33, t * 0.6) + 0.5 * Caustics(uv * 0.21 + 0.37, t * 0.45);
                    emission = _EmissionColor.rgb * c * (horizontal ? 1.0 : 0.6);
                }

                // URP の光の計算に渡す材料
                InputData inputData = (InputData)0;
                inputData.positionWS = input.positionWS;
                inputData.positionCS = input.positionCS;
                inputData.normalWS = normalWS;
                inputData.viewDirectionWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
                inputData.shadowCoord = TransformWorldToShadowCoord(input.positionWS);
                inputData.fogCoord = input.fogFactor;
                inputData.bakedGI = SampleSH(normalWS);
                inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
                inputData.shadowMask = half4(1, 1, 1, 1);

                SurfaceData surface = (SurfaceData)0;
                surface.albedo = albedo;
                surface.metallic = metal;
                surface.specular = 0;
                surface.smoothness = saturate(gloss);
                surface.occlusion = saturate(occ);
                surface.normalTS = half3(0, 0, 1);
                surface.emission = emission;
                surface.alpha = 1;

                half4 color = UniversalFragmentPBR(inputData, surface);
                color.rgb = MixFog(color.rgb, inputData.fogCoord);
                return color;
            }
            ENDHLSL
        }

        // ------------------------------------------------------------------ 影を落とすパス
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
            ZWrite On
            ZTest LEqual
            ColorMask 0

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex ShadowVert
            #pragma fragment ShadowFrag
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            float3 _LightDirection;
            float3 _LightPosition;

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            float4 ShadowVert(Attributes input) : SV_POSITION
            {
                UNITY_SETUP_INSTANCE_ID(input);
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
            #if defined(_CASTING_PUNCTUAL_LIGHT_SHADOW)
                float3 lightDirectionWS = normalize(_LightPosition - positionWS); // スポットライトや点光源
            #else
                float3 lightDirectionWS = _LightDirection;                        // 平行光源
            #endif
                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));
            #if UNITY_REVERSED_Z
                positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
            #else
                positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
            #endif
                return positionCS;
            }

            half4 ShadowFrag() : SV_Target
            {
                return 0;
            }
            ENDHLSL
        }

        // ------------------------------------------------------------------ 奥行きだけを書くパス (URP が前もって奥行きを取るときに使う)
        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }
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

        // ------------------------------------------------------------------ 奥行きと向きを書くパス (SSAO などが使う)
        Pass
        {
            Name "DepthNormals"
            Tags { "LightMode" = "DepthNormals" }
            ZWrite On

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex DepthNormalsVert
            #pragma fragment DepthNormalsFrag
            #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT
            #pragma multi_compile_instancing

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 normalWS : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings DepthNormalsVert(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                return output;
            }

            half4 DepthNormalsFrag(Varyings input) : SV_Target
            {
                float3 normalWS = normalize(input.normalWS);
            #if defined(_GBUFFER_NORMALS_OCT)
                float2 oct = PackNormalOctQuadEncode(normalWS);
                return half4(PackFloat2To888(saturate(oct * 0.5 + 0.5)), 0.0);
            #else
                return half4(normalWS, 0.0);
            #endif
            }
            ENDHLSL
        }
    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
