package ent;

enum BonusKind {
	SpeedUp;
	Shield;
	Rewind;
	Ghost;
}

class Bonus extends Entity
{
	var bonusKind :BonusKind;
	var w = 2.;
	var lifeTime = 10.; //seconds

	public function new()	{
		game = Game.inst;
		var all = BonusKind.createAll();
		bonusKind = all[Std.random(all.length)];
		bonusKind = Shield;

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
		m.material.color.setColor(getBonusColor(bonusKind));
	}

	static public function getBonusColor(k : BonusKind) {
		return switch(k) {
			case SpeedUp: 0x40F010;
			case Shield: 0x2080F0;
			case Rewind: 0xF04020;
			case Ghost: 0xF0F0FF;
		}
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
				p.hitBonus(bonusKind);
				break;
			}
	}
}