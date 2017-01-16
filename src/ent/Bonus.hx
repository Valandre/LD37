package ent;

enum BonusKind {
	SpeedUp;
	Missile;
	Rewind;
	Ghost;
}

class Bonus extends Entity
{
	var bonusKind :BonusKind;
	var w = 1.5;
	var lifeTime = 0;

	public function new(k : BonusKind)	{
		game = Game.inst;
		bonusKind = k;

		var face = Std.random(6);
		var x = 0.;
		var y = 0.;
		var z = 0.;
		var gNormal = null;
		var ray = game.size >> 1;
		switch(face) {
			case 0 : //bottom
				x = hxd.Math.srand(ray * 0.95);
				y = hxd.Math.srand(ray * 0.95);
				z = -ray + w * 0.5;
			case 1 : //top
				x = hxd.Math.srand(ray * 0.95);
				y = hxd.Math.srand(ray * 0.95);
				z = ray - w * 0.5;
			case 2 : //left
				x = -ray + w * 0.5;
				y = hxd.Math.srand(ray * 0.95);
				z = hxd.Math.srand(ray * 0.95);
			case 3 : //right
				x = ray - w * 0.5;
				y = hxd.Math.srand(ray * 0.95);
				z = hxd.Math.srand(ray * 0.95);
			case 4 : //front
				x = hxd.Math.srand(ray * 0.95);
				y = -ray + w * 0.5;
				z = hxd.Math.srand(ray * 0.95);
			case 5 : //back
				x = hxd.Math.srand(ray * 0.95);
				y = ray - w * 0.5;
				z = hxd.Math.srand(ray * 0.95);
		}

		super(Bonus, x, y, z);
		game.bonus.push(this);
	}

	override public function remove() {
		super.remove();
		game.bonus.remove(this);
	}

	override function getModel() {
		//TODO
		return null;
	}
	override function init() {
		obj = new h3d.scene.Object(game.s3d);
		var c = new h3d.prim.Cube(w, w, w);
		c.translate( -w * 0.5, -w * 0.5, -w * 0.5);
		c.addUVs();
		c.addNormals();
		var m = new h3d.scene.Mesh(c, obj);
		m.material.color.setColor(0xFF00FF);
	}

	override public function update(dt:Float) {
		super.update(dt);
	}
}