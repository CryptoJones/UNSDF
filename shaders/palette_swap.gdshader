shader_type canvas_item;
// Indexed palette swap — author sprites with the palette index in the red channel,
// then remap through a 1xN ramp texture. Swap the ramp at runtime for state moods
// (e.g. an "alarm red" palette when a security camera trips). Near-zero cost.

uniform sampler2D palette : filter_nearest;

void fragment() {
	vec4 src = texture(TEXTURE, UV);
	float index = src.r;
	vec3 mapped = texture(palette, vec2(index, 0.0)).rgb;
	COLOR = vec4(mapped, src.a);
}
