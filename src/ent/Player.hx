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
		if(b) canMove = false;

		//if(this == game.players[0]) trace(game.world.isCollide(this));
		return b;
	}

	override public function update(dt:Float) {
		if(dead) {
			var hasPlayer = false;
			for(p in game.players) if(p.kind == Player) hasPlayer = true;
			if(!hasPlayer) {
				if(K.isPressed(K.LEFT) || game.keys.pressed.xAxis < 0) game.players.unshift(game.players.pop());
				if(K.isPressed(K.RIGHT) || game.keys.pressed.xAxis > 0) game.players.push(game.players.shift());
			}
			return;
		}
		super.update(dt);
		if(canMove) {
			updateKeys();
			move(dt);
		}
	}
}