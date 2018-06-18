package ent;

class Energy extends Entity
{
	var w = 2;
	var lifeTime = 10.; //seconds
	var disapear = false;

	public function new()	{
		game = Game.inst;

		var face = Std.random(6);
		var x = 0.;
		var y = 0.;
		var z = 0.;
		var gNormal = null;
		var ray = game.size >> 1;
		switch(face) {
			case 0 : //bottom
				worldNormal = new h3d.col.Point(0, 0, 1);
				x = hxd.Math.srand(ray * 0.95);
				y = hxd.Math.srand(ray * 0.95);
				z = -ray + w * 0.5;
			case 1 : //top
				worldNormal = new h3d.col.Point(0, 0, -1);
				x = hxd.Math.srand(ray * 0.95);
				y = hxd.Math.srand(ray * 0.95);
				z = ray - w * 0.5;
			case 2 : //left
				worldNormal = new h3d.col.Point(1, 0, 0);
				x = -ray + w * 0.5;
				y = hxd.Math.srand(ray * 0.95);
				z = hxd.Math.srand(ray * 0.95);
			case 3 : //right
				worldNormal = new h3d.col.Point(-1, 0, 0);
				x = ray - w * 0.5;
				y = hxd.Math.srand(ray * 0.95);
				z = hxd.Math.srand(ray * 0.95);
			case 4 : //front
				worldNormal = new h3d.col.Point(0, 1, 0);
				x = hxd.Math.srand(ray * 0.95);
				y = -ray + w * 0.5;
				z = hxd.Math.srand(ray * 0.95);
			case 5 : //back
				worldNormal = new h3d.col.Point(0, -1, 0);
				x = hxd.Math.srand(ray * 0.95);
				y = ray - w * 0.5;
				z = hxd.Math.srand(ray * 0.95);
		}

		super(Energy, x, y, z);
		game.bonus.push(this);
	}

	function meshRotate() {
		var n = worldNormal;
		var a = Math.PI;

		obj.setRotation(0, 0, 0);
		if(n.z != 0) {
			if(n.z < 0) obj.rotate(a, 0, 0);
		}
		else if(n.x != 0) {
			obj.rotate(0, a * 0.5, 0);
			if(n.x < 0) obj.rotate(0, a, 0);
		}
		else if(n.y != 0) {
			obj.rotate(a * 0.5, 0, 0);
			if(n.y < 0) obj.rotate(a, 0, 0);
		}
	}

	override public function remove() {
		super.remove();
		game.bonus.remove(this);
	}

	override function getModel() : hxd.res.Model {
		return hxd.Res.Fx.Cells.Model;
	}

	override function init() {
		super.init();
		var a = game.modelCache.loadAnimation(model);
		a.loop = true;
		obj.playAnimation(a);
		meshRotate();
	}


	function kill() {
		var sc = 1.;
		game.event.waitUntil(function(dt) {
			sc *= Math.pow(0.8, dt);
			obj.setScale(sc);
			var v = 25 * (1 - sc);
			for(m in obj.getMeshes())
				m.material.color.set(v, v, v);

			if(sc < 0.1) {
				remove();
				return true;
			}
			return false;
		});
	}

	var sp = 0.;
	override public function update(dt:Float) {
		super.update(dt);

		var decrement = true;
		for(p in game.players) {
			var d = hxd.Math.distance(p.x - x, p.y - y, p.z - z);
			if(d < 10) decrement = false;
			if(d < p.attractRay) {
				x += (p.x - x) * sp * dt;
				y += (p.y - y) * sp * dt;
				z += (p.z - z) * sp * dt;
				sp += 0.03 * dt;
			}
			if(d < 1) {
				remove();
				p.hitEnergy();
				break;
			}
		}

		if(decrement) {
			sp = 0.; //restore speed
			lifeTime -= dt / 60;
			if(lifeTime < 0) {
				if(!disapear) {
					kill();
					disapear = true;
				}
				return;
			}
		}
	}
}