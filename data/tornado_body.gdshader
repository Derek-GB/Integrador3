shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded;

uniform sampler2D noise_tex : hint_default_white;
uniform float scroll_speed : hint_range(0.0, 5.0) = 1.5;
uniform float twist_amount : hint_range(0.0, 10.0) = 3.0;
uniform float wobble_amount : hint_range(0.0, 0.5) = 0.08;
uniform vec4 base_color : source_color = vec4(0.5, 0.5, 0.6, 1.0);
uniform float alpha_strength : hint_range(0.0, 2.0) = 1.0;

uniform vec4 rim_color : source_color = vec4(0.6, 0.85, 1.0, 1.0);
uniform float rim_power : hint_range(0.5, 8.0) = 3.0;
uniform float rim_strength : hint_range(0.0, 2.0) = 0.6;

void vertex() {
    vec3 pos = VERTEX;
    float h = pos.y;
    float angle = h * twist_amount + TIME * scroll_speed;
    float c = cos(angle * 0.3);
    float s = sin(angle * 0.3);
    VERTEX.x = pos.x * c - pos.z * s;
    VERTEX.z = pos.x * s + pos.z * c;

    float wobble_falloff = 1.0 - smoothstep(0.0, 1.0, h);
    VERTEX.x += sin(TIME * 1.3) * wobble_amount * wobble_falloff;
    VERTEX.z += cos(TIME * 1.1) * wobble_amount * wobble_falloff;
}

void fragment() {
    vec2 uv = UV;
    uv.y -= TIME * scroll_speed * 0.5;
    uv.x += sin(uv.y * 10.0 + TIME) * 0.05;
    float noise = texture(noise_tex, uv).r;
    float edge_fade = smoothstep(0.0, 0.15, UV.x) * smoothstep(1.0, 0.85, UV.x);

    // Mezcla blanco/gris según el ruido — nubes en vez de gris plano
    vec3 cloud_white = vec3(0.95, 0.95, 0.97);
    vec3 surface_color = mix(base_color.rgb, cloud_white, smoothstep(0.3, 0.7, noise));

    // Anillo blanco en la cara que mira hacia arriba (la tapa del cilindro),
    // el centro se mantiene gris opaco
    float is_top_face = smoothstep(0.7, 0.95, NORMAL.y);
    vec2 cap_centered = UV - vec2(0.5);
    float cap_dist = length(cap_centered);
    float top_ring = smoothstep(0.08, 0.22, cap_dist) * (1.0 - smoothstep(0.3, 0.45, cap_dist));
    surface_color = mix(surface_color, cloud_white, top_ring * is_top_face);

    float fresnel = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), rim_power);
    ALBEDO = mix(surface_color, rim_color.rgb, fresnel * rim_strength);
    ALPHA = noise * edge_fade * alpha_strength;
}