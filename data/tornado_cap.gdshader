shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded;

uniform sampler2D noise_tex : hint_default_white;
uniform float swirl_speed : hint_range(0.0, 5.0) = 2.0;
uniform float swirl_amount : hint_range(0.0, 10.0) = 4.0;
uniform vec4 cloud_color : source_color = vec4(0.45, 0.45, 0.5, 1.0);
uniform float outer_fade : hint_range(0.0, 1.0) = 0.45;
uniform vec4 rim_color : source_color = vec4(0.6, 0.85, 1.0, 1.0);
uniform float rim_strength : hint_range(0.0, 2.0) = 0.7;

void fragment() {
    vec2 centered = UV - vec2(0.5);
    float dist = length(centered);
    float angle = atan(centered.y, centered.x);

    float swirl = angle + dist * swirl_amount - TIME * swirl_speed;
    vec2 swirl_uv = vec2(cos(swirl), sin(swirl)) * dist + vec2(0.5);

    float noise = texture(noise_tex, swirl_uv).r;
    float radial_fade = 1.0 - smoothstep(outer_fade - 0.2, outer_fade, dist);

    vec3 cloud_white = vec3(0.95, 0.95, 0.97);
    vec3 surface_color = mix(cloud_color.rgb, cloud_white, smoothstep(0.3, 0.7, noise));

    float rim_mask = smoothstep(outer_fade * 0.5, outer_fade * 0.9, dist);
    ALBEDO = mix(surface_color, rim_color.rgb, rim_mask * rim_strength);
    ALPHA = noise * radial_fade;
}