package map;
import hxd.Res;



class UIComposite extends h3d.scene.DefaultRenderer {

	var game : Game;

	@inspect @range(0, 4, 1) var colorBlurScale = 2;
	@inspect @range(0, 4, 1) var envColorScale = 3;

	@inspect public var enableAmbientOcclusion = true;

	@ignore var antiAliasing = new h3d.pass.FXAA();
	var colorBlur = new h3d.pass.Blur(2, 1, 2);
	var envColorBlur = new h3d.pass.Blur(2, 3, 1.4);
	var ambient : h3d.pass.ScreenFx<shaders.Composite>;

	public var finalTex : h3d.mat.Texture;

	public var width = 0;
	public var height = 0;

	public function new() {
		game = Game.inst;
		super();

		ambient = new h3d.pass.ScreenFx(new shaders.Composite());

		ambient.shader.hasDOF = false;
		ambient.shader.hasFOG = false;
		ambient.shader.hasBLOOM = false;

		ambient.shader.global_brightness = 0.;
		ambient.shader.global_contrast = 1.05;
		ambient.shader.global_saturation = 1.;
		ambient.shader.envColorAmount = 0.3;
	}

	override function render() {
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


	//fxaa
		resetTarget();
		//setTarget(null);
		antiAliasing.apply(finalTex);
	}
}
