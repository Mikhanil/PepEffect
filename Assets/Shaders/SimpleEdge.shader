Shader "PepEffect/SimpleEdge"
{
    Properties
    {
        _MainTex("(RGB)", 2D) = "" {}
        _Multiplier("Multiplier", float) = 1
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

            float _Multiplier;

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

            half4 PixelPass(PixelInput input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                half4 fragColor = half4(1, 1, 1, 1);
                float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;

                float3 c[9];
                for (int i = 0; i < 3; ++i)
                {
                    for (int j = 0; j < 3; ++j)
                    {
                        c[3 * i + j] = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, (fragCoord.xy + float2 (i - 1 , j - 1)) / _ScreenParams.xy).rgb;
                    }
                }

                float3 Lx = _Multiplier * (c[7] - c[1]) + c[6] + c[8] - c[2] - c[0];
                float3 Ly = _Multiplier * (c[3] - c[5]) + c[6] + c[0] - c[2] - c[8];
                float3 G = sqrt(Lx * Lx + Ly * Ly);

                fragColor = float4(G, 1.0);
                return fragColor;
            }
            ENDHLSL
        }
    }
}
