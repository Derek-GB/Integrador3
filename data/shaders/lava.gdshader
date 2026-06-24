shader_type spatial;

// Puertos para texturas
uniform sampler2D textura_roca : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D textura_mascara : source_color;
uniform sampler2D textura_ruido : source_color, filter_linear_mipmap, repeat_enable;

// Parámetros de control
uniform float escala_uv_roca : hint_range(0.01, 50.0) = 0.5; 
uniform float suavidad_triplanar : hint_range(1.0, 15.0) = 5.0; // Evita cortes duros entre ángulos
uniform vec4 color_lava : source_color = vec4(1.0, 0.3, 0.0, 1.0);
uniform float velocidad_lava : hint_range(0.0, 2.0) = 0.2;
uniform float umbral_corte : hint_range(0.0, 1.0) = 0.45;
uniform float intensidad_brillo : hint_range(0.0, 20.0) = 5.0;

// Variables para pasar la geometría del vértice al fragmento
varying vec3 pos_local;
varying vec3 normal_local;

void vertex() {
    // Capturamos la posición y normal de la geometría en el espacio
    pos_local = VERTEX;
    normal_local = NORMAL;
}

void fragment() {
    // 1. Algoritmo Triplanar para la Roca (Adiós al estiramiento)
    vec3 pesos = abs(normal_local);
    pesos = pow(pesos, vec3(suavidad_triplanar));
    pesos /= dot(pesos, vec3(1.0)); // Normalizamos para que la suma sea 1.0

    // Proyectamos la textura desde los ejes X, Y y Z
    vec3 textura_x = texture(textura_roca, pos_local.zy * escala_uv_roca).rgb;
    vec3 textura_y = texture(textura_roca, pos_local.xz * escala_uv_roca).rgb;
    vec3 textura_z = texture(textura_roca, pos_local.xy * escala_uv_roca).rgb;

    // Mezclamos el resultado final de la piedra
    vec3 roca_real = textura_x * pesos.x + textura_y * pesos.y + textura_z * pesos.z;
    
    // 2. Máscara estática (Ésta SÍ usa el UV original horneado en Blender)
    float mascara = texture(textura_mascara, UV).r;
    
    // 3. Físicas del fluido (Ruido animado)
    vec2 uv_animada = UV + vec2(0.0, TIME * velocidad_lava);
    float ruido = texture(textura_ruido, uv_animada).r;
    
    // 4. Corte matemático
    float canal_lava = step(umbral_corte, mascara);
    
    // 5. Aplicación final
    ALBEDO = mix(roca_real, color_lava.rgb, canal_lava);
    EMISSION = color_lava.rgb * canal_lava * ruido * intensidad_brillo;
}