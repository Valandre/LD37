package ent;


class IA extends Entity
{
	var sensor : h3d.col.Ray;
	var dray = 5;
	var pt = new h3d.col.Point();
	var time = 0.;

	public function new(dir, scale = 1.)	{
		game = Game.inst;
		this.dir = dir;
		var size = game.size >> 1;
		super(IA, -size * 0.65 * dir.x, -size * 0.65 * dir.y, -size, scale);
		this.z += w * 0.5;

		sensor = h3d.col.Ray.fromValues(x, y, z, 0, 0, 0);
	}

	function updateKeys() {
		if(Math.random() < 0.01)
			checkSensors(false);
	}

	var g : h3d.scene.Graphics;
	function checkSensors(testFront = true ) {
/*
		if(g == null)
			g = new h3d.scene.Graphics(game.s3d);
		g.clear();
*/

		var col = true;
		sensor.px = x; sensor.py = y; sensor.pz = z;

		if(testFront) {
			sensor.lx = dray * dir.x; sensor.ly = dray * dir.y; sensor.lz = dray * dir.z;
			col = sensorCollide(false);
/*
			if(this == game.players[0]) {
				g.lineStyle(3, col ? 0xFF0000 : 0x00FF00);
				g.moveTo(sensor.px, sensor.py,sensor.pz);
				g.lineTo(sensor.px + sensor.lx, sensor.py + sensor.ly, sensor.pz + sensor.lz);
				g.lineStyle();
			}*/
		}

		if(col) {
			var d = setDir(dir, -1);
			sensor.lx = dray * d.x; sensor.ly = dray * d.y; sensor.lz = dray * d.z;
			var lcol = sensorCollide();
/*
			if(this == game.players[0]) {
				g.lineStyle(3, lcol ? 0xFF0000 : 0x00FF00);
				g.moveTo(sensor.px, sensor.py,sensor.pz);
				g.lineTo(sensor.px + sensor.lx, sensor.py + sensor.ly, sensor.pz + sensor.lz);
				g.lineStyle();
			}*/

			var d = setDir(dir, 1);
			sensor.lx = dray * d.x; sensor.ly = dray * d.y; sensor.lz = dray * d.z;
			var rcol = sensorCollide();
/*
			if(this == game.players[0]) {
				g.lineStyle(3, rcol ? 0xFF0000 : 0x00FF00);
				g.moveTo(sensor.px, sensor.py,sensor.pz);
				g.lineTo(sensor.px + sensor.lx, sensor.py + sensor.ly, sensor.pz + sensor.lz);
				g.lineStyle();
			}*/

			//if(this == game.players[0])	trace(lcol, rcol, worldNormal, dir, !lcol ? setDir(dir, -1) : null, !rcol ? setDir(dir, 1) : null);

			if(lcol && rcol) return false;
			if(!lcol && !rcol) changeDir(Math.random() < 0.5 ? -1 : 1);
			else if(lcol) changeDir(1);
			else if(rcol) changeDir( -1);
			return true;
		}
		return false;
	}

	function sensorCollide(dotTest = true ) {
		for(w in game.world.walls) {
			if(w.w == wall) continue;
			if(w.w == lastwall) continue;
			if(w.n.x != worldNormal.x || w.n.y != worldNormal.y || w.n.z != worldNormal.z) continue;
			if(w.w.getBounds().rayIntersection(sensor, pt) != null) {
				var n = new h3d.col.Point(pt.x - sensor.px, pt.y - sensor.py, pt.z - sensor.pz);
				if(hxd.Math.distanceSq(n.x, n.y, n.z) > dray * dray) continue;
				if(!dotTest) return true;
				n.normalize();
				var v = sensor.getDir();
				v.normalize();
				if(v.x != n.x || v.y != n.y || v.z != n.z)
					return true;
			}
		}
		return false;
	}

	override function changeDir(v:Int) {
		super.changeDir(v);
		time = 10;
	}

	override public function update(dt:Float) {
		if(dead) return;
		super.update(dt);
		if(canMove) {
			move(dt);

			time -= dt;
			if(time > 0) return;
			if(!checkSensors())
				updateKeys();
		}
	}
}