shader_type canvas_item;

render_mode unshaded;

uniform sampler2D screen_texture :
	hint_screen_texture,
	repeat_disable,
	filter_linear;


// ============================================================
// LENS DISTORTION
// ============================================================

uniform float distortion_strength :
	hint_range(0.0, 1.0, 0.001) = 0.22;

uniform float distortion_edge :
	hint_range(0.0, 1.0, 0.001) = 0.10;

uniform float lens_zoom :
	hint_range(0.8, 1.5, 0.001) = 1.04;


// ============================================================
// CHROMATIC ABERRATION
// ============================================================

uniform float chromatic_aberration :
	hint_range(0.0, 0.02, 0.0001) = 0.0025;

uniform float chromatic_edge_strength :
	hint_range(0.0, 2.0, 0.01) = 1.0;


// ============================================================
// IMAGE PROCESSING
// ============================================================

// Sharpening strength.
uniform float sharpening :
	hint_range(0.0, 1.0, 0.01) = 0.22;


// Contrast.
uniform float contrast :
	hint_range(0.5, 2.0, 0.01) = 1.08;


// Saturation.
// Values below 1 reduce saturation.
uniform float saturation :
	hint_range(0.0, 2.0, 0.01) = 0.92;


// Small brightness adjustment.
uniform float brightness :
	hint_range(-0.2, 0.2, 0.01) = 0.0;


// ============================================================
// EXPOSURE
// ============================================================
//
// This value is controlled by the BodyCam exposure script.
//
// 1.0 = normal exposure
// < 1.0 = darker
// > 1.0 = brighter
//

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
	hint_range(0.0, 1.0, 0.01) = 0.45;

uniform float vignette_radius :
	hint_range(0.1, 1.5, 0.01) = 0.82;

uniform float vignette_softness :
	hint_range(0.01, 1.0, 0.01) = 0.30;


// ============================================================
// SCREEN
// ============================================================

uniform float aspect_ratio = 1.7777778;


// ============================================================
// FISHEYE
// ============================================================

vec2 fisheye(vec2 uv)
{
	vec2 p = uv - vec2(0.5);

	p.x *= aspect_ratio;

	float r = length(p);

	float r2 = r * r;
	float r4 = r2 * r2;

	float distortion =
		1.0
		+
		distortion_strength * r2
		+
		distortion_edge * r4;

	p /= distortion;

	p.x /= aspect_ratio;

	p *= lens_zoom;

	return p + vec2(0.5);
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
// SATURATION
// ============================================================

vec3 apply_saturation(
	vec3 color,
	float amount
)
{
	float luminance =
		dot(
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
// SHARPENING
// ============================================================

vec3 apply_sharpen(
	vec2 uv,
	vec3 center_color
)
{
	vec2 pixel = vec2(
		0.0012,
		0.0012
	);


	vec3 north = texture(
		screen_texture,
		uv + vec2(0.0, pixel.y)
	).rgb;


	vec3 south = texture(
		screen_texture,
		uv - vec2(0.0, pixel.y)
	).rgb;


	vec3 east = texture(
		screen_texture,
		uv + vec2(pixel.x, 0.0)
	).rgb;


	vec3 west = texture(
		screen_texture,
		uv - vec2(pixel.x, 0.0)
	).rgb;


	vec3 surrounding =
		(
			north +
			south +
			east +
			west
		)
		*
		0.25;


	vec3 sharpened =
		center_color
		+
		(
			center_color -
			surrounding
		)
		*
		sharpening;


	return sharpened;
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
// FRAGMENT
// ============================================================

void fragment()
{
	vec2 uv = SCREEN_UV;


	// --------------------------------------------------------
	// Fisheye
	// --------------------------------------------------------

	vec2 distorted_uv =
		fisheye(uv);


	vec3 final_color =
		vec3(0.0);


	// --------------------------------------------------------
	// Screen bounds
	// --------------------------------------------------------

	if (
		distorted_uv.x >= 0.0 &&
		distorted_uv.x <= 1.0 &&
		distorted_uv.y >= 0.0 &&
		distorted_uv.y <= 1.0
	)
	{
		// ====================================================
		// CHROMATIC ABERRATION
		// ====================================================

		vec2 direction =
			distorted_uv -
			vec2(0.5);


		float distance_from_center =
			length(direction);


		float edge_factor =
			pow(
				clamp(
					distance_from_center * 2.0,
					0.0,
					1.0
				),
				2.0
			);


		edge_factor *=
			chromatic_edge_strength;


		vec2 chromatic_direction =
			vec2(0.0);


		if (distance_from_center > 0.0001)
		{
			chromatic_direction =
				normalize(direction);
		}


		float offset =
			chromatic_aberration *
			edge_factor;


		vec2 red_uv =
			distorted_uv
			+
			chromatic_direction
			*
			offset;


		vec2 green_uv =
			distorted_uv;


		vec2 blue_uv =
			distorted_uv
			-
			chromatic_direction
			*
			offset;


		red_uv = clamp(
			red_uv,
			vec2(0.0),
			vec2(1.0)
		);


		green_uv = clamp(
			green_uv,
			vec2(0.0),
			vec2(1.0)
		);


		blue_uv = clamp(
			blue_uv,
			vec2(0.0),
			vec2(1.0)
		);


		float red =
			texture(
				screen_texture,
				red_uv
			).r;


		float green =
			texture(
				screen_texture,
				green_uv
			).g;


		float blue =
			texture(
				screen_texture,
				blue_uv
			).b;


		final_color =
			vec3(
				red,
				green,
				blue
			);


		// ====================================================
		// SHARPENING
		// ====================================================

		final_color =
			apply_sharpen(
				distorted_uv,
				final_color
			);


		// ====================================================
		// CONTRAST
		// ====================================================

		final_color =
			(
				final_color -
				vec3(0.5)
			)
			*
			contrast
			+
			vec3(0.5);


		// ====================================================
		// SATURATION
		// ====================================================

		final_color =
			apply_saturation(
				final_color,
				saturation
			);


		// ====================================================
		// BRIGHTNESS
		// ====================================================

		final_color +=
			vec3(brightness);


		// ====================================================
		// EXPOSURE
		// ====================================================
		//
		// This is the value controlled by the
		// bodycam_exposure.gd script.
		//

		final_color *= exposure;
	}


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
	// CLAMP
	// ========================================================

	final_color =
		clamp(
			final_color,
			vec3(0.0),
			vec3(1.0)
		);


	// ========================================================
	// OUTPUT
	// ========================================================

	COLOR = vec4(
		final_color,
		1.0
	);
}