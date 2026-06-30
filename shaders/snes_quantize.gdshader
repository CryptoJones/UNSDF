shader_type canvas_item;
// Global posterize/quantize pass — snaps any stray color to a ~15-bit-per-channel
// grid so the whole frame stays inside an authentic 16-bit-era color space.
// Attach to a full-screen ColorRect/CanvasLayer, or to a BackBufferCopy chain.

uniform int levels : hint_range(2, 64) = 32;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	c.rgb = floor(c.rgb * float(levels) + 0.5) / float(levels);
	COLOR = c;
}
