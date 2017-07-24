package ent;
import hxd.Key in K;

class Player extends Fairy
{
	public function new(props, dir, scale = 1., ?id)	{
		game = Game.inst;
		this.dir = dir;
		var size = game.size >> 1;
		super(Player, props, -size * 0.65 * dir.x, -size * 0.65 * dir.y, -size, scale, id);
		this.x += Std.random(5) - 2;
		this.y += Std.random(5) - 2;
		this.z += w * 0.5;
	}

	function updateKeys() {
		if(currBonus != null)
			if((game.state.players.length == 1 && K.isPressed(K.SPACE)) || (controller != null && controller.pressed.A )) {
				activeBonus = currBonus;
				currBonus = null;
			}

		var v = 0;
		if((game.state.players.length == 1 && K.isPressed(K.LEFT)) || (controller != null && controller.pressed.xAxis < 0)) v = -1;
		if((game.state.players.length == 1 && K.isPressed(K.RIGHT)) || (controller != null && controller.pressed.xAxis > 0)) v = 1;
		if(v == 0) return;
		changeDir(v);
	}

	override function hitTest() {
		var b = super.hitTest();
		if(b) canMove = false;
		return b;
	}

	var currFollow = null;
	override public function update(dt:Float) {
		if(dead) {
			if(game.state.players.length == 1 && game.players.length > 0 && game.players.indexOf(this) == -1) {
				inline function setCam() {
					var pl = game.players[0];
					var v = game.customScene.views[0];
					v.id = pl.id;
					v.camera = game.initCamera(pl);
					game.s3d.camera = v.camera;
					currFollow = pl;
				}

				if(currFollow != null && currFollow.dead && game.players.indexOf(currFollow) == -1) {
					game.players.unshift(game.players.pop());
					setCam();
					return;
				}
				if((game.state.players.length == 1 && K.isPressed(K.LEFT)) || (controller != null && controller.pressed.xAxis < 0)) {
					game.players.unshift(game.players.pop());
					setCam();
				}
				if((game.state.players.length == 1 && K.isPressed(K.RIGHT)) || (controller != null && controller.pressed.xAxis > 0)) {
					game.players.push(game.players.shift());
					setCam();
				}
			}
			return;
		}
		if(canMove) {
			updateKeys();
			move(dt);
		}
		super.update(dt);
	}
}