shader_type canvas_item;

uniform vec2 viewport_size = vec2(256.0, 256.0);
uniform vec2 camera_pos = vec2(0.0, 0.0);
uniform float zoom = 1.0;
uniform float world_scale = 30.0;
uniform float grid_size = 8.0;

uniform vec4 bg_color  = vec4(0.09, 0.09, 0.09, 1.0);
uniform vec4 minor_color  = vec4(0.28, 0.28, 0.28, 1.0);
uniform vec4 major_color  = vec4(0.36, 0.36, 0.36, 1.0);
uniform vec4 x_axis_col   = vec4(1.0, 0.2, 0.2, 1.0);
uniform vec4 y_axis_col   = vec4(0.2, 1.0, 0.2, 1.0);

void fragment() {
    float spacing = world_scale * zoom;
    vec2 center = viewport_size * 0.5;
    vec2 world_pos = (FRAGCOORD.xy - center) / spacing + camera_pos;

    float dx = abs(world_pos.x - round(world_pos.x));
    float dy = abs(world_pos.y - round(world_pos.y));
    bool minor = (dx * spacing < 0.6) || (dy * spacing < 0.6);

    float rx = round(world_pos.x / grid_size) * grid_size;
    float ry = round(world_pos.y / grid_size) * grid_size;
    bool major = (abs(world_pos.x - rx) * spacing < 1.3) ||
                 (abs(world_pos.y - ry) * spacing < 1.3);

    vec4 col = bg_color;
    if (minor) {
		col = minor_color;
	};

    if (major){
		col = major_color;
	};


    if (abs(world_pos.x) * spacing < 2.0) { col = y_axis_col; }
    if (abs(world_pos.y) * spacing < 2.0) { col = x_axis_col; }

    COLOR = col;
}
