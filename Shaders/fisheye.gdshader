shader_type canvas_item;

render_mode unshaded;

uniform sampler2D screen_texture :
	hint_screen_texture,
	repeat_disable,
	filter_linear;


// ============================================================
// BODYCAM LENS
// ============================================================

uniform float fisheye_strength :
	hint_range(0.0, 0.50, 0.001) = 0.16;

uniform float fisheye_zoom :
	hint_range(0.80, 1.50, 0.001) = 1.05;


// ============================================================
// CHROMATIC ABERRATION
// ============================================================

uniform float chromatic_aberration :
	hint_range(0.0, 0.02, 0.0001) = 0.0015;

uniform float chromatic_edge_strength :
	hint_range(0.0, 2.0, 0.01) = 1.0;


// ============================================================
// IMAGE PROCESSING
// ============================================================

uniform float contrast :
	hint_range(0.5, 2.0, 0.01) = 1.08;

uniform float saturation :
	hint_range(0.0, 2.0, 0.01) = 0.92;

uniform float brightness :
	hint_range(-0.2, 0.2, 0.01) = 0.0;


// ============================================================
// EXPOSURE
// ============================================================

uniform float exposure = 1.0;


// ============================================================
// SENSOR NOISE
// ============================================================

uniform float grain_strength :
	hint_range(0.0, 0.15, 0.001) = 0.025;

uniform float grain_size :
	hint_range(1.0, 8.0, 0.1) = 2.0;


// ============================================================
// VIGNETTE
// ============================================================

uniform float vignette_strength :
	hint_range(0.0, 1.0, 0.01) = 0.30;

uniform float vignette_radius :
	hint_range(0.1, 1.5, 0.01) = 0.82;

uniform float vignette_softness :
	hint_range(0.01, 1.0, 0.01) = 0.30;


// ============================================================
// SCREEN
// ============================================================

uniform float aspect_ratio = 1.7777778;


// ============================================================
// MOTION BLUR
// ============================================================

uniform float motion_blur_strength :
	hint_range(0.0, 0.10, 0.001) = 0.0;

uniform vec2 motion_blur_direction = vec2(0.0);


// ============================================================
// BODYCAM FISHEYE / BARREL DISTORTION
// ============================================================

vec2 fisheye_projection(vec2 uv)
{
	vec2 p = uv - vec2(0.5);

	// Correct for widescreen aspect ratio.
	p.x *= aspect_ratio;

	float r2 = dot(p, p);

	// Barrel distortion.
	float distortion =
		1.0 +
		fisheye_strength * r2;

	p *= distortion;

	// Zoom slightly to hide distorted edges.
	p *= fisheye_zoom;

	// Restore aspect ratio.
	p.x /= aspect_ratio;

	return p + vec2(0.5);
}


// ============================================================
// SATURATION
// ============================================================

vec3 apply_saturation(
	vec3 color,
	float amount
)
{
	float luminance = dot(
		color,
		vec3(
			0.299,
			0.587,
			0.114
		)
	);

	return mix(
		vec3(luminance),
		color,
		amount
	);
}


// ============================================================
// RANDOM NOISE
// ============================================================

float random_noise(vec2 position)
{
	return fract(
		sin(
			dot(
				position,
				vec2(
					12.9898,
					78.233
				)
			)
		)
		*
		43758.5453
	);
}


// ============================================================
// VIGNETTE
// ============================================================

float calculate_vignette(vec2 uv)
{
	vec2 p = uv - vec2(0.5);

	p.x *= aspect_ratio;

	float distance_from_center = length(p);

	float vignette = smoothstep(
		vignette_radius,
		vignette_radius + vignette_softness,
		distance_from_center
	);

	return 1.0 -
		vignette *
		vignette_strength;
}


// ============================================================
// MOTION BLUR
// 5 TOTAL SCREEN SAMPLES
// ============================================================

vec3 apply_motion_blur(
	vec2 uv,
	vec3 center_color
)
{
	if (motion_blur_strength <= 0.0001)
	{
		return center_color;
	}

	vec2 direction = motion_blur_direction;

	float direction_length = length(direction);

	if (direction_length <= 0.0001)
	{
		return center_color;
	}

	direction = normalize(direction);

	vec2 blur_offset =
		direction *
		motion_blur_strength;


	vec3 blur_color = center_color;


	blur_color += texture(
		screen_texture,
		clamp(
			uv + blur_offset * 0.25,
			vec2(0.001),
			vec2(0.999)
		)
	).rgb;


	blur_color += texture(
		screen_texture,
		clamp(
			uv - blur_offset * 0.25,
			vec2(0.001),
			vec2(0.999)
		)
	).rgb;


	blur_color += texture(
		screen_texture,
		clamp(
			uv + blur_offset * 0.50,
			vec2(0.001),
			vec2(0.999)
		)
	).rgb;


	blur_color += texture(
		screen_texture,
		clamp(
			uv - blur_offset * 0.50,
			vec2(0.001),
			vec2(0.999)
		)
	).rgb;


	return blur_color * 0.2;
}


// ============================================================
// FRAGMENT
// ============================================================

void fragment()
{
	vec2 uv = SCREEN_UV;


	// ========================================================
	// FISHEYE / BARREL DISTORTION
	// ========================================================

	vec2 distorted_uv =
		fisheye_projection(uv);


	// ========================================================
	// EDGE PROTECTION
	// ========================================================

	bool outside_screen = (
		distorted_uv.x < 0.0 ||
		distorted_uv.x > 1.0 ||
		distorted_uv.y < 0.0 ||
		distorted_uv.y > 1.0
	);

	distorted_uv = clamp(
		distorted_uv,
		vec2(0.001),
		vec2(0.999)
	);


	// ========================================================
	// BASE IMAGE
	// ========================================================

	vec3 final_color =
		texture(
			screen_texture,
			distorted_uv
		).rgb;


	// ========================================================
	// CHROMATIC ABERRATION
	// ========================================================

	vec2 direction =
		distorted_uv -
		vec2(0.5);

	float distance_from_center =
		length(direction);

	float edge_factor =
		clamp(
			distance_from_center * 2.0,
			0.0,
			1.0
		);

	edge_factor =
		edge_factor *
		edge_factor *
		chromatic_edge_strength;


	vec2 chromatic_direction =
		vec2(0.0);

	if (distance_from_center > 0.0001)
	{
		chromatic_direction =
			direction /
			distance_from_center;
	}


	float offset =
		chromatic_aberration *
		edge_factor;


	vec2 red_uv =
		clamp(
			distorted_uv +
			chromatic_direction * offset,
			vec2(0.001),
			vec2(0.999)
		);


	vec2 blue_uv =
		clamp(
			distorted_uv -
			chromatic_direction * offset,
			vec2(0.001),
			vec2(0.999)
		);


	final_color.r =
		texture(
			screen_texture,
			red_uv
		).r;


	final_color.b =
		texture(
			screen_texture,
			blue_uv
		).b;


	// ========================================================
	// MOTION BLUR
	// ========================================================

	final_color =
		apply_motion_blur(
			distorted_uv,
			final_color
		);


	// ========================================================
	// CONTRAST
	// ========================================================

	final_color =
		(
			final_color -
			vec3(0.5)
		)
		*
		contrast
		+
		vec3(0.5);


	// ========================================================
	// SATURATION
	// ========================================================

	final_color =
		apply_saturation(
			final_color,
			saturation
		);


	// ========================================================
	// BRIGHTNESS
	// ========================================================

	final_color +=
		vec3(brightness);


	// ========================================================
	// EXPOSURE
	// ========================================================

	final_color *=
		exposure;


	// ========================================================
	// SENSOR GRAIN
	// ========================================================

	vec2 grain_position =
		floor(
			SCREEN_UV *
			1000.0 /
			grain_size
		);


	float noise =
		random_noise(
			grain_position
		);

	noise =
		noise * 2.0 - 1.0;


	final_color +=
		noise *
		grain_strength;


	// ========================================================
	// VIGNETTE
	// ========================================================

	float vignette =
		calculate_vignette(uv);

	final_color *=
		vignette;


	// ========================================================
	// OUTPUT
	// ========================================================

	COLOR =
		vec4(
			clamp(
				final_color,
				vec3(0.0),
				vec3(1.0)
			),
			1.0
		);
}