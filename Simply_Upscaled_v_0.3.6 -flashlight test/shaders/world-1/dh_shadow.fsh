#version 120

#include "/settings.glsl"

uniform sampler2D lightmap;
uniform sampler2D texture;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;

uniform float far;
varying vec3 position;
uniform vec3 cameraPosition;


void main() {
//if THIS_IS_DISTANT_HORIZONS == 1
 if(length(position.xyz-cameraPosition) < far*.9) discard;
//endif
#if DEBUG_SHADOWS == 1
	vec4 color = texture2D(texture, texcoord) * glcolor;

	gl_FragData[0] = color;
#else
gl_FragData[0] =vec4(1.);

#endif
	//gl_FragData[1].r = position.z;
	
}