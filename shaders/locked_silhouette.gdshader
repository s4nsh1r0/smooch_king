shader_type canvas_item;

// Color of the dark silhouette body
uniform vec4 silhouette_color : source_color = vec4(0.12, 0.08, 0.18, 0.95);

// Inner rim/glow color around the character edges
uniform vec4 rim_color : source_color = vec4(0.6, 0.4, 0.85, 0.8);

// Edge glow thickness and sharpness
uniform float rim_thickness : hint_range(0.0, 10.0) = 2.5;
uniform float rim_intense : hint_range(0.0, 5.0) = 1.5;

// Subtle pulsating pulse speed for the edge glow
uniform float pulse_speed : hint_range(0.0, 5.0) = 2.0;

void fragment() {
    // Sample original texture
    vec4 tex_color = texture(TEXTURE, UV);
    
    // Pixel step size for sampling neighboring pixels
    vec2 size = TEXTURE_PIXEL_SIZE * rim_thickness;
    
    // Sample surrounding alpha to detect edges inside the sprite silhouette
    float alpha_up    = texture(TEXTURE, UV + vec2(0.0, -size.y)).a;
    float alpha_down  = texture(TEXTURE, UV + vec2(0.0, size.y)).a;
    float alpha_left  = texture(TEXTURE, UV + vec2(-size.x, 0.0)).a;
    float alpha_right = texture(TEXTURE, UV + vec2(size.x, 0.0)).a;
    
    // Detect edge transitions where alpha drops off
    float edge = (abs(tex_color.a - alpha_up) + 
                  abs(tex_color.a - alpha_down) + 
                  abs(tex_color.a - alpha_left) + 
                  abs(tex_color.a - alpha_right));
    
    // Pulse calculation for subtle breathing visual effect
    float pulse = (sin(TIME * pulse_speed) * 0.5 + 0.5) * 0.3 + 0.7;
    
    // Calculate final rim component constrained within original alpha
    vec4 final_rim = rim_color * edge * rim_intense * pulse;
    
    // Combine base silhouette color with rim highlight, maintaining original alpha
    vec3 final_rgb = mix(silhouette_color.rgb, final_rim.rgb, clamp(edge * rim_intense, 0.0, 1.0));
    
    COLOR = vec4(final_rgb, tex_color.a * silhouette_color.a);
}