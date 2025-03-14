Shader "URP/Water/S_UnderWater"
{
    Properties 
    {
        _UnderWaterColorA("UnderWaterColorA", Color) = (0,1,1,1)
        _UnderWaterColorB("UnderWaterColorB", Color) = (0,0,1,1)
        _DepthMaxDistance("DepthMaxDistance", Float) = 1
        _BaseMap("BaseMap", 2D) = "white" {}
    }
    SubShader 
    {
        Tags { "RenderPipeline" = "UniversalPipeline" }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        
        CBUFFER_START(UnityPerMaterial)
        float4 _UnderWaterColorA;
        float4 _UnderWaterColorB;
        float _DepthMaxDistance;
        float4 _BaseMap_ST;
        CBUFFER_END

		TEXTURE2D(_BaseMap);	SAMPLER(sampler_BaseMap);

        TEXTURE2D(_CameraOpaqueTexture);	    SAMPLER(sampler_CameraOpaqueTexture);
        TEXTURE2D_X_FLOAT(_CameraDepthTexture);     SAMPLER(sampler_CameraDepthTexture);
        ENDHLSL

        Pass {
            
            Blend SrcAlpha OneMinusSrcAlpha

//            ZWrite Off
            Stencil {
                Ref 5
                Comp NotEqual
            }
            
			HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            struct Attributes
			{
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
			{
                float4 positionHCS   : SV_POSITION;
                float4 positionSS : TEXCOORD0;
                float2 uv : TEXCOORD1;
                float2 uvSS : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings vert (Attributes input)
            {
                Varyings output;
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                // output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
                VertexPositionInputs positionInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionHCS = positionInput.positionCS;

                output.positionSS = ComputeScreenPos(positionInput.positionCS);
                output.uvSS = output.positionSS.xy / output.positionSS.w;
                return output;
            }


            half4 frag(Varyings input) : SV_Target
            {

                // Depth
                float depthColor = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, input.uvSS).r;   //采样深度值
                float depthColorEye = LinearEyeDepth(depthColor, _ZBufferParams);   //线性深度
                float depthDifference = depthColorEye - input.positionHCS.w;     //不同的深度值
                float waterScenesDepth = saturate(depthDifference / _DepthMaxDistance);

                float3 depthGradientColor = lerp(_UnderWaterColorA.rgb, _UnderWaterColorB.rgb, waterScenesDepth);
                
                float4 scenesColor = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, input.uvSS);
                scenesColor.rgb = lerp(depthGradientColor, scenesColor, 0.5);


                float3 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv).rgb;
                color = scenesColor.rgb * depthGradientColor;

                return float4(color.rgb, 1);
            }
            ENDHLSL
        }
    }
}
