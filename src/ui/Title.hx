package ui;
//import Sounds;

class Title extends ui.Form
{
	var creditsBmp : h2d.Bitmap;
	var container: h2d.Object;
	var ready = false;

	var mStart : h3d.scene.Mesh;

	public function new(?parent) {
		super(parent);
		//game.setAmbient(0);
		//game.autoCameraKind = Menu;
	}

	override function init() {
		super.init();
		
		//init scene
		var m = hxd.Res.UI.Title.Model;
		obj = game.modelCache.loadModel(m);
		var a = game.modelCache.loadAnimation(m);
		if(a != null) {
			a.loop = false;
			obj.playAnimation(a);
			obj.currentAnimation.onAnimEnd = function() {
				ready = true;
			}
		}
		else ready = true;

		addBg();

		game.s3d.addChild(obj);
		game.s3d.camera.follow = {pos : obj.getObjectByName("CamScreen"), target : obj.getObjectByName("CamScreen.Target")};
		game.autoCameraKind = Choose;
		
		mStart = obj.getObjectByName("TxtStart").toMesh();

		onResize();
	}
	
	override public function onRemove() {
		super.onRemove();
		obj.remove();
		ready = false;
	}
	
	var time = 0.;
	override function update(dt : Float) {
		super.update(dt);
		if(!ready) return;

		time += dt;
		mStart.visible = (time % 40) < 30;

		var c = game.controllers[0];
		if(c != null && (c.pressed.start || c.pressed.A)) {				
			new ui.ChoosePlayers();
			remove();
		}
	}
}