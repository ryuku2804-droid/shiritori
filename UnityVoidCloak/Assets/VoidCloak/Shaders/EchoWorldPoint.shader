// Echo Knight world shader (URP).
//
// Buildings, floors and enemies are point clouds that stay completely invisible in the dark.
// Only when a sound wave from EchoSystem passes over a point does it light up: brightest on the
// wavefront, then fading out within the hold time (about 1.5 s). Points facing the sound are
// brighter. Waves made by enemies tint what they reveal red.
//
// Points are expanded to small quads in a geometry shader; the quad coordinate is passed as a
// TEXCOORD (no SV_PointCoord, so it compiles for D3D11 ps_4_0). Points that are not revealed
// are culled in the geometry shader and cost almost nothing to draw.
//
// Vertex data (EchoPointBuilder):
//   POSITION, NORMAL
//   COLOR     r = brightness, g = random, b = cavity (1 open .. 0 deep joint)
//   TEXCOORD0 x = size multiplier
Shader "EchoKnight/WorldPoint"
{
    Properties
    {
        _EchoColor ("Echo Color (white = stone, red = enemy, gold = item)", Color) = (0.9, 0.93, 1, 1)
        _EnemyWaveColor ("Color Of Enemy Sounds", Color) = (1, 0.14, 0.1, 1)
        _BellWaveColor ("Color Of Shrine Bells", Color) = (1, 0.8, 0.38, 1)
        _Brightness ("Brightness", Range(0, 4)) = 1.0
        _SideLight ("Light On Faces Turned Away", Range(0, 1)) = 0.25
        _FrontBoost ("Wavefront Brightness", Range(0, 4)) = 0.9
        _FrontSwell ("Wavefront Point Swell", Range(0, 3)) = 0.9
        _Ripple ("Wavefront Ripple", Range(0, 0.5)) = 0.06
        _PointSize ("Point Size (world)", Float) = 0.085
        _PointVariation ("Point Size Variation", Range(0, 1)) = 0.35
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "Queue" = "Geometry" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            Name "EchoWorld"
            Tags { "LightMode" = "UniversalForward" }

            Cull Off
            ZWrite On
            ZTest LEqual

            HLSLPROGRAM
            #pragma target 4.0
            #pragma require geometry
            #pragma vertex Vert
            #pragma geometry Geom
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            #define ECHO_MAX_WAVES 24

            // set every frame by EchoSystem.cs
            float4 _EchoWaves[ECHO_MAX_WAVES];       // xyz origin, w start time
            float4 _EchoWaveParams[ECHO_MAX_WAVES];  // x radius, y speed, z source (0 player, 1 enemy, 2 strike, 3 bell), w strength
            float _EchoWaveCount;
            float _EchoTime;
            float _EchoBand;
            float _EchoHold;
            float _EchoRevealAll;

            CBUFFER_START(UnityPerMaterial)
                float4 _EchoColor;
                float4 _EnemyWaveColor;
                float4 _BellWaveColor;
                float _Brightness;
                float _SideLight;
                float _FrontBoost;
                float _FrontSwell;
                float _Ripple;
                float _PointSize;
                float _PointVariation;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float4 color      : COLOR;
                float2 uv0        : TEXCOORD0;
            };

            struct V2G
            {
                float4 positionCS : SV_POSITION;   // unused by the GS, kept for strict compilers
                float3 positionWS : TEXCOORD0;
                float4 color      : TEXCOORD1;     // rgb lit color, a = size
                float2 info       : TEXCOORD2;     // x = reveal, y = wavefront
            };

            struct G2F
            {
                float4 positionCS : SV_POSITION;
                float2 quadUV     : TEXCOORD0;
                float3 color      : TEXCOORD1;
            };

            // How much the sound waves reveal a point.
            //   reveal : 0 hidden .. 1 fully lit
            //   front  : 1 while the wavefront is passing
            //   enemy  : 1 if the strongest wave was made by an enemy
            //   bell   : 1 if the strongest wave was a shrine bell
            //   toSound: direction from the point towards the sound
            void EchoReveal(float3 p, out float reveal, out float front, out float enemy, out float bell, out float3 toSound)
            {
                reveal = 0.0;
                front = 0.0;
                enemy = 0.0;
                bell = 0.0;
                toSound = float3(0.0, 1.0, 0.0);
                int count = (int)_EchoWaveCount;

                [loop]
                for (int i = 0; i < ECHO_MAX_WAVES; i++)
                {
                    if (i >= count) break;
                    float4 w = _EchoWaves[i];
                    float4 q = _EchoWaveParams[i];
                    float age = _EchoTime - w.w;
                    if (age < 0.0) continue;

                    float3 d = p - w.xyz;
                    float dist = length(d);
                    if (dist > q.x) continue;

                    float radius = age * q.y;
                    float x = (dist - radius) / _EchoBand;
                    float band = exp(-x * x);
                    float since = age - dist / q.y;                     // seconds since the front passed
                    float glow = since > 0.0 ? saturate(1.0 - since / _EchoHold) : 0.0;
                    glow *= glow;
                    float fade = 1.0 - smoothstep(0.7, 1.0, dist / q.x);  // weaker towards the edge of its reach
                    float r = max(band, glow * 0.8) * fade * q.w;

                    if (r > reveal)
                    {
                        reveal = r;
                        front = band * fade * q.w;
                        enemy = abs(q.z - 1.0) < 0.5 ? 1.0 : 0.0;
                        bell = abs(q.z - 3.0) < 0.5 ? 1.0 : 0.0;
                        toSound = -d / max(dist, 1e-3);
                    }
                }
            }

            V2G Vert(Attributes input)
            {
                V2G o;
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = normalize(TransformObjectToWorldNormal(input.normalOS));

                float reveal, front, enemy, bell;
                float3 toSound;
                EchoReveal(positionWS, reveal, front, enemy, bell, toSound);

                // the wavefront shakes the points a little, like dust on a drum
                positionWS += normalWS * (front * _Ripple * (input.color.g - 0.3));

                // light from the direction of the sound; faces turned away stay dim
                float facing = saturate(dot(normalWS, toSound));
                float light = _SideLight + (1.0 - _SideLight) * facing;
                float3 baseColor = lerp(_EchoColor.rgb, _EnemyWaveColor.rgb, enemy * 0.85);
                baseColor = lerp(baseColor, _BellWaveColor.rgb, bell * 0.6);   // shrine bells wash the world gold
                float3 color = baseColor * input.color.r * input.color.b * light * _Brightness;
                color += baseColor * front * _FrontBoost * 0.5 + front * _FrontBoost * 0.25;   // hot white-ish front

                // dim preview in the editor (and the debug "reveal all" switch)
                float editor = _EchoRevealAll;
                color = max(color * saturate(reveal), _EchoColor.rgb * input.color.r * input.color.b * editor * (0.4 + 0.6 * saturate(normalWS.y * 0.5 + 0.5)));
                reveal = max(reveal, editor);

                o.positionWS = positionWS;
                o.positionCS = TransformWorldToHClip(positionWS);
                o.color = float4(color, input.uv0.x * (1.0 + front * _FrontSwell));
                o.info = float2(reveal, front);
                return o;
            }

            [maxvertexcount(4)]
            void Geom(point V2G input[1], inout TriangleStream<G2F> stream)
            {
                V2G p = input[0];
                if (p.info.x < 0.01) return;   // not revealed: draw nothing

                float rnd = frac(p.positionWS.x * 12.9898 + p.positionWS.z * 78.233);
                float size = _PointSize * p.color.a * (1.0 + (rnd - 0.5) * 2.0 * _PointVariation) * (0.6 + 0.4 * saturate(p.info.x * 1.5));
                float3 centerVS = TransformWorldToView(p.positionWS);
                float2 corners[4] = { float2(-1, -1), float2(1, -1), float2(-1, 1), float2(1, 1) };

                G2F o;
                o.color = p.color.rgb;
                [unroll]
                for (int i = 0; i < 4; i++)
                {
                    float3 vs = centerVS;
                    vs.xy += corners[i] * size;
                    o.positionCS = TransformWViewToHClip(vs);
                    o.quadUV = corners[i];
                    stream.Append(o);
                }
                stream.RestartStrip();
            }

            half4 Frag(G2F input) : SV_Target
            {
                clip(1.0 - dot(input.quadUV, input.quadUV));
                return half4(input.color, 1.0);
            }
            ENDHLSL
        }
    }

    Fallback Off
}
