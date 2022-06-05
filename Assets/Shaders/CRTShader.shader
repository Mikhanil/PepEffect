Shader "PepEffect/CRTShader"
{
    Properties
    {
        _MainTex("(RGB)", 2D) = "" {}
        _SCAN("Scan",float) = 1.7
        _BRIGHTNESS("Brightness",float) = 3
        _OFFSET("Offset",float) = 1
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Transparent" "RenderPipeline" = "UniversalRenderPipeline" "IgnoreProjector" = "True"
        }
        LOD 300

        Pass
        {
            Name "StandardLit"
            HLSLPROGRAM
            #pragma target 2.0

            #pragma multi_compile_instancing

            #pragma vertex VertexPass
            #pragma fragment PixelPass

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            float4 _MainTex_ST;
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            float _SCAN;
            float _BRIGHTNESS;
            float _OFFSET;
            float _IsScreenSpace;

            struct VertexInput
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct PixelInput
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                float4 screenPos : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            PixelInput VertexPass(VertexInput input)
            {
                PixelInput output = (PixelInput)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);


                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                output.positionCS = vertexInput.positionCS;
                output.screenPos = ComputeScreenPos(vertexInput.positionCS);
                return output;
            }
            
            float mod(float a, float b)
            {
                return a - floor(a / b) * b;
            }

            float2 mod(float2 a, float2 b)
            {
                return a - floor(a / b) * b;
            }

            float3 mod(float3 a, float3 b)
            {
                return a - floor(a / b) * b;
            }

            float4 mod(float4 a, float4 b)
            {
                return a - floor(a / b) * b;
            }

            float2 curve(float2 uv)
            {
                uv = (uv - 0.5) * 2.0;
                uv *= 1.1;
                uv.x *= 1.0 + pow((abs(uv.y) / 5.0), 2.0);
                uv.y *= 1.0 + pow((abs(uv.x) / 4.), 2.0);
                uv = (uv / 2.0) + 0.5;
                uv = uv * 0.92 + 0.04;
                return uv;
            }

            half4 PixelPass(PixelInput input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                half4 fragColor = half4(1, 1, 1, 1);
                float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w)) * _ScreenParams.xy;
                float2 q = fragCoord.xy / _ScreenParams.xy;
                float2 uv = q;
                if (_IsScreenSpace < 0.5)
                    uv = input.uv;
                uv = curve(uv);
                float3 col;
                float x = sin(0.3 * _Time.y + uv.y * 21.0) * sin(0.7 * _Time.y + uv.y * 29.0) * sin(0.3 + 0.33 * _Time.y + uv.y * 31.0) * 0.0017;

                col.r = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2 (x + uv.x + 0.001 , uv.y + 0.001)).x + 0.05;
                col.g = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2 (x + uv.x + 0.000 , uv.y - 0.002)).y + 0.05;
                col.b = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2 (x + uv.x - 0.002 , uv.y + 0.000)).z + 0.05;
                col.r += 0.001 * _OFFSET * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex,
                                                            0.75 * float2 (x + 0.025 , -0.027) + float2 (uv.x + 0.001 , uv.y + 0.001)).x;
                col.g += 0.002 * _OFFSET * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex,
                                                            0.75 * float2 (x + -0.022 , -0.02) + float2 (uv.x + 0.000 , uv.y - 0.002)).y;
                col.b += 0.003 * _OFFSET * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex,
                                                            0.75 * float2 (x + -0.02 , -0.018) + float2 (uv.x - 0.002 , uv.y + 0.000)).z;

                col = clamp(col * (0.6 + 0.4 * col), 0.0, 1.0);

                float vig = (0.0 + 1.0 * 16.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y));
                float figP = pow(vig, 0.3);
                col *= float3(figP, figP, figP);

                col *= float3(0.95, 1.05, 0.95);
                col *= _BRIGHTNESS;

                const float scans = clamp(0.35 + 0.35 * sin(3.5 * _Time.y + uv.y * _ScreenParams.y * 1.5), 0.0, 1.0);

                const float s = pow(scans, _SCAN);
                col = col * float3(0.4 + 0.7 * s, 0.4 + 0.7 * s, 0.4 + 0.7 * s);

                col *= 1.0 + 0.01 * sin(110.0 * _Time.y);
                if (uv.x < 0.0 || uv.x > 1.0)
                    col *= 0.0;
                if (uv.y < 0.0 || uv.y > 1.0)
                    col *= 0.0;

                float cl = clamp((mod(fragCoord.x, 2.0) - 1.0) * 2.0, 0.0, 1.0);
                col *= 1.0 - 0.65 * float3(cl, cl, cl);

                fragColor = float4(col, 1.0);
                return fragColor;
            }
            ENDHLSL
        }
    }
}
