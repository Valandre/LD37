package ui;
import hxd.Key in K;
//import Sounds;

class Form extends h2d.Sprite
{
	var game : Game;

	public function new(?parent) {
		game = Game.inst;
		if(parent == null) parent = game.s2d;
		super(parent);
		game.windows.push(this);

		init();
	}

	function init() {
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