#include "/settings.glsl"



/*
int dhMaterialId ==
DH_BLOCK_UNKNOWN // Any block not in this list that does not emit light
DH_BLOCK_LEAVES // All types of leaves, bamboo, or cactus
DH_BLOCK_STONE // Stone or ore
DH_BLOCK_WOOD // Any wooden item
DH_BLOCK_METAL // Any block that emits a metal or copper sound.
DH_BLOCK_DIRT // Dirt, grass, podzol, and coarse dirt.
DH_BLOCK_LAVA // Lava.
DH_BLOCK_DEEPSLATE // Deepslate, and all it's forms.
DH_BLOCK_SNOW // Snow.
DH_BLOCK_SAND // Sand and red sand.
DH_BLOCK_TERRACOTTA // Terracotta.
DH_BLOCK_NETHER_STONE // Blocks that have the "base_stone_nether" tag.
DH_BLOCK_WATER // Water...
DH_BLOCK_AIR // Air. This should never be accessible/used.
DH_BLOCK_ILLUMINATED // Any block not in this list that emits light

 THIS_IS_DISTANT_HORIZONS 1

*/


attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;

#define INFO_CLICK 0 //[0 1]

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

	uniform mat4 shadowModelView;
	uniform mat4 shadowProjection;
	uniform vec3 shadowLightPosition;
	varying vec4 shadowPosv;

	#include "/distort.glsl"
#if SHADOWS == 1
#endif


#if IS_AN_ENTITY == 1
	#if TEXTURE_FILTERING_CPF > 0 
		uniform int entityId;
	#endif
	
#endif


varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;
varying vec4 viewPos;
#if PBR > 0 || HAND_HELD_TORCH > 0 
	varying vec3 normals_face;
	
#endif
#if PBR > 0
	attribute vec4 at_tangent;
	varying vec4 tangent;
	#if PBR >=2
		
	#endif
#endif
varying float ipbr_id;

#if IS_THE_NETHER == 1 || SHADOWS == 7 || (defined IS_IRIS && ((THIS_IS_DISTANT_HORIZONS == 1 && IS_WATER_SHADER == 1 )|| DH_TEXTURE > 0)) || (IS_WATER_SHADER == 1 && FANCY_WATER > 0)
	varying vec3 world_pos;
	uniform vec3 cameraPosition;
#endif


	varying  vec4 vlocal_uv_components;//CTMPOMFIX
	varying  vec4 vlocal_uv;//CTMPOMFIX
	
	
	//attribute vec4 mc_midTexCoord;//CTMPOMFIX
void deconstruct_and_localize_uvs()//CTMPOMFIX
	{

	
		//use vertex corners of quad to get local coords and components fir reconstruction
	vec2 atlas_uvs = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	//standard get center of quad
	vec2 quad_center= (gl_TextureMatrix[0] *  mc_midTexCoord).st;
	//get center_relative_uvs
	vec2 center_relative_uvs = atlas_uvs.xy-quad_center.xy;
	
	//per vertex local coords 0.0-1.0
	vlocal_uv.st = 0.5 + 0.5 * sign(center_relative_uvs); 
	
	
	//location of uv 0,0 in texture
	vlocal_uv_components.st  = min(atlas_uvs.xy,quad_center-center_relative_uvs);
	
	//size of quad in atlas
	vlocal_uv_components.pq  =  abs(center_relative_uvs)*2.0;

	//and in frag shader
	//atlas_uv_for_tex_lookup = fract(local_uv.st)*local_uv_components.pq+local_uv_components.st;
	}
#if POM == 1 || GEN_NORMAL_MAP > 0
#endif



void main() {
	
	//if TEXTURE_FILTERING_CPF > 0
		deconstruct_and_localize_uvs();//CTMPO
	//endif

	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;

	 viewPos = vec4((gl_ModelViewMatrix * gl_Vertex).xyz,1.);
	#if IS_THE_NETHER == 1 || SHADOWS == 7 || (defined IS_IRIS && ((THIS_IS_DISTANT_HORIZONS == 1 && IS_WATER_SHADER == 1 )|| DH_TEXTURE > 0)) || (IS_WATER_SHADER == 1 && FANCY_WATER > 0)
		 vec4 playerPos = gbufferModelViewInverse * viewPos;
		 world_pos=(playerPos+gbufferModelViewInverse[3]
		 ).xyz+cameraPosition;
	#endif
	
	#if PBR > 0
		tangent = vec4(normalize(gl_NormalMatrix *at_tangent.rgb),at_tangent.w);
	#endif

	
	#if IS_AN_ENTITY == 1
		
		#if TEXTURE_FILTERING_CPF > 0 
			ipbr_id= float(entityId);
		#endif
	#else
		#if THIS_IS_DISTANT_HORIZONS == 1
			ipbr_id = 30000.;
			ipbr_id= dhMaterialId == DH_BLOCK_LEAVES ? 10001 : ipbr_id;
			#if IS_WATER_SHADER == 1
				ipbr_id= dhMaterialId == DH_BLOCK_WATER ? 10020 : ipbr_id;
			#endif
		#else
			ipbr_id= mc_Entity.x ; 
		#endif

	#endif
	



	
	
	#if PBR > 0 || HAND_HELD_TORCH > 0 
		normals_face = normalize(gl_NormalMatrix * gl_Normal);
		// (gl_TextureMatrix[1] * gl_MultiTexCoord1-1./32.).x*16./15.);
	#endif
	#if PBR > 0	
		float lightDot = dot(normalize(shadowLightPosition), normals_face.xyz);
	#else
		float lightDot = dot(normalize(shadowLightPosition), normalize(gl_NormalMatrix * gl_Normal));
	#endif
	 
		
		#if BACK_LIT_GRASS > 0
			//when EXCLUDE_FOLIAGE is enabled, act as if foliage is always facing towards the sun.
			//in other words, don't darken the back side of it unless something else is casting a shadow on it.
			if (mc_Entity.x == 10000.0) lightDot = max(lightDot,float(BACK_LIT_GRASS)*.1);
		#endif
		
	#if SHADOWS >= 1
		
	

		
		//if (lightDot > 0.0)
		{ //vertex is facing towards the sun
			#if !(IS_THE_NETHER == 1 || SHADOWS == 7 || (defined IS_IRIS && ((THIS_IS_DISTANT_HORIZONS == 1 && IS_WATER_SHADER == 1 )|| DH_TEXTURE > 0)) || (IS_WATER_SHADER == 1 && FANCY_WATER > 0))
				 vec4 playerPos = gbufferModelViewInverse * viewPos;
			#endif
			shadowPosv = shadowProjection * (shadowModelView * playerPos); //convert to shadow ndc space.
			float bias = computeBias(shadowPosv.xyz);
			shadowPosv.xyz = distort(shadowPosv.xyz); //apply shadow distortion
			shadowPosv.xyz = shadowPosv.xyz * 0.5 + 0.5; //convert from -1 ~ +1 to 0 ~ 1
			//apply shadow bias.
			#ifdef NORMAL_BIAS
				//we are allowed to project the normal because shadowProjection is purely a scalar matrix.
				//a faster way to apply the same operation would be to multiply by shadowProjection[0][0].
				vec4 normal = shadowProjection * vec4(mat3(shadowModelView) * (mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal)), 1.0);
				shadowPosv.xyz += normal.xyz / normal.w * bias;
			#else
				shadowPosv.z -= bias / abs(lightDot);
			#endif
		}
	
	
	#endif
		shadowPosv.w = lightDot;
		

	#if THIS_IS_DISTANT_HORIZONS == 1 && IS_WATER_SHADER == 1
		
		viewPos= ipbr_id==10020 ? gbufferModelView* vec4(world_pos.xyz-cameraPosition-vec3(0.,.15,0.),1.) : viewPos;
	#endif
	gl_Position = gl_ProjectionMatrix * viewPos;
	
	
}