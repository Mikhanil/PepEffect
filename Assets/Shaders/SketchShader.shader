Shader "PepEffect/Skecth"
{
    Properties
    {
        _MainTex("(RGB)", 2D) = "" {}
        _Noise("Noise", 2D) = "" {}
        [HideInInspector] _RANGE("", float) = 16.
        [HideInInspector] _STEP("", float) = 2.
        _ANGLE("Angle", float) = 1.65
        _THRESHOLD("THRESHOLD", float) = 0.01
        _SENSITIVITY("Sensitivity", float) = 1.
        _COLOR("Color", float) = 1.

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
            float4 _Noise_ST;
            TEXTURE2D(_Noise);
            SAMPLER(sampler_Noise);

            float _RANGE;
            float _STEP;
            float _ANGLE;
            float _THRESHOLD;
            float _SENSITIVITY;
            float _COLOR;
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


            #define PI2 6.28318530717959

            float4 getCol(float2 pos)
            {
                float2 uv = pos / _ScreenParams.xy;
                return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
            }

            float getVal(float2 pos)
            {
                float4 c = getCol(pos);
                return dot(c.xyz, float3(0.2126, 0.7152, 0.0722));
            }

            float2 getGrad(float2 pos, float eps)
            {
                float2 d = float2(eps, 0);
                return float2(
                    getVal(pos + d.xy) - getVal(pos - d.xy),
                    getVal(pos + d.yx) - getVal(pos - d.yx)
                ) / eps / 2.;
            }

            void pR(inout float2 p, float a)
            {
                p = cos(a) * p + sin(a) * float2(p.y, -p.x);
            }

            float absCircular(float t)
            {
                float a = floor(t + 0.5);
                return mod(abs(a - t), 1.0);
            }

            half4 PixelPass(PixelInput input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                half4 fragColor = half4(1, 1, 1, 1);
                float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;

                float2 pos = fragCoord;
                float weight = 1.0;

                [unroll(4)]
                for (float j = 0.; j < _ANGLE; j += 1.)
                {
                    float2 dir = float2(1, 0);
                    pR(dir, j * PI2 / (2. * _ANGLE));

                    float2 grad = float2(-dir.y, dir.x);
                    
                    [unroll(16)]
                    for (float i = -_RANGE; i <= _RANGE; i += _STEP)
                    {
                        float2 pos2 = pos + normalize(dir) * i;

                        if (pos2.y < 0. || pos2.x < 0. || pos2.x > _ScreenParams.x || pos2.y > _ScreenParams.y)
                            continue;

                        float2 g = getGrad(pos2, 1.);
                        if (length(g) < _THRESHOLD)
                            continue;

                        weight -= pow(abs(dot(normalize(grad), normalize(g))), _SENSITIVITY) / floor((2. * _RANGE + 1.) / _STEP) / _ANGLE;
                    }
                }

                #ifndef GRAYSCALE
                float4 col = getCol(pos);
                #else
                float4 col = float4 (getVal(pos));
                #endif

                float4 background = lerp(col, float4(1, 1, 1, 1), _COLOR);

                float r = length(pos - _ScreenParams.xy * .5) / _ScreenParams.x;
                float vign = 1. - r * r * r;

                float4 a = SAMPLE_TEXTURE2D(_Noise, sampler_Noise, pos / _ScreenParams.xy);

                fragColor = vign * lerp(float4(0, 0, 0, 0), background, weight) + a.xxxx / 25.;
                return fragColor;
            }            
            ENDHLSL
        }
    }
}
