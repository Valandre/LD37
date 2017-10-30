package shaders;

class CellShader extends hxsl.Shader {

	static var SRC = {
		@param var shadowColor : Vec3;

		var pixelColor : Vec4;
		var lightPixelColor : Vec3;

		function __init__fragment() {
			lightPixelColor = vec3(0, 0, 0);
		}

		function fragment() {
			var k = ((lightPixelColor.r - 0.4) * 10000).clamp(0.,1.);
			pixelColor.rgb = mix(pixelColor.rgb * shadowColor, pixelColor.rgb, k);
			//pixelColor.rgb = vec3(k, k, k);
			//pixelColor.rgb = pixelColor.rgb * float(k > 0.8);
		}
	}
}