package ent;
import hxd.Key in K;


class Player extends Entity
{
	var w = 1;
	public function new(x = 0., y = 0., z = 0., scale = 1.)	{
		super(Player, x, y, z, scale);
		this.z += w * 0.5;
		createWall();
	}

	override function init() {
		super.init();

		var c = new h3d.prim.Cube(w, w, w);
		c.unindex();
		c.addNormals();
		c.addUVs();
		c.translate( -w * 0.5, -w * 0.5, -w * 0.5);

		obj = new h3d.scene.Mesh(c, game.s3d);
		var m = obj.toMesh();
		m.material.mainPass.enableLights = true;
		m.material.receiveShadows = true;
		m.material.texture = h2d.Tile.fromColor(0xFF00FF).getTexture();

		obj.addChild(light);
		light.params = new h3d.Vector(0.5, 0.2, 0.1);
	}

	function updateKeys() {
		var v = 0;
		if(K.isPressed(K.LEFT)) v = -1;
		if(K.isPressed(K.RIGHT)) v = 1;
		if(v == 0) return;

		var n = game.worldNormal;
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
	}

	function move(dt : Float) {
		speed = Math.min(speedRef, speed + 0.01 * dt);
		x += dir.x * speed * dt;
		y += dir.y * speed * dt;
		z += dir.z * speed * dt;

		if(checkFaceHit()) faceRotate();
	}

	function checkFaceHit() {
		if(game.world.inBounds(x, y, z)) return false;
		do {
			x -= dir.x * speed * 0.01;
			y -= dir.y * speed * 0.01;
			z -= dir.z * speed * 0.01;
		}
		while(!game.world.inBounds(x, y, z));
		return true;
	}

	function faceRotate() {
		var tmp = dir.clone();
		dir = game.worldNormal;
		tmp.scale( -1);
		game.worldNormal = tmp;
		speed = speedRef * 0.5;
		createWall();
	}

	override public function update(dt:Float) {
		super.update(dt);
		updateKeys();
		move(dt);
	}
}