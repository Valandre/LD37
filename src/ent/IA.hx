package ent;


class IA extends Unit
{
	var time = 0.;

	public function new(props, dir, scale = 1., ?id)	{
		game = Game.inst;
		this.dir = dir;
		var size = game.size >> 1;
		super(IA, props, -size * 0.65 * dir.x, -size * 0.65 * dir.y, -size, scale, id);
	}

	function updateKeys() {
		//check around option
		var dist = 20;
		for(b in game.bonus) {
			if(hxd.Math.distance(x - b.x, y - b.y, z - b.z) > dist) continue;

			if(bonuscollide(b, Front, dist) && !scollide(Front, dist))
				return;
			if(bonuscollide(b, Left, dist) && !scollide(Left, dist)) {
				changeDir(-1);
				return;
			}
			if(bonuscollide(b, Right, dist) && !scollide(Right, dist)) {
				changeDir(1);
				return;
			}
		}

		//random change dir
		if(Math.random() < 0.01)
			checkSensors(false);
	}

	//bonus collide
	function bonuscollide(b : ent.Energy, kdir : ent.Unit.CollideDir, ray : Float) {
		var d = switch(kdir) {
			case Left :	setDir(dir, -1);
			case Right : setDir(dir, 1);
			case Front : dir.clone();
		}
		d.normalize();
		d.x *= ray; d.y *= ray; d.z *= ray;
		setSensor(x, y, z, d);

		var bounds = b.getBounds();
		var r = sensor.clone();
		var d = bounds.rayIntersection(r, false);
		if(d != -1){
			if(d > ray) return false;
			return true;
		}

		return false;
	}

	function checkSensors(testFront = true ) {
		if(!enableCollides) return false;

		var r = 2 + Std.random(4);
		var col = true;

		if(testFront)
			col = scollide(Front, r);

		if(col) {
			var lcol = scollide(Left, r);
			var rcol = scollide(Right, r);

			if(lcol && rcol) return false;
			if(!lcol && !rcol) {
				var v = Math.random() < 0.5 ? -1 : 1;
				changeDir(v);
			}
			else if(lcol) changeDir(1);
			else if(rcol) changeDir(-1);
			return true;
		}
		return false;
	}

	override function changeDir(v:Int) {
		super.changeDir(v);
		time = 8;
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

		if(power.isReady && Math.random() < 0.01)
			power.start();
	}
}