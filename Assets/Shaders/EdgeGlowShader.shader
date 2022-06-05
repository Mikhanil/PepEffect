Shader "PepEffect/EdgeGlow"
{
     Properties
    {
        _MainTex("(RGB)", 2D) = "" {}
        _Scale("Scale", float) = 0.5
        [HDR]_EdgeColor("Color", Color) = (1,1,1,1)
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
            #pragma multi_compile_instancing

            #pragma vertex VertexPass
            #pragma fragment PixelPass

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            float4 _MainTex_ST;
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            float _Scale;
            float4 _EdgeColor;

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


            float lookup(float2 p, float dx, float dy)
            {
                float2 uv = (p.xy + float2(dx * _Scale, dy * _Scale)) / _ScreenParams.xy;
                float4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv.xy);
                return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b;
            }

            half4 PixelPass(PixelInput input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
                float2 p = fragCoord.xy;

                float gx = 0.0;
                gx += -1.0 * lookup(p, -1.0, -1.0);
                gx += -2.0 * lookup(p, -1.0, 0.0);
                gx += -1.0 * lookup(p, -1.0, 1.0);
                gx += 1.0 * lookup(p, 1.0, -1.0);
                gx += 2.0 * lookup(p, 1.0, 0.0);
                gx += 1.0 * lookup(p, 1.0, 1.0);

                float gy = 0.0;
                gy += -1.0 * lookup(p, -1.0, -1.0);
                gy += -2.0 * lookup(p, 0.0, -1.0);
                gy += -1.0 * lookup(p, 1.0, -1.0);
                gy += 1.0 * lookup(p, -1.0, 1.0);
                gy += 2.0 * lookup(p, 0.0, 1.0);
                gy += 1.0 * lookup(p, 1.0, 1.0);

                float g = gx + gy;

                float4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, p / _ScreenParams.xy);
                col = lerp(col, _EdgeColor, g);
                col = _EdgeColor * g;

                half4 fragColor = col;
                return fragColor;
            }
            ENDHLSL
        }
    }
}
