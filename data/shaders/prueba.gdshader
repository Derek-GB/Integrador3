shader_type spatial;
// render_mode specular_toon; // Descomenta esto si quieres un brillo estilo cartoon

// --- PARÁMETROS DEL FRAGMENTO (COLOR Y FLUJO) ---
uniform vec3 albedo : source_color = vec3(0.1, 0.4, 0.7); // Color base del agua
uniform sampler2D noise_texture; // Necesitas cargar una textura de ruido aquí
uniform vec2 flow_direction = vec2(1.0, 0.0); // Dirección hacia donde corre el río
uniform float flow_speed = 0.1; // Velocidad de la corriente

// --- PARÁMETROS DEL VÉRTICE (HUNDULEO) ---
uniform float wave_amplitude = 0.2; // Qué tan alta es la ola
uniform float wave_frequency = 2.0; // Qué tan juntas están las olas
uniform float wave_speed = 1.5;     // Qué tan rápido suben y bajan

void vertex() {
    // Calcula la onda matemática basada en la posición X del vértice y el tiempo global
    float wave = sin(VERTEX.x * wave_frequency + TIME * wave_speed) * wave_amplitude;
    
    // Aplica el movimiento al eje Y (altura)
    VERTEX.y += wave;
}

void fragment() {
    // Desplaza las coordenadas UV en la dirección y velocidad indicadas
    
	vec2 moving_uv = (UV * 50.0) + (flow_direction * TIME * flow_speed);
    
    // Lee la textura de ruido usando las nuevas UV en movimiento
    float noise_val = texture(noise_texture, moving_uv).r;
    
    // Mezcla el color base con el ruido para crear el efecto visual de corriente
    vec3 final_color = albedo + vec3(noise_val * 0.2); 
    
    ALBEDO = final_color;
    ROUGHNESS = 0.15; // Agua reflectante (bajo roughness)
    METALLIC = 0.0;   // El agua no es metal
}