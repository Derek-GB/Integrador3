shader_type particles;

uniform float spiral_radius : hint_range(0.1, 3.0) = 0.9;
uniform float spiral_height : hint_range(0.5, 10.0) = 5.0;
uniform float rotation_speed : hint_range(0.0, 3.0) = 0.5;
uniform float lean_x : hint_range(-2.0, 2.0) = 0.6;

float hash(uint n) {
    n = (n << 13u) ^ n;
    n = n * (n * n * 15731u + 789221u) + 1376312589u;
    return float(n & 0x7fffffffu) / float(0x7fffffff);
}

void start() {
    uint idx = uint(INDEX);
    float angle = hash(idx * 3u + 0u) * TAU;
    float h     = hash(idx * 3u + 1u);

    float radius = mix(spiral_radius, spiral_radius * 0.08, h);
    float pos_y  = h * spiral_height - spiral_height * 0.5;
    float lean_offset = lean_x * h;

    TRANSFORM[3].xyz = vec3(
        cos(angle) * radius + lean_offset,
        pos_y,
        sin(angle) * radius
    );

    CUSTOM.x = angle;
    CUSTOM.y = h;
    VELOCITY  = vec3(0.0);
}

void process() {
    float angle  = CUSTOM.x + TIME * rotation_speed;
    float h      = CUSTOM.y;
    float radius = mix(spiral_radius, spiral_radius * 0.08, h);
    float lean_offset = lean_x * h;

    TRANSFORM[3].x = cos(angle) * radius + lean_offset;
    TRANSFORM[3].z = sin(angle) * radius;

    float life = CUSTOM.w;
    COLOR.a = smoothstep(0.0, 0.2, life) * smoothstep(1.0, 0.75, life);
}