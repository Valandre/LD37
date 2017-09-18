package ent;

class Energy extends Entity
{
	var w = 2;
	var lifeTime = 10.; //seconds

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

		obj.setRotate(0, 0, 0);
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


	function blink() {
		for(m in obj.getMeshes()) {
			m.material.blendMode = Alpha;
			m.material.color.w = (Std.int(lifeTime * 10) % 2) == 0 ? 1 : 0.2;
		}
	}

	override public function update(dt:Float) {
		super.update(dt);
		lifeTime -= dt / 60;
		if(lifeTime < 0) {
			remove();
			return;
		}

		if(lifeTime < 2)
			blink();

		for(p in game.players)
			if(obj.getBounds().contains(new h3d.col.Point(p.x, p.y, p.z))) {
				remove();
				p.hitEnergy();
				break;
			}
	}
}