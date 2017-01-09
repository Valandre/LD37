package ent;


class IA extends Entity
{
	var time = 0.;

	public function new(dir, scale = 1., ?id)	{
		game = Game.inst;
		this.dir = dir;
		var size = game.size >> 1;
		super(IA, -size * 0.65 * dir.x, -size * 0.65 * dir.y, -size, scale, id);
		this.z += w * 0.5;
	}

	function updateKeys() {
		if(Math.random() < 0.01)
			checkSensors(false);
	}

	function checkSensors(testFront = true ) {
		if(!enableCollides) return false;

		dray = 2 + Std.random(4);

		var col = true;
		sensor.px = x; sensor.py = y; sensor.pz = z;

		if(testFront) {
			sensor.lx = dray * dir.x; sensor.ly = dray * dir.y; sensor.lz = dray * dir.z;
			col = sensorCollide(dray);
		}

		if(col) {
			var d = setDir(dir, -1);
			sensor.lx = dray * d.x; sensor.ly = dray * d.y; sensor.lz = dray * d.z;
			var lcol = sensorCollide(dray);

			var d = setDir(dir, 1);
			sensor.lx = dray * d.x; sensor.ly = dray * d.y; sensor.lz = dray * d.z;
			var rcol = sensorCollide(dray);

			if(lcol && rcol) return false;
			if(!lcol && !rcol) {
				var v = Math.random() < 0.5 ? -1 : 1;
				changeDir(v);
			}
			else if(lcol) changeDir(1);
			else if(rcol) changeDir( -1);
			return true;
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