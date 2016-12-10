package ent;


class IA extends Entity
{
	public function new(x = 0., y = 0., z = 0., scale = 1.)	{
		super(IA, x, y, z, scale);
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
		light.params = new h3d.Vector(0.2, 0.05, 0.025);
	}

	function updateKeys() {
		var v = 0;

		//if(game.keys.pressed.xAxis < 0) v = -1;
		//if(game.keys.pressed.xAxis > 0) v = 1;

		if(v == 0) return;

		if(wall != null)
			wall.scaleX = hxd.Math.distance(x + dir.x * 0.2 - wall.x, y + dir.y * 0.2 - wall.y, z + dir.z * 0.2 - wall.z);

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


	override public function update(dt:Float) {
		super.update(dt);
		updateKeys();
		move(dt);
	}
}