Shader "PepEffect/CartoonShader"
{
    Properties
    {
        _MainTex("(RGB)", 2D) = "" {}
        _Lines("Lines", float) = 20.
        _Color ("Color", Color) = (1,1,1,1)
        _ColorLight("Color Light", Color) = (1,1,1,1)
        _ColorDark("Color Dark", Color) = (0,0,0,1)
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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            #pragma target 5.0            
            #pragma multi_compile_instancing
            #pragma vertex VertexShaderPass
            #pragma fragment PixelShaderPass
            #pragma enable_d3d11_debug_symbols
           

            float4 _MainTex_ST;
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            float _Lines;
            float4 _ColorLight;
            float4 _ColorDark;

            struct VertexInput
            {
                float4 worldPosition : POSITION;
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

            PixelInput VertexShaderPass(VertexInput input)
            {
                PixelInput output = (PixelInput)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                const VertexPositionInputs vertexInput = GetVertexPositionInputs(input.worldPosition.xyz);
                
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                output.positionCS = vertexInput.positionCS;
                output.screenPos = ComputeScreenPos(vertexInput.positionCS);
                return output;
            }

            float3 Outline(const float2 uv)
            {
                float4 lines = float4(0.30, 0.59, 0.11, 1.0);

                lines.rgb = lines.rgb * _Lines;


                const float s11 = dot(SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + float2 (-1.0 / _ScreenParams.x , -1.0 / _ScreenParams.y)), lines);
                // LEFT 
                const float s12 = dot(SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + float2 (0 , -1.0 / _ScreenParams.y)), lines); // MIDDLE 
                const float s13 = dot(SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + float2 (1.0 / _ScreenParams.x , -1.0 / _ScreenParams.y)), lines);
                // RIGHT 


                const float s21 = dot(SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + float2 (-1.0 / _ScreenParams.x , 0.0)), lines); // LEFT 
                // Omit center 
                const float s23 = dot(SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + float2 (-1.0 / _ScreenParams.x , 0.0)), lines); // RIGHT 

                const float s31 = dot(SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + float2 (-1.0 / _ScreenParams.x , 1.0 / _ScreenParams.y)), lines);
                // LEFT 
                const float s32 = dot(SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + float2 (0 , 1.0 / _ScreenParams.y)), lines); // MIDDLE 
                const float s33 = dot(SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + float2 (1.0 / _ScreenParams.x , 1.0 / _ScreenParams.y)), lines);
                // RIGHT 

                const float t1 = s13 + s33 + (2.0 * s23) - s11 - (2.0 * s21) - s31;
                const float t2 = s31 + (2.0 * s32) + s33 - s11 - (2.0 * s12) - s13;

                float3 col;

                if (((t1 * t1) + (t2 * t2)) > 0.04)
                {
                    col = _ColorLight.rgb;
                }
                else
                {
                    col = _ColorDark.rgb;
                }

                return col;
            }


            half4 PixelShaderPass(PixelInput input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w )) * _ScreenParams.xy;
                const float2 uv = fragCoord.xy / _ScreenParams.xy;
                
                float3 color = float3(0.0f, 0.0f, 0.0f);
                color.rgb += Outline(uv);
                return float4(color, 1.);
            }
            
            ENDHLSL
        }
    }
}
