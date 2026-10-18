// 展示室のアート (光るもの) 用の URP シェーダー。光は受けず、自分で光る。ブルームがあればにじんで見える。
// _Mode で種類を切り替える:
//   0 月の円盤 / 1 天井から下がる光の糸 / 2 夕日の透ける障子 / 3 火の粉 (パーティクル) / 4 天井の光のスリット
//   5 ドームの天窓から見える夜空 / 6 天窓から落ちる光の柱
// 重ね方は _SrcBlend / _DstBlend で決める (光るものは足し算、障子は不透明)。MuseumBuilder がマテリアルごとに設定する
Shader "NightShards/MuseumArt"
{
    Properties
    {
        [Enum(Moon,0,Thread,1,Shoji,2,Ember,3,Slit,4,Oculus,5,Shaft,6)] _Mode ("Mode", Float) = 0
        [HDR] _Color ("Color", Color) = (1, 1, 1, 1)
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend", Float) = 1
        [Enum(Off,0,On,1)] _ZWrite ("ZWrite", Float) = 0
    }

    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            Name "Art"
            Tags { "LightMode" = "UniversalForward" }
            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]
            Cull Off

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma multi_compile_fog
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

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

            CBUFFER_START(UnityPerMaterial)
                float _Mode;
                half4 _Color;
                float _SrcBlend;
                float _DstBlend;
                float _ZWrite;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                half4 color : COLOR;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float2 uv : TEXCOORD2;
                half4 color : COLOR;
                half fogFactor : TEXCOORD3;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings Vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                VertexPositionInputs pos = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = pos.positionCS;
                output.positionWS = pos.positionWS;
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.uv = input.uv;
                output.color = input.color;
                output.fogFactor = ComputeFogFactor(pos.positionCS.z);
                return output;
            }

            // 月: 板の中央の円。縁ほど暗く (球に見える)、海の模様とクレーターを入れ、外側に淡い光の輪
            float3 Moon(float2 uv)
            {
                float2 p = (uv - 0.5) * 2.0;
                float r = length(p) / 0.72;                     // 月の半径は板の 72%
                float disc = 1.0 - smoothstep(0.985, 1.0, r);
                float limb = sqrt(saturate(1.0 - r * r));
                float maria = Fbm(p * 2.2 + 3.1);
                float craters = step(0.82, ValueNoise(p * 18.0));
                float tone = 0.72 + 0.28 * smoothstep(0.35, 0.7, maria) - 0.08 * craters;
                float3 surface = float3(0.86, 0.9, 1.0) * tone * (0.5 + 0.5 * limb);
                float halo = exp(-max(r - 1.0, 0.0) * 5.0) * 0.18 * (1.0 - disc);
                return surface * disc + float3(0.6, 0.7, 1.0) * halo;
            }

            // 光の糸: 幅の中央ほど明るく、上から下へ光の粒がゆっくり流れる。頂点の色の r が糸ごとの乱数
            float3 Thread(float2 uv, half4 color, float t)
            {
                float seed = color.r * 100.0;
                float across = 1.0 - abs(uv.x * 2.0 - 1.0);
                across *= across;
                float pulse = pow(saturate(sin((uv.y * 2.0 - t * 0.25 + seed) * 6.2831)), 12.0) * 1.5;
                float ends = smoothstep(0.0, 0.03, uv.y) * smoothstep(1.0, 0.85, uv.y); // 下の端はふっと消える
                return (0.25 + pulse) * across * ends;
            }

            // 障子: 紙に夕日が透けている。組子 (格子) の桟が影になり、片側の下ほど明るい
            // p は面に沿った位置 (m)、px は1ピクセルが何 m か (分岐の外で計算して渡す)
            float3 Shoji(float2 p, float px, float2 uv, float t)
            {
                float2 cell = float2(0.32, 0.42);
                float2 g = frac(p / cell) * cell;
                float d = min(min(g.x, cell.x - g.x), min(g.y, cell.y - g.y));
                float bar = LineMask(d, 0.009, px);

                float edge = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));   // 外枠
                float frame = 1.0 - smoothstep(0.012, 0.016, edge);

                float fiber = 0.9 + 0.1 * ValueNoise(p * 40.0);
                float sun = lerp(0.55, 1.25, uv.x) * lerp(1.15, 0.75, uv.y);    // 右下ほど明るい
                float breathe = 0.95 + 0.05 * sin(t * 0.3);
                float3 paper = float3(1.0, 0.62, 0.32) * fiber * sun * breathe;
                return lerp(paper, float3(0.04, 0.025, 0.015), saturate(bar + frame));
            }

            // 火の粉: パーティクルの板の中央に、やわらかい丸い光。色と透明度はパーティクルの頂点の色から。
            // カメラのすぐ前を通る火の粉は、画面いっぱいの大きな光になって画面が白く点滅するので、近いほど消す
            float3 Ember(float2 uv, half4 color, float3 positionWS)
            {
                float d = length(uv - 0.5) * 2.0;
                float a = saturate(1.0 - d);
                float near = smoothstep(0.5, 1.5, distance(positionWS, GetCameraPositionWS())); // 0.5m より近いと見えない
                return color.rgb * a * a * color.a * 3.0 * near;
            }

            // 光のスリット: 細長い板の中央の線が光る。端はふっと消える
            float3 Slit(float2 uv)
            {
                float across = 1.0 - abs(uv.y * 2.0 - 1.0);
                float ends = smoothstep(0.0, 0.04, uv.x) * smoothstep(1.0, 0.96, uv.x);
                return pow(saturate(across), 3.0) * ends;
            }

            // 天窓の夜空: 板の中心ほど明るい濃紺の空に、星が瞬く。uv は板の 0〜1
            float3 OculusSky(float2 uv, float t)
            {
                float2 p = uv - 0.5;
                float r = length(p) * 2.0;
                float3 sky = lerp(float3(0.25, 0.35, 0.6), float3(0.04, 0.06, 0.16), saturate(r));
                float2 cell = floor(uv * 90.0);
                float star = step(0.985, Hash21(cell)) * (0.6 + 0.4 * sin(t * 2.0 + Hash21(cell + 3.0) * 30.0));
                return sky + star * 1.5;
            }

            // 光の柱: 筒の縁 (横から見て端) ほど薄く、上ほど明るい。中をほこりの粒がゆっくり漂う
            float3 Shaft(float2 uv, float3 positionWS, float3 normalWS, float t)
            {
                float3 v = normalize(GetCameraPositionWS() - positionWS);
                float facing = abs(dot(normalize(normalWS), v));      // 筒を正面から見る所ほど 1
                float edge = pow(facing, 2.5);
                float fall = lerp(1.0, 0.35, uv.y) * smoothstep(1.0, 0.92, uv.y);
                float dust = ValueNoise(positionWS.xz * 6.0 + float2(0.0, positionWS.y * 2.0 - t * 0.15));
                dust = smoothstep(0.75, 0.95, dust) * 0.6;
                return (0.12 + dust) * edge * fall;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input); // VR: 左右どちらの目を描いているか
                float t = _Time.y;
                float3 n = abs(normalize(input.normalWS));
                float2 planar = n.x > n.z ? input.positionWS.zy : input.positionWS.xy;
                float px = length(fwidth(planar));

                float3 col;
                if (_Mode < 0.5)      col = Moon(input.uv);
                else if (_Mode < 1.5) col = Thread(input.uv, input.color, t);
                else if (_Mode < 2.5) col = Shoji(planar, px, input.uv, t);
                else if (_Mode < 3.5) col = Ember(input.uv, input.color, input.positionWS);
                else if (_Mode < 4.5) col = Slit(input.uv);
                else if (_Mode < 5.5) col = OculusSky(input.uv, t);
                else                  col = Shaft(input.uv, input.positionWS, input.normalWS, t);
                col *= _Color.rgb;

                // 足し算で重ねるものは、霧の中では黒へ消える。不透明の障子は霧の色に溶ける
                if (_Mode > 1.5 && _Mode < 2.5) col = MixFog(col, input.fogFactor);
                else col = MixFogColor(col, half3(0, 0, 0), input.fogFactor);
                col = min(max(col, 0.0), 64.0); // あふれた点を取りのぞく (ブルームで画面が白くとばないように)
                return half4(col, 1.0);
            }
            ENDHLSL
        }
    }
}
