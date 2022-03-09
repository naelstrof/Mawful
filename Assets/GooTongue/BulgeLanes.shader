// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "BulgeLanes"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[ASEBegin]_BulgeLanes_output("BulgeLanes_output", 2D) = "white" {}
		_PenetratorOrigin("PenetratorOrigin", Vector) = (0,0,0,0)
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
		_GooTongue_TongueMaterial_AlbedoTransparency("GooTongue_TongueMaterial_AlbedoTransparency", 2D) = "white" {}
		_GooTongue_TongueMaterial_MetallicSmoothness("GooTongue_TongueMaterial_MetallicSmoothness", 2D) = "white" {}
		_GooTongue_TongueMaterial_Normal("GooTongue_TongueMaterial_Normal", 2D) = "bump" {}
		_BulgeAmount("BulgeAmount", Range( 0 , 1)) = 0.1911196
		_BulgeLanes_normal("BulgeLanes_normal", 2D) = "bump" {}
		[ASEEnd]_BulgeClip("BulgeClip", Range( 0 , 1)) = 0
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
			#define ASE_NEEDS_FRAG_WORLD_VIEW_DIR
			#define ASE_NEEDS_FRAG_WORLD_NORMAL


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord : TEXCOORD0;
				float4 ase_texcoord2 : TEXCOORD2;
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
			float4 _GooTongue_TongueMaterial_MetallicSmoothness_ST;
			float4 _GooTongue_TongueMaterial_Normal_ST;
			float4 _GooTongue_TongueMaterial_AlbedoTransparency_ST;
			float4 _BulgeLanes_normal_ST;
			float3 _PenetratorOrigin;
			float3 _OrificeWorldPosition;
			float3 _PenetratorUp;
			float3 _OrificeOutWorldPosition3;
			float3 _PenetratorForward;
			float3 _OrificeOutWorldPosition2;
			float3 _OrificeOutWorldPosition1;
			float3 _OrificeWorldNormal;
			float3 _PenetratorRight;
			float _DeformBalls;
			float _InvisibleWhenInside;
			float _ClipDick;
			float _NoBlendshapes;
			float _PinchBuffer;
			float _PenetratorCumActive;
			float _PenetratorCumProgress;
			float _PenetratorSquishPullAmount;
			float _PenetratorBulgePercentage;
			float _BulgeClip;
			float _BulgeAmount;
			float _PenetrationDepth;
			float _PenetratorLength;
			float _OrificeLength;
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
			sampler2D _BulgeLanes_output;
			sampler2D _GooTongue_TongueMaterial_AlbedoTransparency;
			sampler2D _GooTongue_TongueMaterial_Normal;
			sampler2D _BulgeLanes_normal;
			sampler2D _GooTongue_TongueMaterial_MetallicSmoothness;


			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 VertexNormal259_g1 = v.ase_normal;
				float3 normalizeResult27_g1062 = normalize( VertexNormal259_g1 );
				float3 temp_output_35_0_g1 = normalizeResult27_g1062;
				float3 normalizeResult31_g1062 = normalize( v.ase_tangent.xyz );
				float3 normalizeResult29_g1062 = normalize( cross( normalizeResult27_g1062 , normalizeResult31_g1062 ) );
				float3 temp_output_35_1_g1 = cross( normalizeResult29_g1062 , normalizeResult27_g1062 );
				float3 temp_output_35_2_g1 = normalizeResult29_g1062;
				float3 SquishDelta85_g1 = ( ( ( temp_output_35_0_g1 * v.ase_texcoord2.x ) + ( temp_output_35_1_g1 * v.ase_texcoord2.y ) + ( temp_output_35_2_g1 * v.ase_texcoord2.z ) ) * _PenetratorBlendshapeMultiplier );
				float temp_output_234_0_g1 = length( SquishDelta85_g1 );
				float temp_output_11_0_g1 = max( _PenetrationDepth , 0.0 );
				float VisibleLength25_g1 = ( _PenetratorLength * ( 1.0 - temp_output_11_0_g1 ) );
				float3 DickOrigin16_g1 = _PenetratorOrigin;
				float4 appendResult132_g1 = (float4(_OrificeWorldPosition , 1.0));
				float4 transform140_g1 = mul(GetWorldToObjectMatrix(),appendResult132_g1);
				float3 OrifacePosition170_g1 = (transform140_g1).xyz;
				float DickLength19_g1 = _PenetratorLength;
				float3 DickUp172_g1 = _PenetratorUp;
				float2 texCoord9 = v.texcoord1.xyzw.xy * float2( 1,0.5 ) + float2( 0,0 );
				float2 break17 = texCoord9;
				float mulTime16 = _TimeParameters.x * 0.08;
				float2 appendResult19 = (float2(break17.x , ( mulTime16 + break17.y )));
				float4 tex2DNode8 = tex2Dlod( _BulgeLanes_output, float4( appendResult19, 0, 0.0) );
				float2 texCoord41 = v.texcoord1.xyzw.xy * float2( 1,1 ) + float2( 0,0 );
				float temp_output_43_0 = saturate( sign( ( texCoord41.y - ( 1.0 - _BulgeClip ) ) ) );
				float3 VertexPosition254_g1 = ( ( v.ase_normal * tex2DNode8.r * _BulgeAmount * temp_output_43_0 ) + v.vertex.xyz );
				float3 temp_output_27_0_g1 = ( VertexPosition254_g1 - DickOrigin16_g1 );
				float3 DickForward18_g1 = _PenetratorForward;
				float dotResult42_g1 = dot( temp_output_27_0_g1 , DickForward18_g1 );
				float BulgePercentage37_g1 = _PenetratorBulgePercentage;
				float temp_output_1_0_g1056 = saturate( ( abs( ( dotResult42_g1 - VisibleLength25_g1 ) ) / ( DickLength19_g1 * BulgePercentage37_g1 ) ) );
				float temp_output_94_0_g1 = sqrt( ( 1.0 - ( temp_output_1_0_g1056 * temp_output_1_0_g1056 ) ) );
				float3 PullDelta91_g1 = ( ( ( temp_output_35_0_g1 * v.ase_texcoord3.x ) + ( temp_output_35_1_g1 * v.ase_texcoord3.y ) + ( temp_output_35_2_g1 * v.ase_texcoord3.z ) ) * _PenetratorBlendshapeMultiplier );
				float dotResult32_g1 = dot( temp_output_27_0_g1 , DickForward18_g1 );
				float temp_output_1_0_g1063 = saturate( ( abs( ( dotResult32_g1 - ( DickLength19_g1 * _PenetratorCumProgress ) ) ) / ( DickLength19_g1 * BulgePercentage37_g1 ) ) );
				float3 CumDelta90_g1 = ( ( ( temp_output_35_0_g1 * v.texcoord1.xyzw.w ) + ( temp_output_35_1_g1 * v.ase_texcoord2.w ) + ( temp_output_35_2_g1 * v.ase_texcoord3.w ) ) * _PenetratorBlendshapeMultiplier );
				float3 lerpResult410_g1 = lerp( ( VertexPosition254_g1 + ( SquishDelta85_g1 * temp_output_94_0_g1 * saturate( -_PenetratorSquishPullAmount ) ) + ( temp_output_94_0_g1 * PullDelta91_g1 * saturate( _PenetratorSquishPullAmount ) ) + ( sqrt( ( 1.0 - ( temp_output_1_0_g1063 * temp_output_1_0_g1063 ) ) ) * CumDelta90_g1 * _PenetratorCumActive ) ) , VertexPosition254_g1 , _NoBlendshapes);
				float3 originalPosition126_g1 = lerpResult410_g1;
				float dotResult118_g1 = dot( ( lerpResult410_g1 - DickOrigin16_g1 ) , DickForward18_g1 );
				float PenetrationDepth39_g1 = _PenetrationDepth;
				float temp_output_65_0_g1 = ( PenetrationDepth39_g1 * DickLength19_g1 );
				float OrifaceLength34_g1 = _OrificeLength;
				float temp_output_73_0_g1 = ( _PinchBuffer * OrifaceLength34_g1 );
				float dotResult80_g1 = dot( ( lerpResult410_g1 - DickOrigin16_g1 ) , DickForward18_g1 );
				float temp_output_112_0_g1 = ( -( ( ( temp_output_65_0_g1 - temp_output_73_0_g1 ) + dotResult80_g1 ) - DickLength19_g1 ) * 10.0 );
				float ClipDick413_g1 = _ClipDick;
				float lerpResult411_g1 = lerp( max( temp_output_112_0_g1 , ( ( ( temp_output_65_0_g1 + dotResult80_g1 + temp_output_73_0_g1 ) - ( OrifaceLength34_g1 + DickLength19_g1 ) ) * 10.0 ) ) , temp_output_112_0_g1 , ClipDick413_g1);
				float InsideLerp123_g1 = saturate( lerpResult411_g1 );
				float3 lerpResult124_g1 = lerp( ( ( DickForward18_g1 * dotResult118_g1 ) + DickOrigin16_g1 ) , originalPosition126_g1 , InsideLerp123_g1);
				float InvisibleWhenInside420_g1 = _InvisibleWhenInside;
				float3 lerpResult422_g1 = lerp( originalPosition126_g1 , lerpResult124_g1 , InvisibleWhenInside420_g1);
				float3 temp_output_354_0_g1 = ( lerpResult422_g1 - DickOrigin16_g1 );
				float dotResult373_g1 = dot( DickUp172_g1 , temp_output_354_0_g1 );
				float3 DickRight184_g1 = _PenetratorRight;
				float dotResult374_g1 = dot( DickRight184_g1 , temp_output_354_0_g1 );
				float dotResult375_g1 = dot( temp_output_354_0_g1 , DickForward18_g1 );
				float3 lerpResult343_g1 = lerp( ( ( ( saturate( ( ( VisibleLength25_g1 - distance( DickOrigin16_g1 , OrifacePosition170_g1 ) ) / DickLength19_g1 ) ) + 1.0 ) * dotResult373_g1 * DickUp172_g1 ) + ( ( saturate( ( ( VisibleLength25_g1 - distance( DickOrigin16_g1 , OrifacePosition170_g1 ) ) / DickLength19_g1 ) ) + 1.0 ) * dotResult374_g1 * DickRight184_g1 ) + ( DickForward18_g1 * dotResult375_g1 ) + DickOrigin16_g1 ) , lerpResult422_g1 , saturate( PenetrationDepth39_g1 ));
				float dotResult177_g1 = dot( ( lerpResult343_g1 - DickOrigin16_g1 ) , DickForward18_g1 );
				float temp_output_178_0_g1 = max( VisibleLength25_g1 , 0.05 );
				float temp_output_42_0_g1057 = ( dotResult177_g1 / temp_output_178_0_g1 );
				float temp_output_26_0_g1058 = temp_output_42_0_g1057;
				float temp_output_19_0_g1058 = ( 1.0 - temp_output_26_0_g1058 );
				float3 temp_output_8_0_g1057 = DickOrigin16_g1;
				float temp_output_393_0_g1 = distance( DickOrigin16_g1 , OrifacePosition170_g1 );
				float temp_output_396_0_g1 = min( temp_output_178_0_g1 , temp_output_393_0_g1 );
				float3 temp_output_9_0_g1057 = ( DickOrigin16_g1 + ( DickForward18_g1 * temp_output_396_0_g1 * 0.25 ) );
				float4 appendResult130_g1 = (float4(_OrificeWorldNormal , 0.0));
				float4 transform135_g1 = mul(GetWorldToObjectMatrix(),appendResult130_g1);
				float3 OrifaceNormal155_g1 = (transform135_g1).xyz;
				float3 temp_output_10_0_g1057 = ( OrifacePosition170_g1 + ( OrifaceNormal155_g1 * 0.25 * temp_output_396_0_g1 ) );
				float3 temp_output_11_0_g1057 = OrifacePosition170_g1;
				float temp_output_1_0_g1060 = temp_output_42_0_g1057;
				float temp_output_8_0_g1060 = ( 1.0 - temp_output_1_0_g1060 );
				float3 temp_output_3_0_g1060 = temp_output_9_0_g1057;
				float3 temp_output_4_0_g1060 = temp_output_10_0_g1057;
				float3 temp_output_7_0_g1059 = ( ( 3.0 * temp_output_8_0_g1060 * temp_output_8_0_g1060 * ( temp_output_3_0_g1060 - temp_output_8_0_g1057 ) ) + ( 6.0 * temp_output_8_0_g1060 * temp_output_1_0_g1060 * ( temp_output_4_0_g1060 - temp_output_3_0_g1060 ) ) + ( 3.0 * temp_output_1_0_g1060 * temp_output_1_0_g1060 * ( temp_output_11_0_g1057 - temp_output_4_0_g1060 ) ) );
				float3 normalizeResult27_g1061 = normalize( temp_output_7_0_g1059 );
				float3 temp_output_4_0_g1057 = DickUp172_g1;
				float3 temp_output_10_0_g1059 = temp_output_4_0_g1057;
				float3 temp_output_3_0_g1057 = DickForward18_g1;
				float3 temp_output_13_0_g1059 = temp_output_3_0_g1057;
				float dotResult33_g1059 = dot( temp_output_7_0_g1059 , temp_output_10_0_g1059 );
				float3 lerpResult34_g1059 = lerp( temp_output_10_0_g1059 , -temp_output_13_0_g1059 , saturate( dotResult33_g1059 ));
				float dotResult37_g1059 = dot( temp_output_7_0_g1059 , -temp_output_10_0_g1059 );
				float3 lerpResult40_g1059 = lerp( lerpResult34_g1059 , temp_output_13_0_g1059 , saturate( dotResult37_g1059 ));
				float3 normalizeResult42_g1059 = normalize( lerpResult40_g1059 );
				float3 normalizeResult31_g1061 = normalize( normalizeResult42_g1059 );
				float3 normalizeResult29_g1061 = normalize( cross( normalizeResult27_g1061 , normalizeResult31_g1061 ) );
				float3 temp_output_65_22_g1057 = normalizeResult29_g1061;
				float3 temp_output_2_0_g1057 = ( lerpResult343_g1 - DickOrigin16_g1 );
				float3 temp_output_5_0_g1057 = DickRight184_g1;
				float dotResult15_g1057 = dot( temp_output_2_0_g1057 , temp_output_5_0_g1057 );
				float3 temp_output_65_0_g1057 = cross( normalizeResult29_g1061 , normalizeResult27_g1061 );
				float dotResult18_g1057 = dot( temp_output_2_0_g1057 , temp_output_4_0_g1057 );
				float dotResult142_g1 = dot( ( lerpResult343_g1 - DickOrigin16_g1 ) , DickForward18_g1 );
				float temp_output_152_0_g1 = ( dotResult142_g1 - VisibleLength25_g1 );
				float temp_output_157_0_g1 = ( temp_output_152_0_g1 / OrifaceLength34_g1 );
				float lerpResult416_g1 = lerp( temp_output_157_0_g1 , min( temp_output_157_0_g1 , 1.0 ) , ClipDick413_g1);
				float temp_output_42_0_g1047 = lerpResult416_g1;
				float temp_output_26_0_g1048 = temp_output_42_0_g1047;
				float temp_output_19_0_g1048 = ( 1.0 - temp_output_26_0_g1048 );
				float3 temp_output_8_0_g1047 = OrifacePosition170_g1;
				float4 appendResult145_g1 = (float4(_OrificeOutWorldPosition1 , 1.0));
				float4 transform151_g1 = mul(GetWorldToObjectMatrix(),appendResult145_g1);
				float3 OrifaceOutPosition1183_g1 = (transform151_g1).xyz;
				float3 temp_output_9_0_g1047 = OrifaceOutPosition1183_g1;
				float4 appendResult144_g1 = (float4(_OrificeOutWorldPosition2 , 1.0));
				float4 transform154_g1 = mul(GetWorldToObjectMatrix(),appendResult144_g1);
				float3 OrifaceOutPosition2182_g1 = (transform154_g1).xyz;
				float3 temp_output_10_0_g1047 = OrifaceOutPosition2182_g1;
				float4 appendResult143_g1 = (float4(_OrificeOutWorldPosition3 , 1.0));
				float4 transform147_g1 = mul(GetWorldToObjectMatrix(),appendResult143_g1);
				float3 OrifaceOutPosition3175_g1 = (transform147_g1).xyz;
				float3 temp_output_11_0_g1047 = OrifaceOutPosition3175_g1;
				float temp_output_1_0_g1050 = temp_output_42_0_g1047;
				float temp_output_8_0_g1050 = ( 1.0 - temp_output_1_0_g1050 );
				float3 temp_output_3_0_g1050 = temp_output_9_0_g1047;
				float3 temp_output_4_0_g1050 = temp_output_10_0_g1047;
				float3 temp_output_7_0_g1049 = ( ( 3.0 * temp_output_8_0_g1050 * temp_output_8_0_g1050 * ( temp_output_3_0_g1050 - temp_output_8_0_g1047 ) ) + ( 6.0 * temp_output_8_0_g1050 * temp_output_1_0_g1050 * ( temp_output_4_0_g1050 - temp_output_3_0_g1050 ) ) + ( 3.0 * temp_output_1_0_g1050 * temp_output_1_0_g1050 * ( temp_output_11_0_g1047 - temp_output_4_0_g1050 ) ) );
				float3 normalizeResult27_g1051 = normalize( temp_output_7_0_g1049 );
				float3 temp_output_4_0_g1047 = DickUp172_g1;
				float3 temp_output_10_0_g1049 = temp_output_4_0_g1047;
				float3 temp_output_3_0_g1047 = DickForward18_g1;
				float3 temp_output_13_0_g1049 = temp_output_3_0_g1047;
				float dotResult33_g1049 = dot( temp_output_7_0_g1049 , temp_output_10_0_g1049 );
				float3 lerpResult34_g1049 = lerp( temp_output_10_0_g1049 , -temp_output_13_0_g1049 , saturate( dotResult33_g1049 ));
				float dotResult37_g1049 = dot( temp_output_7_0_g1049 , -temp_output_10_0_g1049 );
				float3 lerpResult40_g1049 = lerp( lerpResult34_g1049 , temp_output_13_0_g1049 , saturate( dotResult37_g1049 ));
				float3 normalizeResult42_g1049 = normalize( lerpResult40_g1049 );
				float3 normalizeResult31_g1051 = normalize( normalizeResult42_g1049 );
				float3 normalizeResult29_g1051 = normalize( cross( normalizeResult27_g1051 , normalizeResult31_g1051 ) );
				float3 temp_output_65_22_g1047 = normalizeResult29_g1051;
				float3 temp_output_2_0_g1047 = ( lerpResult343_g1 - DickOrigin16_g1 );
				float3 temp_output_5_0_g1047 = DickRight184_g1;
				float dotResult15_g1047 = dot( temp_output_2_0_g1047 , temp_output_5_0_g1047 );
				float3 temp_output_65_0_g1047 = cross( normalizeResult29_g1051 , normalizeResult27_g1051 );
				float dotResult18_g1047 = dot( temp_output_2_0_g1047 , temp_output_4_0_g1047 );
				float temp_output_208_0_g1 = saturate( sign( temp_output_152_0_g1 ) );
				float3 lerpResult221_g1 = lerp( ( ( ( temp_output_19_0_g1058 * temp_output_19_0_g1058 * temp_output_19_0_g1058 * temp_output_8_0_g1057 ) + ( temp_output_19_0_g1058 * temp_output_19_0_g1058 * 3.0 * temp_output_26_0_g1058 * temp_output_9_0_g1057 ) + ( 3.0 * temp_output_19_0_g1058 * temp_output_26_0_g1058 * temp_output_26_0_g1058 * temp_output_10_0_g1057 ) + ( temp_output_26_0_g1058 * temp_output_26_0_g1058 * temp_output_26_0_g1058 * temp_output_11_0_g1057 ) ) + ( temp_output_65_22_g1057 * dotResult15_g1057 ) + ( temp_output_65_0_g1057 * dotResult18_g1057 ) ) , ( ( ( temp_output_19_0_g1048 * temp_output_19_0_g1048 * temp_output_19_0_g1048 * temp_output_8_0_g1047 ) + ( temp_output_19_0_g1048 * temp_output_19_0_g1048 * 3.0 * temp_output_26_0_g1048 * temp_output_9_0_g1047 ) + ( 3.0 * temp_output_19_0_g1048 * temp_output_26_0_g1048 * temp_output_26_0_g1048 * temp_output_10_0_g1047 ) + ( temp_output_26_0_g1048 * temp_output_26_0_g1048 * temp_output_26_0_g1048 * temp_output_11_0_g1047 ) ) + ( temp_output_65_22_g1047 * dotResult15_g1047 ) + ( temp_output_65_0_g1047 * dotResult18_g1047 ) ) , temp_output_208_0_g1);
				float3 temp_output_42_0_g1052 = DickForward18_g1;
				float NonVisibleLength165_g1 = ( temp_output_11_0_g1 * _PenetratorLength );
				float3 temp_output_52_0_g1052 = ( ( temp_output_42_0_g1052 * ( ( NonVisibleLength165_g1 - OrifaceLength34_g1 ) - DickLength19_g1 ) ) + ( lerpResult343_g1 - DickOrigin16_g1 ) );
				float dotResult53_g1052 = dot( temp_output_42_0_g1052 , temp_output_52_0_g1052 );
				float temp_output_1_0_g1054 = 1.0;
				float temp_output_8_0_g1054 = ( 1.0 - temp_output_1_0_g1054 );
				float3 temp_output_3_0_g1054 = OrifaceOutPosition1183_g1;
				float3 temp_output_4_0_g1054 = OrifaceOutPosition2182_g1;
				float3 temp_output_7_0_g1053 = ( ( 3.0 * temp_output_8_0_g1054 * temp_output_8_0_g1054 * ( temp_output_3_0_g1054 - OrifacePosition170_g1 ) ) + ( 6.0 * temp_output_8_0_g1054 * temp_output_1_0_g1054 * ( temp_output_4_0_g1054 - temp_output_3_0_g1054 ) ) + ( 3.0 * temp_output_1_0_g1054 * temp_output_1_0_g1054 * ( OrifaceOutPosition3175_g1 - temp_output_4_0_g1054 ) ) );
				float3 normalizeResult27_g1055 = normalize( temp_output_7_0_g1053 );
				float3 temp_output_85_23_g1052 = normalizeResult27_g1055;
				float3 temp_output_4_0_g1052 = DickUp172_g1;
				float dotResult54_g1052 = dot( temp_output_4_0_g1052 , temp_output_52_0_g1052 );
				float3 temp_output_10_0_g1053 = temp_output_4_0_g1052;
				float3 temp_output_13_0_g1053 = temp_output_42_0_g1052;
				float dotResult33_g1053 = dot( temp_output_7_0_g1053 , temp_output_10_0_g1053 );
				float3 lerpResult34_g1053 = lerp( temp_output_10_0_g1053 , -temp_output_13_0_g1053 , saturate( dotResult33_g1053 ));
				float dotResult37_g1053 = dot( temp_output_7_0_g1053 , -temp_output_10_0_g1053 );
				float3 lerpResult40_g1053 = lerp( lerpResult34_g1053 , temp_output_13_0_g1053 , saturate( dotResult37_g1053 ));
				float3 normalizeResult42_g1053 = normalize( lerpResult40_g1053 );
				float3 normalizeResult31_g1055 = normalize( normalizeResult42_g1053 );
				float3 normalizeResult29_g1055 = normalize( cross( normalizeResult27_g1055 , normalizeResult31_g1055 ) );
				float3 temp_output_85_0_g1052 = cross( normalizeResult29_g1055 , normalizeResult27_g1055 );
				float3 temp_output_43_0_g1052 = DickRight184_g1;
				float dotResult55_g1052 = dot( temp_output_43_0_g1052 , temp_output_52_0_g1052 );
				float3 temp_output_85_22_g1052 = normalizeResult29_g1055;
				float temp_output_222_0_g1 = saturate( sign( ( temp_output_157_0_g1 - 1.0 ) ) );
				float3 lerpResult224_g1 = lerp( lerpResult221_g1 , ( ( ( dotResult53_g1052 * temp_output_85_23_g1052 ) + ( dotResult54_g1052 * temp_output_85_0_g1052 ) + ( dotResult55_g1052 * temp_output_85_22_g1052 ) ) + OrifaceOutPosition3175_g1 ) , temp_output_222_0_g1);
				float3 lerpResult418_g1 = lerp( lerpResult224_g1 , lerpResult221_g1 , ClipDick413_g1);
				float temp_output_226_0_g1 = saturate( -PenetrationDepth39_g1 );
				float3 lerpResult232_g1 = lerp( lerpResult418_g1 , originalPosition126_g1 , temp_output_226_0_g1);
				float3 ifLocalVar237_g1 = 0;
				if( temp_output_234_0_g1 <= 0.0 )
				ifLocalVar237_g1 = originalPosition126_g1;
				else
				ifLocalVar237_g1 = lerpResult232_g1;
				float DeformBalls426_g1 = _DeformBalls;
				float3 lerpResult428_g1 = lerp( ifLocalVar237_g1 , lerpResult232_g1 , DeformBalls426_g1);
				
				float3 temp_output_21_0_g1057 = VertexNormal259_g1;
				float dotResult55_g1057 = dot( temp_output_21_0_g1057 , temp_output_3_0_g1057 );
				float dotResult56_g1057 = dot( temp_output_21_0_g1057 , temp_output_4_0_g1057 );
				float dotResult57_g1057 = dot( temp_output_21_0_g1057 , temp_output_5_0_g1057 );
				float3 normalizeResult31_g1057 = normalize( ( ( dotResult55_g1057 * normalizeResult27_g1061 ) + ( dotResult56_g1057 * temp_output_65_0_g1057 ) + ( dotResult57_g1057 * temp_output_65_22_g1057 ) ) );
				float3 temp_output_21_0_g1047 = VertexNormal259_g1;
				float dotResult55_g1047 = dot( temp_output_21_0_g1047 , temp_output_3_0_g1047 );
				float dotResult56_g1047 = dot( temp_output_21_0_g1047 , temp_output_4_0_g1047 );
				float dotResult57_g1047 = dot( temp_output_21_0_g1047 , temp_output_5_0_g1047 );
				float3 normalizeResult31_g1047 = normalize( ( ( dotResult55_g1047 * normalizeResult27_g1051 ) + ( dotResult56_g1047 * temp_output_65_0_g1047 ) + ( dotResult57_g1047 * temp_output_65_22_g1047 ) ) );
				float3 lerpResult227_g1 = lerp( normalizeResult31_g1057 , normalizeResult31_g1047 , temp_output_208_0_g1);
				float3 temp_output_24_0_g1052 = VertexNormal259_g1;
				float dotResult61_g1052 = dot( temp_output_42_0_g1052 , temp_output_24_0_g1052 );
				float dotResult62_g1052 = dot( temp_output_4_0_g1052 , temp_output_24_0_g1052 );
				float dotResult60_g1052 = dot( temp_output_43_0_g1052 , temp_output_24_0_g1052 );
				float3 normalizeResult33_g1052 = normalize( ( ( dotResult61_g1052 * temp_output_85_23_g1052 ) + ( dotResult62_g1052 * temp_output_85_0_g1052 ) + ( dotResult60_g1052 * temp_output_85_22_g1052 ) ) );
				float3 lerpResult233_g1 = lerp( lerpResult227_g1 , normalizeResult33_g1052 , temp_output_222_0_g1);
				float3 lerpResult419_g1 = lerp( lerpResult233_g1 , lerpResult227_g1 , ClipDick413_g1);
				float3 lerpResult238_g1 = lerp( lerpResult419_g1 , VertexNormal259_g1 , temp_output_226_0_g1);
				float3 ifLocalVar391_g1 = 0;
				if( temp_output_234_0_g1 <= 0.0 )
				ifLocalVar391_g1 = VertexNormal259_g1;
				else
				ifLocalVar391_g1 = lerpResult238_g1;
				
				float lerpResult424_g1 = lerp( 1.0 , InsideLerp123_g1 , InvisibleWhenInside420_g1);
				float vertexToFrag250_g1 = lerpResult424_g1;
				o.ase_texcoord7.z = vertexToFrag250_g1;
				
				o.ase_texcoord7.xy = v.texcoord.xy;
				o.ase_texcoord8 = v.texcoord1.xyzw;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord7.w = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = lerpResult428_g1;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.ase_normal = ifLocalVar391_g1;

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

				float2 uv_GooTongue_TongueMaterial_AlbedoTransparency = IN.ase_texcoord7.xy * _GooTongue_TongueMaterial_AlbedoTransparency_ST.xy + _GooTongue_TongueMaterial_AlbedoTransparency_ST.zw;
				
				float2 uv_GooTongue_TongueMaterial_Normal = IN.ase_texcoord7.xy * _GooTongue_TongueMaterial_Normal_ST.xy + _GooTongue_TongueMaterial_Normal_ST.zw;
				float2 uv_BulgeLanes_normal = IN.ase_texcoord7.xy * _BulgeLanes_normal_ST.xy + _BulgeLanes_normal_ST.zw;
				float3 unpack29 = UnpackNormalScale( tex2D( _BulgeLanes_normal, uv_BulgeLanes_normal ), 2.0 );
				unpack29.z = lerp( 1, unpack29.z, saturate(2.0) );
				float2 texCoord9 = IN.ase_texcoord8.xy * float2( 1,0.5 ) + float2( 0,0 );
				float2 break17 = texCoord9;
				float mulTime16 = _TimeParameters.x * 0.08;
				float2 appendResult19 = (float2(break17.x , ( mulTime16 + break17.y )));
				float4 tex2DNode8 = tex2D( _BulgeLanes_output, appendResult19 );
				float3 lerpResult30 = lerp( UnpackNormalScale( tex2D( _GooTongue_TongueMaterial_Normal, uv_GooTongue_TongueMaterial_Normal ), 1.0f ) , unpack29 , tex2DNode8.r);
				
				float4 color37 = IsGammaSpace() ? float4(0.6033356,0.1512549,0.9716981,1) : float4(0.322454,0.01989593,0.9368213,1);
				float dotResult31 = dot( WorldViewDirection , WorldNormal );
				float2 texCoord41 = IN.ase_texcoord8.xy * float2( 1,1 ) + float2( 0,0 );
				float temp_output_43_0 = saturate( sign( ( texCoord41.y - ( 1.0 - _BulgeClip ) ) ) );
				float4 lerpResult36 = lerp( float4( 0,0,0,0 ) , color37 , ( abs( dotResult31 ) * tex2DNode8.r * temp_output_43_0 ));
				
				float2 uv_GooTongue_TongueMaterial_MetallicSmoothness = IN.ase_texcoord7.xy * _GooTongue_TongueMaterial_MetallicSmoothness_ST.xy + _GooTongue_TongueMaterial_MetallicSmoothness_ST.zw;
				float4 tex2DNode13 = tex2D( _GooTongue_TongueMaterial_MetallicSmoothness, uv_GooTongue_TongueMaterial_MetallicSmoothness );
				
				float vertexToFrag250_g1 = IN.ase_texcoord7.z;
				
				float3 Albedo = tex2D( _GooTongue_TongueMaterial_AlbedoTransparency, uv_GooTongue_TongueMaterial_AlbedoTransparency ).rgb;
				float3 Normal = lerpResult30;
				float3 Emission = lerpResult36.rgb;
				float3 Specular = 0.5;
				float Metallic = tex2DNode13.r;
				float Smoothness = tex2DNode13.a;
				float Occlusion = 1;
				float Alpha = vertexToFrag250_g1;
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
			float4 _GooTongue_TongueMaterial_MetallicSmoothness_ST;
			float4 _GooTongue_TongueMaterial_Normal_ST;
			float4 _GooTongue_TongueMaterial_AlbedoTransparency_ST;
			float4 _BulgeLanes_normal_ST;
			float3 _PenetratorOrigin;
			float3 _OrificeWorldPosition;
			float3 _PenetratorUp;
			float3 _OrificeOutWorldPosition3;
			float3 _PenetratorForward;
			float3 _OrificeOutWorldPosition2;
			float3 _OrificeOutWorldPosition1;
			float3 _OrificeWorldNormal;
			float3 _PenetratorRight;
			float _DeformBalls;
			float _InvisibleWhenInside;
			float _ClipDick;
			float _NoBlendshapes;
			float _PinchBuffer;
			float _PenetratorCumActive;
			float _PenetratorCumProgress;
			float _PenetratorSquishPullAmount;
			float _PenetratorBulgePercentage;
			float _BulgeClip;
			float _BulgeAmount;
			float _PenetrationDepth;
			float _PenetratorLength;
			float _OrificeLength;
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
			sampler2D _BulgeLanes_output;


			
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

				float3 VertexNormal259_g1 = v.ase_normal;
				float3 normalizeResult27_g1062 = normalize( VertexNormal259_g1 );
				float3 temp_output_35_0_g1 = normalizeResult27_g1062;
				float3 normalizeResult31_g1062 = normalize( v.ase_tangent.xyz );
				float3 normalizeResult29_g1062 = normalize( cross( normalizeResult27_g1062 , normalizeResult31_g1062 ) );
				float3 temp_output_35_1_g1 = cross( normalizeResult29_g1062 , normalizeResult27_g1062 );
				float3 temp_output_35_2_g1 = normalizeResult29_g1062;
				float3 SquishDelta85_g1 = ( ( ( temp_output_35_0_g1 * v.ase_texcoord2.x ) + ( temp_output_35_1_g1 * v.ase_texcoord2.y ) + ( temp_output_35_2_g1 * v.ase_texcoord2.z ) ) * _PenetratorBlendshapeMultiplier );
				float temp_output_234_0_g1 = length( SquishDelta85_g1 );
				float temp_output_11_0_g1 = max( _PenetrationDepth , 0.0 );
				float VisibleLength25_g1 = ( _PenetratorLength * ( 1.0 - temp_output_11_0_g1 ) );
				float3 DickOrigin16_g1 = _PenetratorOrigin;
				float4 appendResult132_g1 = (float4(_OrificeWorldPosition , 1.0));
				float4 transform140_g1 = mul(GetWorldToObjectMatrix(),appendResult132_g1);
				float3 OrifacePosition170_g1 = (transform140_g1).xyz;
				float DickLength19_g1 = _PenetratorLength;
				float3 DickUp172_g1 = _PenetratorUp;
				float2 texCoord9 = v.ase_texcoord1 * float2( 1,0.5 ) + float2( 0,0 );
				float2 break17 = texCoord9;
				float mulTime16 = _TimeParameters.x * 0.08;
				float2 appendResult19 = (float2(break17.x , ( mulTime16 + break17.y )));
				float4 tex2DNode8 = tex2Dlod( _BulgeLanes_output, float4( appendResult19, 0, 0.0) );
				float2 texCoord41 = v.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float temp_output_43_0 = saturate( sign( ( texCoord41.y - ( 1.0 - _BulgeClip ) ) ) );
				float3 VertexPosition254_g1 = ( ( v.ase_normal * tex2DNode8.r * _BulgeAmount * temp_output_43_0 ) + v.vertex.xyz );
				float3 temp_output_27_0_g1 = ( VertexPosition254_g1 - DickOrigin16_g1 );
				float3 DickForward18_g1 = _PenetratorForward;
				float dotResult42_g1 = dot( temp_output_27_0_g1 , DickForward18_g1 );
				float BulgePercentage37_g1 = _PenetratorBulgePercentage;
				float temp_output_1_0_g1056 = saturate( ( abs( ( dotResult42_g1 - VisibleLength25_g1 ) ) / ( DickLength19_g1 * BulgePercentage37_g1 ) ) );
				float temp_output_94_0_g1 = sqrt( ( 1.0 - ( temp_output_1_0_g1056 * temp_output_1_0_g1056 ) ) );
				float3 PullDelta91_g1 = ( ( ( temp_output_35_0_g1 * v.ase_texcoord3.x ) + ( temp_output_35_1_g1 * v.ase_texcoord3.y ) + ( temp_output_35_2_g1 * v.ase_texcoord3.z ) ) * _PenetratorBlendshapeMultiplier );
				float dotResult32_g1 = dot( temp_output_27_0_g1 , DickForward18_g1 );
				float temp_output_1_0_g1063 = saturate( ( abs( ( dotResult32_g1 - ( DickLength19_g1 * _PenetratorCumProgress ) ) ) / ( DickLength19_g1 * BulgePercentage37_g1 ) ) );
				float3 CumDelta90_g1 = ( ( ( temp_output_35_0_g1 * v.ase_texcoord1.w ) + ( temp_output_35_1_g1 * v.ase_texcoord2.w ) + ( temp_output_35_2_g1 * v.ase_texcoord3.w ) ) * _PenetratorBlendshapeMultiplier );
				float3 lerpResult410_g1 = lerp( ( VertexPosition254_g1 + ( SquishDelta85_g1 * temp_output_94_0_g1 * saturate( -_PenetratorSquishPullAmount ) ) + ( temp_output_94_0_g1 * PullDelta91_g1 * saturate( _PenetratorSquishPullAmount ) ) + ( sqrt( ( 1.0 - ( temp_output_1_0_g1063 * temp_output_1_0_g1063 ) ) ) * CumDelta90_g1 * _PenetratorCumActive ) ) , VertexPosition254_g1 , _NoBlendshapes);
				float3 originalPosition126_g1 = lerpResult410_g1;
				float dotResult118_g1 = dot( ( lerpResult410_g1 - DickOrigin16_g1 ) , DickForward18_g1 );
				float PenetrationDepth39_g1 = _PenetrationDepth;
				float temp_output_65_0_g1 = ( PenetrationDepth39_g1 * DickLength19_g1 );
				float OrifaceLength34_g1 = _OrificeLength;
				float temp_output_73_0_g1 = ( _PinchBuffer * OrifaceLength34_g1 );
				float dotResult80_g1 = dot( ( lerpResult410_g1 - DickOrigin16_g1 ) , DickForward18_g1 );
				float temp_output_112_0_g1 = ( -( ( ( temp_output_65_0_g1 - temp_output_73_0_g1 ) + dotResult80_g1 ) - DickLength19_g1 ) * 10.0 );
				float ClipDick413_g1 = _ClipDick;
				float lerpResult411_g1 = lerp( max( temp_output_112_0_g1 , ( ( ( temp_output_65_0_g1 + dotResult80_g1 + temp_output_73_0_g1 ) - ( OrifaceLength34_g1 + DickLength19_g1 ) ) * 10.0 ) ) , temp_output_112_0_g1 , ClipDick413_g1);
				float InsideLerp123_g1 = saturate( lerpResult411_g1 );
				float3 lerpResult124_g1 = lerp( ( ( DickForward18_g1 * dotResult118_g1 ) + DickOrigin16_g1 ) , originalPosition126_g1 , InsideLerp123_g1);
				float InvisibleWhenInside420_g1 = _InvisibleWhenInside;
				float3 lerpResult422_g1 = lerp( originalPosition126_g1 , lerpResult124_g1 , InvisibleWhenInside420_g1);
				float3 temp_output_354_0_g1 = ( lerpResult422_g1 - DickOrigin16_g1 );
				float dotResult373_g1 = dot( DickUp172_g1 , temp_output_354_0_g1 );
				float3 DickRight184_g1 = _PenetratorRight;
				float dotResult374_g1 = dot( DickRight184_g1 , temp_output_354_0_g1 );
				float dotResult375_g1 = dot( temp_output_354_0_g1 , DickForward18_g1 );
				float3 lerpResult343_g1 = lerp( ( ( ( saturate( ( ( VisibleLength25_g1 - distance( DickOrigin16_g1 , OrifacePosition170_g1 ) ) / DickLength19_g1 ) ) + 1.0 ) * dotResult373_g1 * DickUp172_g1 ) + ( ( saturate( ( ( VisibleLength25_g1 - distance( DickOrigin16_g1 , OrifacePosition170_g1 ) ) / DickLength19_g1 ) ) + 1.0 ) * dotResult374_g1 * DickRight184_g1 ) + ( DickForward18_g1 * dotResult375_g1 ) + DickOrigin16_g1 ) , lerpResult422_g1 , saturate( PenetrationDepth39_g1 ));
				float dotResult177_g1 = dot( ( lerpResult343_g1 - DickOrigin16_g1 ) , DickForward18_g1 );
				float temp_output_178_0_g1 = max( VisibleLength25_g1 , 0.05 );
				float temp_output_42_0_g1057 = ( dotResult177_g1 / temp_output_178_0_g1 );
				float temp_output_26_0_g1058 = temp_output_42_0_g1057;
				float temp_output_19_0_g1058 = ( 1.0 - temp_output_26_0_g1058 );
				float3 temp_output_8_0_g1057 = DickOrigin16_g1;
				float temp_output_393_0_g1 = distance( DickOrigin16_g1 , OrifacePosition170_g1 );
				float temp_output_396_0_g1 = min( temp_output_178_0_g1 , temp_output_393_0_g1 );
				float3 temp_output_9_0_g1057 = ( DickOrigin16_g1 + ( DickForward18_g1 * temp_output_396_0_g1 * 0.25 ) );
				float4 appendResult130_g1 = (float4(_OrificeWorldNormal , 0.0));
				float4 transform135_g1 = mul(GetWorldToObjectMatrix(),appendResult130_g1);
				float3 OrifaceNormal155_g1 = (transform135_g1).xyz;
				float3 temp_output_10_0_g1057 = ( OrifacePosition170_g1 + ( OrifaceNormal155_g1 * 0.25 * temp_output_396_0_g1 ) );
				float3 temp_output_11_0_g1057 = OrifacePosition170_g1;
				float temp_output_1_0_g1060 = temp_output_42_0_g1057;
				float temp_output_8_0_g1060 = ( 1.0 - temp_output_1_0_g1060 );
				float3 temp_output_3_0_g1060 = temp_output_9_0_g1057;
				float3 temp_output_4_0_g1060 = temp_output_10_0_g1057;
				float3 temp_output_7_0_g1059 = ( ( 3.0 * temp_output_8_0_g1060 * temp_output_8_0_g1060 * ( temp_output_3_0_g1060 - temp_output_8_0_g1057 ) ) + ( 6.0 * temp_output_8_0_g1060 * temp_output_1_0_g1060 * ( temp_output_4_0_g1060 - temp_output_3_0_g1060 ) ) + ( 3.0 * temp_output_1_0_g1060 * temp_output_1_0_g1060 * ( temp_output_11_0_g1057 - temp_output_4_0_g1060 ) ) );
				float3 normalizeResult27_g1061 = normalize( temp_output_7_0_g1059 );
				float3 temp_output_4_0_g1057 = DickUp172_g1;
				float3 temp_output_10_0_g1059 = temp_output_4_0_g1057;
				float3 temp_output_3_0_g1057 = DickForward18_g1;
				float3 temp_output_13_0_g1059 = temp_output_3_0_g1057;
				float dotResult33_g1059 = dot( temp_output_7_0_g1059 , temp_output_10_0_g1059 );
				float3 lerpResult34_g1059 = lerp( temp_output_10_0_g1059 , -temp_output_13_0_g1059 , saturate( dotResult33_g1059 ));
				float dotResult37_g1059 = dot( temp_output_7_0_g1059 , -temp_output_10_0_g1059 );
				float3 lerpResult40_g1059 = lerp( lerpResult34_g1059 , temp_output_13_0_g1059 , saturate( dotResult37_g1059 ));
				float3 normalizeResult42_g1059 = normalize( lerpResult40_g1059 );
				float3 normalizeResult31_g1061 = normalize( normalizeResult42_g1059 );
				float3 normalizeResult29_g1061 = normalize( cross( normalizeResult27_g1061 , normalizeResult31_g1061 ) );
				float3 temp_output_65_22_g1057 = normalizeResult29_g1061;
				float3 temp_output_2_0_g1057 = ( lerpResult343_g1 - DickOrigin16_g1 );
				float3 temp_output_5_0_g1057 = DickRight184_g1;
				float dotResult15_g1057 = dot( temp_output_2_0_g1057 , temp_output_5_0_g1057 );
				float3 temp_output_65_0_g1057 = cross( normalizeResult29_g1061 , normalizeResult27_g1061 );
				float dotResult18_g1057 = dot( temp_output_2_0_g1057 , temp_output_4_0_g1057 );
				float dotResult142_g1 = dot( ( lerpResult343_g1 - DickOrigin16_g1 ) , DickForward18_g1 );
				float temp_output_152_0_g1 = ( dotResult142_g1 - VisibleLength25_g1 );
				float temp_output_157_0_g1 = ( temp_output_152_0_g1 / OrifaceLength34_g1 );
				float lerpResult416_g1 = lerp( temp_output_157_0_g1 , min( temp_output_157_0_g1 , 1.0 ) , ClipDick413_g1);
				float temp_output_42_0_g1047 = lerpResult416_g1;
				float temp_output_26_0_g1048 = temp_output_42_0_g1047;
				float temp_output_19_0_g1048 = ( 1.0 - temp_output_26_0_g1048 );
				float3 temp_output_8_0_g1047 = OrifacePosition170_g1;
				float4 appendResult145_g1 = (float4(_OrificeOutWorldPosition1 , 1.0));
				float4 transform151_g1 = mul(GetWorldToObjectMatrix(),appendResult145_g1);
				float3 OrifaceOutPosition1183_g1 = (transform151_g1).xyz;
				float3 temp_output_9_0_g1047 = OrifaceOutPosition1183_g1;
				float4 appendResult144_g1 = (float4(_OrificeOutWorldPosition2 , 1.0));
				float4 transform154_g1 = mul(GetWorldToObjectMatrix(),appendResult144_g1);
				float3 OrifaceOutPosition2182_g1 = (transform154_g1).xyz;
				float3 temp_output_10_0_g1047 = OrifaceOutPosition2182_g1;
				float4 appendResult143_g1 = (float4(_OrificeOutWorldPosition3 , 1.0));
				float4 transform147_g1 = mul(GetWorldToObjectMatrix(),appendResult143_g1);
				float3 OrifaceOutPosition3175_g1 = (transform147_g1).xyz;
				float3 temp_output_11_0_g1047 = OrifaceOutPosition3175_g1;
				float temp_output_1_0_g1050 = temp_output_42_0_g1047;
				float temp_output_8_0_g1050 = ( 1.0 - temp_output_1_0_g1050 );
				float3 temp_output_3_0_g1050 = temp_output_9_0_g1047;
				float3 temp_output_4_0_g1050 = temp_output_10_0_g1047;
				float3 temp_output_7_0_g1049 = ( ( 3.0 * temp_output_8_0_g1050 * temp_output_8_0_g1050 * ( temp_output_3_0_g1050 - temp_output_8_0_g1047 ) ) + ( 6.0 * temp_output_8_0_g1050 * temp_output_1_0_g1050 * ( temp_output_4_0_g1050 - temp_output_3_0_g1050 ) ) + ( 3.0 * temp_output_1_0_g1050 * temp_output_1_0_g1050 * ( temp_output_11_0_g1047 - temp_output_4_0_g1050 ) ) );
				float3 normalizeResult27_g1051 = normalize( temp_output_7_0_g1049 );
				float3 temp_output_4_0_g1047 = DickUp172_g1;
				float3 temp_output_10_0_g1049 = temp_output_4_0_g1047;
				float3 temp_output_3_0_g1047 = DickForward18_g1;
				float3 temp_output_13_0_g1049 = temp_output_3_0_g1047;
				float dotResult33_g1049 = dot( temp_output_7_0_g1049 , temp_output_10_0_g1049 );
				float3 lerpResult34_g1049 = lerp( temp_output_10_0_g1049 , -temp_output_13_0_g1049 , saturate( dotResult33_g1049 ));
				float dotResult37_g1049 = dot( temp_output_7_0_g1049 , -temp_output_10_0_g1049 );
				float3 lerpResult40_g1049 = lerp( lerpResult34_g1049 , temp_output_13_0_g1049 , saturate( dotResult37_g1049 ));
				float3 normalizeResult42_g1049 = normalize( lerpResult40_g1049 );
				float3 normalizeResult31_g1051 = normalize( normalizeResult42_g1049 );
				float3 normalizeResult29_g1051 = normalize( cross( normalizeResult27_g1051 , normalizeResult31_g1051 ) );
				float3 temp_output_65_22_g1047 = normalizeResult29_g1051;
				float3 temp_output_2_0_g1047 = ( lerpResult343_g1 - DickOrigin16_g1 );
				float3 temp_output_5_0_g1047 = DickRight184_g1;
				float dotResult15_g1047 = dot( temp_output_2_0_g1047 , temp_output_5_0_g1047 );
				float3 temp_output_65_0_g1047 = cross( normalizeResult29_g1051 , normalizeResult27_g1051 );
				float dotResult18_g1047 = dot( temp_output_2_0_g1047 , temp_output_4_0_g1047 );
				float temp_output_208_0_g1 = saturate( sign( temp_output_152_0_g1 ) );
				float3 lerpResult221_g1 = lerp( ( ( ( temp_output_19_0_g1058 * temp_output_19_0_g1058 * temp_output_19_0_g1058 * temp_output_8_0_g1057 ) + ( temp_output_19_0_g1058 * temp_output_19_0_g1058 * 3.0 * temp_output_26_0_g1058 * temp_output_9_0_g1057 ) + ( 3.0 * temp_output_19_0_g1058 * temp_output_26_0_g1058 * temp_output_26_0_g1058 * temp_output_10_0_g1057 ) + ( temp_output_26_0_g1058 * temp_output_26_0_g1058 * temp_output_26_0_g1058 * temp_output_11_0_g1057 ) ) + ( temp_output_65_22_g1057 * dotResult15_g1057 ) + ( temp_output_65_0_g1057 * dotResult18_g1057 ) ) , ( ( ( temp_output_19_0_g1048 * temp_output_19_0_g1048 * temp_output_19_0_g1048 * temp_output_8_0_g1047 ) + ( temp_output_19_0_g1048 * temp_output_19_0_g1048 * 3.0 * temp_output_26_0_g1048 * temp_output_9_0_g1047 ) + ( 3.0 * temp_output_19_0_g1048 * temp_output_26_0_g1048 * temp_output_26_0_g1048 * temp_output_10_0_g1047 ) + ( temp_output_26_0_g1048 * temp_output_26_0_g1048 * temp_output_26_0_g1048 * temp_output_11_0_g1047 ) ) + ( temp_output_65_22_g1047 * dotResult15_g1047 ) + ( temp_output_65_0_g1047 * dotResult18_g1047 ) ) , temp_output_208_0_g1);
				float3 temp_output_42_0_g1052 = DickForward18_g1;
				float NonVisibleLength165_g1 = ( temp_output_11_0_g1 * _PenetratorLength );
				float3 temp_output_52_0_g1052 = ( ( temp_output_42_0_g1052 * ( ( NonVisibleLength165_g1 - OrifaceLength34_g1 ) - DickLength19_g1 ) ) + ( lerpResult343_g1 - DickOrigin16_g1 ) );
				float dotResult53_g1052 = dot( temp_output_42_0_g1052 , temp_output_52_0_g1052 );
				float temp_output_1_0_g1054 = 1.0;
				float temp_output_8_0_g1054 = ( 1.0 - temp_output_1_0_g1054 );
				float3 temp_output_3_0_g1054 = OrifaceOutPosition1183_g1;
				float3 temp_output_4_0_g1054 = OrifaceOutPosition2182_g1;
				float3 temp_output_7_0_g1053 = ( ( 3.0 * temp_output_8_0_g1054 * temp_output_8_0_g1054 * ( temp_output_3_0_g1054 - OrifacePosition170_g1 ) ) + ( 6.0 * temp_output_8_0_g1054 * temp_output_1_0_g1054 * ( temp_output_4_0_g1054 - temp_output_3_0_g1054 ) ) + ( 3.0 * temp_output_1_0_g1054 * temp_output_1_0_g1054 * ( OrifaceOutPosition3175_g1 - temp_output_4_0_g1054 ) ) );
				float3 normalizeResult27_g1055 = normalize( temp_output_7_0_g1053 );
				float3 temp_output_85_23_g1052 = normalizeResult27_g1055;
				float3 temp_output_4_0_g1052 = DickUp172_g1;
				float dotResult54_g1052 = dot( temp_output_4_0_g1052 , temp_output_52_0_g1052 );
				float3 temp_output_10_0_g1053 = temp_output_4_0_g1052;
				float3 temp_output_13_0_g1053 = temp_output_42_0_g1052;
				float dotResult33_g1053 = dot( temp_output_7_0_g1053 , temp_output_10_0_g1053 );
				float3 lerpResult34_g1053 = lerp( temp_output_10_0_g1053 , -temp_output_13_0_g1053 , saturate( dotResult33_g1053 ));
				float dotResult37_g1053 = dot( temp_output_7_0_g1053 , -temp_output_10_0_g1053 );
				float3 lerpResult40_g1053 = lerp( lerpResult34_g1053 , temp_output_13_0_g1053 , saturate( dotResult37_g1053 ));
				float3 normalizeResult42_g1053 = normalize( lerpResult40_g1053 );
				float3 normalizeResult31_g1055 = normalize( normalizeResult42_g1053 );
				float3 normalizeResult29_g1055 = normalize( cross( normalizeResult27_g1055 , normalizeResult31_g1055 ) );
				float3 temp_output_85_0_g1052 = cross( normalizeResult29_g1055 , normalizeResult27_g1055 );
				float3 temp_output_43_0_g1052 = DickRight184_g1;
				float dotResult55_g1052 = dot( temp_output_43_0_g1052 , temp_output_52_0_g1052 );
				float3 temp_output_85_22_g1052 = normalizeResult29_g1055;
				float temp_output_222_0_g1 = saturate( sign( ( temp_output_157_0_g1 - 1.0 ) ) );
				float3 lerpResult224_g1 = lerp( lerpResult221_g1 , ( ( ( dotResult53_g1052 * temp_output_85_23_g1052 ) + ( dotResult54_g1052 * temp_output_85_0_g1052 ) + ( dotResult55_g1052 * temp_output_85_22_g1052 ) ) + OrifaceOutPosition3175_g1 ) , temp_output_222_0_g1);
				float3 lerpResult418_g1 = lerp( lerpResult224_g1 , lerpResult221_g1 , ClipDick413_g1);
				float temp_output_226_0_g1 = saturate( -PenetrationDepth39_g1 );
				float3 lerpResult232_g1 = lerp( lerpResult418_g1 , originalPosition126_g1 , temp_output_226_0_g1);
				float3 ifLocalVar237_g1 = 0;
				if( temp_output_234_0_g1 <= 0.0 )
				ifLocalVar237_g1 = originalPosition126_g1;
				else
				ifLocalVar237_g1 = lerpResult232_g1;
				float DeformBalls426_g1 = _DeformBalls;
				float3 lerpResult428_g1 = lerp( ifLocalVar237_g1 , lerpResult232_g1 , DeformBalls426_g1);
				
				float3 temp_output_21_0_g1057 = VertexNormal259_g1;
				float dotResult55_g1057 = dot( temp_output_21_0_g1057 , temp_output_3_0_g1057 );
				float dotResult56_g1057 = dot( temp_output_21_0_g1057 , temp_output_4_0_g1057 );
				float dotResult57_g1057 = dot( temp_output_21_0_g1057 , temp_output_5_0_g1057 );
				float3 normalizeResult31_g1057 = normalize( ( ( dotResult55_g1057 * normalizeResult27_g1061 ) + ( dotResult56_g1057 * temp_output_65_0_g1057 ) + ( dotResult57_g1057 * temp_output_65_22_g1057 ) ) );
				float3 temp_output_21_0_g1047 = VertexNormal259_g1;
				float dotResult55_g1047 = dot( temp_output_21_0_g1047 , temp_output_3_0_g1047 );
				float dotResult56_g1047 = dot( temp_output_21_0_g1047 , temp_output_4_0_g1047 );
				float dotResult57_g1047 = dot( temp_output_21_0_g1047 , temp_output_5_0_g1047 );
				float3 normalizeResult31_g1047 = normalize( ( ( dotResult55_g1047 * normalizeResult27_g1051 ) + ( dotResult56_g1047 * temp_output_65_0_g1047 ) + ( dotResult57_g1047 * temp_output_65_22_g1047 ) ) );
				float3 lerpResult227_g1 = lerp( normalizeResult31_g1057 , normalizeResult31_g1047 , temp_output_208_0_g1);
				float3 temp_output_24_0_g1052 = VertexNormal259_g1;
				float dotResult61_g1052 = dot( temp_output_42_0_g1052 , temp_output_24_0_g1052 );
				float dotResult62_g1052 = dot( temp_output_4_0_g1052 , temp_output_24_0_g1052 );
				float dotResult60_g1052 = dot( temp_output_43_0_g1052 , temp_output_24_0_g1052 );
				float3 normalizeResult33_g1052 = normalize( ( ( dotResult61_g1052 * temp_output_85_23_g1052 ) + ( dotResult62_g1052 * temp_output_85_0_g1052 ) + ( dotResult60_g1052 * temp_output_85_22_g1052 ) ) );
				float3 lerpResult233_g1 = lerp( lerpResult227_g1 , normalizeResult33_g1052 , temp_output_222_0_g1);
				float3 lerpResult419_g1 = lerp( lerpResult233_g1 , lerpResult227_g1 , ClipDick413_g1);
				float3 lerpResult238_g1 = lerp( lerpResult419_g1 , VertexNormal259_g1 , temp_output_226_0_g1);
				float3 ifLocalVar391_g1 = 0;
				if( temp_output_234_0_g1 <= 0.0 )
				ifLocalVar391_g1 = VertexNormal259_g1;
				else
				ifLocalVar391_g1 = lerpResult238_g1;
				
				float lerpResult424_g1 = lerp( 1.0 , InsideLerp123_g1 , InvisibleWhenInside420_g1);
				float vertexToFrag250_g1 = lerpResult424_g1;
				o.ase_texcoord2.x = vertexToFrag250_g1;
				
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord2.yzw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = lerpResult428_g1;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = ifLocalVar391_g1;

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

				float vertexToFrag250_g1 = IN.ase_texcoord2.x;
				
				float Alpha = vertexToFrag250_g1;
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
			float4 _GooTongue_TongueMaterial_MetallicSmoothness_ST;
			float4 _GooTongue_TongueMaterial_Normal_ST;
			float4 _GooTongue_TongueMaterial_AlbedoTransparency_ST;
			float4 _BulgeLanes_normal_ST;
			float3 _PenetratorOrigin;
			float3 _OrificeWorldPosition;
			float3 _PenetratorUp;
			float3 _OrificeOutWorldPosition3;
			float3 _PenetratorForward;
			float3 _OrificeOutWorldPosition2;
			float3 _OrificeOutWorldPosition1;
			float3 _OrificeWorldNormal;
			float3 _PenetratorRight;
			float _DeformBalls;
			float _InvisibleWhenInside;
			float _ClipDick;
			float _NoBlendshapes;
			float _PinchBuffer;
			float _PenetratorCumActive;
			float _PenetratorCumProgress;
			float _PenetratorSquishPullAmount;
			float _PenetratorBulgePercentage;
			float _BulgeClip;
			float _BulgeAmount;
			float _PenetrationDepth;
			float _PenetratorLength;
			float _OrificeLength;
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
			sampler2D _BulgeLanes_output;


			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 VertexNormal259_g1 = v.ase_normal;
				float3 normalizeResult27_g1062 = normalize( VertexNormal259_g1 );
				float3 temp_output_35_0_g1 = normalizeResult27_g1062;
				float3 normalizeResult31_g1062 = normalize( v.ase_tangent.xyz );
				float3 normalizeResult29_g1062 = normalize( cross( normalizeResult27_g1062 , normalizeResult31_g1062 ) );
				float3 temp_output_35_1_g1 = cross( normalizeResult29_g1062 , normalizeResult27_g1062 );
				float3 temp_output_35_2_g1 = normalizeResult29_g1062;
				float3 SquishDelta85_g1 = ( ( ( temp_output_35_0_g1 * v.ase_texcoord2.x ) + ( temp_output_35_1_g1 * v.ase_texcoord2.y ) + ( temp_output_35_2_g1 * v.ase_texcoord2.z ) ) * _PenetratorBlendshapeMultiplier );
				float temp_output_234_0_g1 = length( SquishDelta85_g1 );
				float temp_output_11_0_g1 = max( _PenetrationDepth , 0.0 );
				float VisibleLength25_g1 = ( _PenetratorLength * ( 1.0 - temp_output_11_0_g1 ) );
				float3 DickOrigin16_g1 = _PenetratorOrigin;
				float4 appendResult132_g1 = (float4(_OrificeWorldPosition , 1.0));
				float4 transform140_g1 = mul(GetWorldToObjectMatrix(),appendResult132_g1);
				float3 OrifacePosition170_g1 = (transform140_g1).xyz;
				float DickLength19_g1 = _PenetratorLength;
				float3 DickUp172_g1 = _PenetratorUp;
				float2 texCoord9 = v.ase_texcoord1 * float2( 1,0.5 ) + float2( 0,0 );
				float2 break17 = texCoord9;
				float mulTime16 = _TimeParameters.x * 0.08;
				float2 appendResult19 = (float2(break17.x , ( mulTime16 + break17.y )));
				float4 tex2DNode8 = tex2Dlod( _BulgeLanes_output, float4( appendResult19, 0, 0.0) );
				float2 texCoord41 = v.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float temp_output_43_0 = saturate( sign( ( texCoord41.y - ( 1.0 - _BulgeClip ) ) ) );
				float3 VertexPosition254_g1 = ( ( v.ase_normal * tex2DNode8.r * _BulgeAmount * temp_output_43_0 ) + v.vertex.xyz );
				float3 temp_output_27_0_g1 = ( VertexPosition254_g1 - DickOrigin16_g1 );
				float3 DickForward18_g1 = _PenetratorForward;
				float dotResult42_g1 = dot( temp_output_27_0_g1 , DickForward18_g1 );
				float BulgePercentage37_g1 = _PenetratorBulgePercentage;
				float temp_output_1_0_g1056 = saturate( ( abs( ( dotResult42_g1 - VisibleLength25_g1 ) ) / ( DickLength19_g1 * BulgePercentage37_g1 ) ) );
				float temp_output_94_0_g1 = sqrt( ( 1.0 - ( temp_output_1_0_g1056 * temp_output_1_0_g1056 ) ) );
				float3 PullDelta91_g1 = ( ( ( temp_output_35_0_g1 * v.ase_texcoord3.x ) + ( temp_output_35_1_g1 * v.ase_texcoord3.y ) + ( temp_output_35_2_g1 * v.ase_texcoord3.z ) ) * _PenetratorBlendshapeMultiplier );
				float dotResult32_g1 = dot( temp_output_27_0_g1 , DickForward18_g1 );
				float temp_output_1_0_g1063 = saturate( ( abs( ( dotResult32_g1 - ( DickLength19_g1 * _PenetratorCumProgress ) ) ) / ( DickLength19_g1 * BulgePercentage37_g1 ) ) );
				float3 CumDelta90_g1 = ( ( ( temp_output_35_0_g1 * v.ase_texcoord1.w ) + ( temp_output_35_1_g1 * v.ase_texcoord2.w ) + ( temp_output_35_2_g1 * v.ase_texcoord3.w ) ) * _PenetratorBlendshapeMultiplier );
				float3 lerpResult410_g1 = lerp( ( VertexPosition254_g1 + ( SquishDelta85_g1 * temp_output_94_0_g1 * saturate( -_PenetratorSquishPullAmount ) ) + ( temp_output_94_0_g1 * PullDelta91_g1 * saturate( _PenetratorSquishPullAmount ) ) + ( sqrt( ( 1.0 - ( temp_output_1_0_g1063 * temp_output_1_0_g1063 ) ) ) * CumDelta90_g1 * _PenetratorCumActive ) ) , VertexPosition254_g1 , _NoBlendshapes);
				float3 originalPosition126_g1 = lerpResult410_g1;
				float dotResult118_g1 = dot( ( lerpResult410_g1 - DickOrigin16_g1 ) , DickForward18_g1 );
				float PenetrationDepth39_g1 = _PenetrationDepth;
				float temp_output_65_0_g1 = ( PenetrationDepth39_g1 * DickLength19_g1 );
				float OrifaceLength34_g1 = _OrificeLength;
				float temp_output_73_0_g1 = ( _PinchBuffer * OrifaceLength34_g1 );
				float dotResult80_g1 = dot( ( lerpResult410_g1 - DickOrigin16_g1 ) , DickForward18_g1 );
				float temp_output_112_0_g1 = ( -( ( ( temp_output_65_0_g1 - temp_output_73_0_g1 ) + dotResult80_g1 ) - DickLength19_g1 ) * 10.0 );
				float ClipDick413_g1 = _ClipDick;
				float lerpResult411_g1 = lerp( max( temp_output_112_0_g1 , ( ( ( temp_output_65_0_g1 + dotResult80_g1 + temp_output_73_0_g1 ) - ( OrifaceLength34_g1 + DickLength19_g1 ) ) * 10.0 ) ) , temp_output_112_0_g1 , ClipDick413_g1);
				float InsideLerp123_g1 = saturate( lerpResult411_g1 );
				float3 lerpResult124_g1 = lerp( ( ( DickForward18_g1 * dotResult118_g1 ) + DickOrigin16_g1 ) , originalPosition126_g1 , InsideLerp123_g1);
				float InvisibleWhenInside420_g1 = _InvisibleWhenInside;
				float3 lerpResult422_g1 = lerp( originalPosition126_g1 , lerpResult124_g1 , InvisibleWhenInside420_g1);
				float3 temp_output_354_0_g1 = ( lerpResult422_g1 - DickOrigin16_g1 );
				float dotResult373_g1 = dot( DickUp172_g1 , temp_output_354_0_g1 );
				float3 DickRight184_g1 = _PenetratorRight;
				float dotResult374_g1 = dot( DickRight184_g1 , temp_output_354_0_g1 );
				float dotResult375_g1 = dot( temp_output_354_0_g1 , DickForward18_g1 );
				float3 lerpResult343_g1 = lerp( ( ( ( saturate( ( ( VisibleLength25_g1 - distance( DickOrigin16_g1 , OrifacePosition170_g1 ) ) / DickLength19_g1 ) ) + 1.0 ) * dotResult373_g1 * DickUp172_g1 ) + ( ( saturate( ( ( VisibleLength25_g1 - distance( DickOrigin16_g1 , OrifacePosition170_g1 ) ) / DickLength19_g1 ) ) + 1.0 ) * dotResult374_g1 * DickRight184_g1 ) + ( DickForward18_g1 * dotResult375_g1 ) + DickOrigin16_g1 ) , lerpResult422_g1 , saturate( PenetrationDepth39_g1 ));
				float dotResult177_g1 = dot( ( lerpResult343_g1 - DickOrigin16_g1 ) , DickForward18_g1 );
				float temp_output_178_0_g1 = max( VisibleLength25_g1 , 0.05 );
				float temp_output_42_0_g1057 = ( dotResult177_g1 / temp_output_178_0_g1 );
				float temp_output_26_0_g1058 = temp_output_42_0_g1057;
				float temp_output_19_0_g1058 = ( 1.0 - temp_output_26_0_g1058 );
				float3 temp_output_8_0_g1057 = DickOrigin16_g1;
				float temp_output_393_0_g1 = distance( DickOrigin16_g1 , OrifacePosition170_g1 );
				float temp_output_396_0_g1 = min( temp_output_178_0_g1 , temp_output_393_0_g1 );
				float3 temp_output_9_0_g1057 = ( DickOrigin16_g1 + ( DickForward18_g1 * temp_output_396_0_g1 * 0.25 ) );
				float4 appendResult130_g1 = (float4(_OrificeWorldNormal , 0.0));
				float4 transform135_g1 = mul(GetWorldToObjectMatrix(),appendResult130_g1);
				float3 OrifaceNormal155_g1 = (transform135_g1).xyz;
				float3 temp_output_10_0_g1057 = ( OrifacePosition170_g1 + ( OrifaceNormal155_g1 * 0.25 * temp_output_396_0_g1 ) );
				float3 temp_output_11_0_g1057 = OrifacePosition170_g1;
				float temp_output_1_0_g1060 = temp_output_42_0_g1057;
				float temp_output_8_0_g1060 = ( 1.0 - temp_output_1_0_g1060 );
				float3 temp_output_3_0_g1060 = temp_output_9_0_g1057;
				float3 temp_output_4_0_g1060 = temp_output_10_0_g1057;
				float3 temp_output_7_0_g1059 = ( ( 3.0 * temp_output_8_0_g1060 * temp_output_8_0_g1060 * ( temp_output_3_0_g1060 - temp_output_8_0_g1057 ) ) + ( 6.0 * temp_output_8_0_g1060 * temp_output_1_0_g1060 * ( temp_output_4_0_g1060 - temp_output_3_0_g1060 ) ) + ( 3.0 * temp_output_1_0_g1060 * temp_output_1_0_g1060 * ( temp_output_11_0_g1057 - temp_output_4_0_g1060 ) ) );
				float3 normalizeResult27_g1061 = normalize( temp_output_7_0_g1059 );
				float3 temp_output_4_0_g1057 = DickUp172_g1;
				float3 temp_output_10_0_g1059 = temp_output_4_0_g1057;
				float3 temp_output_3_0_g1057 = DickForward18_g1;
				float3 temp_output_13_0_g1059 = temp_output_3_0_g1057;
				float dotResult33_g1059 = dot( temp_output_7_0_g1059 , temp_output_10_0_g1059 );
				float3 lerpResult34_g1059 = lerp( temp_output_10_0_g1059 , -temp_output_13_0_g1059 , saturate( dotResult33_g1059 ));
				float dotResult37_g1059 = dot( temp_output_7_0_g1059 , -temp_output_10_0_g1059 );
				float3 lerpResult40_g1059 = lerp( lerpResult34_g1059 , temp_output_13_0_g1059 , saturate( dotResult37_g1059 ));
				float3 normalizeResult42_g1059 = normalize( lerpResult40_g1059 );
				float3 normalizeResult31_g1061 = normalize( normalizeResult42_g1059 );
				float3 normalizeResult29_g1061 = normalize( cross( normalizeResult27_g1061 , normalizeResult31_g1061 ) );
				float3 temp_output_65_22_g1057 = normalizeResult29_g1061;
				float3 temp_output_2_0_g1057 = ( lerpResult343_g1 - DickOrigin16_g1 );
				float3 temp_output_5_0_g1057 = DickRight184_g1;
				float dotResult15_g1057 = dot( temp_output_2_0_g1057 , temp_output_5_0_g1057 );
				float3 temp_output_65_0_g1057 = cross( normalizeResult29_g1061 , normalizeResult27_g1061 );
				float dotResult18_g1057 = dot( temp_output_2_0_g1057 , temp_output_4_0_g1057 );
				float dotResult142_g1 = dot( ( lerpResult343_g1 - DickOrigin16_g1 ) , DickForward18_g1 );
				float temp_output_152_0_g1 = ( dotResult142_g1 - VisibleLength25_g1 );
				float temp_output_157_0_g1 = ( temp_output_152_0_g1 / OrifaceLength34_g1 );
				float lerpResult416_g1 = lerp( temp_output_157_0_g1 , min( temp_output_157_0_g1 , 1.0 ) , ClipDick413_g1);
				float temp_output_42_0_g1047 = lerpResult416_g1;
				float temp_output_26_0_g1048 = temp_output_42_0_g1047;
				float temp_output_19_0_g1048 = ( 1.0 - temp_output_26_0_g1048 );
				float3 temp_output_8_0_g1047 = OrifacePosition170_g1;
				float4 appendResult145_g1 = (float4(_OrificeOutWorldPosition1 , 1.0));
				float4 transform151_g1 = mul(GetWorldToObjectMatrix(),appendResult145_g1);
				float3 OrifaceOutPosition1183_g1 = (transform151_g1).xyz;
				float3 temp_output_9_0_g1047 = OrifaceOutPosition1183_g1;
				float4 appendResult144_g1 = (float4(_OrificeOutWorldPosition2 , 1.0));
				float4 transform154_g1 = mul(GetWorldToObjectMatrix(),appendResult144_g1);
				float3 OrifaceOutPosition2182_g1 = (transform154_g1).xyz;
				float3 temp_output_10_0_g1047 = OrifaceOutPosition2182_g1;
				float4 appendResult143_g1 = (float4(_OrificeOutWorldPosition3 , 1.0));
				float4 transform147_g1 = mul(GetWorldToObjectMatrix(),appendResult143_g1);
				float3 OrifaceOutPosition3175_g1 = (transform147_g1).xyz;
				float3 temp_output_11_0_g1047 = OrifaceOutPosition3175_g1;
				float temp_output_1_0_g1050 = temp_output_42_0_g1047;
				float temp_output_8_0_g1050 = ( 1.0 - temp_output_1_0_g1050 );
				float3 temp_output_3_0_g1050 = temp_output_9_0_g1047;
				float3 temp_output_4_0_g1050 = temp_output_10_0_g1047;
				float3 temp_output_7_0_g1049 = ( ( 3.0 * temp_output_8_0_g1050 * temp_output_8_0_g1050 * ( temp_output_3_0_g1050 - temp_output_8_0_g1047 ) ) + ( 6.0 * temp_output_8_0_g1050 * temp_output_1_0_g1050 * ( temp_output_4_0_g1050 - temp_output_3_0_g1050 ) ) + ( 3.0 * temp_output_1_0_g1050 * temp_output_1_0_g1050 * ( temp_output_11_0_g1047 - temp_output_4_0_g1050 ) ) );
				float3 normalizeResult27_g1051 = normalize( temp_output_7_0_g1049 );
				float3 temp_output_4_0_g1047 = DickUp172_g1;
				float3 temp_output_10_0_g1049 = temp_output_4_0_g1047;
				float3 temp_output_3_0_g1047 = DickForward18_g1;
				float3 temp_output_13_0_g1049 = temp_output_3_0_g1047;
				float dotResult33_g1049 = dot( temp_output_7_0_g1049 , temp_output_10_0_g1049 );
				float3 lerpResult34_g1049 = lerp( temp_output_10_0_g1049 , -temp_output_13_0_g1049 , saturate( dotResult33_g1049 ));
				float dotResult37_g1049 = dot( temp_output_7_0_g1049 , -temp_output_10_0_g1049 );
				float3 lerpResult40_g1049 = lerp( lerpResult34_g1049 , temp_output_13_0_g1049 , saturate( dotResult37_g1049 ));
				float3 normalizeResult42_g1049 = normalize( lerpResult40_g1049 );
				float3 normalizeResult31_g1051 = normalize( normalizeResult42_g1049 );
				float3 normalizeResult29_g1051 = normalize( cross( normalizeResult27_g1051 , normalizeResult31_g1051 ) );
				float3 temp_output_65_22_g1047 = normalizeResult29_g1051;
				float3 temp_output_2_0_g1047 = ( lerpResult343_g1 - DickOrigin16_g1 );
				float3 temp_output_5_0_g1047 = DickRight184_g1;
				float dotResult15_g1047 = dot( temp_output_2_0_g1047 , temp_output_5_0_g1047 );
				float3 temp_output_65_0_g1047 = cross( normalizeResult29_g1051 , normalizeResult27_g1051 );
				float dotResult18_g1047 = dot( temp_output_2_0_g1047 , temp_output_4_0_g1047 );
				float temp_output_208_0_g1 = saturate( sign( temp_output_152_0_g1 ) );
				float3 lerpResult221_g1 = lerp( ( ( ( temp_output_19_0_g1058 * temp_output_19_0_g1058 * temp_output_19_0_g1058 * temp_output_8_0_g1057 ) + ( temp_output_19_0_g1058 * temp_output_19_0_g1058 * 3.0 * temp_output_26_0_g1058 * temp_output_9_0_g1057 ) + ( 3.0 * temp_output_19_0_g1058 * temp_output_26_0_g1058 * temp_output_26_0_g1058 * temp_output_10_0_g1057 ) + ( temp_output_26_0_g1058 * temp_output_26_0_g1058 * temp_output_26_0_g1058 * temp_output_11_0_g1057 ) ) + ( temp_output_65_22_g1057 * dotResult15_g1057 ) + ( temp_output_65_0_g1057 * dotResult18_g1057 ) ) , ( ( ( temp_output_19_0_g1048 * temp_output_19_0_g1048 * temp_output_19_0_g1048 * temp_output_8_0_g1047 ) + ( temp_output_19_0_g1048 * temp_output_19_0_g1048 * 3.0 * temp_output_26_0_g1048 * temp_output_9_0_g1047 ) + ( 3.0 * temp_output_19_0_g1048 * temp_output_26_0_g1048 * temp_output_26_0_g1048 * temp_output_10_0_g1047 ) + ( temp_output_26_0_g1048 * temp_output_26_0_g1048 * temp_output_26_0_g1048 * temp_output_11_0_g1047 ) ) + ( temp_output_65_22_g1047 * dotResult15_g1047 ) + ( temp_output_65_0_g1047 * dotResult18_g1047 ) ) , temp_output_208_0_g1);
				float3 temp_output_42_0_g1052 = DickForward18_g1;
				float NonVisibleLength165_g1 = ( temp_output_11_0_g1 * _PenetratorLength );
				float3 temp_output_52_0_g1052 = ( ( temp_output_42_0_g1052 * ( ( NonVisibleLength165_g1 - OrifaceLength34_g1 ) - DickLength19_g1 ) ) + ( lerpResult343_g1 - DickOrigin16_g1 ) );
				float dotResult53_g1052 = dot( temp_output_42_0_g1052 , temp_output_52_0_g1052 );
				float temp_output_1_0_g1054 = 1.0;
				float temp_output_8_0_g1054 = ( 1.0 - temp_output_1_0_g1054 );
				float3 temp_output_3_0_g1054 = OrifaceOutPosition1183_g1;
				float3 temp_output_4_0_g1054 = OrifaceOutPosition2182_g1;
				float3 temp_output_7_0_g1053 = ( ( 3.0 * temp_output_8_0_g1054 * temp_output_8_0_g1054 * ( temp_output_3_0_g1054 - OrifacePosition170_g1 ) ) + ( 6.0 * temp_output_8_0_g1054 * temp_output_1_0_g1054 * ( temp_output_4_0_g1054 - temp_output_3_0_g1054 ) ) + ( 3.0 * temp_output_1_0_g1054 * temp_output_1_0_g1054 * ( OrifaceOutPosition3175_g1 - temp_output_4_0_g1054 ) ) );
				float3 normalizeResult27_g1055 = normalize( temp_output_7_0_g1053 );
				float3 temp_output_85_23_g1052 = normalizeResult27_g1055;
				float3 temp_output_4_0_g1052 = DickUp172_g1;
				float dotResult54_g1052 = dot( temp_output_4_0_g1052 , temp_output_52_0_g1052 );
				float3 temp_output_10_0_g1053 = temp_output_4_0_g1052;
				float3 temp_output_13_0_g1053 = temp_output_42_0_g1052;
				float dotResult33_g1053 = dot( temp_output_7_0_g1053 , temp_output_10_0_g1053 );
				float3 lerpResult34_g1053 = lerp( temp_output_10_0_g1053 , -temp_output_13_0_g1053 , saturate( dotResult33_g1053 ));
				float dotResult37_g1053 = dot( temp_output_7_0_g1053 , -temp_output_10_0_g1053 );
				float3 lerpResult40_g1053 = lerp( lerpResult34_g1053 , temp_output_13_0_g1053 , saturate( dotResult37_g1053 ));
				float3 normalizeResult42_g1053 = normalize( lerpResult40_g1053 );
				float3 normalizeResult31_g1055 = normalize( normalizeResult42_g1053 );
				float3 normalizeResult29_g1055 = normalize( cross( normalizeResult27_g1055 , normalizeResult31_g1055 ) );
				float3 temp_output_85_0_g1052 = cross( normalizeResult29_g1055 , normalizeResult27_g1055 );
				float3 temp_output_43_0_g1052 = DickRight184_g1;
				float dotResult55_g1052 = dot( temp_output_43_0_g1052 , temp_output_52_0_g1052 );
				float3 temp_output_85_22_g1052 = normalizeResult29_g1055;
				float temp_output_222_0_g1 = saturate( sign( ( temp_output_157_0_g1 - 1.0 ) ) );
				float3 lerpResult224_g1 = lerp( lerpResult221_g1 , ( ( ( dotResult53_g1052 * temp_output_85_23_g1052 ) + ( dotResult54_g1052 * temp_output_85_0_g1052 ) + ( dotResult55_g1052 * temp_output_85_22_g1052 ) ) + OrifaceOutPosition3175_g1 ) , temp_output_222_0_g1);
				float3 lerpResult418_g1 = lerp( lerpResult224_g1 , lerpResult221_g1 , ClipDick413_g1);
				float temp_output_226_0_g1 = saturate( -PenetrationDepth39_g1 );
				float3 lerpResult232_g1 = lerp( lerpResult418_g1 , originalPosition126_g1 , temp_output_226_0_g1);
				float3 ifLocalVar237_g1 = 0;
				if( temp_output_234_0_g1 <= 0.0 )
				ifLocalVar237_g1 = originalPosition126_g1;
				else
				ifLocalVar237_g1 = lerpResult232_g1;
				float DeformBalls426_g1 = _DeformBalls;
				float3 lerpResult428_g1 = lerp( ifLocalVar237_g1 , lerpResult232_g1 , DeformBalls426_g1);
				
				float3 temp_output_21_0_g1057 = VertexNormal259_g1;
				float dotResult55_g1057 = dot( temp_output_21_0_g1057 , temp_output_3_0_g1057 );
				float dotResult56_g1057 = dot( temp_output_21_0_g1057 , temp_output_4_0_g1057 );
				float dotResult57_g1057 = dot( temp_output_21_0_g1057 , temp_output_5_0_g1057 );
				float3 normalizeResult31_g1057 = normalize( ( ( dotResult55_g1057 * normalizeResult27_g1061 ) + ( dotResult56_g1057 * temp_output_65_0_g1057 ) + ( dotResult57_g1057 * temp_output_65_22_g1057 ) ) );
				float3 temp_output_21_0_g1047 = VertexNormal259_g1;
				float dotResult55_g1047 = dot( temp_output_21_0_g1047 , temp_output_3_0_g1047 );
				float dotResult56_g1047 = dot( temp_output_21_0_g1047 , temp_output_4_0_g1047 );
				float dotResult57_g1047 = dot( temp_output_21_0_g1047 , temp_output_5_0_g1047 );
				float3 normalizeResult31_g1047 = normalize( ( ( dotResult55_g1047 * normalizeResult27_g1051 ) + ( dotResult56_g1047 * temp_output_65_0_g1047 ) + ( dotResult57_g1047 * temp_output_65_22_g1047 ) ) );
				float3 lerpResult227_g1 = lerp( normalizeResult31_g1057 , normalizeResult31_g1047 , temp_output_208_0_g1);
				float3 temp_output_24_0_g1052 = VertexNormal259_g1;
				float dotResult61_g1052 = dot( temp_output_42_0_g1052 , temp_output_24_0_g1052 );
				float dotResult62_g1052 = dot( temp_output_4_0_g1052 , temp_output_24_0_g1052 );
				float dotResult60_g1052 = dot( temp_output_43_0_g1052 , temp_output_24_0_g1052 );
				float3 normalizeResult33_g1052 = normalize( ( ( dotResult61_g1052 * temp_output_85_23_g1052 ) + ( dotResult62_g1052 * temp_output_85_0_g1052 ) + ( dotResult60_g1052 * temp_output_85_22_g1052 ) ) );
				float3 lerpResult233_g1 = lerp( lerpResult227_g1 , normalizeResult33_g1052 , temp_output_222_0_g1);
				float3 lerpResult419_g1 = lerp( lerpResult233_g1 , lerpResult227_g1 , ClipDick413_g1);
				float3 lerpResult238_g1 = lerp( lerpResult419_g1 , VertexNormal259_g1 , temp_output_226_0_g1);
				float3 ifLocalVar391_g1 = 0;
				if( temp_output_234_0_g1 <= 0.0 )
				ifLocalVar391_g1 = VertexNormal259_g1;
				else
				ifLocalVar391_g1 = lerpResult238_g1;
				
				float lerpResult424_g1 = lerp( 1.0 , InsideLerp123_g1 , InvisibleWhenInside420_g1);
				float vertexToFrag250_g1 = lerpResult424_g1;
				o.ase_texcoord2.x = vertexToFrag250_g1;
				
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord2.yzw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = lerpResult428_g1;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = ifLocalVar391_g1;
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

				float vertexToFrag250_g1 = IN.ase_texcoord2.x;
				
				float Alpha = vertexToFrag250_g1;
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
			#define ASE_NEEDS_FRAG_WORLD_POSITION


			#pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_tangent : TANGENT;
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
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _GooTongue_TongueMaterial_MetallicSmoothness_ST;
			float4 _GooTongue_TongueMaterial_Normal_ST;
			float4 _GooTongue_TongueMaterial_AlbedoTransparency_ST;
			float4 _BulgeLanes_normal_ST;
			float3 _PenetratorOrigin;
			float3 _OrificeWorldPosition;
			float3 _PenetratorUp;
			float3 _OrificeOutWorldPosition3;
			float3 _PenetratorForward;
			float3 _OrificeOutWorldPosition2;
			float3 _OrificeOutWorldPosition1;
			float3 _OrificeWorldNormal;
			float3 _PenetratorRight;
			float _DeformBalls;
			float _InvisibleWhenInside;
			float _ClipDick;
			float _NoBlendshapes;
			float _PinchBuffer;
			float _PenetratorCumActive;
			float _PenetratorCumProgress;
			float _PenetratorSquishPullAmount;
			float _PenetratorBulgePercentage;
			float _BulgeClip;
			float _BulgeAmount;
			float _PenetrationDepth;
			float _PenetratorLength;
			float _OrificeLength;
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
			sampler2D _BulgeLanes_output;
			sampler2D _GooTongue_TongueMaterial_AlbedoTransparency;


			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 VertexNormal259_g1 = v.ase_normal;
				float3 normalizeResult27_g1062 = normalize( VertexNormal259_g1 );
				float3 temp_output_35_0_g1 = normalizeResult27_g1062;
				float3 normalizeResult31_g1062 = normalize( v.ase_tangent.xyz );
				float3 normalizeResult29_g1062 = normalize( cross( normalizeResult27_g1062 , normalizeResult31_g1062 ) );
				float3 temp_output_35_1_g1 = cross( normalizeResult29_g1062 , normalizeResult27_g1062 );
				float3 temp_output_35_2_g1 = normalizeResult29_g1062;
				float3 SquishDelta85_g1 = ( ( ( temp_output_35_0_g1 * v.texcoord2.x ) + ( temp_output_35_1_g1 * v.texcoord2.y ) + ( temp_output_35_2_g1 * v.texcoord2.z ) ) * _PenetratorBlendshapeMultiplier );
				float temp_output_234_0_g1 = length( SquishDelta85_g1 );
				float temp_output_11_0_g1 = max( _PenetrationDepth , 0.0 );
				float VisibleLength25_g1 = ( _PenetratorLength * ( 1.0 - temp_output_11_0_g1 ) );
				float3 DickOrigin16_g1 = _PenetratorOrigin;
				float4 appendResult132_g1 = (float4(_OrificeWorldPosition , 1.0));
				float4 transform140_g1 = mul(GetWorldToObjectMatrix(),appendResult132_g1);
				float3 OrifacePosition170_g1 = (transform140_g1).xyz;
				float DickLength19_g1 = _PenetratorLength;
				float3 DickUp172_g1 = _PenetratorUp;
				float2 texCoord9 = v.texcoord1.xy * float2( 1,0.5 ) + float2( 0,0 );
				float2 break17 = texCoord9;
				float mulTime16 = _TimeParameters.x * 0.08;
				float2 appendResult19 = (float2(break17.x , ( mulTime16 + break17.y )));
				float4 tex2DNode8 = tex2Dlod( _BulgeLanes_output, float4( appendResult19, 0, 0.0) );
				float2 texCoord41 = v.texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float temp_output_43_0 = saturate( sign( ( texCoord41.y - ( 1.0 - _BulgeClip ) ) ) );
				float3 VertexPosition254_g1 = ( ( v.ase_normal * tex2DNode8.r * _BulgeAmount * temp_output_43_0 ) + v.vertex.xyz );
				float3 temp_output_27_0_g1 = ( VertexPosition254_g1 - DickOrigin16_g1 );
				float3 DickForward18_g1 = _PenetratorForward;
				float dotResult42_g1 = dot( temp_output_27_0_g1 , DickForward18_g1 );
				float BulgePercentage37_g1 = _PenetratorBulgePercentage;
				float temp_output_1_0_g1056 = saturate( ( abs( ( dotResult42_g1 - VisibleLength25_g1 ) ) / ( DickLength19_g1 * BulgePercentage37_g1 ) ) );
				float temp_output_94_0_g1 = sqrt( ( 1.0 - ( temp_output_1_0_g1056 * temp_output_1_0_g1056 ) ) );
				float3 PullDelta91_g1 = ( ( ( temp_output_35_0_g1 * v.ase_texcoord3.x ) + ( temp_output_35_1_g1 * v.ase_texcoord3.y ) + ( temp_output_35_2_g1 * v.ase_texcoord3.z ) ) * _PenetratorBlendshapeMultiplier );
				float dotResult32_g1 = dot( temp_output_27_0_g1 , DickForward18_g1 );
				float temp_output_1_0_g1063 = saturate( ( abs( ( dotResult32_g1 - ( DickLength19_g1 * _PenetratorCumProgress ) ) ) / ( DickLength19_g1 * BulgePercentage37_g1 ) ) );
				float3 CumDelta90_g1 = ( ( ( temp_output_35_0_g1 * v.texcoord1.w ) + ( temp_output_35_1_g1 * v.texcoord2.w ) + ( temp_output_35_2_g1 * v.ase_texcoord3.w ) ) * _PenetratorBlendshapeMultiplier );
				float3 lerpResult410_g1 = lerp( ( VertexPosition254_g1 + ( SquishDelta85_g1 * temp_output_94_0_g1 * saturate( -_PenetratorSquishPullAmount ) ) + ( temp_output_94_0_g1 * PullDelta91_g1 * saturate( _PenetratorSquishPullAmount ) ) + ( sqrt( ( 1.0 - ( temp_output_1_0_g1063 * temp_output_1_0_g1063 ) ) ) * CumDelta90_g1 * _PenetratorCumActive ) ) , VertexPosition254_g1 , _NoBlendshapes);
				float3 originalPosition126_g1 = lerpResult410_g1;
				float dotResult118_g1 = dot( ( lerpResult410_g1 - DickOrigin16_g1 ) , DickForward18_g1 );
				float PenetrationDepth39_g1 = _PenetrationDepth;
				float temp_output_65_0_g1 = ( PenetrationDepth39_g1 * DickLength19_g1 );
				float OrifaceLength34_g1 = _OrificeLength;
				float temp_output_73_0_g1 = ( _PinchBuffer * OrifaceLength34_g1 );
				float dotResult80_g1 = dot( ( lerpResult410_g1 - DickOrigin16_g1 ) , DickForward18_g1 );
				float temp_output_112_0_g1 = ( -( ( ( temp_output_65_0_g1 - temp_output_73_0_g1 ) + dotResult80_g1 ) - DickLength19_g1 ) * 10.0 );
				float ClipDick413_g1 = _ClipDick;
				float lerpResult411_g1 = lerp( max( temp_output_112_0_g1 , ( ( ( temp_output_65_0_g1 + dotResult80_g1 + temp_output_73_0_g1 ) - ( OrifaceLength34_g1 + DickLength19_g1 ) ) * 10.0 ) ) , temp_output_112_0_g1 , ClipDick413_g1);
				float InsideLerp123_g1 = saturate( lerpResult411_g1 );
				float3 lerpResult124_g1 = lerp( ( ( DickForward18_g1 * dotResult118_g1 ) + DickOrigin16_g1 ) , originalPosition126_g1 , InsideLerp123_g1);
				float InvisibleWhenInside420_g1 = _InvisibleWhenInside;
				float3 lerpResult422_g1 = lerp( originalPosition126_g1 , lerpResult124_g1 , InvisibleWhenInside420_g1);
				float3 temp_output_354_0_g1 = ( lerpResult422_g1 - DickOrigin16_g1 );
				float dotResult373_g1 = dot( DickUp172_g1 , temp_output_354_0_g1 );
				float3 DickRight184_g1 = _PenetratorRight;
				float dotResult374_g1 = dot( DickRight184_g1 , temp_output_354_0_g1 );
				float dotResult375_g1 = dot( temp_output_354_0_g1 , DickForward18_g1 );
				float3 lerpResult343_g1 = lerp( ( ( ( saturate( ( ( VisibleLength25_g1 - distance( DickOrigin16_g1 , OrifacePosition170_g1 ) ) / DickLength19_g1 ) ) + 1.0 ) * dotResult373_g1 * DickUp172_g1 ) + ( ( saturate( ( ( VisibleLength25_g1 - distance( DickOrigin16_g1 , OrifacePosition170_g1 ) ) / DickLength19_g1 ) ) + 1.0 ) * dotResult374_g1 * DickRight184_g1 ) + ( DickForward18_g1 * dotResult375_g1 ) + DickOrigin16_g1 ) , lerpResult422_g1 , saturate( PenetrationDepth39_g1 ));
				float dotResult177_g1 = dot( ( lerpResult343_g1 - DickOrigin16_g1 ) , DickForward18_g1 );
				float temp_output_178_0_g1 = max( VisibleLength25_g1 , 0.05 );
				float temp_output_42_0_g1057 = ( dotResult177_g1 / temp_output_178_0_g1 );
				float temp_output_26_0_g1058 = temp_output_42_0_g1057;
				float temp_output_19_0_g1058 = ( 1.0 - temp_output_26_0_g1058 );
				float3 temp_output_8_0_g1057 = DickOrigin16_g1;
				float temp_output_393_0_g1 = distance( DickOrigin16_g1 , OrifacePosition170_g1 );
				float temp_output_396_0_g1 = min( temp_output_178_0_g1 , temp_output_393_0_g1 );
				float3 temp_output_9_0_g1057 = ( DickOrigin16_g1 + ( DickForward18_g1 * temp_output_396_0_g1 * 0.25 ) );
				float4 appendResult130_g1 = (float4(_OrificeWorldNormal , 0.0));
				float4 transform135_g1 = mul(GetWorldToObjectMatrix(),appendResult130_g1);
				float3 OrifaceNormal155_g1 = (transform135_g1).xyz;
				float3 temp_output_10_0_g1057 = ( OrifacePosition170_g1 + ( OrifaceNormal155_g1 * 0.25 * temp_output_396_0_g1 ) );
				float3 temp_output_11_0_g1057 = OrifacePosition170_g1;
				float temp_output_1_0_g1060 = temp_output_42_0_g1057;
				float temp_output_8_0_g1060 = ( 1.0 - temp_output_1_0_g1060 );
				float3 temp_output_3_0_g1060 = temp_output_9_0_g1057;
				float3 temp_output_4_0_g1060 = temp_output_10_0_g1057;
				float3 temp_output_7_0_g1059 = ( ( 3.0 * temp_output_8_0_g1060 * temp_output_8_0_g1060 * ( temp_output_3_0_g1060 - temp_output_8_0_g1057 ) ) + ( 6.0 * temp_output_8_0_g1060 * temp_output_1_0_g1060 * ( temp_output_4_0_g1060 - temp_output_3_0_g1060 ) ) + ( 3.0 * temp_output_1_0_g1060 * temp_output_1_0_g1060 * ( temp_output_11_0_g1057 - temp_output_4_0_g1060 ) ) );
				float3 normalizeResult27_g1061 = normalize( temp_output_7_0_g1059 );
				float3 temp_output_4_0_g1057 = DickUp172_g1;
				float3 temp_output_10_0_g1059 = temp_output_4_0_g1057;
				float3 temp_output_3_0_g1057 = DickForward18_g1;
				float3 temp_output_13_0_g1059 = temp_output_3_0_g1057;
				float dotResult33_g1059 = dot( temp_output_7_0_g1059 , temp_output_10_0_g1059 );
				float3 lerpResult34_g1059 = lerp( temp_output_10_0_g1059 , -temp_output_13_0_g1059 , saturate( dotResult33_g1059 ));
				float dotResult37_g1059 = dot( temp_output_7_0_g1059 , -temp_output_10_0_g1059 );
				float3 lerpResult40_g1059 = lerp( lerpResult34_g1059 , temp_output_13_0_g1059 , saturate( dotResult37_g1059 ));
				float3 normalizeResult42_g1059 = normalize( lerpResult40_g1059 );
				float3 normalizeResult31_g1061 = normalize( normalizeResult42_g1059 );
				float3 normalizeResult29_g1061 = normalize( cross( normalizeResult27_g1061 , normalizeResult31_g1061 ) );
				float3 temp_output_65_22_g1057 = normalizeResult29_g1061;
				float3 temp_output_2_0_g1057 = ( lerpResult343_g1 - DickOrigin16_g1 );
				float3 temp_output_5_0_g1057 = DickRight184_g1;
				float dotResult15_g1057 = dot( temp_output_2_0_g1057 , temp_output_5_0_g1057 );
				float3 temp_output_65_0_g1057 = cross( normalizeResult29_g1061 , normalizeResult27_g1061 );
				float dotResult18_g1057 = dot( temp_output_2_0_g1057 , temp_output_4_0_g1057 );
				float dotResult142_g1 = dot( ( lerpResult343_g1 - DickOrigin16_g1 ) , DickForward18_g1 );
				float temp_output_152_0_g1 = ( dotResult142_g1 - VisibleLength25_g1 );
				float temp_output_157_0_g1 = ( temp_output_152_0_g1 / OrifaceLength34_g1 );
				float lerpResult416_g1 = lerp( temp_output_157_0_g1 , min( temp_output_157_0_g1 , 1.0 ) , ClipDick413_g1);
				float temp_output_42_0_g1047 = lerpResult416_g1;
				float temp_output_26_0_g1048 = temp_output_42_0_g1047;
				float temp_output_19_0_g1048 = ( 1.0 - temp_output_26_0_g1048 );
				float3 temp_output_8_0_g1047 = OrifacePosition170_g1;
				float4 appendResult145_g1 = (float4(_OrificeOutWorldPosition1 , 1.0));
				float4 transform151_g1 = mul(GetWorldToObjectMatrix(),appendResult145_g1);
				float3 OrifaceOutPosition1183_g1 = (transform151_g1).xyz;
				float3 temp_output_9_0_g1047 = OrifaceOutPosition1183_g1;
				float4 appendResult144_g1 = (float4(_OrificeOutWorldPosition2 , 1.0));
				float4 transform154_g1 = mul(GetWorldToObjectMatrix(),appendResult144_g1);
				float3 OrifaceOutPosition2182_g1 = (transform154_g1).xyz;
				float3 temp_output_10_0_g1047 = OrifaceOutPosition2182_g1;
				float4 appendResult143_g1 = (float4(_OrificeOutWorldPosition3 , 1.0));
				float4 transform147_g1 = mul(GetWorldToObjectMatrix(),appendResult143_g1);
				float3 OrifaceOutPosition3175_g1 = (transform147_g1).xyz;
				float3 temp_output_11_0_g1047 = OrifaceOutPosition3175_g1;
				float temp_output_1_0_g1050 = temp_output_42_0_g1047;
				float temp_output_8_0_g1050 = ( 1.0 - temp_output_1_0_g1050 );
				float3 temp_output_3_0_g1050 = temp_output_9_0_g1047;
				float3 temp_output_4_0_g1050 = temp_output_10_0_g1047;
				float3 temp_output_7_0_g1049 = ( ( 3.0 * temp_output_8_0_g1050 * temp_output_8_0_g1050 * ( temp_output_3_0_g1050 - temp_output_8_0_g1047 ) ) + ( 6.0 * temp_output_8_0_g1050 * temp_output_1_0_g1050 * ( temp_output_4_0_g1050 - temp_output_3_0_g1050 ) ) + ( 3.0 * temp_output_1_0_g1050 * temp_output_1_0_g1050 * ( temp_output_11_0_g1047 - temp_output_4_0_g1050 ) ) );
				float3 normalizeResult27_g1051 = normalize( temp_output_7_0_g1049 );
				float3 temp_output_4_0_g1047 = DickUp172_g1;
				float3 temp_output_10_0_g1049 = temp_output_4_0_g1047;
				float3 temp_output_3_0_g1047 = DickForward18_g1;
				float3 temp_output_13_0_g1049 = temp_output_3_0_g1047;
				float dotResult33_g1049 = dot( temp_output_7_0_g1049 , temp_output_10_0_g1049 );
				float3 lerpResult34_g1049 = lerp( temp_output_10_0_g1049 , -temp_output_13_0_g1049 , saturate( dotResult33_g1049 ));
				float dotResult37_g1049 = dot( temp_output_7_0_g1049 , -temp_output_10_0_g1049 );
				float3 lerpResult40_g1049 = lerp( lerpResult34_g1049 , temp_output_13_0_g1049 , saturate( dotResult37_g1049 ));
				float3 normalizeResult42_g1049 = normalize( lerpResult40_g1049 );
				float3 normalizeResult31_g1051 = normalize( normalizeResult42_g1049 );
				float3 normalizeResult29_g1051 = normalize( cross( normalizeResult27_g1051 , normalizeResult31_g1051 ) );
				float3 temp_output_65_22_g1047 = normalizeResult29_g1051;
				float3 temp_output_2_0_g1047 = ( lerpResult343_g1 - DickOrigin16_g1 );
				float3 temp_output_5_0_g1047 = DickRight184_g1;
				float dotResult15_g1047 = dot( temp_output_2_0_g1047 , temp_output_5_0_g1047 );
				float3 temp_output_65_0_g1047 = cross( normalizeResult29_g1051 , normalizeResult27_g1051 );
				float dotResult18_g1047 = dot( temp_output_2_0_g1047 , temp_output_4_0_g1047 );
				float temp_output_208_0_g1 = saturate( sign( temp_output_152_0_g1 ) );
				float3 lerpResult221_g1 = lerp( ( ( ( temp_output_19_0_g1058 * temp_output_19_0_g1058 * temp_output_19_0_g1058 * temp_output_8_0_g1057 ) + ( temp_output_19_0_g1058 * temp_output_19_0_g1058 * 3.0 * temp_output_26_0_g1058 * temp_output_9_0_g1057 ) + ( 3.0 * temp_output_19_0_g1058 * temp_output_26_0_g1058 * temp_output_26_0_g1058 * temp_output_10_0_g1057 ) + ( temp_output_26_0_g1058 * temp_output_26_0_g1058 * temp_output_26_0_g1058 * temp_output_11_0_g1057 ) ) + ( temp_output_65_22_g1057 * dotResult15_g1057 ) + ( temp_output_65_0_g1057 * dotResult18_g1057 ) ) , ( ( ( temp_output_19_0_g1048 * temp_output_19_0_g1048 * temp_output_19_0_g1048 * temp_output_8_0_g1047 ) + ( temp_output_19_0_g1048 * temp_output_19_0_g1048 * 3.0 * temp_output_26_0_g1048 * temp_output_9_0_g1047 ) + ( 3.0 * temp_output_19_0_g1048 * temp_output_26_0_g1048 * temp_output_26_0_g1048 * temp_output_10_0_g1047 ) + ( temp_output_26_0_g1048 * temp_output_26_0_g1048 * temp_output_26_0_g1048 * temp_output_11_0_g1047 ) ) + ( temp_output_65_22_g1047 * dotResult15_g1047 ) + ( temp_output_65_0_g1047 * dotResult18_g1047 ) ) , temp_output_208_0_g1);
				float3 temp_output_42_0_g1052 = DickForward18_g1;
				float NonVisibleLength165_g1 = ( temp_output_11_0_g1 * _PenetratorLength );
				float3 temp_output_52_0_g1052 = ( ( temp_output_42_0_g1052 * ( ( NonVisibleLength165_g1 - OrifaceLength34_g1 ) - DickLength19_g1 ) ) + ( lerpResult343_g1 - DickOrigin16_g1 ) );
				float dotResult53_g1052 = dot( temp_output_42_0_g1052 , temp_output_52_0_g1052 );
				float temp_output_1_0_g1054 = 1.0;
				float temp_output_8_0_g1054 = ( 1.0 - temp_output_1_0_g1054 );
				float3 temp_output_3_0_g1054 = OrifaceOutPosition1183_g1;
				float3 temp_output_4_0_g1054 = OrifaceOutPosition2182_g1;
				float3 temp_output_7_0_g1053 = ( ( 3.0 * temp_output_8_0_g1054 * temp_output_8_0_g1054 * ( temp_output_3_0_g1054 - OrifacePosition170_g1 ) ) + ( 6.0 * temp_output_8_0_g1054 * temp_output_1_0_g1054 * ( temp_output_4_0_g1054 - temp_output_3_0_g1054 ) ) + ( 3.0 * temp_output_1_0_g1054 * temp_output_1_0_g1054 * ( OrifaceOutPosition3175_g1 - temp_output_4_0_g1054 ) ) );
				float3 normalizeResult27_g1055 = normalize( temp_output_7_0_g1053 );
				float3 temp_output_85_23_g1052 = normalizeResult27_g1055;
				float3 temp_output_4_0_g1052 = DickUp172_g1;
				float dotResult54_g1052 = dot( temp_output_4_0_g1052 , temp_output_52_0_g1052 );
				float3 temp_output_10_0_g1053 = temp_output_4_0_g1052;
				float3 temp_output_13_0_g1053 = temp_output_42_0_g1052;
				float dotResult33_g1053 = dot( temp_output_7_0_g1053 , temp_output_10_0_g1053 );
				float3 lerpResult34_g1053 = lerp( temp_output_10_0_g1053 , -temp_output_13_0_g1053 , saturate( dotResult33_g1053 ));
				float dotResult37_g1053 = dot( temp_output_7_0_g1053 , -temp_output_10_0_g1053 );
				float3 lerpResult40_g1053 = lerp( lerpResult34_g1053 , temp_output_13_0_g1053 , saturate( dotResult37_g1053 ));
				float3 normalizeResult42_g1053 = normalize( lerpResult40_g1053 );
				float3 normalizeResult31_g1055 = normalize( normalizeResult42_g1053 );
				float3 normalizeResult29_g1055 = normalize( cross( normalizeResult27_g1055 , normalizeResult31_g1055 ) );
				float3 temp_output_85_0_g1052 = cross( normalizeResult29_g1055 , normalizeResult27_g1055 );
				float3 temp_output_43_0_g1052 = DickRight184_g1;
				float dotResult55_g1052 = dot( temp_output_43_0_g1052 , temp_output_52_0_g1052 );
				float3 temp_output_85_22_g1052 = normalizeResult29_g1055;
				float temp_output_222_0_g1 = saturate( sign( ( temp_output_157_0_g1 - 1.0 ) ) );
				float3 lerpResult224_g1 = lerp( lerpResult221_g1 , ( ( ( dotResult53_g1052 * temp_output_85_23_g1052 ) + ( dotResult54_g1052 * temp_output_85_0_g1052 ) + ( dotResult55_g1052 * temp_output_85_22_g1052 ) ) + OrifaceOutPosition3175_g1 ) , temp_output_222_0_g1);
				float3 lerpResult418_g1 = lerp( lerpResult224_g1 , lerpResult221_g1 , ClipDick413_g1);
				float temp_output_226_0_g1 = saturate( -PenetrationDepth39_g1 );
				float3 lerpResult232_g1 = lerp( lerpResult418_g1 , originalPosition126_g1 , temp_output_226_0_g1);
				float3 ifLocalVar237_g1 = 0;
				if( temp_output_234_0_g1 <= 0.0 )
				ifLocalVar237_g1 = originalPosition126_g1;
				else
				ifLocalVar237_g1 = lerpResult232_g1;
				float DeformBalls426_g1 = _DeformBalls;
				float3 lerpResult428_g1 = lerp( ifLocalVar237_g1 , lerpResult232_g1 , DeformBalls426_g1);
				
				float3 temp_output_21_0_g1057 = VertexNormal259_g1;
				float dotResult55_g1057 = dot( temp_output_21_0_g1057 , temp_output_3_0_g1057 );
				float dotResult56_g1057 = dot( temp_output_21_0_g1057 , temp_output_4_0_g1057 );
				float dotResult57_g1057 = dot( temp_output_21_0_g1057 , temp_output_5_0_g1057 );
				float3 normalizeResult31_g1057 = normalize( ( ( dotResult55_g1057 * normalizeResult27_g1061 ) + ( dotResult56_g1057 * temp_output_65_0_g1057 ) + ( dotResult57_g1057 * temp_output_65_22_g1057 ) ) );
				float3 temp_output_21_0_g1047 = VertexNormal259_g1;
				float dotResult55_g1047 = dot( temp_output_21_0_g1047 , temp_output_3_0_g1047 );
				float dotResult56_g1047 = dot( temp_output_21_0_g1047 , temp_output_4_0_g1047 );
				float dotResult57_g1047 = dot( temp_output_21_0_g1047 , temp_output_5_0_g1047 );
				float3 normalizeResult31_g1047 = normalize( ( ( dotResult55_g1047 * normalizeResult27_g1051 ) + ( dotResult56_g1047 * temp_output_65_0_g1047 ) + ( dotResult57_g1047 * temp_output_65_22_g1047 ) ) );
				float3 lerpResult227_g1 = lerp( normalizeResult31_g1057 , normalizeResult31_g1047 , temp_output_208_0_g1);
				float3 temp_output_24_0_g1052 = VertexNormal259_g1;
				float dotResult61_g1052 = dot( temp_output_42_0_g1052 , temp_output_24_0_g1052 );
				float dotResult62_g1052 = dot( temp_output_4_0_g1052 , temp_output_24_0_g1052 );
				float dotResult60_g1052 = dot( temp_output_43_0_g1052 , temp_output_24_0_g1052 );
				float3 normalizeResult33_g1052 = normalize( ( ( dotResult61_g1052 * temp_output_85_23_g1052 ) + ( dotResult62_g1052 * temp_output_85_0_g1052 ) + ( dotResult60_g1052 * temp_output_85_22_g1052 ) ) );
				float3 lerpResult233_g1 = lerp( lerpResult227_g1 , normalizeResult33_g1052 , temp_output_222_0_g1);
				float3 lerpResult419_g1 = lerp( lerpResult233_g1 , lerpResult227_g1 , ClipDick413_g1);
				float3 lerpResult238_g1 = lerp( lerpResult419_g1 , VertexNormal259_g1 , temp_output_226_0_g1);
				float3 ifLocalVar391_g1 = 0;
				if( temp_output_234_0_g1 <= 0.0 )
				ifLocalVar391_g1 = VertexNormal259_g1;
				else
				ifLocalVar391_g1 = lerpResult238_g1;
				
				float3 ase_worldNormal = TransformObjectToWorldNormal(v.ase_normal);
				o.ase_texcoord3.xyz = ase_worldNormal;
				
				float lerpResult424_g1 = lerp( 1.0 , InsideLerp123_g1 , InvisibleWhenInside420_g1);
				float vertexToFrag250_g1 = lerpResult424_g1;
				o.ase_texcoord2.z = vertexToFrag250_g1;
				
				o.ase_texcoord2.xy = v.ase_texcoord.xy;
				o.ase_texcoord4 = v.texcoord1;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord2.w = 0;
				o.ase_texcoord3.w = 0;
				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = lerpResult428_g1;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = ifLocalVar391_g1;

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

				float2 uv_GooTongue_TongueMaterial_AlbedoTransparency = IN.ase_texcoord2.xy * _GooTongue_TongueMaterial_AlbedoTransparency_ST.xy + _GooTongue_TongueMaterial_AlbedoTransparency_ST.zw;
				
				float4 color37 = IsGammaSpace() ? float4(0.6033356,0.1512549,0.9716981,1) : float4(0.322454,0.01989593,0.9368213,1);
				float3 ase_worldViewDir = ( _WorldSpaceCameraPos.xyz - WorldPosition );
				ase_worldViewDir = normalize(ase_worldViewDir);
				float3 ase_worldNormal = IN.ase_texcoord3.xyz;
				float dotResult31 = dot( ase_worldViewDir , ase_worldNormal );
				float2 texCoord9 = IN.ase_texcoord4.xy * float2( 1,0.5 ) + float2( 0,0 );
				float2 break17 = texCoord9;
				float mulTime16 = _TimeParameters.x * 0.08;
				float2 appendResult19 = (float2(break17.x , ( mulTime16 + break17.y )));
				float4 tex2DNode8 = tex2D( _BulgeLanes_output, appendResult19 );
				float2 texCoord41 = IN.ase_texcoord4.xy * float2( 1,1 ) + float2( 0,0 );
				float temp_output_43_0 = saturate( sign( ( texCoord41.y - ( 1.0 - _BulgeClip ) ) ) );
				float4 lerpResult36 = lerp( float4( 0,0,0,0 ) , color37 , ( abs( dotResult31 ) * tex2DNode8.r * temp_output_43_0 ));
				
				float vertexToFrag250_g1 = IN.ase_texcoord2.z;
				
				
				float3 Albedo = tex2D( _GooTongue_TongueMaterial_AlbedoTransparency, uv_GooTongue_TongueMaterial_AlbedoTransparency ).rgb;
				float3 Emission = lerpResult36.rgb;
				float Alpha = vertexToFrag250_g1;
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
			float4 _GooTongue_TongueMaterial_MetallicSmoothness_ST;
			float4 _GooTongue_TongueMaterial_Normal_ST;
			float4 _GooTongue_TongueMaterial_AlbedoTransparency_ST;
			float4 _BulgeLanes_normal_ST;
			float3 _PenetratorOrigin;
			float3 _OrificeWorldPosition;
			float3 _PenetratorUp;
			float3 _OrificeOutWorldPosition3;
			float3 _PenetratorForward;
			float3 _OrificeOutWorldPosition2;
			float3 _OrificeOutWorldPosition1;
			float3 _OrificeWorldNormal;
			float3 _PenetratorRight;
			float _DeformBalls;
			float _InvisibleWhenInside;
			float _ClipDick;
			float _NoBlendshapes;
			float _PinchBuffer;
			float _PenetratorCumActive;
			float _PenetratorCumProgress;
			float _PenetratorSquishPullAmount;
			float _PenetratorBulgePercentage;
			float _BulgeClip;
			float _BulgeAmount;
			float _PenetrationDepth;
			float _PenetratorLength;
			float _OrificeLength;
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
			sampler2D _BulgeLanes_output;
			sampler2D _GooTongue_TongueMaterial_AlbedoTransparency;


			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				float3 VertexNormal259_g1 = v.ase_normal;
				float3 normalizeResult27_g1062 = normalize( VertexNormal259_g1 );
				float3 temp_output_35_0_g1 = normalizeResult27_g1062;
				float3 normalizeResult31_g1062 = normalize( v.ase_tangent.xyz );
				float3 normalizeResult29_g1062 = normalize( cross( normalizeResult27_g1062 , normalizeResult31_g1062 ) );
				float3 temp_output_35_1_g1 = cross( normalizeResult29_g1062 , normalizeResult27_g1062 );
				float3 temp_output_35_2_g1 = normalizeResult29_g1062;
				float3 SquishDelta85_g1 = ( ( ( temp_output_35_0_g1 * v.ase_texcoord2.x ) + ( temp_output_35_1_g1 * v.ase_texcoord2.y ) + ( temp_output_35_2_g1 * v.ase_texcoord2.z ) ) * _PenetratorBlendshapeMultiplier );
				float temp_output_234_0_g1 = length( SquishDelta85_g1 );
				float temp_output_11_0_g1 = max( _PenetrationDepth , 0.0 );
				float VisibleLength25_g1 = ( _PenetratorLength * ( 1.0 - temp_output_11_0_g1 ) );
				float3 DickOrigin16_g1 = _PenetratorOrigin;
				float4 appendResult132_g1 = (float4(_OrificeWorldPosition , 1.0));
				float4 transform140_g1 = mul(GetWorldToObjectMatrix(),appendResult132_g1);
				float3 OrifacePosition170_g1 = (transform140_g1).xyz;
				float DickLength19_g1 = _PenetratorLength;
				float3 DickUp172_g1 = _PenetratorUp;
				float2 texCoord9 = v.ase_texcoord1 * float2( 1,0.5 ) + float2( 0,0 );
				float2 break17 = texCoord9;
				float mulTime16 = _TimeParameters.x * 0.08;
				float2 appendResult19 = (float2(break17.x , ( mulTime16 + break17.y )));
				float4 tex2DNode8 = tex2Dlod( _BulgeLanes_output, float4( appendResult19, 0, 0.0) );
				float2 texCoord41 = v.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float temp_output_43_0 = saturate( sign( ( texCoord41.y - ( 1.0 - _BulgeClip ) ) ) );
				float3 VertexPosition254_g1 = ( ( v.ase_normal * tex2DNode8.r * _BulgeAmount * temp_output_43_0 ) + v.vertex.xyz );
				float3 temp_output_27_0_g1 = ( VertexPosition254_g1 - DickOrigin16_g1 );
				float3 DickForward18_g1 = _PenetratorForward;
				float dotResult42_g1 = dot( temp_output_27_0_g1 , DickForward18_g1 );
				float BulgePercentage37_g1 = _PenetratorBulgePercentage;
				float temp_output_1_0_g1056 = saturate( ( abs( ( dotResult42_g1 - VisibleLength25_g1 ) ) / ( DickLength19_g1 * BulgePercentage37_g1 ) ) );
				float temp_output_94_0_g1 = sqrt( ( 1.0 - ( temp_output_1_0_g1056 * temp_output_1_0_g1056 ) ) );
				float3 PullDelta91_g1 = ( ( ( temp_output_35_0_g1 * v.ase_texcoord3.x ) + ( temp_output_35_1_g1 * v.ase_texcoord3.y ) + ( temp_output_35_2_g1 * v.ase_texcoord3.z ) ) * _PenetratorBlendshapeMultiplier );
				float dotResult32_g1 = dot( temp_output_27_0_g1 , DickForward18_g1 );
				float temp_output_1_0_g1063 = saturate( ( abs( ( dotResult32_g1 - ( DickLength19_g1 * _PenetratorCumProgress ) ) ) / ( DickLength19_g1 * BulgePercentage37_g1 ) ) );
				float3 CumDelta90_g1 = ( ( ( temp_output_35_0_g1 * v.ase_texcoord1.w ) + ( temp_output_35_1_g1 * v.ase_texcoord2.w ) + ( temp_output_35_2_g1 * v.ase_texcoord3.w ) ) * _PenetratorBlendshapeMultiplier );
				float3 lerpResult410_g1 = lerp( ( VertexPosition254_g1 + ( SquishDelta85_g1 * temp_output_94_0_g1 * saturate( -_PenetratorSquishPullAmount ) ) + ( temp_output_94_0_g1 * PullDelta91_g1 * saturate( _PenetratorSquishPullAmount ) ) + ( sqrt( ( 1.0 - ( temp_output_1_0_g1063 * temp_output_1_0_g1063 ) ) ) * CumDelta90_g1 * _PenetratorCumActive ) ) , VertexPosition254_g1 , _NoBlendshapes);
				float3 originalPosition126_g1 = lerpResult410_g1;
				float dotResult118_g1 = dot( ( lerpResult410_g1 - DickOrigin16_g1 ) , DickForward18_g1 );
				float PenetrationDepth39_g1 = _PenetrationDepth;
				float temp_output_65_0_g1 = ( PenetrationDepth39_g1 * DickLength19_g1 );
				float OrifaceLength34_g1 = _OrificeLength;
				float temp_output_73_0_g1 = ( _PinchBuffer * OrifaceLength34_g1 );
				float dotResult80_g1 = dot( ( lerpResult410_g1 - DickOrigin16_g1 ) , DickForward18_g1 );
				float temp_output_112_0_g1 = ( -( ( ( temp_output_65_0_g1 - temp_output_73_0_g1 ) + dotResult80_g1 ) - DickLength19_g1 ) * 10.0 );
				float ClipDick413_g1 = _ClipDick;
				float lerpResult411_g1 = lerp( max( temp_output_112_0_g1 , ( ( ( temp_output_65_0_g1 + dotResult80_g1 + temp_output_73_0_g1 ) - ( OrifaceLength34_g1 + DickLength19_g1 ) ) * 10.0 ) ) , temp_output_112_0_g1 , ClipDick413_g1);
				float InsideLerp123_g1 = saturate( lerpResult411_g1 );
				float3 lerpResult124_g1 = lerp( ( ( DickForward18_g1 * dotResult118_g1 ) + DickOrigin16_g1 ) , originalPosition126_g1 , InsideLerp123_g1);
				float InvisibleWhenInside420_g1 = _InvisibleWhenInside;
				float3 lerpResult422_g1 = lerp( originalPosition126_g1 , lerpResult124_g1 , InvisibleWhenInside420_g1);
				float3 temp_output_354_0_g1 = ( lerpResult422_g1 - DickOrigin16_g1 );
				float dotResult373_g1 = dot( DickUp172_g1 , temp_output_354_0_g1 );
				float3 DickRight184_g1 = _PenetratorRight;
				float dotResult374_g1 = dot( DickRight184_g1 , temp_output_354_0_g1 );
				float dotResult375_g1 = dot( temp_output_354_0_g1 , DickForward18_g1 );
				float3 lerpResult343_g1 = lerp( ( ( ( saturate( ( ( VisibleLength25_g1 - distance( DickOrigin16_g1 , OrifacePosition170_g1 ) ) / DickLength19_g1 ) ) + 1.0 ) * dotResult373_g1 * DickUp172_g1 ) + ( ( saturate( ( ( VisibleLength25_g1 - distance( DickOrigin16_g1 , OrifacePosition170_g1 ) ) / DickLength19_g1 ) ) + 1.0 ) * dotResult374_g1 * DickRight184_g1 ) + ( DickForward18_g1 * dotResult375_g1 ) + DickOrigin16_g1 ) , lerpResult422_g1 , saturate( PenetrationDepth39_g1 ));
				float dotResult177_g1 = dot( ( lerpResult343_g1 - DickOrigin16_g1 ) , DickForward18_g1 );
				float temp_output_178_0_g1 = max( VisibleLength25_g1 , 0.05 );
				float temp_output_42_0_g1057 = ( dotResult177_g1 / temp_output_178_0_g1 );
				float temp_output_26_0_g1058 = temp_output_42_0_g1057;
				float temp_output_19_0_g1058 = ( 1.0 - temp_output_26_0_g1058 );
				float3 temp_output_8_0_g1057 = DickOrigin16_g1;
				float temp_output_393_0_g1 = distance( DickOrigin16_g1 , OrifacePosition170_g1 );
				float temp_output_396_0_g1 = min( temp_output_178_0_g1 , temp_output_393_0_g1 );
				float3 temp_output_9_0_g1057 = ( DickOrigin16_g1 + ( DickForward18_g1 * temp_output_396_0_g1 * 0.25 ) );
				float4 appendResult130_g1 = (float4(_OrificeWorldNormal , 0.0));
				float4 transform135_g1 = mul(GetWorldToObjectMatrix(),appendResult130_g1);
				float3 OrifaceNormal155_g1 = (transform135_g1).xyz;
				float3 temp_output_10_0_g1057 = ( OrifacePosition170_g1 + ( OrifaceNormal155_g1 * 0.25 * temp_output_396_0_g1 ) );
				float3 temp_output_11_0_g1057 = OrifacePosition170_g1;
				float temp_output_1_0_g1060 = temp_output_42_0_g1057;
				float temp_output_8_0_g1060 = ( 1.0 - temp_output_1_0_g1060 );
				float3 temp_output_3_0_g1060 = temp_output_9_0_g1057;
				float3 temp_output_4_0_g1060 = temp_output_10_0_g1057;
				float3 temp_output_7_0_g1059 = ( ( 3.0 * temp_output_8_0_g1060 * temp_output_8_0_g1060 * ( temp_output_3_0_g1060 - temp_output_8_0_g1057 ) ) + ( 6.0 * temp_output_8_0_g1060 * temp_output_1_0_g1060 * ( temp_output_4_0_g1060 - temp_output_3_0_g1060 ) ) + ( 3.0 * temp_output_1_0_g1060 * temp_output_1_0_g1060 * ( temp_output_11_0_g1057 - temp_output_4_0_g1060 ) ) );
				float3 normalizeResult27_g1061 = normalize( temp_output_7_0_g1059 );
				float3 temp_output_4_0_g1057 = DickUp172_g1;
				float3 temp_output_10_0_g1059 = temp_output_4_0_g1057;
				float3 temp_output_3_0_g1057 = DickForward18_g1;
				float3 temp_output_13_0_g1059 = temp_output_3_0_g1057;
				float dotResult33_g1059 = dot( temp_output_7_0_g1059 , temp_output_10_0_g1059 );
				float3 lerpResult34_g1059 = lerp( temp_output_10_0_g1059 , -temp_output_13_0_g1059 , saturate( dotResult33_g1059 ));
				float dotResult37_g1059 = dot( temp_output_7_0_g1059 , -temp_output_10_0_g1059 );
				float3 lerpResult40_g1059 = lerp( lerpResult34_g1059 , temp_output_13_0_g1059 , saturate( dotResult37_g1059 ));
				float3 normalizeResult42_g1059 = normalize( lerpResult40_g1059 );
				float3 normalizeResult31_g1061 = normalize( normalizeResult42_g1059 );
				float3 normalizeResult29_g1061 = normalize( cross( normalizeResult27_g1061 , normalizeResult31_g1061 ) );
				float3 temp_output_65_22_g1057 = normalizeResult29_g1061;
				float3 temp_output_2_0_g1057 = ( lerpResult343_g1 - DickOrigin16_g1 );
				float3 temp_output_5_0_g1057 = DickRight184_g1;
				float dotResult15_g1057 = dot( temp_output_2_0_g1057 , temp_output_5_0_g1057 );
				float3 temp_output_65_0_g1057 = cross( normalizeResult29_g1061 , normalizeResult27_g1061 );
				float dotResult18_g1057 = dot( temp_output_2_0_g1057 , temp_output_4_0_g1057 );
				float dotResult142_g1 = dot( ( lerpResult343_g1 - DickOrigin16_g1 ) , DickForward18_g1 );
				float temp_output_152_0_g1 = ( dotResult142_g1 - VisibleLength25_g1 );
				float temp_output_157_0_g1 = ( temp_output_152_0_g1 / OrifaceLength34_g1 );
				float lerpResult416_g1 = lerp( temp_output_157_0_g1 , min( temp_output_157_0_g1 , 1.0 ) , ClipDick413_g1);
				float temp_output_42_0_g1047 = lerpResult416_g1;
				float temp_output_26_0_g1048 = temp_output_42_0_g1047;
				float temp_output_19_0_g1048 = ( 1.0 - temp_output_26_0_g1048 );
				float3 temp_output_8_0_g1047 = OrifacePosition170_g1;
				float4 appendResult145_g1 = (float4(_OrificeOutWorldPosition1 , 1.0));
				float4 transform151_g1 = mul(GetWorldToObjectMatrix(),appendResult145_g1);
				float3 OrifaceOutPosition1183_g1 = (transform151_g1).xyz;
				float3 temp_output_9_0_g1047 = OrifaceOutPosition1183_g1;
				float4 appendResult144_g1 = (float4(_OrificeOutWorldPosition2 , 1.0));
				float4 transform154_g1 = mul(GetWorldToObjectMatrix(),appendResult144_g1);
				float3 OrifaceOutPosition2182_g1 = (transform154_g1).xyz;
				float3 temp_output_10_0_g1047 = OrifaceOutPosition2182_g1;
				float4 appendResult143_g1 = (float4(_OrificeOutWorldPosition3 , 1.0));
				float4 transform147_g1 = mul(GetWorldToObjectMatrix(),appendResult143_g1);
				float3 OrifaceOutPosition3175_g1 = (transform147_g1).xyz;
				float3 temp_output_11_0_g1047 = OrifaceOutPosition3175_g1;
				float temp_output_1_0_g1050 = temp_output_42_0_g1047;
				float temp_output_8_0_g1050 = ( 1.0 - temp_output_1_0_g1050 );
				float3 temp_output_3_0_g1050 = temp_output_9_0_g1047;
				float3 temp_output_4_0_g1050 = temp_output_10_0_g1047;
				float3 temp_output_7_0_g1049 = ( ( 3.0 * temp_output_8_0_g1050 * temp_output_8_0_g1050 * ( temp_output_3_0_g1050 - temp_output_8_0_g1047 ) ) + ( 6.0 * temp_output_8_0_g1050 * temp_output_1_0_g1050 * ( temp_output_4_0_g1050 - temp_output_3_0_g1050 ) ) + ( 3.0 * temp_output_1_0_g1050 * temp_output_1_0_g1050 * ( temp_output_11_0_g1047 - temp_output_4_0_g1050 ) ) );
				float3 normalizeResult27_g1051 = normalize( temp_output_7_0_g1049 );
				float3 temp_output_4_0_g1047 = DickUp172_g1;
				float3 temp_output_10_0_g1049 = temp_output_4_0_g1047;
				float3 temp_output_3_0_g1047 = DickForward18_g1;
				float3 temp_output_13_0_g1049 = temp_output_3_0_g1047;
				float dotResult33_g1049 = dot( temp_output_7_0_g1049 , temp_output_10_0_g1049 );
				float3 lerpResult34_g1049 = lerp( temp_output_10_0_g1049 , -temp_output_13_0_g1049 , saturate( dotResult33_g1049 ));
				float dotResult37_g1049 = dot( temp_output_7_0_g1049 , -temp_output_10_0_g1049 );
				float3 lerpResult40_g1049 = lerp( lerpResult34_g1049 , temp_output_13_0_g1049 , saturate( dotResult37_g1049 ));
				float3 normalizeResult42_g1049 = normalize( lerpResult40_g1049 );
				float3 normalizeResult31_g1051 = normalize( normalizeResult42_g1049 );
				float3 normalizeResult29_g1051 = normalize( cross( normalizeResult27_g1051 , normalizeResult31_g1051 ) );
				float3 temp_output_65_22_g1047 = normalizeResult29_g1051;
				float3 temp_output_2_0_g1047 = ( lerpResult343_g1 - DickOrigin16_g1 );
				float3 temp_output_5_0_g1047 = DickRight184_g1;
				float dotResult15_g1047 = dot( temp_output_2_0_g1047 , temp_output_5_0_g1047 );
				float3 temp_output_65_0_g1047 = cross( normalizeResult29_g1051 , normalizeResult27_g1051 );
				float dotResult18_g1047 = dot( temp_output_2_0_g1047 , temp_output_4_0_g1047 );
				float temp_output_208_0_g1 = saturate( sign( temp_output_152_0_g1 ) );
				float3 lerpResult221_g1 = lerp( ( ( ( temp_output_19_0_g1058 * temp_output_19_0_g1058 * temp_output_19_0_g1058 * temp_output_8_0_g1057 ) + ( temp_output_19_0_g1058 * temp_output_19_0_g1058 * 3.0 * temp_output_26_0_g1058 * temp_output_9_0_g1057 ) + ( 3.0 * temp_output_19_0_g1058 * temp_output_26_0_g1058 * temp_output_26_0_g1058 * temp_output_10_0_g1057 ) + ( temp_output_26_0_g1058 * temp_output_26_0_g1058 * temp_output_26_0_g1058 * temp_output_11_0_g1057 ) ) + ( temp_output_65_22_g1057 * dotResult15_g1057 ) + ( temp_output_65_0_g1057 * dotResult18_g1057 ) ) , ( ( ( temp_output_19_0_g1048 * temp_output_19_0_g1048 * temp_output_19_0_g1048 * temp_output_8_0_g1047 ) + ( temp_output_19_0_g1048 * temp_output_19_0_g1048 * 3.0 * temp_output_26_0_g1048 * temp_output_9_0_g1047 ) + ( 3.0 * temp_output_19_0_g1048 * temp_output_26_0_g1048 * temp_output_26_0_g1048 * temp_output_10_0_g1047 ) + ( temp_output_26_0_g1048 * temp_output_26_0_g1048 * temp_output_26_0_g1048 * temp_output_11_0_g1047 ) ) + ( temp_output_65_22_g1047 * dotResult15_g1047 ) + ( temp_output_65_0_g1047 * dotResult18_g1047 ) ) , temp_output_208_0_g1);
				float3 temp_output_42_0_g1052 = DickForward18_g1;
				float NonVisibleLength165_g1 = ( temp_output_11_0_g1 * _PenetratorLength );
				float3 temp_output_52_0_g1052 = ( ( temp_output_42_0_g1052 * ( ( NonVisibleLength165_g1 - OrifaceLength34_g1 ) - DickLength19_g1 ) ) + ( lerpResult343_g1 - DickOrigin16_g1 ) );
				float dotResult53_g1052 = dot( temp_output_42_0_g1052 , temp_output_52_0_g1052 );
				float temp_output_1_0_g1054 = 1.0;
				float temp_output_8_0_g1054 = ( 1.0 - temp_output_1_0_g1054 );
				float3 temp_output_3_0_g1054 = OrifaceOutPosition1183_g1;
				float3 temp_output_4_0_g1054 = OrifaceOutPosition2182_g1;
				float3 temp_output_7_0_g1053 = ( ( 3.0 * temp_output_8_0_g1054 * temp_output_8_0_g1054 * ( temp_output_3_0_g1054 - OrifacePosition170_g1 ) ) + ( 6.0 * temp_output_8_0_g1054 * temp_output_1_0_g1054 * ( temp_output_4_0_g1054 - temp_output_3_0_g1054 ) ) + ( 3.0 * temp_output_1_0_g1054 * temp_output_1_0_g1054 * ( OrifaceOutPosition3175_g1 - temp_output_4_0_g1054 ) ) );
				float3 normalizeResult27_g1055 = normalize( temp_output_7_0_g1053 );
				float3 temp_output_85_23_g1052 = normalizeResult27_g1055;
				float3 temp_output_4_0_g1052 = DickUp172_g1;
				float dotResult54_g1052 = dot( temp_output_4_0_g1052 , temp_output_52_0_g1052 );
				float3 temp_output_10_0_g1053 = temp_output_4_0_g1052;
				float3 temp_output_13_0_g1053 = temp_output_42_0_g1052;
				float dotResult33_g1053 = dot( temp_output_7_0_g1053 , temp_output_10_0_g1053 );
				float3 lerpResult34_g1053 = lerp( temp_output_10_0_g1053 , -temp_output_13_0_g1053 , saturate( dotResult33_g1053 ));
				float dotResult37_g1053 = dot( temp_output_7_0_g1053 , -temp_output_10_0_g1053 );
				float3 lerpResult40_g1053 = lerp( lerpResult34_g1053 , temp_output_13_0_g1053 , saturate( dotResult37_g1053 ));
				float3 normalizeResult42_g1053 = normalize( lerpResult40_g1053 );
				float3 normalizeResult31_g1055 = normalize( normalizeResult42_g1053 );
				float3 normalizeResult29_g1055 = normalize( cross( normalizeResult27_g1055 , normalizeResult31_g1055 ) );
				float3 temp_output_85_0_g1052 = cross( normalizeResult29_g1055 , normalizeResult27_g1055 );
				float3 temp_output_43_0_g1052 = DickRight184_g1;
				float dotResult55_g1052 = dot( temp_output_43_0_g1052 , temp_output_52_0_g1052 );
				float3 temp_output_85_22_g1052 = normalizeResult29_g1055;
				float temp_output_222_0_g1 = saturate( sign( ( temp_output_157_0_g1 - 1.0 ) ) );
				float3 lerpResult224_g1 = lerp( lerpResult221_g1 , ( ( ( dotResult53_g1052 * temp_output_85_23_g1052 ) + ( dotResult54_g1052 * temp_output_85_0_g1052 ) + ( dotResult55_g1052 * temp_output_85_22_g1052 ) ) + OrifaceOutPosition3175_g1 ) , temp_output_222_0_g1);
				float3 lerpResult418_g1 = lerp( lerpResult224_g1 , lerpResult221_g1 , ClipDick413_g1);
				float temp_output_226_0_g1 = saturate( -PenetrationDepth39_g1 );
				float3 lerpResult232_g1 = lerp( lerpResult418_g1 , originalPosition126_g1 , temp_output_226_0_g1);
				float3 ifLocalVar237_g1 = 0;
				if( temp_output_234_0_g1 <= 0.0 )
				ifLocalVar237_g1 = originalPosition126_g1;
				else
				ifLocalVar237_g1 = lerpResult232_g1;
				float DeformBalls426_g1 = _DeformBalls;
				float3 lerpResult428_g1 = lerp( ifLocalVar237_g1 , lerpResult232_g1 , DeformBalls426_g1);
				
				float3 temp_output_21_0_g1057 = VertexNormal259_g1;
				float dotResult55_g1057 = dot( temp_output_21_0_g1057 , temp_output_3_0_g1057 );
				float dotResult56_g1057 = dot( temp_output_21_0_g1057 , temp_output_4_0_g1057 );
				float dotResult57_g1057 = dot( temp_output_21_0_g1057 , temp_output_5_0_g1057 );
				float3 normalizeResult31_g1057 = normalize( ( ( dotResult55_g1057 * normalizeResult27_g1061 ) + ( dotResult56_g1057 * temp_output_65_0_g1057 ) + ( dotResult57_g1057 * temp_output_65_22_g1057 ) ) );
				float3 temp_output_21_0_g1047 = VertexNormal259_g1;
				float dotResult55_g1047 = dot( temp_output_21_0_g1047 , temp_output_3_0_g1047 );
				float dotResult56_g1047 = dot( temp_output_21_0_g1047 , temp_output_4_0_g1047 );
				float dotResult57_g1047 = dot( temp_output_21_0_g1047 , temp_output_5_0_g1047 );
				float3 normalizeResult31_g1047 = normalize( ( ( dotResult55_g1047 * normalizeResult27_g1051 ) + ( dotResult56_g1047 * temp_output_65_0_g1047 ) + ( dotResult57_g1047 * temp_output_65_22_g1047 ) ) );
				float3 lerpResult227_g1 = lerp( normalizeResult31_g1057 , normalizeResult31_g1047 , temp_output_208_0_g1);
				float3 temp_output_24_0_g1052 = VertexNormal259_g1;
				float dotResult61_g1052 = dot( temp_output_42_0_g1052 , temp_output_24_0_g1052 );
				float dotResult62_g1052 = dot( temp_output_4_0_g1052 , temp_output_24_0_g1052 );
				float dotResult60_g1052 = dot( temp_output_43_0_g1052 , temp_output_24_0_g1052 );
				float3 normalizeResult33_g1052 = normalize( ( ( dotResult61_g1052 * temp_output_85_23_g1052 ) + ( dotResult62_g1052 * temp_output_85_0_g1052 ) + ( dotResult60_g1052 * temp_output_85_22_g1052 ) ) );
				float3 lerpResult233_g1 = lerp( lerpResult227_g1 , normalizeResult33_g1052 , temp_output_222_0_g1);
				float3 lerpResult419_g1 = lerp( lerpResult233_g1 , lerpResult227_g1 , ClipDick413_g1);
				float3 lerpResult238_g1 = lerp( lerpResult419_g1 , VertexNormal259_g1 , temp_output_226_0_g1);
				float3 ifLocalVar391_g1 = 0;
				if( temp_output_234_0_g1 <= 0.0 )
				ifLocalVar391_g1 = VertexNormal259_g1;
				else
				ifLocalVar391_g1 = lerpResult238_g1;
				
				float lerpResult424_g1 = lerp( 1.0 , InsideLerp123_g1 , InvisibleWhenInside420_g1);
				float vertexToFrag250_g1 = lerpResult424_g1;
				o.ase_texcoord2.z = vertexToFrag250_g1;
				
				o.ase_texcoord2.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord2.w = 0;
				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = lerpResult428_g1;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = ifLocalVar391_g1;

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

				float2 uv_GooTongue_TongueMaterial_AlbedoTransparency = IN.ase_texcoord2.xy * _GooTongue_TongueMaterial_AlbedoTransparency_ST.xy + _GooTongue_TongueMaterial_AlbedoTransparency_ST.zw;
				
				float vertexToFrag250_g1 = IN.ase_texcoord2.z;
				
				
				float3 Albedo = tex2D( _GooTongue_TongueMaterial_AlbedoTransparency, uv_GooTongue_TongueMaterial_AlbedoTransparency ).rgb;
				float Alpha = vertexToFrag250_g1;
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
			float4 _GooTongue_TongueMaterial_MetallicSmoothness_ST;
			float4 _GooTongue_TongueMaterial_Normal_ST;
			float4 _GooTongue_TongueMaterial_AlbedoTransparency_ST;
			float4 _BulgeLanes_normal_ST;
			float3 _PenetratorOrigin;
			float3 _OrificeWorldPosition;
			float3 _PenetratorUp;
			float3 _OrificeOutWorldPosition3;
			float3 _PenetratorForward;
			float3 _OrificeOutWorldPosition2;
			float3 _OrificeOutWorldPosition1;
			float3 _OrificeWorldNormal;
			float3 _PenetratorRight;
			float _DeformBalls;
			float _InvisibleWhenInside;
			float _ClipDick;
			float _NoBlendshapes;
			float _PinchBuffer;
			float _PenetratorCumActive;
			float _PenetratorCumProgress;
			float _PenetratorSquishPullAmount;
			float _PenetratorBulgePercentage;
			float _BulgeClip;
			float _BulgeAmount;
			float _PenetrationDepth;
			float _PenetratorLength;
			float _OrificeLength;
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
			sampler2D _BulgeLanes_output;


			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 VertexNormal259_g1 = v.ase_normal;
				float3 normalizeResult27_g1062 = normalize( VertexNormal259_g1 );
				float3 temp_output_35_0_g1 = normalizeResult27_g1062;
				float3 normalizeResult31_g1062 = normalize( v.ase_tangent.xyz );
				float3 normalizeResult29_g1062 = normalize( cross( normalizeResult27_g1062 , normalizeResult31_g1062 ) );
				float3 temp_output_35_1_g1 = cross( normalizeResult29_g1062 , normalizeResult27_g1062 );
				float3 temp_output_35_2_g1 = normalizeResult29_g1062;
				float3 SquishDelta85_g1 = ( ( ( temp_output_35_0_g1 * v.ase_texcoord2.x ) + ( temp_output_35_1_g1 * v.ase_texcoord2.y ) + ( temp_output_35_2_g1 * v.ase_texcoord2.z ) ) * _PenetratorBlendshapeMultiplier );
				float temp_output_234_0_g1 = length( SquishDelta85_g1 );
				float temp_output_11_0_g1 = max( _PenetrationDepth , 0.0 );
				float VisibleLength25_g1 = ( _PenetratorLength * ( 1.0 - temp_output_11_0_g1 ) );
				float3 DickOrigin16_g1 = _PenetratorOrigin;
				float4 appendResult132_g1 = (float4(_OrificeWorldPosition , 1.0));
				float4 transform140_g1 = mul(GetWorldToObjectMatrix(),appendResult132_g1);
				float3 OrifacePosition170_g1 = (transform140_g1).xyz;
				float DickLength19_g1 = _PenetratorLength;
				float3 DickUp172_g1 = _PenetratorUp;
				float2 texCoord9 = v.ase_texcoord1 * float2( 1,0.5 ) + float2( 0,0 );
				float2 break17 = texCoord9;
				float mulTime16 = _TimeParameters.x * 0.08;
				float2 appendResult19 = (float2(break17.x , ( mulTime16 + break17.y )));
				float4 tex2DNode8 = tex2Dlod( _BulgeLanes_output, float4( appendResult19, 0, 0.0) );
				float2 texCoord41 = v.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float temp_output_43_0 = saturate( sign( ( texCoord41.y - ( 1.0 - _BulgeClip ) ) ) );
				float3 VertexPosition254_g1 = ( ( v.ase_normal * tex2DNode8.r * _BulgeAmount * temp_output_43_0 ) + v.vertex.xyz );
				float3 temp_output_27_0_g1 = ( VertexPosition254_g1 - DickOrigin16_g1 );
				float3 DickForward18_g1 = _PenetratorForward;
				float dotResult42_g1 = dot( temp_output_27_0_g1 , DickForward18_g1 );
				float BulgePercentage37_g1 = _PenetratorBulgePercentage;
				float temp_output_1_0_g1056 = saturate( ( abs( ( dotResult42_g1 - VisibleLength25_g1 ) ) / ( DickLength19_g1 * BulgePercentage37_g1 ) ) );
				float temp_output_94_0_g1 = sqrt( ( 1.0 - ( temp_output_1_0_g1056 * temp_output_1_0_g1056 ) ) );
				float3 PullDelta91_g1 = ( ( ( temp_output_35_0_g1 * v.ase_texcoord3.x ) + ( temp_output_35_1_g1 * v.ase_texcoord3.y ) + ( temp_output_35_2_g1 * v.ase_texcoord3.z ) ) * _PenetratorBlendshapeMultiplier );
				float dotResult32_g1 = dot( temp_output_27_0_g1 , DickForward18_g1 );
				float temp_output_1_0_g1063 = saturate( ( abs( ( dotResult32_g1 - ( DickLength19_g1 * _PenetratorCumProgress ) ) ) / ( DickLength19_g1 * BulgePercentage37_g1 ) ) );
				float3 CumDelta90_g1 = ( ( ( temp_output_35_0_g1 * v.ase_texcoord1.w ) + ( temp_output_35_1_g1 * v.ase_texcoord2.w ) + ( temp_output_35_2_g1 * v.ase_texcoord3.w ) ) * _PenetratorBlendshapeMultiplier );
				float3 lerpResult410_g1 = lerp( ( VertexPosition254_g1 + ( SquishDelta85_g1 * temp_output_94_0_g1 * saturate( -_PenetratorSquishPullAmount ) ) + ( temp_output_94_0_g1 * PullDelta91_g1 * saturate( _PenetratorSquishPullAmount ) ) + ( sqrt( ( 1.0 - ( temp_output_1_0_g1063 * temp_output_1_0_g1063 ) ) ) * CumDelta90_g1 * _PenetratorCumActive ) ) , VertexPosition254_g1 , _NoBlendshapes);
				float3 originalPosition126_g1 = lerpResult410_g1;
				float dotResult118_g1 = dot( ( lerpResult410_g1 - DickOrigin16_g1 ) , DickForward18_g1 );
				float PenetrationDepth39_g1 = _PenetrationDepth;
				float temp_output_65_0_g1 = ( PenetrationDepth39_g1 * DickLength19_g1 );
				float OrifaceLength34_g1 = _OrificeLength;
				float temp_output_73_0_g1 = ( _PinchBuffer * OrifaceLength34_g1 );
				float dotResult80_g1 = dot( ( lerpResult410_g1 - DickOrigin16_g1 ) , DickForward18_g1 );
				float temp_output_112_0_g1 = ( -( ( ( temp_output_65_0_g1 - temp_output_73_0_g1 ) + dotResult80_g1 ) - DickLength19_g1 ) * 10.0 );
				float ClipDick413_g1 = _ClipDick;
				float lerpResult411_g1 = lerp( max( temp_output_112_0_g1 , ( ( ( temp_output_65_0_g1 + dotResult80_g1 + temp_output_73_0_g1 ) - ( OrifaceLength34_g1 + DickLength19_g1 ) ) * 10.0 ) ) , temp_output_112_0_g1 , ClipDick413_g1);
				float InsideLerp123_g1 = saturate( lerpResult411_g1 );
				float3 lerpResult124_g1 = lerp( ( ( DickForward18_g1 * dotResult118_g1 ) + DickOrigin16_g1 ) , originalPosition126_g1 , InsideLerp123_g1);
				float InvisibleWhenInside420_g1 = _InvisibleWhenInside;
				float3 lerpResult422_g1 = lerp( originalPosition126_g1 , lerpResult124_g1 , InvisibleWhenInside420_g1);
				float3 temp_output_354_0_g1 = ( lerpResult422_g1 - DickOrigin16_g1 );
				float dotResult373_g1 = dot( DickUp172_g1 , temp_output_354_0_g1 );
				float3 DickRight184_g1 = _PenetratorRight;
				float dotResult374_g1 = dot( DickRight184_g1 , temp_output_354_0_g1 );
				float dotResult375_g1 = dot( temp_output_354_0_g1 , DickForward18_g1 );
				float3 lerpResult343_g1 = lerp( ( ( ( saturate( ( ( VisibleLength25_g1 - distance( DickOrigin16_g1 , OrifacePosition170_g1 ) ) / DickLength19_g1 ) ) + 1.0 ) * dotResult373_g1 * DickUp172_g1 ) + ( ( saturate( ( ( VisibleLength25_g1 - distance( DickOrigin16_g1 , OrifacePosition170_g1 ) ) / DickLength19_g1 ) ) + 1.0 ) * dotResult374_g1 * DickRight184_g1 ) + ( DickForward18_g1 * dotResult375_g1 ) + DickOrigin16_g1 ) , lerpResult422_g1 , saturate( PenetrationDepth39_g1 ));
				float dotResult177_g1 = dot( ( lerpResult343_g1 - DickOrigin16_g1 ) , DickForward18_g1 );
				float temp_output_178_0_g1 = max( VisibleLength25_g1 , 0.05 );
				float temp_output_42_0_g1057 = ( dotResult177_g1 / temp_output_178_0_g1 );
				float temp_output_26_0_g1058 = temp_output_42_0_g1057;
				float temp_output_19_0_g1058 = ( 1.0 - temp_output_26_0_g1058 );
				float3 temp_output_8_0_g1057 = DickOrigin16_g1;
				float temp_output_393_0_g1 = distance( DickOrigin16_g1 , OrifacePosition170_g1 );
				float temp_output_396_0_g1 = min( temp_output_178_0_g1 , temp_output_393_0_g1 );
				float3 temp_output_9_0_g1057 = ( DickOrigin16_g1 + ( DickForward18_g1 * temp_output_396_0_g1 * 0.25 ) );
				float4 appendResult130_g1 = (float4(_OrificeWorldNormal , 0.0));
				float4 transform135_g1 = mul(GetWorldToObjectMatrix(),appendResult130_g1);
				float3 OrifaceNormal155_g1 = (transform135_g1).xyz;
				float3 temp_output_10_0_g1057 = ( OrifacePosition170_g1 + ( OrifaceNormal155_g1 * 0.25 * temp_output_396_0_g1 ) );
				float3 temp_output_11_0_g1057 = OrifacePosition170_g1;
				float temp_output_1_0_g1060 = temp_output_42_0_g1057;
				float temp_output_8_0_g1060 = ( 1.0 - temp_output_1_0_g1060 );
				float3 temp_output_3_0_g1060 = temp_output_9_0_g1057;
				float3 temp_output_4_0_g1060 = temp_output_10_0_g1057;
				float3 temp_output_7_0_g1059 = ( ( 3.0 * temp_output_8_0_g1060 * temp_output_8_0_g1060 * ( temp_output_3_0_g1060 - temp_output_8_0_g1057 ) ) + ( 6.0 * temp_output_8_0_g1060 * temp_output_1_0_g1060 * ( temp_output_4_0_g1060 - temp_output_3_0_g1060 ) ) + ( 3.0 * temp_output_1_0_g1060 * temp_output_1_0_g1060 * ( temp_output_11_0_g1057 - temp_output_4_0_g1060 ) ) );
				float3 normalizeResult27_g1061 = normalize( temp_output_7_0_g1059 );
				float3 temp_output_4_0_g1057 = DickUp172_g1;
				float3 temp_output_10_0_g1059 = temp_output_4_0_g1057;
				float3 temp_output_3_0_g1057 = DickForward18_g1;
				float3 temp_output_13_0_g1059 = temp_output_3_0_g1057;
				float dotResult33_g1059 = dot( temp_output_7_0_g1059 , temp_output_10_0_g1059 );
				float3 lerpResult34_g1059 = lerp( temp_output_10_0_g1059 , -temp_output_13_0_g1059 , saturate( dotResult33_g1059 ));
				float dotResult37_g1059 = dot( temp_output_7_0_g1059 , -temp_output_10_0_g1059 );
				float3 lerpResult40_g1059 = lerp( lerpResult34_g1059 , temp_output_13_0_g1059 , saturate( dotResult37_g1059 ));
				float3 normalizeResult42_g1059 = normalize( lerpResult40_g1059 );
				float3 normalizeResult31_g1061 = normalize( normalizeResult42_g1059 );
				float3 normalizeResult29_g1061 = normalize( cross( normalizeResult27_g1061 , normalizeResult31_g1061 ) );
				float3 temp_output_65_22_g1057 = normalizeResult29_g1061;
				float3 temp_output_2_0_g1057 = ( lerpResult343_g1 - DickOrigin16_g1 );
				float3 temp_output_5_0_g1057 = DickRight184_g1;
				float dotResult15_g1057 = dot( temp_output_2_0_g1057 , temp_output_5_0_g1057 );
				float3 temp_output_65_0_g1057 = cross( normalizeResult29_g1061 , normalizeResult27_g1061 );
				float dotResult18_g1057 = dot( temp_output_2_0_g1057 , temp_output_4_0_g1057 );
				float dotResult142_g1 = dot( ( lerpResult343_g1 - DickOrigin16_g1 ) , DickForward18_g1 );
				float temp_output_152_0_g1 = ( dotResult142_g1 - VisibleLength25_g1 );
				float temp_output_157_0_g1 = ( temp_output_152_0_g1 / OrifaceLength34_g1 );
				float lerpResult416_g1 = lerp( temp_output_157_0_g1 , min( temp_output_157_0_g1 , 1.0 ) , ClipDick413_g1);
				float temp_output_42_0_g1047 = lerpResult416_g1;
				float temp_output_26_0_g1048 = temp_output_42_0_g1047;
				float temp_output_19_0_g1048 = ( 1.0 - temp_output_26_0_g1048 );
				float3 temp_output_8_0_g1047 = OrifacePosition170_g1;
				float4 appendResult145_g1 = (float4(_OrificeOutWorldPosition1 , 1.0));
				float4 transform151_g1 = mul(GetWorldToObjectMatrix(),appendResult145_g1);
				float3 OrifaceOutPosition1183_g1 = (transform151_g1).xyz;
				float3 temp_output_9_0_g1047 = OrifaceOutPosition1183_g1;
				float4 appendResult144_g1 = (float4(_OrificeOutWorldPosition2 , 1.0));
				float4 transform154_g1 = mul(GetWorldToObjectMatrix(),appendResult144_g1);
				float3 OrifaceOutPosition2182_g1 = (transform154_g1).xyz;
				float3 temp_output_10_0_g1047 = OrifaceOutPosition2182_g1;
				float4 appendResult143_g1 = (float4(_OrificeOutWorldPosition3 , 1.0));
				float4 transform147_g1 = mul(GetWorldToObjectMatrix(),appendResult143_g1);
				float3 OrifaceOutPosition3175_g1 = (transform147_g1).xyz;
				float3 temp_output_11_0_g1047 = OrifaceOutPosition3175_g1;
				float temp_output_1_0_g1050 = temp_output_42_0_g1047;
				float temp_output_8_0_g1050 = ( 1.0 - temp_output_1_0_g1050 );
				float3 temp_output_3_0_g1050 = temp_output_9_0_g1047;
				float3 temp_output_4_0_g1050 = temp_output_10_0_g1047;
				float3 temp_output_7_0_g1049 = ( ( 3.0 * temp_output_8_0_g1050 * temp_output_8_0_g1050 * ( temp_output_3_0_g1050 - temp_output_8_0_g1047 ) ) + ( 6.0 * temp_output_8_0_g1050 * temp_output_1_0_g1050 * ( temp_output_4_0_g1050 - temp_output_3_0_g1050 ) ) + ( 3.0 * temp_output_1_0_g1050 * temp_output_1_0_g1050 * ( temp_output_11_0_g1047 - temp_output_4_0_g1050 ) ) );
				float3 normalizeResult27_g1051 = normalize( temp_output_7_0_g1049 );
				float3 temp_output_4_0_g1047 = DickUp172_g1;
				float3 temp_output_10_0_g1049 = temp_output_4_0_g1047;
				float3 temp_output_3_0_g1047 = DickForward18_g1;
				float3 temp_output_13_0_g1049 = temp_output_3_0_g1047;
				float dotResult33_g1049 = dot( temp_output_7_0_g1049 , temp_output_10_0_g1049 );
				float3 lerpResult34_g1049 = lerp( temp_output_10_0_g1049 , -temp_output_13_0_g1049 , saturate( dotResult33_g1049 ));
				float dotResult37_g1049 = dot( temp_output_7_0_g1049 , -temp_output_10_0_g1049 );
				float3 lerpResult40_g1049 = lerp( lerpResult34_g1049 , temp_output_13_0_g1049 , saturate( dotResult37_g1049 ));
				float3 normalizeResult42_g1049 = normalize( lerpResult40_g1049 );
				float3 normalizeResult31_g1051 = normalize( normalizeResult42_g1049 );
				float3 normalizeResult29_g1051 = normalize( cross( normalizeResult27_g1051 , normalizeResult31_g1051 ) );
				float3 temp_output_65_22_g1047 = normalizeResult29_g1051;
				float3 temp_output_2_0_g1047 = ( lerpResult343_g1 - DickOrigin16_g1 );
				float3 temp_output_5_0_g1047 = DickRight184_g1;
				float dotResult15_g1047 = dot( temp_output_2_0_g1047 , temp_output_5_0_g1047 );
				float3 temp_output_65_0_g1047 = cross( normalizeResult29_g1051 , normalizeResult27_g1051 );
				float dotResult18_g1047 = dot( temp_output_2_0_g1047 , temp_output_4_0_g1047 );
				float temp_output_208_0_g1 = saturate( sign( temp_output_152_0_g1 ) );
				float3 lerpResult221_g1 = lerp( ( ( ( temp_output_19_0_g1058 * temp_output_19_0_g1058 * temp_output_19_0_g1058 * temp_output_8_0_g1057 ) + ( temp_output_19_0_g1058 * temp_output_19_0_g1058 * 3.0 * temp_output_26_0_g1058 * temp_output_9_0_g1057 ) + ( 3.0 * temp_output_19_0_g1058 * temp_output_26_0_g1058 * temp_output_26_0_g1058 * temp_output_10_0_g1057 ) + ( temp_output_26_0_g1058 * temp_output_26_0_g1058 * temp_output_26_0_g1058 * temp_output_11_0_g1057 ) ) + ( temp_output_65_22_g1057 * dotResult15_g1057 ) + ( temp_output_65_0_g1057 * dotResult18_g1057 ) ) , ( ( ( temp_output_19_0_g1048 * temp_output_19_0_g1048 * temp_output_19_0_g1048 * temp_output_8_0_g1047 ) + ( temp_output_19_0_g1048 * temp_output_19_0_g1048 * 3.0 * temp_output_26_0_g1048 * temp_output_9_0_g1047 ) + ( 3.0 * temp_output_19_0_g1048 * temp_output_26_0_g1048 * temp_output_26_0_g1048 * temp_output_10_0_g1047 ) + ( temp_output_26_0_g1048 * temp_output_26_0_g1048 * temp_output_26_0_g1048 * temp_output_11_0_g1047 ) ) + ( temp_output_65_22_g1047 * dotResult15_g1047 ) + ( temp_output_65_0_g1047 * dotResult18_g1047 ) ) , temp_output_208_0_g1);
				float3 temp_output_42_0_g1052 = DickForward18_g1;
				float NonVisibleLength165_g1 = ( temp_output_11_0_g1 * _PenetratorLength );
				float3 temp_output_52_0_g1052 = ( ( temp_output_42_0_g1052 * ( ( NonVisibleLength165_g1 - OrifaceLength34_g1 ) - DickLength19_g1 ) ) + ( lerpResult343_g1 - DickOrigin16_g1 ) );
				float dotResult53_g1052 = dot( temp_output_42_0_g1052 , temp_output_52_0_g1052 );
				float temp_output_1_0_g1054 = 1.0;
				float temp_output_8_0_g1054 = ( 1.0 - temp_output_1_0_g1054 );
				float3 temp_output_3_0_g1054 = OrifaceOutPosition1183_g1;
				float3 temp_output_4_0_g1054 = OrifaceOutPosition2182_g1;
				float3 temp_output_7_0_g1053 = ( ( 3.0 * temp_output_8_0_g1054 * temp_output_8_0_g1054 * ( temp_output_3_0_g1054 - OrifacePosition170_g1 ) ) + ( 6.0 * temp_output_8_0_g1054 * temp_output_1_0_g1054 * ( temp_output_4_0_g1054 - temp_output_3_0_g1054 ) ) + ( 3.0 * temp_output_1_0_g1054 * temp_output_1_0_g1054 * ( OrifaceOutPosition3175_g1 - temp_output_4_0_g1054 ) ) );
				float3 normalizeResult27_g1055 = normalize( temp_output_7_0_g1053 );
				float3 temp_output_85_23_g1052 = normalizeResult27_g1055;
				float3 temp_output_4_0_g1052 = DickUp172_g1;
				float dotResult54_g1052 = dot( temp_output_4_0_g1052 , temp_output_52_0_g1052 );
				float3 temp_output_10_0_g1053 = temp_output_4_0_g1052;
				float3 temp_output_13_0_g1053 = temp_output_42_0_g1052;
				float dotResult33_g1053 = dot( temp_output_7_0_g1053 , temp_output_10_0_g1053 );
				float3 lerpResult34_g1053 = lerp( temp_output_10_0_g1053 , -temp_output_13_0_g1053 , saturate( dotResult33_g1053 ));
				float dotResult37_g1053 = dot( temp_output_7_0_g1053 , -temp_output_10_0_g1053 );
				float3 lerpResult40_g1053 = lerp( lerpResult34_g1053 , temp_output_13_0_g1053 , saturate( dotResult37_g1053 ));
				float3 normalizeResult42_g1053 = normalize( lerpResult40_g1053 );
				float3 normalizeResult31_g1055 = normalize( normalizeResult42_g1053 );
				float3 normalizeResult29_g1055 = normalize( cross( normalizeResult27_g1055 , normalizeResult31_g1055 ) );
				float3 temp_output_85_0_g1052 = cross( normalizeResult29_g1055 , normalizeResult27_g1055 );
				float3 temp_output_43_0_g1052 = DickRight184_g1;
				float dotResult55_g1052 = dot( temp_output_43_0_g1052 , temp_output_52_0_g1052 );
				float3 temp_output_85_22_g1052 = normalizeResult29_g1055;
				float temp_output_222_0_g1 = saturate( sign( ( temp_output_157_0_g1 - 1.0 ) ) );
				float3 lerpResult224_g1 = lerp( lerpResult221_g1 , ( ( ( dotResult53_g1052 * temp_output_85_23_g1052 ) + ( dotResult54_g1052 * temp_output_85_0_g1052 ) + ( dotResult55_g1052 * temp_output_85_22_g1052 ) ) + OrifaceOutPosition3175_g1 ) , temp_output_222_0_g1);
				float3 lerpResult418_g1 = lerp( lerpResult224_g1 , lerpResult221_g1 , ClipDick413_g1);
				float temp_output_226_0_g1 = saturate( -PenetrationDepth39_g1 );
				float3 lerpResult232_g1 = lerp( lerpResult418_g1 , originalPosition126_g1 , temp_output_226_0_g1);
				float3 ifLocalVar237_g1 = 0;
				if( temp_output_234_0_g1 <= 0.0 )
				ifLocalVar237_g1 = originalPosition126_g1;
				else
				ifLocalVar237_g1 = lerpResult232_g1;
				float DeformBalls426_g1 = _DeformBalls;
				float3 lerpResult428_g1 = lerp( ifLocalVar237_g1 , lerpResult232_g1 , DeformBalls426_g1);
				
				float3 temp_output_21_0_g1057 = VertexNormal259_g1;
				float dotResult55_g1057 = dot( temp_output_21_0_g1057 , temp_output_3_0_g1057 );
				float dotResult56_g1057 = dot( temp_output_21_0_g1057 , temp_output_4_0_g1057 );
				float dotResult57_g1057 = dot( temp_output_21_0_g1057 , temp_output_5_0_g1057 );
				float3 normalizeResult31_g1057 = normalize( ( ( dotResult55_g1057 * normalizeResult27_g1061 ) + ( dotResult56_g1057 * temp_output_65_0_g1057 ) + ( dotResult57_g1057 * temp_output_65_22_g1057 ) ) );
				float3 temp_output_21_0_g1047 = VertexNormal259_g1;
				float dotResult55_g1047 = dot( temp_output_21_0_g1047 , temp_output_3_0_g1047 );
				float dotResult56_g1047 = dot( temp_output_21_0_g1047 , temp_output_4_0_g1047 );
				float dotResult57_g1047 = dot( temp_output_21_0_g1047 , temp_output_5_0_g1047 );
				float3 normalizeResult31_g1047 = normalize( ( ( dotResult55_g1047 * normalizeResult27_g1051 ) + ( dotResult56_g1047 * temp_output_65_0_g1047 ) + ( dotResult57_g1047 * temp_output_65_22_g1047 ) ) );
				float3 lerpResult227_g1 = lerp( normalizeResult31_g1057 , normalizeResult31_g1047 , temp_output_208_0_g1);
				float3 temp_output_24_0_g1052 = VertexNormal259_g1;
				float dotResult61_g1052 = dot( temp_output_42_0_g1052 , temp_output_24_0_g1052 );
				float dotResult62_g1052 = dot( temp_output_4_0_g1052 , temp_output_24_0_g1052 );
				float dotResult60_g1052 = dot( temp_output_43_0_g1052 , temp_output_24_0_g1052 );
				float3 normalizeResult33_g1052 = normalize( ( ( dotResult61_g1052 * temp_output_85_23_g1052 ) + ( dotResult62_g1052 * temp_output_85_0_g1052 ) + ( dotResult60_g1052 * temp_output_85_22_g1052 ) ) );
				float3 lerpResult233_g1 = lerp( lerpResult227_g1 , normalizeResult33_g1052 , temp_output_222_0_g1);
				float3 lerpResult419_g1 = lerp( lerpResult233_g1 , lerpResult227_g1 , ClipDick413_g1);
				float3 lerpResult238_g1 = lerp( lerpResult419_g1 , VertexNormal259_g1 , temp_output_226_0_g1);
				float3 ifLocalVar391_g1 = 0;
				if( temp_output_234_0_g1 <= 0.0 )
				ifLocalVar391_g1 = VertexNormal259_g1;
				else
				ifLocalVar391_g1 = lerpResult238_g1;
				
				float lerpResult424_g1 = lerp( 1.0 , InsideLerp123_g1 , InvisibleWhenInside420_g1);
				float vertexToFrag250_g1 = lerpResult424_g1;
				o.ase_texcoord3.x = vertexToFrag250_g1;
				
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.yzw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = lerpResult428_g1;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = ifLocalVar391_g1;
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

				float vertexToFrag250_g1 = IN.ase_texcoord3.x;
				
				float Alpha = vertexToFrag250_g1;
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
			#define ASE_NEEDS_FRAG_WORLD_VIEW_DIR
			#define ASE_NEEDS_FRAG_WORLD_NORMAL


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord : TEXCOORD0;
				float4 ase_texcoord2 : TEXCOORD2;
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
			float4 _GooTongue_TongueMaterial_MetallicSmoothness_ST;
			float4 _GooTongue_TongueMaterial_Normal_ST;
			float4 _GooTongue_TongueMaterial_AlbedoTransparency_ST;
			float4 _BulgeLanes_normal_ST;
			float3 _PenetratorOrigin;
			float3 _OrificeWorldPosition;
			float3 _PenetratorUp;
			float3 _OrificeOutWorldPosition3;
			float3 _PenetratorForward;
			float3 _OrificeOutWorldPosition2;
			float3 _OrificeOutWorldPosition1;
			float3 _OrificeWorldNormal;
			float3 _PenetratorRight;
			float _DeformBalls;
			float _InvisibleWhenInside;
			float _ClipDick;
			float _NoBlendshapes;
			float _PinchBuffer;
			float _PenetratorCumActive;
			float _PenetratorCumProgress;
			float _PenetratorSquishPullAmount;
			float _PenetratorBulgePercentage;
			float _BulgeClip;
			float _BulgeAmount;
			float _PenetrationDepth;
			float _PenetratorLength;
			float _OrificeLength;
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
			sampler2D _BulgeLanes_output;
			sampler2D _GooTongue_TongueMaterial_AlbedoTransparency;
			sampler2D _GooTongue_TongueMaterial_Normal;
			sampler2D _BulgeLanes_normal;
			sampler2D _GooTongue_TongueMaterial_MetallicSmoothness;


			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 VertexNormal259_g1 = v.ase_normal;
				float3 normalizeResult27_g1062 = normalize( VertexNormal259_g1 );
				float3 temp_output_35_0_g1 = normalizeResult27_g1062;
				float3 normalizeResult31_g1062 = normalize( v.ase_tangent.xyz );
				float3 normalizeResult29_g1062 = normalize( cross( normalizeResult27_g1062 , normalizeResult31_g1062 ) );
				float3 temp_output_35_1_g1 = cross( normalizeResult29_g1062 , normalizeResult27_g1062 );
				float3 temp_output_35_2_g1 = normalizeResult29_g1062;
				float3 SquishDelta85_g1 = ( ( ( temp_output_35_0_g1 * v.ase_texcoord2.x ) + ( temp_output_35_1_g1 * v.ase_texcoord2.y ) + ( temp_output_35_2_g1 * v.ase_texcoord2.z ) ) * _PenetratorBlendshapeMultiplier );
				float temp_output_234_0_g1 = length( SquishDelta85_g1 );
				float temp_output_11_0_g1 = max( _PenetrationDepth , 0.0 );
				float VisibleLength25_g1 = ( _PenetratorLength * ( 1.0 - temp_output_11_0_g1 ) );
				float3 DickOrigin16_g1 = _PenetratorOrigin;
				float4 appendResult132_g1 = (float4(_OrificeWorldPosition , 1.0));
				float4 transform140_g1 = mul(GetWorldToObjectMatrix(),appendResult132_g1);
				float3 OrifacePosition170_g1 = (transform140_g1).xyz;
				float DickLength19_g1 = _PenetratorLength;
				float3 DickUp172_g1 = _PenetratorUp;
				float2 texCoord9 = v.texcoord1.xyzw.xy * float2( 1,0.5 ) + float2( 0,0 );
				float2 break17 = texCoord9;
				float mulTime16 = _TimeParameters.x * 0.08;
				float2 appendResult19 = (float2(break17.x , ( mulTime16 + break17.y )));
				float4 tex2DNode8 = tex2Dlod( _BulgeLanes_output, float4( appendResult19, 0, 0.0) );
				float2 texCoord41 = v.texcoord1.xyzw.xy * float2( 1,1 ) + float2( 0,0 );
				float temp_output_43_0 = saturate( sign( ( texCoord41.y - ( 1.0 - _BulgeClip ) ) ) );
				float3 VertexPosition254_g1 = ( ( v.ase_normal * tex2DNode8.r * _BulgeAmount * temp_output_43_0 ) + v.vertex.xyz );
				float3 temp_output_27_0_g1 = ( VertexPosition254_g1 - DickOrigin16_g1 );
				float3 DickForward18_g1 = _PenetratorForward;
				float dotResult42_g1 = dot( temp_output_27_0_g1 , DickForward18_g1 );
				float BulgePercentage37_g1 = _PenetratorBulgePercentage;
				float temp_output_1_0_g1056 = saturate( ( abs( ( dotResult42_g1 - VisibleLength25_g1 ) ) / ( DickLength19_g1 * BulgePercentage37_g1 ) ) );
				float temp_output_94_0_g1 = sqrt( ( 1.0 - ( temp_output_1_0_g1056 * temp_output_1_0_g1056 ) ) );
				float3 PullDelta91_g1 = ( ( ( temp_output_35_0_g1 * v.ase_texcoord3.x ) + ( temp_output_35_1_g1 * v.ase_texcoord3.y ) + ( temp_output_35_2_g1 * v.ase_texcoord3.z ) ) * _PenetratorBlendshapeMultiplier );
				float dotResult32_g1 = dot( temp_output_27_0_g1 , DickForward18_g1 );
				float temp_output_1_0_g1063 = saturate( ( abs( ( dotResult32_g1 - ( DickLength19_g1 * _PenetratorCumProgress ) ) ) / ( DickLength19_g1 * BulgePercentage37_g1 ) ) );
				float3 CumDelta90_g1 = ( ( ( temp_output_35_0_g1 * v.texcoord1.xyzw.w ) + ( temp_output_35_1_g1 * v.ase_texcoord2.w ) + ( temp_output_35_2_g1 * v.ase_texcoord3.w ) ) * _PenetratorBlendshapeMultiplier );
				float3 lerpResult410_g1 = lerp( ( VertexPosition254_g1 + ( SquishDelta85_g1 * temp_output_94_0_g1 * saturate( -_PenetratorSquishPullAmount ) ) + ( temp_output_94_0_g1 * PullDelta91_g1 * saturate( _PenetratorSquishPullAmount ) ) + ( sqrt( ( 1.0 - ( temp_output_1_0_g1063 * temp_output_1_0_g1063 ) ) ) * CumDelta90_g1 * _PenetratorCumActive ) ) , VertexPosition254_g1 , _NoBlendshapes);
				float3 originalPosition126_g1 = lerpResult410_g1;
				float dotResult118_g1 = dot( ( lerpResult410_g1 - DickOrigin16_g1 ) , DickForward18_g1 );
				float PenetrationDepth39_g1 = _PenetrationDepth;
				float temp_output_65_0_g1 = ( PenetrationDepth39_g1 * DickLength19_g1 );
				float OrifaceLength34_g1 = _OrificeLength;
				float temp_output_73_0_g1 = ( _PinchBuffer * OrifaceLength34_g1 );
				float dotResult80_g1 = dot( ( lerpResult410_g1 - DickOrigin16_g1 ) , DickForward18_g1 );
				float temp_output_112_0_g1 = ( -( ( ( temp_output_65_0_g1 - temp_output_73_0_g1 ) + dotResult80_g1 ) - DickLength19_g1 ) * 10.0 );
				float ClipDick413_g1 = _ClipDick;
				float lerpResult411_g1 = lerp( max( temp_output_112_0_g1 , ( ( ( temp_output_65_0_g1 + dotResult80_g1 + temp_output_73_0_g1 ) - ( OrifaceLength34_g1 + DickLength19_g1 ) ) * 10.0 ) ) , temp_output_112_0_g1 , ClipDick413_g1);
				float InsideLerp123_g1 = saturate( lerpResult411_g1 );
				float3 lerpResult124_g1 = lerp( ( ( DickForward18_g1 * dotResult118_g1 ) + DickOrigin16_g1 ) , originalPosition126_g1 , InsideLerp123_g1);
				float InvisibleWhenInside420_g1 = _InvisibleWhenInside;
				float3 lerpResult422_g1 = lerp( originalPosition126_g1 , lerpResult124_g1 , InvisibleWhenInside420_g1);
				float3 temp_output_354_0_g1 = ( lerpResult422_g1 - DickOrigin16_g1 );
				float dotResult373_g1 = dot( DickUp172_g1 , temp_output_354_0_g1 );
				float3 DickRight184_g1 = _PenetratorRight;
				float dotResult374_g1 = dot( DickRight184_g1 , temp_output_354_0_g1 );
				float dotResult375_g1 = dot( temp_output_354_0_g1 , DickForward18_g1 );
				float3 lerpResult343_g1 = lerp( ( ( ( saturate( ( ( VisibleLength25_g1 - distance( DickOrigin16_g1 , OrifacePosition170_g1 ) ) / DickLength19_g1 ) ) + 1.0 ) * dotResult373_g1 * DickUp172_g1 ) + ( ( saturate( ( ( VisibleLength25_g1 - distance( DickOrigin16_g1 , OrifacePosition170_g1 ) ) / DickLength19_g1 ) ) + 1.0 ) * dotResult374_g1 * DickRight184_g1 ) + ( DickForward18_g1 * dotResult375_g1 ) + DickOrigin16_g1 ) , lerpResult422_g1 , saturate( PenetrationDepth39_g1 ));
				float dotResult177_g1 = dot( ( lerpResult343_g1 - DickOrigin16_g1 ) , DickForward18_g1 );
				float temp_output_178_0_g1 = max( VisibleLength25_g1 , 0.05 );
				float temp_output_42_0_g1057 = ( dotResult177_g1 / temp_output_178_0_g1 );
				float temp_output_26_0_g1058 = temp_output_42_0_g1057;
				float temp_output_19_0_g1058 = ( 1.0 - temp_output_26_0_g1058 );
				float3 temp_output_8_0_g1057 = DickOrigin16_g1;
				float temp_output_393_0_g1 = distance( DickOrigin16_g1 , OrifacePosition170_g1 );
				float temp_output_396_0_g1 = min( temp_output_178_0_g1 , temp_output_393_0_g1 );
				float3 temp_output_9_0_g1057 = ( DickOrigin16_g1 + ( DickForward18_g1 * temp_output_396_0_g1 * 0.25 ) );
				float4 appendResult130_g1 = (float4(_OrificeWorldNormal , 0.0));
				float4 transform135_g1 = mul(GetWorldToObjectMatrix(),appendResult130_g1);
				float3 OrifaceNormal155_g1 = (transform135_g1).xyz;
				float3 temp_output_10_0_g1057 = ( OrifacePosition170_g1 + ( OrifaceNormal155_g1 * 0.25 * temp_output_396_0_g1 ) );
				float3 temp_output_11_0_g1057 = OrifacePosition170_g1;
				float temp_output_1_0_g1060 = temp_output_42_0_g1057;
				float temp_output_8_0_g1060 = ( 1.0 - temp_output_1_0_g1060 );
				float3 temp_output_3_0_g1060 = temp_output_9_0_g1057;
				float3 temp_output_4_0_g1060 = temp_output_10_0_g1057;
				float3 temp_output_7_0_g1059 = ( ( 3.0 * temp_output_8_0_g1060 * temp_output_8_0_g1060 * ( temp_output_3_0_g1060 - temp_output_8_0_g1057 ) ) + ( 6.0 * temp_output_8_0_g1060 * temp_output_1_0_g1060 * ( temp_output_4_0_g1060 - temp_output_3_0_g1060 ) ) + ( 3.0 * temp_output_1_0_g1060 * temp_output_1_0_g1060 * ( temp_output_11_0_g1057 - temp_output_4_0_g1060 ) ) );
				float3 normalizeResult27_g1061 = normalize( temp_output_7_0_g1059 );
				float3 temp_output_4_0_g1057 = DickUp172_g1;
				float3 temp_output_10_0_g1059 = temp_output_4_0_g1057;
				float3 temp_output_3_0_g1057 = DickForward18_g1;
				float3 temp_output_13_0_g1059 = temp_output_3_0_g1057;
				float dotResult33_g1059 = dot( temp_output_7_0_g1059 , temp_output_10_0_g1059 );
				float3 lerpResult34_g1059 = lerp( temp_output_10_0_g1059 , -temp_output_13_0_g1059 , saturate( dotResult33_g1059 ));
				float dotResult37_g1059 = dot( temp_output_7_0_g1059 , -temp_output_10_0_g1059 );
				float3 lerpResult40_g1059 = lerp( lerpResult34_g1059 , temp_output_13_0_g1059 , saturate( dotResult37_g1059 ));
				float3 normalizeResult42_g1059 = normalize( lerpResult40_g1059 );
				float3 normalizeResult31_g1061 = normalize( normalizeResult42_g1059 );
				float3 normalizeResult29_g1061 = normalize( cross( normalizeResult27_g1061 , normalizeResult31_g1061 ) );
				float3 temp_output_65_22_g1057 = normalizeResult29_g1061;
				float3 temp_output_2_0_g1057 = ( lerpResult343_g1 - DickOrigin16_g1 );
				float3 temp_output_5_0_g1057 = DickRight184_g1;
				float dotResult15_g1057 = dot( temp_output_2_0_g1057 , temp_output_5_0_g1057 );
				float3 temp_output_65_0_g1057 = cross( normalizeResult29_g1061 , normalizeResult27_g1061 );
				float dotResult18_g1057 = dot( temp_output_2_0_g1057 , temp_output_4_0_g1057 );
				float dotResult142_g1 = dot( ( lerpResult343_g1 - DickOrigin16_g1 ) , DickForward18_g1 );
				float temp_output_152_0_g1 = ( dotResult142_g1 - VisibleLength25_g1 );
				float temp_output_157_0_g1 = ( temp_output_152_0_g1 / OrifaceLength34_g1 );
				float lerpResult416_g1 = lerp( temp_output_157_0_g1 , min( temp_output_157_0_g1 , 1.0 ) , ClipDick413_g1);
				float temp_output_42_0_g1047 = lerpResult416_g1;
				float temp_output_26_0_g1048 = temp_output_42_0_g1047;
				float temp_output_19_0_g1048 = ( 1.0 - temp_output_26_0_g1048 );
				float3 temp_output_8_0_g1047 = OrifacePosition170_g1;
				float4 appendResult145_g1 = (float4(_OrificeOutWorldPosition1 , 1.0));
				float4 transform151_g1 = mul(GetWorldToObjectMatrix(),appendResult145_g1);
				float3 OrifaceOutPosition1183_g1 = (transform151_g1).xyz;
				float3 temp_output_9_0_g1047 = OrifaceOutPosition1183_g1;
				float4 appendResult144_g1 = (float4(_OrificeOutWorldPosition2 , 1.0));
				float4 transform154_g1 = mul(GetWorldToObjectMatrix(),appendResult144_g1);
				float3 OrifaceOutPosition2182_g1 = (transform154_g1).xyz;
				float3 temp_output_10_0_g1047 = OrifaceOutPosition2182_g1;
				float4 appendResult143_g1 = (float4(_OrificeOutWorldPosition3 , 1.0));
				float4 transform147_g1 = mul(GetWorldToObjectMatrix(),appendResult143_g1);
				float3 OrifaceOutPosition3175_g1 = (transform147_g1).xyz;
				float3 temp_output_11_0_g1047 = OrifaceOutPosition3175_g1;
				float temp_output_1_0_g1050 = temp_output_42_0_g1047;
				float temp_output_8_0_g1050 = ( 1.0 - temp_output_1_0_g1050 );
				float3 temp_output_3_0_g1050 = temp_output_9_0_g1047;
				float3 temp_output_4_0_g1050 = temp_output_10_0_g1047;
				float3 temp_output_7_0_g1049 = ( ( 3.0 * temp_output_8_0_g1050 * temp_output_8_0_g1050 * ( temp_output_3_0_g1050 - temp_output_8_0_g1047 ) ) + ( 6.0 * temp_output_8_0_g1050 * temp_output_1_0_g1050 * ( temp_output_4_0_g1050 - temp_output_3_0_g1050 ) ) + ( 3.0 * temp_output_1_0_g1050 * temp_output_1_0_g1050 * ( temp_output_11_0_g1047 - temp_output_4_0_g1050 ) ) );
				float3 normalizeResult27_g1051 = normalize( temp_output_7_0_g1049 );
				float3 temp_output_4_0_g1047 = DickUp172_g1;
				float3 temp_output_10_0_g1049 = temp_output_4_0_g1047;
				float3 temp_output_3_0_g1047 = DickForward18_g1;
				float3 temp_output_13_0_g1049 = temp_output_3_0_g1047;
				float dotResult33_g1049 = dot( temp_output_7_0_g1049 , temp_output_10_0_g1049 );
				float3 lerpResult34_g1049 = lerp( temp_output_10_0_g1049 , -temp_output_13_0_g1049 , saturate( dotResult33_g1049 ));
				float dotResult37_g1049 = dot( temp_output_7_0_g1049 , -temp_output_10_0_g1049 );
				float3 lerpResult40_g1049 = lerp( lerpResult34_g1049 , temp_output_13_0_g1049 , saturate( dotResult37_g1049 ));
				float3 normalizeResult42_g1049 = normalize( lerpResult40_g1049 );
				float3 normalizeResult31_g1051 = normalize( normalizeResult42_g1049 );
				float3 normalizeResult29_g1051 = normalize( cross( normalizeResult27_g1051 , normalizeResult31_g1051 ) );
				float3 temp_output_65_22_g1047 = normalizeResult29_g1051;
				float3 temp_output_2_0_g1047 = ( lerpResult343_g1 - DickOrigin16_g1 );
				float3 temp_output_5_0_g1047 = DickRight184_g1;
				float dotResult15_g1047 = dot( temp_output_2_0_g1047 , temp_output_5_0_g1047 );
				float3 temp_output_65_0_g1047 = cross( normalizeResult29_g1051 , normalizeResult27_g1051 );
				float dotResult18_g1047 = dot( temp_output_2_0_g1047 , temp_output_4_0_g1047 );
				float temp_output_208_0_g1 = saturate( sign( temp_output_152_0_g1 ) );
				float3 lerpResult221_g1 = lerp( ( ( ( temp_output_19_0_g1058 * temp_output_19_0_g1058 * temp_output_19_0_g1058 * temp_output_8_0_g1057 ) + ( temp_output_19_0_g1058 * temp_output_19_0_g1058 * 3.0 * temp_output_26_0_g1058 * temp_output_9_0_g1057 ) + ( 3.0 * temp_output_19_0_g1058 * temp_output_26_0_g1058 * temp_output_26_0_g1058 * temp_output_10_0_g1057 ) + ( temp_output_26_0_g1058 * temp_output_26_0_g1058 * temp_output_26_0_g1058 * temp_output_11_0_g1057 ) ) + ( temp_output_65_22_g1057 * dotResult15_g1057 ) + ( temp_output_65_0_g1057 * dotResult18_g1057 ) ) , ( ( ( temp_output_19_0_g1048 * temp_output_19_0_g1048 * temp_output_19_0_g1048 * temp_output_8_0_g1047 ) + ( temp_output_19_0_g1048 * temp_output_19_0_g1048 * 3.0 * temp_output_26_0_g1048 * temp_output_9_0_g1047 ) + ( 3.0 * temp_output_19_0_g1048 * temp_output_26_0_g1048 * temp_output_26_0_g1048 * temp_output_10_0_g1047 ) + ( temp_output_26_0_g1048 * temp_output_26_0_g1048 * temp_output_26_0_g1048 * temp_output_11_0_g1047 ) ) + ( temp_output_65_22_g1047 * dotResult15_g1047 ) + ( temp_output_65_0_g1047 * dotResult18_g1047 ) ) , temp_output_208_0_g1);
				float3 temp_output_42_0_g1052 = DickForward18_g1;
				float NonVisibleLength165_g1 = ( temp_output_11_0_g1 * _PenetratorLength );
				float3 temp_output_52_0_g1052 = ( ( temp_output_42_0_g1052 * ( ( NonVisibleLength165_g1 - OrifaceLength34_g1 ) - DickLength19_g1 ) ) + ( lerpResult343_g1 - DickOrigin16_g1 ) );
				float dotResult53_g1052 = dot( temp_output_42_0_g1052 , temp_output_52_0_g1052 );
				float temp_output_1_0_g1054 = 1.0;
				float temp_output_8_0_g1054 = ( 1.0 - temp_output_1_0_g1054 );
				float3 temp_output_3_0_g1054 = OrifaceOutPosition1183_g1;
				float3 temp_output_4_0_g1054 = OrifaceOutPosition2182_g1;
				float3 temp_output_7_0_g1053 = ( ( 3.0 * temp_output_8_0_g1054 * temp_output_8_0_g1054 * ( temp_output_3_0_g1054 - OrifacePosition170_g1 ) ) + ( 6.0 * temp_output_8_0_g1054 * temp_output_1_0_g1054 * ( temp_output_4_0_g1054 - temp_output_3_0_g1054 ) ) + ( 3.0 * temp_output_1_0_g1054 * temp_output_1_0_g1054 * ( OrifaceOutPosition3175_g1 - temp_output_4_0_g1054 ) ) );
				float3 normalizeResult27_g1055 = normalize( temp_output_7_0_g1053 );
				float3 temp_output_85_23_g1052 = normalizeResult27_g1055;
				float3 temp_output_4_0_g1052 = DickUp172_g1;
				float dotResult54_g1052 = dot( temp_output_4_0_g1052 , temp_output_52_0_g1052 );
				float3 temp_output_10_0_g1053 = temp_output_4_0_g1052;
				float3 temp_output_13_0_g1053 = temp_output_42_0_g1052;
				float dotResult33_g1053 = dot( temp_output_7_0_g1053 , temp_output_10_0_g1053 );
				float3 lerpResult34_g1053 = lerp( temp_output_10_0_g1053 , -temp_output_13_0_g1053 , saturate( dotResult33_g1053 ));
				float dotResult37_g1053 = dot( temp_output_7_0_g1053 , -temp_output_10_0_g1053 );
				float3 lerpResult40_g1053 = lerp( lerpResult34_g1053 , temp_output_13_0_g1053 , saturate( dotResult37_g1053 ));
				float3 normalizeResult42_g1053 = normalize( lerpResult40_g1053 );
				float3 normalizeResult31_g1055 = normalize( normalizeResult42_g1053 );
				float3 normalizeResult29_g1055 = normalize( cross( normalizeResult27_g1055 , normalizeResult31_g1055 ) );
				float3 temp_output_85_0_g1052 = cross( normalizeResult29_g1055 , normalizeResult27_g1055 );
				float3 temp_output_43_0_g1052 = DickRight184_g1;
				float dotResult55_g1052 = dot( temp_output_43_0_g1052 , temp_output_52_0_g1052 );
				float3 temp_output_85_22_g1052 = normalizeResult29_g1055;
				float temp_output_222_0_g1 = saturate( sign( ( temp_output_157_0_g1 - 1.0 ) ) );
				float3 lerpResult224_g1 = lerp( lerpResult221_g1 , ( ( ( dotResult53_g1052 * temp_output_85_23_g1052 ) + ( dotResult54_g1052 * temp_output_85_0_g1052 ) + ( dotResult55_g1052 * temp_output_85_22_g1052 ) ) + OrifaceOutPosition3175_g1 ) , temp_output_222_0_g1);
				float3 lerpResult418_g1 = lerp( lerpResult224_g1 , lerpResult221_g1 , ClipDick413_g1);
				float temp_output_226_0_g1 = saturate( -PenetrationDepth39_g1 );
				float3 lerpResult232_g1 = lerp( lerpResult418_g1 , originalPosition126_g1 , temp_output_226_0_g1);
				float3 ifLocalVar237_g1 = 0;
				if( temp_output_234_0_g1 <= 0.0 )
				ifLocalVar237_g1 = originalPosition126_g1;
				else
				ifLocalVar237_g1 = lerpResult232_g1;
				float DeformBalls426_g1 = _DeformBalls;
				float3 lerpResult428_g1 = lerp( ifLocalVar237_g1 , lerpResult232_g1 , DeformBalls426_g1);
				
				float3 temp_output_21_0_g1057 = VertexNormal259_g1;
				float dotResult55_g1057 = dot( temp_output_21_0_g1057 , temp_output_3_0_g1057 );
				float dotResult56_g1057 = dot( temp_output_21_0_g1057 , temp_output_4_0_g1057 );
				float dotResult57_g1057 = dot( temp_output_21_0_g1057 , temp_output_5_0_g1057 );
				float3 normalizeResult31_g1057 = normalize( ( ( dotResult55_g1057 * normalizeResult27_g1061 ) + ( dotResult56_g1057 * temp_output_65_0_g1057 ) + ( dotResult57_g1057 * temp_output_65_22_g1057 ) ) );
				float3 temp_output_21_0_g1047 = VertexNormal259_g1;
				float dotResult55_g1047 = dot( temp_output_21_0_g1047 , temp_output_3_0_g1047 );
				float dotResult56_g1047 = dot( temp_output_21_0_g1047 , temp_output_4_0_g1047 );
				float dotResult57_g1047 = dot( temp_output_21_0_g1047 , temp_output_5_0_g1047 );
				float3 normalizeResult31_g1047 = normalize( ( ( dotResult55_g1047 * normalizeResult27_g1051 ) + ( dotResult56_g1047 * temp_output_65_0_g1047 ) + ( dotResult57_g1047 * temp_output_65_22_g1047 ) ) );
				float3 lerpResult227_g1 = lerp( normalizeResult31_g1057 , normalizeResult31_g1047 , temp_output_208_0_g1);
				float3 temp_output_24_0_g1052 = VertexNormal259_g1;
				float dotResult61_g1052 = dot( temp_output_42_0_g1052 , temp_output_24_0_g1052 );
				float dotResult62_g1052 = dot( temp_output_4_0_g1052 , temp_output_24_0_g1052 );
				float dotResult60_g1052 = dot( temp_output_43_0_g1052 , temp_output_24_0_g1052 );
				float3 normalizeResult33_g1052 = normalize( ( ( dotResult61_g1052 * temp_output_85_23_g1052 ) + ( dotResult62_g1052 * temp_output_85_0_g1052 ) + ( dotResult60_g1052 * temp_output_85_22_g1052 ) ) );
				float3 lerpResult233_g1 = lerp( lerpResult227_g1 , normalizeResult33_g1052 , temp_output_222_0_g1);
				float3 lerpResult419_g1 = lerp( lerpResult233_g1 , lerpResult227_g1 , ClipDick413_g1);
				float3 lerpResult238_g1 = lerp( lerpResult419_g1 , VertexNormal259_g1 , temp_output_226_0_g1);
				float3 ifLocalVar391_g1 = 0;
				if( temp_output_234_0_g1 <= 0.0 )
				ifLocalVar391_g1 = VertexNormal259_g1;
				else
				ifLocalVar391_g1 = lerpResult238_g1;
				
				float lerpResult424_g1 = lerp( 1.0 , InsideLerp123_g1 , InvisibleWhenInside420_g1);
				float vertexToFrag250_g1 = lerpResult424_g1;
				o.ase_texcoord7.z = vertexToFrag250_g1;
				
				o.ase_texcoord7.xy = v.texcoord.xy;
				o.ase_texcoord8 = v.texcoord1.xyzw;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord7.w = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = lerpResult428_g1;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.ase_normal = ifLocalVar391_g1;

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

				float2 uv_GooTongue_TongueMaterial_AlbedoTransparency = IN.ase_texcoord7.xy * _GooTongue_TongueMaterial_AlbedoTransparency_ST.xy + _GooTongue_TongueMaterial_AlbedoTransparency_ST.zw;
				
				float2 uv_GooTongue_TongueMaterial_Normal = IN.ase_texcoord7.xy * _GooTongue_TongueMaterial_Normal_ST.xy + _GooTongue_TongueMaterial_Normal_ST.zw;
				float2 uv_BulgeLanes_normal = IN.ase_texcoord7.xy * _BulgeLanes_normal_ST.xy + _BulgeLanes_normal_ST.zw;
				float3 unpack29 = UnpackNormalScale( tex2D( _BulgeLanes_normal, uv_BulgeLanes_normal ), 2.0 );
				unpack29.z = lerp( 1, unpack29.z, saturate(2.0) );
				float2 texCoord9 = IN.ase_texcoord8.xy * float2( 1,0.5 ) + float2( 0,0 );
				float2 break17 = texCoord9;
				float mulTime16 = _TimeParameters.x * 0.08;
				float2 appendResult19 = (float2(break17.x , ( mulTime16 + break17.y )));
				float4 tex2DNode8 = tex2D( _BulgeLanes_output, appendResult19 );
				float3 lerpResult30 = lerp( UnpackNormalScale( tex2D( _GooTongue_TongueMaterial_Normal, uv_GooTongue_TongueMaterial_Normal ), 1.0f ) , unpack29 , tex2DNode8.r);
				
				float4 color37 = IsGammaSpace() ? float4(0.6033356,0.1512549,0.9716981,1) : float4(0.322454,0.01989593,0.9368213,1);
				float dotResult31 = dot( WorldViewDirection , WorldNormal );
				float2 texCoord41 = IN.ase_texcoord8.xy * float2( 1,1 ) + float2( 0,0 );
				float temp_output_43_0 = saturate( sign( ( texCoord41.y - ( 1.0 - _BulgeClip ) ) ) );
				float4 lerpResult36 = lerp( float4( 0,0,0,0 ) , color37 , ( abs( dotResult31 ) * tex2DNode8.r * temp_output_43_0 ));
				
				float2 uv_GooTongue_TongueMaterial_MetallicSmoothness = IN.ase_texcoord7.xy * _GooTongue_TongueMaterial_MetallicSmoothness_ST.xy + _GooTongue_TongueMaterial_MetallicSmoothness_ST.zw;
				float4 tex2DNode13 = tex2D( _GooTongue_TongueMaterial_MetallicSmoothness, uv_GooTongue_TongueMaterial_MetallicSmoothness );
				
				float vertexToFrag250_g1 = IN.ase_texcoord7.z;
				
				float3 Albedo = tex2D( _GooTongue_TongueMaterial_AlbedoTransparency, uv_GooTongue_TongueMaterial_AlbedoTransparency ).rgb;
				float3 Normal = lerpResult30;
				float3 Emission = lerpResult36.rgb;
				float3 Specular = 0.5;
				float Metallic = tex2DNode13.r;
				float Smoothness = tex2DNode13.a;
				float Occlusion = 1;
				float Alpha = vertexToFrag250_g1;
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
115;277;2027;749;1657.279;135.7961;1.698365;True;True
Node;AmplifyShaderEditor.TextureCoordinatesNode;9;-2400.581,743.1214;Inherit;False;1;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,0.5;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;39;-2421.014,1166.811;Inherit;False;Property;_BulgeClip;BulgeClip;29;0;Create;True;0;0;0;False;0;False;0;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;17;-1617.214,871.8438;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.OneMinusNode;44;-2076.744,1160.568;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;41;-2416.745,910.3833;Inherit;False;1;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleTimeNode;16;-2077.602,603.3158;Inherit;False;1;0;FLOAT;0.08;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;18;-1574.244,1043.722;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;40;-2022.683,949.7897;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SignOpNode;42;-1891.752,1059.11;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;19;-1434.964,919.2584;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;32;-979.1683,172.3152;Inherit;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldNormalVector;33;-1110.252,388.4965;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.NormalVertexDataNode;10;-1134.74,705.1667;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;8;-1271.454,910.7476;Inherit;True;Property;_BulgeLanes_output;BulgeLanes_output;0;0;Create;True;0;0;0;False;0;False;-1;70f3cd3eb0effca489c1e47ba427ac02;70f3cd3eb0effca489c1e47ba427ac02;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DotProductOpNode;31;-762.1832,260.2476;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;43;-1763.056,1120.208;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;15;-984.8935,1005.816;Inherit;False;Property;_BulgeAmount;BulgeAmount;27;0;Create;True;0;0;0;False;0;False;0.1911196;0.24;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.AbsOpNode;35;-632.3539,324.0743;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PosVertexDataNode;47;-335.95,1083.63;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;11;-349.9149,810.2642;Inherit;False;4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ColorNode;37;-531.7908,80.58714;Inherit;False;Constant;_GlowColor;GlowColor;6;0;Create;True;0;0;0;False;0;False;0.6033356,0.1512549,0.9716981,1;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;29;-1260.647,-88.79173;Inherit;True;Property;_BulgeLanes_normal;BulgeLanes_normal;28;0;Create;True;0;0;0;False;0;False;-1;236f8c747dc5c8f488e26fe8896968d1;None;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;2;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;46;-89.68689,988.5219;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;38;-299.3038,421.3253;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;14;-1296.248,-320.649;Inherit;True;Property;_GooTongue_TongueMaterial_Normal;GooTongue_TongueMaterial_Normal;26;0;Create;True;0;0;0;False;0;False;-1;b509a39944911ce4eb35a5c83f125f34;b509a39944911ce4eb35a5c83f125f34;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;12;-1288.016,-742.7499;Inherit;True;Property;_GooTongue_TongueMaterial_AlbedoTransparency;GooTongue_TongueMaterial_AlbedoTransparency;24;0;Create;True;0;0;0;False;0;False;-1;e1ef26fa61548364a8a323ef16512443;e1ef26fa61548364a8a323ef16512443;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;36;-227.7474,200.6638;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SaturateNode;22;-1353.348,207.3987;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;24;-1170.163,183.4669;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SignOpNode;20;-1529.013,193.7695;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;30;-642.0082,-70.3913;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;45;-23.06465,764.2743;Inherit;False;PenetrationTechDeformation;1;;1;cb4db099da64a8846a0c6877ff8e2b5f;0;3;253;FLOAT3;0,0,0;False;258;FLOAT3;0,0,0;False;265;FLOAT3;0,0,0;False;3;FLOAT3;0;FLOAT;251;FLOAT3;252
Node;AmplifyShaderEditor.SamplerNode;13;-1310.248,-514.649;Inherit;True;Property;_GooTongue_TongueMaterial_MetallicSmoothness;GooTongue_TongueMaterial_MetallicSmoothness;25;0;Create;True;0;0;0;False;0;False;-1;b2ab29231afa34d4095e03f1414f0041;b2ab29231afa34d4095e03f1414f0041;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;48;151.4799,482.4089;Inherit;False;Constant;_Float5;Float 5;8;0;Create;True;0;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;3;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;True;False;False;False;False;0;False;-1;False;False;False;False;False;False;False;False;False;True;1;False;-1;False;False;True;1;LightMode=DepthOnly;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;7;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;GBuffer;0;7;GBuffer;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;1;False;-1;0;False;-1;1;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=UniversalGBuffer;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;4;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;6;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;DepthNormals;0;6;DepthNormals;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;False;True;1;LightMode=DepthNormals;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;0;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;0;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;5;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;Universal2D;0;5;Universal2D;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;1;False;-1;0;False;-1;1;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=Universal2D;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;426.14,148.6535;Float;False;True;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;2;BulgeLanes;94348b07e5e8bab40bd6c8a1e3df54cd;True;Forward;0;1;Forward;18;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;2;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;1;False;-1;0;False;-1;1;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=UniversalForward;False;False;0;Hidden/InternalErrorShader;0;0;Standard;38;Workflow;1;0;Surface;0;0;  Refraction Model;0;0;  Blend;0;0;Two Sided;1;0;Fragment Normal Space,InvertActionOnDeselection;0;0;Transmission;0;0;  Transmission Shadow;0.5,False,-1;0;Translucency;0;0;  Translucency Strength;1,False,-1;0;  Normal Distortion;0.5,False,-1;0;  Scattering;2,False,-1;0;  Direct;0.9,False,-1;0;  Ambient;0.1,False,-1;0;  Shadow;0.5,False,-1;0;Cast Shadows;1;0;  Use Shadow Threshold;0;0;Receive Shadows;1;0;GPU Instancing;1;0;LOD CrossFade;1;0;Built-in Fog;1;0;_FinalColorxAlpha;0;0;Meta Pass;1;0;Override Baked GI;0;0;Extra Pre Pass;0;0;DOTS Instancing;0;0;Tessellation;0;0;  Phong;0;0;  Strength;0.5,False,-1;0;  Type;0;0;  Tess;16,False,-1;0;  Min;10,False,-1;0;  Max;25,False,-1;0;  Edge Length;16,False,-1;0;  Max Displacement;25,False,-1;0;Write Depth;0;0;  Early Z;0;0;Vertex Position,InvertActionOnDeselection;0;637823911586179267;0;8;False;True;True;True;True;True;True;True;False;;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;2;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;True;False;False;False;False;0;False;-1;False;False;False;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;False;True;1;LightMode=ShadowCaster;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
WireConnection;17;0;9;0
WireConnection;44;0;39;0
WireConnection;18;0;16;0
WireConnection;18;1;17;1
WireConnection;40;0;41;2
WireConnection;40;1;44;0
WireConnection;42;0;40;0
WireConnection;19;0;17;0
WireConnection;19;1;18;0
WireConnection;8;1;19;0
WireConnection;31;0;32;0
WireConnection;31;1;33;0
WireConnection;43;0;42;0
WireConnection;35;0;31;0
WireConnection;11;0;10;0
WireConnection;11;1;8;1
WireConnection;11;2;15;0
WireConnection;11;3;43;0
WireConnection;46;0;11;0
WireConnection;46;1;47;0
WireConnection;38;0;35;0
WireConnection;38;1;8;1
WireConnection;38;2;43;0
WireConnection;36;1;37;0
WireConnection;36;2;38;0
WireConnection;22;0;20;0
WireConnection;24;2;22;0
WireConnection;20;0;9;2
WireConnection;30;0;14;0
WireConnection;30;1;29;0
WireConnection;30;2;8;1
WireConnection;45;253;46;0
WireConnection;1;0;12;0
WireConnection;1;1;30;0
WireConnection;1;2;36;0
WireConnection;1;3;13;1
WireConnection;1;4;13;4
WireConnection;1;6;45;251
WireConnection;1;7;48;0
WireConnection;1;8;45;0
WireConnection;1;10;45;252
ASEEND*/
//CHKSM=678576FFA78E3DB69968C8892A09CB00B95C1F3C