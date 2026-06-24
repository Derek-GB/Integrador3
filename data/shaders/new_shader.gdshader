
shader_type spatial;

uniform vec4 water_color = vec4(0.2, 0.6, 1.0, 0.7); // azul cartoon con transparencia
uniform float speed = 1.0;
uniform float scale = 4.0;
uniform float amplitude = 0.05;

void fragment() {
    vec2 uv = UV;
    uv.x += TIME * speed; // desplazamiento horizontal
    uv.y += sin(UV.x * scale + TIME * speed) * amplitude; // ondas suaves
    ALBEDO = water_color.rgb;
    ALPHA = water_color.a; // transparencia
}

void vertex() {
    VERTEX.y += sin(VERTEX.x * scale + TIME * speed) * amplitude;
}
