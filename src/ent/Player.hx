package ent;


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
		if(game.keys.pressed.xAxis < 0) v = -1;
		if(game.keys.pressed.xAxis > 0) v = 1;
		if(v == 0) return;

		if(wall != null)
			wall.scaleX = hxd.Math.distance(x + dir.x * wallSize * 0.5 - wall.x, y + dir.y * wallSize * 0.5 - wall.y, z + dir.z * wallSize * 0.5 - wall.z);

		var n = worldNormal;
		if(n.z != 0) {
			var tmp = dir.x;
			dir.x = dir.y * v * -n.z;
			dir.y = -tmp * v * -n.z;
		}
		else if(n.x != 0) {
			var tmp = dir.y;
			dir.y = dir.z * v * -n.x;
			dir.z = -tmp * v * -n.x;
		}
		else if(n.y != 0) {
			var tmp = dir.z;
			dir.z = dir.x * v * -n.y;
			dir.x = -tmp * v * -n.y;
		}

		createWall();
		meshRotate(obj);
	}

	override function hitTest() {
		var b = super.hitTest();
		if(b) game.event.wait(0.5,  game.restart);
		canMove = !b;
		return b;
	}

	override public function update(dt:Float) {
		super.update(dt);
		if(canMove) {
			updateKeys();
			move(dt);
		}
	}
}