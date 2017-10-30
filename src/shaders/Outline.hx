package shaders;

class Outline extends hxsl.Shader {

	static var SRC = {

		@:import h3d.shader.BaseMesh;

		@input var logicNormal : Vec3;

		@param var size : Float;
		@param var distance : Float;
		@param var color : Vec4;

		function __init__vertex() {
			{
				var pproj = vec4(relativePosition * global.modelView.mat3x4(), 1.) * camera.viewProj;
				relativePosition += logicNormal * size * sqrt(pproj.w / 100);
			}
		}

		function vertex() {
			projectedPosition.z += distance;
		}

		function fragment() {
			pixelColor = color;
		}

	};

}