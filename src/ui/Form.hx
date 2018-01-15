package ui;
import hxd.Key in K;
//import Sounds;

class Form extends h2d.Sprite
{
	var game : Game;
	var obj : h3d.scene.Object;

	static var bg : h3d.scene.Object;

	public function new(?parent) {
		game = Game.inst;
		if(parent == null) parent = game.s2d;
		super(parent);
		game.windows.push(this);
		init();
	}

	function init() {
	}

	public function addBg() {
		if(obj == null) return;
		var root = obj.getObjectByName("Root");
		if(root == null) return;

		if(bg == null) {
			var m = hxd.Res.UI.BG01.Model;
			bg = game.modelCache.loadModel(m);
			var a = game.modelCache.loadAnimation(m);
			if(a != null) {
				a.loop = true;
				a.speed = 0.15;
				bg.playAnimation(a);
			}
			for(m in bg.getMeshes())
				m.material.shadows = false;

			bg.setScale(1.1);
			var t = 0.;
			game.event.waitUntil(function(dt) {
				t += 0.015 * dt;
				bg.z = 0.03 * Math.sin(t);
				return bg == null;
			});
		}
		obj.addChild(bg);
	}

	override public function onRemove() {
		super.onRemove();
		game.windows.remove(this);
	}

	public function onResize() {
	}

	public function update(dt : Float) {
	}
}