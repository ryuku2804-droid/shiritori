// キャプションの文字 (TextMesh) 用の URP シェーダー。
// Unity 標準の文字のシェーダーは壁の向こうからも透けて見えてしまうので、奥行きを見て隠れるようにしたもの。
// 光は受けず、いつも同じ明るさで読める。霧だけはかかる
Shader "NightShards/MuseumText"
{
    Properties
    {
        _MainTex ("Font Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1, 1, 1, 1)
    }

    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            Name "Text"
            Tags { "LightMode" = "UniversalForward" }
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            ZTest LEqual
            Cull Off
            Offset -1, -1 // プレートの面より少し手前に描いて、ちらつきを防ぐ

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma multi_compile_fog
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                half4 _Color;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                half4 color : COLOR;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                half4 color : COLOR;
                float2 uv : TEXCOORD0;
                half fogFactor : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings Vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.color = input.color * _Color; // TextMesh の色は頂点の色で来る
                output.uv = input.uv;
                output.fogFactor = ComputeFogFactor(output.positionCS.z);
                return output;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input); // VR: 左右どちらの目を描いているか
                // 文字の形はフォントのテクスチャのアルファに入っている
                half a = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv).a;
                half4 c = half4(input.color.rgb, input.color.a * a);
                c.rgb = MixFog(c.rgb, input.fogFactor);
                return c;
            }
            ENDHLSL
        }
    }
}
