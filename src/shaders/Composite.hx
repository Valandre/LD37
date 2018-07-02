package shaders;

class Composite extends h3d.shader.ScreenShader {
	static var SRC = {

		@ignore @param var color : Sampler2D;

		@range(-1,1) @param var global_brightness : Float; 	// -1 to 1
		@range(0,2) @param var global_contrast : Float;		// 0 to 2
		@range(0,2) @param var global_saturation: Float;    // 0 to 2

		@ignore @param var additive : Sampler2D;

		function fragment() {
			var pColor = color.get(input.uv);

			// additive
			var addColor = additive.get(input.uv);
			pColor += addColor;

			// transform
			pColor.rgb = (pColor.rgb - 0.5) * (global_contrast) + 0.5;
			pColor.rgb = pColor.rgb + global_brightness;
			var intensity = dot(pColor.rgb, vec3(0.299,0.587,0.114));
			pColor.rgb = mix(intensity.xxx, pColor.rgb, global_saturation);

			// done
			output.color = pColor;
		}
	}
}
