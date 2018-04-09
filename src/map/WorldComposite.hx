package map;
import hxd.Res;

class SAO implements hxd.inspect.Group {

	@inspect @range(0, 4, 1)
	public var scale = 2;
	public var pass = new h3d.pass.ScalableAO();
	public var blur = new h3d.pass.Blur(2, 3, 2);
	public function new() {
	}
}

class ToonAmbientShader extends hxsl.Shader {

	static var SRC = {
		@param var shadowColor : Vec3;

		var pixelColor : Vec4;
		var lightPixelColor : Vec3;

		function __init__fragment() {
			lightPixelColor = vec3(0,0,0);
		}

		function fragment() {
			var k = ((lightPixelColor.r - 0.4) * 10000).clamp(0.,1.);
			pixelColor.rgb = mix(pixelColor.rgb * shadowColor, pixelColor.rgb, k);
		}
	}
}

class WorldComposite extends h3d.scene.DefaultRenderer {

	var game : Game;

	@inspect @range(0, 4, 1) var colorBlurScale = 2;
	@inspect @range(0, 4, 1) var envColorScale = 3;

	@inspect public var enableAmbientOcclusion = true;

	var sao = new SAO();
	@ignore var antiAliasing = new h3d.pass.FXAA();
	var colorBlur = new h3d.pass.Blur(2, 1, 2);
	var envColorBlur = new h3d.pass.Blur(2, 3, 1.4);
	var ambient : h3d.pass.ScreenFx<shaders.Composite>;
	var uiAmbient : h3d.pass.ScreenFx<shaders.CompositeUI>;

	public var finalTex : h3d.mat.Texture;

	public var width = 0;
	public var height = 0;

	public function new() {
		game = Game.inst;
		super();

		ambient = new h3d.pass.ScreenFx(new shaders.Composite());

		ambient.shader.hasDOF = true;
		ambient.shader.hasFOG = true;
		ambient.shader.hasBLOOM = true;

		ambient.shader.global_brightness = 0.;
		ambient.shader.global_contrast = 1.05;
		ambient.shader.global_saturation = 1.;
		ambient.shader.bloomPower = 2;
		ambient.shader.bloomAmount = 0.3;
		ambient.shader.fogPower = 3.7;
		ambient.shader.fogAmount = 1.4;
		ambient.shader.dofStart = 0.1;
		ambient.shader.dofPower = 2;
		ambient.shader.dofAmount = 0.8;
		ambient.shader.envColorAmount = 0.3;
		ambient.shader.fogColor.setColor(0x8EB0C3);

		sao.pass.shader.sampleRadius = 1;
		sao.pass.shader.intensity = 1;
		sao.pass.shader.bias = 0.05;

		uiAmbient = new h3d.pass.ScreenFx(new shaders.CompositeUI());

/*

		var light = new h3d.scene.DirLight(new h3d.Vector(-0.3, -0.2, -0.4), game.s3d);
		light.enableSpecular = true;
		light.color.setColor(0x717678);
		game.s3d.lightSystem.ambientLight.setColor(0xB1BECE);
		game.s3d.lightSystem.perPixelLighting = true;
		game.s3d.lightSystem.shadowLight = light;
		*/

/*
		var shadow = Std.instance(getPass("shadow"), h3d.pass.ShadowMap);
		shadow.size = 1024;
		shadow.power = 30;
		shadow.blur.passes = 2;
		shadow.bias = 0;
		shadow.color.setColor(0x556596);
		shadow.calcShadowBounds = function(cam) {
			cam.orthoBounds = h3d.col.Bounds.fromValues(-100, -100, -100,  200, 200, 200);
		}*/
	}

	override function render() {

		switch(game.s3d.name) {
			case "uiAlpha":
				clear(0);
				uiRender();
			default:
				defaultRender();
		}
	}

	function uiRender() {
		super.render();

		/*
	// ambient
		uiAmbient.shader.color = colorTex;
		finalTex = allocTarget("final", 0, true);
		setTarget(finalTex);
		uiAmbient.setGlobals(ctx);
		uiAmbient.render();

	//fxaa
		resetTarget();
		antiAliasing.apply(finalTex);
		*/
	}


	function defaultRender() {
		shadow.draw(get("shadow"));

		var colorTex, depthTex;
		depth.draw(get("depth"));
		normal.draw(get("normal"));
		colorTex = allocTarget("color");
		depthTex = ctx.textures.getNamed("depthMap");

	//color
		setTarget(colorTex);
		clear(0, 1);

		var envColor = allocTarget("envColor", envColorScale, false);
		h3d.pass.Copy.run(colorTex, envColor);
		envColorBlur.apply(envColor, allocTarget("envColorBlur", envColorScale, false));
		setTarget(colorTex);

		draw("default");
		draw("outline");
		def.draw(getSort("alpha"));

		var addTex = allocTarget("addColor");
		setTarget(addTex);
		clear(0);
		draw("additive");

	// blur
		setTarget(colorTex);
		draw("env");

		var colorBlurTex = allocTarget("colorBlur", colorBlurScale, false);
		h3d.pass.Copy.run(colorTex, colorBlurTex);
		h3d.pass.Copy.run(addTex, colorBlurTex, Add);
		colorBlur.apply(colorBlurTex, allocTarget("colorBlurTmp", colorBlurScale, false));


	// ambient
		ambient.shader.color = colorTex;
		ambient.shader.envColor = envColor;
		ambient.shader.colorBlur = colorBlurTex;
		ambient.shader.additive = addTex;
		ambient.shader.depth = depthTex;
		var dist = game.s3d.camera.pos.sub(game.s3d.camera.target).length();
		ambient.shader.fogScale = dist / 111;
		ambient.shader.cameraInverseViewProj = game.s3d.camera.getInverseViewProj();
		ambient.shader.camera = ctx.camera;
		ambient.shader.time += ctx.elapsedTime;

		finalTex = allocTarget("final", 0, true);
		setTarget(finalTex);
		ambient.setGlobals(ctx);
		ambient.render();


		//h3d.pass.Copy.run(finalTex, null);
		resetTarget();
		//setTarget(null);
		antiAliasing.apply(finalTex);
	}
}
