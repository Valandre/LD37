package ui;
//import Sounds;

class Title extends ui.Form
{
	var creditsBmp : h2d.Bitmap;
	var container: h2d.Sprite;
	var ready = false;

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

		onResize();
	}
	
	override public function onRemove() {
		super.onRemove();
		obj.remove();
		ready = false;
	}
	
	override function update(dt : Float) {
		super.update(dt);
		if(!ready) return;

		var c = game.controllers[0];
		if(c != null && (c.pressed.start || c.pressed.A)) {				
			new ui.ChoosePlayers();
			remove();
		}
	}
}