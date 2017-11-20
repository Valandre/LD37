package ui;
import hxd.Key in K;
//import Sounds;

class ChooseArena extends ui.Form
{
	var selector : h3d.scene.Object;

	var ready = false;

	var mview : h3d.scene.Mesh;
	var mname : h3d.scene.Mesh;
	var mthumbs : Array<h3d.scene.Object> = [];

	var viewTex : Array<h3d.mat.Texture> = [];
	var nameTex : Array<h3d.mat.Texture> = [];
	var buttonTex : Array<Array<h3d.mat.Texture>> = [];

	var mSelect : h3d.scene.Mesh;
	var mBack : h3d.scene.Mesh;

	var selectId = 0;

	override function init() {
		super.init();

		//init scene
		var m = hxd.Res.UI.WorldSelect.Model;
		obj = game.modelCache.loadModel(m);
		var a = game.modelCache.loadAnimation(m);
		a.loop = false;
		obj.playAnimation(a);
		obj.currentAnimation.onAnimEnd = function() {
			ready = true;
			selector.visible = true;
		}

		for(m in obj.getMeshes())
			m.material.shadows = false;

		addBg();

		game.s3d.addChild(obj);
		game.s3d.camera.follow = {pos : obj.getObjectByName("CamScreen"), target : obj.getObjectByName("CamScreen.Target")};
		game.autoCameraKind = Choose;
		game.s3d.lightSystem.ambientLight.setColor(0xFFFFFF);

		for(i in 0...6)
			mthumbs.push(obj.getObjectByName("PosThumb0" + (i + 1)));

		mname = obj.getObjectByName("Name").toMesh();
		mview = obj.getObjectByName("View").toMesh();

		viewTex.push(hxd.Res.UI.WorldSelect.View01.toTexture());
		viewTex.push(hxd.Res.UI.WorldSelect.View02.toTexture());

		nameTex.push(hxd.Res.UI.WorldSelect.Name01.toTexture());
		nameTex.push(hxd.Res.UI.WorldSelect.Name02.toTexture());

		//
		mSelect = obj.getObjectByName("ButtonA").toMesh();
		mBack = obj.getObjectByName("ButtonB").toMesh();
		buttonTex = [];
		buttonTex.push([hxd.Res.UI.CharacterSelect.ButtonA01.toTexture(), hxd.Res.UI.CharacterSelect.ButtonA02.toTexture()]);
		buttonTex.push([hxd.Res.UI.CharacterSelect.ButtonB01.toTexture(), hxd.Res.UI.CharacterSelect.ButtonB02.toTexture()]);

		//
		var m = hxd.Res.UI.Selector.Model;
		selector = game.modelCache.loadModel(m);
		selector.visible = false;
		for(m in selector.getMeshes())
			m.material.shadows = false;
		game.s3d.addChild(selector);

		updateView();
		onResize();
	}

	override public function onRemove() {
		super.onRemove();
		obj.remove();
		selector.remove();
	}

	function updateView() {
		mview.material.texture = viewTex[selectId];
		mname.material.texture = nameTex[selectId];

		var th = mthumbs[selectId];
		var pos = th.getAbsPos();
		selector.x = pos.tx;
		selector.y = pos.ty;
		selector.z = pos.tz;
	}

	var time = 0.;
	override function update(dt : Float) {
		super.update(dt);

		time += dt;
		mSelect.material.texture = buttonTex[0][(time % 40) < 20 ? 1 : 0];
		mBack.material.texture = buttonTex[1][(time % 40) < 20 ? 0 : 1];

		var c = game.controllers[0];
		if(c != null) {
			c.active = true;
			if(c.pressed.B) {
				new ui.ChoosePlayers();
				remove();
			}
			if(c.pressed.A && ready) {
				remove();
				game.state.arenaId = selectId;
				game.restart();
			}

			if(c.pressed.xAxis < 0) {
				selectId--;
				if(selectId < 0) selectId = viewTex.length - 1;
				updateView();
			}

			if(c.pressed.xAxis > 0) {
				selectId++;
				if(selectId >= viewTex.length) selectId = 0;
				updateView();
			}
		}
	}
}