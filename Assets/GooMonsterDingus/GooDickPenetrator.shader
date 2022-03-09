// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "GooDickPenetrator"
{
	Properties
	{
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[ASEBegin]_PenetratorOrigin("PenetratorOrigin", Vector) = (0,0,0,0)
		_PenetratorForward("PenetratorForward", Vector) = (0,0,1,0)
		_PenetratorLength("PenetratorLength", Float) = 1
		_PenetratorUp("PenetratorUp", Vector) = (0,1,0,0)
		_PenetratorRight("PenetratorRight", Vector) = (1,0,0,0)
		_OrificeOutWorldPosition1("OrificeOutWorldPosition1", Vector) = (0,0.33,0,0)
		_OrificeOutWorldPosition3("OrificeOutWorldPosition3", Vector) = (0,1,0,0)
		_OrificeWorldPosition("OrificeWorldPosition", Vector) = (0,0,0,0)
		_OrificeOutWorldPosition2("OrificeOutWorldPosition2", Vector) = (0,0.66,0,0)
		_OrificeWorldNormal("OrificeWorldNormal", Vector) = (0,-1,0,0)
		_PenetrationDepth("PenetrationDepth", Range( -1 , 10)) = 0
		_PenetratorBlendshapeMultiplier("PenetratorBlendshapeMultiplier", Range( 0 , 100)) = 1
		_OrificeLength("OrificeLength", Float) = 1
		_PenetratorBulgePercentage("PenetratorBulgePercentage", Range( 0 , 1)) = 0
		_PenetratorCumProgress("PenetratorCumProgress", Range( -1 , 2)) = 0
		_PenetratorSquishPullAmount("PenetratorSquishPullAmount", Range( -1 , 1)) = 0
		_PenetratorCumActive("PenetratorCumActive", Range( 0 , 1)) = 0
		_InvisibleWhenInside("InvisibleWhenInside", Range( 0 , 1)) = 0
		_DeformBalls("DeformBalls", Range( 0 , 1)) = 0
		_ClipDick("ClipDick", Range( 0 , 1)) = 0
		_NoBlendshapes("NoBlendshapes", Range( 0 , 1)) = 0
		_PinchBuffer("PinchBuffer", Range( 0 , 0.5)) = 0.25
		_BaseColorMap("BaseColorMap", 2D) = "white" {}
		_NormalMap("NormalMap", 2D) = "bump" {}
		_MetallicSmoothness("MetallicSmoothness", 2D) = "gray" {}
		_EmissionColor("EmissionColor", Color) = (0,0,0,0)
		_BulgeDistance("BulgeDistance", Range( 0 , 5)) = 1
		_Foam("Foam", 2D) = "white" {}
		_FoamNormal("FoamNormal", 2D) = "bump" {}
		[ASEEnd]_EmissionMap("_EmissionMap", 2D) = "white" {}
		[HideInInspector] _texcoord( "", 2D ) = "white" {}

		//_TransmissionShadow( "Transmission Shadow", Range( 0, 1 ) ) = 0.5
		//_TransStrength( "Trans Strength", Range( 0, 50 ) ) = 1
		//_TransNormal( "Trans Normal Distortion", Range( 0, 1 ) ) = 0.5
		//_TransScattering( "Trans Scattering", Range( 1, 50 ) ) = 2
		//_TransDirect( "Trans Direct", Range( 0, 1 ) ) = 0.9
		//_TransAmbient( "Trans Ambient", Range( 0, 1 ) ) = 0.1
		//_TransShadow( "Trans Shadow", Range( 0, 1 ) ) = 0.5
		//_TessPhongStrength( "Tess Phong Strength", Range( 0, 1 ) ) = 0.5
		//_TessValue( "Tess Max Tessellation", Range( 1, 32 ) ) = 16
		//_TessMin( "Tess Min Distance", Float ) = 10
		//_TessMax( "Tess Max Distance", Float ) = 25
		//_TessEdgeLength ( "Tess Edge length", Range( 2, 50 ) ) = 16
		//_TessMaxDisp( "Tess Max Displacement", Float ) = 25
	}

	SubShader
	{
		LOD 0

		

		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" }
		Cull Back
		AlphaToMask Off
		
		HLSLINCLUDE
		#pragma target 3.0

		#pragma prefer_hlslcc gles
		#pragma exclude_renderers d3d11_9x 

		#ifndef ASE_TESS_FUNCS
		#define ASE_TESS_FUNCS
		float4 FixedTess( float tessValue )
		{
			return tessValue;
		}
		
		float CalcDistanceTessFactor (float4 vertex, float minDist, float maxDist, float tess, float4x4 o2w, float3 cameraPos )
		{
			float3 wpos = mul(o2w,vertex).xyz;
			float dist = distance (wpos, cameraPos);
			float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
			return f;
		}

		float4 CalcTriEdgeTessFactors (float3 triVertexFactors)
		{
			float4 tess;
			tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
			tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
			tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
			tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
			return tess;
		}

		float CalcEdgeTessFactor (float3 wpos0, float3 wpos1, float edgeLen, float3 cameraPos, float4 scParams )
		{
			float dist = distance (0.5 * (wpos0+wpos1), cameraPos);
			float len = distance(wpos0, wpos1);
			float f = max(len * scParams.y / (edgeLen * dist), 1.0);
			return f;
		}

		float DistanceFromPlane (float3 pos, float4 plane)
		{
			float d = dot (float4(pos,1.0f), plane);
			return d;
		}

		bool WorldViewFrustumCull (float3 wpos0, float3 wpos1, float3 wpos2, float cullEps, float4 planes[6] )
		{
			float4 planeTest;
			planeTest.x = (( DistanceFromPlane(wpos0, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[0]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.y = (( DistanceFromPlane(wpos0, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[1]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.z = (( DistanceFromPlane(wpos0, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[2]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.w = (( DistanceFromPlane(wpos0, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[3]) > -cullEps) ? 1.0f : 0.0f );
			return !all (planeTest);
		}

		float4 DistanceBasedTess( float4 v0, float4 v1, float4 v2, float tess, float minDist, float maxDist, float4x4 o2w, float3 cameraPos )
		{
			float3 f;
			f.x = CalcDistanceTessFactor (v0,minDist,maxDist,tess,o2w,cameraPos);
			f.y = CalcDistanceTessFactor (v1,minDist,maxDist,tess,o2w,cameraPos);
			f.z = CalcDistanceTessFactor (v2,minDist,maxDist,tess,o2w,cameraPos);

			return CalcTriEdgeTessFactors (f);
		}

		float4 EdgeLengthBasedTess( float4 v0, float4 v1, float4 v2, float edgeLength, float4x4 o2w, float3 cameraPos, float4 scParams )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;
			tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
			tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
			tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
			tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			return tess;
		}

		float4 EdgeLengthBasedTessCull( float4 v0, float4 v1, float4 v2, float edgeLength, float maxDisplacement, float4x4 o2w, float3 cameraPos, float4 scParams, float4 planes[6] )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;

			if (WorldViewFrustumCull(pos0, pos1, pos2, maxDisplacement, planes))
			{
				tess = 0.0f;
			}
			else
			{
				tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
				tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
				tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
				tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			}
			return tess;
		}
		#endif //ASE_TESS_FUNCS

		ENDHLSL

		
		Pass
		{
			
			Name "Forward"
			Tags { "LightMode"="UniversalForward" }
			
			Blend One Zero, One Zero
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA
			

			HLSLPROGRAM
			
			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_instancing
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define ASE_ABSOLUTE_VERTEX_POS 1
			#define _EMISSION
			#define _ALPHATEST_ON 1
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 100600

			
			#pragma multi_compile _ _SCREEN_SPACE_OCCLUSION
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS _ADDITIONAL_OFF
			#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile _ _SHADOWS_SOFT
			#pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
			
			#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
			#pragma multi_compile _ SHADOWS_SHADOWMASK

			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile _ LIGHTMAP_ON

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS_FORWARD

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			
			#if ASE_SRP_VERSION <= 70108
			#define REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
			#endif

			#if defined(UNITY_INSTANCING_ENABLED) && defined(_TERRAIN_INSTANCED_PERPIXEL_NORMAL)
			    #define ENABLE_TERRAIN_PERPIXEL_NORMAL
			#endif

			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_VERT_TANGENT
			#define ASE_NEEDS_VERT_POSITION


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord : TEXCOORD0;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				float4 ase_texcoord3 : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				float4 lightmapUVOrVertexSH : TEXCOORD0;
				half4 fogFactorAndVertexLight : TEXCOORD1;
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
				float4 shadowCoord : TEXCOORD2;
				#endif
				float4 tSpace0 : TEXCOORD3;
				float4 tSpace1 : TEXCOORD4;
				float4 tSpace2 : TEXCOORD5;
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
				float4 screenPos : TEXCOORD6;
				#endif
				float4 ase_texcoord7 : TEXCOORD7;
				float4 ase_texcoord8 : TEXCOORD8;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _MetallicSmoothness_ST;
			float4 _EmissionMap_ST;
			float4 _NormalMap_ST;
			float4 _BaseColorMap_ST;
			float4 _EmissionColor;
			float3 _PenetratorOrigin;
			float3 _OrificeWorldPosition;
			float3 _PenetratorUp;
			float3 _PenetratorForward;
			float3 _OrificeOutWorldPosition3;
			float3 _OrificeOutWorldPosition2;
			float3 _OrificeOutWorldPosition1;
			float3 _OrificeWorldNormal;
			float3 _PenetratorRight;
			float _DeformBalls;
			float _InvisibleWhenInside;
			float _PinchBuffer;
			float _OrificeLength;
			float _NoBlendshapes;
			float _PenetratorCumActive;
			float _PenetratorCumProgress;
			float _PenetratorSquishPullAmount;
			float _PenetratorBulgePercentage;
			float _BulgeDistance;
			float _PenetrationDepth;
			float _PenetratorLength;
			float _ClipDick;
			float _PenetratorBlendshapeMultiplier;
			#ifdef _TRANSMISSION_ASE
				float _TransmissionShadow;
			#endif
			#ifdef _TRANSLUCENCY_ASE
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			float4 _JiggleInfos[16];
			sampler2D _Foam;
			sampler2D _BaseColorMap;
			sampler2D _NormalMap;
			sampler2D _FoamNormal;
			sampler2D _EmissionMap;
			sampler2D _MetallicSmoothness;


			float3 GetSoftbodyOffset3_g1064( float blend, float3 vertexPosition )
			{
				float3 vertexOffset = float3(0,0,0);
				for(int i=0;i<8;i++) {
				    float4 targetPosePositionRadius = _JiggleInfos[i*2];
				    float4 verletPositionBlend = _JiggleInfos[i*2+1];
				    float3 movement = (verletPositionBlend.xyz - targetPosePositionRadius.xyz);
				    float dist = distance(vertexPosition, targetPosePositionRadius.xyz);
				    float multi = 1-smoothstep(0,targetPosePositionRadius.w,dist);
				    vertexOffset += movement * multi * verletPositionBlend.w * blend;
				}
				return vertexOffset;
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 VertexNormal259_g1065 = v.ase_normal;
				float3 normalizeResult27_g1081 = normalize( VertexNormal259_g1065 );
				float3 temp_output_35_0_g1065 = normalizeResult27_g1081;
				float3 normalizeResult31_g1081 = normalize( v.ase_tangent.xyz );
				float3 normalizeResult29_g1081 = normalize( cross( normalizeResult27_g1081 , normalizeResult31_g1081 ) );
				float3 temp_output_35_1_g1065 = cross( normalizeResult29_g1081 , normalizeResult27_g1081 );
				float3 temp_output_35_2_g1065 = normalizeResult29_g1081;
				float3 SquishDelta85_g1065 = ( ( ( temp_output_35_0_g1065 * v.ase_texcoord2.x ) + ( temp_output_35_1_g1065 * v.ase_texcoord2.y ) + ( temp_output_35_2_g1065 * v.ase_texcoord2.z ) ) * _PenetratorBlendshapeMultiplier );
				float temp_output_234_0_g1065 = length( SquishDelta85_g1065 );
				float temp_output_11_0_g1065 = max( _PenetrationDepth , 0.0 );
				float VisibleLength25_g1065 = ( _PenetratorLength * ( 1.0 - temp_output_11_0_g1065 ) );
				float3 DickOrigin16_g1065 = _PenetratorOrigin;
				float4 appendResult132_g1065 = (float4(_OrificeWorldPosition , 1.0));
				float4 transform140_g1065 = mul(GetWorldToObjectMatrix(),appendResult132_g1065);
				float3 OrifacePosition170_g1065 = (transform140_g1065).xyz;
				float DickLength19_g1065 = _PenetratorLength;
				float3 DickUp172_g1065 = _PenetratorUp;
				float blend3_g1064 = v.ase_color.r;
				float2 texCoord10 = v.texcoord1.xyzw.xy * float2( 1,1 ) + float2( 0,0 );
				float mulTime12 = _TimeParameters.x * 0.01;
				float mulTime11 = _TimeParameters.x * 0.1;
				float2 appendResult15 = (float2(( texCoord10.x + mulTime12 ) , ( texCoord10.y + mulTime11 )));
				float4 tex2DNode16 = tex2Dlod( _Foam, float4( appendResult15, 0, 0.0) );
				float3 temp_output_20_0 = ( v.ase_normal * _BulgeDistance * tex2DNode16.r * v.ase_color.g );
				float3 vertexPosition3_g1064 = ( v.vertex.xyz + temp_output_20_0 );
				float3 localGetSoftbodyOffset3_g1064 = GetSoftbodyOffset3_g1064( blend3_g1064 , vertexPosition3_g1064 );
				float3 VertexPosition254_g1065 = ( localGetSoftbodyOffset3_g1064 + temp_output_20_0 + v.vertex.xyz );
				float3 temp_output_27_0_g1065 = ( VertexPosition254_g1065 - DickOrigin16_g1065 );
				float3 DickForward18_g1065 = _PenetratorForward;
				float dotResult42_g1065 = dot( temp_output_27_0_g1065 , DickForward18_g1065 );
				float BulgePercentage37_g1065 = _PenetratorBulgePercentage;
				float temp_output_1_0_g1075 = saturate( ( abs( ( dotResult42_g1065 - VisibleLength25_g1065 ) ) / ( DickLength19_g1065 * BulgePercentage37_g1065 ) ) );
				float temp_output_94_0_g1065 = sqrt( ( 1.0 - ( temp_output_1_0_g1075 * temp_output_1_0_g1075 ) ) );
				float3 PullDelta91_g1065 = ( ( ( temp_output_35_0_g1065 * v.ase_texcoord3.x ) + ( temp_output_35_1_g1065 * v.ase_texcoord3.y ) + ( temp_output_35_2_g1065 * v.ase_texcoord3.z ) ) * _PenetratorBlendshapeMultiplier );
				float dotResult32_g1065 = dot( temp_output_27_0_g1065 , DickForward18_g1065 );
				float temp_output_1_0_g1082 = saturate( ( abs( ( dotResult32_g1065 - ( DickLength19_g1065 * _PenetratorCumProgress ) ) ) / ( DickLength19_g1065 * BulgePercentage37_g1065 ) ) );
				float3 CumDelta90_g1065 = ( ( ( temp_output_35_0_g1065 * v.texcoord1.xyzw.w ) + ( temp_output_35_1_g1065 * v.ase_texcoord2.w ) + ( temp_output_35_2_g1065 * v.ase_texcoord3.w ) ) * _PenetratorBlendshapeMultiplier );
				float3 lerpResult410_g1065 = lerp( ( VertexPosition254_g1065 + ( SquishDelta85_g1065 * temp_output_94_0_g1065 * saturate( -_PenetratorSquishPullAmount ) ) + ( temp_output_94_0_g1065 * PullDelta91_g1065 * saturate( _PenetratorSquishPullAmount ) ) + ( sqrt( ( 1.0 - ( temp_output_1_0_g1082 * temp_output_1_0_g1082 ) ) ) * CumDelta90_g1065 * _PenetratorCumActive ) ) , VertexPosition254_g1065 , _NoBlendshapes);
				float3 originalPosition126_g1065 = lerpResult410_g1065;
				float dotResult118_g1065 = dot( ( lerpResult410_g1065 - DickOrigin16_g1065 ) , DickForward18_g1065 );
				float PenetrationDepth39_g1065 = _PenetrationDepth;
				float temp_output_65_0_g1065 = ( PenetrationDepth39_g1065 * DickLength19_g1065 );
				float OrifaceLength34_g1065 = _OrificeLength;
				float temp_output_73_0_g1065 = ( _PinchBuffer * OrifaceLength34_g1065 );
				float dotResult80_g1065 = dot( ( lerpResult410_g1065 - DickOrigin16_g1065 ) , DickForward18_g1065 );
				float temp_output_112_0_g1065 = ( -( ( ( temp_output_65_0_g1065 - temp_output_73_0_g1065 ) + dotResult80_g1065 ) - DickLength19_g1065 ) * 10.0 );
				float ClipDick413_g1065 = _ClipDick;
				float lerpResult411_g1065 = lerp( max( temp_output_112_0_g1065 , ( ( ( temp_output_65_0_g1065 + dotResult80_g1065 + temp_output_73_0_g1065 ) - ( OrifaceLength34_g1065 + DickLength19_g1065 ) ) * 10.0 ) ) , temp_output_112_0_g1065 , ClipDick413_g1065);
				float InsideLerp123_g1065 = saturate( lerpResult411_g1065 );
				float3 lerpResult124_g1065 = lerp( ( ( DickForward18_g1065 * dotResult118_g1065 ) + DickOrigin16_g1065 ) , originalPosition126_g1065 , InsideLerp123_g1065);
				float InvisibleWhenInside420_g1065 = _InvisibleWhenInside;
				float3 lerpResult422_g1065 = lerp( originalPosition126_g1065 , lerpResult124_g1065 , InvisibleWhenInside420_g1065);
				float3 temp_output_354_0_g1065 = ( lerpResult422_g1065 - DickOrigin16_g1065 );
				float dotResult373_g1065 = dot( DickUp172_g1065 , temp_output_354_0_g1065 );
				float3 DickRight184_g1065 = _PenetratorRight;
				float dotResult374_g1065 = dot( DickRight184_g1065 , temp_output_354_0_g1065 );
				float dotResult375_g1065 = dot( temp_output_354_0_g1065 , DickForward18_g1065 );
				float3 lerpResult343_g1065 = lerp( ( ( ( saturate( ( ( VisibleLength25_g1065 - distance( DickOrigin16_g1065 , OrifacePosition170_g1065 ) ) / DickLength19_g1065 ) ) + 1.0 ) * dotResult373_g1065 * DickUp172_g1065 ) + ( ( saturate( ( ( VisibleLength25_g1065 - distance( DickOrigin16_g1065 , OrifacePosition170_g1065 ) ) / DickLength19_g1065 ) ) + 1.0 ) * dotResult374_g1065 * DickRight184_g1065 ) + ( DickForward18_g1065 * dotResult375_g1065 ) + DickOrigin16_g1065 ) , lerpResult422_g1065 , saturate( PenetrationDepth39_g1065 ));
				float dotResult177_g1065 = dot( ( lerpResult343_g1065 - DickOrigin16_g1065 ) , DickForward18_g1065 );
				float temp_output_178_0_g1065 = max( VisibleLength25_g1065 , 0.05 );
				float temp_output_42_0_g1076 = ( dotResult177_g1065 / temp_output_178_0_g1065 );
				float temp_output_26_0_g1077 = temp_output_42_0_g1076;
				float temp_output_19_0_g1077 = ( 1.0 - temp_output_26_0_g1077 );
				float3 temp_output_8_0_g1076 = DickOrigin16_g1065;
				float temp_output_393_0_g1065 = distance( DickOrigin16_g1065 , OrifacePosition170_g1065 );
				float temp_output_396_0_g1065 = min( temp_output_178_0_g1065 , temp_output_393_0_g1065 );
				float3 temp_output_9_0_g1076 = ( DickOrigin16_g1065 + ( DickForward18_g1065 * temp_output_396_0_g1065 * 0.25 ) );
				float4 appendResult130_g1065 = (float4(_OrificeWorldNormal , 0.0));
				float4 transform135_g1065 = mul(GetWorldToObjectMatrix(),appendResult130_g1065);
				float3 OrifaceNormal155_g1065 = (transform135_g1065).xyz;
				float3 temp_output_10_0_g1076 = ( OrifacePosition170_g1065 + ( OrifaceNormal155_g1065 * 0.25 * temp_output_396_0_g1065 ) );
				float3 temp_output_11_0_g1076 = OrifacePosition170_g1065;
				float temp_output_1_0_g1079 = temp_output_42_0_g1076;
				float temp_output_8_0_g1079 = ( 1.0 - temp_output_1_0_g1079 );
				float3 temp_output_3_0_g1079 = temp_output_9_0_g1076;
				float3 temp_output_4_0_g1079 = temp_output_10_0_g1076;
				float3 temp_output_7_0_g1078 = ( ( 3.0 * temp_output_8_0_g1079 * temp_output_8_0_g1079 * ( temp_output_3_0_g1079 - temp_output_8_0_g1076 ) ) + ( 6.0 * temp_output_8_0_g1079 * temp_output_1_0_g1079 * ( temp_output_4_0_g1079 - temp_output_3_0_g1079 ) ) + ( 3.0 * temp_output_1_0_g1079 * temp_output_1_0_g1079 * ( temp_output_11_0_g1076 - temp_output_4_0_g1079 ) ) );
				float3 normalizeResult27_g1080 = normalize( temp_output_7_0_g1078 );
				float3 temp_output_4_0_g1076 = DickUp172_g1065;
				float3 temp_output_10_0_g1078 = temp_output_4_0_g1076;
				float3 temp_output_3_0_g1076 = DickForward18_g1065;
				float3 temp_output_13_0_g1078 = temp_output_3_0_g1076;
				float dotResult33_g1078 = dot( temp_output_7_0_g1078 , temp_output_10_0_g1078 );
				float3 lerpResult34_g1078 = lerp( temp_output_10_0_g1078 , -temp_output_13_0_g1078 , saturate( dotResult33_g1078 ));
				float dotResult37_g1078 = dot( temp_output_7_0_g1078 , -temp_output_10_0_g1078 );
				float3 lerpResult40_g1078 = lerp( lerpResult34_g1078 , temp_output_13_0_g1078 , saturate( dotResult37_g1078 ));
				float3 normalizeResult42_g1078 = normalize( lerpResult40_g1078 );
				float3 normalizeResult31_g1080 = normalize( normalizeResult42_g1078 );
				float3 normalizeResult29_g1080 = normalize( cross( normalizeResult27_g1080 , normalizeResult31_g1080 ) );
				float3 temp_output_65_22_g1076 = normalizeResult29_g1080;
				float3 temp_output_2_0_g1076 = ( lerpResult343_g1065 - DickOrigin16_g1065 );
				float3 temp_output_5_0_g1076 = DickRight184_g1065;
				float dotResult15_g1076 = dot( temp_output_2_0_g1076 , temp_output_5_0_g1076 );
				float3 temp_output_65_0_g1076 = cross( normalizeResult29_g1080 , normalizeResult27_g1080 );
				float dotResult18_g1076 = dot( temp_output_2_0_g1076 , temp_output_4_0_g1076 );
				float dotResult142_g1065 = dot( ( lerpResult343_g1065 - DickOrigin16_g1065 ) , DickForward18_g1065 );
				float temp_output_152_0_g1065 = ( dotResult142_g1065 - VisibleLength25_g1065 );
				float temp_output_157_0_g1065 = ( temp_output_152_0_g1065 / OrifaceLength34_g1065 );
				float lerpResult416_g1065 = lerp( temp_output_157_0_g1065 , min( temp_output_157_0_g1065 , 1.0 ) , ClipDick413_g1065);
				float temp_output_42_0_g1066 = lerpResult416_g1065;
				float temp_output_26_0_g1067 = temp_output_42_0_g1066;
				float temp_output_19_0_g1067 = ( 1.0 - temp_output_26_0_g1067 );
				float3 temp_output_8_0_g1066 = OrifacePosition170_g1065;
				float4 appendResult145_g1065 = (float4(_OrificeOutWorldPosition1 , 1.0));
				float4 transform151_g1065 = mul(GetWorldToObjectMatrix(),appendResult145_g1065);
				float3 OrifaceOutPosition1183_g1065 = (transform151_g1065).xyz;
				float3 temp_output_9_0_g1066 = OrifaceOutPosition1183_g1065;
				float4 appendResult144_g1065 = (float4(_OrificeOutWorldPosition2 , 1.0));
				float4 transform154_g1065 = mul(GetWorldToObjectMatrix(),appendResult144_g1065);
				float3 OrifaceOutPosition2182_g1065 = (transform154_g1065).xyz;
				float3 temp_output_10_0_g1066 = OrifaceOutPosition2182_g1065;
				float4 appendResult143_g1065 = (float4(_OrificeOutWorldPosition3 , 1.0));
				float4 transform147_g1065 = mul(GetWorldToObjectMatrix(),appendResult143_g1065);
				float3 OrifaceOutPosition3175_g1065 = (transform147_g1065).xyz;
				float3 temp_output_11_0_g1066 = OrifaceOutPosition3175_g1065;
				float temp_output_1_0_g1069 = temp_output_42_0_g1066;
				float temp_output_8_0_g1069 = ( 1.0 - temp_output_1_0_g1069 );
				float3 temp_output_3_0_g1069 = temp_output_9_0_g1066;
				float3 temp_output_4_0_g1069 = temp_output_10_0_g1066;
				float3 temp_output_7_0_g1068 = ( ( 3.0 * temp_output_8_0_g1069 * temp_output_8_0_g1069 * ( temp_output_3_0_g1069 - temp_output_8_0_g1066 ) ) + ( 6.0 * temp_output_8_0_g1069 * temp_output_1_0_g1069 * ( temp_output_4_0_g1069 - temp_output_3_0_g1069 ) ) + ( 3.0 * temp_output_1_0_g1069 * temp_output_1_0_g1069 * ( temp_output_11_0_g1066 - temp_output_4_0_g1069 ) ) );
				float3 normalizeResult27_g1070 = normalize( temp_output_7_0_g1068 );
				float3 temp_output_4_0_g1066 = DickUp172_g1065;
				float3 temp_output_10_0_g1068 = temp_output_4_0_g1066;
				float3 temp_output_3_0_g1066 = DickForward18_g1065;
				float3 temp_output_13_0_g1068 = temp_output_3_0_g1066;
				float dotResult33_g1068 = dot( temp_output_7_0_g1068 , temp_output_10_0_g1068 );
				float3 lerpResult34_g1068 = lerp( temp_output_10_0_g1068 , -temp_output_13_0_g1068 , saturate( dotResult33_g1068 ));
				float dotResult37_g1068 = dot( temp_output_7_0_g1068 , -temp_output_10_0_g1068 );
				float3 lerpResult40_g1068 = lerp( lerpResult34_g1068 , temp_output_13_0_g1068 , saturate( dotResult37_g1068 ));
				float3 normalizeResult42_g1068 = normalize( lerpResult40_g1068 );
				float3 normalizeResult31_g1070 = normalize( normalizeResult42_g1068 );
				float3 normalizeResult29_g1070 = normalize( cross( normalizeResult27_g1070 , normalizeResult31_g1070 ) );
				float3 temp_output_65_22_g1066 = normalizeResult29_g1070;
				float3 temp_output_2_0_g1066 = ( lerpResult343_g1065 - DickOrigin16_g1065 );
				float3 temp_output_5_0_g1066 = DickRight184_g1065;
				float dotResult15_g1066 = dot( temp_output_2_0_g1066 , temp_output_5_0_g1066 );
				float3 temp_output_65_0_g1066 = cross( normalizeResult29_g1070 , normalizeResult27_g1070 );
				float dotResult18_g1066 = dot( temp_output_2_0_g1066 , temp_output_4_0_g1066 );
				float temp_output_208_0_g1065 = saturate( sign( temp_output_152_0_g1065 ) );
				float3 lerpResult221_g1065 = lerp( ( ( ( temp_output_19_0_g1077 * temp_output_19_0_g1077 * temp_output_19_0_g1077 * temp_output_8_0_g1076 ) + ( temp_output_19_0_g1077 * temp_output_19_0_g1077 * 3.0 * temp_output_26_0_g1077 * temp_output_9_0_g1076 ) + ( 3.0 * temp_output_19_0_g1077 * temp_output_26_0_g1077 * temp_output_26_0_g1077 * temp_output_10_0_g1076 ) + ( temp_output_26_0_g1077 * temp_output_26_0_g1077 * temp_output_26_0_g1077 * temp_output_11_0_g1076 ) ) + ( temp_output_65_22_g1076 * dotResult15_g1076 ) + ( temp_output_65_0_g1076 * dotResult18_g1076 ) ) , ( ( ( temp_output_19_0_g1067 * temp_output_19_0_g1067 * temp_output_19_0_g1067 * temp_output_8_0_g1066 ) + ( temp_output_19_0_g1067 * temp_output_19_0_g1067 * 3.0 * temp_output_26_0_g1067 * temp_output_9_0_g1066 ) + ( 3.0 * temp_output_19_0_g1067 * temp_output_26_0_g1067 * temp_output_26_0_g1067 * temp_output_10_0_g1066 ) + ( temp_output_26_0_g1067 * temp_output_26_0_g1067 * temp_output_26_0_g1067 * temp_output_11_0_g1066 ) ) + ( temp_output_65_22_g1066 * dotResult15_g1066 ) + ( temp_output_65_0_g1066 * dotResult18_g1066 ) ) , temp_output_208_0_g1065);
				float3 temp_output_42_0_g1071 = DickForward18_g1065;
				float NonVisibleLength165_g1065 = ( temp_output_11_0_g1065 * _PenetratorLength );
				float3 temp_output_52_0_g1071 = ( ( temp_output_42_0_g1071 * ( ( NonVisibleLength165_g1065 - OrifaceLength34_g1065 ) - DickLength19_g1065 ) ) + ( lerpResult343_g1065 - DickOrigin16_g1065 ) );
				float dotResult53_g1071 = dot( temp_output_42_0_g1071 , temp_output_52_0_g1071 );
				float temp_output_1_0_g1073 = 1.0;
				float temp_output_8_0_g1073 = ( 1.0 - temp_output_1_0_g1073 );
				float3 temp_output_3_0_g1073 = OrifaceOutPosition1183_g1065;
				float3 temp_output_4_0_g1073 = OrifaceOutPosition2182_g1065;
				float3 temp_output_7_0_g1072 = ( ( 3.0 * temp_output_8_0_g1073 * temp_output_8_0_g1073 * ( temp_output_3_0_g1073 - OrifacePosition170_g1065 ) ) + ( 6.0 * temp_output_8_0_g1073 * temp_output_1_0_g1073 * ( temp_output_4_0_g1073 - temp_output_3_0_g1073 ) ) + ( 3.0 * temp_output_1_0_g1073 * temp_output_1_0_g1073 * ( OrifaceOutPosition3175_g1065 - temp_output_4_0_g1073 ) ) );
				float3 normalizeResult27_g1074 = normalize( temp_output_7_0_g1072 );
				float3 temp_output_85_23_g1071 = normalizeResult27_g1074;
				float3 temp_output_4_0_g1071 = DickUp172_g1065;
				float dotResult54_g1071 = dot( temp_output_4_0_g1071 , temp_output_52_0_g1071 );
				float3 temp_output_10_0_g1072 = temp_output_4_0_g1071;
				float3 temp_output_13_0_g1072 = temp_output_42_0_g1071;
				float dotResult33_g1072 = dot( temp_output_7_0_g1072 , temp_output_10_0_g1072 );
				float3 lerpResult34_g1072 = lerp( temp_output_10_0_g1072 , -temp_output_13_0_g1072 , saturate( dotResult33_g1072 ));
				float dotResult37_g1072 = dot( temp_output_7_0_g1072 , -temp_output_10_0_g1072 );
				float3 lerpResult40_g1072 = lerp( lerpResult34_g1072 , temp_output_13_0_g1072 , saturate( dotResult37_g1072 ));
				float3 normalizeResult42_g1072 = normalize( lerpResult40_g1072 );
				float3 normalizeResult31_g1074 = normalize( normalizeResult42_g1072 );
				float3 normalizeResult29_g1074 = normalize( cross( normalizeResult27_g1074 , normalizeResult31_g1074 ) );
				float3 temp_output_85_0_g1071 = cross( normalizeResult29_g1074 , normalizeResult27_g1074 );
				float3 temp_output_43_0_g1071 = DickRight184_g1065;
				float dotResult55_g1071 = dot( temp_output_43_0_g1071 , temp_output_52_0_g1071 );
				float3 temp_output_85_22_g1071 = normalizeResult29_g1074;
				float temp_output_222_0_g1065 = saturate( sign( ( temp_output_157_0_g1065 - 1.0 ) ) );
				float3 lerpResult224_g1065 = lerp( lerpResult221_g1065 , ( ( ( dotResult53_g1071 * temp_output_85_23_g1071 ) + ( dotResult54_g1071 * temp_output_85_0_g1071 ) + ( dotResult55_g1071 * temp_output_85_22_g1071 ) ) + OrifaceOutPosition3175_g1065 ) , temp_output_222_0_g1065);
				float3 lerpResult418_g1065 = lerp( lerpResult224_g1065 , lerpResult221_g1065 , ClipDick413_g1065);
				float temp_output_226_0_g1065 = saturate( -PenetrationDepth39_g1065 );
				float3 lerpResult232_g1065 = lerp( lerpResult418_g1065 , originalPosition126_g1065 , temp_output_226_0_g1065);
				float3 ifLocalVar237_g1065 = 0;
				if( temp_output_234_0_g1065 <= 0.0 )
				ifLocalVar237_g1065 = originalPosition126_g1065;
				else
				ifLocalVar237_g1065 = lerpResult232_g1065;
				float DeformBalls426_g1065 = _DeformBalls;
				float3 lerpResult428_g1065 = lerp( ifLocalVar237_g1065 , lerpResult232_g1065 , DeformBalls426_g1065);
				
				float3 temp_output_21_0_g1076 = VertexNormal259_g1065;
				float dotResult55_g1076 = dot( temp_output_21_0_g1076 , temp_output_3_0_g1076 );
				float dotResult56_g1076 = dot( temp_output_21_0_g1076 , temp_output_4_0_g1076 );
				float dotResult57_g1076 = dot( temp_output_21_0_g1076 , temp_output_5_0_g1076 );
				float3 normalizeResult31_g1076 = normalize( ( ( dotResult55_g1076 * normalizeResult27_g1080 ) + ( dotResult56_g1076 * temp_output_65_0_g1076 ) + ( dotResult57_g1076 * temp_output_65_22_g1076 ) ) );
				float3 temp_output_21_0_g1066 = VertexNormal259_g1065;
				float dotResult55_g1066 = dot( temp_output_21_0_g1066 , temp_output_3_0_g1066 );
				float dotResult56_g1066 = dot( temp_output_21_0_g1066 , temp_output_4_0_g1066 );
				float dotResult57_g1066 = dot( temp_output_21_0_g1066 , temp_output_5_0_g1066 );
				float3 normalizeResult31_g1066 = normalize( ( ( dotResult55_g1066 * normalizeResult27_g1070 ) + ( dotResult56_g1066 * temp_output_65_0_g1066 ) + ( dotResult57_g1066 * temp_output_65_22_g1066 ) ) );
				float3 lerpResult227_g1065 = lerp( normalizeResult31_g1076 , normalizeResult31_g1066 , temp_output_208_0_g1065);
				float3 temp_output_24_0_g1071 = VertexNormal259_g1065;
				float dotResult61_g1071 = dot( temp_output_42_0_g1071 , temp_output_24_0_g1071 );
				float dotResult62_g1071 = dot( temp_output_4_0_g1071 , temp_output_24_0_g1071 );
				float dotResult60_g1071 = dot( temp_output_43_0_g1071 , temp_output_24_0_g1071 );
				float3 normalizeResult33_g1071 = normalize( ( ( dotResult61_g1071 * temp_output_85_23_g1071 ) + ( dotResult62_g1071 * temp_output_85_0_g1071 ) + ( dotResult60_g1071 * temp_output_85_22_g1071 ) ) );
				float3 lerpResult233_g1065 = lerp( lerpResult227_g1065 , normalizeResult33_g1071 , temp_output_222_0_g1065);
				float3 lerpResult419_g1065 = lerp( lerpResult233_g1065 , lerpResult227_g1065 , ClipDick413_g1065);
				float3 lerpResult238_g1065 = lerp( lerpResult419_g1065 , VertexNormal259_g1065 , temp_output_226_0_g1065);
				float3 ifLocalVar391_g1065 = 0;
				if( temp_output_234_0_g1065 <= 0.0 )
				ifLocalVar391_g1065 = VertexNormal259_g1065;
				else
				ifLocalVar391_g1065 = lerpResult238_g1065;
				
				float lerpResult424_g1065 = lerp( 1.0 , InsideLerp123_g1065 , InvisibleWhenInside420_g1065);
				float vertexToFrag250_g1065 = lerpResult424_g1065;
				o.ase_texcoord7.z = vertexToFrag250_g1065;
				
				o.ase_texcoord7.xy = v.texcoord.xy;
				o.ase_texcoord8 = v.texcoord1.xyzw;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord7.w = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = lerpResult428_g1065;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.ase_normal = ifLocalVar391_g1065;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float3 positionVS = TransformWorldToView( positionWS );
				float4 positionCS = TransformWorldToHClip( positionWS );

				VertexNormalInputs normalInput = GetVertexNormalInputs( v.ase_normal, v.ase_tangent );

				o.tSpace0 = float4( normalInput.normalWS, positionWS.x);
				o.tSpace1 = float4( normalInput.tangentWS, positionWS.y);
				o.tSpace2 = float4( normalInput.bitangentWS, positionWS.z);

				OUTPUT_LIGHTMAP_UV( v.texcoord1, unity_LightmapST, o.lightmapUVOrVertexSH.xy );
				OUTPUT_SH( normalInput.normalWS.xyz, o.lightmapUVOrVertexSH.xyz );

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					o.lightmapUVOrVertexSH.zw = v.texcoord;
					o.lightmapUVOrVertexSH.xy = v.texcoord * unity_LightmapST.xy + unity_LightmapST.zw;
				#endif

				half3 vertexLight = VertexLighting( positionWS, normalInput.normalWS );
				#ifdef ASE_FOG
					half fogFactor = ComputeFogFactor( positionCS.z );
				#else
					half fogFactor = 0;
				#endif
				o.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
				
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
				VertexPositionInputs vertexInput = (VertexPositionInputs)0;
				vertexInput.positionWS = positionWS;
				vertexInput.positionCS = positionCS;
				o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				
				o.clipPos = positionCS;
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
				o.screenPos = ComputeScreenPos(positionCS);
				#endif
				return o;
			}
			
			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				float4 ase_texcoord3 : TEXCOORD3;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_tangent = v.ase_tangent;
				o.texcoord = v.texcoord;
				o.texcoord1 = v.texcoord1;
				o.texcoord = v.texcoord;
				o.ase_texcoord2 = v.ase_texcoord2;
				o.ase_color = v.ase_color;
				o.ase_texcoord3 = v.ase_texcoord3;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				o.texcoord = patch[0].texcoord * bary.x + patch[1].texcoord * bary.y + patch[2].texcoord * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.texcoord = patch[0].texcoord * bary.x + patch[1].texcoord * bary.y + patch[2].texcoord * bary.z;
				o.ase_texcoord2 = patch[0].ase_texcoord2 * bary.x + patch[1].ase_texcoord2 * bary.y + patch[2].ase_texcoord2 * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				o.ase_texcoord3 = patch[0].ase_texcoord3 * bary.x + patch[1].ase_texcoord3 * bary.y + patch[2].ase_texcoord3 * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE)
				#define ASE_SV_DEPTH SV_DepthLessEqual  
			#else
				#define ASE_SV_DEPTH SV_Depth
			#endif

			half4 frag ( VertexOutput IN 
						#ifdef ASE_DEPTH_WRITE_ON
						,out float outputDepth : ASE_SV_DEPTH
						#endif
						 ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					float2 sampleCoords = (IN.lightmapUVOrVertexSH.zw / _TerrainHeightmapRecipSize.zw + 0.5f) * _TerrainHeightmapRecipSize.xy;
					float3 WorldNormal = TransformObjectToWorldNormal(normalize(SAMPLE_TEXTURE2D(_TerrainNormalmapTexture, sampler_TerrainNormalmapTexture, sampleCoords).rgb * 2 - 1));
					float3 WorldTangent = -cross(GetObjectToWorldMatrix()._13_23_33, WorldNormal);
					float3 WorldBiTangent = cross(WorldNormal, -WorldTangent);
				#else
					float3 WorldNormal = normalize( IN.tSpace0.xyz );
					float3 WorldTangent = IN.tSpace1.xyz;
					float3 WorldBiTangent = IN.tSpace2.xyz;
				#endif
				float3 WorldPosition = float3(IN.tSpace0.w,IN.tSpace1.w,IN.tSpace2.w);
				float3 WorldViewDirection = _WorldSpaceCameraPos.xyz  - WorldPosition;
				float4 ShadowCoords = float4( 0, 0, 0, 0 );
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
				float4 ScreenPos = IN.screenPos;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					ShadowCoords = IN.shadowCoord;
				#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
					ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
				#endif
	
				WorldViewDirection = SafeNormalize( WorldViewDirection );

				float2 uv_BaseColorMap = IN.ase_texcoord7.xy * _BaseColorMap_ST.xy + _BaseColorMap_ST.zw;
				
				float2 uv_NormalMap = IN.ase_texcoord7.xy * _NormalMap_ST.xy + _NormalMap_ST.zw;
				float2 texCoord10 = IN.ase_texcoord8.xy * float2( 1,1 ) + float2( 0,0 );
				float mulTime12 = _TimeParameters.x * 0.01;
				float mulTime11 = _TimeParameters.x * 0.1;
				float2 appendResult15 = (float2(( texCoord10.x + mulTime12 ) , ( texCoord10.y + mulTime11 )));
				float3 unpack27 = UnpackNormalScale( tex2D( _FoamNormal, appendResult15 ), 2.0 );
				unpack27.z = lerp( 1, unpack27.z, saturate(2.0) );
				float4 tex2DNode16 = tex2D( _Foam, appendResult15 );
				float3 lerpResult34 = lerp( UnpackNormalScale( tex2D( _NormalMap, uv_NormalMap ), 1.0f ) , unpack27 , saturate( ( tex2DNode16.r * 8.0 ) ));
				
				float2 uv_EmissionMap = IN.ase_texcoord7.xy * _EmissionMap_ST.xy + _EmissionMap_ST.zw;
				
				float2 uv_MetallicSmoothness = IN.ase_texcoord7.xy * _MetallicSmoothness_ST.xy + _MetallicSmoothness_ST.zw;
				float4 tex2DNode35 = tex2D( _MetallicSmoothness, uv_MetallicSmoothness );
				
				float vertexToFrag250_g1065 = IN.ase_texcoord7.z;
				
				float3 Albedo = tex2D( _BaseColorMap, uv_BaseColorMap ).rgb;
				float3 Normal = lerpResult34;
				float3 Emission = ( tex2D( _EmissionMap, uv_EmissionMap ) * _EmissionColor ).rgb;
				float3 Specular = 0.5;
				float Metallic = tex2DNode35.r;
				float Smoothness = tex2DNode35.a;
				float Occlusion = 1;
				float Alpha = vertexToFrag250_g1065;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;
				float3 BakedGI = 0;
				float3 RefractionColor = 1;
				float RefractionIndex = 1;
				float3 Transmission = 1;
				float3 Translucency = 1;
				#ifdef ASE_DEPTH_WRITE_ON
				float DepthValue = 0;
				#endif

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				InputData inputData;
				inputData.positionWS = WorldPosition;
				inputData.viewDirectionWS = WorldViewDirection;
				inputData.shadowCoord = ShadowCoords;

				#ifdef _NORMALMAP
					#if _NORMAL_DROPOFF_TS
					inputData.normalWS = TransformTangentToWorld(Normal, half3x3( WorldTangent, WorldBiTangent, WorldNormal ));
					#elif _NORMAL_DROPOFF_OS
					inputData.normalWS = TransformObjectToWorldNormal(Normal);
					#elif _NORMAL_DROPOFF_WS
					inputData.normalWS = Normal;
					#endif
					inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
				#else
					inputData.normalWS = WorldNormal;
				#endif

				#ifdef ASE_FOG
					inputData.fogCoord = IN.fogFactorAndVertexLight.x;
				#endif

				inputData.vertexLighting = IN.fogFactorAndVertexLight.yzw;
				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					float3 SH = SampleSH(inputData.normalWS.xyz);
				#else
					float3 SH = IN.lightmapUVOrVertexSH.xyz;
				#endif

				inputData.bakedGI = SAMPLE_GI( IN.lightmapUVOrVertexSH.xy, SH, inputData.normalWS );
				#ifdef _ASE_BAKEDGI
					inputData.bakedGI = BakedGI;
				#endif
				
				inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(IN.clipPos);
				inputData.shadowMask = SAMPLE_SHADOWMASK(IN.lightmapUVOrVertexSH.xy);

				half4 color = UniversalFragmentPBR(
					inputData, 
					Albedo, 
					Metallic, 
					Specular, 
					Smoothness, 
					Occlusion, 
					Emission, 
					Alpha);

				#ifdef _TRANSMISSION_ASE
				{
					float shadow = _TransmissionShadow;

					Light mainLight = GetMainLight( inputData.shadowCoord );
					float3 mainAtten = mainLight.color * mainLight.distanceAttenuation;
					mainAtten = lerp( mainAtten, mainAtten * mainLight.shadowAttenuation, shadow );
					half3 mainTransmission = max(0 , -dot(inputData.normalWS, mainLight.direction)) * mainAtten * Transmission;
					color.rgb += Albedo * mainTransmission;

					#ifdef _ADDITIONAL_LIGHTS
						int transPixelLightCount = GetAdditionalLightsCount();
						for (int i = 0; i < transPixelLightCount; ++i)
						{
							Light light = GetAdditionalLight(i, inputData.positionWS);
							float3 atten = light.color * light.distanceAttenuation;
							atten = lerp( atten, atten * light.shadowAttenuation, shadow );

							half3 transmission = max(0 , -dot(inputData.normalWS, light.direction)) * atten * Transmission;
							color.rgb += Albedo * transmission;
						}
					#endif
				}
				#endif

				#ifdef _TRANSLUCENCY_ASE
				{
					float shadow = _TransShadow;
					float normal = _TransNormal;
					float scattering = _TransScattering;
					float direct = _TransDirect;
					float ambient = _TransAmbient;
					float strength = _TransStrength;

					Light mainLight = GetMainLight( inputData.shadowCoord );
					float3 mainAtten = mainLight.color * mainLight.distanceAttenuation;
					mainAtten = lerp( mainAtten, mainAtten * mainLight.shadowAttenuation, shadow );

					half3 mainLightDir = mainLight.direction + inputData.normalWS * normal;
					half mainVdotL = pow( saturate( dot( inputData.viewDirectionWS, -mainLightDir ) ), scattering );
					half3 mainTranslucency = mainAtten * ( mainVdotL * direct + inputData.bakedGI * ambient ) * Translucency;
					color.rgb += Albedo * mainTranslucency * strength;

					#ifdef _ADDITIONAL_LIGHTS
						int transPixelLightCount = GetAdditionalLightsCount();
						for (int i = 0; i < transPixelLightCount; ++i)
						{
							Light light = GetAdditionalLight(i, inputData.positionWS);
							float3 atten = light.color * light.distanceAttenuation;
							atten = lerp( atten, atten * light.shadowAttenuation, shadow );

							half3 lightDir = light.direction + inputData.normalWS * normal;
							half VdotL = pow( saturate( dot( inputData.viewDirectionWS, -lightDir ) ), scattering );
							half3 translucency = atten * ( VdotL * direct + inputData.bakedGI * ambient ) * Translucency;
							color.rgb += Albedo * translucency * strength;
						}
					#endif
				}
				#endif

				#ifdef _REFRACTION_ASE
					float4 projScreenPos = ScreenPos / ScreenPos.w;
					float3 refractionOffset = ( RefractionIndex - 1.0 ) * mul( UNITY_MATRIX_V, float4( WorldNormal,0 ) ).xyz * ( 1.0 - dot( WorldNormal, WorldViewDirection ) );
					projScreenPos.xy += refractionOffset.xy;
					float3 refraction = SHADERGRAPH_SAMPLE_SCENE_COLOR( projScreenPos.xy ) * RefractionColor;
					color.rgb = lerp( refraction, color.rgb, color.a );
					color.a = 1;
				#endif

				#ifdef ASE_FINAL_COLOR_ALPHA_MULTIPLY
					color.rgb *= color.a;
				#endif

				#ifdef ASE_FOG
					#ifdef TERRAIN_SPLAT_ADDPASS
						color.rgb = MixFogColor(color.rgb, half3( 0, 0, 0 ), IN.fogFactorAndVertexLight.x );
					#else
						color.rgb = MixFog(color.rgb, IN.fogFactorAndVertexLight.x);
					#endif
				#endif

				#ifdef ASE_DEPTH_WRITE_ON
					outputDepth = DepthValue;
				#endif

				return color;
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "ShadowCaster"
			Tags { "LightMode"="ShadowCaster" }

			ZWrite On
			ZTest LEqual
			AlphaToMask Off
			ColorMask 0

			HLSLPROGRAM
			
			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_instancing
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define ASE_ABSOLUTE_VERTEX_POS 1
			#define _EMISSION
			#define _ALPHATEST_ON 1
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 100600

			
			#pragma vertex vert
			#pragma fragment frag
#if ASE_SRP_VERSION >= 110000
			#pragma multi_compile _ _CASTING_PUNCTUAL_LIGHT_SHADOW
#endif
			#define SHADERPASS_SHADOWCASTER

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_VERT_POSITION


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_tangent : TANGENT;
				float4 ase_color : COLOR;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord3 : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				float4 ase_texcoord2 : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _MetallicSmoothness_ST;
			float4 _EmissionMap_ST;
			float4 _NormalMap_ST;
			float4 _BaseColorMap_ST;
			float4 _EmissionColor;
			float3 _PenetratorOrigin;
			float3 _OrificeWorldPosition;
			float3 _PenetratorUp;
			float3 _PenetratorForward;
			float3 _OrificeOutWorldPosition3;
			float3 _OrificeOutWorldPosition2;
			float3 _OrificeOutWorldPosition1;
			float3 _OrificeWorldNormal;
			float3 _PenetratorRight;
			float _DeformBalls;
			float _InvisibleWhenInside;
			float _PinchBuffer;
			float _OrificeLength;
			float _NoBlendshapes;
			float _PenetratorCumActive;
			float _PenetratorCumProgress;
			float _PenetratorSquishPullAmount;
			float _PenetratorBulgePercentage;
			float _BulgeDistance;
			float _PenetrationDepth;
			float _PenetratorLength;
			float _ClipDick;
			float _PenetratorBlendshapeMultiplier;
			#ifdef _TRANSMISSION_ASE
				float _TransmissionShadow;
			#endif
			#ifdef _TRANSLUCENCY_ASE
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			float4 _JiggleInfos[16];
			sampler2D _Foam;


			float3 GetSoftbodyOffset3_g1064( float blend, float3 vertexPosition )
			{
				float3 vertexOffset = float3(0,0,0);
				for(int i=0;i<8;i++) {
				    float4 targetPosePositionRadius = _JiggleInfos[i*2];
				    float4 verletPositionBlend = _JiggleInfos[i*2+1];
				    float3 movement = (verletPositionBlend.xyz - targetPosePositionRadius.xyz);
				    float dist = distance(vertexPosition, targetPosePositionRadius.xyz);
				    float multi = 1-smoothstep(0,targetPosePositionRadius.w,dist);
				    vertexOffset += movement * multi * verletPositionBlend.w * blend;
				}
				return vertexOffset;
			}
			

			float3 _LightDirection;
#if ASE_SRP_VERSION >= 110000 
			float3 _LightPosition;
#endif
			VertexOutput VertexFunction( VertexInput v )
			{
				VertexOutput o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				float3 VertexNormal259_g1065 = v.ase_normal;
				float3 normalizeResult27_g1081 = normalize( VertexNormal259_g1065 );
				float3 temp_output_35_0_g1065 = normalizeResult27_g1081;
				float3 normalizeResult31_g1081 = normalize( v.ase_tangent.xyz );
				float3 normalizeResult29_g1081 = normalize( cross( normalizeResult27_g1081 , normalizeResult31_g1081 ) );
				float3 temp_output_35_1_g1065 = cross( normalizeResult29_g1081 , normalizeResult27_g1081 );
				float3 temp_output_35_2_g1065 = normalizeResult29_g1081;
				float3 SquishDelta85_g1065 = ( ( ( temp_output_35_0_g1065 * v.ase_texcoord2.x ) + ( temp_output_35_1_g1065 * v.ase_texcoord2.y ) + ( temp_output_35_2_g1065 * v.ase_texcoord2.z ) ) * _PenetratorBlendshapeMultiplier );
				float temp_output_234_0_g1065 = length( SquishDelta85_g1065 );
				float temp_output_11_0_g1065 = max( _PenetrationDepth , 0.0 );
				float VisibleLength25_g1065 = ( _PenetratorLength * ( 1.0 - temp_output_11_0_g1065 ) );
				float3 DickOrigin16_g1065 = _PenetratorOrigin;
				float4 appendResult132_g1065 = (float4(_OrificeWorldPosition , 1.0));
				float4 transform140_g1065 = mul(GetWorldToObjectMatrix(),appendResult132_g1065);
				float3 OrifacePosition170_g1065 = (transform140_g1065).xyz;
				float DickLength19_g1065 = _PenetratorLength;
				float3 DickUp172_g1065 = _PenetratorUp;
				float blend3_g1064 = v.ase_color.r;
				float2 texCoord10 = v.ase_texcoord1 * float2( 1,1 ) + float2( 0,0 );
				float mulTime12 = _TimeParameters.x * 0.01;
				float mulTime11 = _TimeParameters.x * 0.1;
				float2 appendResult15 = (float2(( texCoord10.x + mulTime12 ) , ( texCoord10.y + mulTime11 )));
				float4 tex2DNode16 = tex2Dlod( _Foam, float4( appendResult15, 0, 0.0) );
				float3 temp_output_20_0 = ( v.ase_normal * _BulgeDistance * tex2DNode16.r * v.ase_color.g );
				float3 vertexPosition3_g1064 = ( v.vertex.xyz + temp_output_20_0 );
				float3 localGetSoftbodyOffset3_g1064 = GetSoftbodyOffset3_g1064( blend3_g1064 , vertexPosition3_g1064 );
				float3 VertexPosition254_g1065 = ( localGetSoftbodyOffset3_g1064 + temp_output_20_0 + v.vertex.xyz );
				float3 temp_output_27_0_g1065 = ( VertexPosition254_g1065 - DickOrigin16_g1065 );
				float3 DickForward18_g1065 = _PenetratorForward;
				float dotResult42_g1065 = dot( temp_output_27_0_g1065 , DickForward18_g1065 );
				float BulgePercentage37_g1065 = _PenetratorBulgePercentage;
				float temp_output_1_0_g1075 = saturate( ( abs( ( dotResult42_g1065 - VisibleLength25_g1065 ) ) / ( DickLength19_g1065 * BulgePercentage37_g1065 ) ) );
				float temp_output_94_0_g1065 = sqrt( ( 1.0 - ( temp_output_1_0_g1075 * temp_output_1_0_g1075 ) ) );
				float3 PullDelta91_g1065 = ( ( ( temp_output_35_0_g1065 * v.ase_texcoord3.x ) + ( temp_output_35_1_g1065 * v.ase_texcoord3.y ) + ( temp_output_35_2_g1065 * v.ase_texcoord3.z ) ) * _PenetratorBlendshapeMultiplier );
				float dotResult32_g1065 = dot( temp_output_27_0_g1065 , DickForward18_g1065 );
				float temp_output_1_0_g1082 = saturate( ( abs( ( dotResult32_g1065 - ( DickLength19_g1065 * _PenetratorCumProgress ) ) ) / ( DickLength19_g1065 * BulgePercentage37_g1065 ) ) );
				float3 CumDelta90_g1065 = ( ( ( temp_output_35_0_g1065 * v.ase_texcoord1.w ) + ( temp_output_35_1_g1065 * v.ase_texcoord2.w ) + ( temp_output_35_2_g1065 * v.ase_texcoord3.w ) ) * _PenetratorBlendshapeMultiplier );
				float3 lerpResult410_g1065 = lerp( ( VertexPosition254_g1065 + ( SquishDelta85_g1065 * temp_output_94_0_g1065 * saturate( -_PenetratorSquishPullAmount ) ) + ( temp_output_94_0_g1065 * PullDelta91_g1065 * saturate( _PenetratorSquishPullAmount ) ) + ( sqrt( ( 1.0 - ( temp_output_1_0_g1082 * temp_output_1_0_g1082 ) ) ) * CumDelta90_g1065 * _PenetratorCumActive ) ) , VertexPosition254_g1065 , _NoBlendshapes);
				float3 originalPosition126_g1065 = lerpResult410_g1065;
				float dotResult118_g1065 = dot( ( lerpResult410_g1065 - DickOrigin16_g1065 ) , DickForward18_g1065 );
				float PenetrationDepth39_g1065 = _PenetrationDepth;
				float temp_output_65_0_g1065 = ( PenetrationDepth39_g1065 * DickLength19_g1065 );
				float OrifaceLength34_g1065 = _OrificeLength;
				float temp_output_73_0_g1065 = ( _PinchBuffer * OrifaceLength34_g1065 );
				float dotResult80_g1065 = dot( ( lerpResult410_g1065 - DickOrigin16_g1065 ) , DickForward18_g1065 );
				float temp_output_112_0_g1065 = ( -( ( ( temp_output_65_0_g1065 - temp_output_73_0_g1065 ) + dotResult80_g1065 ) - DickLength19_g1065 ) * 10.0 );
				float ClipDick413_g1065 = _ClipDick;
				float lerpResult411_g1065 = lerp( max( temp_output_112_0_g1065 , ( ( ( temp_output_65_0_g1065 + dotResult80_g1065 + temp_output_73_0_g1065 ) - ( OrifaceLength34_g1065 + DickLength19_g1065 ) ) * 10.0 ) ) , temp_output_112_0_g1065 , ClipDick413_g1065);
				float InsideLerp123_g1065 = saturate( lerpResult411_g1065 );
				float3 lerpResult124_g1065 = lerp( ( ( DickForward18_g1065 * dotResult118_g1065 ) + DickOrigin16_g1065 ) , originalPosition126_g1065 , InsideLerp123_g1065);
				float InvisibleWhenInside420_g1065 = _InvisibleWhenInside;
				float3 lerpResult422_g1065 = lerp( originalPosition126_g1065 , lerpResult124_g1065 , InvisibleWhenInside420_g1065);
				float3 temp_output_354_0_g1065 = ( lerpResult422_g1065 - DickOrigin16_g1065 );
				float dotResult373_g1065 = dot( DickUp172_g1065 , temp_output_354_0_g1065 );
				float3 DickRight184_g1065 = _PenetratorRight;
				float dotResult374_g1065 = dot( DickRight184_g1065 , temp_output_354_0_g1065 );
				float dotResult375_g1065 = dot( temp_output_354_0_g1065 , DickForward18_g1065 );
				float3 lerpResult343_g1065 = lerp( ( ( ( saturate( ( ( VisibleLength25_g1065 - distance( DickOrigin16_g1065 , OrifacePosition170_g1065 ) ) / DickLength19_g1065 ) ) + 1.0 ) * dotResult373_g1065 * DickUp172_g1065 ) + ( ( saturate( ( ( VisibleLength25_g1065 - distance( DickOrigin16_g1065 , OrifacePosition170_g1065 ) ) / DickLength19_g1065 ) ) + 1.0 ) * dotResult374_g1065 * DickRight184_g1065 ) + ( DickForward18_g1065 * dotResult375_g1065 ) + DickOrigin16_g1065 ) , lerpResult422_g1065 , saturate( PenetrationDepth39_g1065 ));
				float dotResult177_g1065 = dot( ( lerpResult343_g1065 - DickOrigin16_g1065 ) , DickForward18_g1065 );
				float temp_output_178_0_g1065 = max( VisibleLength25_g1065 , 0.05 );
				float temp_output_42_0_g1076 = ( dotResult177_g1065 / temp_output_178_0_g1065 );
				float temp_output_26_0_g1077 = temp_output_42_0_g1076;
				float temp_output_19_0_g1077 = ( 1.0 - temp_output_26_0_g1077 );
				float3 temp_output_8_0_g1076 = DickOrigin16_g1065;
				float temp_output_393_0_g1065 = distance( DickOrigin16_g1065 , OrifacePosition170_g1065 );
				float temp_output_396_0_g1065 = min( temp_output_178_0_g1065 , temp_output_393_0_g1065 );
				float3 temp_output_9_0_g1076 = ( DickOrigin16_g1065 + ( DickForward18_g1065 * temp_output_396_0_g1065 * 0.25 ) );
				float4 appendResult130_g1065 = (float4(_OrificeWorldNormal , 0.0));
				float4 transform135_g1065 = mul(GetWorldToObjectMatrix(),appendResult130_g1065);
				float3 OrifaceNormal155_g1065 = (transform135_g1065).xyz;
				float3 temp_output_10_0_g1076 = ( OrifacePosition170_g1065 + ( OrifaceNormal155_g1065 * 0.25 * temp_output_396_0_g1065 ) );
				float3 temp_output_11_0_g1076 = OrifacePosition170_g1065;
				float temp_output_1_0_g1079 = temp_output_42_0_g1076;
				float temp_output_8_0_g1079 = ( 1.0 - temp_output_1_0_g1079 );
				float3 temp_output_3_0_g1079 = temp_output_9_0_g1076;
				float3 temp_output_4_0_g1079 = temp_output_10_0_g1076;
				float3 temp_output_7_0_g1078 = ( ( 3.0 * temp_output_8_0_g1079 * temp_output_8_0_g1079 * ( temp_output_3_0_g1079 - temp_output_8_0_g1076 ) ) + ( 6.0 * temp_output_8_0_g1079 * temp_output_1_0_g1079 * ( temp_output_4_0_g1079 - temp_output_3_0_g1079 ) ) + ( 3.0 * temp_output_1_0_g1079 * temp_output_1_0_g1079 * ( temp_output_11_0_g1076 - temp_output_4_0_g1079 ) ) );
				float3 normalizeResult27_g1080 = normalize( temp_output_7_0_g1078 );
				float3 temp_output_4_0_g1076 = DickUp172_g1065;
				float3 temp_output_10_0_g1078 = temp_output_4_0_g1076;
				float3 temp_output_3_0_g1076 = DickForward18_g1065;
				float3 temp_output_13_0_g1078 = temp_output_3_0_g1076;
				float dotResult33_g1078 = dot( temp_output_7_0_g1078 , temp_output_10_0_g1078 );
				float3 lerpResult34_g1078 = lerp( temp_output_10_0_g1078 , -temp_output_13_0_g1078 , saturate( dotResult33_g1078 ));
				float dotResult37_g1078 = dot( temp_output_7_0_g1078 , -temp_output_10_0_g1078 );
				float3 lerpResult40_g1078 = lerp( lerpResult34_g1078 , temp_output_13_0_g1078 , saturate( dotResult37_g1078 ));
				float3 normalizeResult42_g1078 = normalize( lerpResult40_g1078 );
				float3 normalizeResult31_g1080 = normalize( normalizeResult42_g1078 );
				float3 normalizeResult29_g1080 = normalize( cross( normalizeResult27_g1080 , normalizeResult31_g1080 ) );
				float3 temp_output_65_22_g1076 = normalizeResult29_g1080;
				float3 temp_output_2_0_g1076 = ( lerpResult343_g1065 - DickOrigin16_g1065 );
				float3 temp_output_5_0_g1076 = DickRight184_g1065;
				float dotResult15_g1076 = dot( temp_output_2_0_g1076 , temp_output_5_0_g1076 );
				float3 temp_output_65_0_g1076 = cross( normalizeResult29_g1080 , normalizeResult27_g1080 );
				float dotResult18_g1076 = dot( temp_output_2_0_g1076 , temp_output_4_0_g1076 );
				float dotResult142_g1065 = dot( ( lerpResult343_g1065 - DickOrigin16_g1065 ) , DickForward18_g1065 );
				float temp_output_152_0_g1065 = ( dotResult142_g1065 - VisibleLength25_g1065 );
				float temp_output_157_0_g1065 = ( temp_output_152_0_g1065 / OrifaceLength34_g1065 );
				float lerpResult416_g1065 = lerp( temp_output_157_0_g1065 , min( temp_output_157_0_g1065 , 1.0 ) , ClipDick413_g1065);
				float temp_output_42_0_g1066 = lerpResult416_g1065;
				float temp_output_26_0_g1067 = temp_output_42_0_g1066;
				float temp_output_19_0_g1067 = ( 1.0 - temp_output_26_0_g1067 );
				float3 temp_output_8_0_g1066 = OrifacePosition170_g1065;
				float4 appendResult145_g1065 = (float4(_OrificeOutWorldPosition1 , 1.0));
				float4 transform151_g1065 = mul(GetWorldToObjectMatrix(),appendResult145_g1065);
				float3 OrifaceOutPosition1183_g1065 = (transform151_g1065).xyz;
				float3 temp_output_9_0_g1066 = OrifaceOutPosition1183_g1065;
				float4 appendResult144_g1065 = (float4(_OrificeOutWorldPosition2 , 1.0));
				float4 transform154_g1065 = mul(GetWorldToObjectMatrix(),appendResult144_g1065);
				float3 OrifaceOutPosition2182_g1065 = (transform154_g1065).xyz;
				float3 temp_output_10_0_g1066 = OrifaceOutPosition2182_g1065;
				float4 appendResult143_g1065 = (float4(_OrificeOutWorldPosition3 , 1.0));
				float4 transform147_g1065 = mul(GetWorldToObjectMatrix(),appendResult143_g1065);
				float3 OrifaceOutPosition3175_g1065 = (transform147_g1065).xyz;
				float3 temp_output_11_0_g1066 = OrifaceOutPosition3175_g1065;
				float temp_output_1_0_g1069 = temp_output_42_0_g1066;
				float temp_output_8_0_g1069 = ( 1.0 - temp_output_1_0_g1069 );
				float3 temp_output_3_0_g1069 = temp_output_9_0_g1066;
				float3 temp_output_4_0_g1069 = temp_output_10_0_g1066;
				float3 temp_output_7_0_g1068 = ( ( 3.0 * temp_output_8_0_g1069 * temp_output_8_0_g1069 * ( temp_output_3_0_g1069 - temp_output_8_0_g1066 ) ) + ( 6.0 * temp_output_8_0_g1069 * temp_output_1_0_g1069 * ( temp_output_4_0_g1069 - temp_output_3_0_g1069 ) ) + ( 3.0 * temp_output_1_0_g1069 * temp_output_1_0_g1069 * ( temp_output_11_0_g1066 - temp_output_4_0_g1069 ) ) );
				float3 normalizeResult27_g1070 = normalize( temp_output_7_0_g1068 );
				float3 temp_output_4_0_g1066 = DickUp172_g1065;
				float3 temp_output_10_0_g1068 = temp_output_4_0_g1066;
				float3 temp_output_3_0_g1066 = DickForward18_g1065;
				float3 temp_output_13_0_g1068 = temp_output_3_0_g1066;
				float dotResult33_g1068 = dot( temp_output_7_0_g1068 , temp_output_10_0_g1068 );
				float3 lerpResult34_g1068 = lerp( temp_output_10_0_g1068 , -temp_output_13_0_g1068 , saturate( dotResult33_g1068 ));
				float dotResult37_g1068 = dot( temp_output_7_0_g1068 , -temp_output_10_0_g1068 );
				float3 lerpResult40_g1068 = lerp( lerpResult34_g1068 , temp_output_13_0_g1068 , saturate( dotResult37_g1068 ));
				float3 normalizeResult42_g1068 = normalize( lerpResult40_g1068 );
				float3 normalizeResult31_g1070 = normalize( normalizeResult42_g1068 );
				float3 normalizeResult29_g1070 = normalize( cross( normalizeResult27_g1070 , normalizeResult31_g1070 ) );
				float3 temp_output_65_22_g1066 = normalizeResult29_g1070;
				float3 temp_output_2_0_g1066 = ( lerpResult343_g1065 - DickOrigin16_g1065 );
				float3 temp_output_5_0_g1066 = DickRight184_g1065;
				float dotResult15_g1066 = dot( temp_output_2_0_g1066 , temp_output_5_0_g1066 );
				float3 temp_output_65_0_g1066 = cross( normalizeResult29_g1070 , normalizeResult27_g1070 );
				float dotResult18_g1066 = dot( temp_output_2_0_g1066 , temp_output_4_0_g1066 );
				float temp_output_208_0_g1065 = saturate( sign( temp_output_152_0_g1065 ) );
				float3 lerpResult221_g1065 = lerp( ( ( ( temp_output_19_0_g1077 * temp_output_19_0_g1077 * temp_output_19_0_g1077 * temp_output_8_0_g1076 ) + ( temp_output_19_0_g1077 * temp_output_19_0_g1077 * 3.0 * temp_output_26_0_g1077 * temp_output_9_0_g1076 ) + ( 3.0 * temp_output_19_0_g1077 * temp_output_26_0_g1077 * temp_output_26_0_g1077 * temp_output_10_0_g1076 ) + ( temp_output_26_0_g1077 * temp_output_26_0_g1077 * temp_output_26_0_g1077 * temp_output_11_0_g1076 ) ) + ( temp_output_65_22_g1076 * dotResult15_g1076 ) + ( temp_output_65_0_g1076 * dotResult18_g1076 ) ) , ( ( ( temp_output_19_0_g1067 * temp_output_19_0_g1067 * temp_output_19_0_g1067 * temp_output_8_0_g1066 ) + ( temp_output_19_0_g1067 * temp_output_19_0_g1067 * 3.0 * temp_output_26_0_g1067 * temp_output_9_0_g1066 ) + ( 3.0 * temp_output_19_0_g1067 * temp_output_26_0_g1067 * temp_output_26_0_g1067 * temp_output_10_0_g1066 ) + ( temp_output_26_0_g1067 * temp_output_26_0_g1067 * temp_output_26_0_g1067 * temp_output_11_0_g1066 ) ) + ( temp_output_65_22_g1066 * dotResult15_g1066 ) + ( temp_output_65_0_g1066 * dotResult18_g1066 ) ) , temp_output_208_0_g1065);
				float3 temp_output_42_0_g1071 = DickForward18_g1065;
				float NonVisibleLength165_g1065 = ( temp_output_11_0_g1065 * _PenetratorLength );
				float3 temp_output_52_0_g1071 = ( ( temp_output_42_0_g1071 * ( ( NonVisibleLength165_g1065 - OrifaceLength34_g1065 ) - DickLength19_g1065 ) ) + ( lerpResult343_g1065 - DickOrigin16_g1065 ) );
				float dotResult53_g1071 = dot( temp_output_42_0_g1071 , temp_output_52_0_g1071 );
				float temp_output_1_0_g1073 = 1.0;
				float temp_output_8_0_g1073 = ( 1.0 - temp_output_1_0_g1073 );
				float3 temp_output_3_0_g1073 = OrifaceOutPosition1183_g1065;
				float3 temp_output_4_0_g1073 = OrifaceOutPosition2182_g1065;
				float3 temp_output_7_0_g1072 = ( ( 3.0 * temp_output_8_0_g1073 * temp_output_8_0_g1073 * ( temp_output_3_0_g1073 - OrifacePosition170_g1065 ) ) + ( 6.0 * temp_output_8_0_g1073 * temp_output_1_0_g1073 * ( temp_output_4_0_g1073 - temp_output_3_0_g1073 ) ) + ( 3.0 * temp_output_1_0_g1073 * temp_output_1_0_g1073 * ( OrifaceOutPosition3175_g1065 - temp_output_4_0_g1073 ) ) );
				float3 normalizeResult27_g1074 = normalize( temp_output_7_0_g1072 );
				float3 temp_output_85_23_g1071 = normalizeResult27_g1074;
				float3 temp_output_4_0_g1071 = DickUp172_g1065;
				float dotResult54_g1071 = dot( temp_output_4_0_g1071 , temp_output_52_0_g1071 );
				float3 temp_output_10_0_g1072 = temp_output_4_0_g1071;
				float3 temp_output_13_0_g1072 = temp_output_42_0_g1071;
				float dotResult33_g1072 = dot( temp_output_7_0_g1072 , temp_output_10_0_g1072 );
				float3 lerpResult34_g1072 = lerp( temp_output_10_0_g1072 , -temp_output_13_0_g1072 , saturate( dotResult33_g1072 ));
				float dotResult37_g1072 = dot( temp_output_7_0_g1072 , -temp_output_10_0_g1072 );
				float3 lerpResult40_g1072 = lerp( lerpResult34_g1072 , temp_output_13_0_g1072 , saturate( dotResult37_g1072 ));
				float3 normalizeResult42_g1072 = normalize( lerpResult40_g1072 );
				float3 normalizeResult31_g1074 = normalize( normalizeResult42_g1072 );
				float3 normalizeResult29_g1074 = normalize( cross( normalizeResult27_g1074 , normalizeResult31_g1074 ) );
				float3 temp_output_85_0_g1071 = cross( normalizeResult29_g1074 , normalizeResult27_g1074 );
				float3 temp_output_43_0_g1071 = DickRight184_g1065;
				float dotResult55_g1071 = dot( temp_output_43_0_g1071 , temp_output_52_0_g1071 );
				float3 temp_output_85_22_g1071 = normalizeResult29_g1074;
				float temp_output_222_0_g1065 = saturate( sign( ( temp_output_157_0_g1065 - 1.0 ) ) );
				float3 lerpResult224_g1065 = lerp( lerpResult221_g1065 , ( ( ( dotResult53_g1071 * temp_output_85_23_g1071 ) + ( dotResult54_g1071 * temp_output_85_0_g1071 ) + ( dotResult55_g1071 * temp_output_85_22_g1071 ) ) + OrifaceOutPosition3175_g1065 ) , temp_output_222_0_g1065);
				float3 lerpResult418_g1065 = lerp( lerpResult224_g1065 , lerpResult221_g1065 , ClipDick413_g1065);
				float temp_output_226_0_g1065 = saturate( -PenetrationDepth39_g1065 );
				float3 lerpResult232_g1065 = lerp( lerpResult418_g1065 , originalPosition126_g1065 , temp_output_226_0_g1065);
				float3 ifLocalVar237_g1065 = 0;
				if( temp_output_234_0_g1065 <= 0.0 )
				ifLocalVar237_g1065 = originalPosition126_g1065;
				else
				ifLocalVar237_g1065 = lerpResult232_g1065;
				float DeformBalls426_g1065 = _DeformBalls;
				float3 lerpResult428_g1065 = lerp( ifLocalVar237_g1065 , lerpResult232_g1065 , DeformBalls426_g1065);
				
				float3 temp_output_21_0_g1076 = VertexNormal259_g1065;
				float dotResult55_g1076 = dot( temp_output_21_0_g1076 , temp_output_3_0_g1076 );
				float dotResult56_g1076 = dot( temp_output_21_0_g1076 , temp_output_4_0_g1076 );
				float dotResult57_g1076 = dot( temp_output_21_0_g1076 , temp_output_5_0_g1076 );
				float3 normalizeResult31_g1076 = normalize( ( ( dotResult55_g1076 * normalizeResult27_g1080 ) + ( dotResult56_g1076 * temp_output_65_0_g1076 ) + ( dotResult57_g1076 * temp_output_65_22_g1076 ) ) );
				float3 temp_output_21_0_g1066 = VertexNormal259_g1065;
				float dotResult55_g1066 = dot( temp_output_21_0_g1066 , temp_output_3_0_g1066 );
				float dotResult56_g1066 = dot( temp_output_21_0_g1066 , temp_output_4_0_g1066 );
				float dotResult57_g1066 = dot( temp_output_21_0_g1066 , temp_output_5_0_g1066 );
				float3 normalizeResult31_g1066 = normalize( ( ( dotResult55_g1066 * normalizeResult27_g1070 ) + ( dotResult56_g1066 * temp_output_65_0_g1066 ) + ( dotResult57_g1066 * temp_output_65_22_g1066 ) ) );
				float3 lerpResult227_g1065 = lerp( normalizeResult31_g1076 , normalizeResult31_g1066 , temp_output_208_0_g1065);
				float3 temp_output_24_0_g1071 = VertexNormal259_g1065;
				float dotResult61_g1071 = dot( temp_output_42_0_g1071 , temp_output_24_0_g1071 );
				float dotResult62_g1071 = dot( temp_output_4_0_g1071 , temp_output_24_0_g1071 );
				float dotResult60_g1071 = dot( temp_output_43_0_g1071 , temp_output_24_0_g1071 );
				float3 normalizeResult33_g1071 = normalize( ( ( dotResult61_g1071 * temp_output_85_23_g1071 ) + ( dotResult62_g1071 * temp_output_85_0_g1071 ) + ( dotResult60_g1071 * temp_output_85_22_g1071 ) ) );
				float3 lerpResult233_g1065 = lerp( lerpResult227_g1065 , normalizeResult33_g1071 , temp_output_222_0_g1065);
				float3 lerpResult419_g1065 = lerp( lerpResult233_g1065 , lerpResult227_g1065 , ClipDick413_g1065);
				float3 lerpResult238_g1065 = lerp( lerpResult419_g1065 , VertexNormal259_g1065 , temp_output_226_0_g1065);
				float3 ifLocalVar391_g1065 = 0;
				if( temp_output_234_0_g1065 <= 0.0 )
				ifLocalVar391_g1065 = VertexNormal259_g1065;
				else
				ifLocalVar391_g1065 = lerpResult238_g1065;
				
				float lerpResult424_g1065 = lerp( 1.0 , InsideLerp123_g1065 , InvisibleWhenInside420_g1065);
				float vertexToFrag250_g1065 = lerpResult424_g1065;
				o.ase_texcoord2.x = vertexToFrag250_g1065;
				
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord2.yzw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = lerpResult428_g1065;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = ifLocalVar391_g1065;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
				#endif
				float3 normalWS = TransformObjectToWorldDir(v.ase_normal);

		#if ASE_SRP_VERSION >= 110000 
			#if _CASTING_PUNCTUAL_LIGHT_SHADOW
				float3 lightDirectionWS = normalize(_LightPosition - positionWS);
			#else
				float3 lightDirectionWS = _LightDirection;
			#endif
				float4 clipPos = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));
			#if UNITY_REVERSED_Z
				clipPos.z = min(clipPos.z, UNITY_NEAR_CLIP_VALUE);
			#else
				clipPos.z = max(clipPos.z, UNITY_NEAR_CLIP_VALUE);
			#endif
		#else
				float4 clipPos = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));
			#if UNITY_REVERSED_Z
				clipPos.z = min(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
			#else
				clipPos.z = max(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
			#endif
		#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = clipPos;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				o.clipPos = clipPos;
				return o;
			}

			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_tangent : TANGENT;
				float4 ase_color : COLOR;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord3 : TEXCOORD3;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord2 = v.ase_texcoord2;
				o.ase_tangent = v.ase_tangent;
				o.ase_color = v.ase_color;
				o.ase_texcoord1 = v.ase_texcoord1;
				o.ase_texcoord3 = v.ase_texcoord3;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord2 = patch[0].ase_texcoord2 * bary.x + patch[1].ase_texcoord2 * bary.y + patch[2].ase_texcoord2 * bary.z;
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				o.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				o.ase_texcoord3 = patch[0].ase_texcoord3 * bary.x + patch[1].ase_texcoord3 * bary.y + patch[2].ase_texcoord3 * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE)
				#define ASE_SV_DEPTH SV_DepthLessEqual  
			#else
				#define ASE_SV_DEPTH SV_Depth
			#endif

			half4 frag(	VertexOutput IN 
						#ifdef ASE_DEPTH_WRITE_ON
						,out float outputDepth : ASE_SV_DEPTH
						#endif
						 ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );
				
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.worldPos;
				#endif
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float vertexToFrag250_g1065 = IN.ase_texcoord2.x;
				
				float Alpha = vertexToFrag250_g1065;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;
				#ifdef ASE_DEPTH_WRITE_ON
				float DepthValue = 0;
				#endif

				#ifdef _ALPHATEST_ON
					#ifdef _ALPHATEST_SHADOW_ON
						clip(Alpha - AlphaClipThresholdShadow);
					#else
						clip(Alpha - AlphaClipThreshold);
					#endif
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif
				#ifdef ASE_DEPTH_WRITE_ON
					outputDepth = DepthValue;
				#endif
				return 0;
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthOnly"
			Tags { "LightMode"="DepthOnly" }

			ZWrite On
			ColorMask 0
			AlphaToMask Off

			HLSLPROGRAM
			
			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_instancing
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define ASE_ABSOLUTE_VERTEX_POS 1
			#define _EMISSION
			#define _ALPHATEST_ON 1
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 100600

			
			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS_DEPTHONLY

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_VERT_POSITION


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_tangent : TANGENT;
				float4 ase_color : COLOR;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord3 : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				float4 ase_texcoord2 : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _MetallicSmoothness_ST;
			float4 _EmissionMap_ST;
			float4 _NormalMap_ST;
			float4 _BaseColorMap_ST;
			float4 _EmissionColor;
			float3 _PenetratorOrigin;
			float3 _OrificeWorldPosition;
			float3 _PenetratorUp;
			float3 _PenetratorForward;
			float3 _OrificeOutWorldPosition3;
			float3 _OrificeOutWorldPosition2;
			float3 _OrificeOutWorldPosition1;
			float3 _OrificeWorldNormal;
			float3 _PenetratorRight;
			float _DeformBalls;
			float _InvisibleWhenInside;
			float _PinchBuffer;
			float _OrificeLength;
			float _NoBlendshapes;
			float _PenetratorCumActive;
			float _PenetratorCumProgress;
			float _PenetratorSquishPullAmount;
			float _PenetratorBulgePercentage;
			float _BulgeDistance;
			float _PenetrationDepth;
			float _PenetratorLength;
			float _ClipDick;
			float _PenetratorBlendshapeMultiplier;
			#ifdef _TRANSMISSION_ASE
				float _TransmissionShadow;
			#endif
			#ifdef _TRANSLUCENCY_ASE
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			float4 _JiggleInfos[16];
			sampler2D _Foam;


			float3 GetSoftbodyOffset3_g1064( float blend, float3 vertexPosition )
			{
				float3 vertexOffset = float3(0,0,0);
				for(int i=0;i<8;i++) {
				    float4 targetPosePositionRadius = _JiggleInfos[i*2];
				    float4 verletPositionBlend = _JiggleInfos[i*2+1];
				    float3 movement = (verletPositionBlend.xyz - targetPosePositionRadius.xyz);
				    float dist = distance(vertexPosition, targetPosePositionRadius.xyz);
				    float multi = 1-smoothstep(0,targetPosePositionRadius.w,dist);
				    vertexOffset += movement * multi * verletPositionBlend.w * blend;
				}
				return vertexOffset;
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 VertexNormal259_g1065 = v.ase_normal;
				float3 normalizeResult27_g1081 = normalize( VertexNormal259_g1065 );
				float3 temp_output_35_0_g1065 = normalizeResult27_g1081;
				float3 normalizeResult31_g1081 = normalize( v.ase_tangent.xyz );
				float3 normalizeResult29_g1081 = normalize( cross( normalizeResult27_g1081 , normalizeResult31_g1081 ) );
				float3 temp_output_35_1_g1065 = cross( normalizeResult29_g1081 , normalizeResult27_g1081 );
				float3 temp_output_35_2_g1065 = normalizeResult29_g1081;
				float3 SquishDelta85_g1065 = ( ( ( temp_output_35_0_g1065 * v.ase_texcoord2.x ) + ( temp_output_35_1_g1065 * v.ase_texcoord2.y ) + ( temp_output_35_2_g1065 * v.ase_texcoord2.z ) ) * _PenetratorBlendshapeMultiplier );
				float temp_output_234_0_g1065 = length( SquishDelta85_g1065 );
				float temp_output_11_0_g1065 = max( _PenetrationDepth , 0.0 );
				float VisibleLength25_g1065 = ( _PenetratorLength * ( 1.0 - temp_output_11_0_g1065 ) );
				float3 DickOrigin16_g1065 = _PenetratorOrigin;
				float4 appendResult132_g1065 = (float4(_OrificeWorldPosition , 1.0));
				float4 transform140_g1065 = mul(GetWorldToObjectMatrix(),appendResult132_g1065);
				float3 OrifacePosition170_g1065 = (transform140_g1065).xyz;
				float DickLength19_g1065 = _PenetratorLength;
				float3 DickUp172_g1065 = _PenetratorUp;
				float blend3_g1064 = v.ase_color.r;
				float2 texCoord10 = v.ase_texcoord1 * float2( 1,1 ) + float2( 0,0 );
				float mulTime12 = _TimeParameters.x * 0.01;
				float mulTime11 = _TimeParameters.x * 0.1;
				float2 appendResult15 = (float2(( texCoord10.x + mulTime12 ) , ( texCoord10.y + mulTime11 )));
				float4 tex2DNode16 = tex2Dlod( _Foam, float4( appendResult15, 0, 0.0) );
				float3 temp_output_20_0 = ( v.ase_normal * _BulgeDistance * tex2DNode16.r * v.ase_color.g );
				float3 vertexPosition3_g1064 = ( v.vertex.xyz + temp_output_20_0 );
				float3 localGetSoftbodyOffset3_g1064 = GetSoftbodyOffset3_g1064( blend3_g1064 , vertexPosition3_g1064 );
				float3 VertexPosition254_g1065 = ( localGetSoftbodyOffset3_g1064 + temp_output_20_0 + v.vertex.xyz );
				float3 temp_output_27_0_g1065 = ( VertexPosition254_g1065 - DickOrigin16_g1065 );
				float3 DickForward18_g1065 = _PenetratorForward;
				float dotResult42_g1065 = dot( temp_output_27_0_g1065 , DickForward18_g1065 );
				float BulgePercentage37_g1065 = _PenetratorBulgePercentage;
				float temp_output_1_0_g1075 = saturate( ( abs( ( dotResult42_g1065 - VisibleLength25_g1065 ) ) / ( DickLength19_g1065 * BulgePercentage37_g1065 ) ) );
				float temp_output_94_0_g1065 = sqrt( ( 1.0 - ( temp_output_1_0_g1075 * temp_output_1_0_g1075 ) ) );
				float3 PullDelta91_g1065 = ( ( ( temp_output_35_0_g1065 * v.ase_texcoord3.x ) + ( temp_output_35_1_g1065 * v.ase_texcoord3.y ) + ( temp_output_35_2_g1065 * v.ase_texcoord3.z ) ) * _PenetratorBlendshapeMultiplier );
				float dotResult32_g1065 = dot( temp_output_27_0_g1065 , DickForward18_g1065 );
				float temp_output_1_0_g1082 = saturate( ( abs( ( dotResult32_g1065 - ( DickLength19_g1065 * _PenetratorCumProgress ) ) ) / ( DickLength19_g1065 * BulgePercentage37_g1065 ) ) );
				float3 CumDelta90_g1065 = ( ( ( temp_output_35_0_g1065 * v.ase_texcoord1.w ) + ( temp_output_35_1_g1065 * v.ase_texcoord2.w ) + ( temp_output_35_2_g1065 * v.ase_texcoord3.w ) ) * _PenetratorBlendshapeMultiplier );
				float3 lerpResult410_g1065 = lerp( ( VertexPosition254_g1065 + ( SquishDelta85_g1065 * temp_output_94_0_g1065 * saturate( -_PenetratorSquishPullAmount ) ) + ( temp_output_94_0_g1065 * PullDelta91_g1065 * saturate( _PenetratorSquishPullAmount ) ) + ( sqrt( ( 1.0 - ( temp_output_1_0_g1082 * temp_output_1_0_g1082 ) ) ) * CumDelta90_g1065 * _PenetratorCumActive ) ) , VertexPosition254_g1065 , _NoBlendshapes);
				float3 originalPosition126_g1065 = lerpResult410_g1065;
				float dotResult118_g1065 = dot( ( lerpResult410_g1065 - DickOrigin16_g1065 ) , DickForward18_g1065 );
				float PenetrationDepth39_g1065 = _PenetrationDepth;
				float temp_output_65_0_g1065 = ( PenetrationDepth39_g1065 * DickLength19_g1065 );
				float OrifaceLength34_g1065 = _OrificeLength;
				float temp_output_73_0_g1065 = ( _PinchBuffer * OrifaceLength34_g1065 );
				float dotResult80_g1065 = dot( ( lerpResult410_g1065 - DickOrigin16_g1065 ) , DickForward18_g1065 );
				float temp_output_112_0_g1065 = ( -( ( ( temp_output_65_0_g1065 - temp_output_73_0_g1065 ) + dotResult80_g1065 ) - DickLength19_g1065 ) * 10.0 );
				float ClipDick413_g1065 = _ClipDick;
				float lerpResult411_g1065 = lerp( max( temp_output_112_0_g1065 , ( ( ( temp_output_65_0_g1065 + dotResult80_g1065 + temp_output_73_0_g1065 ) - ( OrifaceLength34_g1065 + DickLength19_g1065 ) ) * 10.0 ) ) , temp_output_112_0_g1065 , ClipDick413_g1065);
				float InsideLerp123_g1065 = saturate( lerpResult411_g1065 );
				float3 lerpResult124_g1065 = lerp( ( ( DickForward18_g1065 * dotResult118_g1065 ) + DickOrigin16_g1065 ) , originalPosition126_g1065 , InsideLerp123_g1065);
				float InvisibleWhenInside420_g1065 = _InvisibleWhenInside;
				float3 lerpResult422_g1065 = lerp( originalPosition126_g1065 , lerpResult124_g1065 , InvisibleWhenInside420_g1065);
				float3 temp_output_354_0_g1065 = ( lerpResult422_g1065 - DickOrigin16_g1065 );
				float dotResult373_g1065 = dot( DickUp172_g1065 , temp_output_354_0_g1065 );
				float3 DickRight184_g1065 = _PenetratorRight;
				float dotResult374_g1065 = dot( DickRight184_g1065 , temp_output_354_0_g1065 );
				float dotResult375_g1065 = dot( temp_output_354_0_g1065 , DickForward18_g1065 );
				float3 lerpResult343_g1065 = lerp( ( ( ( saturate( ( ( VisibleLength25_g1065 - distance( DickOrigin16_g1065 , OrifacePosition170_g1065 ) ) / DickLength19_g1065 ) ) + 1.0 ) * dotResult373_g1065 * DickUp172_g1065 ) + ( ( saturate( ( ( VisibleLength25_g1065 - distance( DickOrigin16_g1065 , OrifacePosition170_g1065 ) ) / DickLength19_g1065 ) ) + 1.0 ) * dotResult374_g1065 * DickRight184_g1065 ) + ( DickForward18_g1065 * dotResult375_g1065 ) + DickOrigin16_g1065 ) , lerpResult422_g1065 , saturate( PenetrationDepth39_g1065 ));
				float dotResult177_g1065 = dot( ( lerpResult343_g1065 - DickOrigin16_g1065 ) , DickForward18_g1065 );
				float temp_output_178_0_g1065 = max( VisibleLength25_g1065 , 0.05 );
				float temp_output_42_0_g1076 = ( dotResult177_g1065 / temp_output_178_0_g1065 );
				float temp_output_26_0_g1077 = temp_output_42_0_g1076;
				float temp_output_19_0_g1077 = ( 1.0 - temp_output_26_0_g1077 );
				float3 temp_output_8_0_g1076 = DickOrigin16_g1065;
				float temp_output_393_0_g1065 = distance( DickOrigin16_g1065 , OrifacePosition170_g1065 );
				float temp_output_396_0_g1065 = min( temp_output_178_0_g1065 , temp_output_393_0_g1065 );
				float3 temp_output_9_0_g1076 = ( DickOrigin16_g1065 + ( DickForward18_g1065 * temp_output_396_0_g1065 * 0.25 ) );
				float4 appendResult130_g1065 = (float4(_OrificeWorldNormal , 0.0));
				float4 transform135_g1065 = mul(GetWorldToObjectMatrix(),appendResult130_g1065);
				float3 OrifaceNormal155_g1065 = (transform135_g1065).xyz;
				float3 temp_output_10_0_g1076 = ( OrifacePosition170_g1065 + ( OrifaceNormal155_g1065 * 0.25 * temp_output_396_0_g1065 ) );
				float3 temp_output_11_0_g1076 = OrifacePosition170_g1065;
				float temp_output_1_0_g1079 = temp_output_42_0_g1076;
				float temp_output_8_0_g1079 = ( 1.0 - temp_output_1_0_g1079 );
				float3 temp_output_3_0_g1079 = temp_output_9_0_g1076;
				float3 temp_output_4_0_g1079 = temp_output_10_0_g1076;
				float3 temp_output_7_0_g1078 = ( ( 3.0 * temp_output_8_0_g1079 * temp_output_8_0_g1079 * ( temp_output_3_0_g1079 - temp_output_8_0_g1076 ) ) + ( 6.0 * temp_output_8_0_g1079 * temp_output_1_0_g1079 * ( temp_output_4_0_g1079 - temp_output_3_0_g1079 ) ) + ( 3.0 * temp_output_1_0_g1079 * temp_output_1_0_g1079 * ( temp_output_11_0_g1076 - temp_output_4_0_g1079 ) ) );
				float3 normalizeResult27_g1080 = normalize( temp_output_7_0_g1078 );
				float3 temp_output_4_0_g1076 = DickUp172_g1065;
				float3 temp_output_10_0_g1078 = temp_output_4_0_g1076;
				float3 temp_output_3_0_g1076 = DickForward18_g1065;
				float3 temp_output_13_0_g1078 = temp_output_3_0_g1076;
				float dotResult33_g1078 = dot( temp_output_7_0_g1078 , temp_output_10_0_g1078 );
				float3 lerpResult34_g1078 = lerp( temp_output_10_0_g1078 , -temp_output_13_0_g1078 , saturate( dotResult33_g1078 ));
				float dotResult37_g1078 = dot( temp_output_7_0_g1078 , -temp_output_10_0_g1078 );
				float3 lerpResult40_g1078 = lerp( lerpResult34_g1078 , temp_output_13_0_g1078 , saturate( dotResult37_g1078 ));
				float3 normalizeResult42_g1078 = normalize( lerpResult40_g1078 );
				float3 normalizeResult31_g1080 = normalize( normalizeResult42_g1078 );
				float3 normalizeResult29_g1080 = normalize( cross( normalizeResult27_g1080 , normalizeResult31_g1080 ) );
				float3 temp_output_65_22_g1076 = normalizeResult29_g1080;
				float3 temp_output_2_0_g1076 = ( lerpResult343_g1065 - DickOrigin16_g1065 );
				float3 temp_output_5_0_g1076 = DickRight184_g1065;
				float dotResult15_g1076 = dot( temp_output_2_0_g1076 , temp_output_5_0_g1076 );
				float3 temp_output_65_0_g1076 = cross( normalizeResult29_g1080 , normalizeResult27_g1080 );
				float dotResult18_g1076 = dot( temp_output_2_0_g1076 , temp_output_4_0_g1076 );
				float dotResult142_g1065 = dot( ( lerpResult343_g1065 - DickOrigin16_g1065 ) , DickForward18_g1065 );
				float temp_output_152_0_g1065 = ( dotResult142_g1065 - VisibleLength25_g1065 );
				float temp_output_157_0_g1065 = ( temp_output_152_0_g1065 / OrifaceLength34_g1065 );
				float lerpResult416_g1065 = lerp( temp_output_157_0_g1065 , min( temp_output_157_0_g1065 , 1.0 ) , ClipDick413_g1065);
				float temp_output_42_0_g1066 = lerpResult416_g1065;
				float temp_output_26_0_g1067 = temp_output_42_0_g1066;
				float temp_output_19_0_g1067 = ( 1.0 - temp_output_26_0_g1067 );
				float3 temp_output_8_0_g1066 = OrifacePosition170_g1065;
				float4 appendResult145_g1065 = (float4(_OrificeOutWorldPosition1 , 1.0));
				float4 transform151_g1065 = mul(GetWorldToObjectMatrix(),appendResult145_g1065);
				float3 OrifaceOutPosition1183_g1065 = (transform151_g1065).xyz;
				float3 temp_output_9_0_g1066 = OrifaceOutPosition1183_g1065;
				float4 appendResult144_g1065 = (float4(_OrificeOutWorldPosition2 , 1.0));
				float4 transform154_g1065 = mul(GetWorldToObjectMatrix(),appendResult144_g1065);
				float3 OrifaceOutPosition2182_g1065 = (transform154_g1065).xyz;
				float3 temp_output_10_0_g1066 = OrifaceOutPosition2182_g1065;
				float4 appendResult143_g1065 = (float4(_OrificeOutWorldPosition3 , 1.0));
				float4 transform147_g1065 = mul(GetWorldToObjectMatrix(),appendResult143_g1065);
				float3 OrifaceOutPosition3175_g1065 = (transform147_g1065).xyz;
				float3 temp_output_11_0_g1066 = OrifaceOutPosition3175_g1065;
				float temp_output_1_0_g1069 = temp_output_42_0_g1066;
				float temp_output_8_0_g1069 = ( 1.0 - temp_output_1_0_g1069 );
				float3 temp_output_3_0_g1069 = temp_output_9_0_g1066;
				float3 temp_output_4_0_g1069 = temp_output_10_0_g1066;
				float3 temp_output_7_0_g1068 = ( ( 3.0 * temp_output_8_0_g1069 * temp_output_8_0_g1069 * ( temp_output_3_0_g1069 - temp_output_8_0_g1066 ) ) + ( 6.0 * temp_output_8_0_g1069 * temp_output_1_0_g1069 * ( temp_output_4_0_g1069 - temp_output_3_0_g1069 ) ) + ( 3.0 * temp_output_1_0_g1069 * temp_output_1_0_g1069 * ( temp_output_11_0_g1066 - temp_output_4_0_g1069 ) ) );
				float3 normalizeResult27_g1070 = normalize( temp_output_7_0_g1068 );
				float3 temp_output_4_0_g1066 = DickUp172_g1065;
				float3 temp_output_10_0_g1068 = temp_output_4_0_g1066;
				float3 temp_output_3_0_g1066 = DickForward18_g1065;
				float3 temp_output_13_0_g1068 = temp_output_3_0_g1066;
				float dotResult33_g1068 = dot( temp_output_7_0_g1068 , temp_output_10_0_g1068 );
				float3 lerpResult34_g1068 = lerp( temp_output_10_0_g1068 , -temp_output_13_0_g1068 , saturate( dotResult33_g1068 ));
				float dotResult37_g1068 = dot( temp_output_7_0_g1068 , -temp_output_10_0_g1068 );
				float3 lerpResult40_g1068 = lerp( lerpResult34_g1068 , temp_output_13_0_g1068 , saturate( dotResult37_g1068 ));
				float3 normalizeResult42_g1068 = normalize( lerpResult40_g1068 );
				float3 normalizeResult31_g1070 = normalize( normalizeResult42_g1068 );
				float3 normalizeResult29_g1070 = normalize( cross( normalizeResult27_g1070 , normalizeResult31_g1070 ) );
				float3 temp_output_65_22_g1066 = normalizeResult29_g1070;
				float3 temp_output_2_0_g1066 = ( lerpResult343_g1065 - DickOrigin16_g1065 );
				float3 temp_output_5_0_g1066 = DickRight184_g1065;
				float dotResult15_g1066 = dot( temp_output_2_0_g1066 , temp_output_5_0_g1066 );
				float3 temp_output_65_0_g1066 = cross( normalizeResult29_g1070 , normalizeResult27_g1070 );
				float dotResult18_g1066 = dot( temp_output_2_0_g1066 , temp_output_4_0_g1066 );
				float temp_output_208_0_g1065 = saturate( sign( temp_output_152_0_g1065 ) );
				float3 lerpResult221_g1065 = lerp( ( ( ( temp_output_19_0_g1077 * temp_output_19_0_g1077 * temp_output_19_0_g1077 * temp_output_8_0_g1076 ) + ( temp_output_19_0_g1077 * temp_output_19_0_g1077 * 3.0 * temp_output_26_0_g1077 * temp_output_9_0_g1076 ) + ( 3.0 * temp_output_19_0_g1077 * temp_output_26_0_g1077 * temp_output_26_0_g1077 * temp_output_10_0_g1076 ) + ( temp_output_26_0_g1077 * temp_output_26_0_g1077 * temp_output_26_0_g1077 * temp_output_11_0_g1076 ) ) + ( temp_output_65_22_g1076 * dotResult15_g1076 ) + ( temp_output_65_0_g1076 * dotResult18_g1076 ) ) , ( ( ( temp_output_19_0_g1067 * temp_output_19_0_g1067 * temp_output_19_0_g1067 * temp_output_8_0_g1066 ) + ( temp_output_19_0_g1067 * temp_output_19_0_g1067 * 3.0 * temp_output_26_0_g1067 * temp_output_9_0_g1066 ) + ( 3.0 * temp_output_19_0_g1067 * temp_output_26_0_g1067 * temp_output_26_0_g1067 * temp_output_10_0_g1066 ) + ( temp_output_26_0_g1067 * temp_output_26_0_g1067 * temp_output_26_0_g1067 * temp_output_11_0_g1066 ) ) + ( temp_output_65_22_g1066 * dotResult15_g1066 ) + ( temp_output_65_0_g1066 * dotResult18_g1066 ) ) , temp_output_208_0_g1065);
				float3 temp_output_42_0_g1071 = DickForward18_g1065;
				float NonVisibleLength165_g1065 = ( temp_output_11_0_g1065 * _PenetratorLength );
				float3 temp_output_52_0_g1071 = ( ( temp_output_42_0_g1071 * ( ( NonVisibleLength165_g1065 - OrifaceLength34_g1065 ) - DickLength19_g1065 ) ) + ( lerpResult343_g1065 - DickOrigin16_g1065 ) );
				float dotResult53_g1071 = dot( temp_output_42_0_g1071 , temp_output_52_0_g1071 );
				float temp_output_1_0_g1073 = 1.0;
				float temp_output_8_0_g1073 = ( 1.0 - temp_output_1_0_g1073 );
				float3 temp_output_3_0_g1073 = OrifaceOutPosition1183_g1065;
				float3 temp_output_4_0_g1073 = OrifaceOutPosition2182_g1065;
				float3 temp_output_7_0_g1072 = ( ( 3.0 * temp_output_8_0_g1073 * temp_output_8_0_g1073 * ( temp_output_3_0_g1073 - OrifacePosition170_g1065 ) ) + ( 6.0 * temp_output_8_0_g1073 * temp_output_1_0_g1073 * ( temp_output_4_0_g1073 - temp_output_3_0_g1073 ) ) + ( 3.0 * temp_output_1_0_g1073 * temp_output_1_0_g1073 * ( OrifaceOutPosition3175_g1065 - temp_output_4_0_g1073 ) ) );
				float3 normalizeResult27_g1074 = normalize( temp_output_7_0_g1072 );
				float3 temp_output_85_23_g1071 = normalizeResult27_g1074;
				float3 temp_output_4_0_g1071 = DickUp172_g1065;
				float dotResult54_g1071 = dot( temp_output_4_0_g1071 , temp_output_52_0_g1071 );
				float3 temp_output_10_0_g1072 = temp_output_4_0_g1071;
				float3 temp_output_13_0_g1072 = temp_output_42_0_g1071;
				float dotResult33_g1072 = dot( temp_output_7_0_g1072 , temp_output_10_0_g1072 );
				float3 lerpResult34_g1072 = lerp( temp_output_10_0_g1072 , -temp_output_13_0_g1072 , saturate( dotResult33_g1072 ));
				float dotResult37_g1072 = dot( temp_output_7_0_g1072 , -temp_output_10_0_g1072 );
				float3 lerpResult40_g1072 = lerp( lerpResult34_g1072 , temp_output_13_0_g1072 , saturate( dotResult37_g1072 ));
				float3 normalizeResult42_g1072 = normalize( lerpResult40_g1072 );
				float3 normalizeResult31_g1074 = normalize( normalizeResult42_g1072 );
				float3 normalizeResult29_g1074 = normalize( cross( normalizeResult27_g1074 , normalizeResult31_g1074 ) );
				float3 temp_output_85_0_g1071 = cross( normalizeResult29_g1074 , normalizeResult27_g1074 );
				float3 temp_output_43_0_g1071 = DickRight184_g1065;
				float dotResult55_g1071 = dot( temp_output_43_0_g1071 , temp_output_52_0_g1071 );
				float3 temp_output_85_22_g1071 = normalizeResult29_g1074;
				float temp_output_222_0_g1065 = saturate( sign( ( temp_output_157_0_g1065 - 1.0 ) ) );
				float3 lerpResult224_g1065 = lerp( lerpResult221_g1065 , ( ( ( dotResult53_g1071 * temp_output_85_23_g1071 ) + ( dotResult54_g1071 * temp_output_85_0_g1071 ) + ( dotResult55_g1071 * temp_output_85_22_g1071 ) ) + OrifaceOutPosition3175_g1065 ) , temp_output_222_0_g1065);
				float3 lerpResult418_g1065 = lerp( lerpResult224_g1065 , lerpResult221_g1065 , ClipDick413_g1065);
				float temp_output_226_0_g1065 = saturate( -PenetrationDepth39_g1065 );
				float3 lerpResult232_g1065 = lerp( lerpResult418_g1065 , originalPosition126_g1065 , temp_output_226_0_g1065);
				float3 ifLocalVar237_g1065 = 0;
				if( temp_output_234_0_g1065 <= 0.0 )
				ifLocalVar237_g1065 = originalPosition126_g1065;
				else
				ifLocalVar237_g1065 = lerpResult232_g1065;
				float DeformBalls426_g1065 = _DeformBalls;
				float3 lerpResult428_g1065 = lerp( ifLocalVar237_g1065 , lerpResult232_g1065 , DeformBalls426_g1065);
				
				float3 temp_output_21_0_g1076 = VertexNormal259_g1065;
				float dotResult55_g1076 = dot( temp_output_21_0_g1076 , temp_output_3_0_g1076 );
				float dotResult56_g1076 = dot( temp_output_21_0_g1076 , temp_output_4_0_g1076 );
				float dotResult57_g1076 = dot( temp_output_21_0_g1076 , temp_output_5_0_g1076 );
				float3 normalizeResult31_g1076 = normalize( ( ( dotResult55_g1076 * normalizeResult27_g1080 ) + ( dotResult56_g1076 * temp_output_65_0_g1076 ) + ( dotResult57_g1076 * temp_output_65_22_g1076 ) ) );
				float3 temp_output_21_0_g1066 = VertexNormal259_g1065;
				float dotResult55_g1066 = dot( temp_output_21_0_g1066 , temp_output_3_0_g1066 );
				float dotResult56_g1066 = dot( temp_output_21_0_g1066 , temp_output_4_0_g1066 );
				float dotResult57_g1066 = dot( temp_output_21_0_g1066 , temp_output_5_0_g1066 );
				float3 normalizeResult31_g1066 = normalize( ( ( dotResult55_g1066 * normalizeResult27_g1070 ) + ( dotResult56_g1066 * temp_output_65_0_g1066 ) + ( dotResult57_g1066 * temp_output_65_22_g1066 ) ) );
				float3 lerpResult227_g1065 = lerp( normalizeResult31_g1076 , normalizeResult31_g1066 , temp_output_208_0_g1065);
				float3 temp_output_24_0_g1071 = VertexNormal259_g1065;
				float dotResult61_g1071 = dot( temp_output_42_0_g1071 , temp_output_24_0_g1071 );
				float dotResult62_g1071 = dot( temp_output_4_0_g1071 , temp_output_24_0_g1071 );
				float dotResult60_g1071 = dot( temp_output_43_0_g1071 , temp_output_24_0_g1071 );
				float3 normalizeResult33_g1071 = normalize( ( ( dotResult61_g1071 * temp_output_85_23_g1071 ) + ( dotResult62_g1071 * temp_output_85_0_g1071 ) + ( dotResult60_g1071 * temp_output_85_22_g1071 ) ) );
				float3 lerpResult233_g1065 = lerp( lerpResult227_g1065 , normalizeResult33_g1071 , temp_output_222_0_g1065);
				float3 lerpResult419_g1065 = lerp( lerpResult233_g1065 , lerpResult227_g1065 , ClipDick413_g1065);
				float3 lerpResult238_g1065 = lerp( lerpResult419_g1065 , VertexNormal259_g1065 , temp_output_226_0_g1065);
				float3 ifLocalVar391_g1065 = 0;
				if( temp_output_234_0_g1065 <= 0.0 )
				ifLocalVar391_g1065 = VertexNormal259_g1065;
				else
				ifLocalVar391_g1065 = lerpResult238_g1065;
				
				float lerpResult424_g1065 = lerp( 1.0 , InsideLerp123_g1065 , InvisibleWhenInside420_g1065);
				float vertexToFrag250_g1065 = lerpResult424_g1065;
				o.ase_texcoord2.x = vertexToFrag250_g1065;
				
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord2.yzw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = lerpResult428_g1065;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = ifLocalVar391_g1065;
				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				o.clipPos = positionCS;
				return o;
			}

			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_tangent : TANGENT;
				float4 ase_color : COLOR;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord3 : TEXCOORD3;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord2 = v.ase_texcoord2;
				o.ase_tangent = v.ase_tangent;
				o.ase_color = v.ase_color;
				o.ase_texcoord1 = v.ase_texcoord1;
				o.ase_texcoord3 = v.ase_texcoord3;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord2 = patch[0].ase_texcoord2 * bary.x + patch[1].ase_texcoord2 * bary.y + patch[2].ase_texcoord2 * bary.z;
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				o.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				o.ase_texcoord3 = patch[0].ase_texcoord3 * bary.x + patch[1].ase_texcoord3 * bary.y + patch[2].ase_texcoord3 * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE)
				#define ASE_SV_DEPTH SV_DepthLessEqual  
			#else
				#define ASE_SV_DEPTH SV_Depth
			#endif
			half4 frag(	VertexOutput IN 
						#ifdef ASE_DEPTH_WRITE_ON
						,out float outputDepth : ASE_SV_DEPTH
						#endif
						 ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.worldPos;
				#endif
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float vertexToFrag250_g1065 = IN.ase_texcoord2.x;
				
				float Alpha = vertexToFrag250_g1065;
				float AlphaClipThreshold = 0.5;
				#ifdef ASE_DEPTH_WRITE_ON
				float DepthValue = 0;
				#endif

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif
				#ifdef ASE_DEPTH_WRITE_ON
				outputDepth = DepthValue;
				#endif

				return 0;
			}
			ENDHLSL
		}
		
		
		Pass
		{
			
			Name "Meta"
			Tags { "LightMode"="Meta" }

			Cull Off

			HLSLPROGRAM
			
			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_instancing
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define ASE_ABSOLUTE_VERTEX_POS 1
			#define _EMISSION
			#define _ALPHATEST_ON 1
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 100600

			
			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS_META

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_VERT_POSITION


			#pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_tangent : TANGENT;
				float4 ase_color : COLOR;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				float4 ase_texcoord2 : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _MetallicSmoothness_ST;
			float4 _EmissionMap_ST;
			float4 _NormalMap_ST;
			float4 _BaseColorMap_ST;
			float4 _EmissionColor;
			float3 _PenetratorOrigin;
			float3 _OrificeWorldPosition;
			float3 _PenetratorUp;
			float3 _PenetratorForward;
			float3 _OrificeOutWorldPosition3;
			float3 _OrificeOutWorldPosition2;
			float3 _OrificeOutWorldPosition1;
			float3 _OrificeWorldNormal;
			float3 _PenetratorRight;
			float _DeformBalls;
			float _InvisibleWhenInside;
			float _PinchBuffer;
			float _OrificeLength;
			float _NoBlendshapes;
			float _PenetratorCumActive;
			float _PenetratorCumProgress;
			float _PenetratorSquishPullAmount;
			float _PenetratorBulgePercentage;
			float _BulgeDistance;
			float _PenetrationDepth;
			float _PenetratorLength;
			float _ClipDick;
			float _PenetratorBlendshapeMultiplier;
			#ifdef _TRANSMISSION_ASE
				float _TransmissionShadow;
			#endif
			#ifdef _TRANSLUCENCY_ASE
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			float4 _JiggleInfos[16];
			sampler2D _Foam;
			sampler2D _BaseColorMap;
			sampler2D _EmissionMap;


			float3 GetSoftbodyOffset3_g1064( float blend, float3 vertexPosition )
			{
				float3 vertexOffset = float3(0,0,0);
				for(int i=0;i<8;i++) {
				    float4 targetPosePositionRadius = _JiggleInfos[i*2];
				    float4 verletPositionBlend = _JiggleInfos[i*2+1];
				    float3 movement = (verletPositionBlend.xyz - targetPosePositionRadius.xyz);
				    float dist = distance(vertexPosition, targetPosePositionRadius.xyz);
				    float multi = 1-smoothstep(0,targetPosePositionRadius.w,dist);
				    vertexOffset += movement * multi * verletPositionBlend.w * blend;
				}
				return vertexOffset;
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 VertexNormal259_g1065 = v.ase_normal;
				float3 normalizeResult27_g1081 = normalize( VertexNormal259_g1065 );
				float3 temp_output_35_0_g1065 = normalizeResult27_g1081;
				float3 normalizeResult31_g1081 = normalize( v.ase_tangent.xyz );
				float3 normalizeResult29_g1081 = normalize( cross( normalizeResult27_g1081 , normalizeResult31_g1081 ) );
				float3 temp_output_35_1_g1065 = cross( normalizeResult29_g1081 , normalizeResult27_g1081 );
				float3 temp_output_35_2_g1065 = normalizeResult29_g1081;
				float3 SquishDelta85_g1065 = ( ( ( temp_output_35_0_g1065 * v.texcoord2.x ) + ( temp_output_35_1_g1065 * v.texcoord2.y ) + ( temp_output_35_2_g1065 * v.texcoord2.z ) ) * _PenetratorBlendshapeMultiplier );
				float temp_output_234_0_g1065 = length( SquishDelta85_g1065 );
				float temp_output_11_0_g1065 = max( _PenetrationDepth , 0.0 );
				float VisibleLength25_g1065 = ( _PenetratorLength * ( 1.0 - temp_output_11_0_g1065 ) );
				float3 DickOrigin16_g1065 = _PenetratorOrigin;
				float4 appendResult132_g1065 = (float4(_OrificeWorldPosition , 1.0));
				float4 transform140_g1065 = mul(GetWorldToObjectMatrix(),appendResult132_g1065);
				float3 OrifacePosition170_g1065 = (transform140_g1065).xyz;
				float DickLength19_g1065 = _PenetratorLength;
				float3 DickUp172_g1065 = _PenetratorUp;
				float blend3_g1064 = v.ase_color.r;
				float2 texCoord10 = v.texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float mulTime12 = _TimeParameters.x * 0.01;
				float mulTime11 = _TimeParameters.x * 0.1;
				float2 appendResult15 = (float2(( texCoord10.x + mulTime12 ) , ( texCoord10.y + mulTime11 )));
				float4 tex2DNode16 = tex2Dlod( _Foam, float4( appendResult15, 0, 0.0) );
				float3 temp_output_20_0 = ( v.ase_normal * _BulgeDistance * tex2DNode16.r * v.ase_color.g );
				float3 vertexPosition3_g1064 = ( v.vertex.xyz + temp_output_20_0 );
				float3 localGetSoftbodyOffset3_g1064 = GetSoftbodyOffset3_g1064( blend3_g1064 , vertexPosition3_g1064 );
				float3 VertexPosition254_g1065 = ( localGetSoftbodyOffset3_g1064 + temp_output_20_0 + v.vertex.xyz );
				float3 temp_output_27_0_g1065 = ( VertexPosition254_g1065 - DickOrigin16_g1065 );
				float3 DickForward18_g1065 = _PenetratorForward;
				float dotResult42_g1065 = dot( temp_output_27_0_g1065 , DickForward18_g1065 );
				float BulgePercentage37_g1065 = _PenetratorBulgePercentage;
				float temp_output_1_0_g1075 = saturate( ( abs( ( dotResult42_g1065 - VisibleLength25_g1065 ) ) / ( DickLength19_g1065 * BulgePercentage37_g1065 ) ) );
				float temp_output_94_0_g1065 = sqrt( ( 1.0 - ( temp_output_1_0_g1075 * temp_output_1_0_g1075 ) ) );
				float3 PullDelta91_g1065 = ( ( ( temp_output_35_0_g1065 * v.ase_texcoord3.x ) + ( temp_output_35_1_g1065 * v.ase_texcoord3.y ) + ( temp_output_35_2_g1065 * v.ase_texcoord3.z ) ) * _PenetratorBlendshapeMultiplier );
				float dotResult32_g1065 = dot( temp_output_27_0_g1065 , DickForward18_g1065 );
				float temp_output_1_0_g1082 = saturate( ( abs( ( dotResult32_g1065 - ( DickLength19_g1065 * _PenetratorCumProgress ) ) ) / ( DickLength19_g1065 * BulgePercentage37_g1065 ) ) );
				float3 CumDelta90_g1065 = ( ( ( temp_output_35_0_g1065 * v.texcoord1.w ) + ( temp_output_35_1_g1065 * v.texcoord2.w ) + ( temp_output_35_2_g1065 * v.ase_texcoord3.w ) ) * _PenetratorBlendshapeMultiplier );
				float3 lerpResult410_g1065 = lerp( ( VertexPosition254_g1065 + ( SquishDelta85_g1065 * temp_output_94_0_g1065 * saturate( -_PenetratorSquishPullAmount ) ) + ( temp_output_94_0_g1065 * PullDelta91_g1065 * saturate( _PenetratorSquishPullAmount ) ) + ( sqrt( ( 1.0 - ( temp_output_1_0_g1082 * temp_output_1_0_g1082 ) ) ) * CumDelta90_g1065 * _PenetratorCumActive ) ) , VertexPosition254_g1065 , _NoBlendshapes);
				float3 originalPosition126_g1065 = lerpResult410_g1065;
				float dotResult118_g1065 = dot( ( lerpResult410_g1065 - DickOrigin16_g1065 ) , DickForward18_g1065 );
				float PenetrationDepth39_g1065 = _PenetrationDepth;
				float temp_output_65_0_g1065 = ( PenetrationDepth39_g1065 * DickLength19_g1065 );
				float OrifaceLength34_g1065 = _OrificeLength;
				float temp_output_73_0_g1065 = ( _PinchBuffer * OrifaceLength34_g1065 );
				float dotResult80_g1065 = dot( ( lerpResult410_g1065 - DickOrigin16_g1065 ) , DickForward18_g1065 );
				float temp_output_112_0_g1065 = ( -( ( ( temp_output_65_0_g1065 - temp_output_73_0_g1065 ) + dotResult80_g1065 ) - DickLength19_g1065 ) * 10.0 );
				float ClipDick413_g1065 = _ClipDick;
				float lerpResult411_g1065 = lerp( max( temp_output_112_0_g1065 , ( ( ( temp_output_65_0_g1065 + dotResult80_g1065 + temp_output_73_0_g1065 ) - ( OrifaceLength34_g1065 + DickLength19_g1065 ) ) * 10.0 ) ) , temp_output_112_0_g1065 , ClipDick413_g1065);
				float InsideLerp123_g1065 = saturate( lerpResult411_g1065 );
				float3 lerpResult124_g1065 = lerp( ( ( DickForward18_g1065 * dotResult118_g1065 ) + DickOrigin16_g1065 ) , originalPosition126_g1065 , InsideLerp123_g1065);
				float InvisibleWhenInside420_g1065 = _InvisibleWhenInside;
				float3 lerpResult422_g1065 = lerp( originalPosition126_g1065 , lerpResult124_g1065 , InvisibleWhenInside420_g1065);
				float3 temp_output_354_0_g1065 = ( lerpResult422_g1065 - DickOrigin16_g1065 );
				float dotResult373_g1065 = dot( DickUp172_g1065 , temp_output_354_0_g1065 );
				float3 DickRight184_g1065 = _PenetratorRight;
				float dotResult374_g1065 = dot( DickRight184_g1065 , temp_output_354_0_g1065 );
				float dotResult375_g1065 = dot( temp_output_354_0_g1065 , DickForward18_g1065 );
				float3 lerpResult343_g1065 = lerp( ( ( ( saturate( ( ( VisibleLength25_g1065 - distance( DickOrigin16_g1065 , OrifacePosition170_g1065 ) ) / DickLength19_g1065 ) ) + 1.0 ) * dotResult373_g1065 * DickUp172_g1065 ) + ( ( saturate( ( ( VisibleLength25_g1065 - distance( DickOrigin16_g1065 , OrifacePosition170_g1065 ) ) / DickLength19_g1065 ) ) + 1.0 ) * dotResult374_g1065 * DickRight184_g1065 ) + ( DickForward18_g1065 * dotResult375_g1065 ) + DickOrigin16_g1065 ) , lerpResult422_g1065 , saturate( PenetrationDepth39_g1065 ));
				float dotResult177_g1065 = dot( ( lerpResult343_g1065 - DickOrigin16_g1065 ) , DickForward18_g1065 );
				float temp_output_178_0_g1065 = max( VisibleLength25_g1065 , 0.05 );
				float temp_output_42_0_g1076 = ( dotResult177_g1065 / temp_output_178_0_g1065 );
				float temp_output_26_0_g1077 = temp_output_42_0_g1076;
				float temp_output_19_0_g1077 = ( 1.0 - temp_output_26_0_g1077 );
				float3 temp_output_8_0_g1076 = DickOrigin16_g1065;
				float temp_output_393_0_g1065 = distance( DickOrigin16_g1065 , OrifacePosition170_g1065 );
				float temp_output_396_0_g1065 = min( temp_output_178_0_g1065 , temp_output_393_0_g1065 );
				float3 temp_output_9_0_g1076 = ( DickOrigin16_g1065 + ( DickForward18_g1065 * temp_output_396_0_g1065 * 0.25 ) );
				float4 appendResult130_g1065 = (float4(_OrificeWorldNormal , 0.0));
				float4 transform135_g1065 = mul(GetWorldToObjectMatrix(),appendResult130_g1065);
				float3 OrifaceNormal155_g1065 = (transform135_g1065).xyz;
				float3 temp_output_10_0_g1076 = ( OrifacePosition170_g1065 + ( OrifaceNormal155_g1065 * 0.25 * temp_output_396_0_g1065 ) );
				float3 temp_output_11_0_g1076 = OrifacePosition170_g1065;
				float temp_output_1_0_g1079 = temp_output_42_0_g1076;
				float temp_output_8_0_g1079 = ( 1.0 - temp_output_1_0_g1079 );
				float3 temp_output_3_0_g1079 = temp_output_9_0_g1076;
				float3 temp_output_4_0_g1079 = temp_output_10_0_g1076;
				float3 temp_output_7_0_g1078 = ( ( 3.0 * temp_output_8_0_g1079 * temp_output_8_0_g1079 * ( temp_output_3_0_g1079 - temp_output_8_0_g1076 ) ) + ( 6.0 * temp_output_8_0_g1079 * temp_output_1_0_g1079 * ( temp_output_4_0_g1079 - temp_output_3_0_g1079 ) ) + ( 3.0 * temp_output_1_0_g1079 * temp_output_1_0_g1079 * ( temp_output_11_0_g1076 - temp_output_4_0_g1079 ) ) );
				float3 normalizeResult27_g1080 = normalize( temp_output_7_0_g1078 );
				float3 temp_output_4_0_g1076 = DickUp172_g1065;
				float3 temp_output_10_0_g1078 = temp_output_4_0_g1076;
				float3 temp_output_3_0_g1076 = DickForward18_g1065;
				float3 temp_output_13_0_g1078 = temp_output_3_0_g1076;
				float dotResult33_g1078 = dot( temp_output_7_0_g1078 , temp_output_10_0_g1078 );
				float3 lerpResult34_g1078 = lerp( temp_output_10_0_g1078 , -temp_output_13_0_g1078 , saturate( dotResult33_g1078 ));
				float dotResult37_g1078 = dot( temp_output_7_0_g1078 , -temp_output_10_0_g1078 );
				float3 lerpResult40_g1078 = lerp( lerpResult34_g1078 , temp_output_13_0_g1078 , saturate( dotResult37_g1078 ));
				float3 normalizeResult42_g1078 = normalize( lerpResult40_g1078 );
				float3 normalizeResult31_g1080 = normalize( normalizeResult42_g1078 );
				float3 normalizeResult29_g1080 = normalize( cross( normalizeResult27_g1080 , normalizeResult31_g1080 ) );
				float3 temp_output_65_22_g1076 = normalizeResult29_g1080;
				float3 temp_output_2_0_g1076 = ( lerpResult343_g1065 - DickOrigin16_g1065 );
				float3 temp_output_5_0_g1076 = DickRight184_g1065;
				float dotResult15_g1076 = dot( temp_output_2_0_g1076 , temp_output_5_0_g1076 );
				float3 temp_output_65_0_g1076 = cross( normalizeResult29_g1080 , normalizeResult27_g1080 );
				float dotResult18_g1076 = dot( temp_output_2_0_g1076 , temp_output_4_0_g1076 );
				float dotResult142_g1065 = dot( ( lerpResult343_g1065 - DickOrigin16_g1065 ) , DickForward18_g1065 );
				float temp_output_152_0_g1065 = ( dotResult142_g1065 - VisibleLength25_g1065 );
				float temp_output_157_0_g1065 = ( temp_output_152_0_g1065 / OrifaceLength34_g1065 );
				float lerpResult416_g1065 = lerp( temp_output_157_0_g1065 , min( temp_output_157_0_g1065 , 1.0 ) , ClipDick413_g1065);
				float temp_output_42_0_g1066 = lerpResult416_g1065;
				float temp_output_26_0_g1067 = temp_output_42_0_g1066;
				float temp_output_19_0_g1067 = ( 1.0 - temp_output_26_0_g1067 );
				float3 temp_output_8_0_g1066 = OrifacePosition170_g1065;
				float4 appendResult145_g1065 = (float4(_OrificeOutWorldPosition1 , 1.0));
				float4 transform151_g1065 = mul(GetWorldToObjectMatrix(),appendResult145_g1065);
				float3 OrifaceOutPosition1183_g1065 = (transform151_g1065).xyz;
				float3 temp_output_9_0_g1066 = OrifaceOutPosition1183_g1065;
				float4 appendResult144_g1065 = (float4(_OrificeOutWorldPosition2 , 1.0));
				float4 transform154_g1065 = mul(GetWorldToObjectMatrix(),appendResult144_g1065);
				float3 OrifaceOutPosition2182_g1065 = (transform154_g1065).xyz;
				float3 temp_output_10_0_g1066 = OrifaceOutPosition2182_g1065;
				float4 appendResult143_g1065 = (float4(_OrificeOutWorldPosition3 , 1.0));
				float4 transform147_g1065 = mul(GetWorldToObjectMatrix(),appendResult143_g1065);
				float3 OrifaceOutPosition3175_g1065 = (transform147_g1065).xyz;
				float3 temp_output_11_0_g1066 = OrifaceOutPosition3175_g1065;
				float temp_output_1_0_g1069 = temp_output_42_0_g1066;
				float temp_output_8_0_g1069 = ( 1.0 - temp_output_1_0_g1069 );
				float3 temp_output_3_0_g1069 = temp_output_9_0_g1066;
				float3 temp_output_4_0_g1069 = temp_output_10_0_g1066;
				float3 temp_output_7_0_g1068 = ( ( 3.0 * temp_output_8_0_g1069 * temp_output_8_0_g1069 * ( temp_output_3_0_g1069 - temp_output_8_0_g1066 ) ) + ( 6.0 * temp_output_8_0_g1069 * temp_output_1_0_g1069 * ( temp_output_4_0_g1069 - temp_output_3_0_g1069 ) ) + ( 3.0 * temp_output_1_0_g1069 * temp_output_1_0_g1069 * ( temp_output_11_0_g1066 - temp_output_4_0_g1069 ) ) );
				float3 normalizeResult27_g1070 = normalize( temp_output_7_0_g1068 );
				float3 temp_output_4_0_g1066 = DickUp172_g1065;
				float3 temp_output_10_0_g1068 = temp_output_4_0_g1066;
				float3 temp_output_3_0_g1066 = DickForward18_g1065;
				float3 temp_output_13_0_g1068 = temp_output_3_0_g1066;
				float dotResult33_g1068 = dot( temp_output_7_0_g1068 , temp_output_10_0_g1068 );
				float3 lerpResult34_g1068 = lerp( temp_output_10_0_g1068 , -temp_output_13_0_g1068 , saturate( dotResult33_g1068 ));
				float dotResult37_g1068 = dot( temp_output_7_0_g1068 , -temp_output_10_0_g1068 );
				float3 lerpResult40_g1068 = lerp( lerpResult34_g1068 , temp_output_13_0_g1068 , saturate( dotResult37_g1068 ));
				float3 normalizeResult42_g1068 = normalize( lerpResult40_g1068 );
				float3 normalizeResult31_g1070 = normalize( normalizeResult42_g1068 );
				float3 normalizeResult29_g1070 = normalize( cross( normalizeResult27_g1070 , normalizeResult31_g1070 ) );
				float3 temp_output_65_22_g1066 = normalizeResult29_g1070;
				float3 temp_output_2_0_g1066 = ( lerpResult343_g1065 - DickOrigin16_g1065 );
				float3 temp_output_5_0_g1066 = DickRight184_g1065;
				float dotResult15_g1066 = dot( temp_output_2_0_g1066 , temp_output_5_0_g1066 );
				float3 temp_output_65_0_g1066 = cross( normalizeResult29_g1070 , normalizeResult27_g1070 );
				float dotResult18_g1066 = dot( temp_output_2_0_g1066 , temp_output_4_0_g1066 );
				float temp_output_208_0_g1065 = saturate( sign( temp_output_152_0_g1065 ) );
				float3 lerpResult221_g1065 = lerp( ( ( ( temp_output_19_0_g1077 * temp_output_19_0_g1077 * temp_output_19_0_g1077 * temp_output_8_0_g1076 ) + ( temp_output_19_0_g1077 * temp_output_19_0_g1077 * 3.0 * temp_output_26_0_g1077 * temp_output_9_0_g1076 ) + ( 3.0 * temp_output_19_0_g1077 * temp_output_26_0_g1077 * temp_output_26_0_g1077 * temp_output_10_0_g1076 ) + ( temp_output_26_0_g1077 * temp_output_26_0_g1077 * temp_output_26_0_g1077 * temp_output_11_0_g1076 ) ) + ( temp_output_65_22_g1076 * dotResult15_g1076 ) + ( temp_output_65_0_g1076 * dotResult18_g1076 ) ) , ( ( ( temp_output_19_0_g1067 * temp_output_19_0_g1067 * temp_output_19_0_g1067 * temp_output_8_0_g1066 ) + ( temp_output_19_0_g1067 * temp_output_19_0_g1067 * 3.0 * temp_output_26_0_g1067 * temp_output_9_0_g1066 ) + ( 3.0 * temp_output_19_0_g1067 * temp_output_26_0_g1067 * temp_output_26_0_g1067 * temp_output_10_0_g1066 ) + ( temp_output_26_0_g1067 * temp_output_26_0_g1067 * temp_output_26_0_g1067 * temp_output_11_0_g1066 ) ) + ( temp_output_65_22_g1066 * dotResult15_g1066 ) + ( temp_output_65_0_g1066 * dotResult18_g1066 ) ) , temp_output_208_0_g1065);
				float3 temp_output_42_0_g1071 = DickForward18_g1065;
				float NonVisibleLength165_g1065 = ( temp_output_11_0_g1065 * _PenetratorLength );
				float3 temp_output_52_0_g1071 = ( ( temp_output_42_0_g1071 * ( ( NonVisibleLength165_g1065 - OrifaceLength34_g1065 ) - DickLength19_g1065 ) ) + ( lerpResult343_g1065 - DickOrigin16_g1065 ) );
				float dotResult53_g1071 = dot( temp_output_42_0_g1071 , temp_output_52_0_g1071 );
				float temp_output_1_0_g1073 = 1.0;
				float temp_output_8_0_g1073 = ( 1.0 - temp_output_1_0_g1073 );
				float3 temp_output_3_0_g1073 = OrifaceOutPosition1183_g1065;
				float3 temp_output_4_0_g1073 = OrifaceOutPosition2182_g1065;
				float3 temp_output_7_0_g1072 = ( ( 3.0 * temp_output_8_0_g1073 * temp_output_8_0_g1073 * ( temp_output_3_0_g1073 - OrifacePosition170_g1065 ) ) + ( 6.0 * temp_output_8_0_g1073 * temp_output_1_0_g1073 * ( temp_output_4_0_g1073 - temp_output_3_0_g1073 ) ) + ( 3.0 * temp_output_1_0_g1073 * temp_output_1_0_g1073 * ( OrifaceOutPosition3175_g1065 - temp_output_4_0_g1073 ) ) );
				float3 normalizeResult27_g1074 = normalize( temp_output_7_0_g1072 );
				float3 temp_output_85_23_g1071 = normalizeResult27_g1074;
				float3 temp_output_4_0_g1071 = DickUp172_g1065;
				float dotResult54_g1071 = dot( temp_output_4_0_g1071 , temp_output_52_0_g1071 );
				float3 temp_output_10_0_g1072 = temp_output_4_0_g1071;
				float3 temp_output_13_0_g1072 = temp_output_42_0_g1071;
				float dotResult33_g1072 = dot( temp_output_7_0_g1072 , temp_output_10_0_g1072 );
				float3 lerpResult34_g1072 = lerp( temp_output_10_0_g1072 , -temp_output_13_0_g1072 , saturate( dotResult33_g1072 ));
				float dotResult37_g1072 = dot( temp_output_7_0_g1072 , -temp_output_10_0_g1072 );
				float3 lerpResult40_g1072 = lerp( lerpResult34_g1072 , temp_output_13_0_g1072 , saturate( dotResult37_g1072 ));
				float3 normalizeResult42_g1072 = normalize( lerpResult40_g1072 );
				float3 normalizeResult31_g1074 = normalize( normalizeResult42_g1072 );
				float3 normalizeResult29_g1074 = normalize( cross( normalizeResult27_g1074 , normalizeResult31_g1074 ) );
				float3 temp_output_85_0_g1071 = cross( normalizeResult29_g1074 , normalizeResult27_g1074 );
				float3 temp_output_43_0_g1071 = DickRight184_g1065;
				float dotResult55_g1071 = dot( temp_output_43_0_g1071 , temp_output_52_0_g1071 );
				float3 temp_output_85_22_g1071 = normalizeResult29_g1074;
				float temp_output_222_0_g1065 = saturate( sign( ( temp_output_157_0_g1065 - 1.0 ) ) );
				float3 lerpResult224_g1065 = lerp( lerpResult221_g1065 , ( ( ( dotResult53_g1071 * temp_output_85_23_g1071 ) + ( dotResult54_g1071 * temp_output_85_0_g1071 ) + ( dotResult55_g1071 * temp_output_85_22_g1071 ) ) + OrifaceOutPosition3175_g1065 ) , temp_output_222_0_g1065);
				float3 lerpResult418_g1065 = lerp( lerpResult224_g1065 , lerpResult221_g1065 , ClipDick413_g1065);
				float temp_output_226_0_g1065 = saturate( -PenetrationDepth39_g1065 );
				float3 lerpResult232_g1065 = lerp( lerpResult418_g1065 , originalPosition126_g1065 , temp_output_226_0_g1065);
				float3 ifLocalVar237_g1065 = 0;
				if( temp_output_234_0_g1065 <= 0.0 )
				ifLocalVar237_g1065 = originalPosition126_g1065;
				else
				ifLocalVar237_g1065 = lerpResult232_g1065;
				float DeformBalls426_g1065 = _DeformBalls;
				float3 lerpResult428_g1065 = lerp( ifLocalVar237_g1065 , lerpResult232_g1065 , DeformBalls426_g1065);
				
				float3 temp_output_21_0_g1076 = VertexNormal259_g1065;
				float dotResult55_g1076 = dot( temp_output_21_0_g1076 , temp_output_3_0_g1076 );
				float dotResult56_g1076 = dot( temp_output_21_0_g1076 , temp_output_4_0_g1076 );
				float dotResult57_g1076 = dot( temp_output_21_0_g1076 , temp_output_5_0_g1076 );
				float3 normalizeResult31_g1076 = normalize( ( ( dotResult55_g1076 * normalizeResult27_g1080 ) + ( dotResult56_g1076 * temp_output_65_0_g1076 ) + ( dotResult57_g1076 * temp_output_65_22_g1076 ) ) );
				float3 temp_output_21_0_g1066 = VertexNormal259_g1065;
				float dotResult55_g1066 = dot( temp_output_21_0_g1066 , temp_output_3_0_g1066 );
				float dotResult56_g1066 = dot( temp_output_21_0_g1066 , temp_output_4_0_g1066 );
				float dotResult57_g1066 = dot( temp_output_21_0_g1066 , temp_output_5_0_g1066 );
				float3 normalizeResult31_g1066 = normalize( ( ( dotResult55_g1066 * normalizeResult27_g1070 ) + ( dotResult56_g1066 * temp_output_65_0_g1066 ) + ( dotResult57_g1066 * temp_output_65_22_g1066 ) ) );
				float3 lerpResult227_g1065 = lerp( normalizeResult31_g1076 , normalizeResult31_g1066 , temp_output_208_0_g1065);
				float3 temp_output_24_0_g1071 = VertexNormal259_g1065;
				float dotResult61_g1071 = dot( temp_output_42_0_g1071 , temp_output_24_0_g1071 );
				float dotResult62_g1071 = dot( temp_output_4_0_g1071 , temp_output_24_0_g1071 );
				float dotResult60_g1071 = dot( temp_output_43_0_g1071 , temp_output_24_0_g1071 );
				float3 normalizeResult33_g1071 = normalize( ( ( dotResult61_g1071 * temp_output_85_23_g1071 ) + ( dotResult62_g1071 * temp_output_85_0_g1071 ) + ( dotResult60_g1071 * temp_output_85_22_g1071 ) ) );
				float3 lerpResult233_g1065 = lerp( lerpResult227_g1065 , normalizeResult33_g1071 , temp_output_222_0_g1065);
				float3 lerpResult419_g1065 = lerp( lerpResult233_g1065 , lerpResult227_g1065 , ClipDick413_g1065);
				float3 lerpResult238_g1065 = lerp( lerpResult419_g1065 , VertexNormal259_g1065 , temp_output_226_0_g1065);
				float3 ifLocalVar391_g1065 = 0;
				if( temp_output_234_0_g1065 <= 0.0 )
				ifLocalVar391_g1065 = VertexNormal259_g1065;
				else
				ifLocalVar391_g1065 = lerpResult238_g1065;
				
				float lerpResult424_g1065 = lerp( 1.0 , InsideLerp123_g1065 , InvisibleWhenInside420_g1065);
				float vertexToFrag250_g1065 = lerpResult424_g1065;
				o.ase_texcoord2.z = vertexToFrag250_g1065;
				
				o.ase_texcoord2.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord2.w = 0;
				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = lerpResult428_g1065;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = ifLocalVar391_g1065;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
				#endif

				o.clipPos = MetaVertexPosition( v.vertex, v.texcoord1.xy, v.texcoord1.xy, unity_LightmapST, unity_DynamicLightmapST );
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = o.clipPos;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				return o;
			}

			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_tangent : TANGENT;
				float4 ase_color : COLOR;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.texcoord1 = v.texcoord1;
				o.texcoord2 = v.texcoord2;
				o.ase_tangent = v.ase_tangent;
				o.ase_color = v.ase_color;
				o.ase_texcoord3 = v.ase_texcoord3;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				o.ase_texcoord3 = patch[0].ase_texcoord3 * bary.x + patch[1].ase_texcoord3 * bary.y + patch[2].ase_texcoord3 * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.worldPos;
				#endif
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float2 uv_BaseColorMap = IN.ase_texcoord2.xy * _BaseColorMap_ST.xy + _BaseColorMap_ST.zw;
				
				float2 uv_EmissionMap = IN.ase_texcoord2.xy * _EmissionMap_ST.xy + _EmissionMap_ST.zw;
				
				float vertexToFrag250_g1065 = IN.ase_texcoord2.z;
				
				
				float3 Albedo = tex2D( _BaseColorMap, uv_BaseColorMap ).rgb;
				float3 Emission = ( tex2D( _EmissionMap, uv_EmissionMap ) * _EmissionColor ).rgb;
				float Alpha = vertexToFrag250_g1065;
				float AlphaClipThreshold = 0.5;

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				MetaInput metaInput = (MetaInput)0;
				metaInput.Albedo = Albedo;
				metaInput.Emission = Emission;
				
				return MetaFragment(metaInput);
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "Universal2D"
			Tags { "LightMode"="Universal2D" }

			Blend One Zero, One Zero
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA

			HLSLPROGRAM
			
			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_instancing
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define ASE_ABSOLUTE_VERTEX_POS 1
			#define _EMISSION
			#define _ALPHATEST_ON 1
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 100600

			
			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS_2D

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			
			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_VERT_POSITION


			#pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_tangent : TANGENT;
				float4 ase_color : COLOR;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				float4 ase_texcoord2 : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _MetallicSmoothness_ST;
			float4 _EmissionMap_ST;
			float4 _NormalMap_ST;
			float4 _BaseColorMap_ST;
			float4 _EmissionColor;
			float3 _PenetratorOrigin;
			float3 _OrificeWorldPosition;
			float3 _PenetratorUp;
			float3 _PenetratorForward;
			float3 _OrificeOutWorldPosition3;
			float3 _OrificeOutWorldPosition2;
			float3 _OrificeOutWorldPosition1;
			float3 _OrificeWorldNormal;
			float3 _PenetratorRight;
			float _DeformBalls;
			float _InvisibleWhenInside;
			float _PinchBuffer;
			float _OrificeLength;
			float _NoBlendshapes;
			float _PenetratorCumActive;
			float _PenetratorCumProgress;
			float _PenetratorSquishPullAmount;
			float _PenetratorBulgePercentage;
			float _BulgeDistance;
			float _PenetrationDepth;
			float _PenetratorLength;
			float _ClipDick;
			float _PenetratorBlendshapeMultiplier;
			#ifdef _TRANSMISSION_ASE
				float _TransmissionShadow;
			#endif
			#ifdef _TRANSLUCENCY_ASE
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			float4 _JiggleInfos[16];
			sampler2D _Foam;
			sampler2D _BaseColorMap;


			float3 GetSoftbodyOffset3_g1064( float blend, float3 vertexPosition )
			{
				float3 vertexOffset = float3(0,0,0);
				for(int i=0;i<8;i++) {
				    float4 targetPosePositionRadius = _JiggleInfos[i*2];
				    float4 verletPositionBlend = _JiggleInfos[i*2+1];
				    float3 movement = (verletPositionBlend.xyz - targetPosePositionRadius.xyz);
				    float dist = distance(vertexPosition, targetPosePositionRadius.xyz);
				    float multi = 1-smoothstep(0,targetPosePositionRadius.w,dist);
				    vertexOffset += movement * multi * verletPositionBlend.w * blend;
				}
				return vertexOffset;
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				float3 VertexNormal259_g1065 = v.ase_normal;
				float3 normalizeResult27_g1081 = normalize( VertexNormal259_g1065 );
				float3 temp_output_35_0_g1065 = normalizeResult27_g1081;
				float3 normalizeResult31_g1081 = normalize( v.ase_tangent.xyz );
				float3 normalizeResult29_g1081 = normalize( cross( normalizeResult27_g1081 , normalizeResult31_g1081 ) );
				float3 temp_output_35_1_g1065 = cross( normalizeResult29_g1081 , normalizeResult27_g1081 );
				float3 temp_output_35_2_g1065 = normalizeResult29_g1081;
				float3 SquishDelta85_g1065 = ( ( ( temp_output_35_0_g1065 * v.ase_texcoord2.x ) + ( temp_output_35_1_g1065 * v.ase_texcoord2.y ) + ( temp_output_35_2_g1065 * v.ase_texcoord2.z ) ) * _PenetratorBlendshapeMultiplier );
				float temp_output_234_0_g1065 = length( SquishDelta85_g1065 );
				float temp_output_11_0_g1065 = max( _PenetrationDepth , 0.0 );
				float VisibleLength25_g1065 = ( _PenetratorLength * ( 1.0 - temp_output_11_0_g1065 ) );
				float3 DickOrigin16_g1065 = _PenetratorOrigin;
				float4 appendResult132_g1065 = (float4(_OrificeWorldPosition , 1.0));
				float4 transform140_g1065 = mul(GetWorldToObjectMatrix(),appendResult132_g1065);
				float3 OrifacePosition170_g1065 = (transform140_g1065).xyz;
				float DickLength19_g1065 = _PenetratorLength;
				float3 DickUp172_g1065 = _PenetratorUp;
				float blend3_g1064 = v.ase_color.r;
				float2 texCoord10 = v.ase_texcoord1 * float2( 1,1 ) + float2( 0,0 );
				float mulTime12 = _TimeParameters.x * 0.01;
				float mulTime11 = _TimeParameters.x * 0.1;
				float2 appendResult15 = (float2(( texCoord10.x + mulTime12 ) , ( texCoord10.y + mulTime11 )));
				float4 tex2DNode16 = tex2Dlod( _Foam, float4( appendResult15, 0, 0.0) );
				float3 temp_output_20_0 = ( v.ase_normal * _BulgeDistance * tex2DNode16.r * v.ase_color.g );
				float3 vertexPosition3_g1064 = ( v.vertex.xyz + temp_output_20_0 );
				float3 localGetSoftbodyOffset3_g1064 = GetSoftbodyOffset3_g1064( blend3_g1064 , vertexPosition3_g1064 );
				float3 VertexPosition254_g1065 = ( localGetSoftbodyOffset3_g1064 + temp_output_20_0 + v.vertex.xyz );
				float3 temp_output_27_0_g1065 = ( VertexPosition254_g1065 - DickOrigin16_g1065 );
				float3 DickForward18_g1065 = _PenetratorForward;
				float dotResult42_g1065 = dot( temp_output_27_0_g1065 , DickForward18_g1065 );
				float BulgePercentage37_g1065 = _PenetratorBulgePercentage;
				float temp_output_1_0_g1075 = saturate( ( abs( ( dotResult42_g1065 - VisibleLength25_g1065 ) ) / ( DickLength19_g1065 * BulgePercentage37_g1065 ) ) );
				float temp_output_94_0_g1065 = sqrt( ( 1.0 - ( temp_output_1_0_g1075 * temp_output_1_0_g1075 ) ) );
				float3 PullDelta91_g1065 = ( ( ( temp_output_35_0_g1065 * v.ase_texcoord3.x ) + ( temp_output_35_1_g1065 * v.ase_texcoord3.y ) + ( temp_output_35_2_g1065 * v.ase_texcoord3.z ) ) * _PenetratorBlendshapeMultiplier );
				float dotResult32_g1065 = dot( temp_output_27_0_g1065 , DickForward18_g1065 );
				float temp_output_1_0_g1082 = saturate( ( abs( ( dotResult32_g1065 - ( DickLength19_g1065 * _PenetratorCumProgress ) ) ) / ( DickLength19_g1065 * BulgePercentage37_g1065 ) ) );
				float3 CumDelta90_g1065 = ( ( ( temp_output_35_0_g1065 * v.ase_texcoord1.w ) + ( temp_output_35_1_g1065 * v.ase_texcoord2.w ) + ( temp_output_35_2_g1065 * v.ase_texcoord3.w ) ) * _PenetratorBlendshapeMultiplier );
				float3 lerpResult410_g1065 = lerp( ( VertexPosition254_g1065 + ( SquishDelta85_g1065 * temp_output_94_0_g1065 * saturate( -_PenetratorSquishPullAmount ) ) + ( temp_output_94_0_g1065 * PullDelta91_g1065 * saturate( _PenetratorSquishPullAmount ) ) + ( sqrt( ( 1.0 - ( temp_output_1_0_g1082 * temp_output_1_0_g1082 ) ) ) * CumDelta90_g1065 * _PenetratorCumActive ) ) , VertexPosition254_g1065 , _NoBlendshapes);
				float3 originalPosition126_g1065 = lerpResult410_g1065;
				float dotResult118_g1065 = dot( ( lerpResult410_g1065 - DickOrigin16_g1065 ) , DickForward18_g1065 );
				float PenetrationDepth39_g1065 = _PenetrationDepth;
				float temp_output_65_0_g1065 = ( PenetrationDepth39_g1065 * DickLength19_g1065 );
				float OrifaceLength34_g1065 = _OrificeLength;
				float temp_output_73_0_g1065 = ( _PinchBuffer * OrifaceLength34_g1065 );
				float dotResult80_g1065 = dot( ( lerpResult410_g1065 - DickOrigin16_g1065 ) , DickForward18_g1065 );
				float temp_output_112_0_g1065 = ( -( ( ( temp_output_65_0_g1065 - temp_output_73_0_g1065 ) + dotResult80_g1065 ) - DickLength19_g1065 ) * 10.0 );
				float ClipDick413_g1065 = _ClipDick;
				float lerpResult411_g1065 = lerp( max( temp_output_112_0_g1065 , ( ( ( temp_output_65_0_g1065 + dotResult80_g1065 + temp_output_73_0_g1065 ) - ( OrifaceLength34_g1065 + DickLength19_g1065 ) ) * 10.0 ) ) , temp_output_112_0_g1065 , ClipDick413_g1065);
				float InsideLerp123_g1065 = saturate( lerpResult411_g1065 );
				float3 lerpResult124_g1065 = lerp( ( ( DickForward18_g1065 * dotResult118_g1065 ) + DickOrigin16_g1065 ) , originalPosition126_g1065 , InsideLerp123_g1065);
				float InvisibleWhenInside420_g1065 = _InvisibleWhenInside;
				float3 lerpResult422_g1065 = lerp( originalPosition126_g1065 , lerpResult124_g1065 , InvisibleWhenInside420_g1065);
				float3 temp_output_354_0_g1065 = ( lerpResult422_g1065 - DickOrigin16_g1065 );
				float dotResult373_g1065 = dot( DickUp172_g1065 , temp_output_354_0_g1065 );
				float3 DickRight184_g1065 = _PenetratorRight;
				float dotResult374_g1065 = dot( DickRight184_g1065 , temp_output_354_0_g1065 );
				float dotResult375_g1065 = dot( temp_output_354_0_g1065 , DickForward18_g1065 );
				float3 lerpResult343_g1065 = lerp( ( ( ( saturate( ( ( VisibleLength25_g1065 - distance( DickOrigin16_g1065 , OrifacePosition170_g1065 ) ) / DickLength19_g1065 ) ) + 1.0 ) * dotResult373_g1065 * DickUp172_g1065 ) + ( ( saturate( ( ( VisibleLength25_g1065 - distance( DickOrigin16_g1065 , OrifacePosition170_g1065 ) ) / DickLength19_g1065 ) ) + 1.0 ) * dotResult374_g1065 * DickRight184_g1065 ) + ( DickForward18_g1065 * dotResult375_g1065 ) + DickOrigin16_g1065 ) , lerpResult422_g1065 , saturate( PenetrationDepth39_g1065 ));
				float dotResult177_g1065 = dot( ( lerpResult343_g1065 - DickOrigin16_g1065 ) , DickForward18_g1065 );
				float temp_output_178_0_g1065 = max( VisibleLength25_g1065 , 0.05 );
				float temp_output_42_0_g1076 = ( dotResult177_g1065 / temp_output_178_0_g1065 );
				float temp_output_26_0_g1077 = temp_output_42_0_g1076;
				float temp_output_19_0_g1077 = ( 1.0 - temp_output_26_0_g1077 );
				float3 temp_output_8_0_g1076 = DickOrigin16_g1065;
				float temp_output_393_0_g1065 = distance( DickOrigin16_g1065 , OrifacePosition170_g1065 );
				float temp_output_396_0_g1065 = min( temp_output_178_0_g1065 , temp_output_393_0_g1065 );
				float3 temp_output_9_0_g1076 = ( DickOrigin16_g1065 + ( DickForward18_g1065 * temp_output_396_0_g1065 * 0.25 ) );
				float4 appendResult130_g1065 = (float4(_OrificeWorldNormal , 0.0));
				float4 transform135_g1065 = mul(GetWorldToObjectMatrix(),appendResult130_g1065);
				float3 OrifaceNormal155_g1065 = (transform135_g1065).xyz;
				float3 temp_output_10_0_g1076 = ( OrifacePosition170_g1065 + ( OrifaceNormal155_g1065 * 0.25 * temp_output_396_0_g1065 ) );
				float3 temp_output_11_0_g1076 = OrifacePosition170_g1065;
				float temp_output_1_0_g1079 = temp_output_42_0_g1076;
				float temp_output_8_0_g1079 = ( 1.0 - temp_output_1_0_g1079 );
				float3 temp_output_3_0_g1079 = temp_output_9_0_g1076;
				float3 temp_output_4_0_g1079 = temp_output_10_0_g1076;
				float3 temp_output_7_0_g1078 = ( ( 3.0 * temp_output_8_0_g1079 * temp_output_8_0_g1079 * ( temp_output_3_0_g1079 - temp_output_8_0_g1076 ) ) + ( 6.0 * temp_output_8_0_g1079 * temp_output_1_0_g1079 * ( temp_output_4_0_g1079 - temp_output_3_0_g1079 ) ) + ( 3.0 * temp_output_1_0_g1079 * temp_output_1_0_g1079 * ( temp_output_11_0_g1076 - temp_output_4_0_g1079 ) ) );
				float3 normalizeResult27_g1080 = normalize( temp_output_7_0_g1078 );
				float3 temp_output_4_0_g1076 = DickUp172_g1065;
				float3 temp_output_10_0_g1078 = temp_output_4_0_g1076;
				float3 temp_output_3_0_g1076 = DickForward18_g1065;
				float3 temp_output_13_0_g1078 = temp_output_3_0_g1076;
				float dotResult33_g1078 = dot( temp_output_7_0_g1078 , temp_output_10_0_g1078 );
				float3 lerpResult34_g1078 = lerp( temp_output_10_0_g1078 , -temp_output_13_0_g1078 , saturate( dotResult33_g1078 ));
				float dotResult37_g1078 = dot( temp_output_7_0_g1078 , -temp_output_10_0_g1078 );
				float3 lerpResult40_g1078 = lerp( lerpResult34_g1078 , temp_output_13_0_g1078 , saturate( dotResult37_g1078 ));
				float3 normalizeResult42_g1078 = normalize( lerpResult40_g1078 );
				float3 normalizeResult31_g1080 = normalize( normalizeResult42_g1078 );
				float3 normalizeResult29_g1080 = normalize( cross( normalizeResult27_g1080 , normalizeResult31_g1080 ) );
				float3 temp_output_65_22_g1076 = normalizeResult29_g1080;
				float3 temp_output_2_0_g1076 = ( lerpResult343_g1065 - DickOrigin16_g1065 );
				float3 temp_output_5_0_g1076 = DickRight184_g1065;
				float dotResult15_g1076 = dot( temp_output_2_0_g1076 , temp_output_5_0_g1076 );
				float3 temp_output_65_0_g1076 = cross( normalizeResult29_g1080 , normalizeResult27_g1080 );
				float dotResult18_g1076 = dot( temp_output_2_0_g1076 , temp_output_4_0_g1076 );
				float dotResult142_g1065 = dot( ( lerpResult343_g1065 - DickOrigin16_g1065 ) , DickForward18_g1065 );
				float temp_output_152_0_g1065 = ( dotResult142_g1065 - VisibleLength25_g1065 );
				float temp_output_157_0_g1065 = ( temp_output_152_0_g1065 / OrifaceLength34_g1065 );
				float lerpResult416_g1065 = lerp( temp_output_157_0_g1065 , min( temp_output_157_0_g1065 , 1.0 ) , ClipDick413_g1065);
				float temp_output_42_0_g1066 = lerpResult416_g1065;
				float temp_output_26_0_g1067 = temp_output_42_0_g1066;
				float temp_output_19_0_g1067 = ( 1.0 - temp_output_26_0_g1067 );
				float3 temp_output_8_0_g1066 = OrifacePosition170_g1065;
				float4 appendResult145_g1065 = (float4(_OrificeOutWorldPosition1 , 1.0));
				float4 transform151_g1065 = mul(GetWorldToObjectMatrix(),appendResult145_g1065);
				float3 OrifaceOutPosition1183_g1065 = (transform151_g1065).xyz;
				float3 temp_output_9_0_g1066 = OrifaceOutPosition1183_g1065;
				float4 appendResult144_g1065 = (float4(_OrificeOutWorldPosition2 , 1.0));
				float4 transform154_g1065 = mul(GetWorldToObjectMatrix(),appendResult144_g1065);
				float3 OrifaceOutPosition2182_g1065 = (transform154_g1065).xyz;
				float3 temp_output_10_0_g1066 = OrifaceOutPosition2182_g1065;
				float4 appendResult143_g1065 = (float4(_OrificeOutWorldPosition3 , 1.0));
				float4 transform147_g1065 = mul(GetWorldToObjectMatrix(),appendResult143_g1065);
				float3 OrifaceOutPosition3175_g1065 = (transform147_g1065).xyz;
				float3 temp_output_11_0_g1066 = OrifaceOutPosition3175_g1065;
				float temp_output_1_0_g1069 = temp_output_42_0_g1066;
				float temp_output_8_0_g1069 = ( 1.0 - temp_output_1_0_g1069 );
				float3 temp_output_3_0_g1069 = temp_output_9_0_g1066;
				float3 temp_output_4_0_g1069 = temp_output_10_0_g1066;
				float3 temp_output_7_0_g1068 = ( ( 3.0 * temp_output_8_0_g1069 * temp_output_8_0_g1069 * ( temp_output_3_0_g1069 - temp_output_8_0_g1066 ) ) + ( 6.0 * temp_output_8_0_g1069 * temp_output_1_0_g1069 * ( temp_output_4_0_g1069 - temp_output_3_0_g1069 ) ) + ( 3.0 * temp_output_1_0_g1069 * temp_output_1_0_g1069 * ( temp_output_11_0_g1066 - temp_output_4_0_g1069 ) ) );
				float3 normalizeResult27_g1070 = normalize( temp_output_7_0_g1068 );
				float3 temp_output_4_0_g1066 = DickUp172_g1065;
				float3 temp_output_10_0_g1068 = temp_output_4_0_g1066;
				float3 temp_output_3_0_g1066 = DickForward18_g1065;
				float3 temp_output_13_0_g1068 = temp_output_3_0_g1066;
				float dotResult33_g1068 = dot( temp_output_7_0_g1068 , temp_output_10_0_g1068 );
				float3 lerpResult34_g1068 = lerp( temp_output_10_0_g1068 , -temp_output_13_0_g1068 , saturate( dotResult33_g1068 ));
				float dotResult37_g1068 = dot( temp_output_7_0_g1068 , -temp_output_10_0_g1068 );
				float3 lerpResult40_g1068 = lerp( lerpResult34_g1068 , temp_output_13_0_g1068 , saturate( dotResult37_g1068 ));
				float3 normalizeResult42_g1068 = normalize( lerpResult40_g1068 );
				float3 normalizeResult31_g1070 = normalize( normalizeResult42_g1068 );
				float3 normalizeResult29_g1070 = normalize( cross( normalizeResult27_g1070 , normalizeResult31_g1070 ) );
				float3 temp_output_65_22_g1066 = normalizeResult29_g1070;
				float3 temp_output_2_0_g1066 = ( lerpResult343_g1065 - DickOrigin16_g1065 );
				float3 temp_output_5_0_g1066 = DickRight184_g1065;
				float dotResult15_g1066 = dot( temp_output_2_0_g1066 , temp_output_5_0_g1066 );
				float3 temp_output_65_0_g1066 = cross( normalizeResult29_g1070 , normalizeResult27_g1070 );
				float dotResult18_g1066 = dot( temp_output_2_0_g1066 , temp_output_4_0_g1066 );
				float temp_output_208_0_g1065 = saturate( sign( temp_output_152_0_g1065 ) );
				float3 lerpResult221_g1065 = lerp( ( ( ( temp_output_19_0_g1077 * temp_output_19_0_g1077 * temp_output_19_0_g1077 * temp_output_8_0_g1076 ) + ( temp_output_19_0_g1077 * temp_output_19_0_g1077 * 3.0 * temp_output_26_0_g1077 * temp_output_9_0_g1076 ) + ( 3.0 * temp_output_19_0_g1077 * temp_output_26_0_g1077 * temp_output_26_0_g1077 * temp_output_10_0_g1076 ) + ( temp_output_26_0_g1077 * temp_output_26_0_g1077 * temp_output_26_0_g1077 * temp_output_11_0_g1076 ) ) + ( temp_output_65_22_g1076 * dotResult15_g1076 ) + ( temp_output_65_0_g1076 * dotResult18_g1076 ) ) , ( ( ( temp_output_19_0_g1067 * temp_output_19_0_g1067 * temp_output_19_0_g1067 * temp_output_8_0_g1066 ) + ( temp_output_19_0_g1067 * temp_output_19_0_g1067 * 3.0 * temp_output_26_0_g1067 * temp_output_9_0_g1066 ) + ( 3.0 * temp_output_19_0_g1067 * temp_output_26_0_g1067 * temp_output_26_0_g1067 * temp_output_10_0_g1066 ) + ( temp_output_26_0_g1067 * temp_output_26_0_g1067 * temp_output_26_0_g1067 * temp_output_11_0_g1066 ) ) + ( temp_output_65_22_g1066 * dotResult15_g1066 ) + ( temp_output_65_0_g1066 * dotResult18_g1066 ) ) , temp_output_208_0_g1065);
				float3 temp_output_42_0_g1071 = DickForward18_g1065;
				float NonVisibleLength165_g1065 = ( temp_output_11_0_g1065 * _PenetratorLength );
				float3 temp_output_52_0_g1071 = ( ( temp_output_42_0_g1071 * ( ( NonVisibleLength165_g1065 - OrifaceLength34_g1065 ) - DickLength19_g1065 ) ) + ( lerpResult343_g1065 - DickOrigin16_g1065 ) );
				float dotResult53_g1071 = dot( temp_output_42_0_g1071 , temp_output_52_0_g1071 );
				float temp_output_1_0_g1073 = 1.0;
				float temp_output_8_0_g1073 = ( 1.0 - temp_output_1_0_g1073 );
				float3 temp_output_3_0_g1073 = OrifaceOutPosition1183_g1065;
				float3 temp_output_4_0_g1073 = OrifaceOutPosition2182_g1065;
				float3 temp_output_7_0_g1072 = ( ( 3.0 * temp_output_8_0_g1073 * temp_output_8_0_g1073 * ( temp_output_3_0_g1073 - OrifacePosition170_g1065 ) ) + ( 6.0 * temp_output_8_0_g1073 * temp_output_1_0_g1073 * ( temp_output_4_0_g1073 - temp_output_3_0_g1073 ) ) + ( 3.0 * temp_output_1_0_g1073 * temp_output_1_0_g1073 * ( OrifaceOutPosition3175_g1065 - temp_output_4_0_g1073 ) ) );
				float3 normalizeResult27_g1074 = normalize( temp_output_7_0_g1072 );
				float3 temp_output_85_23_g1071 = normalizeResult27_g1074;
				float3 temp_output_4_0_g1071 = DickUp172_g1065;
				float dotResult54_g1071 = dot( temp_output_4_0_g1071 , temp_output_52_0_g1071 );
				float3 temp_output_10_0_g1072 = temp_output_4_0_g1071;
				float3 temp_output_13_0_g1072 = temp_output_42_0_g1071;
				float dotResult33_g1072 = dot( temp_output_7_0_g1072 , temp_output_10_0_g1072 );
				float3 lerpResult34_g1072 = lerp( temp_output_10_0_g1072 , -temp_output_13_0_g1072 , saturate( dotResult33_g1072 ));
				float dotResult37_g1072 = dot( temp_output_7_0_g1072 , -temp_output_10_0_g1072 );
				float3 lerpResult40_g1072 = lerp( lerpResult34_g1072 , temp_output_13_0_g1072 , saturate( dotResult37_g1072 ));
				float3 normalizeResult42_g1072 = normalize( lerpResult40_g1072 );
				float3 normalizeResult31_g1074 = normalize( normalizeResult42_g1072 );
				float3 normalizeResult29_g1074 = normalize( cross( normalizeResult27_g1074 , normalizeResult31_g1074 ) );
				float3 temp_output_85_0_g1071 = cross( normalizeResult29_g1074 , normalizeResult27_g1074 );
				float3 temp_output_43_0_g1071 = DickRight184_g1065;
				float dotResult55_g1071 = dot( temp_output_43_0_g1071 , temp_output_52_0_g1071 );
				float3 temp_output_85_22_g1071 = normalizeResult29_g1074;
				float temp_output_222_0_g1065 = saturate( sign( ( temp_output_157_0_g1065 - 1.0 ) ) );
				float3 lerpResult224_g1065 = lerp( lerpResult221_g1065 , ( ( ( dotResult53_g1071 * temp_output_85_23_g1071 ) + ( dotResult54_g1071 * temp_output_85_0_g1071 ) + ( dotResult55_g1071 * temp_output_85_22_g1071 ) ) + OrifaceOutPosition3175_g1065 ) , temp_output_222_0_g1065);
				float3 lerpResult418_g1065 = lerp( lerpResult224_g1065 , lerpResult221_g1065 , ClipDick413_g1065);
				float temp_output_226_0_g1065 = saturate( -PenetrationDepth39_g1065 );
				float3 lerpResult232_g1065 = lerp( lerpResult418_g1065 , originalPosition126_g1065 , temp_output_226_0_g1065);
				float3 ifLocalVar237_g1065 = 0;
				if( temp_output_234_0_g1065 <= 0.0 )
				ifLocalVar237_g1065 = originalPosition126_g1065;
				else
				ifLocalVar237_g1065 = lerpResult232_g1065;
				float DeformBalls426_g1065 = _DeformBalls;
				float3 lerpResult428_g1065 = lerp( ifLocalVar237_g1065 , lerpResult232_g1065 , DeformBalls426_g1065);
				
				float3 temp_output_21_0_g1076 = VertexNormal259_g1065;
				float dotResult55_g1076 = dot( temp_output_21_0_g1076 , temp_output_3_0_g1076 );
				float dotResult56_g1076 = dot( temp_output_21_0_g1076 , temp_output_4_0_g1076 );
				float dotResult57_g1076 = dot( temp_output_21_0_g1076 , temp_output_5_0_g1076 );
				float3 normalizeResult31_g1076 = normalize( ( ( dotResult55_g1076 * normalizeResult27_g1080 ) + ( dotResult56_g1076 * temp_output_65_0_g1076 ) + ( dotResult57_g1076 * temp_output_65_22_g1076 ) ) );
				float3 temp_output_21_0_g1066 = VertexNormal259_g1065;
				float dotResult55_g1066 = dot( temp_output_21_0_g1066 , temp_output_3_0_g1066 );
				float dotResult56_g1066 = dot( temp_output_21_0_g1066 , temp_output_4_0_g1066 );
				float dotResult57_g1066 = dot( temp_output_21_0_g1066 , temp_output_5_0_g1066 );
				float3 normalizeResult31_g1066 = normalize( ( ( dotResult55_g1066 * normalizeResult27_g1070 ) + ( dotResult56_g1066 * temp_output_65_0_g1066 ) + ( dotResult57_g1066 * temp_output_65_22_g1066 ) ) );
				float3 lerpResult227_g1065 = lerp( normalizeResult31_g1076 , normalizeResult31_g1066 , temp_output_208_0_g1065);
				float3 temp_output_24_0_g1071 = VertexNormal259_g1065;
				float dotResult61_g1071 = dot( temp_output_42_0_g1071 , temp_output_24_0_g1071 );
				float dotResult62_g1071 = dot( temp_output_4_0_g1071 , temp_output_24_0_g1071 );
				float dotResult60_g1071 = dot( temp_output_43_0_g1071 , temp_output_24_0_g1071 );
				float3 normalizeResult33_g1071 = normalize( ( ( dotResult61_g1071 * temp_output_85_23_g1071 ) + ( dotResult62_g1071 * temp_output_85_0_g1071 ) + ( dotResult60_g1071 * temp_output_85_22_g1071 ) ) );
				float3 lerpResult233_g1065 = lerp( lerpResult227_g1065 , normalizeResult33_g1071 , temp_output_222_0_g1065);
				float3 lerpResult419_g1065 = lerp( lerpResult233_g1065 , lerpResult227_g1065 , ClipDick413_g1065);
				float3 lerpResult238_g1065 = lerp( lerpResult419_g1065 , VertexNormal259_g1065 , temp_output_226_0_g1065);
				float3 ifLocalVar391_g1065 = 0;
				if( temp_output_234_0_g1065 <= 0.0 )
				ifLocalVar391_g1065 = VertexNormal259_g1065;
				else
				ifLocalVar391_g1065 = lerpResult238_g1065;
				
				float lerpResult424_g1065 = lerp( 1.0 , InsideLerp123_g1065 , InvisibleWhenInside420_g1065);
				float vertexToFrag250_g1065 = lerpResult424_g1065;
				o.ase_texcoord2.z = vertexToFrag250_g1065;
				
				o.ase_texcoord2.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord2.w = 0;
				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = lerpResult428_g1065;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = ifLocalVar391_g1065;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				o.clipPos = positionCS;
				return o;
			}

			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_tangent : TANGENT;
				float4 ase_color : COLOR;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord2 = v.ase_texcoord2;
				o.ase_tangent = v.ase_tangent;
				o.ase_color = v.ase_color;
				o.ase_texcoord1 = v.ase_texcoord1;
				o.ase_texcoord3 = v.ase_texcoord3;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord2 = patch[0].ase_texcoord2 * bary.x + patch[1].ase_texcoord2 * bary.y + patch[2].ase_texcoord2 * bary.z;
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				o.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				o.ase_texcoord3 = patch[0].ase_texcoord3 * bary.x + patch[1].ase_texcoord3 * bary.y + patch[2].ase_texcoord3 * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.worldPos;
				#endif
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float2 uv_BaseColorMap = IN.ase_texcoord2.xy * _BaseColorMap_ST.xy + _BaseColorMap_ST.zw;
				
				float vertexToFrag250_g1065 = IN.ase_texcoord2.z;
				
				
				float3 Albedo = tex2D( _BaseColorMap, uv_BaseColorMap ).rgb;
				float Alpha = vertexToFrag250_g1065;
				float AlphaClipThreshold = 0.5;

				half4 color = half4( Albedo, Alpha );

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				return color;
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthNormals"
			Tags { "LightMode"="DepthNormals" }

			ZWrite On
			Blend One Zero
            ZTest LEqual
            ZWrite On

			HLSLPROGRAM
			
			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_instancing
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define ASE_ABSOLUTE_VERTEX_POS 1
			#define _EMISSION
			#define _ALPHATEST_ON 1
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 100600

			
			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS_DEPTHNORMALSONLY

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_VERT_POSITION


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_tangent : TANGENT;
				float4 ase_color : COLOR;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord3 : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				float3 worldNormal : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _MetallicSmoothness_ST;
			float4 _EmissionMap_ST;
			float4 _NormalMap_ST;
			float4 _BaseColorMap_ST;
			float4 _EmissionColor;
			float3 _PenetratorOrigin;
			float3 _OrificeWorldPosition;
			float3 _PenetratorUp;
			float3 _PenetratorForward;
			float3 _OrificeOutWorldPosition3;
			float3 _OrificeOutWorldPosition2;
			float3 _OrificeOutWorldPosition1;
			float3 _OrificeWorldNormal;
			float3 _PenetratorRight;
			float _DeformBalls;
			float _InvisibleWhenInside;
			float _PinchBuffer;
			float _OrificeLength;
			float _NoBlendshapes;
			float _PenetratorCumActive;
			float _PenetratorCumProgress;
			float _PenetratorSquishPullAmount;
			float _PenetratorBulgePercentage;
			float _BulgeDistance;
			float _PenetrationDepth;
			float _PenetratorLength;
			float _ClipDick;
			float _PenetratorBlendshapeMultiplier;
			#ifdef _TRANSMISSION_ASE
				float _TransmissionShadow;
			#endif
			#ifdef _TRANSLUCENCY_ASE
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			float4 _JiggleInfos[16];
			sampler2D _Foam;


			float3 GetSoftbodyOffset3_g1064( float blend, float3 vertexPosition )
			{
				float3 vertexOffset = float3(0,0,0);
				for(int i=0;i<8;i++) {
				    float4 targetPosePositionRadius = _JiggleInfos[i*2];
				    float4 verletPositionBlend = _JiggleInfos[i*2+1];
				    float3 movement = (verletPositionBlend.xyz - targetPosePositionRadius.xyz);
				    float dist = distance(vertexPosition, targetPosePositionRadius.xyz);
				    float multi = 1-smoothstep(0,targetPosePositionRadius.w,dist);
				    vertexOffset += movement * multi * verletPositionBlend.w * blend;
				}
				return vertexOffset;
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 VertexNormal259_g1065 = v.ase_normal;
				float3 normalizeResult27_g1081 = normalize( VertexNormal259_g1065 );
				float3 temp_output_35_0_g1065 = normalizeResult27_g1081;
				float3 normalizeResult31_g1081 = normalize( v.ase_tangent.xyz );
				float3 normalizeResult29_g1081 = normalize( cross( normalizeResult27_g1081 , normalizeResult31_g1081 ) );
				float3 temp_output_35_1_g1065 = cross( normalizeResult29_g1081 , normalizeResult27_g1081 );
				float3 temp_output_35_2_g1065 = normalizeResult29_g1081;
				float3 SquishDelta85_g1065 = ( ( ( temp_output_35_0_g1065 * v.ase_texcoord2.x ) + ( temp_output_35_1_g1065 * v.ase_texcoord2.y ) + ( temp_output_35_2_g1065 * v.ase_texcoord2.z ) ) * _PenetratorBlendshapeMultiplier );
				float temp_output_234_0_g1065 = length( SquishDelta85_g1065 );
				float temp_output_11_0_g1065 = max( _PenetrationDepth , 0.0 );
				float VisibleLength25_g1065 = ( _PenetratorLength * ( 1.0 - temp_output_11_0_g1065 ) );
				float3 DickOrigin16_g1065 = _PenetratorOrigin;
				float4 appendResult132_g1065 = (float4(_OrificeWorldPosition , 1.0));
				float4 transform140_g1065 = mul(GetWorldToObjectMatrix(),appendResult132_g1065);
				float3 OrifacePosition170_g1065 = (transform140_g1065).xyz;
				float DickLength19_g1065 = _PenetratorLength;
				float3 DickUp172_g1065 = _PenetratorUp;
				float blend3_g1064 = v.ase_color.r;
				float2 texCoord10 = v.ase_texcoord1 * float2( 1,1 ) + float2( 0,0 );
				float mulTime12 = _TimeParameters.x * 0.01;
				float mulTime11 = _TimeParameters.x * 0.1;
				float2 appendResult15 = (float2(( texCoord10.x + mulTime12 ) , ( texCoord10.y + mulTime11 )));
				float4 tex2DNode16 = tex2Dlod( _Foam, float4( appendResult15, 0, 0.0) );
				float3 temp_output_20_0 = ( v.ase_normal * _BulgeDistance * tex2DNode16.r * v.ase_color.g );
				float3 vertexPosition3_g1064 = ( v.vertex.xyz + temp_output_20_0 );
				float3 localGetSoftbodyOffset3_g1064 = GetSoftbodyOffset3_g1064( blend3_g1064 , vertexPosition3_g1064 );
				float3 VertexPosition254_g1065 = ( localGetSoftbodyOffset3_g1064 + temp_output_20_0 + v.vertex.xyz );
				float3 temp_output_27_0_g1065 = ( VertexPosition254_g1065 - DickOrigin16_g1065 );
				float3 DickForward18_g1065 = _PenetratorForward;
				float dotResult42_g1065 = dot( temp_output_27_0_g1065 , DickForward18_g1065 );
				float BulgePercentage37_g1065 = _PenetratorBulgePercentage;
				float temp_output_1_0_g1075 = saturate( ( abs( ( dotResult42_g1065 - VisibleLength25_g1065 ) ) / ( DickLength19_g1065 * BulgePercentage37_g1065 ) ) );
				float temp_output_94_0_g1065 = sqrt( ( 1.0 - ( temp_output_1_0_g1075 * temp_output_1_0_g1075 ) ) );
				float3 PullDelta91_g1065 = ( ( ( temp_output_35_0_g1065 * v.ase_texcoord3.x ) + ( temp_output_35_1_g1065 * v.ase_texcoord3.y ) + ( temp_output_35_2_g1065 * v.ase_texcoord3.z ) ) * _PenetratorBlendshapeMultiplier );
				float dotResult32_g1065 = dot( temp_output_27_0_g1065 , DickForward18_g1065 );
				float temp_output_1_0_g1082 = saturate( ( abs( ( dotResult32_g1065 - ( DickLength19_g1065 * _PenetratorCumProgress ) ) ) / ( DickLength19_g1065 * BulgePercentage37_g1065 ) ) );
				float3 CumDelta90_g1065 = ( ( ( temp_output_35_0_g1065 * v.ase_texcoord1.w ) + ( temp_output_35_1_g1065 * v.ase_texcoord2.w ) + ( temp_output_35_2_g1065 * v.ase_texcoord3.w ) ) * _PenetratorBlendshapeMultiplier );
				float3 lerpResult410_g1065 = lerp( ( VertexPosition254_g1065 + ( SquishDelta85_g1065 * temp_output_94_0_g1065 * saturate( -_PenetratorSquishPullAmount ) ) + ( temp_output_94_0_g1065 * PullDelta91_g1065 * saturate( _PenetratorSquishPullAmount ) ) + ( sqrt( ( 1.0 - ( temp_output_1_0_g1082 * temp_output_1_0_g1082 ) ) ) * CumDelta90_g1065 * _PenetratorCumActive ) ) , VertexPosition254_g1065 , _NoBlendshapes);
				float3 originalPosition126_g1065 = lerpResult410_g1065;
				float dotResult118_g1065 = dot( ( lerpResult410_g1065 - DickOrigin16_g1065 ) , DickForward18_g1065 );
				float PenetrationDepth39_g1065 = _PenetrationDepth;
				float temp_output_65_0_g1065 = ( PenetrationDepth39_g1065 * DickLength19_g1065 );
				float OrifaceLength34_g1065 = _OrificeLength;
				float temp_output_73_0_g1065 = ( _PinchBuffer * OrifaceLength34_g1065 );
				float dotResult80_g1065 = dot( ( lerpResult410_g1065 - DickOrigin16_g1065 ) , DickForward18_g1065 );
				float temp_output_112_0_g1065 = ( -( ( ( temp_output_65_0_g1065 - temp_output_73_0_g1065 ) + dotResult80_g1065 ) - DickLength19_g1065 ) * 10.0 );
				float ClipDick413_g1065 = _ClipDick;
				float lerpResult411_g1065 = lerp( max( temp_output_112_0_g1065 , ( ( ( temp_output_65_0_g1065 + dotResult80_g1065 + temp_output_73_0_g1065 ) - ( OrifaceLength34_g1065 + DickLength19_g1065 ) ) * 10.0 ) ) , temp_output_112_0_g1065 , ClipDick413_g1065);
				float InsideLerp123_g1065 = saturate( lerpResult411_g1065 );
				float3 lerpResult124_g1065 = lerp( ( ( DickForward18_g1065 * dotResult118_g1065 ) + DickOrigin16_g1065 ) , originalPosition126_g1065 , InsideLerp123_g1065);
				float InvisibleWhenInside420_g1065 = _InvisibleWhenInside;
				float3 lerpResult422_g1065 = lerp( originalPosition126_g1065 , lerpResult124_g1065 , InvisibleWhenInside420_g1065);
				float3 temp_output_354_0_g1065 = ( lerpResult422_g1065 - DickOrigin16_g1065 );
				float dotResult373_g1065 = dot( DickUp172_g1065 , temp_output_354_0_g1065 );
				float3 DickRight184_g1065 = _PenetratorRight;
				float dotResult374_g1065 = dot( DickRight184_g1065 , temp_output_354_0_g1065 );
				float dotResult375_g1065 = dot( temp_output_354_0_g1065 , DickForward18_g1065 );
				float3 lerpResult343_g1065 = lerp( ( ( ( saturate( ( ( VisibleLength25_g1065 - distance( DickOrigin16_g1065 , OrifacePosition170_g1065 ) ) / DickLength19_g1065 ) ) + 1.0 ) * dotResult373_g1065 * DickUp172_g1065 ) + ( ( saturate( ( ( VisibleLength25_g1065 - distance( DickOrigin16_g1065 , OrifacePosition170_g1065 ) ) / DickLength19_g1065 ) ) + 1.0 ) * dotResult374_g1065 * DickRight184_g1065 ) + ( DickForward18_g1065 * dotResult375_g1065 ) + DickOrigin16_g1065 ) , lerpResult422_g1065 , saturate( PenetrationDepth39_g1065 ));
				float dotResult177_g1065 = dot( ( lerpResult343_g1065 - DickOrigin16_g1065 ) , DickForward18_g1065 );
				float temp_output_178_0_g1065 = max( VisibleLength25_g1065 , 0.05 );
				float temp_output_42_0_g1076 = ( dotResult177_g1065 / temp_output_178_0_g1065 );
				float temp_output_26_0_g1077 = temp_output_42_0_g1076;
				float temp_output_19_0_g1077 = ( 1.0 - temp_output_26_0_g1077 );
				float3 temp_output_8_0_g1076 = DickOrigin16_g1065;
				float temp_output_393_0_g1065 = distance( DickOrigin16_g1065 , OrifacePosition170_g1065 );
				float temp_output_396_0_g1065 = min( temp_output_178_0_g1065 , temp_output_393_0_g1065 );
				float3 temp_output_9_0_g1076 = ( DickOrigin16_g1065 + ( DickForward18_g1065 * temp_output_396_0_g1065 * 0.25 ) );
				float4 appendResult130_g1065 = (float4(_OrificeWorldNormal , 0.0));
				float4 transform135_g1065 = mul(GetWorldToObjectMatrix(),appendResult130_g1065);
				float3 OrifaceNormal155_g1065 = (transform135_g1065).xyz;
				float3 temp_output_10_0_g1076 = ( OrifacePosition170_g1065 + ( OrifaceNormal155_g1065 * 0.25 * temp_output_396_0_g1065 ) );
				float3 temp_output_11_0_g1076 = OrifacePosition170_g1065;
				float temp_output_1_0_g1079 = temp_output_42_0_g1076;
				float temp_output_8_0_g1079 = ( 1.0 - temp_output_1_0_g1079 );
				float3 temp_output_3_0_g1079 = temp_output_9_0_g1076;
				float3 temp_output_4_0_g1079 = temp_output_10_0_g1076;
				float3 temp_output_7_0_g1078 = ( ( 3.0 * temp_output_8_0_g1079 * temp_output_8_0_g1079 * ( temp_output_3_0_g1079 - temp_output_8_0_g1076 ) ) + ( 6.0 * temp_output_8_0_g1079 * temp_output_1_0_g1079 * ( temp_output_4_0_g1079 - temp_output_3_0_g1079 ) ) + ( 3.0 * temp_output_1_0_g1079 * temp_output_1_0_g1079 * ( temp_output_11_0_g1076 - temp_output_4_0_g1079 ) ) );
				float3 normalizeResult27_g1080 = normalize( temp_output_7_0_g1078 );
				float3 temp_output_4_0_g1076 = DickUp172_g1065;
				float3 temp_output_10_0_g1078 = temp_output_4_0_g1076;
				float3 temp_output_3_0_g1076 = DickForward18_g1065;
				float3 temp_output_13_0_g1078 = temp_output_3_0_g1076;
				float dotResult33_g1078 = dot( temp_output_7_0_g1078 , temp_output_10_0_g1078 );
				float3 lerpResult34_g1078 = lerp( temp_output_10_0_g1078 , -temp_output_13_0_g1078 , saturate( dotResult33_g1078 ));
				float dotResult37_g1078 = dot( temp_output_7_0_g1078 , -temp_output_10_0_g1078 );
				float3 lerpResult40_g1078 = lerp( lerpResult34_g1078 , temp_output_13_0_g1078 , saturate( dotResult37_g1078 ));
				float3 normalizeResult42_g1078 = normalize( lerpResult40_g1078 );
				float3 normalizeResult31_g1080 = normalize( normalizeResult42_g1078 );
				float3 normalizeResult29_g1080 = normalize( cross( normalizeResult27_g1080 , normalizeResult31_g1080 ) );
				float3 temp_output_65_22_g1076 = normalizeResult29_g1080;
				float3 temp_output_2_0_g1076 = ( lerpResult343_g1065 - DickOrigin16_g1065 );
				float3 temp_output_5_0_g1076 = DickRight184_g1065;
				float dotResult15_g1076 = dot( temp_output_2_0_g1076 , temp_output_5_0_g1076 );
				float3 temp_output_65_0_g1076 = cross( normalizeResult29_g1080 , normalizeResult27_g1080 );
				float dotResult18_g1076 = dot( temp_output_2_0_g1076 , temp_output_4_0_g1076 );
				float dotResult142_g1065 = dot( ( lerpResult343_g1065 - DickOrigin16_g1065 ) , DickForward18_g1065 );
				float temp_output_152_0_g1065 = ( dotResult142_g1065 - VisibleLength25_g1065 );
				float temp_output_157_0_g1065 = ( temp_output_152_0_g1065 / OrifaceLength34_g1065 );
				float lerpResult416_g1065 = lerp( temp_output_157_0_g1065 , min( temp_output_157_0_g1065 , 1.0 ) , ClipDick413_g1065);
				float temp_output_42_0_g1066 = lerpResult416_g1065;
				float temp_output_26_0_g1067 = temp_output_42_0_g1066;
				float temp_output_19_0_g1067 = ( 1.0 - temp_output_26_0_g1067 );
				float3 temp_output_8_0_g1066 = OrifacePosition170_g1065;
				float4 appendResult145_g1065 = (float4(_OrificeOutWorldPosition1 , 1.0));
				float4 transform151_g1065 = mul(GetWorldToObjectMatrix(),appendResult145_g1065);
				float3 OrifaceOutPosition1183_g1065 = (transform151_g1065).xyz;
				float3 temp_output_9_0_g1066 = OrifaceOutPosition1183_g1065;
				float4 appendResult144_g1065 = (float4(_OrificeOutWorldPosition2 , 1.0));
				float4 transform154_g1065 = mul(GetWorldToObjectMatrix(),appendResult144_g1065);
				float3 OrifaceOutPosition2182_g1065 = (transform154_g1065).xyz;
				float3 temp_output_10_0_g1066 = OrifaceOutPosition2182_g1065;
				float4 appendResult143_g1065 = (float4(_OrificeOutWorldPosition3 , 1.0));
				float4 transform147_g1065 = mul(GetWorldToObjectMatrix(),appendResult143_g1065);
				float3 OrifaceOutPosition3175_g1065 = (transform147_g1065).xyz;
				float3 temp_output_11_0_g1066 = OrifaceOutPosition3175_g1065;
				float temp_output_1_0_g1069 = temp_output_42_0_g1066;
				float temp_output_8_0_g1069 = ( 1.0 - temp_output_1_0_g1069 );
				float3 temp_output_3_0_g1069 = temp_output_9_0_g1066;
				float3 temp_output_4_0_g1069 = temp_output_10_0_g1066;
				float3 temp_output_7_0_g1068 = ( ( 3.0 * temp_output_8_0_g1069 * temp_output_8_0_g1069 * ( temp_output_3_0_g1069 - temp_output_8_0_g1066 ) ) + ( 6.0 * temp_output_8_0_g1069 * temp_output_1_0_g1069 * ( temp_output_4_0_g1069 - temp_output_3_0_g1069 ) ) + ( 3.0 * temp_output_1_0_g1069 * temp_output_1_0_g1069 * ( temp_output_11_0_g1066 - temp_output_4_0_g1069 ) ) );
				float3 normalizeResult27_g1070 = normalize( temp_output_7_0_g1068 );
				float3 temp_output_4_0_g1066 = DickUp172_g1065;
				float3 temp_output_10_0_g1068 = temp_output_4_0_g1066;
				float3 temp_output_3_0_g1066 = DickForward18_g1065;
				float3 temp_output_13_0_g1068 = temp_output_3_0_g1066;
				float dotResult33_g1068 = dot( temp_output_7_0_g1068 , temp_output_10_0_g1068 );
				float3 lerpResult34_g1068 = lerp( temp_output_10_0_g1068 , -temp_output_13_0_g1068 , saturate( dotResult33_g1068 ));
				float dotResult37_g1068 = dot( temp_output_7_0_g1068 , -temp_output_10_0_g1068 );
				float3 lerpResult40_g1068 = lerp( lerpResult34_g1068 , temp_output_13_0_g1068 , saturate( dotResult37_g1068 ));
				float3 normalizeResult42_g1068 = normalize( lerpResult40_g1068 );
				float3 normalizeResult31_g1070 = normalize( normalizeResult42_g1068 );
				float3 normalizeResult29_g1070 = normalize( cross( normalizeResult27_g1070 , normalizeResult31_g1070 ) );
				float3 temp_output_65_22_g1066 = normalizeResult29_g1070;
				float3 temp_output_2_0_g1066 = ( lerpResult343_g1065 - DickOrigin16_g1065 );
				float3 temp_output_5_0_g1066 = DickRight184_g1065;
				float dotResult15_g1066 = dot( temp_output_2_0_g1066 , temp_output_5_0_g1066 );
				float3 temp_output_65_0_g1066 = cross( normalizeResult29_g1070 , normalizeResult27_g1070 );
				float dotResult18_g1066 = dot( temp_output_2_0_g1066 , temp_output_4_0_g1066 );
				float temp_output_208_0_g1065 = saturate( sign( temp_output_152_0_g1065 ) );
				float3 lerpResult221_g1065 = lerp( ( ( ( temp_output_19_0_g1077 * temp_output_19_0_g1077 * temp_output_19_0_g1077 * temp_output_8_0_g1076 ) + ( temp_output_19_0_g1077 * temp_output_19_0_g1077 * 3.0 * temp_output_26_0_g1077 * temp_output_9_0_g1076 ) + ( 3.0 * temp_output_19_0_g1077 * temp_output_26_0_g1077 * temp_output_26_0_g1077 * temp_output_10_0_g1076 ) + ( temp_output_26_0_g1077 * temp_output_26_0_g1077 * temp_output_26_0_g1077 * temp_output_11_0_g1076 ) ) + ( temp_output_65_22_g1076 * dotResult15_g1076 ) + ( temp_output_65_0_g1076 * dotResult18_g1076 ) ) , ( ( ( temp_output_19_0_g1067 * temp_output_19_0_g1067 * temp_output_19_0_g1067 * temp_output_8_0_g1066 ) + ( temp_output_19_0_g1067 * temp_output_19_0_g1067 * 3.0 * temp_output_26_0_g1067 * temp_output_9_0_g1066 ) + ( 3.0 * temp_output_19_0_g1067 * temp_output_26_0_g1067 * temp_output_26_0_g1067 * temp_output_10_0_g1066 ) + ( temp_output_26_0_g1067 * temp_output_26_0_g1067 * temp_output_26_0_g1067 * temp_output_11_0_g1066 ) ) + ( temp_output_65_22_g1066 * dotResult15_g1066 ) + ( temp_output_65_0_g1066 * dotResult18_g1066 ) ) , temp_output_208_0_g1065);
				float3 temp_output_42_0_g1071 = DickForward18_g1065;
				float NonVisibleLength165_g1065 = ( temp_output_11_0_g1065 * _PenetratorLength );
				float3 temp_output_52_0_g1071 = ( ( temp_output_42_0_g1071 * ( ( NonVisibleLength165_g1065 - OrifaceLength34_g1065 ) - DickLength19_g1065 ) ) + ( lerpResult343_g1065 - DickOrigin16_g1065 ) );
				float dotResult53_g1071 = dot( temp_output_42_0_g1071 , temp_output_52_0_g1071 );
				float temp_output_1_0_g1073 = 1.0;
				float temp_output_8_0_g1073 = ( 1.0 - temp_output_1_0_g1073 );
				float3 temp_output_3_0_g1073 = OrifaceOutPosition1183_g1065;
				float3 temp_output_4_0_g1073 = OrifaceOutPosition2182_g1065;
				float3 temp_output_7_0_g1072 = ( ( 3.0 * temp_output_8_0_g1073 * temp_output_8_0_g1073 * ( temp_output_3_0_g1073 - OrifacePosition170_g1065 ) ) + ( 6.0 * temp_output_8_0_g1073 * temp_output_1_0_g1073 * ( temp_output_4_0_g1073 - temp_output_3_0_g1073 ) ) + ( 3.0 * temp_output_1_0_g1073 * temp_output_1_0_g1073 * ( OrifaceOutPosition3175_g1065 - temp_output_4_0_g1073 ) ) );
				float3 normalizeResult27_g1074 = normalize( temp_output_7_0_g1072 );
				float3 temp_output_85_23_g1071 = normalizeResult27_g1074;
				float3 temp_output_4_0_g1071 = DickUp172_g1065;
				float dotResult54_g1071 = dot( temp_output_4_0_g1071 , temp_output_52_0_g1071 );
				float3 temp_output_10_0_g1072 = temp_output_4_0_g1071;
				float3 temp_output_13_0_g1072 = temp_output_42_0_g1071;
				float dotResult33_g1072 = dot( temp_output_7_0_g1072 , temp_output_10_0_g1072 );
				float3 lerpResult34_g1072 = lerp( temp_output_10_0_g1072 , -temp_output_13_0_g1072 , saturate( dotResult33_g1072 ));
				float dotResult37_g1072 = dot( temp_output_7_0_g1072 , -temp_output_10_0_g1072 );
				float3 lerpResult40_g1072 = lerp( lerpResult34_g1072 , temp_output_13_0_g1072 , saturate( dotResult37_g1072 ));
				float3 normalizeResult42_g1072 = normalize( lerpResult40_g1072 );
				float3 normalizeResult31_g1074 = normalize( normalizeResult42_g1072 );
				float3 normalizeResult29_g1074 = normalize( cross( normalizeResult27_g1074 , normalizeResult31_g1074 ) );
				float3 temp_output_85_0_g1071 = cross( normalizeResult29_g1074 , normalizeResult27_g1074 );
				float3 temp_output_43_0_g1071 = DickRight184_g1065;
				float dotResult55_g1071 = dot( temp_output_43_0_g1071 , temp_output_52_0_g1071 );
				float3 temp_output_85_22_g1071 = normalizeResult29_g1074;
				float temp_output_222_0_g1065 = saturate( sign( ( temp_output_157_0_g1065 - 1.0 ) ) );
				float3 lerpResult224_g1065 = lerp( lerpResult221_g1065 , ( ( ( dotResult53_g1071 * temp_output_85_23_g1071 ) + ( dotResult54_g1071 * temp_output_85_0_g1071 ) + ( dotResult55_g1071 * temp_output_85_22_g1071 ) ) + OrifaceOutPosition3175_g1065 ) , temp_output_222_0_g1065);
				float3 lerpResult418_g1065 = lerp( lerpResult224_g1065 , lerpResult221_g1065 , ClipDick413_g1065);
				float temp_output_226_0_g1065 = saturate( -PenetrationDepth39_g1065 );
				float3 lerpResult232_g1065 = lerp( lerpResult418_g1065 , originalPosition126_g1065 , temp_output_226_0_g1065);
				float3 ifLocalVar237_g1065 = 0;
				if( temp_output_234_0_g1065 <= 0.0 )
				ifLocalVar237_g1065 = originalPosition126_g1065;
				else
				ifLocalVar237_g1065 = lerpResult232_g1065;
				float DeformBalls426_g1065 = _DeformBalls;
				float3 lerpResult428_g1065 = lerp( ifLocalVar237_g1065 , lerpResult232_g1065 , DeformBalls426_g1065);
				
				float3 temp_output_21_0_g1076 = VertexNormal259_g1065;
				float dotResult55_g1076 = dot( temp_output_21_0_g1076 , temp_output_3_0_g1076 );
				float dotResult56_g1076 = dot( temp_output_21_0_g1076 , temp_output_4_0_g1076 );
				float dotResult57_g1076 = dot( temp_output_21_0_g1076 , temp_output_5_0_g1076 );
				float3 normalizeResult31_g1076 = normalize( ( ( dotResult55_g1076 * normalizeResult27_g1080 ) + ( dotResult56_g1076 * temp_output_65_0_g1076 ) + ( dotResult57_g1076 * temp_output_65_22_g1076 ) ) );
				float3 temp_output_21_0_g1066 = VertexNormal259_g1065;
				float dotResult55_g1066 = dot( temp_output_21_0_g1066 , temp_output_3_0_g1066 );
				float dotResult56_g1066 = dot( temp_output_21_0_g1066 , temp_output_4_0_g1066 );
				float dotResult57_g1066 = dot( temp_output_21_0_g1066 , temp_output_5_0_g1066 );
				float3 normalizeResult31_g1066 = normalize( ( ( dotResult55_g1066 * normalizeResult27_g1070 ) + ( dotResult56_g1066 * temp_output_65_0_g1066 ) + ( dotResult57_g1066 * temp_output_65_22_g1066 ) ) );
				float3 lerpResult227_g1065 = lerp( normalizeResult31_g1076 , normalizeResult31_g1066 , temp_output_208_0_g1065);
				float3 temp_output_24_0_g1071 = VertexNormal259_g1065;
				float dotResult61_g1071 = dot( temp_output_42_0_g1071 , temp_output_24_0_g1071 );
				float dotResult62_g1071 = dot( temp_output_4_0_g1071 , temp_output_24_0_g1071 );
				float dotResult60_g1071 = dot( temp_output_43_0_g1071 , temp_output_24_0_g1071 );
				float3 normalizeResult33_g1071 = normalize( ( ( dotResult61_g1071 * temp_output_85_23_g1071 ) + ( dotResult62_g1071 * temp_output_85_0_g1071 ) + ( dotResult60_g1071 * temp_output_85_22_g1071 ) ) );
				float3 lerpResult233_g1065 = lerp( lerpResult227_g1065 , normalizeResult33_g1071 , temp_output_222_0_g1065);
				float3 lerpResult419_g1065 = lerp( lerpResult233_g1065 , lerpResult227_g1065 , ClipDick413_g1065);
				float3 lerpResult238_g1065 = lerp( lerpResult419_g1065 , VertexNormal259_g1065 , temp_output_226_0_g1065);
				float3 ifLocalVar391_g1065 = 0;
				if( temp_output_234_0_g1065 <= 0.0 )
				ifLocalVar391_g1065 = VertexNormal259_g1065;
				else
				ifLocalVar391_g1065 = lerpResult238_g1065;
				
				float lerpResult424_g1065 = lerp( 1.0 , InsideLerp123_g1065 , InvisibleWhenInside420_g1065);
				float vertexToFrag250_g1065 = lerpResult424_g1065;
				o.ase_texcoord3.x = vertexToFrag250_g1065;
				
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.yzw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = lerpResult428_g1065;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = ifLocalVar391_g1065;
				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float3 normalWS = TransformObjectToWorldNormal( v.ase_normal );
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
				#endif

				o.worldNormal = normalWS;

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				o.clipPos = positionCS;
				return o;
			}

			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_tangent : TANGENT;
				float4 ase_color : COLOR;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord3 : TEXCOORD3;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord2 = v.ase_texcoord2;
				o.ase_tangent = v.ase_tangent;
				o.ase_color = v.ase_color;
				o.ase_texcoord1 = v.ase_texcoord1;
				o.ase_texcoord3 = v.ase_texcoord3;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord2 = patch[0].ase_texcoord2 * bary.x + patch[1].ase_texcoord2 * bary.y + patch[2].ase_texcoord2 * bary.z;
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				o.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				o.ase_texcoord3 = patch[0].ase_texcoord3 * bary.x + patch[1].ase_texcoord3 * bary.y + patch[2].ase_texcoord3 * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE)
				#define ASE_SV_DEPTH SV_DepthLessEqual  
			#else
				#define ASE_SV_DEPTH SV_Depth
			#endif
			half4 frag(	VertexOutput IN 
						#ifdef ASE_DEPTH_WRITE_ON
						,out float outputDepth : ASE_SV_DEPTH
						#endif
						 ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.worldPos;
				#endif
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float vertexToFrag250_g1065 = IN.ase_texcoord3.x;
				
				float Alpha = vertexToFrag250_g1065;
				float AlphaClipThreshold = 0.5;
				#ifdef ASE_DEPTH_WRITE_ON
				float DepthValue = 0;
				#endif

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif
				
				#ifdef ASE_DEPTH_WRITE_ON
				outputDepth = DepthValue;
				#endif
				
				return float4(PackNormalOctRectEncode(TransformWorldToViewDir(IN.worldNormal, true)), 0.0, 0.0);
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "GBuffer"
			Tags { "LightMode"="UniversalGBuffer" }
			
			Blend One Zero, One Zero
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA
			

			HLSLPROGRAM
			
			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_instancing
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define ASE_ABSOLUTE_VERTEX_POS 1
			#define _EMISSION
			#define _ALPHATEST_ON 1
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 100600

			
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile _ _SHADOWS_SOFT
			#pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
			#pragma multi_compile _ _GBUFFER_NORMALS_OCT
			
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile _ LIGHTMAP_ON

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS SHADERPASS_GBUFFER

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"

			#if ASE_SRP_VERSION <= 70108
			#define REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
			#endif

			#if defined(UNITY_INSTANCING_ENABLED) && defined(_TERRAIN_INSTANCED_PERPIXEL_NORMAL)
			    #define ENABLE_TERRAIN_PERPIXEL_NORMAL
			#endif

			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_VERT_TANGENT
			#define ASE_NEEDS_VERT_POSITION


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord : TEXCOORD0;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				float4 ase_texcoord3 : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				float4 lightmapUVOrVertexSH : TEXCOORD0;
				half4 fogFactorAndVertexLight : TEXCOORD1;
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
				float4 shadowCoord : TEXCOORD2;
				#endif
				float4 tSpace0 : TEXCOORD3;
				float4 tSpace1 : TEXCOORD4;
				float4 tSpace2 : TEXCOORD5;
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
				float4 screenPos : TEXCOORD6;
				#endif
				float4 ase_texcoord7 : TEXCOORD7;
				float4 ase_texcoord8 : TEXCOORD8;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _MetallicSmoothness_ST;
			float4 _EmissionMap_ST;
			float4 _NormalMap_ST;
			float4 _BaseColorMap_ST;
			float4 _EmissionColor;
			float3 _PenetratorOrigin;
			float3 _OrificeWorldPosition;
			float3 _PenetratorUp;
			float3 _PenetratorForward;
			float3 _OrificeOutWorldPosition3;
			float3 _OrificeOutWorldPosition2;
			float3 _OrificeOutWorldPosition1;
			float3 _OrificeWorldNormal;
			float3 _PenetratorRight;
			float _DeformBalls;
			float _InvisibleWhenInside;
			float _PinchBuffer;
			float _OrificeLength;
			float _NoBlendshapes;
			float _PenetratorCumActive;
			float _PenetratorCumProgress;
			float _PenetratorSquishPullAmount;
			float _PenetratorBulgePercentage;
			float _BulgeDistance;
			float _PenetrationDepth;
			float _PenetratorLength;
			float _ClipDick;
			float _PenetratorBlendshapeMultiplier;
			#ifdef _TRANSMISSION_ASE
				float _TransmissionShadow;
			#endif
			#ifdef _TRANSLUCENCY_ASE
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			float4 _JiggleInfos[16];
			sampler2D _Foam;
			sampler2D _BaseColorMap;
			sampler2D _NormalMap;
			sampler2D _FoamNormal;
			sampler2D _EmissionMap;
			sampler2D _MetallicSmoothness;


			float3 GetSoftbodyOffset3_g1064( float blend, float3 vertexPosition )
			{
				float3 vertexOffset = float3(0,0,0);
				for(int i=0;i<8;i++) {
				    float4 targetPosePositionRadius = _JiggleInfos[i*2];
				    float4 verletPositionBlend = _JiggleInfos[i*2+1];
				    float3 movement = (verletPositionBlend.xyz - targetPosePositionRadius.xyz);
				    float dist = distance(vertexPosition, targetPosePositionRadius.xyz);
				    float multi = 1-smoothstep(0,targetPosePositionRadius.w,dist);
				    vertexOffset += movement * multi * verletPositionBlend.w * blend;
				}
				return vertexOffset;
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 VertexNormal259_g1065 = v.ase_normal;
				float3 normalizeResult27_g1081 = normalize( VertexNormal259_g1065 );
				float3 temp_output_35_0_g1065 = normalizeResult27_g1081;
				float3 normalizeResult31_g1081 = normalize( v.ase_tangent.xyz );
				float3 normalizeResult29_g1081 = normalize( cross( normalizeResult27_g1081 , normalizeResult31_g1081 ) );
				float3 temp_output_35_1_g1065 = cross( normalizeResult29_g1081 , normalizeResult27_g1081 );
				float3 temp_output_35_2_g1065 = normalizeResult29_g1081;
				float3 SquishDelta85_g1065 = ( ( ( temp_output_35_0_g1065 * v.ase_texcoord2.x ) + ( temp_output_35_1_g1065 * v.ase_texcoord2.y ) + ( temp_output_35_2_g1065 * v.ase_texcoord2.z ) ) * _PenetratorBlendshapeMultiplier );
				float temp_output_234_0_g1065 = length( SquishDelta85_g1065 );
				float temp_output_11_0_g1065 = max( _PenetrationDepth , 0.0 );
				float VisibleLength25_g1065 = ( _PenetratorLength * ( 1.0 - temp_output_11_0_g1065 ) );
				float3 DickOrigin16_g1065 = _PenetratorOrigin;
				float4 appendResult132_g1065 = (float4(_OrificeWorldPosition , 1.0));
				float4 transform140_g1065 = mul(GetWorldToObjectMatrix(),appendResult132_g1065);
				float3 OrifacePosition170_g1065 = (transform140_g1065).xyz;
				float DickLength19_g1065 = _PenetratorLength;
				float3 DickUp172_g1065 = _PenetratorUp;
				float blend3_g1064 = v.ase_color.r;
				float2 texCoord10 = v.texcoord1.xyzw.xy * float2( 1,1 ) + float2( 0,0 );
				float mulTime12 = _TimeParameters.x * 0.01;
				float mulTime11 = _TimeParameters.x * 0.1;
				float2 appendResult15 = (float2(( texCoord10.x + mulTime12 ) , ( texCoord10.y + mulTime11 )));
				float4 tex2DNode16 = tex2Dlod( _Foam, float4( appendResult15, 0, 0.0) );
				float3 temp_output_20_0 = ( v.ase_normal * _BulgeDistance * tex2DNode16.r * v.ase_color.g );
				float3 vertexPosition3_g1064 = ( v.vertex.xyz + temp_output_20_0 );
				float3 localGetSoftbodyOffset3_g1064 = GetSoftbodyOffset3_g1064( blend3_g1064 , vertexPosition3_g1064 );
				float3 VertexPosition254_g1065 = ( localGetSoftbodyOffset3_g1064 + temp_output_20_0 + v.vertex.xyz );
				float3 temp_output_27_0_g1065 = ( VertexPosition254_g1065 - DickOrigin16_g1065 );
				float3 DickForward18_g1065 = _PenetratorForward;
				float dotResult42_g1065 = dot( temp_output_27_0_g1065 , DickForward18_g1065 );
				float BulgePercentage37_g1065 = _PenetratorBulgePercentage;
				float temp_output_1_0_g1075 = saturate( ( abs( ( dotResult42_g1065 - VisibleLength25_g1065 ) ) / ( DickLength19_g1065 * BulgePercentage37_g1065 ) ) );
				float temp_output_94_0_g1065 = sqrt( ( 1.0 - ( temp_output_1_0_g1075 * temp_output_1_0_g1075 ) ) );
				float3 PullDelta91_g1065 = ( ( ( temp_output_35_0_g1065 * v.ase_texcoord3.x ) + ( temp_output_35_1_g1065 * v.ase_texcoord3.y ) + ( temp_output_35_2_g1065 * v.ase_texcoord3.z ) ) * _PenetratorBlendshapeMultiplier );
				float dotResult32_g1065 = dot( temp_output_27_0_g1065 , DickForward18_g1065 );
				float temp_output_1_0_g1082 = saturate( ( abs( ( dotResult32_g1065 - ( DickLength19_g1065 * _PenetratorCumProgress ) ) ) / ( DickLength19_g1065 * BulgePercentage37_g1065 ) ) );
				float3 CumDelta90_g1065 = ( ( ( temp_output_35_0_g1065 * v.texcoord1.xyzw.w ) + ( temp_output_35_1_g1065 * v.ase_texcoord2.w ) + ( temp_output_35_2_g1065 * v.ase_texcoord3.w ) ) * _PenetratorBlendshapeMultiplier );
				float3 lerpResult410_g1065 = lerp( ( VertexPosition254_g1065 + ( SquishDelta85_g1065 * temp_output_94_0_g1065 * saturate( -_PenetratorSquishPullAmount ) ) + ( temp_output_94_0_g1065 * PullDelta91_g1065 * saturate( _PenetratorSquishPullAmount ) ) + ( sqrt( ( 1.0 - ( temp_output_1_0_g1082 * temp_output_1_0_g1082 ) ) ) * CumDelta90_g1065 * _PenetratorCumActive ) ) , VertexPosition254_g1065 , _NoBlendshapes);
				float3 originalPosition126_g1065 = lerpResult410_g1065;
				float dotResult118_g1065 = dot( ( lerpResult410_g1065 - DickOrigin16_g1065 ) , DickForward18_g1065 );
				float PenetrationDepth39_g1065 = _PenetrationDepth;
				float temp_output_65_0_g1065 = ( PenetrationDepth39_g1065 * DickLength19_g1065 );
				float OrifaceLength34_g1065 = _OrificeLength;
				float temp_output_73_0_g1065 = ( _PinchBuffer * OrifaceLength34_g1065 );
				float dotResult80_g1065 = dot( ( lerpResult410_g1065 - DickOrigin16_g1065 ) , DickForward18_g1065 );
				float temp_output_112_0_g1065 = ( -( ( ( temp_output_65_0_g1065 - temp_output_73_0_g1065 ) + dotResult80_g1065 ) - DickLength19_g1065 ) * 10.0 );
				float ClipDick413_g1065 = _ClipDick;
				float lerpResult411_g1065 = lerp( max( temp_output_112_0_g1065 , ( ( ( temp_output_65_0_g1065 + dotResult80_g1065 + temp_output_73_0_g1065 ) - ( OrifaceLength34_g1065 + DickLength19_g1065 ) ) * 10.0 ) ) , temp_output_112_0_g1065 , ClipDick413_g1065);
				float InsideLerp123_g1065 = saturate( lerpResult411_g1065 );
				float3 lerpResult124_g1065 = lerp( ( ( DickForward18_g1065 * dotResult118_g1065 ) + DickOrigin16_g1065 ) , originalPosition126_g1065 , InsideLerp123_g1065);
				float InvisibleWhenInside420_g1065 = _InvisibleWhenInside;
				float3 lerpResult422_g1065 = lerp( originalPosition126_g1065 , lerpResult124_g1065 , InvisibleWhenInside420_g1065);
				float3 temp_output_354_0_g1065 = ( lerpResult422_g1065 - DickOrigin16_g1065 );
				float dotResult373_g1065 = dot( DickUp172_g1065 , temp_output_354_0_g1065 );
				float3 DickRight184_g1065 = _PenetratorRight;
				float dotResult374_g1065 = dot( DickRight184_g1065 , temp_output_354_0_g1065 );
				float dotResult375_g1065 = dot( temp_output_354_0_g1065 , DickForward18_g1065 );
				float3 lerpResult343_g1065 = lerp( ( ( ( saturate( ( ( VisibleLength25_g1065 - distance( DickOrigin16_g1065 , OrifacePosition170_g1065 ) ) / DickLength19_g1065 ) ) + 1.0 ) * dotResult373_g1065 * DickUp172_g1065 ) + ( ( saturate( ( ( VisibleLength25_g1065 - distance( DickOrigin16_g1065 , OrifacePosition170_g1065 ) ) / DickLength19_g1065 ) ) + 1.0 ) * dotResult374_g1065 * DickRight184_g1065 ) + ( DickForward18_g1065 * dotResult375_g1065 ) + DickOrigin16_g1065 ) , lerpResult422_g1065 , saturate( PenetrationDepth39_g1065 ));
				float dotResult177_g1065 = dot( ( lerpResult343_g1065 - DickOrigin16_g1065 ) , DickForward18_g1065 );
				float temp_output_178_0_g1065 = max( VisibleLength25_g1065 , 0.05 );
				float temp_output_42_0_g1076 = ( dotResult177_g1065 / temp_output_178_0_g1065 );
				float temp_output_26_0_g1077 = temp_output_42_0_g1076;
				float temp_output_19_0_g1077 = ( 1.0 - temp_output_26_0_g1077 );
				float3 temp_output_8_0_g1076 = DickOrigin16_g1065;
				float temp_output_393_0_g1065 = distance( DickOrigin16_g1065 , OrifacePosition170_g1065 );
				float temp_output_396_0_g1065 = min( temp_output_178_0_g1065 , temp_output_393_0_g1065 );
				float3 temp_output_9_0_g1076 = ( DickOrigin16_g1065 + ( DickForward18_g1065 * temp_output_396_0_g1065 * 0.25 ) );
				float4 appendResult130_g1065 = (float4(_OrificeWorldNormal , 0.0));
				float4 transform135_g1065 = mul(GetWorldToObjectMatrix(),appendResult130_g1065);
				float3 OrifaceNormal155_g1065 = (transform135_g1065).xyz;
				float3 temp_output_10_0_g1076 = ( OrifacePosition170_g1065 + ( OrifaceNormal155_g1065 * 0.25 * temp_output_396_0_g1065 ) );
				float3 temp_output_11_0_g1076 = OrifacePosition170_g1065;
				float temp_output_1_0_g1079 = temp_output_42_0_g1076;
				float temp_output_8_0_g1079 = ( 1.0 - temp_output_1_0_g1079 );
				float3 temp_output_3_0_g1079 = temp_output_9_0_g1076;
				float3 temp_output_4_0_g1079 = temp_output_10_0_g1076;
				float3 temp_output_7_0_g1078 = ( ( 3.0 * temp_output_8_0_g1079 * temp_output_8_0_g1079 * ( temp_output_3_0_g1079 - temp_output_8_0_g1076 ) ) + ( 6.0 * temp_output_8_0_g1079 * temp_output_1_0_g1079 * ( temp_output_4_0_g1079 - temp_output_3_0_g1079 ) ) + ( 3.0 * temp_output_1_0_g1079 * temp_output_1_0_g1079 * ( temp_output_11_0_g1076 - temp_output_4_0_g1079 ) ) );
				float3 normalizeResult27_g1080 = normalize( temp_output_7_0_g1078 );
				float3 temp_output_4_0_g1076 = DickUp172_g1065;
				float3 temp_output_10_0_g1078 = temp_output_4_0_g1076;
				float3 temp_output_3_0_g1076 = DickForward18_g1065;
				float3 temp_output_13_0_g1078 = temp_output_3_0_g1076;
				float dotResult33_g1078 = dot( temp_output_7_0_g1078 , temp_output_10_0_g1078 );
				float3 lerpResult34_g1078 = lerp( temp_output_10_0_g1078 , -temp_output_13_0_g1078 , saturate( dotResult33_g1078 ));
				float dotResult37_g1078 = dot( temp_output_7_0_g1078 , -temp_output_10_0_g1078 );
				float3 lerpResult40_g1078 = lerp( lerpResult34_g1078 , temp_output_13_0_g1078 , saturate( dotResult37_g1078 ));
				float3 normalizeResult42_g1078 = normalize( lerpResult40_g1078 );
				float3 normalizeResult31_g1080 = normalize( normalizeResult42_g1078 );
				float3 normalizeResult29_g1080 = normalize( cross( normalizeResult27_g1080 , normalizeResult31_g1080 ) );
				float3 temp_output_65_22_g1076 = normalizeResult29_g1080;
				float3 temp_output_2_0_g1076 = ( lerpResult343_g1065 - DickOrigin16_g1065 );
				float3 temp_output_5_0_g1076 = DickRight184_g1065;
				float dotResult15_g1076 = dot( temp_output_2_0_g1076 , temp_output_5_0_g1076 );
				float3 temp_output_65_0_g1076 = cross( normalizeResult29_g1080 , normalizeResult27_g1080 );
				float dotResult18_g1076 = dot( temp_output_2_0_g1076 , temp_output_4_0_g1076 );
				float dotResult142_g1065 = dot( ( lerpResult343_g1065 - DickOrigin16_g1065 ) , DickForward18_g1065 );
				float temp_output_152_0_g1065 = ( dotResult142_g1065 - VisibleLength25_g1065 );
				float temp_output_157_0_g1065 = ( temp_output_152_0_g1065 / OrifaceLength34_g1065 );
				float lerpResult416_g1065 = lerp( temp_output_157_0_g1065 , min( temp_output_157_0_g1065 , 1.0 ) , ClipDick413_g1065);
				float temp_output_42_0_g1066 = lerpResult416_g1065;
				float temp_output_26_0_g1067 = temp_output_42_0_g1066;
				float temp_output_19_0_g1067 = ( 1.0 - temp_output_26_0_g1067 );
				float3 temp_output_8_0_g1066 = OrifacePosition170_g1065;
				float4 appendResult145_g1065 = (float4(_OrificeOutWorldPosition1 , 1.0));
				float4 transform151_g1065 = mul(GetWorldToObjectMatrix(),appendResult145_g1065);
				float3 OrifaceOutPosition1183_g1065 = (transform151_g1065).xyz;
				float3 temp_output_9_0_g1066 = OrifaceOutPosition1183_g1065;
				float4 appendResult144_g1065 = (float4(_OrificeOutWorldPosition2 , 1.0));
				float4 transform154_g1065 = mul(GetWorldToObjectMatrix(),appendResult144_g1065);
				float3 OrifaceOutPosition2182_g1065 = (transform154_g1065).xyz;
				float3 temp_output_10_0_g1066 = OrifaceOutPosition2182_g1065;
				float4 appendResult143_g1065 = (float4(_OrificeOutWorldPosition3 , 1.0));
				float4 transform147_g1065 = mul(GetWorldToObjectMatrix(),appendResult143_g1065);
				float3 OrifaceOutPosition3175_g1065 = (transform147_g1065).xyz;
				float3 temp_output_11_0_g1066 = OrifaceOutPosition3175_g1065;
				float temp_output_1_0_g1069 = temp_output_42_0_g1066;
				float temp_output_8_0_g1069 = ( 1.0 - temp_output_1_0_g1069 );
				float3 temp_output_3_0_g1069 = temp_output_9_0_g1066;
				float3 temp_output_4_0_g1069 = temp_output_10_0_g1066;
				float3 temp_output_7_0_g1068 = ( ( 3.0 * temp_output_8_0_g1069 * temp_output_8_0_g1069 * ( temp_output_3_0_g1069 - temp_output_8_0_g1066 ) ) + ( 6.0 * temp_output_8_0_g1069 * temp_output_1_0_g1069 * ( temp_output_4_0_g1069 - temp_output_3_0_g1069 ) ) + ( 3.0 * temp_output_1_0_g1069 * temp_output_1_0_g1069 * ( temp_output_11_0_g1066 - temp_output_4_0_g1069 ) ) );
				float3 normalizeResult27_g1070 = normalize( temp_output_7_0_g1068 );
				float3 temp_output_4_0_g1066 = DickUp172_g1065;
				float3 temp_output_10_0_g1068 = temp_output_4_0_g1066;
				float3 temp_output_3_0_g1066 = DickForward18_g1065;
				float3 temp_output_13_0_g1068 = temp_output_3_0_g1066;
				float dotResult33_g1068 = dot( temp_output_7_0_g1068 , temp_output_10_0_g1068 );
				float3 lerpResult34_g1068 = lerp( temp_output_10_0_g1068 , -temp_output_13_0_g1068 , saturate( dotResult33_g1068 ));
				float dotResult37_g1068 = dot( temp_output_7_0_g1068 , -temp_output_10_0_g1068 );
				float3 lerpResult40_g1068 = lerp( lerpResult34_g1068 , temp_output_13_0_g1068 , saturate( dotResult37_g1068 ));
				float3 normalizeResult42_g1068 = normalize( lerpResult40_g1068 );
				float3 normalizeResult31_g1070 = normalize( normalizeResult42_g1068 );
				float3 normalizeResult29_g1070 = normalize( cross( normalizeResult27_g1070 , normalizeResult31_g1070 ) );
				float3 temp_output_65_22_g1066 = normalizeResult29_g1070;
				float3 temp_output_2_0_g1066 = ( lerpResult343_g1065 - DickOrigin16_g1065 );
				float3 temp_output_5_0_g1066 = DickRight184_g1065;
				float dotResult15_g1066 = dot( temp_output_2_0_g1066 , temp_output_5_0_g1066 );
				float3 temp_output_65_0_g1066 = cross( normalizeResult29_g1070 , normalizeResult27_g1070 );
				float dotResult18_g1066 = dot( temp_output_2_0_g1066 , temp_output_4_0_g1066 );
				float temp_output_208_0_g1065 = saturate( sign( temp_output_152_0_g1065 ) );
				float3 lerpResult221_g1065 = lerp( ( ( ( temp_output_19_0_g1077 * temp_output_19_0_g1077 * temp_output_19_0_g1077 * temp_output_8_0_g1076 ) + ( temp_output_19_0_g1077 * temp_output_19_0_g1077 * 3.0 * temp_output_26_0_g1077 * temp_output_9_0_g1076 ) + ( 3.0 * temp_output_19_0_g1077 * temp_output_26_0_g1077 * temp_output_26_0_g1077 * temp_output_10_0_g1076 ) + ( temp_output_26_0_g1077 * temp_output_26_0_g1077 * temp_output_26_0_g1077 * temp_output_11_0_g1076 ) ) + ( temp_output_65_22_g1076 * dotResult15_g1076 ) + ( temp_output_65_0_g1076 * dotResult18_g1076 ) ) , ( ( ( temp_output_19_0_g1067 * temp_output_19_0_g1067 * temp_output_19_0_g1067 * temp_output_8_0_g1066 ) + ( temp_output_19_0_g1067 * temp_output_19_0_g1067 * 3.0 * temp_output_26_0_g1067 * temp_output_9_0_g1066 ) + ( 3.0 * temp_output_19_0_g1067 * temp_output_26_0_g1067 * temp_output_26_0_g1067 * temp_output_10_0_g1066 ) + ( temp_output_26_0_g1067 * temp_output_26_0_g1067 * temp_output_26_0_g1067 * temp_output_11_0_g1066 ) ) + ( temp_output_65_22_g1066 * dotResult15_g1066 ) + ( temp_output_65_0_g1066 * dotResult18_g1066 ) ) , temp_output_208_0_g1065);
				float3 temp_output_42_0_g1071 = DickForward18_g1065;
				float NonVisibleLength165_g1065 = ( temp_output_11_0_g1065 * _PenetratorLength );
				float3 temp_output_52_0_g1071 = ( ( temp_output_42_0_g1071 * ( ( NonVisibleLength165_g1065 - OrifaceLength34_g1065 ) - DickLength19_g1065 ) ) + ( lerpResult343_g1065 - DickOrigin16_g1065 ) );
				float dotResult53_g1071 = dot( temp_output_42_0_g1071 , temp_output_52_0_g1071 );
				float temp_output_1_0_g1073 = 1.0;
				float temp_output_8_0_g1073 = ( 1.0 - temp_output_1_0_g1073 );
				float3 temp_output_3_0_g1073 = OrifaceOutPosition1183_g1065;
				float3 temp_output_4_0_g1073 = OrifaceOutPosition2182_g1065;
				float3 temp_output_7_0_g1072 = ( ( 3.0 * temp_output_8_0_g1073 * temp_output_8_0_g1073 * ( temp_output_3_0_g1073 - OrifacePosition170_g1065 ) ) + ( 6.0 * temp_output_8_0_g1073 * temp_output_1_0_g1073 * ( temp_output_4_0_g1073 - temp_output_3_0_g1073 ) ) + ( 3.0 * temp_output_1_0_g1073 * temp_output_1_0_g1073 * ( OrifaceOutPosition3175_g1065 - temp_output_4_0_g1073 ) ) );
				float3 normalizeResult27_g1074 = normalize( temp_output_7_0_g1072 );
				float3 temp_output_85_23_g1071 = normalizeResult27_g1074;
				float3 temp_output_4_0_g1071 = DickUp172_g1065;
				float dotResult54_g1071 = dot( temp_output_4_0_g1071 , temp_output_52_0_g1071 );
				float3 temp_output_10_0_g1072 = temp_output_4_0_g1071;
				float3 temp_output_13_0_g1072 = temp_output_42_0_g1071;
				float dotResult33_g1072 = dot( temp_output_7_0_g1072 , temp_output_10_0_g1072 );
				float3 lerpResult34_g1072 = lerp( temp_output_10_0_g1072 , -temp_output_13_0_g1072 , saturate( dotResult33_g1072 ));
				float dotResult37_g1072 = dot( temp_output_7_0_g1072 , -temp_output_10_0_g1072 );
				float3 lerpResult40_g1072 = lerp( lerpResult34_g1072 , temp_output_13_0_g1072 , saturate( dotResult37_g1072 ));
				float3 normalizeResult42_g1072 = normalize( lerpResult40_g1072 );
				float3 normalizeResult31_g1074 = normalize( normalizeResult42_g1072 );
				float3 normalizeResult29_g1074 = normalize( cross( normalizeResult27_g1074 , normalizeResult31_g1074 ) );
				float3 temp_output_85_0_g1071 = cross( normalizeResult29_g1074 , normalizeResult27_g1074 );
				float3 temp_output_43_0_g1071 = DickRight184_g1065;
				float dotResult55_g1071 = dot( temp_output_43_0_g1071 , temp_output_52_0_g1071 );
				float3 temp_output_85_22_g1071 = normalizeResult29_g1074;
				float temp_output_222_0_g1065 = saturate( sign( ( temp_output_157_0_g1065 - 1.0 ) ) );
				float3 lerpResult224_g1065 = lerp( lerpResult221_g1065 , ( ( ( dotResult53_g1071 * temp_output_85_23_g1071 ) + ( dotResult54_g1071 * temp_output_85_0_g1071 ) + ( dotResult55_g1071 * temp_output_85_22_g1071 ) ) + OrifaceOutPosition3175_g1065 ) , temp_output_222_0_g1065);
				float3 lerpResult418_g1065 = lerp( lerpResult224_g1065 , lerpResult221_g1065 , ClipDick413_g1065);
				float temp_output_226_0_g1065 = saturate( -PenetrationDepth39_g1065 );
				float3 lerpResult232_g1065 = lerp( lerpResult418_g1065 , originalPosition126_g1065 , temp_output_226_0_g1065);
				float3 ifLocalVar237_g1065 = 0;
				if( temp_output_234_0_g1065 <= 0.0 )
				ifLocalVar237_g1065 = originalPosition126_g1065;
				else
				ifLocalVar237_g1065 = lerpResult232_g1065;
				float DeformBalls426_g1065 = _DeformBalls;
				float3 lerpResult428_g1065 = lerp( ifLocalVar237_g1065 , lerpResult232_g1065 , DeformBalls426_g1065);
				
				float3 temp_output_21_0_g1076 = VertexNormal259_g1065;
				float dotResult55_g1076 = dot( temp_output_21_0_g1076 , temp_output_3_0_g1076 );
				float dotResult56_g1076 = dot( temp_output_21_0_g1076 , temp_output_4_0_g1076 );
				float dotResult57_g1076 = dot( temp_output_21_0_g1076 , temp_output_5_0_g1076 );
				float3 normalizeResult31_g1076 = normalize( ( ( dotResult55_g1076 * normalizeResult27_g1080 ) + ( dotResult56_g1076 * temp_output_65_0_g1076 ) + ( dotResult57_g1076 * temp_output_65_22_g1076 ) ) );
				float3 temp_output_21_0_g1066 = VertexNormal259_g1065;
				float dotResult55_g1066 = dot( temp_output_21_0_g1066 , temp_output_3_0_g1066 );
				float dotResult56_g1066 = dot( temp_output_21_0_g1066 , temp_output_4_0_g1066 );
				float dotResult57_g1066 = dot( temp_output_21_0_g1066 , temp_output_5_0_g1066 );
				float3 normalizeResult31_g1066 = normalize( ( ( dotResult55_g1066 * normalizeResult27_g1070 ) + ( dotResult56_g1066 * temp_output_65_0_g1066 ) + ( dotResult57_g1066 * temp_output_65_22_g1066 ) ) );
				float3 lerpResult227_g1065 = lerp( normalizeResult31_g1076 , normalizeResult31_g1066 , temp_output_208_0_g1065);
				float3 temp_output_24_0_g1071 = VertexNormal259_g1065;
				float dotResult61_g1071 = dot( temp_output_42_0_g1071 , temp_output_24_0_g1071 );
				float dotResult62_g1071 = dot( temp_output_4_0_g1071 , temp_output_24_0_g1071 );
				float dotResult60_g1071 = dot( temp_output_43_0_g1071 , temp_output_24_0_g1071 );
				float3 normalizeResult33_g1071 = normalize( ( ( dotResult61_g1071 * temp_output_85_23_g1071 ) + ( dotResult62_g1071 * temp_output_85_0_g1071 ) + ( dotResult60_g1071 * temp_output_85_22_g1071 ) ) );
				float3 lerpResult233_g1065 = lerp( lerpResult227_g1065 , normalizeResult33_g1071 , temp_output_222_0_g1065);
				float3 lerpResult419_g1065 = lerp( lerpResult233_g1065 , lerpResult227_g1065 , ClipDick413_g1065);
				float3 lerpResult238_g1065 = lerp( lerpResult419_g1065 , VertexNormal259_g1065 , temp_output_226_0_g1065);
				float3 ifLocalVar391_g1065 = 0;
				if( temp_output_234_0_g1065 <= 0.0 )
				ifLocalVar391_g1065 = VertexNormal259_g1065;
				else
				ifLocalVar391_g1065 = lerpResult238_g1065;
				
				float lerpResult424_g1065 = lerp( 1.0 , InsideLerp123_g1065 , InvisibleWhenInside420_g1065);
				float vertexToFrag250_g1065 = lerpResult424_g1065;
				o.ase_texcoord7.z = vertexToFrag250_g1065;
				
				o.ase_texcoord7.xy = v.texcoord.xy;
				o.ase_texcoord8 = v.texcoord1.xyzw;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord7.w = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = lerpResult428_g1065;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.ase_normal = ifLocalVar391_g1065;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float3 positionVS = TransformWorldToView( positionWS );
				float4 positionCS = TransformWorldToHClip( positionWS );

				VertexNormalInputs normalInput = GetVertexNormalInputs( v.ase_normal, v.ase_tangent );

				o.tSpace0 = float4( normalInput.normalWS, positionWS.x);
				o.tSpace1 = float4( normalInput.tangentWS, positionWS.y);
				o.tSpace2 = float4( normalInput.bitangentWS, positionWS.z);

				OUTPUT_LIGHTMAP_UV( v.texcoord1, unity_LightmapST, o.lightmapUVOrVertexSH.xy );
				OUTPUT_SH( normalInput.normalWS.xyz, o.lightmapUVOrVertexSH.xyz );

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					o.lightmapUVOrVertexSH.zw = v.texcoord;
					o.lightmapUVOrVertexSH.xy = v.texcoord * unity_LightmapST.xy + unity_LightmapST.zw;
				#endif

				half3 vertexLight = VertexLighting( positionWS, normalInput.normalWS );
				#ifdef ASE_FOG
					half fogFactor = ComputeFogFactor( positionCS.z );
				#else
					half fogFactor = 0;
				#endif
				o.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
				
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
				VertexPositionInputs vertexInput = (VertexPositionInputs)0;
				vertexInput.positionWS = positionWS;
				vertexInput.positionCS = positionCS;
				o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				
				o.clipPos = positionCS;
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
				o.screenPos = ComputeScreenPos(positionCS);
				#endif
				return o;
			}
			
			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				float4 ase_texcoord3 : TEXCOORD3;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_tangent = v.ase_tangent;
				o.texcoord = v.texcoord;
				o.texcoord1 = v.texcoord1;
				o.texcoord = v.texcoord;
				o.ase_texcoord2 = v.ase_texcoord2;
				o.ase_color = v.ase_color;
				o.ase_texcoord3 = v.ase_texcoord3;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				o.texcoord = patch[0].texcoord * bary.x + patch[1].texcoord * bary.y + patch[2].texcoord * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.texcoord = patch[0].texcoord * bary.x + patch[1].texcoord * bary.y + patch[2].texcoord * bary.z;
				o.ase_texcoord2 = patch[0].ase_texcoord2 * bary.x + patch[1].ase_texcoord2 * bary.y + patch[2].ase_texcoord2 * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				o.ase_texcoord3 = patch[0].ase_texcoord3 * bary.x + patch[1].ase_texcoord3 * bary.y + patch[2].ase_texcoord3 * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE)
				#define ASE_SV_DEPTH SV_DepthLessEqual  
			#else
				#define ASE_SV_DEPTH SV_Depth
			#endif
			FragmentOutput frag ( VertexOutput IN 
								#ifdef ASE_DEPTH_WRITE_ON
								,out float outputDepth : ASE_SV_DEPTH
								#endif
								 )
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					float2 sampleCoords = (IN.lightmapUVOrVertexSH.zw / _TerrainHeightmapRecipSize.zw + 0.5f) * _TerrainHeightmapRecipSize.xy;
					float3 WorldNormal = TransformObjectToWorldNormal(normalize(SAMPLE_TEXTURE2D(_TerrainNormalmapTexture, sampler_TerrainNormalmapTexture, sampleCoords).rgb * 2 - 1));
					float3 WorldTangent = -cross(GetObjectToWorldMatrix()._13_23_33, WorldNormal);
					float3 WorldBiTangent = cross(WorldNormal, -WorldTangent);
				#else
					float3 WorldNormal = normalize( IN.tSpace0.xyz );
					float3 WorldTangent = IN.tSpace1.xyz;
					float3 WorldBiTangent = IN.tSpace2.xyz;
				#endif
				float3 WorldPosition = float3(IN.tSpace0.w,IN.tSpace1.w,IN.tSpace2.w);
				float3 WorldViewDirection = _WorldSpaceCameraPos.xyz  - WorldPosition;
				float4 ShadowCoords = float4( 0, 0, 0, 0 );
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
				float4 ScreenPos = IN.screenPos;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					ShadowCoords = IN.shadowCoord;
				#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
					ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
				#endif
	
				WorldViewDirection = SafeNormalize( WorldViewDirection );

				float2 uv_BaseColorMap = IN.ase_texcoord7.xy * _BaseColorMap_ST.xy + _BaseColorMap_ST.zw;
				
				float2 uv_NormalMap = IN.ase_texcoord7.xy * _NormalMap_ST.xy + _NormalMap_ST.zw;
				float2 texCoord10 = IN.ase_texcoord8.xy * float2( 1,1 ) + float2( 0,0 );
				float mulTime12 = _TimeParameters.x * 0.01;
				float mulTime11 = _TimeParameters.x * 0.1;
				float2 appendResult15 = (float2(( texCoord10.x + mulTime12 ) , ( texCoord10.y + mulTime11 )));
				float3 unpack27 = UnpackNormalScale( tex2D( _FoamNormal, appendResult15 ), 2.0 );
				unpack27.z = lerp( 1, unpack27.z, saturate(2.0) );
				float4 tex2DNode16 = tex2D( _Foam, appendResult15 );
				float3 lerpResult34 = lerp( UnpackNormalScale( tex2D( _NormalMap, uv_NormalMap ), 1.0f ) , unpack27 , saturate( ( tex2DNode16.r * 8.0 ) ));
				
				float2 uv_EmissionMap = IN.ase_texcoord7.xy * _EmissionMap_ST.xy + _EmissionMap_ST.zw;
				
				float2 uv_MetallicSmoothness = IN.ase_texcoord7.xy * _MetallicSmoothness_ST.xy + _MetallicSmoothness_ST.zw;
				float4 tex2DNode35 = tex2D( _MetallicSmoothness, uv_MetallicSmoothness );
				
				float vertexToFrag250_g1065 = IN.ase_texcoord7.z;
				
				float3 Albedo = tex2D( _BaseColorMap, uv_BaseColorMap ).rgb;
				float3 Normal = lerpResult34;
				float3 Emission = ( tex2D( _EmissionMap, uv_EmissionMap ) * _EmissionColor ).rgb;
				float3 Specular = 0.5;
				float Metallic = tex2DNode35.r;
				float Smoothness = tex2DNode35.a;
				float Occlusion = 1;
				float Alpha = vertexToFrag250_g1065;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;
				float3 BakedGI = 0;
				float3 RefractionColor = 1;
				float RefractionIndex = 1;
				float3 Transmission = 1;
				float3 Translucency = 1;
				#ifdef ASE_DEPTH_WRITE_ON
				float DepthValue = 0;
				#endif

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				InputData inputData;
				inputData.positionWS = WorldPosition;
				inputData.viewDirectionWS = WorldViewDirection;
				inputData.shadowCoord = ShadowCoords;

				#ifdef _NORMALMAP
					#if _NORMAL_DROPOFF_TS
					inputData.normalWS = TransformTangentToWorld(Normal, half3x3( WorldTangent, WorldBiTangent, WorldNormal ));
					#elif _NORMAL_DROPOFF_OS
					inputData.normalWS = TransformObjectToWorldNormal(Normal);
					#elif _NORMAL_DROPOFF_WS
					inputData.normalWS = Normal;
					#endif
					inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
				#else
					inputData.normalWS = WorldNormal;
				#endif

				#ifdef ASE_FOG
					inputData.fogCoord = IN.fogFactorAndVertexLight.x;
				#endif

				inputData.vertexLighting = IN.fogFactorAndVertexLight.yzw;
				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					float3 SH = SampleSH(inputData.normalWS.xyz);
				#else
					float3 SH = IN.lightmapUVOrVertexSH.xyz;
				#endif

				inputData.bakedGI = SAMPLE_GI( IN.lightmapUVOrVertexSH.xy, SH, inputData.normalWS );
				#ifdef _ASE_BAKEDGI
					inputData.bakedGI = BakedGI;
				#endif

				BRDFData brdfData;
				InitializeBRDFData( Albedo, Metallic, Specular, Smoothness, Alpha, brdfData);
				half4 color;
				color.rgb = GlobalIllumination( brdfData, inputData.bakedGI, Occlusion, inputData.normalWS, inputData.viewDirectionWS);
				color.a = Alpha;

				#ifdef _TRANSMISSION_ASE
				{
					float shadow = _TransmissionShadow;
				
					Light mainLight = GetMainLight( inputData.shadowCoord );
					float3 mainAtten = mainLight.color * mainLight.distanceAttenuation;
					mainAtten = lerp( mainAtten, mainAtten * mainLight.shadowAttenuation, shadow );
					half3 mainTransmission = max(0 , -dot(inputData.normalWS, mainLight.direction)) * mainAtten * Transmission;
					color.rgb += Albedo * mainTransmission;
				
					#ifdef _ADDITIONAL_LIGHTS
						int transPixelLightCount = GetAdditionalLightsCount();
						for (int i = 0; i < transPixelLightCount; ++i)
						{
							Light light = GetAdditionalLight(i, inputData.positionWS);
							float3 atten = light.color * light.distanceAttenuation;
							atten = lerp( atten, atten * light.shadowAttenuation, shadow );
				
							half3 transmission = max(0 , -dot(inputData.normalWS, light.direction)) * atten * Transmission;
							color.rgb += Albedo * transmission;
						}
					#endif
				}
				#endif
				
				#ifdef _TRANSLUCENCY_ASE
				{
					float shadow = _TransShadow;
					float normal = _TransNormal;
					float scattering = _TransScattering;
					float direct = _TransDirect;
					float ambient = _TransAmbient;
					float strength = _TransStrength;
				
					Light mainLight = GetMainLight( inputData.shadowCoord );
					float3 mainAtten = mainLight.color * mainLight.distanceAttenuation;
					mainAtten = lerp( mainAtten, mainAtten * mainLight.shadowAttenuation, shadow );
				
					half3 mainLightDir = mainLight.direction + inputData.normalWS * normal;
					half mainVdotL = pow( saturate( dot( inputData.viewDirectionWS, -mainLightDir ) ), scattering );
					half3 mainTranslucency = mainAtten * ( mainVdotL * direct + inputData.bakedGI * ambient ) * Translucency;
					color.rgb += Albedo * mainTranslucency * strength;
				
					#ifdef _ADDITIONAL_LIGHTS
						int transPixelLightCount = GetAdditionalLightsCount();
						for (int i = 0; i < transPixelLightCount; ++i)
						{
							Light light = GetAdditionalLight(i, inputData.positionWS);
							float3 atten = light.color * light.distanceAttenuation;
							atten = lerp( atten, atten * light.shadowAttenuation, shadow );
				
							half3 lightDir = light.direction + inputData.normalWS * normal;
							half VdotL = pow( saturate( dot( inputData.viewDirectionWS, -lightDir ) ), scattering );
							half3 translucency = atten * ( VdotL * direct + inputData.bakedGI * ambient ) * Translucency;
							color.rgb += Albedo * translucency * strength;
						}
					#endif
				}
				#endif
				
				#ifdef _REFRACTION_ASE
					float4 projScreenPos = ScreenPos / ScreenPos.w;
					float3 refractionOffset = ( RefractionIndex - 1.0 ) * mul( UNITY_MATRIX_V, float4( WorldNormal, 0 ) ).xyz * ( 1.0 - dot( WorldNormal, WorldViewDirection ) );
					projScreenPos.xy += refractionOffset.xy;
					float3 refraction = SHADERGRAPH_SAMPLE_SCENE_COLOR( projScreenPos.xy ) * RefractionColor;
					color.rgb = lerp( refraction, color.rgb, color.a );
					color.a = 1;
				#endif
				
				#ifdef ASE_FINAL_COLOR_ALPHA_MULTIPLY
					color.rgb *= color.a;
				#endif
				
				#ifdef ASE_FOG
					#ifdef TERRAIN_SPLAT_ADDPASS
						color.rgb = MixFogColor(color.rgb, half3( 0, 0, 0 ), IN.fogFactorAndVertexLight.x );
					#else
						color.rgb = MixFog(color.rgb, IN.fogFactorAndVertexLight.x);
					#endif
				#endif
				
				#ifdef ASE_DEPTH_WRITE_ON
					outputDepth = DepthValue;
				#endif
				
				return BRDFDataToGbuffer(brdfData, inputData, Smoothness, Emission + color.rgb);
			}

			ENDHLSL
		}
		
	}
	
	CustomEditor "UnityEditor.ShaderGraph.PBRMasterGUI"
	Fallback "Hidden/InternalErrorShader"
	
}
/*ASEBEGIN
Version=18935
44;658;2027;755;1964.245;-183.8261;1;True;True
Node;AmplifyShaderEditor.TextureCoordinatesNode;10;-3658.598,-553.4916;Inherit;False;1;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleTimeNode;12;-3433.376,-279.3965;Inherit;False;1;0;FLOAT;0.01;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;11;-3341.237,13.47651;Inherit;False;1;0;FLOAT;0.1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;14;-3188.976,-353.4966;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;13;-3161.387,-181.2224;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;15;-2709.458,-616.3365;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;16;-2651.594,-467.8983;Inherit;True;Property;_Foam;Foam;28;0;Create;True;0;0;0;False;0;False;-1;ca74d5c3c307fd44989092d53e4c194c;ca74d5c3c307fd44989092d53e4c194c;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.NormalVertexDataNode;19;-1946.276,705.3063;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VertexColorNode;17;-1530.486,815.8731;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;18;-1852.198,876.1707;Inherit;False;Property;_BulgeDistance;BulgeDistance;27;0;Create;True;0;0;0;False;0;False;1;0.25;0;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;20;-1658.279,580.767;Inherit;False;4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.PosVertexDataNode;21;-1638.493,406.77;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;23;-1426.493,425.77;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;29;-1298.751,598.8589;Inherit;False;JigglePhysicsSoftbody;-1;;1064;6ec46ef0369ac3449867136b98c25983;0;2;6;FLOAT3;0,0,0;False;10;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;22;-2245.858,185.623;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;8;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;24;-1928.552,82.33714;Inherit;False;Property;_EmissionColor;EmissionColor;26;0;Create;True;0;0;0;False;0;False;0,0,0,0;0,0,0,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;27;-2656.154,-239.9122;Inherit;True;Property;_FoamNormal;FoamNormal;29;0;Create;True;0;0;0;False;0;False;-1;None;578097abe8951ee4f9a7be3641f6633c;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;2;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;26;-2077.373,-310.1344;Inherit;True;Property;_NormalMap;NormalMap;24;0;Create;True;0;0;0;False;0;False;-1;None;c97cc752ef2fbda4187df653f2e6a012;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;25;-1513.56,-765.2394;Inherit;True;Property;_EmissionMap;_EmissionMap;30;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;33;-805.0193,711.1205;Inherit;False;3;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;28;-2168.556,90.72989;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;32;-945.4073,-320.9549;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.FunctionNode;8;-552.5,306.5;Inherit;False;PenetrationTechDeformation;0;;1065;cb4db099da64a8846a0c6877ff8e2b5f;0;3;253;FLOAT3;0,0,0;False;258;FLOAT3;0,0,0;False;265;FLOAT3;0,0,0;False;3;FLOAT3;0;FLOAT;251;FLOAT3;252
Node;AmplifyShaderEditor.LerpOp;34;-1417.345,-304.3614;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;35;-1378.038,68.86272;Inherit;True;Property;_MetallicSmoothness;MetallicSmoothness;25;0;Create;True;0;0;0;False;0;False;-1;None;49747107317e10747acf3e466d2f0a0f;True;0;False;gray;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;31;-2056.896,-549.1188;Inherit;True;Property;_BaseColorMap;BaseColorMap;23;0;Create;True;0;0;0;False;0;False;-1;None;0ca6ae9afa3ffa04b89dced1e09003a7;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;37;-233.7758,218.4553;Inherit;False;Constant;_Float5;Float 5;10;0;Create;True;0;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;0;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;0;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;3;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;True;False;False;False;False;0;False;-1;False;False;False;False;False;False;False;False;False;True;1;False;-1;False;False;True;1;LightMode=DepthOnly;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;2;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;True;False;False;False;False;0;False;-1;False;False;False;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;False;True;1;LightMode=ShadowCaster;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;0,0;Float;False;True;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;2;GooDickPenetrator;94348b07e5e8bab40bd6c8a1e3df54cd;True;Forward;0;1;Forward;18;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;2;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;1;False;-1;0;False;-1;1;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=UniversalForward;False;False;0;Hidden/InternalErrorShader;0;0;Standard;38;Workflow;1;0;Surface;0;0;  Refraction Model;0;0;  Blend;0;0;Two Sided;1;0;Fragment Normal Space,InvertActionOnDeselection;0;0;Transmission;0;0;  Transmission Shadow;0.5,False,-1;0;Translucency;0;0;  Translucency Strength;1,False,-1;0;  Normal Distortion;0.5,False,-1;0;  Scattering;2,False,-1;0;  Direct;0.9,False,-1;0;  Ambient;0.1,False,-1;0;  Shadow;0.5,False,-1;0;Cast Shadows;1;0;  Use Shadow Threshold;0;0;Receive Shadows;1;0;GPU Instancing;1;0;LOD CrossFade;1;0;Built-in Fog;1;0;_FinalColorxAlpha;0;0;Meta Pass;1;0;Override Baked GI;0;0;Extra Pre Pass;0;0;DOTS Instancing;0;0;Tessellation;0;0;  Phong;0;0;  Strength;0.5,False,-1;0;  Type;0;0;  Tess;16,False,-1;0;  Min;10,False,-1;0;  Max;25,False,-1;0;  Edge Length;16,False,-1;0;  Max Displacement;25,False,-1;0;Write Depth;0;0;  Early Z;0;0;Vertex Position,InvertActionOnDeselection;0;637823826717923759;0;8;False;True;True;True;True;True;True;True;False;;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;7;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;GBuffer;0;7;GBuffer;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;1;False;-1;0;False;-1;1;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=UniversalGBuffer;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;6;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;DepthNormals;0;6;DepthNormals;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;False;True;1;LightMode=DepthNormals;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;5;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;Universal2D;0;5;Universal2D;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;1;False;-1;0;False;-1;1;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=Universal2D;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;4;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
WireConnection;14;0;10;1
WireConnection;14;1;12;0
WireConnection;13;0;10;2
WireConnection;13;1;11;0
WireConnection;15;0;14;0
WireConnection;15;1;13;0
WireConnection;16;1;15;0
WireConnection;20;0;19;0
WireConnection;20;1;18;0
WireConnection;20;2;16;1
WireConnection;20;3;17;2
WireConnection;23;0;21;0
WireConnection;23;1;20;0
WireConnection;29;6;23;0
WireConnection;29;10;17;1
WireConnection;22;0;16;1
WireConnection;27;1;15;0
WireConnection;33;0;29;0
WireConnection;33;1;20;0
WireConnection;33;2;21;0
WireConnection;28;0;22;0
WireConnection;32;0;25;0
WireConnection;32;1;24;0
WireConnection;8;253;33;0
WireConnection;34;0;26;0
WireConnection;34;1;27;0
WireConnection;34;2;28;0
WireConnection;1;0;31;0
WireConnection;1;1;34;0
WireConnection;1;2;32;0
WireConnection;1;3;35;1
WireConnection;1;4;35;4
WireConnection;1;6;8;251
WireConnection;1;7;37;0
WireConnection;1;8;8;0
WireConnection;1;10;8;252
ASEEND*/
//CHKSM=41E7199E5FF9CB2E75577E331992A6F2E526EFF2