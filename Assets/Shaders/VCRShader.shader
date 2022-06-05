Shader "PepEffect/VCR"
{
    Properties
    {
        _MainTex("(RGB)", 2D) = "" {}
        _Noise("Noise", 2D) = "" {}
        _Stripes("Stripes", float) = 1.
        _Noisy("Noisy", float) = 1.
        _VShift("Vertical Shift", float) = 5.
        _HShift("Horizontal Shift", float) = 2.
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

            float _Stripes;
            float _Noisy;
            float _VShift;
            float _HShift;

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

            float noise(float2 p)
            {
                float s = SAMPLE_TEXTURE2D(_Noise, sampler_Noise, float2 (1. , 2. * cos(_Time.y)) * _Time.y * 8. + p * 1.).x;
                s *= s;
                return s;
            }

            float onOff(float a, float b, float c)
            {
                return step(c, sin(_Time.y + a * cos(_Time.y * b)));
            }

            float ramp(float y, float start, float end)
            {
                float inside = step(start, y) - step(end, y);
                float fact = (y - start) / (end - start) * inside;
                return (1. - fact) * inside;
            }

            float stripes(float2 uv)
            {
                float noi = noise(uv * float2(0.5, 1.) + float2(1., 3.));
                return ramp(mod(uv.y * 4. + _Time.y / 2. + sin(_Time.y + sin(_Time.y * 0.63)), 1.), 0.5, 0.6) * noi;
            }

            float3 getVideo(float2 uv)
            {
                float2 look = uv;
                float window = 1. / (1. + 20. * (look.y - mod(_Time.y / 4., 1.)) * (look.y - mod(_Time.y / 4., 1.)));
                look.x = look.x + sin(look.y * 10. + _Time.y) / (50 / _HShift) * onOff(4., 4., .3) * (1. + cos(_Time.y * 80.)) * window;
                float vShift = 0.4 * onOff(2., 3., .9) * (sin(_Time.y) * sin(_Time.y * 20.) +
                    (0.5 + 0.1 * sin(_Time.y * 200.) * cos(_Time.y)));
                look.y = mod(look.y + vShift * _VShift, 1.);
                float3 rgb = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, look).rgb;
                float3 video = rgb;
                return video;
            }

            float2 screenDistort(float2 uv)
            {
                uv -= float2(.5, .5);
                uv = uv * 1.2 * (1. / 1.2 + 2. * uv.x * uv.x * uv.y * uv.y);
                uv += float2(.5, .5);
                return uv;
            }

            half4 PixelPass(PixelInput input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                half4 fragColor = half4(1, 1, 1, 1);
                float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w )) * _ScreenParams.xy;
                float2 uv = fragCoord.xy / _ScreenParams.xy;
                 
                uv = screenDistort(uv);
                float3 video = getVideo(uv);
                float vigAmt = 3. + .3 * sin(_Time.y + 5. * cos(_Time.y * 5.));
                float vignette = (1. - vigAmt * (uv.y - .5) * (uv.y - .5)) * (1. - vigAmt * (uv.x - .5) * (uv.x - .5));

                video += stripes(uv) * _Stripes;
                video += noise(uv) * _Noisy; // 2.;
                video *= vignette;
                video *= (12. + mod(uv.y * 30. + _Time.y, 1.)) / 13.;

                fragColor = float4(video, 1.0);
                return fragColor;
            }
            
            ENDHLSL
        }
    }
}
