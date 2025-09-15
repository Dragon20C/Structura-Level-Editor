shader_type canvas_item;

uniform vec2 viewport_size = vec2(1.0);
uniform vec2 camera_pos = vec2(0.0);
uniform float zoom = 1.0;
uniform float world_scale = 30.0;
uniform float grid_size = 8.0;

const vec4 grid_color  = vec4(0.4, 0.4, 0.4, 1.0);
const vec4 bg_color    = vec4(0.1, 0.1, 0.1, 1.0);
const vec4 x_axis_col  = vec4(1, 0, 0, 1);
const vec4 y_axis_col  = vec4(0, 1, 0, 1);

void fragment() {
    float spacing = world_scale * zoom;
    vec2 center = viewport_size * 0.5;
    vec2 pos = FRAGCOORD.xy - center;
    vec2 world_pixel_offset = pos + camera_pos * spacing;

    vec2 modpos = mod(world_pixel_offset, spacing * grid_size);
    bool line = (modpos.x < 1.0 || modpos.y < 1.0);
    vec4 color = line ? grid_color : bg_color;

    vec2 origin_pix = -camera_pos * spacing + center;
    origin_pix = floor(origin_pix) + 0.5; // Snap to nearest pixel center

    float half_thickness = 1.0;
    if (abs(FRAGCOORD.x - origin_pix.x) <= half_thickness) {
        color = y_axis_col;
    }
    if (abs(FRAGCOORD.y - origin_pix.y) <= half_thickness) {
        color = x_axis_col;
    }

    COLOR = color;
}
