// Void Cloak particle shader (URP).
//
// Each vertex of the MeshTopology.Points mesh is one cloth particle. The geometry shader
// expands it into a small camera facing quad, stretched along the cloth flow direction.
// The quad corner coordinate is passed as a regular TEXCOORD, so SV_PointCoord is NOT used
// (it fails on D3D11 ps_4_0: "invalid ps_4_0 input semantic 'SV_PointCoord'").
//
// Vertex data written by VoidCloakCharacter.cs:
//   POSITION  particle position (object space)
//   NORMAL    cloth normal
//   TANGENT   xyz = flow direction along the folds, w = layer (-1 back .. +1 front)
//   COLOR     r = part id / 32, g = major ridge (0 valley .. 1 crest), b = void amount, a = random
//   TEXCOORD0 x = size multiplier, y = wind weight
//   TEXCOORD1 x = secondary ridge (0..1), y = baked occlusion
//   TEXCOORD2 x = material (0 cloth, 1 steel, 2 leather), y = floor (1 = cloth lying on the ground)
Shader "VoidCloak/ClothPoint"
{
    Properties
    {
        [Header(Particles)]
        _PointSize ("Point Size (world)", Float) = 0.016
        _PointVariation ("Point Size Variation", Range(0, 1)) = 0.2
        _FlowStretch ("Stretch Along Folds", Range(0, 3)) = 0.8
        _EdgeSoftness ("Disc Edge Softness", Range(0.01, 1)) = 0.35

        [Header(Cloth Color)]
        _BaseColor ("Base Color", Color) = (0.022, 0.022, 0.026, 1)
        _SheenColor ("Sheen / Highlight Color", Color) = (0.62, 0.64, 0.68, 1)
        _AmbientColor ("Ambient", Color) = (0.35, 0.35, 0.38, 1)

        [Header(Fake Light)]
        _LightDirection ("Fake Light Direction (world)", Vector) = (-0.45, 0.75, 0.6, 0)
        _LightColor ("Fake Light Color", Color) = (1, 1, 1, 1)
        _MainLightInfluence ("Use URP Main Light", Range(0, 1)) = 0
        _DiffuseStrength ("Diffuse", Range(0, 4)) = 1.5
        _WrapDiffuse ("Diffuse Wrap", Range(0, 1)) = 0.5

        [Header(Satin Specular)]
        _SpecularStrength ("Specular", Range(0, 2)) = 0.42
        _AnisoAlong ("Roughness Along Folds", Range(0.05, 1.5)) = 0.55
        _AnisoAcross ("Roughness Across Folds", Range(0.02, 1)) = 0.16
        _RidgeHighlight ("Extra Highlight On Crests", Range(0, 3)) = 0.9
        _ValleyDarkening ("Valley Darkening", Range(0, 1)) = 0.35

        [Header(Rim)]
        _RimColor ("Rim Color", Color) = (0.3, 0.32, 0.36, 1)
        _RimStrength ("Rim Strength", Range(0, 2)) = 0.25
        _RimPower ("Rim Power", Range(0.5, 8)) = 4

        [Header(Void)]
        _VoidColor ("Hood Void Color", Color) = (0.004, 0.004, 0.005, 1)
        _VoidDepthVariation ("Void Depth Variation", Range(0, 1)) = 0.35
        _BackfaceDarkness ("Inside Of Cloth Brightness", Range(0, 1)) = 0.12

        [Header(Wind)]
        _WindStrength ("Wind Strength", Float) = 0.04
        _WindSpeed ("Wind Speed", Float) = 1.2
        _WindFrequency ("Wind Frequency", Float) = 1.3
        _WindDirection ("Wind Direction (object)", Vector) = (1, 0, 0.35, 0)
        _WindFlutter ("Small Flutter", Range(0, 1)) = 0.25

        [Header(Sword)]
        _SteelColor ("Steel Color", Color) = (0.42, 0.43, 0.45, 1)
        _SteelEnvLow ("Steel Reflection (below horizon)", Color) = (0.03, 0.03, 0.035, 1)
        _SteelEnvHigh ("Steel Reflection (sky)", Color) = (0.58, 0.6, 0.64, 1)
        _SteelReflection ("Steel Reflection Strength", Range(0, 2)) = 0.55
        _SteelSpecular ("Steel Specular", Range(0, 4)) = 1.6
        _SteelGloss ("Steel Gloss", Range(4, 512)) = 90
        _GripColor ("Grip Leather Color", Color) = (0.07, 0.045, 0.03, 1)

        [Header(Walking set by VoidCloakMover)]
        _MotionLag ("Motion Lag (object)", Vector) = (0, 0, 0, 0)
        _Gait ("Gait (phase, push, bob, billow)", Vector) = (0, 0, 0, 0)
        _FloorMotion ("Floor Cloth (follow, lift)", Vector) = (0.85, 0.3, 0, 0)

        [Header(Debug)]
        [Toggle] _DebugParts ("Show Part Colors", Float) = 0
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "Queue" = "Geometry" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            Name "VoidCloakForward"
            Tags { "LightMode" = "UniversalForward" }

            Cull Off
            ZWrite On
            ZTest LEqual

            HLSLPROGRAM
            // Geometry shaders need shader model 4.0 (D3D11 / Vulkan / OpenGL Core / GLES 3.2).
            #pragma target 4.0
            #pragma require geometry
            #pragma vertex Vert
            #pragma geometry Geom
            #pragma fragment Frag
            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float _PointSize;
                float _PointVariation;
                float _FlowStretch;
                float _EdgeSoftness;
                float4 _BaseColor;
                float4 _SheenColor;
                float4 _AmbientColor;
                float4 _LightDirection;
                float4 _LightColor;
                float _MainLightInfluence;
                float _DiffuseStrength;
                float _WrapDiffuse;
                float _SpecularStrength;
                float _AnisoAlong;
                float _AnisoAcross;
                float _RidgeHighlight;
                float _ValleyDarkening;
                float4 _RimColor;
                float _RimStrength;
                float _RimPower;
                float4 _VoidColor;
                float _VoidDepthVariation;
                float _BackfaceDarkness;
                float _WindStrength;
                float _WindSpeed;
                float _WindFrequency;
                float4 _WindDirection;
                float _WindFlutter;
                float _DebugParts;
                float4 _SteelColor;
                float4 _SteelEnvLow;
                float4 _SteelEnvHigh;
                float _SteelReflection;
                float _SteelSpecular;
                float _SteelGloss;
                float4 _GripColor;
                float4 _MotionLag;
                float4 _Gait;
                float4 _FloorMotion;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float4 tangentOS  : TANGENT;
                float4 color      : COLOR;
                float2 uv0        : TEXCOORD0;
                float2 uv1        : TEXCOORD1;
                float2 uv2        : TEXCOORD2;
            };

            struct V2G
            {
                float4 positionCS : SV_POSITION;   // unused by the GS, kept for strict compilers
                float3 positionWS : TEXCOORD0;
                float3 normalWS   : TEXCOORD1;
                float4 flowWS     : TEXCOORD2;   // xyz flow, w layer
                float4 data       : TEXCOORD3;   // part, ridge, void, random
                float4 extra      : TEXCOORD4;   // size, wind, secondary, ao
                float material    : TEXCOORD5;   // 0 cloth, 1 steel, 2 leather
            };

            struct G2F
            {
                float4 positionCS : SV_POSITION;
                float2 quadUV     : TEXCOORD0;   // replaces SV_PointCoord, -1..1
                float3 positionWS : TEXCOORD1;
                float3 normalWS   : TEXCOORD2;
                float3 flowWS     : TEXCOORD3;
                float4 data       : TEXCOORD4;
                float4 extra      : TEXCOORD5;
                float fogFactor   : TEXCOORD6;
                float material    : TEXCOORD7;
            };

            // ---------------------------------------------------------------- wind
            float3 WindOffset(float3 positionOS, float weight, float rnd)
            {
                float t = _Time.y * _WindSpeed;
                float3 dir = normalize(_WindDirection.xyz + float3(1e-4, 0, 0));
                // large slow swell travelling down the cloak + smaller gusts
                float swell = sin(t + positionOS.y * _WindFrequency + positionOS.x * 0.7);
                float gust  = sin(t * 2.3 + positionOS.y * _WindFrequency * 2.7 + positionOS.z * 1.9) * 0.35;
                float flutter = sin(t * 7.0 + rnd * 40.0) * _WindFlutter * 0.15;
                float3 offset = dir * (swell + gust + flutter);
                offset.y += (swell * 0.15 + flutter) * 0.2;
                return offset * (_WindStrength * weight);
            }

            // ---------------------------------------------------------- walking / running
            // The hem trails behind the motion, each step pushes the front of the cloak
            // forward on one side, and the whole figure bobs a little. While running
            // (_Gait.w = billow) the trailing side puffs out and lifts, waves run down the
            // cloak and the hem flaps. The wind weight (0 on hood / shoulders / sword,
            // 1 at the hem) decides how much each point moves. Cloth lying on the floor
            // (floorAmount = 1) is dragged along like a train and lifts off the ground.
            float3 MotionOffset(float3 positionOS, float windWeight, float floorAmount)
            {
                float weight = max(windWeight, floorAmount * _FloorMotion.x);
                float w2 = weight * weight;
                float billow = _Gait.w;

                float lagLen = length(_MotionLag.xz);
                float2 trailDir = lagLen > 1e-4 ? -_MotionLag.xz / lagLen : float2(0.0, 0.0);  // where the cloth streams to
                float2 radial = positionOS.xz / max(length(positionOS.xz), 1e-3);
                float behind = saturate(dot(radial, trailDir));                                  // 1 on the trailing side

                // trailing: the back of the cloak puffs out, the front is pressed against the body
                float puff = 0.65 + 0.7 * behind * (0.5 + 0.5 * saturate(billow));
                float3 offset = float3(trailDir.x, 0.0, trailDir.y) * (lagLen * w2 * puff);
                offset.y += lagLen * w2 * (0.12 + 0.3 * behind * saturate(billow));             // streaming cloth lifts

                // billow: waves travelling from the shoulders down to the hem
                float t = _Time.y;
                float wave = sin(t * 8.0 - positionOS.y * 2.3 + positionOS.x * 1.7)
                           + 0.5 * sin(t * 13.0 - positionOS.y * 3.9 - positionOS.z * 2.3);
                offset.xz += trailDir * (wave * billow * weight * 0.1 * (0.4 + behind));
                offset.y += wave * billow * w2 * 0.05;
                // hem flapping sideways
                offset.x += sin(t * 6.5 + positionOS.y * 1.3 + positionOS.z * 1.1) * billow * w2 * 0.07;

                // the train on the floor rises and ripples while running, most on the trailing side
                float floorWave = 0.75 + 0.25 * sin(t * 9.0 - length(positionOS.xz) * 3.0 + positionOS.x * 1.3);
                offset.y += floorAmount * billow * _FloorMotion.y * (0.35 + 0.65 * behind) * floorWave;

                // steps
                float side = clamp(positionOS.x / 0.5, -1.0, 1.0);       // left / right leg
                float front = saturate(positionOS.z / 0.8 + 0.4);        // mostly the front of the cloak
                offset.z += sin(_Gait.x) * side * front * _Gait.y * weight;

                offset.y += _Gait.z * saturate(positionOS.y / 1.5);       // body bob, cloth on the floor stays down
                return offset;
            }

            V2G Vert(Attributes input)
            {
                V2G o;
                float rnd = input.color.a;
                float3 posOS = input.positionOS.xyz + WindOffset(input.positionOS.xyz, input.uv0.y, rnd)
                             + MotionOffset(input.positionOS.xyz, input.uv0.y, input.uv2.y);
                // cloth on the floor never sinks below it
                if (input.uv2.y > 0.01) posOS.y = max(posOS.y, 0.003);
                o.positionWS = TransformObjectToWorld(posOS);
                o.positionCS = TransformWorldToHClip(o.positionWS);
                o.normalWS = TransformObjectToWorldNormal(input.normalOS);
                o.flowWS = float4(TransformObjectToWorldDir(input.tangentOS.xyz), input.tangentOS.w);
                o.data = input.color;
                o.extra = float4(input.uv0.x, input.uv0.y, input.uv1.x, input.uv1.y);
                o.material = input.uv2.x;
                return o;
            }

            // --------------------------------------------------------- point -> quad
            [maxvertexcount(4)]
            void Geom(point V2G input[1], inout TriangleStream<G2F> stream)
            {
                V2G p = input[0];

                float rnd = p.data.a;
                float size = _PointSize * p.extra.x * (1.0 + (rnd - 0.5) * 2.0 * _PointVariation);
                float3 centerVS = TransformWorldToView(p.positionWS);

                // stretch the particle along the projected cloth flow (fibres along the folds)
                float3 flowVS = TransformWorldToViewDir(p.flowWS.xyz, false);
                float2 axisA = flowVS.xy;
                float len = length(axisA);
                axisA = len > 1e-4 ? axisA / len : float2(0, 1);
                float stretch = 1.0 + _FlowStretch * saturate(len);
                float2 axisB = float2(-axisA.y, axisA.x);

                float2 corners[4] = { float2(-1, -1), float2(1, -1), float2(-1, 1), float2(1, 1) };

                G2F o;
                o.positionWS = p.positionWS;
                o.normalWS = p.normalWS;
                o.flowWS = p.flowWS.xyz;
                o.data = p.data;
                o.extra = p.extra;
                o.material = p.material;

                [unroll]
                for (int i = 0; i < 4; i++)
                {
                    float2 c = corners[i];
                    float3 vs = centerVS;
                    vs.xy += (axisA * (c.y * stretch) + axisB * c.x) * size;
                    o.positionCS = TransformWViewToHClip(vs);
                    o.quadUV = c;
                    o.fogFactor = ComputeFogFactor(o.positionCS.z);
                    stream.Append(o);
                }
                stream.RestartStrip();
            }

            // ---------------------------------------------------------------- shading
            float3 PartColor(float id)
            {
                // cheap distinct palette for the debug view
                float3 h = frac(float3(0.0, 0.33, 0.67) + id * 0.137);
                return saturate(abs(h * 6.0 - 3.0) - 1.0) * 0.8 + 0.2;
            }

            half4 Frag(G2F input) : SV_Target
            {
                // round disc; alpha-tested so the cloth keeps a clean depth buffer (no smoke look)
                float r2 = dot(input.quadUV, input.quadUV);
                float rnd = input.data.a;
                float threshold = 1.0 - _EdgeSoftness * 0.5 * rnd;
                clip(threshold - r2);

                float partId = floor(input.data.r * 32.0);
                float ridge = input.data.g * 2.0 - 1.0;
                float voidAmount = input.data.b;
                float secondary = input.extra.z * 2.0 - 1.0;
                float ao = input.extra.w;

                float3 N = normalize(input.normalWS);
                float3 V = normalize(GetWorldSpaceViewDir(input.positionWS));

                // slight dome per particle so a group of points shades like a soft surface
                float3 viewRight = UNITY_MATRIX_V[0].xyz;
                float3 viewUp = UNITY_MATRIX_V[1].xyz;
                N = normalize(N + (viewRight * input.quadUV.x + viewUp * input.quadUV.y) * 0.15);

                // the inside of the cloak (and the inside of the hood) is in shadow
                float NdotV = dot(N, V);
                float inside = NdotV < 0.0 ? 1.0 : 0.0;
                N = NdotV < 0.0 ? -N : N;
                NdotV = abs(NdotV);

                float3 L = normalize(_LightDirection.xyz);
                float3 lightColor = _LightColor.rgb;
                if (_MainLightInfluence > 0.0)
                {
                    Light mainLight = GetMainLight();
                    L = normalize(lerp(L, mainLight.direction, _MainLightInfluence));
                    lightColor = lerp(lightColor, mainLight.color, _MainLightInfluence);
                }

                float NdotL = dot(N, L);
                float wrapped = saturate((NdotL + _WrapDiffuse) / (1.0 + _WrapDiffuse));
                float diffuse = wrapped * wrapped * _DiffuseStrength;

                // satin: anisotropic (Ward style) lobe, wide along the folds and narrow across,
                // which turns every fold crest into a long thin highlight
                float3 T = normalize(input.flowWS - N * dot(input.flowWS, N) + 1e-5);
                float3 B = cross(N, T);
                float3 H = normalize(L + V);
                float ht = dot(H, T) / _AnisoAlong;
                float hb = dot(H, B) / _AnisoAcross;
                float hn = max(dot(H, N), 1e-3);
                float spec = exp(-(ht * ht + hb * hb) / (hn * hn)) * sqrt(saturate(NdotL));

                float crest = saturate(ridge) + 0.4 * saturate(secondary);
                float valley = saturate(-ridge);
                float occlusion = ao * (1.0 - _ValleyDarkening * valley);

                float material = floor(input.material + 0.5);
                float3 baseColor = material > 1.5 ? _GripColor.rgb : _BaseColor.rgb;
                float specScale = material > 1.5 ? 0.35 : 1.0;

                float3 color = baseColor * (_AmbientColor.rgb + diffuse * lightColor) * occlusion;
                color += _SheenColor.rgb * lightColor * spec * _SpecularStrength * specScale * (0.55 + _RidgeHighlight * crest) * occlusion;
                color += _RimColor.rgb * pow(1.0 - NdotV, _RimPower) * _RimStrength * occlusion;

                if (material > 0.5 && material < 1.5)
                {
                    // steel: dark metal body + fake sky / ground reflection + tight highlight,
                    // edges (ridge channel) catch a bit more light
                    float3 R = reflect(-V, N);
                    float horizon = exp(-R.y * R.y * 30.0) * 0.35;
                    float3 env = lerp(_SteelEnvLow.rgb, _SteelEnvHigh.rgb, smoothstep(-0.15, 0.35, R.y)) + _SteelEnvHigh.rgb * horizon;
                    float fresnel = 0.6 + 0.4 * pow(1.0 - NdotV, 3.0);
                    float steelSpec = pow(saturate(dot(N, H)), _SteelGloss) * _SteelSpecular;
                    float edgeGlow = 1.0 + 0.6 * saturate(ridge);
                    color = _SteelColor.rgb * (0.15 + 0.35 * wrapped) * lightColor
                          + env * _SteelReflection * fresnel * edgeGlow
                          + steelSpec * lightColor;
                }
                else
                {
                    color *= lerp(1.0, _BackfaceDarkness, inside);
                }

                // hood void: almost black, with a hint of depth so it is not a flat plate
                float depthHint = 1.0 - _VoidDepthVariation + _VoidDepthVariation * rnd * NdotV;
                color = lerp(color, _VoidColor.rgb * depthHint, saturate(voidAmount));

                if (_DebugParts > 0.5)
                {
                    color = PartColor(partId) * (0.3 + 0.7 * saturate(dot(N, normalize(float3(-0.4, 0.7, 0.6)))));
                }

                color = MixFog(color, input.fogFactor);
                return half4(color, 1.0);
            }
            ENDHLSL
        }
    }

    Fallback Off
}
