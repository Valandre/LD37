package shaders;

class CompositeUI extends h3d.shader.ScreenShader {
	static var SRC = {
		@param var color : Sampler2D;
		function fragment() {
			output.color = color.get(input.uv);
			//output.color.rgb = color.get(input.uv).aaa;
		}
	}
}
