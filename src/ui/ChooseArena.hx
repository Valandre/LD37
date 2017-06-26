package ui;
import hxd.Key in K;
import Sounds;

class ChooseArena extends ui.Form
{
	var obj : h3d.scene.Object;
	var selector : h3d.scene.Object;

	var ready = false;

	var mview : h3d.scene.Mesh;
	var mname : h3d.scene.Mesh;
	var mthumbs : Array<h3d.scene.Object> = [];
	var pbutton : h3d.scene.Mesh;

	var viewTex : Array<h3d.mat.Texture> = [];
	var nameTex : Array<h3d.mat.Texture> = [];
	var buttonTex : Array<h3d.mat.Texture> = [];

	var selectId = 0;

	public function new(?parent) {
		super(parent);
		game.setAmbient(1);
	}

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
		}

		for(m in obj.getMeshes())
			m.material.shadows = false;

		game.s3d.addChild(obj);
		game.s3d.camera.follow = {pos : obj.getObjectByName("CamScreen"), target : obj.getObjectByName("CamScreen.Target")};
		game.autoCameraKind = Choose;
		game.s3d.lightSystem.ambientLight.setColor(0xFFFFFF);

		for(i in 0...6)
			mthumbs.push(obj.getObjectByName("PosThumb0" + (i + 1)));

		mname = obj.getObjectByName("Name").toMesh();
		mview = obj.getObjectByName("View").toMesh();
		pbutton = obj.getObjectByName("ButtonP1").toMesh();

		viewTex.push(hxd.Res.UI.WorldSelect.View01.toTexture());
		viewTex.push(hxd.Res.UI.WorldSelect.View02.toTexture());

		nameTex.push(hxd.Res.UI.WorldSelect.Name01.toTexture());
		nameTex.push(hxd.Res.UI.WorldSelect.Name02.toTexture());

		buttonTex.push(hxd.Res.UI.CharacterSelect.ButtonX01.toTexture());
		buttonTex.push(hxd.Res.UI.CharacterSelect.ButtonX02.toTexture());

		var m = hxd.Res.UI.Selector.Model;
		selector = game.modelCache.loadModel(m);
		for(m in selector.getMeshes())
			m.material.shadows = false;
		game.s3d.addChild(selector);


/*
		btBack = new NavigateButton(Texts.navigate.back, this);
		btBack.onClick = function() {
			new ui.ChoosePlayers();
			remove();
		}

		btNext = new NavigateButton(Texts.navigate.next, this);
		btNext.onClick = function() {
			remove();
			game.state.arenaId = selectId;
			game.restart();
		}*/

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
		pbutton.material.texture = buttonTex[(time % 40) < 20 ? 1 : 0];

		var c = game.controllers[0];
		if(c != null) {
			c.active = true;
			if(c.pressed.B) {
				new ui.ChoosePlayers();
				remove();
			}
			if(c.pressed.A) {
				remove();
				game.state.arenaId = selectId;
				game.restart();
			}

			if(c.pressed.yAxis < 0) {
				selectId--;
				if(selectId < 0) selectId = viewTex.length - 1;
				updateView();
			}

			if(c.pressed.yAxis > 0) {
				selectId++;
				if(selectId >= viewTex.length) selectId = 0;
				updateView();
			}
		}
	}
}