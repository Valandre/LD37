package map;
import hxd.Res;

class WorldComposite extends h3d.scene.DefaultRenderer {

	var game : Game;
	@ignore var antiAliasing = new h3d.pass.FXAA();
	var ambient : h3d.pass.ScreenFx<shaders.Composite>;
	var uiAmbient : h3d.pass.ScreenFx<shaders.Composite>;

	public var finalTex : h3d.mat.Texture;

	public var width = 0;
	public var height = 0;

	public function new() {
		game = Game.inst;
		super();

		ambient = new h3d.pass.ScreenFx(new shaders.Composite());

		ambient.shader.global_brightness = 0.;
		ambient.shader.global_contrast = 1.05;
		ambient.shader.global_saturation = 1.;

		uiAmbient = new h3d.pass.ScreenFx(new shaders.Composite());
	}

	override function render() {

		switch(game.s3d.name) {
			case "uiAlpha":
				clear(0);
				super.render();
			case "playerView":
				playerView();
			default:
				defaultMenu();
		}
	}
	
	function defaultMenu() {
		shadow.draw(get("shadow"));

		var colorTex;
		depth.draw(get("depth"));
		normal.draw(get("normal"));
		colorTex = allocTarget("color");

	//color
		setTarget(colorTex);
		clear(0, 1);

		draw("default");
		draw("outline");
		def.draw(getSort("alpha"));

		var addTex = allocTarget("addColor");
		setTarget(addTex);
		clear(0);
		draw("additive");

	// ambient
		ambient.shader.color = colorTex;
		ambient.shader.additive = addTex;

		finalTex = allocTarget("final", 0, true);
		setTarget(finalTex);
		ambient.setGlobals(ctx);
		ambient.render();

		h3d.pass.Copy.run(finalTex, null);
	}

	function playerView() {
		shadow.draw(get("shadow"));

		var colorTex;
		depth.draw(get("depth"));
		normal.draw(get("normal"));
		colorTex = allocTarget("color");

	//color
		setTarget(colorTex);
		clear(0, 1);

		draw("default");
		draw("outline");
		def.draw(getSort("alpha"));

		var addTex = allocTarget("addColor");
		setTarget(addTex);
		clear(0);
		draw("additive");

	// ambient
		ambient.shader.color = colorTex;
		ambient.shader.additive = addTex;

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
