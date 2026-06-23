shader_type spatial;
render_mode blend_mix, depth_draw_opaque, unshaded, cull_disabled;

uniform sampler2D cloud_tex : hint_default_white;
uniform vec4 cloud_color : source_color = vec4(0.78, 0.78, 0.82, 1.0);
uniform vec4 rim_color : source_color = vec4(0.6, 0.85, 1.0, 1.0);
uniform float rim_strength : hint_range(0.0, 1.0) = 0.4;

void fragment() {
    vec2 centered = UV - vec2(0.5);
    float dist = length(centered);

    float alpha = texture(cloud_tex, UV).r;
    float rim = smoothstep(0.2, 0.5, dist) * rim_strength;
    vec3 color = mix(cloud_color.rgb, rim_color.rgb, rim);

    ALBEDO = color;
    ALPHA = alpha * COLOR.a * smoothstep(0.5, 0.35, dist);
}