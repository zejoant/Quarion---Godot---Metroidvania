shader_type canvas_item;

uniform sampler2D palette : source_color;
uniform bool use_palette_alpha = false;
uniform int palette_choice = 0;

void fragment() { //loops through each pixel in the image
	vec4 original_color = texture(TEXTURE, UV); //color of the pixal at the position of UV in the original texture (0-1)
	//ivec3 colori = ivec3(round(original_color.rgb * 255.0)); //original_color in rgb format (0-255)
	
	ivec2 color_count = textureSize(palette, 0); //width of palette image, which also is the amount of colors for each palette, range is 0-1
	
	float idx = -1.0; //x position in the palette row (start value is oob since it have not found any of the original colors in the first palette row)
	for (int i = 0; i < color_count.x; i++) { //loops through each color in the first palette row
		vec3 color2 = texture(palette, vec2(float(i) / float(color_count.x - 1), 0)).rgb; //texture read of palette color, stores rgb (0-1)
		//ivec3 colori2 = ivec3(round(color2 * 255.0)); //converts color2's rgb values to 0-255
		
		if (original_color.rgb == color2) { //checks if it can find and of the original textures colors in the palette
			idx = float(i);
			break;
		}
	}
	
	if (idx >= 0.0) { //if it has found any of the original colors in the first palette row
		vec2 uv; //position of the color in palettes png
		uv.x = idx / float(color_count.x - 1); //x pos of color in palette row (0-1)
		uv.y = float(palette_choice)/float(color_count.y-1); //y pos of palette row (0-1)
		//uv.y = (mod(TIME * fps, max(float(color_count.y - 1 - int(skip_first_row)), 1.0)) + float(skip_first_row))  / float(color_count.y - 1);
		
		vec4 palette_color = texture(palette, uv); //the palette color corresponding to the original texture palette
		COLOR = vec4(palette_color.rgb, mix(original_color.a, palette_color.a, float(use_palette_alpha))); //sets the current pixel to the new color
	} else { //the obj remains as the original color
		COLOR = original_color;
	}
}