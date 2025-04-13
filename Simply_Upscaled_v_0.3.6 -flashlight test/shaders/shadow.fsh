#version 120
#include "/settings.glsl"

//if POTATO_SHADOWS != 1
	uniform sampler2D lightmap;
	uniform sampler2D texture;

	varying vec2 lmcoord;
	varying vec2 texcoord;
	varying vec4 glcolor;
//endif




void main() {
//if POTATO_SHADOWS != 1
	vec4 color = texture2D(texture, texcoord) * glcolor;
	color.rgb = vec3(0.,0.,1.);//debug
    gl_FragData[0] = vec4(color);
//else
	// gl_FragData[0] = vec4(0.,0.,0.,1.);;
//endif
	
}

#version 120

uniform sampler2D lightmap;
uniform sampler2D texture;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;

void main() {
	vec4 color = texture2D(texture, texcoord) * glcolor;
    color.rgb = vec3(0.,0.,1.);
	gl_FragData[0] = color;
}