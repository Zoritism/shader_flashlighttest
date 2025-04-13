#include "/settings.glsl"
#include "/noise.glsl"

	#if defined IS_IRIS && defined DISTANT_HORIZONS && DH_SHADOWS == 1 && DUAL_DISTORT == 1
			//per fragment shadow pos
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
	#endif

#if DH_FLYING_FIX_CIRCLE == 1
	uniform float frametime;
	uniform vec3 previousCameraPosition;
	uniform bool is_on_ground;
	uniform float speed_smooth1;
	
#endif

#if FLASH_LIGHT > 0
	uniform float viewWidth;
	uniform float viewHeight;
	uniform int heldItemId;
	uniform int heldItemId2;
#endif

uniform vec3 cameraPosition;

#if HAND_HELD_TORCH > 0 
	uniform int heldBlockLightValue;
	uniform int heldBlockLightValue2;
#endif

#define UPSCALE_TERRAIN 1 //[0 1]
#define UPSCALE_ENTITIES 1 //[0 1]
#define UPSCALE_HAND_HELD 0 //[0 1]
#define UPSCALE_PARTICLES 0 //[0 1]

#if DH_SHADOWS == 1
#endif

uniform float far;
uniform float near;

#if defined IS_IRIS
	#if defined DISTANT_HORIZONS
		uniform float dhNearPlane;
		uniform float dhFarPlane;
		float far1 = dhFarPlane*DH_FOG_END;
		#if THIS_IS_DISTANT_HORIZONS > 0 
			
			uniform sampler2D depthtex0;
			float linearize_depth_1(in float d)
			{
				// from gl_FragCoord.z to world measurements
				//float far4 = dhFarPlane*4.;
				return 2.0 * near  * far / (far + near - (2.0 * d - 1.0) * (far - near));

			}
			
		#endif
	#endif
		uniform vec3 playerBodyVector;
		uniform vec3 relativeEyePosition;
#endif

#if defined IS_IRIS && defined DISTANT_HORIZONS
#else
	float far1 = far;
#endif

const vec4 colortex1ClearColor = vec4(10000.,0.,0.,0.);


uniform sampler2D lightmap;

	#define COLORED_SHADOWS 1 //[0 1] //0: Stained glass will cast ordinary shadows. 1: Stained glass will cast colored shadows.
	#define SHADOW_BRIGHTNESS 0.75 //Light levels are multiplied by this number when the surface is in shadows [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]

	uniform sampler2D shadowcolor0;
	uniform sampler2D shadowtex0;
	uniform sampler2D shadowtex1;
	varying vec4 shadowPosv;
	vec4 shadowPos;
#if SHADOWS == 1
#endif
uniform sampler2D texture;
uniform sampler2D normals;
uniform sampler2D specular;


uniform int isEyeInWater;
uniform float fogStart;
uniform float fogEnd;
uniform vec3 fogColor;
uniform float rainStrength;
uniform float sunAngle;


varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;
#if SHOW_MOB_DAMAGE == 1 && IS_AN_ENTITY == 1
	uniform vec4 entityColor;
#endif

varying vec4 viewPos;

#if IS_THE_NETHER == 1 || SHADOWS == 7 || (defined IS_IRIS && ((THIS_IS_DISTANT_HORIZONS == 1 && IS_WATER_SHADER == 1 )|| DH_TEXTURE > 0)) || (IS_WATER_SHADER == 1 && FANCY_WATER > 0)
	varying vec3 world_pos;
#endif
#if IS_THE_NETHER == 1
	uniform float frameTimeCounter;
#endif

//fix artifacts when colored shadows are enabled
const bool shadowcolor0Nearest = true;
const bool shadowtex0Nearest = true;
const bool shadowtex1Nearest = true;

//only using this include for shadowMapResolution,
//since that has to be declared in the fragment stage in order to do anything.
#include "/distort.glsl"

varying float ipbr_id;



    vec2 dfdx = dFdx(texcoord.st);
	vec2 dfdy = dFdy(texcoord.st);
	varying  vec4 vlocal_uv_components;//CTMPOMFIX
	varying  vec4 vlocal_uv;//CTMPOMFIX
	#include "/timetravelbeards_Better_3D_Textures.glsl"


#if PBR > 0 || HAND_HELD_TORCH > 0 
	varying vec3 normals_face;
#endif
#if PBR > 0
	varying vec4 tangent;
	uniform vec3 shadowLightPosition;
	uniform vec3 upPosition;
	#if PBR >=2
		uniform float wetness;
		#if SSS >= 1  && PBR >= 2
           const float	iShadowDepth = 1./256.;
		#endif
  	#endif
#endif
#if PBR >=2 || SKY_COLOR_ALTERNATE == 1
		uniform vec3 skyColor;
#endif

#if defined IS_IRIS && defined DISTANT_HORIZONS && DH_SHADOWS == 0
	
#endif
#if defined IS_IRIS && defined DISTANT_HORIZONS && DH_SHADOWS > 0 && LONG_SUNSET_SHADOWS == 1
	uniform mat4 shadowProjection;
	float Shadow_map_depth = -2.0 / shadowProjection[2][2];
	//float Shadow_map_depth =256.0;
#else
	float Shadow_map_depth =256.0;
#endif

#include "/check_shadow_depth.glsl"


	
	
#if defined IS_IRIS && defined DISTANT_HORIZONS
float linearize_depth_dh(in float d)
{
    // from gl_FragCoord.z to world measurements
    return 2.0 * dhNearPlane  * dhFarPlane / (dhFarPlane + dhNearPlane - (2.0 * d - 1.0) * (dhFarPlane - dhNearPlane));

}
	float linearize_depth(in float d)
		{
			// from gl_FragCoord.z to world measurements

			return 2.0 * near  * far / (far + near - (2.0 * d - 1.0) * (far - near));

		}
#endif
		
	
void main() {
	#if DEBUG_MODE > 0
		vec3 debugdata3;;
	#endif
	
	#if DH_FLYING_FIX_CIRCLE == 1
		float player_speed =  
		#if defined IS_IRIS
			#if DH_FLYING_FIX_CIRCLE_ONLY_IN_AIR == 1
				is_on_ground? 0.: 
			#endif
		#endif
		
		  speed_smooth1;
				
		float dh_discard_circle = .9*clamp(1.-(player_speed-3.)/DH_FLYING_FIX_CIRCLE_SPEED,0.,1.);
		float dh_discard_circle_small = max(0.,dh_discard_circle-.1);
	#else
		float dh_discard_circle = .9;
		float dh_discard_circle_small = .8;
	#endif

	shadowPos=shadowPosv;
	
	#if defined IS_IRIS && defined DISTANT_HORIZONS && DH_SHADOWS == 1 && DUAL_DISTORT == 1
			//per fragment shadow pos
			vec4 playerPos = gbufferModelViewInverse * viewPos;
			shadowPos = shadowProjection * (shadowModelView * playerPos); //convert to shadow ndc space.
			float bias = computeBias(shadowPos.xyz);
			shadowPos.xyz = distort(shadowPos.xyz); //apply shadow distortion
			shadowPos.xyz = shadowPos.xyz * 0.5 + 0.5; //convert from -1 ~ +1 to 0 ~ 1
			shadowPos.w=shadowPosv.w;
	#endif



	float dist = distance(vec3(0.),viewPos.xyz);
	
	#if defined IS_IRIS && defined DISTANT_HORIZONS
		#if THIS_IS_DISTANT_HORIZONS > 0 
			#if IS_WATER_SHADER == 1
				//vec2 screencoord = ((gl_FragCoord.xy))*texelSize;
				float od = texelFetch(depthtex0,ivec2(gl_FragCoord.xy),0).r;
				float old_d = linearize_depth_1(od);

				float new_d = dist;//linearize_depth_dh((gl_FragCoord.z));
				#if SMOOTH_DH_FADE_IN >= 2
					//color.a *= 1.-clamp((dist-far*(1.-DH_FADE))/(far*DH_FADE),0.,1.);
					if( dist<=far*dh_discard_circle)
					{
						discard;
					};
				#endif
					//if (old_d < new_d )//|| new_d < far*.9)
					//if(abs(relative_position_w_pom.z) < abs(texture2D(colortex15, screencoord).z))
					{
						if (od < 1. )
						{
							discard;
							return;
						}
					}
				
			#else
				if(dist < far*dh_discard_circle_small)
				{
					discard;
					return;
				}
			#endif
			
		#else
			#if SMOOTH_DH_FADE_IN >= 2
				if( dist>far*.9)
				{
					discard;
				};
			#endif
		#endif
	#endif



	float face_shading = clamp(shadowPos.w,0.,1.);
	
	
	
	#if defined IS_IRIS && defined DISTANT_HORIZONS && THIS_IS_DISTANT_HORIZONS == 1
		vec4 color= glcolor;

		#if DH_TEXTURE > 0
			color.rgb+=-.5*DH_TEXTURE_STR+DH_TEXTURE_STR
			#if DH_FANCY_NOISE > 0 
				*fractal_noise_3d(world_pos.xyz,DH_NOISE_FRACTAL_STEPS);
			#else
				*hashfrom3(floor((world_pos.xyz)*4.)/4.);
			#endif
		#endif
		
			#if PBR > 0
				vec4 normals_pixel = vec4(0.5,0.5,1.0,1.0);
			#endif
			#if PBR >= 2
				vec4 specular_pixel = vec4(0.0,0.0,0.0,0.0);
			#endif
	#else
		#if TEXTURE_FILTERING_CPF > 0 && FILTER_HERE == 1
			vec4 color= atlas_uv_to_bilinear_data( texcoord,dist )*glcolor;
			#if PBR > 0
				vec4 normals_pixel = atlas_uv_to_bilinear_data_normal( texcoord,dist );
			#endif
			#if PBR >= 2
				vec4 specular_pixel = atlas_uv_to_bilinear_data_specular( texcoord,dist );
			#endif
		#else
			vec4 color = texture2D(texture, texcoord) * glcolor;
			#if PBR > 0
				vec4 normals_pixel = texture2D(normals, texcoord);
			#endif	
			#if PBR >= 2
				vec4 specular_pixel = texture2D(specular, texcoord);
			#endif
		#endif
		
		#if defined IS_IRIS && defined DISTANT_HORIZONS
			#if THIS_IS_DISTANT_HORIZONS != 1
				#if SMOOTH_DH_FADE_IN >= 1
					#if TEXTURE_SIZE_AVAILABLE == 1
						color.rgb=mix(color.rgb,
					textureLod(texture, texcoord.xy,log2(float(textureSize(texture, 0).x))).rgb* glcolor.rgb
					#endif
						#if DH_TEXTURE > 0
						+-.5*DH_TEXTURE_STR+DH_TEXTURE_STR
						#if DH_FANCY_NOISE > 0 
							*fractal_noise_3d(world_pos.xyz,DH_NOISE_FRACTAL_STEPS)
						#else
							*hashfrom3(floor((world_pos.xyz)*4.)/4.)
						#endif
					#endif
					,
					clamp((dist-far*(1.-DH_FADE))/(far*DH_FADE),0.,1.));
					
				#endif	
			#endif
		#endif
		//color.rgb*=1.-clamp((dist-far*.8)/(far*.1),0.,1.);
	#endif
	
	//if (color.a<1./255.) discard; //shouldnn't be needed
	float sss = 0.;
	#if PBR >= 2
		//sss
		 sss = specular_pixel.b;
		sss=sss<64.5/255.?0.:sss;
		//emmission
		specular_pixel.a=specular_pixel.a >=254.5/255.?0.:specular_pixel.a;
	#endif
	#if SSS >= 1 && SHADOWS > 0
		//ipbr sss
	
		#if PBR < 2
			#if SSS >= 2
					sss= max(.25,(abs(ipbr_id-10001.)<=.5? 1. :0.));
			#else
					sss= (abs(ipbr_id-10001.)<=.5? 1. :0.);
			#endif
	
		#else
			#if SSS >= 2
					sss= max(sss,max(.25,(abs(ipbr_id-10001.)<=.5? 1. :0.)));
			#else
					sss= max(sss,(abs(ipbr_id-10001.)<=.5? 1. :0.));
			#endif
	
		#endif

	#endif
	#if SHADOWS > 0 && DH_SHADOWS == 0
		float actual_shadow_distance = min(far,shadowDistance);
		float shadow_edge_fade = clamp((dist-actual_shadow_distance*(1.-SHADOW_FADE))/(actual_shadow_distance*SHADOW_FADE),0.,1.);
		sss *= 1.-shadow_edge_fade;
	#endif

	
	
	
	
	
	float main_lighting = sunAngle <.5 ? SUN_BRIGHTNESS : MOON_BRIGHTNESS ;
	
	
	
	vec2 lm = lmcoord;
	
			//Lighting Primary
						lm.x=pow(lm.x,TORCH_FALLOFF);
						
		

						
						
						
						
						
						float lmy_og=lm.y;
					
					
						
						lm.y=
						#if BRIGHTER_UNDERWATER == 1
							isEyeInWater == 0?
						#endif
						pow(lm.y,SKY_LIGHT_FALLOFF)*SKY_LIGHT_BRIGHTNESS
						#if BRIGHTER_UNDERWATER == 1
							:.8
						#endif
						;
						
						
						vec3 sky_color = 
						#if SKY_COLOR_ALTERNATE == 1
							#if EXTRA_DARK_NIGHT > 0
								mix(
								skyColor,
								vec3(0.),
								clamp((1.-abs(sunAngle-.75)*4.)*10.,0.,1.)*float(EXTRA_DARK_NIGHT)*.1
								)
							#else
								skyColor
							#endif
						#else
							#if EXTRA_DARK_NIGHT > 0
								mix(
								texture2D(lightmap, vec2(1./32.,lm.y)).rgb,
								vec3(0.),
								clamp((1.-abs(sunAngle-.75)*4.)*10.,0.,1.)*float(EXTRA_DARK_NIGHT)*.1
								)
							#else
								texture2D(lightmap, vec2(1./32.,lm.y)).rgb
							#endif	
						#endif
						
						
						;
						
						
						
					#if SUNSET == 0
						vec3 sun_color =
						
						#if CUSTOM_SUN_COLOR == 0
							texture2D(lightmap, vec2(1./32.,lmy_og)).rgb //sky_color at lmy_og
						#endif
						#if CUSTOM_SUN_COLOR == 1
							(sunAngle <.5 ?
							vec3(SUN_COLOR_R,SUN_COLOR_G,SUN_COLOR_B)
							:vec3(MOON_COLOR_R,MOON_COLOR_G,MOON_COLOR_B)
							)
							
						#endif
						;
					#endif
					
					#if SUNSET == 2
						vec3 sun_color =
						clamp(
						
						#if CUSTOM_SUN_COLOR == 0
							texture2D(lightmap, vec2(1./32.,lmy_og)).rgb //sky_color at lmy_og
						#endif
						#if CUSTOM_SUN_COLOR == 1
							(sunAngle <.5 ?
							 vec3(SUN_COLOR_R,SUN_COLOR_G,SUN_COLOR_B)
							 :vec3(MOON_COLOR_R,MOON_COLOR_G,MOON_COLOR_B)
							 )
						#endif

						  -
						  vec3(SUNSET_FADE_R,SUNSET_FADE_G,SUNSET_FADE_B )
						  *(1.-clamp((1.-abs(sunAngle-
						  (sunAngle<.5? .25 : .75)
						  
						  )*4.)*10.,0.,1.))
						  ,0.,1.)
						  ;
					#endif
						 
						 
					#if SUNSET == 1
							#if CUSTOM_SUN_COLOR == 0
								vec3 sun_color = texture2D(lightmap, vec2(1./32.,lmy_og)).rgb //sky_color at lmy_og
							#endif
							#if CUSTOM_SUN_COLOR == 1
								vec3 sun_color =
								sunAngle <.5 ?
								 vec3(SUN_COLOR_R,SUN_COLOR_G,SUN_COLOR_B)
								 :vec3(MOON_COLOR_R,MOON_COLOR_G,MOON_COLOR_B)
							 #endif
						*clamp((1.-abs(sunAngle-
						  (sunAngle<.5? .25 : .75)
						  
						  )*4.)*10.,0.,1.);
				
	 
					#endif
				
					
					#if FIX_COLOR_SPACE == 1
						sky_color.rgb=pow(sky_color.rgb,vec3(2.2));
						sun_color.rgb=pow(sun_color.rgb,vec3(2.2));
					#endif
						
					
						
						
							
								
						
						
						
						vec4 shadowLightColor=vec4(1.0);
						
						
	#if PBR > 0
		
				
		float ao_allowed_light = mix(1.,normals_pixel.z,AMBIENT_OCCLUSSION_TEXTURES);
		normals_pixel.xy=normals_pixel.xy*2.-1.;
		normals_pixel.z = sqrt(1.0-dot(normals_pixel.xy, normals_pixel.xy)); //Reconstruct Z
		
		normals_pixel.xyz =normalize(normals_pixel.xyz );//fsster no norm?
	
	

		vec3 sky_shine = vec3(pow(lmy_og,10.));
		vec3 n_sky_dir = normalize(upPosition);
		
		#if PBR >= 2
		
			#if (IS_WATER_SHADER == 1 && FANCY_WATER > 0) == 1
				if(abs(ipbr_id-10020.)<=.5)
				{
					float w = fractal_noise_3d(world_pos.xyz,4);
					float w2 = fractal_noise_3d(world_pos.xyz+vec3(.1,0.,0.),4);
					float w3 = fractal_noise_3d(world_pos.xyz+vec3(0.,0.1,0.),4);
					
					float g=w-w3;
					float r =w-w2;
					float b = 1. -(abs(r)+abs(g));
					 
					normals_pixel = vec4(r,g,1.,1.);
					//normals_pixel.xy = normals_pixel.xy;
					//normals_pixel.z = sqrt(1.0-dot(normals_pixel.xy, normals_pixel.xy)); //Reconstruct Z
					
					color.rgb = vec3(normals_pixel.xyz);//debug
					
					specular_pixel = vec4(.8,0.9,1.,0.);
				}
			#endif
		
		
		
			float metalness = specular_pixel.g>=229.5/255.?1.:0.;
			
			
			
			float sky_dot_face = dot(n_sky_dir,normals_face.xyz);
				//porosity
				float actual_wetness=clamp(sky_shine.r,0.,1.)
				*max(0.,sky_dot_face)
				*wetness;
				//wet porosity darkening
				float porosity = specular_pixel.b;
				porosity=porosity>=64.5/255.?0:porosity/64.;



				actual_wetness*=1.-.25*porosity;
				specular_pixel.g=mix(specular_pixel.g,1.,
				min(1.,actual_wetness*1.));
				specular_pixel.r =mix(specular_pixel.r,1., min(1.,actual_wetness*2.));
				float puddles = sky_dot_face*PUDDLE_DEPTH;
					normals_pixel.xy=mix(normals_pixel.xy,vec2(0.),min(1.,actual_wetness*1.5*puddles));
				normals_pixel.z = mix(normals_pixel.z,1.,min(1.,actual_wetness*1.5*puddles));
				normals_pixel.xyz= normalize(normals_pixel.xyz);
			#endif
		
        



		vec3 tangent2 = normalize(cross(tangent.rgb,normals_face.xyz)*tangent.w);
		mat3 tbn_matrix = mat3(tangent.xyz, tangent2.xyz, normals_face.xyz);

		normals_pixel.xyz = normalize(tbn_matrix * normals_pixel.xyz); //Rotate by TBN matrix //faster no norm?
			
		float sun_lighting = max(sss,clamp (dot(normalize(shadowLightPosition), normals_pixel.xyz) ,0.,1.)) ;
		
		float sky_lighting = clamp((dot(n_sky_dir,normals_pixel.xyz)+1.)*.5, NON_DIRECTIONAL_AMBIENT_SKY_LIGHT ,1.);//fix?
		
		#if BORDERS >= 2 
			float sun_lighting_back = max(sss,clamp (dot(normalize(shadowLightPosition), 
			normalize( mix(-normals_pixel.xyz,vec3(0.,0.,-1.),0.5) )
			) ,0.,1.)) ;
			float sky_lighting_back = clamp((dot(n_sky_dir,
			normalize( mix(-normals_pixel.xyz,vec3(0.,0.,-1.),0.5) )
			)+1.)*.5, NON_DIRECTIONAL_AMBIENT_SKY_LIGHT ,1.);//fix?
		#endif
		
	#else
		#if SSS >= 1  && SHADOWS > 0
			float sun_lighting=  max(sss,face_shading); //sunlighting wo normals
		#else
			float sun_lighting=  face_shading; //sunlighting wo normals
		#endif
		
	#endif
	
	
	
	#if HAND_HELD_TORCH > 0 
		
		#if FLASH_LIGHT == 2
			float f_dist = clamp( 1.-distance( vec3(0.),viewPos.xyz )/ HAND_HELD_TORCH_RANGE ,0.,1.);
			float radial_fl = (1. -2.* distance(gl_FragCoord.xy,.5*vec2(viewWidth,viewHeight))/(viewHeight*2.*FLASH_LIGHT_WIDTH*(.25+.75*(1.-f_dist))));
			
		#endif
		#if PBR == 0
			vec3 normals_pixel = normals_face.xyz;	
		#endif
		float torch_hand_light = heldBlockLightValue > 0 || heldBlockLightValue2 > 0 ? 
		
		
		#if FLASH_LIGHT < 2
			clamp( 1.-distance( vec3(0.),viewPos.xyz )/ HAND_HELD_TORCH_RANGE ,0.,1.)
		#endif
		
		
		#if FLASH_LIGHT == 1
			#if FLASH_LIGHT_LISTED_ITEMS_ONLY == 1
				*((heldItemId2 == 1 || heldItemId== 1) ? 
				clamp( (1. -2.* distance(gl_FragCoord.xy,.5*vec2(viewWidth,viewHeight))
				/(viewHeight*FLASH_LIGHT_WIDTH)
				) 
				*FLASH_LIGHT_CRISPNESS
				,0.,1.)
				:1.
				)
			#else
				*clamp( (1. -2.* distance(gl_FragCoord.xy,.5*vec2(viewWidth,viewHeight))
				/(viewHeight*FLASH_LIGHT_WIDTH)
				) 
				*FLASH_LIGHT_CRISPNESS
				,0.,1.)
			#endif
		#endif
		#if FLASH_LIGHT == 2
			#if FLASH_LIGHT_LISTED_ITEMS_ONLY == 1
				f_dist		
				*(
				(heldItemId2 == 1 || heldItemId== 1) ? 
				clamp( radial_fl *FLASH_LIGHT_CRISPNESS,0.,1.) 
				* .7*((f_dist+radial_fl*f_dist)+pow(abs(sin(3.+radial_fl*8.*f_dist) ),2.-radial_fl) )
				:1.)
			#else
				f_dist		
			*clamp( radial_fl *FLASH_LIGHT_CRISPNESS,0.,1.) 
			* .7*((f_dist+radial_fl*f_dist)+pow(abs(sin(3.+radial_fl*8.*f_dist) ),2.-radial_fl) )
			
			#endif
			
		#endif
		 
		#if TORCH_LIGHT_3D == 1
			*
			(
			(heldBlockLightValue>0?1.:0.) * clamp(dot(normals_pixel.xyz,normalize(vec3(0.5,-.5,1.))),0.0,1.) 
			+
			(heldBlockLightValue2>0?1.:0.) * clamp(dot(normals_pixel.xyz,normalize(vec3(-0.5,-.5,1.))),0.0,1.)
			)
		#endif
		#if TORCH_LIGHT_3D == 2
			*
			(
			(heldBlockLightValue>0?1.:0.) * clamp(dot(normals_pixel.xyz,normalize(-viewPos.xyz-vec3(-TORCH_HORIZONTAL_OFFSET,-TORCH_V_OFFSET,TORCH_Z_OFFSET))),0.0,1.) 
			+
			(heldBlockLightValue2>0?1.:0.) * clamp(dot(normals_pixel.xyz,normalize(-viewPos.xyz-vec3(TORCH_HORIZONTAL_OFFSET,-TORCH_V_OFFSET,TORCH_Z_OFFSET))),0.0,1.)
			)
		#endif
		: 0.0;
		//float torch_hand_light = 0.;
		lm.x=min(1.,lm.x+pow(torch_hand_light,TORCH_FALLOFF));
	#endif
		
		#if CUSTOM_TORCH_COLOR == 0
			vec3 torch_color = 
				vec3(1.,0.9,0.8)*TORCH_BRIGHTNESS;
				//texture2D(lightmap, vec2(lm.x,0.1)).rgb;//
		#endif
		#if CUSTOM_TORCH_COLOR == 1
			vec3 torch_color = 
				vec3(TORCH_HI_R,TORCH_HI_G,TORCH_HI_B)*TORCH_BRIGHTNESS;
				
		#endif
		#if CUSTOM_TORCH_COLOR == 2
			vec3 torch_color = 
				mix(vec3(TORCH_LOW_R,TORCH_LOW_G,TORCH_LOW_B),
				vec3(TORCH_HI_R,TORCH_HI_G,TORCH_HI_B),
				lm.x)*TORCH_BRIGHTNESS
				;
				
		#endif
	
		#if IS_THE_NETHER == 1
				torch_color *=2.-1.5* clamp(vec3(1.,2.5,3.)*(1.-world_pos.y*(2.-1.*sin(frameTimeCounter))/100.),0.,1.);
		#endif
	
	
	#if PBR >= 3
		
	#endif
						
						
	#if SHADOWS >= 1
		
		#if SSS == 0
		if (face_shading > 0.0) //surface is facing towards shadowLightPosition
		#endif
		{
			#include "/shadows.glsl"

			
		}
		#if BRIGHTER_UNDERWATER == 1
			sky_color*=isEyeInWater > 0 ? main_lighting  : 1.0;
		#endif
				
		#if FIX_COLOR_SPACE == 1
			color.rgb=pow(color.rgb,vec3(2.2));
		#endif
		#include "/pbr2.glsl"
		
		
		
		color.rgb = 	
		#if PBR >= 2
			//emmissi9n
	color.rgb*specular_pixel.a*PBR_EMMISSIVE_STRENGTH+
			sun_shine+sky_shine+
		#endif 
		color.rgb* max(
		#if IS_THE_NETHER == 1
			clamp(max(vec3(MINIMUM_LIGHT_LEVEL),vec3(1.,0.9,0.7)-vec3(1.,2.5,3.)*world_pos.y*(2.+1.*sin(frameTimeCounter))/100.),0.,1.)
		#else
			vec3(MINIMUM_LIGHT_LEVEL)
		#endif
		
		
		,

			sun_lighting*		

		sun_color*
		 shadowLightColor.rgb*main_lighting
		+
		#if PBR > 0
			ao_allowed_light*
			(lm.y*sky_color*sky_lighting 
			+lm.x*torch_color)
		#else
			lm.y*sky_color
			+lm.x*torch_color
		#endif
		
		)
		;
	#else
		#if FIX_COLOR_SPACE == 1
			color.rgb=pow(color.rgb,vec3(2.2));
		#endif
		#include "/pbr2.glsl"
		color.rgb = 	
		#if PBR >= 2
			//emmissi9n
		color.rgb*specular_pixel.a*PBR_EMMISSIVE_STRENGTH+
			sun_shine+sky_shine+
		
		#endif 
		color.rgb* max(
		#if IS_THE_NETHER == 1
				clamp(max(vec3(MINIMUM_LIGHT_LEVEL),vec3(1.,0.9,0.7)-vec3(1.,2.5,3.)*world_pos.y*(2.+1.*sin(frameTimeCounter))/100.),0.,1.)
		#else
			vec3(MINIMUM_LIGHT_LEVEL)
		#endif
		,

		
		
		#if DIRECTIONAL_LIGHTING == 1
	
				sun_lighting*
	
			
			main_lighting
		#else 
			
			main_lighting
		#endif
		*sun_color
		+
	
			lm.y*sky_color
			+lm.x*torch_color

		
		);
		;
		
			
		

	
//	color.rgb=vec3(1.,0.,0.);//normals_pixel.xyz*.5+.5;//debug
	
	#endif
	
	#if SHOW_MOB_DAMAGE == 1 && IS_AN_ENTITY == 1
		color.rgb= mix(color.rgb,entityColor.rgb,entityColor.a);
	#endif
	
	#if FOG == 1 
		float water_fog = isEyeInWater == 1? 30. : isEyeInWater == 2? 20. : isEyeInWater == 1? 10. : 0.;
		water_fog = (water_fog > 1. ) ? clamp((dist)/water_fog,0.,1.) : 0.;
		//fogColor FOG_START FOG_END
			float border_fog_amount = clamp((dist-(BORDER_FOG_START*far1))/(((1.-BORDER_FOG_START)*far1)),0.,1.);
			float fog_amount = 
				clamp(
				max(
				water_fog,
				max( 
					clamp((dist-FOG_START)/(FOG_END-FOG_START),0.,FOG_MAX),
					border_fog_amount)
					*(1.+rainStrength)
					)
				,0.,1.)
				;
				
				#if EXPONENTIAL_FOG == 1
					fog_amount=pow(fog_amount,2.);
				#endif
			color.rgb = mix(color.rgb,fogColor.rgb,fog_amount);
	#endif
	
	#if DONT_BLOW_OUT_WHITES == 1
		color.r = color.r <.95?color.r : .95+(color.r-.95)*.1;
		color.g = color.g <.95?color.g : .95+(color.g-.95)*.1;
		color.b = color.b <.95?color.b : .95+(color.b-.95)*.1;
	#endif
	
	//color.rgb = vec3( lm.x ) ;//debug
	
	
	#if BORDERS >= 2
		vec4 edge_colors = 
		
		vec4(
			mix(color.rgb*3.,+vec3(1.),.25)*
			
			(sun_lighting_back)*		
			sun_color*
			shadowLightColor.rgb*main_lighting
			
			+
			color.rgb*3.*
			//(color.rgb+vec3(1.))*.5*
			#if PBR > 0
				ao_allowed_light*
				(clamp((lm.y*skyColor*sky_lighting_back -lm.y*skyColor,0.)*5.,0.,1.)*0.
					+lm.x*torch_color)
			#else
				clamp((lm.y*skyColor *sky_lighting_back -lm.y*skyColor)*5.,0.,1.)*0.
				+lm.x*torch_color
			#endif
			,1.);
		
	#endif
	
	#if DEBUG_FIX_CIRCLE == 1
	  color.rgb = dist > dh_discard_circle*far? vec3(1.,0.,0.)*player_speed/DH_FLYING_FIX_CIRCLE_SPEED: color.rgb;//debug
	#endif
	
	//color.rgb = vec3(fract(shadowPos.z*Shadow_map_depth));// <= 0.? vec3(0.,0.,1.):shadowPos.z >= 1.? vec3(1.,0.,0.):color.rgb;
	//color.rgb= abs(ipbr_id-20001.)<=.5?  vec3(1.,0.,0.) : color.rgb;//debug
	//color.rgb=vec3(fract(.1*viewPos.z));//debug

	#if FIX_COLOR_SPACE == 1
		color.rgb=pow(color.rgb,vec3(1./2.2));
	#endif

	
	#if DEBUG_MODE > 0
		color.rgb=debugdata3;
	#endif
	

	
		#if IS_THE_NETHER == 1
			//color.rgb=vec3(fract(world_pos.y));
		#endif

	#if defined IS_IRIS && defined DISTANT_HORIZONS && BORDERS_IN_DH == 1
		/* RENDERTARGETS: 0,1 */
		gl_FragData[0] = color;
		/*
			const int colortex1Format = R16F;
		*/
		gl_FragData[1].x = 
		abs(ipbr_id-10020.)<=.5? 0.:
		distance(vec3(0.),viewPos.xyz)
		; 
	#else
		/* DRAWBUFFERS:0 */
		gl_FragData[0] = color; 
	#endif



		//gl_FragData[1] = edge_colors; 

}