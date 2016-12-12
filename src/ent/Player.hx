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
		if((game.nbPlayers == 1 && K.isPressed(K.LEFT)) || (controller != null && controller.pressed.xAxis < 0)) v = -1;
		if((game.nbPlayers == 1 && K.isPressed(K.RIGHT)) || (controller != null && controller.pressed.xAxis > 0)) v = 1;
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
			if(game.nbPlayers == 1 && game.players.length > 0 && game.players.indexOf(this) == -1) {

				inline function setCam() {
					var pl = game.players[0];
					var v = game.customScene.views[0];
					v.id = pl.id;
					v.camera = game.initCamera(pl);
					game.s3d.camera = v.camera;
				}

				if((game.nbPlayers == 1 && K.isPressed(K.LEFT)) || (controller != null && controller.pressed.xAxis < 0)) {
					game.players.unshift(game.players.pop());
					setCam();
				}
				if((game.nbPlayers == 1 && K.isPressed(K.RIGHT)) || (controller != null && controller.pressed.xAxis > 0)) {
					game.players.push(game.players.shift());
					setCam();
				}
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