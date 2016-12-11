package ent;
import hxd.Key in K;


class Player extends Entity
{
	public function new(dir, scale = 1.)	{
		game = Game.inst;
		this.dir = dir;
		var size = game.size >> 1;
		super(Player, -size * 0.65 * dir.x, -size * 0.65 * dir.y, -size, scale);
		this.z += w * 0.5;

		createWall();
	}

	function updateKeys() {
		var v = 0;
		if(K.isPressed(K.LEFT) || game.keys.pressed.xAxis < 0) v = -1;
		if(K.isPressed(K.RIGHT) || game.keys.pressed.xAxis > 0) v = 1;
		if(v == 0) return;
		changeDir(v);
	}

	override function hitTest() {
		var b = super.hitTest();
		canMove = !b;
		return b;
	}

	override public function update(dt:Float) {
		if(dead) return;
		super.update(dt);
		if(canMove) {
			updateKeys();
			move(dt);
		}
	}
}