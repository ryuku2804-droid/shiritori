// 展示室のアート (光るもの) 用の URP シェーダー。光は受けず、自分で光る。ブルームがあればにじんで見える。
// _Mode で種類を切り替える:
//   0 月の円盤 / 1 天井から下がる光の糸 / 2 夕日の透ける障子 / 3 火の粉 (パーティクル)
// 重ね方は _SrcBlend / _DstBlend で決める (光るものは足し算、障子は不透明)。MuseumBuilder がマテリアルごとに設定する
Shader "NightShards/MuseumArt"
{
    Properties
    {
        [Enum(Moon,0,Thread,1,Shoji,2,Ember,3)] _Mode ("Mode", Float) = 0
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
            #include "MuseumNoise.hlsl"

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

            // 火の粉: パーティクルの板の中央に、やわらかい丸い光。色と透明度はパーティクルの頂点の色から
            float3 Ember(float2 uv, half4 color)
            {
                float d = length(uv - 0.5) * 2.0;
                float a = saturate(1.0 - d);
                return color.rgb * a * a * color.a * 3.0;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                float t = _Time.y;
                float3 n = abs(normalize(input.normalWS));
                float2 planar = n.x > n.z ? input.positionWS.zy : input.positionWS.xy;
                float px = length(fwidth(planar));

                float3 col;
                if (_Mode < 0.5)      col = Moon(input.uv);
                else if (_Mode < 1.5) col = Thread(input.uv, input.color, t);
                else if (_Mode < 2.5) col = Shoji(planar, px, input.uv, t);
                else                  col = Ember(input.uv, input.color);
                col *= _Color.rgb;

                // 足し算で重ねるものは、霧の中では黒へ消える。不透明の障子は霧の色に溶ける
                if (_Mode > 1.5 && _Mode < 2.5) col = MixFog(col, input.fogFactor);
                else col = MixFogColor(col, half3(0, 0, 0), input.fogFactor);
                return half4(col, 1.0);
            }
            ENDHLSL
        }
    }
}
