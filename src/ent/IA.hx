package ent;


class IA extends Entity
{
	var sensor : h3d.col.Ray;
	var dray = 5;
	var pt = new h3d.col.Point();

	public function new(dir, scale = 1.)	{
		game = Game.inst;
		this.dir = dir;
		var size = game.size >> 1;
		super(IA, -size * 0.65 * dir.x, -size * 0.65 * dir.y, -size, scale);
		this.z += w * 0.5;

		createWall();
		sensor = h3d.col.Ray.fromValues(x, y, z, 0, 0, 0);
	}

	function updateKeys() {
		var v = 0;
		if(Math.random() < 0.01)
			v = Math.random() < 0.5 ? -1 : 1;
		if(v == 0) return;
		changeDir(v);
	}

	function checkSensors() {
		sensor.px = x; sensor.py = y; sensor.pz = z;
		sensor.lx = dray * dir.x; sensor.ly = dray * dir.y; sensor.lz = dray * dir.z;

		var col = sensorCollide();
		if(col && Math.random() < 0.05) {
			var d = setDir(dir, -1);
			sensor.lx = dray * d.x; sensor.ly = dray * d.y; sensor.lz = dray * d.z;
			var lcol = sensorCollide();

			var d = setDir(dir, 1);
			sensor.lx = dray * d.x; sensor.ly = dray * d.y; sensor.lz = dray * d.z;
			var rcol = sensorCollide();

			if(lcol && rcol) changeDir(Math.random() < 0.5 ? -1 : 1);
			if(lcol) changeDir(1);
			if(rcol) changeDir( -1);
			return true;
		}
		return false;
	}

	function sensorCollide() {
		var n = worldNormal;
		for(w in game.world.walls) {
			if(w.w == wall) continue;
			if(w.w == lastwall) continue;
			if(w.n.x != n.x || w.n.y != n.y || w.n.z != n.z) continue;
			if(w.w.getBounds().rayIntersection(sensor, pt) != null) {
				var n = new h3d.col.Point(pt.x - sensor.px, pt.y - sensor.py, pt.z - sensor.pz);
				if(hxd.Math.distanceSq(n.x, n.y, n.z) > dray * dray) continue;
				n.normalize();
				var v = sensor.getDir();
				v.normalize();
				if(v.dot(pt) >= 0)
					return true;
			}
		}
		return false;
	}


	override public function update(dt:Float) {
		super.update(dt);
		updateKeys();

		if(!checkSensors())
			move(dt);
	}
}