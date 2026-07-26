shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

// Texturas
uniform sampler2D textura_cesped : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D mascara_nieve : hint_default_black, filter_linear;
uniform vec3 color_nieve : source_color = vec3(1.0, 1.0, 1.0);

// Controles que replican el UV1 de Godot
uniform bool usar_triplanar = false;
uniform vec3 uv1_escala = vec3(1.0, 1.0, 1.0);

varying vec3 local_pos;
varying vec3 local_normal;

void vertex() {
    // Almacenamos la posición y normales para el caso en que se active el triplanar
    local_pos = VERTEX;
    local_normal = abs(NORMAL);
    local_normal /= (local_normal.x + local_normal.y + local_normal.z); 
}

void fragment() {
    vec3 color_base;

    // Evaluamos el interruptor del Inspector
    if (usar_triplanar) {
        // Lógica Triplanar escalada
        vec4 cesped_x = texture(textura_cesped, local_pos.zy * uv1_escala.zy);
        vec4 cesped_y = texture(textura_cesped, local_pos.xz * uv1_escala.xz);
        vec4 cesped_z = texture(textura_cesped, local_pos.xy * uv1_escala.xy);
        
        color_base = (cesped_x * local_normal.x + cesped_y * local_normal.y + cesped_z * local_normal.z).rgb;
    } else {
        // Lógica UV estándar repetible (Escalada solo en X e Y)
        color_base = texture(textura_cesped, UV * uv1_escala.xy).rgb;
    }

    // Leemos la máscara de nieve. CRÍTICO: El UV de la máscara NO se multiplica por uv1_escala.
    float intensidad_nieve = texture(mascara_nieve, UV).r;

    // Mezcla final
    ALBEDO = mix(color_base, color_nieve, intensidad_nieve);
}