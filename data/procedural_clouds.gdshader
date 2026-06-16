shader_type sky;
render_mode use_debanding;

// — Cielo arriba —
uniform vec4 sky_top_color : source_color = vec4(0.38, 0.65, 0.85, 1.0);
uniform vec4 sky_horizon_color : source_color = vec4(0.75, 0.88, 0.95, 1.0);
uniform float inv_sky_curve : hint_range(1, 100) = 4.0;

// — Cielo abajo (isla flotante, no hay suelo) —
uniform vec4 sky_bottom_color : source_color = vec4(0.45, 0.72, 0.90, 1.0);
uniform vec4 bottom_horizon_color : source_color = vec4(0.75, 0.88, 0.95, 1.0);
uniform float inv_bottom_curve : hint_range(1, 100) = 30.0;

// — Sol —
uniform float sun_angle_max = 0.877;
uniform float inv_sun_curve : hint_range(1, 100) = 22.78;
uniform float exposure : hint_range(0, 128) = 1.0;

void sky() {
    float v = clamp(EYEDIR.y, -1.0, 1.0);

    // Gradiente arriba
    vec3 sky_up = mix(sky_top_color.rgb, sky_horizon_color.rgb,
                      clamp(pow(1.0 - v, inv_sky_curve), 0.0, 1.0));

    // Gradiente abajo
    vec3 sky_down = mix(sky_bottom_color.rgb, bottom_horizon_color.rgb,
                        clamp(pow(1.0 + v, inv_bottom_curve), 0.0, 1.0));

    // Mezcla en el horizonte
    vec3 sky = mix(sky_down, sky_up, step(0.0, v));

    // Sol — igual que el original
    if (LIGHT0_ENABLED) {
        float sa = dot(LIGHT0_DIRECTION, EYEDIR);
        float ss = cos(LIGHT0_SIZE);
        if (sa > ss) {
            sky = LIGHT0_COLOR * LIGHT0_ENERGY;
        } else if (sa > sun_angle_max) {
            float c2 = (ss - sa) / (ss - sun_angle_max);
            sky = mix(sky, LIGHT0_COLOR * LIGHT0_ENERGY,
                      clamp(pow(1.0 - c2, inv_sun_curve), 0.0, 1.0));
        }
    }
    if (LIGHT1_ENABLED) {
        float sa = dot(LIGHT1_DIRECTION, EYEDIR);
        float ss = cos(LIGHT1_SIZE);
        if (sa > ss) {
            sky = LIGHT1_COLOR * LIGHT1_ENERGY;
        } else if (sa > sun_angle_max) {
            float c2 = (ss - sa) / (ss - sun_angle_max);
            sky = mix(sky, LIGHT1_COLOR * LIGHT1_ENERGY,
                      clamp(pow(1.0 - c2, inv_sun_curve), 0.0, 1.0));
        }
    }
    if (LIGHT2_ENABLED) {
        float sa = dot(LIGHT2_DIRECTION, EYEDIR);
        float ss = cos(LIGHT2_SIZE);
        if (sa > ss) {
            sky = LIGHT2_COLOR * LIGHT2_ENERGY;
        } else if (sa > sun_angle_max) {
            float c2 = (ss - sa) / (ss - sun_angle_max);
            sky = mix(sky, LIGHT2_COLOR * LIGHT2_ENERGY,
                      clamp(pow(1.0 - c2, inv_sun_curve), 0.0, 1.0));
        }
    }
    if (LIGHT3_ENABLED) {
        float sa = dot(LIGHT3_DIRECTION, EYEDIR);
        float ss = cos(LIGHT3_SIZE);
        if (sa > ss) {
            sky = LIGHT3_COLOR * LIGHT3_ENERGY;
        } else if (sa > sun_angle_max) {
            float c2 = (ss - sa) / (ss - sun_angle_max);
            sky = mix(sky, LIGHT3_COLOR * LIGHT3_ENERGY,
                      clamp(pow(1.0 - c2, inv_sun_curve), 0.0, 1.0));
        }
    }

    COLOR = sky * exposure;
}