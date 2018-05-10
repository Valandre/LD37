package ent;
import hxd.Key in K;

class Player extends Unit
{
	public function new(props, dir, scale = 1., ?id)	{
		game = Game.inst;
		this.dir = dir;
		var size = game.size >> 1;
		super(Player, props, -size * 0.65 * dir.x, -size * 0.65 * dir.y, -size, scale, id);
	}

	function updateKeys() {
		power.progress = 1;
		if(power.isReady)
			if((game.state.players.length == 1 && K.isPressed(K.SPACE)) || (controller != null && controller.pressed.A ))
				power.start();

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

	function getNonIAPlayersCount() {
		var count = 0;
		for(p in game.state.players)
			if(p.kind == Player) count++;
		return count;
	}

	var forceNext = false;
	override function destroy() {
		super.destroy();
		
		game.event.wait(5, function() {
			if(currFollow != null) return;
			forceNext = true;
			//setCam();
		});
	}

	inline function setCam() {
		var pl = game.players[0];
		var v = game.customScene.views[0];
		v.id = pl.id;
		v.camera = game.initCamera(pl);
		game.s3d.camera = v.camera;
		currFollow = pl;
	}

	var currFollow = null;
	override public function update(dt:Float) {
		if(dead) {
			var nb = getNonIAPlayersCount();
			if(nb == 1 && game.players.length > 0 && game.players.indexOf(this) == -1) {
				if(forceNext || game.players.length == 1 || (currFollow != null && currFollow.dead && game.players.indexOf(currFollow) == -1)) {
					if(currFollow != game.players[0])
						setCam();
					forceNext = false;
					return;
				}
				if(K.isPressed(K.LEFT) || (controller != null && controller.pressed.xAxis < 0)) {
					game.players.unshift(game.players.pop());
					setCam();
				}
				if(K.isPressed(K.RIGHT) || (controller != null && controller.pressed.xAxis > 0)) {
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