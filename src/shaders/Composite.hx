package shaders;

class Composite extends h3d.shader.ScreenShader {
	static var SRC = {
		@const var hasDOF : Bool;
		@const var hasFOG : Bool;
		@const var hasBLOOM : Bool;

		@ignore @param var camera : {
			var pos : Vec3;
			var zNear: Float;
			var zFar : Float;
		}

		@ignore @param var color : Sampler2D;
		@ignore @param var colorBlur : Sampler2D;
		@ignore @param var depth : Sampler2D;
		@param var envColor : Sampler2D;
		@range(0,0.5) @param var envColorAmount : Float;

		@range(0,1) @param var dofStart : Float;
		@range(0,5) @param var dofPower : Float;
		@range(0,3) @param var dofAmount: Float;

		@range(0, 5) @param var fogPower : Float;
		@range(0, 5) @param var fogAmount : Float;
		@range(0, 0.1) @param var fogDensity : Float;
		@range(0, 3) @param var fogStart : Float;
		@ignore @param var fogScale : Float;
		@param var fogColor: Vec3;

		@param var bloomPower : Float;
		@param var bloomAmount : Float;

		@range(-1,1) @param var global_brightness : Float; 	// -1 to 1
		@range(0,2) @param var global_contrast : Float;		// 0 to 2
		@range(0,2) @param var global_saturation: Float;    // 0 to 2

		@ignore @param var cameraInverseViewProj : Mat4;
		@ignore @param var time : Float;

		@ignore @param var additive : Sampler2D;

		@global var shadow : {
			map : Sampler2D,
			proj : Mat3x4,
			color : Vec3,
			power : Float,
			bias : Float,
		};

		function linearize(d : Float) : Float {
			var n = camera.zNear;
			var f = camera.zFar;
			return (2 * n * f) / (f + n - (2 * d - 1) * (f - n));
		}

		function getPosition( uv : Vec2, depth : Float ) : Vec3 {
			var uv2 = (uv - 0.5) * vec2(2, -2);
			var temp = vec4(uv2, depth, 1) * cameraInverseViewProj;
			var originWS = temp.xyz / temp.w;
			return originWS;
		}

		function fragment() {
			var pColor = color.get(input.uv);
			var bColor = colorBlur.get(input.uv);
			var pDepth = unpack(depth.get(input.uv));
			var cDepth = linearize(pDepth);
			var pos = getPosition(input.uv, pDepth);
			var camDir = camera.pos - pos;
			var camDist = camDir;
			camDir = camDir.normalize();
			var d = (camDist.length() - camera.zNear) / (camera.zFar - camera.zNear);

			var fog = 1 - exp( (-(camDist * vec3(1,1,1.2)).length() * fogDensity + fogStart * fogScale).min(0.) );
			var fog = (fogAmount * fog.pow(fogPower)).saturate();

			// shadows
			var shadowPos = pos * shadow.proj * vec3(0.5, -0.5, 1) + vec3(0.5, 0.5, 0);
			var shadowDepth = unpack(shadow.map.get(shadowPos.xy));
			var zMax = shadowPos.z.saturate();
			var delta = (shadowDepth + shadow.bias).min(zMax) - zMax;
			var shade = (exp( shadow.power * delta  )).saturate();
			pColor.rgb = mix(pColor.rgb * shadow.color.rgb, pColor.rgb, shade);

			// dof
			if(hasDOF) {
				var k = ((d - dofStart).max(0.).pow(dofPower) * dofAmount).min(1.);
				pColor = mix(pColor, bColor, k);
			}

			// additive
			var addColor = additive.get(input.uv);
			pColor += addColor;

			// env
			var eColor = envColor.get(input.uv + vec2(0,0.05));
			pColor += eColor * envColorAmount * abs(eColor - pColor) * (1 - pColor);

			// bloom
			if(hasBLOOM) {
				var lum = log( (bColor.rgb.dot(vec3(0.2126, 0.7152, 0.0722))).pow(bloomPower) + 1. ) * 0.5;
				pColor.rgb += (exp(lum * 2.) - 1.) * bloomAmount.xxx;
			}

			// fog
			if(hasFOG) {
				var warF = 0.;
				pColor.rgb = mix(pColor.rgb, fogColor, fog * (1 - warF) );
			}

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
